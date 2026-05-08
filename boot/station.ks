// boot: station.ks

runOncePath("0:/common/util.ks").
runOncePath("0:/common/menu.ks").
runOncePath("0:/common/maneuvers.ks").
runOncePath("0:/common/sequence.ks").

    // TODO: Create sequences for these
declare options is list(
  // TODO: Add titles for these?
  CreateOption("Tag current parts", { for part in ship:parts { set part:tag to "station". } }),
  CreateOption("Transfer resources in", { ExecuteSequenceList(TransferAllResourcesByTag("", "station")). }),
  CreateOption("Transfer resources out", { ExecuteSequenceList(TransferAllResourcesByTag("station", "")). }),
  CreateOption("Correct orbit", {
    declare estimate_inrecement is 10000.
    declare target_alt is round(ship:orbit:semimajoraxis/estimate_inrecement)*estimate_inrecement.

    ChangeAPAtPE(target_alt).
    ChangePEAtAP(target_alt).
  }),
  CreateOption("Exit", IdleScreen@)
).

declare domelights is ship:partsnamedpattern("Domelight").

declare DSTS is lexicon(
  "VACANT", 0,
  "OCCUPIED", 1,
  "ASSIGNED", 2
).

function GetDockingLights {
  parameter port.

  declare closest_light is domelights[0].
  declare closest_distance is 2^64.
  for l in domelights:sublist(1, domelights:length-1) {
    declare d is (l:position - port:position):mag.
    if d < closest_distance {
      set closest_distance to d.
      set closest_light to l.
    }
  }

  declare docking_lights is list().
  for l in domelights {
    declare d is (l:position - port:position):mag.
    if d < closest_distance + 1 {
      docking_lights:add(l).
    }
  }

  return docking_lights.
}

function UpdateDockingLights { 
  parameter port.
  parameter dock_status.

  declare lights is GetDockingLights(port).
  // TODO: colors with kal

  for l in lights {
    declare light_module is l:GetModule("ModuleLight").
    declare event is "blink " + (choose "on" if dock_status = DSTS["ASSIGNED"] else "off").
    if light_module:HasEvent(event) { light_module:DoEvent(event). }
  }
}

// TODO: Move me
FUNCTION RotateVector {
    PARAMETER original_vec.
    PARAMETER rot_vec.
    PARAMETER thetaDeg.

    SET axis TO rot_vec:NORMALIZED.

    // kOS trig functions use degrees.
    SET c TO COS(thetaDeg).
    SET s TO SIN(thetaDeg).

    SET term1 TO original_vec * c.
    SET term2 TO VCRS(axis, original_vec) * s.
    SET term3 TO axis * VDOT(axis, original_vec) * (1 - c).

    RETURN term1 + term2 + term3.
}

// Docking a ship to a station from the station's persepctive
function Handle_Docking {
  // TODO: Go to a custom screen for this
  for port in ship:dockingports {
    UpdateDockingLights(port, 0). // FIXME
  }

  when not ship:messages:empty then {
    set received to ship:messages:pop.
    declare tgt is RECEIVED:SENDER.
    declare port_type is RECEIVED:CONTENT.

    declare compatible_open_ports is list().
    for p in ship:dockingports {
      // TODO: Make sure it's a station port too
      if p:nodetype = port_type and not p:haspartner and p:tag = "station" { compatible_open_ports:add(p). }
    }

    if compatible_open_ports:length = 0 {
      return tgt:connection:sendmessage("ABORT"). // FIXME doesn't call self
    }

    // TODO: make a getclosest function
    declare closest_distance is 2^64.
    declare port is "".
    for p in compatible_open_ports {
      if (tgt:position - p:position):mag < closest_distance {
        set closest_distance to (tgt:position - p:position):mag.
        set port to p.
      }
    }

    UpdateDockingLights(port, DSTS["ASSIGNED"]).

    tgt:connection:sendmessage("ASSIGNED").

    // port:getModule("ModuleDockingNode"):DoEvent("control from here").

    set station_port_arrow to VecDraw(
      { return port:position. },
      { return port:portfacing:forevector * 500. },
      RGB(0, 0, 1),
      "Station Port Normal",
      1.0,
      true,
      0.2,
      true,
      true
    ).

    // Rotate until assigned port faces target
    SET norm_vec TO ship:facing:forevector.

    lock ship_vec TO tgt:dockingports[0]:POSITION - PORT:POSITION.
    lock targetRadial TO (ship_vec - norm_vec * VDOT(ship_vec, norm_vec)):NORMALIZED.

    // TODO: Fix this
    LOCK STEERING TO LOOKDIRUP(ship:facing:forevector, RotateVector(targetRadial, norm_vec, 90)).

    // Wait for TODO: add failure options
    wait 5.
    WAIT UNTIL ship:angularvel:mag < 0.1.

    tgt:connection:sendmessage("READY").

    // Wait until port conected with failsafes
    wait until port:haspartner.

    // TODO: Fix the "keep pointing at target" problem
    // Cleanup
    Handle_Docking().
  }
}

Handle_Docking().
lock steering to vCrs(ship:prograde:vector, ship:position - kerbin:position).

// main
until false {
  InitTerminal("Welcome to " + ship:name + "! Your home away from home.").

  SequenceMenu(options).
}
