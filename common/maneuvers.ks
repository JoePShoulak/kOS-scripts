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

  declare apoapsis_time is ApoapsisTime(mnv).

  local apoapsis_diff is 5 * abs((target:orbit:periapsis + 1000 - mnv:orbit:apoapsis)).
  local distance_at_apo is (positionAt(ship, apoapsis_time) - positionAt(target, apoapsis_time)):mag.
  local score is apoapsis_diff + distance_at_apo.
  ManeuverStats(mnv, score).
  remove mnv.

  return score.
}

function CreateRefineInterceptScore {
  parameter full_data. 

  function RefineInterceptScore {
    parameter data.
    local mnv is node(data[0], full_data[1], full_data[2], full_data[3]).
    add mnv.

    declare apoapsis_time is ApoapsisTime(mnv).

    local score is (positionAt(ship, apoapsis_time) - positionAt(target, apoapsis_time)):mag.
    ManeuverStats(mnv, score).
    remove mnv.
    
    return score.
  }

  return RefineInterceptScore@.
}

function CircularizeAtApoapsis {
  declare data is list(0).
  set data to ImproveParameters(data, EccentricityScore_Apoapsis@).
  ExecuteManeuver(node(time:seconds + ship:orbit:eta:apoapsis, 0, 0, data[0])).
}

function HohmannTransferToTarget {
  parameter tgt is target.
  set target to tgt.

  // Steps 1 and 2
  declare transfer_AP is target:orbit:semimajoraxis.
  declare transfer_PE is ship:orbit:semimajoraxis.
  declare transfer_SMA is (transfer_AP + transfer_PE)/2.
  declare transfer_period is 2 * constant:pi * sqrt(transfer_SMA^3 / kerbin:mu).
  declare transfer_time is transfer_period / 2.

  // Steps 3, 4, and 6
  declare ship_speed_deg is 360 / ship:orbit:period.
  declare target_speed_deg is 360 / target:orbit:period.
  declare target_travel_deg is target_speed_deg * transfer_time.

  // Steps 5 and 7
  declare vecKS is ship:position - ship:body:position.
  declare vecKT is target:position - target:body:position.

  declare transfer_phase_angle is 180 + target_travel_deg.
  declare current_phase_angle is vang(vecKS, vecKT).

  declare forVec TO VXCL(vecKS, SHIP:VELOCITY:ORBIT).
  declare isAhead TO 0 < VDOT(vecKT, forVec).

  // Told this was needed, but it brewaks it. Is it backwards?
  // if not isAhead { set current_phase_angle to 360 - current_phase_angle. } 

  // Step 8
  declare relative_speed_deg is ship_speed_deg - target_speed_deg.
  declare time_to_wait is (transfer_phase_angle - current_phase_angle) / relative_speed_deg.

  // Step 9
  // Vis-viva: v^2 = G*M*(2/r - 1/a)
  declare pos is kerbin:radius + ship:altitude.
  declare new_speed is sqrt(kerbin:mu*(2/pos - 1/transfer_SMA)).
  declare delta_v is new_speed - ship:velocity:orbit:mag.

  // Steps 10, 11, and 12
  declare data is list(time:seconds + time_to_wait, 0, 0, delta_v).
  // set data to ImproveParameters(data, ProtectFromPast(InterceptScore@), list(1, 0.1)).
  // set data to ImproveParameters(data, ProtectFromPast(CreateRefineInterceptScore(data))).
  ExecuteManeuver(node(data[0], data[1], data[2], data[3])).
}
