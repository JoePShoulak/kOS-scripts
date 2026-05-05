// flight.ks
runOncePath("0:/common/util.ks").
runOncePath("0:/common/mechjeb.ks").
runOncePath("0:/common/stats.ks").
runOncePath("0:/common/maneuvers.ks").

function SSTOToOrbit {
  print " ".
  print "Performing Sequence: SSTO to Orbit.".

  Sequence(1, "Takeoff", SEQ["IDLE"]).
  Sequence(2, "Gain Speed", SEQ["IDLE"]).
  Sequence(3, "Reach Orbit", SEQ["IDLE"]).

  wait 1.

  Takeoff().
  LevelFlightToSpeed().
  PitchToOrbit().
}

// TAKEOFF
function Takeoff {
  parameter pitch is 10.
  parameter safe_alt is 1000.
  parameter hdg is 90.

  lock throttle to 1.0.
  LOCK STEERING to HEADING(hdg, 0).

  stage.

  Sequence(1, "Takeoff - Ignition!").

  declare local t to timestamp().
  until timestamp() - t > 3 { FlightAscentStats(). }

  Sequence(1, "Takeoff - Gaining speed for takeoff.").
  UNTIL ship:groundspeed > 100 { FlightAscentStats(). }

  Sequence(1, "Takeoff - Pitching for takeoff.").
  LOCK STEERING to HEADING(hdg, pitch).
  UNTIL altitude > 75 or verticalSpeed > 1 { FlightAscentStats(). }

  Sequence(1, "Takeoff - Airborne! Raising gear.").
  SET gear to false.
  set t to timestamp().
  until timestamp() - t > 3 { FlightAscentStats(). }

  Sequence(1, "Takeoff - Ascending to " + safe_alt + "m.").
  set warpmode to "PHYSICS".
  set warp to 3.
  until altitude > safe_alt { FlightAscentStats(). }
  set warp to 0.

  Sequence(1, "Takeoff - Safe altitude reached. Takeoff complete.", SEQ["COMPLETE"]).
}

// LEVEL FLIGHT TO SPEED:
//   Performs a level flight until a given speed is reached.
function LevelFlightToSpeed {
  parameter speed is 1000.
  parameter hdg is 90.

  Sequence(2, "Gain Speed - Flying level until: " + speed + "m/s...").
  set warpmode to "PHYSICS".
  set warp to 1.
  LOCK STEERING to HEADING(hdg, 2).
  until ship:airspeed > speed { FlightAscentStats(). }
  set warp to 0.
  Sequence(2, "Gain Speed - Target speed reached.", SEQ["COMPLETE"]).
}

// Time to get high
function PitchToOrbit {
  parameter target_alt is 80000.
  parameter hdg is 90.
  set warpmode to "PHYSICS".

  // Pitch up until we run out of thrust
  Sequence(3, "Reach Orbit - Pitching up for altitude.").
  set warp to 1.
  lock steering to heading(hdg, 15).
  until ship:thrust < 100 { FlightAscentStats(). }

  // Toggle out engines to closed cycle mode
  Sequence(3, "Reach Orbit - Switching engines to Closed Cycle mode.").
  set warp to 2.
  LIST ENGINES IN my_engines.
  for eng in my_engines { eng:togglemode(). }
  until apoapsis > target_alt { FlightAscentStats(). }
  lock throttle to 0.0.

  // Touch space
  Sequence(3, "Reach Orbit - Coasting to space.").
  lock steering to prograde.
  set warp to 3.
  until altitude > ship:orbit:body:atm:height {
    if apoapsis < target_alt {
      lock throttle to (choose 0.05 if throttle < 0.05 else throttle * 2.0).
    } else {
      lock throttle to 0.0.
    }

    FlightAscentStats(). 
  }
  set warp to 0.

  // Get to a stable orbit
  Sequence(3, "Reach Orbit - Circularizing.").
  Circularize().

  // Actually enter orbit
  // Sequence(3, "Reach Orbit - Let MechJeb handle the rest of the orbit.").
  // unlock steering.
  // unlock throttle.
  // MJQuickOrbit(target_alt).

  // Completion
  until periapsis > ship:orbit:body:atm:height and ship:thrust < 1 { FlightAscentStats(). }
  Sequence(3, "Reach Orbit - Orbit achieved!", SEQ["COMPLETE"]).
}
