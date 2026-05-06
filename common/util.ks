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

declare global SEQ is lexicon(
  "IDLE", 0,
  "ACTIVE", 1,
  "COMPLETE", 2
).

// TODO: Make these lexicons so that we can have their initial data, index, and callbacks
function Sequence {
  parameter number.
  parameter text.
  parameter state is SEQ["ACTIVE"].

  local msg is "[" + (
    choose "X" if state = SEQ["COMPLETE"] else
    choose "-" if state = SEQ["ACTIVE"] else " "
  ) + "] " + number + ". " + text.
  print msg:padright(terminal:width) at(0, number + 3).
}

function ExecuteSequenceList {
  parameter sequence_func_list.

  declare sequence_list is list().

  declare i is 1.
  for seq_func in sequence_func_list {
    sequence_list:add(seq_func(i)).
    set i to i + 1.
  }

  for s in sequence_list { s["init"](). }
  wait 1.
  for s in sequence_list { s["exec"](). }

  for line in list(2, 3, 4, 5, 6, 7, 8, 9, 10) {ClearLine(line).} // TODO: Better clear
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
      if res:name = "ElectricCharge" { } 
      else { TransferResourceByTag(res:name, from_tag, to_tag). }
    }
}

function Alert {
  parameter message.

  local my_gui is GUI(200).
  local label is my_gui:addlabel(message).
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

function PhaseAngleToTarget {
  declare aShip is obt:lan+obt:argumentofperiapsis+obt:trueanomaly. //the ships angle to universal reference direction.
  declare aTarget is target:obt:lan+target:obt:argumentofperiapsis+target:obt:trueanomaly. //target angle

  declare aPhase is aTarget - aShip.
  set aPhase to aPhase - 360 * floor(aPhase/360).

  return aPhase.
}

function AltitudeAt {
  parameter t.

  Kerbin:altitudeof(positionAt(ship, t)).
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

function WaitForPhaseAngle {
  parameter angle.
  parameter tgt is target.
  set target to tgt.

  // TODO: Improve this warping. It should go a little faster, but have smoothing when close.

  until PhaseAngleToTarget() > angle and PhaseAngleToTarget() < angle+5 {set warp to 3.}
  set warp to 0.
  wait 1.
  until PhaseAngleToTarget() > angle and PhaseAngleToTarget() < angle+5 {set warp to 3.}

  set warp to 0. 
}
