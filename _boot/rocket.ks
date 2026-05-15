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
    declare global oldThrust to ship:availablethrust.
  }
}

function LaunchRocket {
  parameter index.

  return lexicon(
    "init", { Sequence(index, "Launch", SEQ["IDLE"]). },
    "exec", {
      lock steering to ship:up.
      lock throttle to 1.0.
      stage. 
      
      when altitude > 10e3 then {
        when altitude < 10e3 then {
          set chutes to true.
          Sequence(index, "Launch - Waiting for chutes...").
          until stage:number = 0  { stage. }
        }
      } // failsafe

      Sequence(index, "Launch - Pushing apoapsis to 80km...").
      until apoapsis > 80e3 { 
        AutoStage().
        FlightStats().
      }
      lock throttle to 0.0.
      when ship:thrust = 0 then { stage. }

      Sequence(index, "Launch - Coasting to space...").
      until altitude > 70e3 { FlightStats(). }.

      Sequence(index, "Launch - Pushing apopasis to 80km...").
      lock steering to heading(90, 0).
      lock throttle to 1.0.
      until periapsis > 80e3 { FlightStats(). }.
      lock throttle to 0.0.
      
      Sequence(index, "Launch - Waiting an hour...").
      warpto(time:seconds + 60*60).
      
      Sequence(index, "Launch - Breaking orbit...").
      lock steering to retrograde.
      lock throttle to 1.0.
      until periapsis < 55e3 { FlightStats(). }.
      lock throttle to 0.0.

      Sequence(index, "Launch - Killing remaining speed...").
      until altitude < 60e3 { FlightStats(). }.
      lock throttle to 1.0.
      lock steering to ship:up.

      Sequence(index, "Launch - Waiting for chutes...").

      until ship:status = "LANDED" or ship:status = "SPLASHED" { FlightStats(). }
      Sequence(index, "Launch - Landed!", SEQ["COMPLETE"]).
    }
  ).
}

declare launch_options is list(
  CreateOption("LKO", { Mission(list(LaunchRocket@)). })
).

until false {
  InitTerminal("Welcome to the " + ship:name + " kOS autopilot!").

  SequenceMenu(launch_options, 30).
}
