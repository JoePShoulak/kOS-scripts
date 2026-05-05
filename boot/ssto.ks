// boot: ssto.ks

// INCLUDES
runOncePath("0:/common/flight.ks").
runOncePath("0:/common/util.ks").
runOncePath("0:/common/menu.ks").

// MAIN
wait 3. // in case we want to telnet in before init

InitTerminal("Welcome to the " + ship:name + " kOS autpilot!").

declare delegates is list(SSTOToOrbit@, { SHUTDOWN. }).
declare labels is list("Fly to orbit.", "Manual control.").

AutoLaunchMenu(delegates, labels).

// Rendezvous("Kerbin Alpha").

// Alert("Rendezvous and dock with Kerbin Alpha.").
// declare docking_port is ship:partsnamedpattern("docking")[0].
// wait until docking_port:haspartner().
// PRINT "Nice job docking!".
