// rendevous.ks

runOncePath("0:/common/util.ks").

function Rendezvous {
  parameter tgt.

  set target to tgt.

  declare dir is "".

  if target:obt:periapsis > ship:obt:periapsis {
    // Circularize("PERIAPSIS").
    set dir to "rising".
  } else if target:orbit:apoapsis < ship:obt:apoapsis {
    // Circularize("APOAPSIS").
    set dir to "falling".
    // circ at apo, then falling
  } else if target:obt:periapsis > ship:obt:apoapsis {
    set dir to "rising".
    // rising orbit
  } else if target:obt:apoapsis < ship:obt:periapsis {
    set dir to "falling".
    // falling orbit
  } 

  PRINT "Transfer type is " + dir.
  PRINT "Time to peri: " + ship:obt:eta:periapsis.
  PRINT "Target's time to peri: " + target:obt:eta:periapsis.
}


