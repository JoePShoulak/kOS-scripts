// maneuvers.ks

// TODO: Double check there's nothing else to review / improve here

runOncePath("0:/util/maneuver.ks").

// TODO: Redo improvement scores to be able to do a hill climbing algorithm 
// to find the closest approach to target (both on the current orbit and maneuver orbits)
// to be able to both display the distance to target in rendezvous stats, as wellas refine
// hohmann intercept maneuvers before performing the burns

// TODO: Make this work, eventually
function ContinueBurnUntilCircular {
  lock throttle to 0.1.
  declare old_ecc is ship:orbit:eccentricity.
  until ship:orbit:eccentricity > old_ecc {
    wait 1.
    set old_ecc to ship:orbit:eccentricity.
  }
  lock throttle to 0.0.
}

function CircularizeAtApoapsis { 
  ChangePEAtAP(apoapsis).
  // ContinueBurnUntilCircular().
}

function CircularizeAtPreiapsis { 
  ChangeAPAtPE(periapsis).
  // ContinueBurnUntilCircular().
}

function CalcDVForNewSMA {
  parameter new_SMA.

  declare pos is kerbin:radius + ship:altitude.
  declare new_speed is sqrt(kerbin:mu*(2/pos - 1/new_SMA)).
  
  return new_speed - ship:velocity:orbit:mag.
}

function ChangeAPAtPE {
  parameter new_alt.

  declare new_SMA is body:radius + (new_alt + periapsis) / 2.

  ExecuteManeuver(node(time:seconds + orbit:eta:periapsis, 0, 0, CalcDVForNewSMA(new_SMA))).
}

function ChangePEAtAP {
  parameter new_alt.

  declare new_SMA is body:radius + (new_alt + apoapsis) / 2.

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
  // TODO: Plane transfer before the transfer

  declare SMA is CalcHohmannInterceptSMA().
  declare time_to_wait is CalcHohmannInterceptTime(SMA).
  declare dV is CalcDVForNewSMA(SMA).

  ExecuteManeuver(node(time:seconds + time_to_wait, 0, 0, dV)).
}
