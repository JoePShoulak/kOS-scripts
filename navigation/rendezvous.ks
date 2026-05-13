// rendezvous.ks

// TODO: Double check there's nothing else to review / improve here

runOncePath("0:/navigation/maneuvers.ks").
runOncePath("0:/navigation/docking.ks").
runOncePath("0:/util/core.ks").
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
  wait until vang(ship:facing:forevector, -rvel) < 2 and ship:angularvel:mag < 0.1.
  wait 1.

  if not zero and inital_rvel:mag > 20 {
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

      // MatchVelocity(true). // TODO: Fix this

      Sequence(index, "Refine Intercept - Rendezvous complete!", SEQ["COMPLETE"]).
    }
  ).
}

// TODO: Match intercept plane
function Rendezvous {
  declare seqs is list().

  if DistanceToTarget() > 200e3 { seqs:add(Intercept@). }

  seqs:add(ReduceDistanceAndVelocity@).

  return seqs.
}

