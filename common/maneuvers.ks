runOncePath("0:/common/maneuver_core.ks").

function ProtectFromPast {
  parameter OriginalFunction.

  function ReplacementFunction {
    parameter data.

    if data[0] < time:seconds + 30 {
      return 2^64.
    } else {
      return OriginalFunction(data).
    }
  }
  
  return ReplacementFunction@.
}

function EccentricityScore_Apoapsis {
  parameter data.

  local mnv is node(time:seconds + ship:orbit:eta:apoapsis, 0, 0, data[0]).
  add mnv.
  local score is mnv:orbit:eccentricity.
  ManeuverStats(mnv, score).
  remove mnv.

  return score.
}

function InterceptScore {
  parameter data.

  local mnv is node(data[0], data[1], data[2], data[3]).
  add mnv.

  local apoapsis_time is TernarySearch(
    AltitudeAt@,
    time:seconds + mnv:eta,
    time:seconds + mnv:eta + (mnv:orbit:period / 2),
    1
  ).

  local apoapsis_diff is abs((mnv:orbit:apoapsis - kerbin:altitudeof(positionAt(target, apoapsis_time)))).
  local distance_at_apo is (positionAt(ship, apoapsis_time) - positionAt(target, apoapsis_time)):mag.
  local score is apoapsis_diff + distance_at_apo.
  ManeuverStats(mnv, score).
  remove mnv.

  return score.
}

function CircularizeAtApoapsis {
  declare data is list(0).
  set data to ImproveParameters(data, EccentricityScore_Apoapsis@).
  ExecuteManeuver(node(time:seconds + ship:orbit:eta:apoapsis, 0, 0, data[0])).
}

function HohmannTransferToTarget {
  parameter tgt is target.
  set target to tgt.

  declare data is list(time:seconds + 30, 0, 0, 0).
  set data to ImproveParameters(data, ProtectFromPast(InterceptScore@)).
  ExecuteManeuver(node(data[0], data[1], data[2], data[3])).
}
