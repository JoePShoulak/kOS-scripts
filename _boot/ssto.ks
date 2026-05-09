// boot: ssto.ks

// INCLUDES
runOncePath("0:/util/core.ks").
runOncePath("0:/common/menu.ks").
runOncePath("0:/navigation/flight.ks").
runOncePath("0:/navigation/rendezvous.ks").

declare ESL is ExecuteSequenceList@.

declare launch_options is list(
  CreateOption("LKO",                     { ESL(list(SSTOToOrbit())). }),
  CreateOption("LKO - Tourism",           { ESL(list(SSTOToOrbit())). }), // TODO: Wait an hour and return
  CreateOption("Kerbin Beta",             { ESL(list(SSTOToOrbit(), Rendezvous("Kerbin Beta"), DockWithTarget())). }),
  CreateOption("Kerbin Beta - Resupply",  { ESL(list(SSTOToOrbit(), Rendezvous("Kerbin Beta"), DockWithTarget())). }), // TODO: Resupply and return home
  CreateOption("Kerbin Beta - Tourism",   { ESL(list(SSTOToOrbit(), Rendezvous("Kerbin Beta"), DockWithTarget())). }), // TODO: Wait 4 hours and return home
  CreateOption("Exit",                      IdleScreen@ ) 
).

declare orbit_options is list(
  CreateOption("Kerbal Space Center",     { ESL(ReturnToKerbin_SSTO()). }), // TODO: Return home
  CreateOption("Rendezvous with target",  { ESL(list(Rendezvous("Kerbin Beta"))). }),
  CreateOption("Dock with target",        { ESL(list(DockWithTarget())). }),
  CreateOption("Kerbin Beta",             { ESL(list(Rendezvous("Kerbin Beta"))). }),
  CreateOption("Kerbin Beta - Resupply",  { ESL(list(Rendezvous("Kerbin Beta"))). }), // TODO: Resupply and return home
  CreateOption("Kerbin Beta - Tourism",   { ESL(list(Rendezvous("Kerbin Beta"))). }), // TODO: Wait 4 hours and return home
  CreateOption("Exit",                      IdleScreen@ ) 
).

// MAIN
if ship:status = "PRELAUNCH" { set brakes to true. }
ship:partsnamedpattern("Cockpit")[0]:getmodule("ModuleCommand"):doevent("control from here").
SET SHIP:CONTROL:NEUTRALIZE to TRUE.
when altitude > 1000 then { // TODO: Remove this later. It's for in case we orbit cheat
  set gear to false.
  stage.
}

until false {
  InitTerminal("Welcome to the " + ship:name + " kOS autpilot!").

  // TODO: Large ships bouncing on the runway are tricking prelaunch
  if ship:status = "PRELAUNCH" or (altitude < 100)  { SequenceMenu(launch_options, 30). }
  else { SequenceMenu(orbit_options). }
}
