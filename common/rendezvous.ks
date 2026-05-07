// rendezvous.ks

runOncePath("0:/common/maneuvers.ks").
runOncePath("0:/common/util.ks").
runOncePath("0:/common/sequence.ks").

declare target_distance is 100.

function GetRVelToTarget { return ship:velocity:orbit - target:velocity:orbit. }

// TODO: Polish this up
function MatchVelocity {
  parameter zero is false.

  lock rvel to ship:velocity:orbit - target:velocity:orbit.
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
  return list(Intercept@, ReduceDistanceAndVelocity@).
}

function AlignPorts {
  parameter index.

  return lexicon(
    "init", { Sequence(index, "Align Ports", SEQ["IDLE"]). },
    "exec", {
      wait 5.
      Sequence(index, "Align Ports - Ports Aligned!", SEQ["COMPLETE"]).
    }
  ).
}

function DockingInsertion {
  parameter index.

  return lexicon(
    "init", { Sequence(index, "Docking Insertion", SEQ["IDLE"]). },
    "exec", {
      wait 5.
      Sequence(index, "Docking Insertion - Docking Complete!", SEQ["COMPLETE"]).
    }
  ).
}

function DockWithTarget {
  return list(AlignPorts@, DockingInsertion@).
}


