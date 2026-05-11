// flight.ks

runOncePath("0:/util/core.ks").
runOncePath("0:/common/stats.ks").
runOncePath("0:/navigation/maneuvers.ks").
runOncePath("0:/common/sequence.ks").

function Takeoff {
  parameter index.

  return lexicon (
    "init", { Sequence(index, "Takeoff", SEQ["IDLE"]). },
    "exec", {
      parameter pitch is 10.
      parameter safe_alt is 2000.
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
      LOCK STEERING to HEADING(hdg, 15).
      UNTIL ship:status = "FLYING" { FlightStats_SSTO(). }

      Sequence(index, "Takeoff - Airborne! Raising gear...").
      SET gear to false.
      set init_time to timestamp().
      until altitude > 150 { FlightStats_SSTO(). }

      Sequence(index, "Takeoff - Ascending to " + safe_alt + "m...").
      set warp to 3.
      LOCK STEERING to HEADING(hdg, PITCH).
      until altitude > safe_alt { FlightStats_SSTO(). }

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
      // set warp to 1.

      declare pid_pitch is pidloop(1, 0.1, 1, 0, 15).
      set input_pitch to 2.
      lock steering to heading(90, input_pitch).
      until input_pitch = 15 {
        set input_pitch to pid_pitch:update(time:seconds, input_pitch).
        FlightStats_SSTO().
      }


      lock steering to heading(hdg, 15).
      declare old_speed is 0.
      until ship:thrust < 500 and ship:airspeed < old_speed { 
        wait 0.1.
        set old_speed to ship:airspeed.
        FlightStats_SSTO(). }

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

function InSunlight {
  parameter object.

  SET sun_pos TO BODY("SUN"):POSITION.
  SET obj_pos TO object:POSITION.
  SET body_center TO BODY("KERBIN"):POSITION. // Or use SHIP:BODY:POSITION

  SET v_obj_to_sun TO sun_pos - obj_pos.
  SET v_obj_to_body TO body_center - obj_pos.

  return vang(v_obj_to_sun, -v_obj_to_body) < 90.
}

function Undock {
  parameter index.

  return lexicon(
    "init", { Sequence(index, "Undock", SEQ["IDLE"]). },
    "exec", {
      declare port is core:element:dockingports[0].

      Sequence(index, "Undock - Undocking...").
      port:undock.
      kuniverse:forceactive(core:vessel).

      wait until kuniverse:activevessel = core:vessel.
      wait 3.
      Sequence(index, "Undock - Gaining distance...").
      set rcs to true.
      set ship:control:translation to v(0,1,0).
      wait 5.
      set rcs to false.
      SET SHIP:CONTROL:NEUTRALIZE to True.

      declare animator is port:getmodule("ModuleAnimateGeneric").
      declare deploy_event is "retract docking port". 

      if animator:HasEvent(deploy_event) { animator:DoEvent(deploy_event). }
      Sequence(index, "Undock - Undocked!", SEQ["COMPLETE"]).
    }
  ).
}

function ReenterAtmosphere_SSTO {
  parameter index.

  return lexicon(
    "init", { Sequence(index, "Returning to Kerbin", SEQ["IDLE"]). },
    "exec", {  
      declare ksc is Waypoint("KSC").
      lock phase_angle to CalculatePhaseAngle(ksc).

      if apoapsis > 100000 or periapsis > 100000 {
        Sequence(index, "Returning to Kerbin - Transferring to smaller orbit...").
        // TODO: no most likely
         ChangeAPAtPE(100000). ChangeAPAtPE(100000). // This turns our old periapsis into our new apoapsis (most likely)
      }

      // TODO: Improve this warping
      declare tpa is 200. // target phase angle
      set warp to 5.
      until phase_angle > tpa - 90 and phase_angle < tpa and InSunlight(ksc) { FlightStats_Landing(). }.
      set warp to 3.
      until phase_angle > tpa - 10 and phase_angle < tpa and InSunlight(ksc) { FlightStats_Landing(). }.
      set warp to 1.
      until phase_angle > tpa and phase_angle < tpa + 1 { FlightStats_Landing(). }.
      set warp to 0.
      Sequence(index, "Returning to Kerbin - Lowering PE to within atmosphere...").
      lock steering to retrograde.
      until vang(ship:facing:forevector, retrograde:forevector) < 2 and ship:angularvel:mag < 0.1 { FlightStats_Landing(). }.
      lock throttle to 1.
      until periapsis < 30000 { FlightStats_Landing(). }.
      lock throttle to 0.
      wait 1.

      Sequence(index, "Returning to Kerbin - Descending with high AoA...").
      set warp to 3.
      when altitude < 70000 then {
        set warpmode to "PHYSICS".
        set warp to 3.
        LIST ENGINES IN my_engines.
        for eng in my_engines { eng:togglemode(). }
      }

      lock steering to heading(90, 20). 
      when altitude < 50000 then { set warp to 0. }
      until ship:velocity:surface:mag < 2000 { FlightStats_Landing(). } // TODO: Should be surface speed?

      Sequence(index, "Returning to Kerbin - Coasting with low AoA...").
      until ship:airspeed < 700 or altitude < 10000 { lock steering to heading(90, 5). FlightStats_Landing(). }
      Sequence(index, "Returning to Kerbin - Successful return to Kerbin!", SEQ["COMPLETE"]).
    }
  ).
}

function LandAtKSC_SSTO {
  parameter index.
  declare ksc is Waypoint("KSC").

  return lexicon(
    "init", { Sequence(index, "Landing at KSC", SEQ["IDLE"]). },
    "exec", {
      declare pid_throttle is pidLoop(2.5, 0.1, 5, 0, 1).
      declare pid_pitch to pidLoop(50, 0.1, 80, -5, 5).

      Sequence(index, "Landing at KSC - Descending to safe altitude...").
      set desired_pitch to 0.
      set desired_throttle to 0.
      set desired_roll to 0.
      lock steering to Heading(90, desired_pitch).
      lock throttle to desired_throttle.
      set pid_pitch:setpoint to 6000. // altitude
      set pid_throttle:setpoint to 600. // airspeed
      until (ksc:position - ship:position):mag < 50000 {
        set desired_throttle to pid_throttle:update(time:seconds, ship:airspeed).
        set desired_pitch to pid_pitch:update(time:seconds, altitude).
        FlightStats_Landing().
      }

      Sequence(index, "Landing at KSC - Approaching runway...").
      set pid_pitch to pidLoop(50, 0.1, 100, -10, 10).
      set pid_pitch:setpoint to 1000. // altitude
      set pid_throttle:setpoint to 250. // airspeed
      until (ksc:position - ship:position):mag < 20000 {
        set desired_throttle to pid_throttle:update(time:seconds, ship:airspeed).
        set desired_pitch to pid_pitch:update(time:seconds, altitude).
        FlightStats_Landing().
      }

      Sequence(index, "Landing at KSC - Landing at runway...").
      set pid_pitch:setpoint to 400. // altitude
      set pid_throttle:setpoint to 150. // airspeed
      declare pid_roll is pidloop(100, 1, 50, -1, 1).
      set pid_roll:setpoint to -0.0485998228908655. // KSC Runway 09 lat
      set rcs to true.
      until (ksc:position - ship:position):mag < 5000 {
        set desired_throttle to pid_throttle:update(time:seconds, ship:airspeed).
        set desired_pitch to pid_pitch:update(time:seconds, altitude).
        set desired_roll to pid_roll:update(time:seconds, ship:geoposition:lat).
        set ship:control:translation to v(-desired_roll, 0, 0). // TODO: Don't use RCS
        FlightStats_Landing().
      }

      lock steering to Heading(90, 3).
      set pid_throttle:setpoint to 75. // airspeed
      set gear to true.

      until status = "landed" {
        set desired_roll to pid_roll:update(time:seconds, ship:geoposition:lat).
        set ship:control:translation to v(-desired_roll, 0, 0). // TODO: Don't use RCS
        set desired_throttle to pid_throttle:update(time:seconds, ship:airspeed).
        FlightStats_Landing().
      }

      set rcs to false.
      lock throttle to 0.
      set brakes to true.

      Sequence(index, "Landing at KSC - Successful landing at KSC!", SEQ["COMPLETE"]).
      unlock steering.
      unlock throttle.
      until false { FlightStats_Landing(). }
    }
  ).
}

function ReturnToKerbin_SSTO {
  declare port is core:element:dockingports[0].

  declare seqs is list().
  if port:haspartner { seqs:add(undock@). }

  seqs:add(ReenterAtmosphere_SSTO@).
  seqs:add(LandAtKSC_SSTO@).

  return seqs.
}
