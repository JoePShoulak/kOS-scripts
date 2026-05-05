// maneuver.ks

runOncePath("0:/common/stats.ks").

function calculateStartTime {
  parameter mnv.

  return time:seconds + mnv:eta - maneuverBurnTime(mnv) / 2.
}

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

function MetricCirc {
  parameter mnv.
  return mnv:orbit:eccentricity.
}

function Score {
  parameter data.
  parameter metric.

  local mnv is node(data[0], data[1], data[2], data[3]).
  add mnv.
  local result is metric(mnv).
  remove mnv.

  ManeuverStats(mnv, result).

  return result.
}

function Improve {
  parameter data.
  parameter metric.
  parameter step_size is 1.

  local score_to_beat is Score(data, metric@).
  local best_candidate is data.
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

  for candidate in candidates {
    local new_score to Score(candidate, metric@).

    if new_score < score_to_beat {
      set score_to_beat to new_score.
      set best_candidate  to candidate.
    }
  }

  return best_candidate.
}

function CreateManeuver {
  parameter metric.
  parameter seed_time is 30.

  local mnv is list(time:seconds + seed_time, 0, 0, 0).

  declare old_score is 0.
  until false {
    set old_score to Score(mnv, metric@).
    set mnv to Improve(mnv, metric@).
    if old_score <= Score(mnv, metric@) { break. }
  }
}

function ExecuteManeuver {
  parameter data.

  local mnv is node(data[0], data[1], data[2], data[3]).
  local startTime is CalculateStartTime(mnv).
  
  add mnv.

  until time:seconds > startTime - 10 { ManeuverStats(mnv). }
  lock steering to mnv:burnvector.
  until time:seconds > startTime { ManeuverStats(mnv). }
  lock throttle to 1.
  until IsManeuverComplete(mnv) { ManeuverStats(mnv). }
  lock throttle to 0.
  
  remove mnv.
}
