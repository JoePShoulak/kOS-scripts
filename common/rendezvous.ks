// rendezvous.ks

runOncePath("0:/common/maneuvers.ks").
runOncePath("0:/common/util.ks").
runOncePath("0:/common/sequence.ks").

declare target_distance is 100.

function GetRVelToTarget { return ship:velocity:orbit - target:velocity:orbit. }

// TODO: Polish this up
function MatchVelocity {
  parameter zero is false.
  set tgt to (choose target if target:istype("Vessel") else target:ship).

  lock rvel to ship:velocity:orbit - tgt:velocity:orbit.
  declare inital_rvel is rvel.

  declare old_velocity is 2^64.

  lock steering to -rvel.
  wait until vang(ship:facing:forevector, -rvel) < 2.

  if not zero and inital_rvel:mag > 20{
    lock throttle to 1.0.
    until rvel:mag < inital_rvel:mag / 5
    or rvel:mag > old_velocity {
      wait 0.001.
      set old_velocity to rvel:mag.
    }
  }

  if not zero {
    lock throttle to 0.1.
  } else {
    set rcs to true.
    set ship:control:translation to v(0, 0, 1).
  }
  until rvel:mag < (choose 0.1 if zero else 1.0)
  or rvel:mag > old_velocity {
    wait 0.001.
    set old_velocity to rvel:mag.
  }

  lock throttle to 0.
  SET SHIP:CONTROL:NEUTRALIZE to TRUE.
  unlock throttle. 
  unlock steering. 
}

// TODO: Polish this up
function CloseDistance {
  declare tgt_pos is target:position - ship:position.
  declare intitial_distance is DistanceToTarget().

  lock steering to tgt_pos.
  wait until vang(ship:facing:forevector, tgt_pos) < 2.

  lock throttle to (choose 1.0 if DistanceToTarget > 1000 else 0.1).
  wait until GetRVelToTarget():mag > intitial_distance / 100.
  lock throttle to 0.0.

  declare old_distance is 2^64.
  lock steering to -rvel.
  until DistanceToTarget() < intitial_distance / 10
  or DistanceToTarget() > old_distance
  or DistanceToTarget() < target_distance {
    wait 0.001.
    set old_distance to DistanceToTarget().
  }
  
  lock throttle to 0.0.
  unlock throttle. 
  unlock steering. 
}

function Intercept {
  parameter index.

  return lexicon(
    "init", { Sequence(index, "Hohmann Transfer", SEQ["IDLE"]). },
    "exec", {
      Sequence(index, "Hohmann Transfer - Intercepting target...").
      HohmannTransferToTarget().

      Sequence(index, "Hohmann Transfer - Matching target orbit...").
      CircularizeAtApoapsis().

      Sequence(index, "Hohman Transfer - Entered target orbit!", SEQ["COMPLETE"]).
    }
  ).
}

function DistanceToTarget {
  return (target:position - ship:position):mag.
}

function ReduceDistanceAndVelocity {
  parameter index.

  return lexicon(
    "init", { Sequence(index, "Refine Intercept", SEQ["IDLE"]). },
    "exec", {
      Sequence(index, "Refine Intercept - Matching Velocity...").
      MatchVelocity().

      until DistanceToTarget() < target_distance { // relative velocity < 1m/s and distance < 200m
        Sequence(index, "Refine Intercept - Closing Distance...").
        CloseDistance().
        Sequence(index, "Refine Intercept - Matching Velocity...").
        MatchVelocity().
      }

      MatchVelocity(true).

      Sequence(index, "Refine Intercept - Rendezvous complete!", SEQ["COMPLETE"]).
    }
  ).
}

function Rendezvous {
  declare seqs is list().

  if DistanceToTarget() > 200000 {
    seqs:add(Intercept@).
  }
    seqs:add(ReduceDistanceAndVelocity@).

  return seqs.
}

function PrepareForDocking {
  parameter index.

  return lexicon(
    "init", { Sequence(index, "Prepare for Docking", SEQ["IDLE"]). },
    "exec", {
      // Set control point to do0cking port (and deploy if needed)
      Sequence(index, "Prepare for Docking - Setting control point...").
      DrawDockingVectors().
      set target to (choose target if target:istype("Vessel") else target:ship).

      declare port is ship:dockingports[0].
      declare docking_node_module is port:getmodule("ModuleDockingNode").
      declare animator is port:getmodule("ModuleAnimateGeneric").
      declare deploy_event is "deploy docking port". 

      set rcs to false.
      lock steering to lookDirUp(target:facing:forevector, (ship:position - target:position)).

      set init_time to timestamp().
      if animator:HasEvent(deploy_event) { animator:DoEvent(deploy_event). }
      docking_node_module:DoEvent("control from here").
      until timestamp() - init_time > 3 { wait 0.01. }.

      // Request docking port from station
      set init_time to timestamp().
      Sequence(index, "Prepare for Docking - Requesting docking port...").
      declare c is target:connection.
      c:sendmessage(port:nodetype).
      until timestamp() - init_time > 3 { wait 0.01. }.

      // TODO: Be very careful with this messaging logic
      until not ship:messages:empty { wait 0.01. }.

      if ship:messages:pop:content = "ABORT" { return. }

      // If granted, wait for station to align assigned docking port
      Sequence(index, "Prepare for Docking - Docking port granted. Awaiting presentation...").

      declare compatible_open_ports is list().
      for p in target:dockingports {
        if p:nodetype = port:nodetype and not p:haspartner { compatible_open_ports:add(p). }
      }

      // TODO: make a getclosest function
      declare closest_distance is 2^64.
      declare station_port is "".
      for p in compatible_open_ports {
        if (target:position - p:position):mag < closest_distance {
          set closest_distance to (target:position - p:position):mag.
          set station_port to p.
        }
      }

      set up_dir to target:facing:forevector.
      set target to station_port.
      lock steering to lookDirUp(target:position - port:position, -up_dir).

      until not ship:messages:empty { wait 0.01. }.
      if ship:messages:pop:content = "ABORT" { return. }

      until ship:angularVel:mag < 0.1 { wait 0.01.}.

      Sequence(index, "Prepare for Docking - Station and ship ready!", SEQ["COMPLETE"]).
    }
  ).
}

function DrawDockingVectors {
  declare port is ship:dockingports[0].

  set port_arrow to VecDraw(
    { return port:position. },
    { return port:portfacing:forevector * 5. },
    RGB(0, 0, 1),
    "Ship Port Normal",
    1.0,
    true,
    0.2,
    true,
    true
  ).

  declare target_vessel is (choose target if target:istype("Vessel") else target:ship).
  set prograde_arrow to VecDraw(
    { return port:position. },
    { return (ship:velocity:orbit - target_vessel:velocity:orbit):normalized*5. },
    RGB(0, 1, 0),
    "Ship Prograde",
    1.0,
    true,
    0.2,
    true,
    true
  ).

  set target_arrow to VecDraw(
    { return port:position. },
    { return target:position - port:position. },
    RGB(1, 0, 1),
    "Target",
    1.0,
    true,
    0.2,
    true,
    true
  ).
}

FUNCTION VectorFromPointToLine {
    PARAMETER pointPosition.      
    PARAMETER lineOriginPosition. 
    PARAMETER lineDirectionVector.

    SET normalizedLineDirection TO lineDirectionVector:NORMALIZED.
    SET originToPointVector TO pointPosition - lineOriginPosition.
    SET projectionLengthOntoLine TO VDOT(originToPointVector, normalizedLineDirection).
    SET closestPointOnLine TO lineOriginPosition + normalizedLineDirection * projectionLengthOntoLine.

    RETURN closestPointOnLine - pointPosition.
}

// TODO: Add protection to make sure we're not directly on top of or below the station
function DockingInsertion {
  parameter index.

  return lexicon(
    "init", { Sequence(index, "Docking Insertion", SEQ["IDLE"]). },
    "exec", {
      Sequence(index, "Docking Insertion - Intercepting docking vector...").

      declare port is ship:dockingports[0].


      lock rvel to ship:velocity:orbit - target:ship:velocity:orbit.
      // lock steering to lookDirUp(target:position - port:position, -up_dir).
      ship:partsnamedpattern("Cockpit")[0]:getmodule("ModuleCommand"):doevent("control from here").
      lock steering to lookDirUp(target:ship:facing:forevector, (ship:position - target:position)).
      // TODO: Turn this into a function
      wait until vang(ship:facing:forevector, target:ship:facing:forevector) < 1 and ship:angularvel:mag < 0.1.

      set RAWtoSHIP to ship:facing:inverse.
      lock target_vec_local to (target:position - ship:position) * RAWtoSHIP.
      
      set fore_pid to pidloop(20, 0.1, 30, -1, 1).

      set rcs to true.

      until target_vec_local:mag < 0.01 {
        set desired_forward_val to fore_pid:update(time:seconds, target_vec_local:z).
        set ship:control:translation to v(0, 0, -desired_forward_val).
      }

      // when dock_vec_int_vec:mag < 10 then {
      //   until rvel:mag < 0.1 { set ship:control:translation to  }
      // }

      Sequence(index, "Docking Insertion - Docking Complete!", SEQ["COMPLETE"]).
    }
  ).
}

function DockWithTarget {
  declare seq_list is list().
  ship:messages:clear().

  if (target:position - ship:position):mag > 2000 { return. }
  if (target:position - ship:position):mag > 150 { seq_list:add(ReduceDistanceAndVelocity@). }
  seq_list:add(PrepareForDocking@).
  seq_list:add(DockingInsertion@).

  return seq_list.
}
