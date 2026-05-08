// util.ks

/////////////
// DOCKING //
/////////////




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

  return {
    parameter index.

    return lexicon(
      "init", { Sequence(index, "Transfer " + res, SEQ["IDLE"]). },
      "exec", {
        Sequence(index, "Transfer " + res + " - Transfering..."). 
        set t to TransferAll(res, ship:partstagged(from_tag), ship:partstagged(to_tag)).
        set t:active to true.
        wait until t:status = "Failed" or t:status = "Finished".
        if t:message:contains("connected") { Sequence(index, "Transfer " + res + " - No source/destination!", SEQ["COMPLETE"]). }
        else if t:message:contains("Transferred") { Sequence(index, "Transfer " + res + " - Transfer complete!", SEQ["COMPLETE"]). }
        else { Sequence(index, "Transfer " + res + " - Unknown error!", SEQ["COMPLETE"]). } // TODO: Add SEQ:ERROR ?
      }
    ).
  }.
}

function TransferAllResourcesByTag {
  parameter from_tag, to_tag.

  declare transfer_list is list().

  for res in ship:resources { 
    if res:name = "ElectricCharge" {} 
    else { transfer_list:add(TransferResourceByTag(res:name, from_tag, to_tag)). }
  }

  return transfer_list.
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

// TODO: This is getting messy
function WaitForKeypress {

}

function IdleScreen {
  parameter delegate is {}.
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

  PRINT "Press any button to continue":padright(100) at(0,0).
  until terminal:input:haschar() { {IdleStats(). delegate(). } }
  terminal:input:clear().
  }
