// INIT TERMINAL: 
//   Clears and brings up the kOS Terminal in-game
function InitTerminal {
  CLEARSCREEN.
  CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
  set terminal:width to 100.
}

function QuickOrbit {
  set mj  to addons:mj.
  set asc to mj:ascent.

  // Basic target orbit
  set asc:desiredaltitude    to 80000.
  set asc:desiredinclination to 0.

  // Turn profile
  set asc:turnstartaltitude  to 1500.
  set asc:turnendaltitude    to 70000.
  set asc:turnendangle       to 0.
  set asc:turnshapeexponent  to 0.4.

  // Roll profile
  set asc:forceroll    to true.
  set asc:verticalroll to 0.
  set asc:turnroll     to 0.

  // // Safety limits
  // set asc:limitaoa                to true.
  // set asc:maxaoa                  to 5.
  // set asc:limitqaenabled          to true.
  // set asc:limitqa                 to 45000.
  // set asc:limittopreventoverheats to true.

  // // Autostage & fairings
  // set asc:autostage                 to true.
  // set asc:autostagelimit            to 5.
  // set asc:autostagepredelay         to 0.5.
  // set asc:autostagepostdelay        to 0.5.
  // set asc:fairingmaxdynamicpressure to 25000.
  // set asc:fairingminaltitude        to 30000.

  // QoL features
  // set asc:autodeployantennas    to true.
  // set asc:autodeploysolarpanels to true.
  // set asc:skipcircularization   to false.
  set asc:autowarp              to true.

  set asc:enabled to true.

  WAIT until ship:periapsis > 70000 and ship:thrust < 1.
  print "Congrats! we're in orbit".
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