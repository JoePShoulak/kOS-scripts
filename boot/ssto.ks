// boot: ssto.ks

// INCLUDES
runOncePath("0:/common/util.ks").
runOncePath("0:/common/menu.ks").
runOncePath("0:/common/flight.ks").
runOncePath("0:/common/rendezvous.ks").

declare launch_options is list(
  CreateOption("LKO",                       SSTOToOrbit@),
  CreateOption("LKO - Tourism",             SSTOToOrbit@), // TODO: Wait an hour and return
  CreateOption("Kerbin Alpha",              { SSTOToOrbit(). Rendezvous("Kerbin Alpha"). DockWithClosestVessel(). }),
  CreateOption("Kerbin Alpha - Resupply",   { SSTOToOrbit(). Rendezvous("Kerbin Alpha"). DockWithClosestVessel(). }), // TODO: Resupply and return home
  CreateOption("Kerbin Alpha - Tourism",    { SSTOToOrbit(). Rendezvous("Kerbin Alpha"). DockWithClosestVessel(). }), // TODO: Wait 4 hours and return home
  CreateOption("Exit",                      {})
).

declare orbit_options is list(
  CreateOption("Kerbal Space Center",      {}), // TODO: Return home
  CreateOption("Kerbin Alpha",             { Rendezvous("Kerbin Alpha"). DockWithClosestVessel(). }),
  CreateOption("Kerbin Alpha - Resupply",  { Rendezvous("Kerbin Alpha"). DockWithClosestVessel(). }), // TODO: Resupply and return home
  CreateOption("Kerbin Alpha - Tourism",   { Rendezvous("Kerbin Alpha"). DockWithClosestVessel(). }), // TODO: Wait 4 hours and return home
  CreateOption("Exit",                     {}) 
).

// MAIN
if ship:status = "PRELAUNCH" { set brakes to true. }

until false {
  InitTerminal("Welcome to the " + ship:name + " kOS autpilot!").

  if ship:status = "PRELAUNCH" { SequenceMenu(launch_options, 30). }
  else { SequenceMenu(orbit_options). }

  IdleScreen().
}
