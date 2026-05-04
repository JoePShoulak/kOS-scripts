// flight.ks
runOncePath("0:/common/util.ks").

declare global hdg is 90.


// TAKEOFF:
//   Pitches the plane up until the wheels leave the ground
function Takeoff {
  parameter pitch is 10.
  parameter safe_alt is 1000.

  lock throttle to 1.0.
  LOCK STEERING to HEADING(hdg, 0).
  stage.

  PRINT "Gaining speed for takeoff...".
  WAIT UNTIL ship:groundspeed > 100.

  PRINT "Pitching for takeoff...".
  LOCK STEERING to HEADING(hdg, pitch).
  WAIT UNTIL altitude > 75 or verticalSpeed > 1.

  PRINT "We are airborne! Raising gear and gaining altitude...".
  SET gear to false.
  WAIT until altitude > safe_alt.
  LOCK THROTTLE to 1.0.

  PRINT "Safe altitude reached!".

  PRINT "------".
}

// LEVEL FLIGHT TO SPEED:
//   Performs a level flight until a given speed is reached.
function LevelFlightToSpeed {
  parameter speed is 1000.

  PRINT "Flying level until: " + speed + "m/s...".

  LOCK STEERING to HEADING(hdg, 2).
  WAIT until ship:airspeed > speed.

  PRINT "Target speed reached.".

  PRINT "------".
}

// Time to get high
function PitchToOrbit {
  PRINT "time to get high...".

  // Pitch up until we run out of thrust
  lock steering to heading(hdg, 15).
  WAIT until ship:thrust < 100.

  // Toggle out engines to closed cycle mode
  LIST ENGINES IN my_engines.
  for eng in my_engines { eng:togglemode(). }
  unlock steering.
  unlock throttle.

  // Actually enter orbit
  QuickOrbit().
  PRINT "------".
}
