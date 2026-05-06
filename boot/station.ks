// boot: station.ks

runOncePath("0:/common/util.ks").
runOncePath("0:/common/menu.ks").
runOncePath("0:/common/maneuvers.ks").

declare options is list(
  CreateOption("Tag current parts", { for part in ship:parts { set part:tag to "station". } }),
  CreateOption("Transfer resources in", { TransferAllResourcesByTag("", "station"). }),
  CreateOption("Transfer resources out", { TransferAllResourcesByTag("station", ""). }),
  CreateOption("Correct orbit", {}),
  CreateOption("Exit", {})
).

// main
until false {
  InitTerminal("Welcome to " + ship:name + "! Your home away from home.").

  SequenceMenu(options).

  wait 3.

  IdleScreen().
}
