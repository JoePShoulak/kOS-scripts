// util.ks

/////////////
// DOCKING //
/////////////

declare domelights is ship:partsnamedpattern("Domelight").

declare DSTS is lexicon(
  "VACANT", 0,
  "OCCUPIED", 1,
  "ASSIGNED", 2
).

function GetDockingLights {
  parameter port.

  declare closest_light is domelights[0].
  declare closest_distance is 2^64.
  for l in domelights:sublist(1, domelights:length-1) {
    declare d is (l:position - port:position):mag.
    if d < closest_distance {
      set closest_distance to d.
      set closest_light to l.
    }
  }

  declare docking_lights is list().
  for l in domelights {
    declare d is (l:position - port:position):mag.
    if d < closest_distance + 1 {
      docking_lights:add(l).
    }
  }

  return docking_lights.
}

function UpdateDockingLights { 
  parameter port.
  parameter dock_status.

  declare lights is GetDockingLights(port).

  for l in lights {
    declare light_module is l:GetModule("ModuleLight").
    declare event is "blink " + (choose "on" if dock_status = DSTS["ASSIGNED"] else "off").
    if light_module:HasEvent(event) { light_module:DoEvent(event). }
  }
}


function dummy {
  declare p is ship:dockingports[0].

  UpdateDockingLights(p, DSTS["ASSIGNED"]).
}

/////////////
// UTILITY //
/////////////

// INIT TERMINAL: 
//   Clears and brings up the kOS Terminal in-game
function InitTerminal {
  parameter greeting is "".

  CLEARSCREEN.
  CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
  set terminal:width to 100.

  if greeting:length { print greeting. }
}

function ClearLine {
  parameter line.

  PRINT " ":padright(terminal:width) AT (0,line).
}

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

function TransferAllResourcesByTag {
  parameter from_tag, to_tag.

    for res in ship:resources { 
      if res:name = "ElectricCharge" {} 
      else { TransferResourceByTag(res:name, from_tag, to_tag). }
    }
}

function Alert {
  parameter message.

  local my_gui is GUI(200).
  declare label is my_gui:addlabel(message).
  SET label:STYLE:ALIGN TO "CENTER".
  SET label:STYLE:HSTRETCH TO True. // Fill horizontally
  LOCAL ok TO my_gui:ADDBUTTON("OK").
  my_gui:SHOW().

  LOCAL isDone IS FALSE.
  function myClickChecker { SET isDone TO TRUE. }
  SET ok:ONCLICK TO myClickChecker@. // This could also be an anonymous function instead.
  wait until isDone.

  my_gui:HIDE().
}

function AltitudeAt {
  parameter alt_time.

  Kerbin:altitudeof(positionAt(ship, alt_time)).
}

function TernarySearch {
  parameter f, left, right, absolute_precision.

  until false {
    if abs(right-left) < absolute_precision {
      return (left+right)/2.
    }

    local left_third is left + (right-left)/3.
    local right_third is right - (right-left)/3.

    if f(left_third) < f(right_third) {
      set left to left_third.
    } else {
      set right to right_third.
    }
  }
}

function ApoapsisTime {
  parameter mnv.

  local apoapsis_time is TernarySearch(
    AltitudeAt@,
    time:seconds + mnv:eta,
    time:seconds + mnv:eta + (mnv:orbit:period / 2),
    1
  ).

  return apoapsis_time.
}

function IdleScreen {
  clearScreen.

  // TODO: Find better art, maybe a different picture in flight, etc. 
  PRINT "             ___" AT (terminal:width/2 - 8, terminal:height/2 - 6).
  PRINT "     |     | |"   AT (terminal:width/2 - 8, terminal:height/2 - 5).
  PRINT "    / \    | |"   AT (terminal:width/2 - 8, terminal:height/2 - 4).
  PRINT "   |--o|===|-|"   AT (terminal:width/2 - 8, terminal:height/2 - 3).
  PRINT "   |---|   |K|"   AT (terminal:width/2 - 8, terminal:height/2 - 2).
  PRINT "  /     \  |S|"   AT (terminal:width/2 - 8, terminal:height/2 - 1).
  PRINT " | |     | |C|"   AT (terminal:width/2 - 8, terminal:height/2    ).
  PRINT " | |     |=| |"   AT (terminal:width/2 - 8, terminal:height/2 + 1).
  PRINT " | |     | | |"   AT (terminal:width/2 - 8, terminal:height/2 + 2).
  PRINT " |_______| |_|"   AT (terminal:width/2 - 8, terminal:height/2 + 3).
  PRINT "  |@| |@|  | |"   AT (terminal:width/2 - 8, terminal:height/2 + 4).
  PRINT "___________|_|_"  AT (terminal:width/2 - 8, terminal:height/2 + 5).

  PRINT "Press any button to continue".
  until terminal:input:haschar() { IdleStats(). }
  terminal:input:clear().
}
