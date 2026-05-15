runOncePath("0:/util/core.ks").

InitTerminal("Welcome to the " + ship:name + " autopilot!").

// FAILSAFE
when ship:verticalspeed < -50 and alt:radar < 1000 then { print "Bailing...". abort on. }

// Ignition
print "Ignition...".
lock steering to heading(90, 0).
lock throttle to 1.0.
stage.

wait until airspeed > 60.
// Takeoff
declare pid_pitch is pidloop(3, 0.1, 30, -10, 10).
set pid_pitch:setpoint to 1000.
set input_pitch to 0.
lock steering to heading(90, input_pitch).
until altitude >= 1000 {
  set input_pitch to pid_pitch:update(time:seconds, altitude).
}

function ChangeHeading {
  parameter target_global_heading.

  print "Changing heading to " + target_global_heading.

  // Maintain altitude
  declare _pid_pitch is pidloop(3, 0.1, 30, -10, 10).
  set _pid_pitch:setpoint to altitude.
  set input_pitch to PitchFor(ship).
  
  // Heading stuff
  lock current_global_heading to mod(360 - ship:bearing, 360). // always our true heading
  declare intitial_global_heading is current_global_heading.   // our intial true heading

  lock current_relative_heading to current_global_heading - intitial_global_heading. // The amount we've turned
  declare target_relative_heading is 180 - mod((target_global_heading - intitial_global_heading + 180), 360). // The total amount we need to turn

  declare pid_hdg is pidloop(1, 0.1, 10, -5, 5). // Make the pid
  set pid_hdg:setpoint to target_relative_heading. // Set the goal to the amount we need to turn
  declare input_hdg is 0. // Start with a change in steering of 0

  lock steering to heading(mod(intitial_global_heading + input_hdg, 360), input_pitch). // steer towards our true heading + the calc'd input
  until false { // We are at our target
    set input_pitch to _pid_pitch:update(time:seconds, altitude).
    set input_hdg   to pid_hdg:update(  time:seconds, current_relative_heading). // Set the new input to the pid output after giving it our progress so far
  }
}

ChangeHeading(180).
ChangeHeading(270).

print "Waiting 3.5 minutes...".
wait 3.5*60.

ChangeHeading(360).
ChangeHeading(90).

// Intitial descent
print "Beginning initial descent...".
set pid_pitch to 100.
wait until altitude <= 100.

// Landing
print "Landing...".
when alt:radar < 200 then { gear on. }
lock throttle to 0.0.

print "Pattern finished. Holding steady ad infinitum.".

wait until false.
