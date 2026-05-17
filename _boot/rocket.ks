runOncePath("0:/common/menu.ks").
runOncePath("0:/common/sequence.ks").
runOncePath("0:/util/core.ks").
runOncePath("0:/navigation/autopilot_rocket.ks").

declare AP is Autopilot_rocket:init().


declare launch_options is list(
  CreateOption("LKO", AP:Launch@),
  CreateOption("LKO Tourism", AP:LKOTourism@),
  CreateOption("Kerbin Alpha", AP:KerbinAlpha@),
  CreateOption("Return Home", AP:Return@ ),
  CreateOption("Land", AP:Land@ )
).

InitTerminal("Welcome to the " + ship:name + " kOS autopilot!").

if ship:status = "PRELAUNCH" { SequenceMenu(launch_options, 5). }
else { SequenceMenu(launch_options). }
