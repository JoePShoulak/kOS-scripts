runOncePath("0:/util/core.ks").
runOncePath("0:/navigation/flight.ks").

set cam to addons:camera:flightcamera.
set cam:mode to "CHASE".

InitTerminal("Welcome to the " + ship:name + " autopilot!").

declare AP is Autopilot:init().

AP:Takeoff().
AP:ChangeHeading(180).
AP:ChangeHeading(270).
AP:HoldForMinutes(3).
AP:ChangeHeading(360).
AP:ChangeHeading(90).
AP:ApproachRunway().

wait until false.
