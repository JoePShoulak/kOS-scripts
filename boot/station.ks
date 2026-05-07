// boot: station.ks

runOncePath("0:/common/util.ks").
runOncePath("0:/common/menu.ks").
runOncePath("0:/common/maneuvers.ks").

    // TODO: Create sequences for these
declare options is list(
  CreateOption("Tag current parts", { for part in ship:parts { set part:tag to "station". } }),
  CreateOption("Transfer resources in", { TransferAllResourcesByTag("", "station"). }),
  CreateOption("Transfer resources out", { TransferAllResourcesByTag("station", ""). }),
  CreateOption("Correct orbit", {
    declare estimate_inrecement is 10000.
    declare target_alt is round(ship:orbit:semimajoraxis/estimate_inrecement)*estimate_inrecement.

    ChangeAPAtPE(target_alt).
    ChangePEAtAP(target_alt).
  }),
  CreateOption("Exit", {})
).

dummy().

// main
until false {
  InitTerminal("Welcome to " + ship:name + "! Your home away from home.").

  SequenceMenu(options).

  IdleScreen().
}
