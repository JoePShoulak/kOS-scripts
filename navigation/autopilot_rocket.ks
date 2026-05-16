// Autopilot_rocket.ks

runOncePath("0:/util/core.ks").
runOncePath("0:/navigation/maneuvers.ks").

declare crr is addons:career.

declare global Autopilot_rocket is lexicon(
  "init", {
    declare this is lexicon().

    this:add("DoSafeStage", {
      wait until stage:ready.
      stage.
    }).

    this:add("WarpSettled", {
      return kuniverse:timewarp:issettled() and warp = 0 and ship:thrust = 0.
    }).

    this:add("Autostage", {
      if not(defined oldThrust) {
        declare global oldThrust to ship:availablethrust.
      }
      if ship:availablethrust < (oldThrust - 10) {
        this:DoSafeStage(). wait 1.
        lock throttle to 1.0. // FIXME
        declare global oldThrust to ship:availablethrust.
      }
    }).

    this:add("Launch", {
      print "Launching...".
      lock steering to Heading(90, 75).
      stage. 
      wait 3.
      set warpmode to "physics".
      set warp to 3.
      lock steering to ship:srfprograde.

      until apoapsis > 250e3 { this:Autostage(). }

      lock throttle to 0.0.

      wait until altitude > 70e3.
      set warp to 0.
      wait until this:WarpSettled().
      CircularizeAtApoapsis().
      lock throttle to 0.2.
      wait until apoapsis - periapsis > 10e3.
      lock throttle to 0.
      wait until this:WarpSettled().
    }).

    this:add("WaitForContract", {
      parameter hours is 1.

      print "Waiting...".

      declare init_time is time:seconds().
      set warpmode to "rails".
      until time:seconds() - init_time > 60 {
        warpto(time:seconds() + hours*60*60).
        wait until kuniverse:timewarp:issettled() and warp = 0.
      }
    }).

    this:add("BreakOrbit", {
      print "Returning...".
      parameter target_pe is 55e3. 

      ChangePEAtAP(target_pe).
      wait until this:WarpSettled().
    }).

    this:add("Land", {
      print "Landing...".
      wait until this:WarpSettled().
      wait 3. // FIXME: Needed?
      warpto(time:seconds() + eta:periapsis).
      wait until this:WarpSettled().
      set warpmode to "physics".
      set warp to 3.
      lock steering to ship:srfretrograde.
      wait until vang(ship:facing:forevector, ship:srfretrograde:forevector) < 1.
      lock throttle to 1.0.
      wait 1.
      until ship:stagenum = 0 { if ship:engines[0]:flameout { stage.} }

      when alt:radar < 2000 then { chutes on. stage. }

      wait until status = "LANDED" or ship:status = "SPLASHED".
    }).

    this:add("Recover", {
      wait until crr:isrecoverable(ship).
      crr:recovervessel(ship).
    }).

    // MISSIONS

    this:add("LKOTourism", { this:Launch(). this:WaitForContract(). this:BreakOrbit(). this:Land(). this:Recover(). }).

    return this.
  }
).