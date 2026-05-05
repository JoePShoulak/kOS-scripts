// menu.ks

runOncePath("0:/common/util.ks").

function MenuItem {
  parameter number.
  parameter text.
  parameter selected is false.

  PRINT "[" + (choose "x" if selected else " ") + "] " + text AT(0, number+1). 
}

function DrawMenu {
  parameter labels.
  parameter s is 1.

  declare n is 0.
  until n = labels:length() {
    MenuItem(n+1, labels[n], s = n+1).
    set n to n + 1.
  }
}

function GetSelection {
  parameter labels.
  parameter timeout is -1.
  declare selection is 1.
  declare t is timestamp().

  DrawMenu(labels).

  declare ch is "".
  until ch = terminal:input:enter or (timeout > 0 and timestamp() - t > timeout) {
    if terminal:input:haschar() {
      set ch to terminal:input:getchar().

      if ch = terminal:input:upcursorone { set selection to max(selection - 1, 1). }
      else if ch = terminal:input:downcursorone { set selection to min(selection + 1, labels:length). }

      DrawMenu(labels, selection).
    }

    declare select_message is "Make a selection using the arrow keys and enter.".
    if timeout > 0 {
      declare time_remaining is ceiling(30 - (timestamp() - t):seconds()).
      set select_message to select_message + " Autoselecting in " + time_remaining + "s.".
    }
    PRINT select_message AT(0,labels:length+3).
  }

  ClearMenu(labels).

  return selection.
}

function ClearMenu {
  parameter labels.

  for line in list(2, 3, 4, 5, 6, 7, 8, 9, 10) {ClearLine(line).}
}

function DestinationMenu {
  parameter delegates.
  parameter labels.
  parameter timeout is -1.

  delegates[GetSelection(labels, timeout)-1](). // Call the function associated with the selection
}
