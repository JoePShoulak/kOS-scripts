// flight.ks
runOncePath("0:/common/util.ks").

declare global hdg is 90.

function UpdateStats {
  declare padding is floor(terminal:width/4).
  declare row is terminal:height - 3.

  PRINT ("Speed: "    + round(ship:airspeed, 2) + "m/s" ):padright(padding) at(0, row).
  PRINT ("Altitude: " + round(altitude/1000, 2) + "km"  ):padright(padding) at(padding, row).
  PRINT ("Apoapsis: " + round(apoapsis/1000, 2) + "km"  ):padright(padding) at(2*padding, row).
  PRINT ("Thrust: "   + round(ship:thrust, 2) + "N"     ):padright(padding) at(3*padding, row).

  PRINT ("V. Speed: "   + round(ship:verticalspeed, 2) + "m/s"):padright(padding) at(0, row+1).
  PRINT ("Q: "          + round(ship:q, 2) + "ATM"            ):padright(padding) at(padding, row+1).
  PRINT ("Periapsis: "  + round(periapsis/1000, 2) + "km"     ):padright(padding) at (2*padding, row+1).
  PRINT ("Engines: "    + ship:engines[0]:mode()              ):padright(padding) at (3*padding, row+1).
  wait 0.001.
}


// TAKEOFF:
//   Pitches the plane up until the wheels leave the ground
function Takeoff {
  parameter pitch is 10.
  parameter safe_alt is 1000.

  lock throttle to 1.0.
  LOCK STEERING to HEADING(hdg, 0).

  stage.

  PRINT "[ ]  1. Takeoff - Ignition!":padright(100) at(0, 2).

  set a to timestamp().
  until timestamp() - a > 3 { UpdateStats(). }

  PRINT "[ ]  1. Takeoff - Gaining speed for takeoff.":padright(100) at(0, 2).
  UNTIL ship:groundspeed > 100 { UpdateStats(). }

  PRINT "[ ]  1. Takeoff - Pitching for takeoff.":padright(100) at(0, 2).
  LOCK STEERING to HEADING(hdg, pitch).
  UNTIL altitude > 75 or verticalSpeed > 1 { UpdateStats(). }

  PRINT "[ ]  1. Takeoff - Airborne! Raising gear.":padright(100) at(0, 2).
  SET gear to false.
  set a to timestamp().
  until timestamp() - a > 3 { UpdateStats(). }

  PRINT ("[ ]  1. Takeoff - Ascending to " + safe_alt + "m."):padright(100) at(0, 2).
  until altitude > safe_alt { UpdateStats(). }
  LOCK THROTTLE to 1.0.

  PRINT "[X]  1. Takeoff - Safe altitude reached. Takeoff complete.":padright(100) at(0, 2).
}

// LEVEL FLIGHT TO SPEED:
//   Performs a level flight until a given speed is reached.
function LevelFlightToSpeed {
  parameter speed is 1000.

  PRINT "[ ]  2. Gain Speed - Flying level until: " + speed + "m/s...":padright(100)  AT(0, 3).

  LOCK STEERING to HEADING(hdg, 2).
  until ship:airspeed > speed { UpdateStats(). }

  PRINT "[X]  2. Gain Speed - Target speed reached.":padright(100)  AT(0, 3).
}

// Time to get high
function PitchToOrbit {
  PRINT "[ ]  3. Reach Orbit - Pitching up for altitude.":padright(100)  AT(0, 4).

  // Pitch up until we run out of thrust
  lock steering to heading(hdg, 15).
  until ship:thrust < 100 { UpdateStats(). }

  // Toggle out engines to closed cycle mode
  PRINT "[ ]  3. Reach Orbit - Switching engines to Closed Cycle mode.":padright(100)  AT(0, 4).
  LIST ENGINES IN my_engines.
  for eng in my_engines { eng:togglemode(). }
  until apoapsis > 80000 { UpdateStats(). }

  // Actually enter orbit
  PRINT "[ ]  4. Reach Orbit - Let MechJeb handle the rest of the orbit.":padright(100)  AT(0, 4).
  unlock steering.
  unlock throttle.
  QuickOrbit().

  until periapsis > 70000 and ship:thrust < 1 { UpdateStats(). }
  PRINT "[X]  4. Reach Orbit - Orbit achieved!":padright(100)  AT(0, 4).
}
