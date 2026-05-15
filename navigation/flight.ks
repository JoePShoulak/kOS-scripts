// flight.ks

runOncePath("0:/util/core.ks").

declare global Autopilot is lexicon(
  "default_altitude", 2500,
  "default_takeoff_speed", 60,
  "default_speed", 300,

  "GHTR", { // Global Heading to Relative
    parameter intitial_heading.
    parameter global_heading.

    declare output is -180 + mod(global_heading - intitial_heading + 180, 360).
    if output < -180 { set output to 360 + output. } // FIXME
    return output.
  },

  "init", {
    set this to lexicon().

    // Failsafe
    // TODO: Detect more failure states
    when ship:verticalspeed < -50 and alt:radar < 1000 then { print "Bailing...". abort on. }

    // Helpers
    this:add("Heading", { return mod(360 - ship:bearing, 360). }).

    // Properties
    this:add("target_heading", this:Heading()).
    this:add("input", lexicon(
      "heading", 0,
      "pitch", altitude,
      "throttle", 0
    )).

    this:add("pid", lexicon(
      "pitch", pidloop(3, 0.1, 10, -10, 10),
      "heading", pidloop(1, 0.1, 15, -5, 5),
      "throttle", pidloop(0.1, 0.01, 0.1, 0, 1),
      "update", {
        set this:input:pitch to this:pid:pitch:update(time:seconds, altitude).
        set this:input:heading to this:pid:heading:update(time:seconds, this:HeadingError()).
        set this:input:throttle to this:pid:throttle:update(time:seconds, airspeed).      
      }
    )).

    lock throttle to this:input:throttle.
    // TODO: Not sure I like this solution
    this:add("FullAuto", {
      lock steering to Heading(mod(this:Heading() + this:input:heading, 360), this:input:pitch).
    }).

    ////////////////// Steps

    // Start the plane and give it some gas
    this:add("Ignition", {
      print "Ignition...".
      set this:pid:throttle:setpoint to Autopilot:default_speed.
      stage.
    }).

    // Get it off the ground
    this:add("Takeoff", {
      if ship:availableThrust = 0 { this:ignition(). }

      print "Takeoff...".

      lock steering to Heading(this:Heading(), 0).
      until airspeed > Autopilot:default_takeoff_speed { this:pid:update(). }
      
      lock steering to Heading(this:Heading(), 10).
      set this:pid:pitch:setpoint to Autopilot:default_altitude.
      when alt:radar > 100 then { this:FullAuto(). }
      until altitude >= this:pid:pitch:setpoint { this:pid:update(). }
    }).

    this:add("HeadingError", {
      return Autopilot:GHTR(this:target_heading, this:Heading()).
    }).

    // Changes in heading need some special attention
    // TODO: Or do they?
    this:add("ChangeHeading", {
      parameter hdg.

      print "Assuming heading of " + hdg + "...".

      set this:target_heading to hdg.

      until abs(this:HeadingError()) < 1 { this:pid:update(). }
    }).
    
    // Keep the current course for some number of minutes
    this:add("HoldForMinutes", {
      parameter minutes.

      print "Flying this course for " + minutes + " minutes...".

      declare start_time is time:seconds().
      until time:seconds > start_time + minutes*60 { this:pid:update(). }
    }).

    return this.
  }
).

// Can land you on KSC runway 09.
// Tested with ~15km distance due west, 2500 altitude, heading 90
// Should generally work if west of KSC and within 15deg of the start of the runway, 
// if starting with reasonable height and speed
function ApproachRunway {
  parameter target_speed is 100.

  print "Lining up with the runway...".

  declare ksc is Waypoint("KSC").
  declare ksc_09_lat is -0.0485998228908655. // Runway 9 true lat
  lock lat_err to ksc_09_lat - ship:geoposition:lat.

  declare pid_hdg is pidloop(500, 1, 100, -15, 15).
  declare input_hdg is 90.

  declare pid_pitch is pidloop(3, 0.1, 30, -10, 10).
  lock dist to (ksc:position - ship:position):mag.
  set initial_altitude to altitude.
  // declare runway_start is 2000.
  declare runway_start is 2500.
  declare descent_end is runway_start + 500. // meters away from runway start
  declare descent_start is initial_altitude * 6 + descent_end.
  declare descent_target_height is 175.
  lock target_altitude to max(descent_target_height, min(initial_altitude, FitLine(descent_start, initial_altitude, descent_end, descent_target_height)(dist))).
  set pid_pitch:setpoint to altitude.
  declare input_pitch is PitchFor(ship).

  declare pid_throttle is pidloop(0.1, 0.01, 0.1, 0, 1).
  set pid_throttle:setpoint to target_speed.
  declare input_throttle is throttle.

  lock throttle to input_throttle.
  lock steering to Heading(input_hdg, input_pitch).

  clearScreen.
  until dist < runway_start {
    set pid_pitch:setpoint to target_altitude.
    set input_pitch to pid_pitch:update(time:seconds, altitude).
    set input_hdg to 90 + pid_hdg:update(time:seconds, lat_err).
    set input_throttle to pid_throttle:update(time:seconds, airspeed).
    print "Lat err: " + round(lat_err, 8) + ", inp_hdg: " + round(input_hdg, 2) at(0,0).
    print ("target_alt: " + round(target_altitude) + ", inp_pitch: " + round(input_pitch, 2) + ", dist: " + round(dist)):padright(10) at(0,1).
  }

  set pid_pitch:setpoint to 0.
  set pid_throttle:setpoint to 50.
  set input_hdg to 90.
  until ship:status = "LANDED" {
    set input_pitch to pid_pitch:update(time:seconds, alt:radar).
    set input_throttle to pid_throttle:update(time:seconds, airspeed).
    if alt:radar <= 2 { break. }
    print "Lat err: " + round(lat_err, 8) + ", inp_hdg: " + round(input_hdg, 2) at(0,0).
    print ("target_alt: " + round(target_altitude) + ", inp_pitch: " + round(input_pitch, 2) + ", dist: " + round(dist)):padright(10) at(0,1).
  }

  lock throttle to 0.
  lock steering to heading(90, 0).
  brakes on.
}

// ROUTINES


/////////////// OLD FLIGHT BELOW //////////////////////


// runOncePath("0:/common/stats.ks").
// runOncePath("0:/navigation/maneuvers.ks").
// runOncePath("0:/navigation/docking.ks").
// runOncePath("0:/common/sequence.ks").

// TAKEOFF
// Performs a safe takeoff for a plane
//   - Heading: This should match 10*[the runway number]
//   - Pitch: The pitch you want to have for your climb to the safe alt
//   - Takeoff pitch: The pitch to rock back on the wheels for takeoff
//   - Takeoff speed: The speed at which to perform the above pitch
//   - Takeoff alt: The altitude at which the pitch switches from takeoff_pitch to pitch
//   - Safe alt: We pitch up until we reach this altitude
// function Takeoff {
//   parameter index.

//   return lexicon (
//     "init", { Sequence(index, "Takeoff", SEQ["IDLE"]). },
//     "exec", {
//       // parameter hdg is 90.
//       parameter pitch is 10.
//       parameter takeoff_pitch is 15.
//       parameter takeoff_speed is 100.
//       parameter takeoff_alt is 150.
//       parameter safe_alt is 500.

//       lock throttle to 1.0.
//       lock steering to HEADING(90, 0).
//       set brakes to false.
//       set warpmode to "physics".

//       // Light the engines
//       Sequence(index, "Takeoff - Ignition...").
//       stage.
//       declare init_time to timestamp().
//       until timestamp() - init_time > 3 { FlightStats_SSTO(). } 

//       // Wait for takeoff speed (100m/s)
//       Sequence(index, "Takeoff - Gaining speed for takeoff...").
//       UNTIL ship:groundspeed > takeoff_speed { FlightStats_SSTO(). }

//       // Pitch the nose up for takeoff (15deg)
//       Sequence(index, "Takeoff - Pitching for takeoff...").
//       lock steering to HEADING(90, takeoff_pitch).
//       UNTIL ship:status = "FLYING" { FlightStats_SSTO(). }

//       // Raise gear and wait until above takeoff alt (150km)
//       Sequence(index, "Takeoff - Airborne! Raising gear...").
//       SET gear to false.
//       until altitude > takeoff_alt { FlightStats_SSTO(). }

//       // Go to a more moderate pitch (10deg) and fly up to safe alt (2000km)
//       Sequence(index, "Takeoff - Ascending to " + safe_alt + "m...").
//       set warp to 3.
//       lock steering to HEADING(90, PITCH).
//       until altitude > safe_alt { FlightStats_SSTO(). }

//       // All done!
//       Sequence(index, "Takeoff - Safe altitude reached!", SEQ["COMPLETE"]).
//       set warp to 0.
//     }
//   ).
// }

// // LEVEL FLIGHT TO SPEED
// // Performs a level flight until a given speed is reached (usually to feedback thrusters)
// //   - speed: The target speed to fly level until reached
// //   - hdg: The heading to fly in (should match the heading you were on before this function)
// //   - pitch: The pitch to fly at until the target speed is reached (low enough to gain massive speed without hitting the water)
// function LevelFlightToSpeed {
//   parameter index.

//   return lexicon(
//     "init", { Sequence(index, "Gain Speed", SEQ["IDLE"]). },
//     "exec", {
//       parameter speed is 1000.

//       Sequence(index, "Gain Speed - Flying level until: " + speed + "m/s...").
//       set warp to 1.
//       lock steering to HEADING(90, 2).
//       until ship:airspeed > speed { FlightStats_SSTO(). }

//       Sequence(index, "Gain Speed - Target speed reached!", SEQ["COMPLETE"]).
//       set warp to 0.
//     }
//   ).
// }

// // PITCH TO ORBIT
// // Pitch upwards to convert massive horizontal speed into some altitude (and more speed) to reach orbit
// // Uses a PID top slowly pitch up to the target angle 
// // - target_alt: The apoapsis (and periapsis) of our desired orbit
// // - hdg: The heading to fly in while pitching up
// //        (should be 90 for equatorial orbit benefits. Should also be the heading from previous step(s))
// // - Thrust Cutoff Check: The thrust at which, late in the function, we begin checking for loss of speed, indicating the
// //                        air-breathing mode is too lossy to continue, so we switch to the less-efficient closed-cycle mode. 
// function PitchToOrbit {
//   parameter index.

//   return lexicon(
//     "init", { Sequence(index, "Reach Orbit", SEQ["IDLE"]). },
//     "exec", {
//       parameter target_alt is ship:orbit:body:atm:height + 10e3. // 80000 on Kerbin
//       parameter target_pitch is 15.
//       parameter thrust_cutoff_check is 500.

//       // Assuming we have gained a lot of speed before this function, turn it into altitude (and speed)
//       Sequence(index, "Reach Orbit - Pitching up for altitude...").
//       declare pid_pitch is pidloop(0.01, 0.001, 10, 0, 15).
//       set input_pitch to 2.
//       lock steering to heading(90, input_pitch).
//       until input_pitch = 15 {
//         set input_pitch to pid_pitch:update(time:seconds, input_pitch).
//         FlightStats_SSTO().
//       }

//       // Ride the air breathers for as long as we can
//       Sequence(index, "Reach Orbit - Gaining altitude...").
//       lock steering to heading(90, target_pitch).
//       declare old_speed is 0.
//       until ship:thrust < thrust_cutoff_check and ship:airspeed < old_speed { 
//         set old_speed to ship:airspeed.
//         FlightStats_SSTO().
//       }

//       // Toggle our engines to closed cycle mode
//       Sequence(index, "Reach Orbit - Switching engines to Closed Cycle mode...").
//       set warp to 2.
//       list engines IN my_engines.
//       for eng in my_engines { if eng:multimode { eng:togglemode(). } }
//       until apoapsis >= target_alt { FlightStats_SSTO(). }
//       lock throttle to 0.0.

//       // Touch space
//       Sequence(index, "Reach Orbit - Coasting to space...").
//       lock steering to prograde.
//       set warp to 3.
//       until altitude >= ship:orbit:body:atm:height {
//         lock throttle to choose 0.2 if apoapsis < target_alt else 0.
//         FlightStats_SSTO().
//       }
//       set warp to 0. wait until kuniverse:timewarp:issettled.
      
//       // Get to a stable orbit
//       Sequence(index, "Reach Orbit - Circularizing...").
//       CircularizeAtApoapsis().

//       // Completion
//       Sequence(index, "Reach Orbit - Orbit achieved!", SEQ["COMPLETE"]).
//     }
//   ).
// }

// // SETUP RETURN TRAJECTORY SSTO
// // Put the ship into a specifc LKO (80km, same as takeoff orbit), then wait for the right time to do
// // an injection to get close to KSC, and perform that periapsis-lowering burn (20km)
// function SetupReturnTrajectory_SSTO {
//   parameter index.

//   return lexicon(
//     "init", { Sequence(index, "Setting up Kerbin Return", SEQ["IDLE"]). },
//     "exec", {  
//       declare ksc is Waypoint("KSC").
//       lock phase_angle to CalculatePhaseAngle(ksc).

//       // If we're even in a true orbit
//       if periapsis >= ship:orbit:body:atm:height {
//         // If our orbit is too big, we need to switch to a smaller one so our rentry angle isn't too steep
//         if apoapsis > 85e3 {
//           Sequence(index, "Setting up Kerbin Return - Transferring to smaller orbit...").
//           if apoapsis > 85e3 { ChangeAPAtPE(80e3). }
//           if apoapsis > 85e3 { ChangeAPAtPE(80e3). }
//         }

//         // Wait until our typical flight path would deliver us on a reasonable approach to KSC
//         declare tpa is 225. // target phase angle
//         if phase_angle < tpa or phase_angle > tpa + 1 {
//           Sequence(index, "Setting up Kerbin Return - Waiting for KSC approach phase angle...").
//           until phase_angle > tpa - 10 and phase_angle < tpa { set warp to 3. FlightStats_Landing(). }.
//           until phase_angle > tpa and phase_angle < tpa + 1 { set warp to 1. FlightStats_Landing(). }.
//           set warp to 0.
//         }

//         // We lower our periapsis but do it in a check in case this program is called mid-descent
//         Sequence(index, "Setting up Kerbin Return - Lowering PE to within atmosphere...").
//         lock steering to retrograde.
//         until vang(ship:facing:forevector, retrograde:forevector) < 2 and ship:angularvel:mag < 0.1 { FlightStats_Landing(). }.
//         lock throttle to 1.
//         until periapsis < 20 { FlightStats_Landing(). }.
//         lock throttle to 0.
//         wait 1.
//         Sequence(index, "Setting up Kerbin Return - Trajectory acquired!", SEQ["COMPLETE"]).
//       }
//     }
//   ).
// }

// // REENTER ATMOSPHERE SSTO
// // Handle a high speed return into Kerbin's atmosphere by doing a high AoA descent
// // and a low AoA coast to reasonable speed and altitude
// // TODO: Long-term: Try to do some math and pid to keep the "impact location" close to KSC.
// // (or some practical offset) such that by the end of this sequence, we are in a consistent and
// // reasonable location to begin the landing sequence. This includes SetupReturnTrajectory_SSTO.
// // Also, improve the true moment of landing. 
// function ReenterAtmosphere_SSTO {
//   parameter index.

//   return lexicon(
//     "init", { Sequence(index, "Returning to Kerbin", SEQ["IDLE"]). },
//     "exec", {  
//       // If we're out of the atmosphere now, pitch up 20 and wait to blast through the top of it
//       if altitude > 50e3 or ship:velocity:surface:mag > 1500 {
//         lock steering to heading(90, 20). 
//         Sequence(index, "Returning to Kerbin - Descending with high AoA...").
//         wait until kuniverse:timewarp:issettled().
//         set warp to 3.
//         if altitude > 70e3 { when altitude < 70e3 then {
//           wait until kuniverse:timewarp:issettled().
//           wait 1.
//           set warp to 3.
//         }}
//         if altitude > 50e3 { when altitude < 50e3 then { set warp to 0. } }
//         when altitude < ship:orbit:body:atm:height then {
//           list ENGINES IN my_engines.
//           for eng in my_engines { if eng:multimode { eng:togglemode(). } }
//         }
//         until ship:velocity:surface:mag < 1500 { FlightStats_Landing(). }
//       }

//       // If we're at unreasonable speeds and altitude, wait until we're not, at which point standard autopilots can take over
//       if ship:airspeed > 700 and altitude > 10e3 {
//         Sequence(index, "Returning to Kerbin - Coasting with low AoA...").
//         lock steering to heading(90, 5).
//         until ship:airspeed < 700 or altitude < 10e3 { FlightStats_Landing(). }
//         Sequence(index, "Returning to Kerbin - Successful return to Kerbin!", SEQ["COMPLETE"]).
//       }
//     }
//   ).
// }

// // LAND AT KSC SSTO
// // Now that previous functions have brought us to a reasonable altitude and speed,
// // let's land at KSC! Uses a lerped PID to go from just above the mountains
// // west of KSC to just before thr runway
// function LandAtKSC {
//   parameter index.
//   return lexicon(
//     "init", { Sequence(index, "Landing at KSC", SEQ["IDLE"]). },
//     "exec", {
//       declare pid_throttle is pidLoop(0.5, 0.02, 0.1, 0, 1).
//       declare pid_pitch to pidLoop(2, 8, 50, -5, 5).
//       declare ksc is Waypoint("KSC").
//       declare ksc_09_lat is -0.0485998228908655. // Runway 9 true lat

//       // Maintain 90hdg (correcting to runway), 6km alt, and 500m/s 
//       // until we're past the mountains just west of KSC
//       Sequence(index, "Landing at KSC - Descending to safe altitude...").
//       declare input_pitch is PitchFor(ship).
//       declare input_throttle is 0.
//       lock dist to (ksc:position - ship:position):mag.
//       lock target_altitude to min(6000, FitLine(50e3, 6000, 5000, 300)(dist)).
//       lock target_airspeed to min(600, FitLine(50e3, 500, 5000, 150)(dist)).

//       lock hdg to 90 + 10 * (ship:geoposition:lat - ksc_09_lat).
//       lock steering to heading(hdg, input_pitch).
//       lock throttle to input_throttle.

//       when dist < 50e3 then { Sequence(index, "Landing at KSC - Flying towards KSC..."). }

//       // TODO: This is fairly repetitive
//       // At this point, our flight path should have us at 0.3km alt and 150m/s speed as declared above
//       until (ksc:position - ship:position):mag < 5000 {
//         set pid_pitch:setpoint to target_altitude.
//         set pid_throttle:setpoint to target_airspeed.

//         set input_pitch to pid_pitch:update(time:seconds, altitude).
//         set input_throttle to pid_throttle:update(time:seconds, airspeed).
//         FlightStats_Landing().
//       }

//       lock target_altitude to min(300, FitLine(5000, 300, 2000, 200)(dist)).
//       Sequence(index, "Landing at KSC - Approaching KSC...").
//       until (ksc:position - ship:position):mag < 3200 {
//         set pid_pitch:setpoint to target_altitude.
//         set pid_throttle:setpoint to target_airspeed.

//         set input_pitch to pid_pitch:update(time:seconds, altitude).
//         set input_throttle to pid_throttle:update(time:seconds, airspeed).
//         FlightStats_Landing().
//       }

//       // We set our airspeed to 75 on PID, our pitch to 3 degrees, put down our gear, and hope
//       Sequence(index, "Landing at KSC - Landing at KSC...").
//       lock steering to Heading(90, 3).
//       set pid_throttle:setpoint to 75. // airspeed
//       set gear to true.
//       until status = "landed" or status = "SPLASHED" {
//         set input_throttle to pid_throttle:update(time:seconds, airspeed).
//         FlightStats_Landing().
//       }

//       // Stop RCS, stop engines, throw on brakes
//       Sequence(index, "Landing at KSC - Successful landing at KSC!", SEQ["COMPLETE"]).
//       set rcs to false.
//       lock throttle to 0.
//       set brakes to true.
//       unlock steering.
//       unlock throttle.
//       wait 3.
//     }
//   ).
// }

// // TODO: Refine/double-check these logics
// // Handle every step needed for getting an SSTO from KSC Runway 09 to orbit
// function SSTOToOrbit {

//   declare seqs is list().

//   if ship:status = "prelaunch" { seqs:add(Takeoff@). }
//   if airspeed < 500 { seqs:add(LevelFlightToSpeed@). }
//   seqs:add(PitchToOrbit@).

//   return seqs.
// }

// // Handle every step needed for returning an SSTO from orbit to KSC Runway 09
// function ReturnToKerbin_SSTO {
//   declare port is core:element:dockingports[0].

//   declare seqs is list().
//   if port:haspartner { seqs:add(undock@). }
//   if periapsis > ship:orbit:body:atm:height or ship:status = "PRELAUNCH" { seqs:add(SetupReturnTrajectory_SSTO@). }
//   if ship:airspeed > 700 and altitude > 10e3 or ship:status = "PRELAUNCH" { seqs:add(ReenterAtmosphere_SSTO@). }
//   seqs:add(LandAtKSC@).

//   return seqs.
// }
