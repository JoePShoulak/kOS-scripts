// boot: ssto.ks

// INCLUDES
runOncePath("0:/common/flight.ks").
runOncePath("0:/common/rendezvous.ks").
runOncePath("0:/common/util.ks").
runOncePath("0:/common/menu.ks").

// MAIN
InitTerminal("Welcome to the " + ship:name + " kOS autpilot!").

AutoLaunchMenu(SSTOToOrbit@).

// Rendezvous("Kerbin Alpha").

// Alert("Rendezvous and dock with Kerbin Alpha.").
// declare docking_port is ship:partsnamedpattern("docking")[0].
// wait until docking_port:haspartner().
// PRINT "Nice job docking!".
