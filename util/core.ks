// util.ks

runOncePath("0:/common/stats.ks").

// TODO: Double check there's nothing else to review / improve here
// TODO: Clean up and organize ALL of this

/////////////
// UTILITY //
/////////////



function WaitForSeconds {
  parameter seconds.

  declare local init_time is time:seconds().
  wait until time:seconds() > init_time + seconds.
}

// INIT TERMINAL: 
//   Clears and brings up the kOS Terminal in-game
function InitTerminal {
  parameter greeting is "".

  CLEARSCREEN.
  CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
  set terminal:width to 100.

  if greeting:length { print greeting. }
}

function DistanceToTarget {
  return (target:position - ship:position):mag.
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

function WaitForHours {
  parameter hours.

  return {
    parameter index.

    return lexicon(
      "init", { Sequence(index, "Wait for contract requirment", SEQ["IDLE"]). },
      "exec", {
        Sequence(index, "Wait for contract requirment - Waiting for " + hours + " hours...").
        set warp to 0.
        set warpmode to "rails".
        wait 5. warpTo(time:seconds + hours * 60 * 60).
        wait until warp = 0.
        wait until kuniverse:timewarp:issettled().
        wait 3.
        Sequence(index, "Wait for contract requirment - Waiting complete!", SEQ["COMPLETE"]).
      }
    ).
  }.
}

function ClearLine {
  parameter line.

  PRINT " ":padright(terminal:width) AT (0,line).
}

function TransferResourceByTag {
  parameter res, from_tag, to_tag.

  return {
    parameter index.

    return lexicon(
      "init", { Sequence(index, "Transfer " + res, SEQ["IDLE"]). },
      "exec", {
        Sequence(index, "Transfer " + res + " - Transfering..."). 
        set t to TransferAll(res, ship:partstagged(from_tag), ship:partstagged(to_tag)).
        set t:active to true.
        wait until t:status = "Failed" or t:status = "Finished".
        if t:message:contains("connected") { Sequence(index, "Transfer " + res + " - No source/destination!", SEQ["COMPLETE"]). }
        else if t:message:contains("Transferred") { Sequence(index, "Transfer " + res + " - Transfer complete!", SEQ["COMPLETE"]). }
        else { Sequence(index, "Transfer " + res + " - Unknown error!", SEQ["COMPLETE"]). } // TODO: Add SEQ:ERROR ?
      }
    ).
  }.
}

// TODO: Redo this with elements
function TransferAllResourcesByTag {
  parameter from_tag, to_tag.

  declare transfer_list is list().

  for res in ship:resources { 
    if res:name = "ElectricCharge" {} 
    else { transfer_list:add(TransferResourceByTag(res:name, from_tag, to_tag)). }
  }

  return transfer_list.
}

function AltitudeAt {
  parameter alt_time.

  Kerbin:altitudeof(positionAt(ship, alt_time)).
}

function TernarySearch {
  parameter f, left, right, absolute_precision.

  until false {
    if abs(right-left) < absolute_precision {
      return (left+right)/2.
    }

    local left_third is left + (right-left)/3.
    local right_third is right - (right-left)/3.

    if f(left_third) < f(right_third) {
      set left to left_third.
    } else {
      set right to right_third.
    }
  }
}

function ApoapsisTime {
  parameter mnv.

  local apoapsis_time is TernarySearch(
    AltitudeAt@,
    time:seconds + mnv:eta,
    time:seconds + mnv:eta + (mnv:orbit:period / 2),
    1
  ).

  return apoapsis_time.
}

function InSunlight {
  parameter object.

  SET sun_pos TO BODY("SUN"):POSITION.
  SET obj_pos TO object:POSITION.
  SET body_center TO BODY("KERBIN"):POSITION. // Or use SHIP:BODY:POSITION

  SET v_obj_to_sun TO sun_pos - obj_pos.
  SET v_obj_to_body TO body_center - obj_pos.

  return vang(v_obj_to_sun, -v_obj_to_body) < 90.
}

function FlattenList {
  parameter bulky_list.

  declare new_list is list().

  for li in bulky_list {
    if li:typename = "list" {
      until li:length = 0{
        new_list:add(li[0]).
        li:remove(0).
      }
    } else {
      new_list:add(li).
    }
  }

  return new_list.
}

function PitchFor {
  parameter ves is ship.

  local pointing is ves:facing:forevector.

  return 90 - vang(ves:up:vector, pointing).
}

function FitLine {
  parameter x1, y1, x2, y2.
  parameter extrapolate is false.

  declare max_y is max(y1, y2).
  declare min_y is min(y1, y2).

  declare m is (y2-y1)/(x2-x1).

  if extrapolate {
    return { parameter x. return m * (x - x1) + y1. }.
  } else {
    return { parameter x. return min(max_y, max(min_y, m * (x - x1) + y1)). }.
  }
}

function FitQuadratic {
  parameter x1, y1, x2, y2, x3, y3. 

    declare a is y1/((x1-x2)*(x1-x3)) + y2/((x2-x1)*(x2-x3)) + y3/((x3-x1)*(x3-x2)).

    declare b is (-y1*(x2+x3)/((x1-x2)*(x1-x3))
         -y2*(x1+x3)/((x2-x1)*(x2-x3))
         -y3*(x1+x2)/((x3-x1)*(x3-x2))).

    declare c is (y1*x2*x3/((x1-x2)*(x1-x3))
        +y2*x1*x3/((x2-x1)*(x2-x3))
        +y3*x1*x2/((x3-x1)*(x3-x2))).

    return { parameter x. return a*x^2 + b*x + c. }.
}

function CalculatePhaseAngle {
  parameter object.

  declare ship_vec is ship:position - ship:body:position.
  declare obj_vec is object:position - object:body:position.
  declare phase_angle is vang(ship_vec, obj_vec).

  declare force_vec TO VXCL(ship_vec, SHIP:VELOCITY:ORBIT).
  declare is_ahead TO 0 < VDOT(obj_vec, force_vec).

  if is_ahead { set phase_angle to 360 - phase_angle. } 

  return phase_angle.
}

// 30x30 icon centered on screen
// padright is a function that lets you add spaces to the right until the paraeter length is reached
function DrawAsciiArt {
  parameter iterator.

  local lines is list().
  until not iterator:next() {
    lines:add(iterator:value()).
  }

  // Get max line length (for centering purposes)
  local max_len is 0.
  for line in lines {
    if line:length > max_len {
      set max_len to line:length.
    }
  }

  local y is (terminal:height - lines:length) / 2.
  local x is (terminal:width - max_len) / 2.
  for line in lines {
    print line at (x, y).
    set y to y + 1.
  }
}

function GetAsciiArtIterator {
  parameter name.

  return archive:open("/ascii_art/" + name + ".txt"):readall:iterator.
}

function IdleScreen {
  parameter delegate is {}.
  clearScreen.

  // TODO: Find more/better art
  if ship:type = "STATION" { DrawAsciiArt(GetAsciiArtIterator("station")). }
  else if ship:status = "PRELAUNCH" { DrawAsciiArt(GetAsciiArtIterator("rocket_prelaunch")). }
  else { DrawAsciiArt(GetAsciiArtIterator("rocket")). }

  PRINT "Press any button to continue":padright(100) at(0,0).
  until terminal:input:haschar() { {IdleStats(). delegate(). } }
  terminal:input:clear().
}
