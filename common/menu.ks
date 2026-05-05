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
  declare selection is 1.
  declare t is timestamp().

  DrawMenu(labels).

  declare ch is "".
  until timestamp() - t > 30 or ch = terminal:input:enter {
    if terminal:input:haschar() {
      set ch to terminal:input:getchar().

      if ch = terminal:input:upcursorone { set selection to max(selection - 1, 1). }
      else if ch = terminal:input:downcursorone { set selection to min(selection + 1, labels:length). }

      DrawMenu(labels, selection).
    }

    declare time_remaining is ceiling(30 - (timestamp() - t):seconds()).
    PRINT "Make a selection using the arrow keys and enter. Autoselecting in " + time_remaining + "s." AT(0,5).
  }

  ClearMenu(labels).

  return selection.
}

function ClearMenu {
  parameter labels.

  declare bl is ClearLine(3).
  declare n is 2.
  until n > labels:length {
    ClearLine(n+2).
    set n to n + 1.
  }
  ClearLine(n+3, bl).
}

function AutoLaunchMenu {
  parameter delegates.
  parameter labels.

  delegates[GetSelection(labels)-1](). // Call the function associated with the selection
}
