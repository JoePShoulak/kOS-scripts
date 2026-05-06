runOncePath("0:/common/maneuvers.ks").
runOncePath("0:/common/util.ks").

function MatchVelocity {

}

function CloseDistance {

}

function Rendezvous {
  parameter tgt is target.
  set target to tgt.

  print "Performing Sequence: Rendezvous with " + tgt AT(0,2).

  Sequence(1, "Hohmann Transfer", SEQ["IDLE"]).
  Sequence(2, "Refine Intercept", SEQ["IDLE"]).

  wait 1.

  Sequence(1, "Hohmann Transfer - Intercepting target...").
  HohmannTransferToTarget().

  Sequence(1, "Hohmann Transfer - Matching target orbit...").
  CircularizeAtApoapsis().

  Sequence(1, "Hohman Transfer - Entered target orbit.", SEQ["COMPLETE"]).

  wait 1.

  until false { // relative velocity < 1m/s and distance < 200m
    Sequence(2, "Refine Intercept - Closing Distance...").
    lock steering to positionAt(target, time:seconds) - positionAt(ship, time:seconds).
    wait 1.
    Sequence(2, "Refine Intercept - Matching Velocity at closest intercept...").
    // TODO: Match velocity
    wait 1.
  }

  Sequence(2, "Refine Intercept - Rendezvous complete.", SEQ["COMPLETE"]).
}

function DockWithClosestVessel {

}
