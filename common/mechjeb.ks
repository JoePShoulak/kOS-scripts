function MJQuickOrbit {
  parameter target_alt is 80000.

  set mj  to addons:mj.
  set asc to mj:ascent.

  // Basic target orbit
  set asc:desiredaltitude    to target_alt.
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
}