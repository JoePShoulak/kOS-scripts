// boot: ssto.ks

// TODO: Double check there's nothing else to review / improve here

// INCLUDES
runOncePath("0:/util/core.ks").
runOncePath("0:/common/menu.ks").
runOncePath("0:/navigation/flight.ks").
runOncePath("0:/navigation/rendezvous.ks").
runOncePath("0:/navigation/docking.ks").

// TODO: Try to find a cleaner solution to these lists
// TODO: Something's fucked with calling the docking function and rendezvous in the same mission
declare launch_options is list(
  CreateOption("LKO",                     { Mission(SSTOToOrbit()). }),
  CreateOption("LKO - Tourism",           { Mission(list(SSTOToOrbit(), WaitForHours(1), ReturnToKerbin_SSTO())). }),
  CreateOption("Kerbin Beta",             { set target to "Kerbin Beta". Mission(list(SSTOToOrbit(), Rendezvous(), DockWithTarget() )). }),
  CreateOption("Kerbin Beta - Resupply",  { set target to "Kerbin Beta". Mission(list(SSTOToOrbit(), Rendezvous(), DockWithTarget() )). }), // TODO: Resupply and return home
  CreateOption("Kerbin Beta - Tourism",   { set target to "Kerbin Beta". Mission(list(SSTOToOrbit(), Rendezvous(), DockWithTarget() , WaitForHours(5), ReturnToKerbin_SSTO())). }),
  CreateOption("Exit",                      IdleScreen@ ) 
).

declare orbit_options is list(
  CreateOption("Kerbal Space Center",     { Mission(ReturnToKerbin_SSTO()).           }),
  CreateOption("Rendezvous with target",  { set target to "Kerbin Beta". Mission(list(Rendezvous(), DockWithTarget() )). }),
  CreateOption("Dock with target",        { set target to "Kerbin Beta". Mission(list()).          }),
  CreateOption("Kerbin Beta",             { set target to "Kerbin Beta". Mission(list(Rendezvous(), DockWithTarget() )). }),
  CreateOption("Kerbin Beta - Resupply",  { set target to "Kerbin Beta". Mission(list(Rendezvous(), DockWithTarget() )). }), // TODO: Resupply and return home
  CreateOption("Kerbin Beta - Tourism",   { set target to "Kerbin Beta". Mission(list(Rendezvous(), DockWithTarget() , WaitForHours(5), ReturnToKerbin_SSTO())). }), 
  CreateOption("Exit",                      IdleScreen@ ) 
).

// MAIN
if ship:status = "PRELAUNCH" { set brakes to true. }
SET SHIP:CONTROL:NEUTRALIZE to TRUE.

// TODO: There's some bad idle screen logic here somewhere
until false {
  InitTerminal("Welcome to the " + ship:name + " kOS autopilot!").
  
  if ship:status = "PRELAUNCH" { SequenceMenu(launch_options, 30). }
  else {
    IdleScreen().
    InitTerminal("Welcome to the " + ship:name + " kOS autpilot!").
    SequenceMenu(orbit_options).
    }
}
