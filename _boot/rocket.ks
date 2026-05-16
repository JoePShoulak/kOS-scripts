runOncePath("0:/common/menu.ks").
runOncePath("0:/common/sequence.ks").
runOncePath("0:/util/core.ks").

function doSafeStage {
  wait until stage:ready.
  stage.
}

function AutoStage {
  if not(defined oldThrust) {
    declare global oldThrust to ship:availablethrust.
  }
  if ship:availablethrust < (oldThrust - 10) {
    doSafeStage(). wait 1.
    lock throttle to 1.0. // FIXME
    declare global oldThrust to ship:availablethrust.
  }
}

function LaunchRocket {
  print "Launching...".
  lock steering to Heading(90, 75).
  stage. 
  wait 3.
  set warpmode to "physics".
  set warp to 3.
  lock steering to ship:srfprograde.

  until apoapsis > 100e3 { AutoStage(). }

  lock throttle to 0.0.

  wait until altitude > 90e3.
  lock steering to Heading(90, 0).
  wait until altitude > 95e3.

  lock throttle to 1.0.
  until periapsis > 90e3 { AutoStage(). }
  lock throttle to 0.0.
  set warp to 0.
  wait until kuniverse:timewarp:issettled() and warp = 0 and ship:thrust = 0.
  wait 3.
}

function WaitForContract {
  print "Waiting...".
  parameter hours is 1.

  wait 2.

  declare init_time is time:seconds().
  until time:seconds() - init_time > 60 {
    warpto(time:seconds() + hours*60*60).
    wait until kuniverse:timewarp:issettled() and warp = 0.
  }

}

function BreakOrbit {
  print "Returning...".
  parameter target_pe is 55e3. 

  wait until kuniverse:timewarp:issettled() and warp = 0 and ship:thrust = 0.
  wait 3.

  warpto(time:seconds() + eta:apoapsis).
  wait until kuniverse:timewarp:issettled() and warp = 0 and ship:thrust = 0.
  lock steering to retrograde.
  wait 5.
  lock throttle to 1.0.
  until periapsis <= target_pe { autostage(). }
  lock throttle to 0.0.
}

function Land {
  print "Landing...".
  wait until kuniverse:timewarp:issettled() and warp = 0 and ship:thrust = 0.
  wait 3.
  warpto(time:seconds() + eta:periapsis).
  wait until altitude < 70e3.
  wait until kuniverse:timewarp:issettled() and warp = 0 and ship:thrust = 0.
  wait 3.
  set warpmode to "physics".
  set warp to 3.
  lock steering to ship:srfretrograde.

  lock throttle to 1.0.
  wait 3.
  until ship:stagenum = 0 {
    if ship:thrust = 0 { stage. }
    else { AutoStage(). }
  }

  when alt:radar < 2000 then { chutes on. stage. }
}

declare launch_options is list(
  CreateOption("LKO", { LaunchRocket(). WaitForContract(). BreakOrbit(). Land(). })
).

until false {
  InitTerminal("Welcome to the " + ship:name + " kOS autopilot!").

  SequenceMenu(launch_options, 30).
}
