
function PrintStatText {
  parameter label, text, col, row.

  declare padding is floor(terminal:width/4).
  declare start_row is terminal:height - 3.

  PRINT (label + ": " + text):padright(padding) AT(col*padding, start_row + row).
}

function CreateStat {
  parameter label, delegate.

  return lexicon(
    "label", label,
    "delegate", delegate
  ).
}

declare s_air_speed    is CreateStat("Speed",     { return round(ship:airspeed,       2) + "m/s". } ).
declare s_altitude     is CreateStat("Altitude",  { return round(altitude/1000,       2) + "km".  } ).
declare s_apoapsis     is CreateStat("Apoapsis",  { return round(apoapsis/1000,       2) + "km".  } ).
declare s_thrust       is CreateStat("Thrust",    { return round(ship:thrust,         2) + "N".   } ).
declare s_v_speed      is CreateStat("V. Speed",  { return round(ship:verticalspeed,  2) + "m/s". } ).
declare s_q            is CreateStat("q",         { return round(ship:q,              2) + "ARM". } ).
declare s_periapsis    is CreateStat("periapsis", { return round(periapsis/1000,      2) + "km".  } ).
declare s_enginemode   is CreateStat("periapsis", { return round(ship:airspeed,       2) + "m/s". } ).

declare s_fuel         is CreateStat("Fuel",      { return round(ship:deltav:current, 2) + "m/s". } ).
declare s_mnv_eta      is CreateStat("ETA",       { return round(nextnode:eta,        2) + "s".   } ).
declare s_nodes        is CreateStat("Nodes",     { return round(allnodes:length,     2) + "".    } ).
declare s_dv_total     is CreateStat("Speed",     { return round(nextnode:deltav:mag, 2) + "m/s". } ).
declare s_dv_prograde  is CreateStat("Speed",     { return round(nextnode:prograde,   2) + "m/s". } ).
declare s_dv_radial    is CreateStat("Speed",     { return round(nextnode:radialout,  2) + "m/s". } ).
declare s_dv_normal    is CreateStat("Speed",     { return round(nextnode:normal,     2) + "m/s". } ).
declare s_period       is CreateStat("Period",    { return timestamp(orbit:period).               } ).

function DrawStatPanel {
  parameter s1, s2, s3, s4, s5, s6, s7, s8.

  declare i is 0.
  declare j is 0.

  for s in list(s1, s2, s3, s4, s5, s6, s7, s8) {
    if i = 4 { set i to 0. set j to 1. }
    PrintStatText(s["label"], s["delegate"](), i, j).
    set i to i + 1.
  }
}

function SSTOStats {
  return DrawStatPanel(
    s_air_speed,  s_altitude, s_apoapsis,  s_thrust,
    s_v_speed,    s_q,        s_periapsis, s_enginemode
  ).
}

// TODO: Non-ssto plane stats

function ManeuverStats {
  return DrawStatPanel(
    s_fuel,     s_mnv_eta,     s_nodes,     s_thrust,
    s_dv_total, s_dv_prograde, s_dv_radial, s_dv_normal
  ).
}

function OrbitStats {
  return DrawStatPanel(
    s_air_speed, s_altitude, s_apoapsis,  s_thrust,
    s_v_speed,  s_q,        s_periapsis, s_period
  ).
}

function RendezvousStats {
  // TODO: create this stat panel
}

function StationStats {
  // TODO: create this stat panel
}

// TODO: Fix this, have better conditional idle categories
// SSTOStatPanel is unsafe due to modal engine check
function IdleStats {
  // if ship:status = "PRELAUNCH" { SSTOStatPanel(). } 
  // else { OrbitStats(). }

  OrbitStats().
}
