// boot: ssto.ks

// INCLUDES
runOncePath("0:/common/util.ks").
runOncePath("0:/common/menu.ks").
runOncePath("0:/common/flight.ks").
runOncePath("0:/common/rendezvous.ks").

declare launch_options is list(
  CreateOption("LKO", { ExecuteSequenceList(list(SSTOToOrbit())). }),
  CreateOption("LKO - Tourism", {ExecuteSequenceList(list(SSTOToOrbit())). }), // TODO: Wait an hour and return
  CreateOption("Kerbin Alpha", {
    set target to "Kerbin Alpha".
    ExecuteSequenceList(list(SSTOToOrbit(), Rendezvous(), DockWithTarget())).
  }),
  CreateOption("Kerbin Alpha - Resupply", {
    set target to "Kerbin Alpha".
    ExecuteSequenceList(list(SSTOToOrbit(), Rendezvous(), DockWithTarget())).
  }), // TODO: Resupply and return home
  CreateOption("Kerbin Alpha - Tourism", {
    set target to "Kerbin Alpha".
    ExecuteSequenceList(list(SSTOToOrbit(), Rendezvous(), DockWithTarget())).
  }), // TODO: Wait 4 hours and return home
  CreateOption("Exit", {})
).

declare orbit_options is list(
  CreateOption("Kerbal Space Center",      {}), // TODO: Return home
  CreateOption("Rendezvous with target", { ExecuteSequenceList(list(Rendezvous())). }),
  CreateOption("Dock with target", { ExecuteSequenceList(list(DockWithTarget())). }),
  CreateOption("Kerbin Alpha",             {
    set target to "Kerbin Alpha".
    ExecuteSequenceList(list(Rendezvous())).
  }),
  CreateOption("Kerbin Alpha - Resupply",  {
    set target to "Kerbin Alpha".
    ExecuteSequenceList(list(Rendezvous())).
  }), // TODO: Resupply and return home
  CreateOption("Kerbin Alpha - Tourism",   {
    set target to "Kerbin Alpha".
    ExecuteSequenceList(list(Rendezvous())).
  }), // TODO: Wait 4 hours and return home
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
