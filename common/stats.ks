function FlightAscentStats {
  declare padding is floor(terminal:width/4).
  declare row is terminal:height - 3.

  PRINT ("Speed: "    + round(ship:airspeed, 2) + "m/s" ):padright(padding) at(0, row).
  PRINT ("Altitude: " + round(altitude/1000, 2) + "km"  ):padright(padding) at(padding, row).
  PRINT ("Apoapsis: " + round(apoapsis/1000, 2) + "km"  ):padright(padding) at(2*padding, row).
  PRINT ("Thrust: "   + round(ship:thrust, 2) + "N"     ):padright(padding) at(3*padding, row).

  PRINT ("V. Speed: "   + round(ship:verticalspeed, 2) + "m/s"):padright(padding) at(0, row+1).
  PRINT ("Q: "          + round(ship:q, 2) + "ATM"            ):padright(padding) at(padding, row+1).
  PRINT ("Periapsis: "  + round(periapsis/1000, 2) + "km"     ):padright(padding) at (2*padding, row+1).
  PRINT ("Engines: "    + ship:engines[0]:mode()              ):padright(padding) at (3*padding, row+1).
  wait 0.001.
}