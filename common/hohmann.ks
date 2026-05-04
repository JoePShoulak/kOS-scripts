set target to "Kerbin Alpha".
set targetAlt to target:altitude.

set mu to body:mu.
set r1 to body:radius + ship:altitude.
set r2 to body:radius + targetAlt.

set aTrans to (r1 + r2) / 2.
set transferTime to constant:pi * sqrt(aTrans^3 / mu).

set nTarget to sqrt(mu / r2^3).
set targetTravelAngle to nTarget * transferTime.
set desiredPhase to constant:pi - targetTravelAngle.
set desiredPhaseDeg to desiredPhase * 180 / constant:pi.

function getPhase {
    set shipPos to ship:position - body:position.
    set targPos to target:position - body:position.

    set unsignedPhase to vang(shipPos, targPos).

    set orbitNormal to vxcl(ship:velocity:orbit, shipPos).
    set crossDir to vxcl(shipPos, targPos).

    if vdot(crossDir, orbitNormal) < 0 {
        return 360 - unsignedPhase.
    } else {
        return unsignedPhase.
    }
}

print "Waiting for phase angle: " + round(desiredPhaseDeg, 2).

until abs(getPhase() - desiredPhaseDeg) < 0.5 {
    print "Phase: " + round(getPhase(), 2) + " / " + round(desiredPhaseDeg, 2) at (0, 10).
    wait 0.5.
}

set v1 to sqrt(mu / r1).
set vTrans1 to sqrt(mu * ((2 / r1) - (1 / aTrans))).
set dv1 to vTrans1 - v1.

set n to node(time:seconds + 30, 0, 0, dv1).
add n.

print "Node added: " + round(dv1, 2) + " m/s prograde.".
