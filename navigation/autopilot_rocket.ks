// Autopilot_rocket.ks

runOncePath("0:/util/core.ks").
runOncePath("0:/navigation/maneuvers.ks").
runOncePath("0:/navigation/rendezvous.ks").
runOncePath("0:/common/sequence.ks").

declare crr is addons:career.

// TODO: Convert all methods to be lexicons of size one, where the key is the sequence name, the value is the 
// actual method delegate, and we can use the key names to list our mission sequences, before executing them afterwards. 
// We will probably need to give the autopilot a reference to the line number or something to keep track of what to print when,
//3 Or figure out how to have menu handle that

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
        declare global oldThrust to ship:availablethrust.
      }
    }).

    this:add("Launch", {
      if ship:status = "PRELAUNCH" {
        print "Launching...".
        lock steering to Heading(90, 85).
        lock throttle to 1.0.
        stage. 
        wait 3.
        set warpmode to "physics".
        set warp to 1.
        when ship:engines:length < 3 then { wait 1. set warp to 3. }
        lock steering to ship:srfprograde.

        until apoapsis > 120e3 { this:Autostage(). }

        lock throttle to 0.0.

        until altitude > 70e3 { this:Autostage(). }
        set warp to 0.
        wait until this:WarpSettled().
        CircularizeAtApoapsis().
        wait until this:WarpSettled().
        lock steering to ship:srfprograde.
        lock throttle to 1.0.
        wait until periapsis > 71e3. // FIXME
        lock throttle to 0.
        wait until this:WarpSettled().
        CircularizeAtApoapsis().
        wait until this:WarpSettled().
      }
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

    this:add("Rendezvous", {
      parameter tgt.
      set target to tgt.

      print "Initiating rendezvous with " + tgt + "...".
      // TOOD: Determine if we need to perform the Hohmann transfer or not
      Mission(list(Rendezvous())).
    }).

    this:add("BreakOrbit", {
      print "Returning...".
      parameter target_pe is 55e3. 

      if periapsis > target_pe {
        ChangePEAtAP(target_pe).
        wait until this:WarpSettled().
      }
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
        when alt:radar < 200 then { gear on. }

        wait until status = "LANDED" or ship:status = "SPLASHED".
      }
    ).

    this:add("Recover", {
      wait until crr:isrecoverable(ship).
      wait 3.
      wait until crr:isrecoverable(ship).
      crr:recovervessel(ship).
    }).

    // MISSIONS

    this:add("Return", { this:BreakOrbit(). this:Land(). this:Recover(). }).
    this:add("KerbinAlpha", { this:Launch(). this:Rendezvous("Kerbin Alpha"). }).
    this:add("LKOTourism", { this:Launch(). this:WaitForContract(). this:Return(). }).

    return this.
  }
).
