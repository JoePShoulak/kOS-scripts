runOncePath("0:/util/core.ks").
runOncePath("0:/navigation/autopilot_plane.ks").

set cam to addons:camera:flightcamera.
set cam:mode to "CHASE".

InitTerminal("Welcome to the " + ship:name + " autopilot!").

set Autopilot_plane:default_altitude to 10010.
declare AP is Autopilot_plane:init().

// TODO: Adjust some part of the landing sequence to take the altitude into account,
// and decide if you're too close to land from that altitude
AP:Takeoff().
AP:ChangeHeading(180).
AP:ChangeHeading(270).
// AP:HoldForMinutes(3).
AP:HoldForMinutes(12).
AP:ChangeHeading(360).
AP:ChangeHeading(90).
AP:ApproachRunway().

wait until false.
