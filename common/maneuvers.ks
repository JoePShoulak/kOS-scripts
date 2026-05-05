runOncePath("0:/common/maneuver_core.ks").

function ProtectFromPast {
  parameter OriginalFunction.

  function ReplacementFunction {
    parameter data.

    if data[0] < time:seconds + 15 {
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

  local mnv is node(time:seconds + ship:orbit:eta:apoapsis, 0, 0, data[0]).
  add mnv.
  local score is 0. // TODO: Implement
  ManeuverStats(mnv, score).
  remove mnv.

  return score.}

function CircularizeAtApoapsis {
  declare data is list(0).
  set data to ImproveParameters(data, EccentricityScore_Apoapsis@).
  ExecuteManeuver(node(time:seconds + ship:orbit:eta:apoapsis, 0, 0, data[0])).
}

function HohmannTransferToTarget {
  declare data is list(time:seconds + 30, 0, 0, 0).
  set data to ImproveParameters(data, ProtectFromPast(InterceptScore@)).
  ExecuteManeuver(node(data[0], data[1], data[2], data[3])).
}
