// boot: ssto.ks

// TODO: Double check there's nothing else to review / improve here

// INCLUDES
runOncePath("0:/util/core.ks").
runOncePath("0:/common/menu.ks").
runOncePath("0:/navigation/flight.ks").
runOncePath("0:/navigation/rendezvous.ks").

// TODO: Try to find a cleaner solution to these lists
declare launch_options is list(
  CreateOption("LKO",                     { Mission(SSTOToOrbit()). }),
  CreateOption("LKO - Tourism",           { Mission(list(SSTOToOrbit(), WaitForHours(1), ReturnToKerbin_SSTO())). }),
  CreateOption("Kerbin Beta",             { Mission(list(SSTOToOrbit(), DockWithTarget("Kerbin Beta"))). }),
  CreateOption("Kerbin Beta - Resupply",  { Mission(list(SSTOToOrbit(), DockWithTarget("Kerbin Beta"))). }), // TODO: Resupply and return home
  CreateOption("Kerbin Beta - Tourism",   { Mission(list(SSTOToOrbit(), DockWithTarget("Kerbin Beta"), WaitForHours(5), ReturnToKerbin_SSTO())). }),
  CreateOption("Exit",                      IdleScreen@ ) 
).

declare orbit_options is list(
  CreateOption("Kerbal Space Center",     { Mission(ReturnToKerbin_SSTO()).           }),
  CreateOption("Rendezvous with target",  { Mission(list(Rendezvous("Kerbin Beta"))). }),
  CreateOption("Dock with target",        { Mission(list(DockWithTarget())).          }),
  CreateOption("Kerbin Beta",             { Mission(list(Rendezvous("Kerbin Beta"))). }),
  CreateOption("Kerbin Beta - Resupply",  { Mission(list(DockWithTarget("Kerbin Beta"))). }), // TODO: Resupply and return home
  CreateOption("Kerbin Beta - Tourism",   { Mission(list(DockWithTarget("Kerbin Beta"), WaitForHours(5), ReturnToKerbin_SSTO())). }), 
  CreateOption("Exit",                      IdleScreen@ ) 
).

// MAIN
if ship:status = "PRELAUNCH" { set brakes to true. }
SET SHIP:CONTROL:NEUTRALIZE to TRUE.

until false {
  InitTerminal("Welcome to the " + ship:name + " kOS autopilot!").
  
  if ship:status = "PRELAUNCH" { SequenceMenu(launch_options, 30). }
  else {
    IdleScreen().
    InitTerminal("Welcome to the " + ship:name + " kOS autpilot!").
    SequenceMenu(orbit_options).
    }
}
