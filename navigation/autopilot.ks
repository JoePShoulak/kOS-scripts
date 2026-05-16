// autopilot.ks

runOncePath("0:/util/core.ks").

declare global Autopilot is lexicon(
  "default_altitude", 2500,
  "default_takeoff_speed", 60,
  "default_speed", 300,
  "default_landing_distance", 2500,

  "CreateDescentProfile", {
    parameter intitial_altitude.
    declare ksc is Waypoint("KSC").
    lock lat_err to ksc:geoposition:lat - ship:geoposition:lat.

    lock dist to (ksc:position - ship:position):mag.
    declare runway_start is Autopilot:default_landing_distance.
    declare descent_end is runway_start + 500. // meters away from runway start
    declare descent_start is intitial_altitude * 6 + descent_end.
    declare descent_target_height is 175.
    // TODO: Consider having fitline have an option to do the min/max for us
    return { parameter dist. return max(descent_target_height, min(intitial_altitude, FitLine(descent_start, intitial_altitude, descent_end, descent_target_height)(dist))). }.
  },

  "GHTR", { // Global Heading to Relative
    parameter intitial_heading.
    parameter global_heading.

    declare output is -180 + mod(global_heading - intitial_heading + 180, 360).
    if output < -180 { set output to 360 + output. } // FIXME
    return output.
  },

  "init", {
    set this to lexicon().

    // Failsafe
    // TODO: Detect more failure states
    when ship:verticalspeed < -50 and alt:radar < 1000 then { print "Bailing...". abort on. }

    // Helpers
    this:add("Heading", { return mod(360 - ship:bearing, 360). }).

    // Properties
    this:add("target_heading", this:Heading()).
    this:add("input", lexicon(
      "heading", 0,
      "pitch", 0,
      "throttle", 0
    )).

    lock throttle to this:input:throttle.

    this:add("pid", lexicon(
      "pitch", pidloop(5, 0.1, 30, -10, 10),
      "heading", pidloop(1, 0.1, 15, -5, 5),
      "throttle", pidloop(0.1, 0.01, 0.1, 0, 1),
      "update", {
        set this:input:pitch to this:pid:pitch:update(time:seconds, altitude).
        set this:input:heading to this:pid:heading:update(time:seconds, this:HeadingError()).
        set this:input:throttle to this:pid:throttle:update(time:seconds, airspeed).      
      }
    )).

    // TODO: Not sure I like this solution
    this:add("FullAuto", {
      lock steering to Heading(mod(this:Heading() + this:input:heading, 360), this:input:pitch).
    }).

    ////////////////// Steps

    // Start the plane and give it some gas
    this:add("Ignition", {
      print "Ignition...".
      set this:pid:throttle:setpoint to Autopilot:default_speed.
      set this:pid:pitch:setpoint to Autopilot:default_altitude.
      set warpmode to "physics".
      stage.
    }).

    // Get it off the ground
    this:add("Takeoff", {
      if ship:availableThrust = 0 { this:ignition(). }

      print "Takeoff...".
      set warp to 1. when alt:radar > 100 then { set warp to 3. }

      lock steering to Heading(this:Heading(), 0).
      until airspeed > Autopilot:default_takeoff_speed { this:pid:update(). }
      
      this:fullauto().
      until altitude >= this:pid:pitch:setpoint - 10 { this:pid:update(). }
    }).

    this:add("HeadingError", {
      return Autopilot:GHTR(this:target_heading, this:Heading()).
    }).

    // Changes in heading need some special attention
    // TODO: Or do they?
    this:add("ChangeHeading", {
      parameter hdg.

      print "Assuming heading of " + hdg + "...".

      set this:target_heading to hdg.

      until abs(this:HeadingError()) < 1 { this:pid:update(). }
    }).
    
    // Keep the current course for some number of minutes
    this:add("HoldForMinutes", {
      parameter minutes.

      print "Flying this course for " + minutes + " minutes...".

      declare start_time is time:seconds().
      until time:seconds > start_time + minutes*60 { this:pid:update(). }
    }).

    this:add("ApproachRunway", {
      parameter dest is "KSC".
      parameter target_speed is 100.

      print "Lining up with the runway...".

      // TODO: Classify destinations, airports, etc...
      declare ksc is Waypoint("KSC").
      lock lat_err to ksc:geoposition:lat - ship:geoposition:lat.

      declare pid_hdg is pidloop(500, 1, 100, -15, 15).
      declare input_hdg is 90.

      lock dist to (ksc:position - ship:position):mag.
      set initial_altitude to altitude.
      lock target_altitude to Autopilot:CreateDescentProfile(initial_altitude)(dist).
      
      set this:pid:pitch:setpoint to altitude.
      set this:pid:throttle:setpoint to target_speed.

      lock steering to Heading(input_hdg, this:input:pitch).

      // TODO: Find a way to make this work with this:pid:update()
      until dist < Autopilot:default_landing_distance {
        set this:pid:pitch:setpoint to target_altitude.
        set this:input:pitch to this:pid:pitch:update(time:seconds, altitude).
        set this:input:throttle to this:pid:throttle:update(time:seconds, airspeed).
        set input_hdg to 90 + pid_hdg:update(time:seconds, lat_err).
      }

      this:Land(dest).
    }).

    // TODO: Find a way to make this work with this:pid:update()
    // TODO: Test landing manually using this function (no dest)
    this:add("Land", {
      parameter dest.

      print "Landing".

      set warp to 0. 

      declare pid_hdg is pidloop(500, 1, 100, -15, 15).
      declare input_hdg is choose 90 if dest = "KSC" else this:Heading().

      set this:pid:pitch:setpoint to 0.
      set this:pid:throttle:setpoint to 50.
      until ship:status = "LANDED" {
        set this:input:pitch to this:pid:pitch:update(time:seconds, alt:radar).
        set this:input:throttle to this:pid:throttle:update(time:seconds, airspeed).
        set input_hdg to choose 90 + pid_hdg:update(time:seconds, lat_err) if dest = "KSC" else input_hdg.
        if alt:radar <= 2 { break. }
      }

      lock throttle to 0.
      lock steering to heading(90, 0).
      brakes on.
    }).

    return this.
  }
).