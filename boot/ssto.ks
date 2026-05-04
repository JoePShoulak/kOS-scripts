// boot: ssto.ks

// INCLUDES
runOncePath("0:/common/flight.ks").
runOncePath("0:/common/rendezvous.ks").
runOncePath("0:/common/util.ks").

// MAIN
InitTerminal().

PRINT "Welcome to the " + ship:name + " kOS autpilot!".

PRINT "[ ]  1. Takeoff"  AT(0, 2).
PRINT "[ ]  2. Stabilize"  AT(0, 3).

Takeoff().
LevelFlightToSpeed().
PitchToOrbit().


runPath("0:/common/hohmann.ks").

// Rendezvous("Kerbin Alpha").

// Alert("Rendezvous and dock with Kerbin Alpha.").
// declare docking_port is ship:partsnamedpattern("docking")[0].
// wait until docking_port:haspartner().
// PRINT "Nice job docking!".
