// maneuver_core.ks

// TODO: Double check there's nothing else to review / improve here

runOncePath("0:/common/stats.ks").
runOncePath("0:/util/core.ks").

// TODO: Rewatch the video to understand this math better
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
  local burn_time is (ship:mass - mf) / fuelFlow.

  remove mnv.

  return burn_time.
}

// TODO: Try to find a way to do this without squigglies
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

function ExecuteManeuver {
  parameter mnv.

  local startTime is time:seconds + mnv:eta - maneuverBurnTime(mnv) / 2.
  
  add mnv.

  if startTime - time:seconds > 600 { warpTo(startTime - 600).  }
  lock steering to mnv:burnvector.
  wait until vang(ship:facing:forevector, mnv:burnvector) < 2.
  set warpmode to "rails".
  warpTo(startTime - 10).
  until time:seconds > startTime { ManeuverStats(). }
  lock throttle to 1.
  until IsManeuverComplete(mnv) { ManeuverStats(). }
  // TODO: Better throttle smoothing
  lock throttle to 0.
  unlock steering.
  unlock throttle.
  
  remove mnv.

  wait 1. 
}
