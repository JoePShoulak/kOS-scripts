// maneuver.ks

runOncePath("0:/common/stats.ks").

function maneuverBurnTime {
  parameter mnv.

  add mnv.

  local dV is mnv:deltaV:mag.
  local g0 is 9.80665.
  local isp is 0.

  list engines in myEngines.
  for en in myEngines {
    if en:ignition and not en:flameout {
      set isp to isp + (en:isp * (en:availablethrust / ship:availablethrust)).
    }
  }

  local mf is ship:mass / constant():e^(dV / (isp * g0)).
  local fuelFlow is ship:availablethrust / (isp * g0).
  local t is (ship:mass - mf) / fuelFlow.

  remove mnv.

  return t.
}

function isManeuverComplete {
  parameter mnv.
  if not(defined originalVector) or originalVector = -1 {
    declare global originalVector to mnv:burnvector.
  }
  if vang(originalVector, mnv:burnvector) > 90 {
    declare global originalVector to -1.
    return true.
  }
  return false.
}

function GenerateCandidates {
  parameter data, step_size.

  local candidates is list().
  local index is 0.

  until index >= data:length {
    local inc_candidate is data:copy().
    local dec_candidate is data:copy().

    set inc_candidate[index] to inc_candidate[index] + step_size.
    set dec_candidate[index] to dec_candidate[index] - step_size.

    candidates:add(inc_candidate).
    candidates:add(dec_candidate).

    set index to index + 1.
  }

  return candidates.
}

function Improve {
  parameter data, Metric, step_size.

  local score_to_beat is Metric(data).
  local best_candidate is data.

  for candidate in GenerateCandidates(data, step_size) {
    local new_score to Metric(candidate).
    if new_score < score_to_beat {
      set score_to_beat to new_score.
      set best_candidate  to candidate.
    }
  }

  return best_candidate.
}

function ImproveParameters {
  parameter data, Metric.
  parameter step_list is list(100, 10, 1).

  declare old_score is 2^64.

  for step_size in step_list {
    until false {
      set old_score to Metric(data).
      set data to Improve(data, Metric@, step_size).
      if old_score <= Metric(data) { break. }
    }
  }

  return data.
}

function ExecuteManeuver {
  parameter mnv.

  local startTime is time:seconds + mnv:eta - maneuverBurnTime(mnv) / 2.
  
  add mnv.

  until time:seconds > startTime - 10 { ManeuverStats(mnv). }
  lock steering to mnv:burnvector.
  until time:seconds > startTime { ManeuverStats(mnv). }
  lock throttle to 1.
  until IsManeuverComplete(mnv) { ManeuverStats(mnv). }
  lock throttle to 0.
  unlock steering.
  unlock throttle.
  
  remove mnv.
}
