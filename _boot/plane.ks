runOncePath("0:/util/core.ks").
runOncePath("0:/navigation/flight.ks").

set cam to addons:camera:flightcamera.
set cam:mode to "CHASE".

InitTerminal("Welcome to the " + ship:name + " autopilot!").

declare ap is Autopilot:init().

ap:Takeoff().
ap:ChangeHeading(180).
ap:ChangeHeading(270).
ap:HoldForMinutes(3).
ap:ChangeHeading(360).
ap:ChangeHeading(90).
ApproachRunway().

wait until false.
