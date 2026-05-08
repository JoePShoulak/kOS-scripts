// boot: ssto.ks

// INCLUDES
runOncePath("0:/common/util.ks").
runOncePath("0:/common/menu.ks").
runOncePath("0:/common/flight.ks").
runOncePath("0:/common/rendezvous.ks").

declare launch_options is list(
  CreateOption("LKO", { ExecuteSequenceList(list(SSTOToOrbit())). }),
  CreateOption("LKO - Tourism", {ExecuteSequenceList(list(SSTOToOrbit())). }), // TODO: Wait an hour and return
  CreateOption("Kerbin Beta", {
    set target to "Kerbin Beta".
    ExecuteSequenceList(list(SSTOToOrbit(), Rendezvous(), DockWithTarget())).
  }),
  CreateOption("Kerbin Beta - Resupply", {
    set target to "Kerbin Beta".
    ExecuteSequenceList(list(SSTOToOrbit(), Rendezvous(), DockWithTarget())).
  }), // TODO: Resupply and return home
  CreateOption("Kerbin Beta - Tourism", {
    set target to "Kerbin Beta".
    ExecuteSequenceList(list(SSTOToOrbit(), Rendezvous(), DockWithTarget())).
  }), // TODO: Wait 4 hours and return home
  CreateOption("Exit", {})
).

declare orbit_options is list(
  CreateOption("Kerbal Space Center",      {}), // TODO: Return home
  CreateOption("Rendezvous with target", { ExecuteSequenceList(list(Rendezvous())). }),
  CreateOption("Dock with target", {
    ExecuteSequenceList(list(DockWithTarget())).
  ship:partsnamedpattern("Cockpit")[0]:getmodule("ModuleCommand"):doevent("control from here").
}),
  CreateOption("Kerbin Beta",             {
    set target to "Kerbin Beta".
    ExecuteSequenceList(list(Rendezvous())).
  }),
  CreateOption("Kerbin Beta - Resupply",  {
    set target to "Kerbin Beta".
    ExecuteSequenceList(list(Rendezvous())).
  }), // TODO: Resupply and return home
  CreateOption("Kerbin Beta - Tourism",   {
    set target to "Kerbin Beta".
    ExecuteSequenceList(list(Rendezvous())).
  }), // TODO: Wait 4 hours and return home
  CreateOption("Exit", IdleScreen@) 
).

// MAIN
if ship:status = "PRELAUNCH" { set brakes to true. }
ship:partsnamedpattern("Cockpit")[0]:getmodule("ModuleCommand"):doevent("control from here").
SET SHIP:CONTROL:NEUTRALIZE to TRUE.

until false {
  InitTerminal("Welcome to the " + ship:name + " kOS autpilot!").

  // TODO: Large ships bouncing on the runway are tricking prelaunch
  if ship:status = "PRELAUNCH" or (altitude < 100)  { SequenceMenu(launch_options, 30). }
  else { SequenceMenu(orbit_options). }
  
}
