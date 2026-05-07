// flight.ks

runOncePath("0:/common/util.ks").
runOncePath("0:/common/stats.ks").
runOncePath("0:/common/maneuvers.ks").
runOncePath("0:/common/sequence.ks").

function Takeoff {
  parameter index.

  return lexicon (
    "init", { Sequence(index, "Takeoff", SEQ["IDLE"]). },
    "exec", {
      parameter pitch is 10.
      parameter safe_alt is 1000.
      parameter hdg is 90.

      lock throttle to 1.0.
      LOCK STEERING to HEADING(hdg, 0).
      set brakes to false.

      stage.

      Sequence(index, "Takeoff - Ignition...").

      declare local init_time to timestamp().
      until timestamp() - init_time > 3 { FlightStats_SSTO(). }

      Sequence(index, "Takeoff - Gaining speed for takeoff...").
      UNTIL ship:groundspeed > 100 { FlightStats_SSTO(). }

      Sequence(index, "Takeoff - Pitching for takeoff...").
      LOCK STEERING to HEADING(hdg, pitch).
      UNTIL altitude > 75 or verticalSpeed > 1 { FlightStats_SSTO(). }

      Sequence(index, "Takeoff - Airborne! Raising gear...").
      SET gear to false.
      set init_time to timestamp().
      until timestamp() - init_time > 3 { FlightStats_SSTO(). }

      Sequence(index, "Takeoff - Ascending to " + safe_alt + "m...").
      set warpmode to "PHYSICS".
      set warp to 3.
      until altitude > safe_alt { FlightStats_SSTO(). }
      set warp to 0.

      Sequence(index, "Takeoff - Safe altitude reached!", SEQ["COMPLETE"]).
    }
  ).
}

// LEVEL FLIGHT TO SPEED:
//   Performs a level flight until a given speed is reached.
function LevelFlightToSpeed {
  parameter index.

  return lexicon(
    "init", { Sequence(index, "Gain Speed", SEQ["IDLE"]). },
    "exec", {
      parameter speed is 1000.
      parameter hdg is 90.

      Sequence(index, "Gain Speed - Flying level until: " + speed + "m/s...").
      set warpmode to "PHYSICS".
      set warp to 1.
      LOCK STEERING to HEADING(hdg, 2).
      until ship:airspeed > speed { FlightStats_SSTO(). }
      set warp to 0.
      Sequence(index, "Gain Speed - Target speed reached!", SEQ["COMPLETE"]).
    }
  ).
}

// Time to get high
function PitchToOrbit {
  parameter index.

  return lexicon(
    "init", { Sequence(index, "Reach Orbit", SEQ["IDLE"]). },
    "exec", {
      parameter target_alt is 80000.
      parameter hdg is 90.
      set warpmode to "PHYSICS".

      // Pitch up until we run out of thrust
      Sequence(index, "Reach Orbit - Pitching up for altitude...").
      set warp to 1.
      lock steering to heading(hdg, 15).
      until ship:thrust < 100 { FlightStats_SSTO(). }

      // Toggle out engines to closed cycle mode
      Sequence(index, "Reach Orbit - Switching engines to Closed Cycle mode...").
      set warp to 2.
      LIST ENGINES IN my_engines.
      for eng in my_engines { eng:togglemode(). }
      until apoapsis > target_alt { FlightStats_SSTO(). }
      lock throttle to 0.0.

      // Touch space
      Sequence(index, "Reach Orbit - Coasting to space...").
      lock steering to prograde.
      set warp to 3.
      until altitude > ship:orbit:body:atm:height {
        if apoapsis < target_alt {
          lock throttle to (choose 0.05 if throttle < 0.05 else throttle * 2.0).
        } else {
          lock throttle to 0.0.
        }

        FlightStats_SSTO(). 
      }
      set warp to 0.

      // Get to a stable orbit
      Sequence(index, "Reach Orbit - Circularizing...").
      CircularizeAtApoapsis().

      // Completion
      Sequence(index, "Reach Orbit - Orbit achieved!", SEQ["COMPLETE"]).
    }
  ).
}

function SSTOToOrbit {
  return list(Takeoff@, LevelFlightToSpeed@, PitchToOrbit@).
}
