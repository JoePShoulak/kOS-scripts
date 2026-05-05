// boot: ssto.ks

// INCLUDES
runOncePath("0:/common/flight.ks").
runOncePath("0:/common/util.ks").
runOncePath("0:/common/menu.ks").
runOncePath("0:/common/maneuvers.ks").
runOncePath("0:/common/rendezvous.ks").

// MAIN
wait 3. // in case we want to telnet in before init

InitTerminal("Welcome to the " + ship:name + " kOS autpilot!").

// TODO: Implement all these delegates
// TODO: Allow for gracefully leaving the menu and add an idle screen with an easy way to rengage with the program

declare launch_labels is list(
  "LKO",
  "LKO - Tourism",
  "Kerbin Alpha",
  "Kerbin Alpha - Resupply",
  "Kerbin Alpha - Tourism",
  "Exit"
).

declare launch_delegates is list(
  SSTOToOrbit@,
  { SHUTDOWN. },
  { SSTOToOrbit(). Rendezvous("Kerbin Alpha"). DockWithClosestVessel(). },
  { SHUTDOWN. },
  { SHUTDOWN. },
  { SHUTDOWN. }
).

declare orbit_labels is list(
  "Kerbal Space Center",
  "Kerbin Alpha",
  "Kerbin Alpha - Resupply",
  "Kerbin Alpha - Tourism",
  "Exit"
).

declare orbit_delegates is list(
  { SHUTDOWN. },
  { SHUTDOWN. },
  { SHUTDOWN. },
  { SHUTDOWN. },
  { SHUTDOWN. }
).

if ship:status = "PRELAUNCH" { DestinationMenu(launch_delegates, launch_labels, 30). }
else { DestinationMenu(orbit_delegates, orbit_labels). }


// Alert("Rendezvous and dock with Kerbin Alpha.").
// declare docking_port is ship:partsnamedpattern("docking")[0].
// wait until docking_port:haspartner().
// PRINT "Nice job docking!".
