// docking.ks

// TODO: Double check there's nothing else to review / improve here

runOncePath("0:/common/sequence.ks").

function Undock {
  parameter index.

  return lexicon(
    "init", { Sequence(index, "Undock", SEQ["IDLE"]). },
    "exec", {
      declare port is core:element:dockingports[0].

      Sequence(index, "Undock - Undocking...").
      port:undock.
      kuniverse:forceactive(core:vessel).

      wait until kuniverse:activevessel = core:vessel.
      wait 3.
      Sequence(index, "Undock - Gaining distance...").
      set rcs to true.
      set ship:control:translation to v(0,1,0). // TODO: Change this to be out from the docking port, not currently known
      wait 5.
      set rcs to false.
      SET SHIP:CONTROL:NEUTRALIZE to True.

      declare animator is port:getmodule("ModuleAnimateGeneric").
      declare deploy_event is "retract docking port". 

      if animator:HasEvent(deploy_event) { animator:DoEvent(deploy_event). }
      Sequence(index, "Undock - Undocked!", SEQ["COMPLETE"]).
    }
  ).
}
 