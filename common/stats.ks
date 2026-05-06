
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

function ShipMach { // TODO: Test this
  declare gamma is body:atm:adiabaticindex.
  declare molar_mass is body:atm:molarmass.
  declare temp is body:atm:altitudetemperature(ship:altitude).
  declare R_val to 8.31442618. // J/(mol*K)

  declare speed_of_sound is sqrt(gamma * R_val * temp / molar_mass).

  return ship:airspeed / speed_of_sound. 
}

function ResourceFillPercentage {
  parameter res.

  return res:amount/res:capacity*100 + "%".
}

// Flight
declare s_altitude     is CreateStat("Altitude",    { return round(altitude/1000,       2) + "km".     } ).
declare s_apoapsis     is CreateStat("Apoapsis",    { return round(apoapsis/1000,       2) + "km".     } ).
declare s_periapsis    is CreateStat("Periapsis",   { return round(periapsis/1000,      2) + "km".     } ).
declare s_air_speed    is CreateStat("Speed",       { return round(ship:airspeed,       2) + "m/s".    } ).
declare s_thrust       is CreateStat("Thrust",      { return round(ship:thrust,         2) + "N".      } ).
declare s_v_speed      is CreateStat("V. Speed",    { return round(ship:verticalspeed,  2) + "m/s".    } ).
declare s_q            is CreateStat("q",           { return round(ship:q,              2) + "ATM".    } ).
declare s_mach         is CreateStat("Mach",        { return round(ShipMach,            2).            } ).
declare s_fuel         is CreateStat("Fuel",        { return round(ship:deltav:current, 2) + "m/s".    } ).

// Maneuver
declare s_mnv_eta      is CreateStat("ETA",         { return round(nextnode:eta,        2) + "s".      } ).
declare s_nodes        is CreateStat("Nodes",       { return round(allnodes:length,     2) + "".       } ).
declare s_dv_total     is CreateStat("Speed",       { return round(nextnode:deltav:mag, 2) + "m/s".    } ).
declare s_dv_prograde  is CreateStat("Speed",       { return round(nextnode:prograde,   2) + "m/s".    } ).
declare s_dv_radial    is CreateStat("Speed",       { return round(nextnode:radialout,  2) + "m/s".    } ).
declare s_dv_normal    is CreateStat("Speed",       { return round(nextnode:normal,     2) + "m/s".    } ).

// Misc
declare s_enginemode   is CreateStat("Engines",     { return ship:engines[0]:mode.                     } ).
declare s_period       is CreateStat("Period",      { return timestamp(orbit:period):clock.            } ).

// Resources
declare s_liquidfuel   is CreateStat("L. Fuel",     { return ResourceFillPercentage("LiquidFuel").     } ).
declare s_oxidizer     is CreateStat("Oxidizer",    { return ResourceFillPercentage("Oxidizer").       } ).
declare s_fertilizer   is CreateStat("Fertilizer",  { return ResourceFillPercentage("Fertilizer").     } ).
declare s_machinery    is CreateStat("Machinery",   { return ResourceFillPercentage("Machinery").      } ).
declare s_materialkits is CreateStat("Materials",   { return ResourceFillPercentage("MaterialKits").   } ).
declare s_monoprop     is CreateStat("Monoprop",    { return ResourceFillPercentage("Monopropellant"). } ).
declare s_supplies     is CreateStat("Supplies",    { return ResourceFillPercentage("Supplies").       } ).
declare s_electricity  is CreateStat("Power",       { return ResourceFillPercentage("ElectricCharge"). } ).

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

function StationStats {
  return DrawStatPanel(
    s_liquidfuel, s_fertilizer, s_machinery, s_materialkits,
    s_oxidizer,   s_monoprop,   s_supplies,  s_electricity
  ).
}

function BaseStats { // TODO: Improve this
  return DrawStatPanel(
    s_liquidfuel, s_fertilizer, s_machinery, s_materialkits,
    s_oxidizer,   s_monoprop,   s_supplies,  s_electricity
  ).
}

function FlightStats_SSTO {
  return DrawStatPanel(
    s_air_speed,  s_altitude, s_apoapsis,  s_thrust,
    s_v_speed,    s_q,        s_periapsis, s_enginemode
  ).
}

function FlightStats {
  return DrawStatPanel(
    s_air_speed,  s_altitude, s_apoapsis,  s_thrust,
    s_v_speed,    s_q,        s_periapsis, s_mach
  ).
}

function ManeuverStats {
  return DrawStatPanel(
    s_fuel,     s_mnv_eta,     s_nodes,     s_thrust,
    s_dv_total, s_dv_prograde, s_dv_radial, s_dv_normal
  ).
}

function OrbitStats { // TODO: improve this one
  return DrawStatPanel(
    s_air_speed, s_altitude, s_apoapsis,  s_thrust,
    s_v_speed,   s_q,        s_periapsis, s_period
  ).
}

function RendezvousStats {
  // TODO: create this stat panel
}

// TODO: Fix this, have better conditional idle categories
function IdleStats {
  declare SSTO is ship:engines[0]:multimode.

  if ship:status = "Prelaunch" or ship:q > 0{ (choose FlightStats_SSTO() if SSTO else FlightStats()). }
  else if ship:type = "Station" { StationStats(). }
  else { OrbitStats(). }
}
