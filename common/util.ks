// INIT TERMINAL: 
//   Clears and brings up the kOS Terminal in-game
function InitTerminal {
  parameter greeting is "".

  CLEARSCREEN.
  CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
  set terminal:width to 100.

  if greeting:length {print greeting. }
}

function ClearLine {
  parameter line.
  parameter blank_line is " ".

  until blank_line:length >= terminal:width { set blank_line to blank_line + " ". }

  PRINT blank_line AT (0,line).

  return blank_line.
}

declare global SEQ is lexicon(
  "IDLE", 0,
  "ACTIVE", 1,
  "COMPLETE", 2
).

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