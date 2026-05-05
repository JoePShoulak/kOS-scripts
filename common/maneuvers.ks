runOncePath("0:/common/maneuver_core.ks").

function Circularize {
  parameter seed_time is ship:orbit:eta:apoapsis.

  declare mnv is CreateManeuver(MetricCirc@, seed_time).

  ExecuteManeuver(mnv).
}

