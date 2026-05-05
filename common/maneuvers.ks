runOncePath("0:/common/maneuver_core.ks").

function EccentricityScore_Apoapsis {
  parameter data.

  local mnv is node(time:seconds + ship:orbit:eta:apoapsis, 0, 0, data[0]).
  add mnv.
  local score is mnv:orbit:eccentricity.
  ManeuverStats(mnv, score).
  remove mnv.

  return score.
}

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

function CircularizeAtApoapsis {
  declare data is list(0).
  set data to ImproveParameters(data, EccentricityScore_Apoapsis@).
  ExecuteManeuver(node(time:seconds + ship:orbit:eta:apoapsis, 0, 0, data[0])).
}
