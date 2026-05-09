// maneuvers.ks

runOncePath("0:/util/maneuver_core.ks").

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
  ManeuverStats().
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
  ManeuverStats().
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
    ManeuverStats().
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

function CalcDVForNewSMA {
  parameter new_SMA.

  declare pos is kerbin:radius + ship:altitude.
  declare new_speed is sqrt(kerbin:mu*(2/pos - 1/new_SMA)).
  
  return new_speed - ship:velocity:orbit:mag.
}

function ChangeAPAtPE {
  parameter new_alt.

  declare new_SMA is body:radius + (new_alt + periapsis)/2.

  ExecuteManeuver(node(time:seconds + orbit:eta:periapsis, 0, 0, CalcDVForNewSMA(new_SMA))).
}

function ChangePEAtAP {
  parameter new_alt.

  declare new_SMA is body:radius + (new_alt + apoapsis)/2.

  ExecuteManeuver(node(time:seconds + orbit:eta:apoapsis, 0, 0, CalcDVForNewSMA(new_SMA))).
}

// Hohmann below
function CalcHohmannInterceptSMA {
  parameter tgt is target.
  set target to tgt.

  declare transfer_AP is tgt:orbit:semimajoraxis.
  declare transfer_PE is ship:orbit:semimajoraxis.

  return (transfer_AP + transfer_PE)/2.
}

function CalcHohmannInterceptTime {
  parameter SMA.
  parameter tgt is target.
  set target to tgt.

  declare transfer_period is 2 * constant:pi * sqrt(SMA^3 / kerbin:mu).
  declare transfer_time is transfer_period / 2.

  declare ship_speed_deg is 360 / ship:orbit:period.
  declare target_speed_deg is 360 / target:orbit:period.
  declare target_travel_deg is target_speed_deg * transfer_time.

 
  declare transfer_phase_angle is 180 + target_travel_deg.
  declare current_phase_angle is CalculatePhaseAngle(target).

  declare relative_speed_deg is ship_speed_deg - target_speed_deg.
  return (transfer_phase_angle - current_phase_angle) / relative_speed_deg.
}

function HohmannTransferToTarget {
  parameter tgt is target.
  set target to tgt.

  // TODO: Plane transfer before the transfer

  declare SMA is CalcHohmannInterceptSMA().
  declare time_to_wait is CalcHohmannInterceptTime(SMA).
  declare dV is CalcDVForNewSMA(SMA).

  ExecuteManeuver(node(time:seconds + time_to_wait, 0, 0, dV)).
}
