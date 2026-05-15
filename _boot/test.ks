runOncePath("0:/util/core.ks").
runOncePath("0:/navigation/flight.ks").

InitTerminal("Welcome to the " + ship:name + " autopilot!").

Failsafe().

Takeoff().
ChangeHeading(180).
ChangeHeading(270).
FlyForMinutes(3.5).
ChangeHeading(360).
ChangeHeading(90).
ApproachRunway().

// InitialDescent().
// Landing().

wait until false.
