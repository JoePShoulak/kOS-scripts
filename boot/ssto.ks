// boot: ssto.ks

// INCLUDES
runOncePath("0:/common/flight.ks").
runOncePath("0:/common/util.ks").
runOncePath("0:/common/menu.ks").
runOncePath("0:/common/maneuvers.ks").
runOncePath("0:/common/rendezvous.ks").

// TODO: Implement all these delegates

declare launch_labels is list(
  "LKO",
  "LKO - Tourism",
  "Kerbin Alpha",
  "Kerbin Alpha - Resupply",
  "Kerbin Alpha - Tourism",
  "Exit"
).

declare launch_delegates is list(
  SSTOToOrbit@, // LKO
  {}, // LKO - Tourism
  { // Kerbin Alpha
    SSTOToOrbit(). Rendezvous(). DockWithClosestVessel().
  },
  { // Kerbin Alpha - Resupply
    SSTOToOrbit(). Rendezvous(). DockWithClosestVessel(). 
    // Transfer resources 
    // Return home
  },
  { // Kerbin Alpha - Tourism
    SSTOToOrbit(). Rendezvous(). DockWithClosestVessel().
    // Wait 4 hours
    // Return home
  }, 
  {}  // Exit
).

declare orbit_labels is list(
  "Kerbal Space Center",
  "Kerbin Alpha",
  "Kerbin Alpha - Resupply",
  "Kerbin Alpha - Tourism",
  "Exit"
).

declare orbit_delegates is list(
  {}, // Kerbal Space Center
  { Rendezvous("Kerbin Alpha"). DockWithClosestVessel(). }, // Kerbin Alpha
  { Rendezvous("Kerbin Alpha"). DockWithClosestVessel(). }, // Kerbin Alpha - Resupply
  { Rendezvous("Kerbin Alpha"). DockWithClosestVessel(). }, // Kerbin Alpha - Tourism
  {}  // Exit
).

// MAIN
if ship:status = "PRELAUNCH" { set brakes to true. }

until false {
  InitTerminal("Welcome to the " + ship:name + " kOS autpilot!").

  if ship:status = "PRELAUNCH" { SequenceMenu(launch_delegates, launch_labels, 30). }
  else { SequenceMenu(orbit_delegates, orbit_labels). }

  IdleScreen().
}
