
function PrintStatText {
  parameter label, text, col, row.

  declare padding is floor(terminal:width/4).
  declare start_row is terminal:height - 3.

  PRINT (label + ": " + text):padright(padding) AT(col*padding, start_row + row).
}

function PrintStatNumber {
  parameter label, value, unit, col, row.

  PrintStatText(label, round(value, 2) + unit, col, row).
}

function FlightAscentStats {
  PrintStatNumber("Speed",      ship:airspeed,      "m/s",  0, 0).
  PrintStatNumber("Altitude",   altitude/1000,      "km",   1, 0).
  PrintStatNumber("Apoapsis",   apoapsis/1000,      "km",   2, 0).
  PrintStatNumber("Thrust",     ship:thrust,        "N",    3, 0).

  PrintStatNumber("V. Speed",   ship:verticalspeed, "m/s",  0, 1).
  PrintStatNumber("q",          ship:q,             "ATM",  1, 1).
  PrintStatNumber("Periapsis",  periapsis/1000,     "km",   2, 1).
  PrintStatText("Engines",      ship:engines[0]:mode(),     3, 1).

  wait 0.001. // Since this is often a "do while waiting" task, best to add a small delay
}

function ManeuverStats {
  parameter mnv.
  parameter score is "".

  PrintStatNumber("Fuel",           ship:deltav:current,  "m/s",  0, 0).
  PrintStatNumber("ETA",            mnv:eta,              "s",    1, 0).
  if score:istype("Scalar") {
    PrintStatNumber("Score",        score,                "",     2, 0). }
  PrintStatNumber("Thrust",         ship:thrust,          "N",    3, 0).

  PrintStatNumber("dV - Total",     mnv:deltav:mag,       "m/s",  0, 1).
  PrintStatNumber("dV - Prograde",  mnv:prograde,         "m/s",  1, 1).
  PrintStatNumber("dV - Radial",    mnv:radialout,        "m/s",  2, 1).
  PrintStatNumber("dV - Normal",    mnv:normal,           "m/s",  3, 1).

  wait 0.001. // Since this is often a "do while waiting" task, best to add a small delay
}
