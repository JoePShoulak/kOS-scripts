// boot: station.ks

runOncePath("0:/common/util.ks").
runOncePath("0:/common/menu.ks").
runOncePath("0:/common/maneuvers.ks").

declare labels is list(
  "Tag current parts",
  "Transfer resources in",
  "Transfer resources out",
  "Swap Crew",
  "Correct orbit"
).

declare delegates is list(
  {}, // Tag parts
  {}, // Resources in
  {}, // Resources out
  {}, // Swap crew
  { // Correct orbit
      // Find probable correct orbit (round AP or PE to nearest hundred km)
      // Until satisfactory...
        // Change AP at PE
        // Change PE at AP
  }
).

// main
until false {
  InitTerminal("Welcome to " + ship:name + "! Your home away from home.").

  SequenceMenu(delegates, labels).

  IdleScreen().
}
