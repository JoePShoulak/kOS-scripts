runOncePath("0:/common/menu.ks").
runOncePath("0:/common/sequence.ks").
runOncePath("0:/util/core.ks").
runOncePath("0:/navigation/autopilot_rocket.ks").

declare AP is Autopilot_rocket:init().

declare launch_options is list( CreateOption("LKO Tourism", AP:LKOTourism@) ).

InitTerminal("Welcome to the " + ship:name + " kOS autopilot!").

SequenceMenu(launch_options, 5).
