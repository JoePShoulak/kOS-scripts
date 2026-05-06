// boot: station.ks

runOncePath("0:/common/util.ks").
runOncePath("0:/common/menu.ks").
runOncePath("0:/common/maneuvers.ks").

declare labels is list(
  "Tag current parts",
  "Transfer resources in",
  "Transfer resources out",
  "Correct orbit",
  "Exit"
).

function TransferResourceByTag {
  parameter res, from_tag, to_tag.

  set t to TransferAll(res, ship:partstagged(from_tag), ship:partstagged(to_tag)).
    set t:active to true.
    print " ".
    print "Transferring " + res + "...".
    wait until t:status = "Failed" or t:status = "Finished".
    if t:message:contains("connected") { print "  No source/destination.". }
    else if t:message:contains("Transferred") { print "  Transfer complete!". }
    else { print "  Unkown error.". }
}

declare delegates is list(
  { for part in ship:parts { set part:tag to "station". } }, // Tag parts
  { 
    for res in ship:resources { 
      if res:name = "ElectricCharge" { } 
      else { TransferResourceByTag(res:name, "", "station"). } }
    }, // Resources in to station
  { 
    for res in ship:resources { 
      if res:name = "ElectricCharge" { } 
      else { TransferResourceByTag(res:name, "station", ""). } }
     }, // Resources out from station
  {}, // Swap crew
  { // Correct orbit
      // Find probable correct orbit (round AP or PE to nearest hundred km)
      // Until satisfactory...
        // Change AP at PE
        // Change PE at AP
  },
  {}
).

// main
until false {
  InitTerminal("Welcome to " + ship:name + "! Your home away from home.").


  SequenceMenu(delegates, labels).

  wait 3.

  IdleScreen().
}
