// menu.ks

runOncePath("0:/util/core.ks").

function CreateOption {
  parameter label.
  parameter delegate.

  return lexicon(
    "label", label,
    "delegate", delegate
  ).
}

function MenuItem {
  parameter number.
  parameter text.
  parameter selected is false.

  PRINT "[" + (choose "x" if selected else " ") + "] " + text AT(0, number+1). 
}

function DrawMenu {
  parameter options.
  parameter s is 1.

  declare n is 0.
  until n = options:length {
    MenuItem(n+1, options[n]["label"], s = n+1).
    set n to n + 1.
  }
}

function ClearMenu { // TODO: Do this better
  for line in list(2, 3, 4, 5, 6, 7, 8, 9, 10) {ClearLine(line).}
}

function SequenceMenu {
  parameter options.
  parameter timeout is -1.

  declare selection is 1.
  declare start_time is timestamp().

  DrawMenu(options).

  declare ch is "".
  until ch = terminal:input:enter or (timeout > 0 and timestamp() - start_time > timeout) {
    if terminal:input:haschar() {
      set ch to terminal:input:getchar().

      if ch = terminal:input:upcursorone { set selection to max(selection - 1, 1). }
      else if ch = terminal:input:downcursorone { set selection to min(selection + 1, options:length). }

      DrawMenu(options, selection).
    }

    declare select_message is "Make a selection using the arrow keys and enter.".
    if timeout > 0 {
      declare time_remaining is ceiling(30 - (timestamp() - start_time):seconds()).
      set select_message to select_message + " Autoselecting in " + time_remaining + "s.".
    }
    PRINT select_message AT(0, options:length+3).
  }

  ClearMenu().

  options[selection - 1]["delegate"]().
}
