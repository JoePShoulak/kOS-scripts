// menu.ks

runOncePath("0:/common/util.ks").

function MenuItem {
  parameter number.
  parameter text.
  parameter selected is false.

  PRINT "[" + (choose "x" if selected else " ") + "] " + text AT(0, number+1). 
}

function AutoLaunchMenu {
  parameter launch_function.
  parameter manual_function is { shutdown. }.
  parameter launch_name is "Auto Launch.".
  parameter manual_name is "Manual Launch.".

  function DrawMenu {
    parameter s is 1.

    MenuItem(1, launch_name, s = 1).
    MenuItem(2, manual_name, s = 2).
  }

  // MAIN
  DrawMenu().

  declare selection is 1.
  declare t is timestamp().

  terminal:input:clear().

  until timestamp() - t > 30 {
    if terminal:input:haschar() {
      declare ch is terminal:input:getchar().

      if ch = terminal:input:upcursorone { set selection to 1. }
      else if ch = terminal:input:downcursorone { set selection to 2. }
      else if ch = terminal:input:enter { break. }

      DrawMenu(selection).
    }

    declare time_remaining is ceiling(30 - (timestamp() - t):seconds()).
    PRINT "Make a selection using the arrow keys and enter. Autoselecting in " + time_remaining + "s." AT(0,5).
  }

  declare bl is ClearLine(2).
  ClearLine(3, bl).
  ClearLine(5, bl).

  if selection = 1 { launch_function(). }
  else if selection = 2 { manual_function(). }
}
