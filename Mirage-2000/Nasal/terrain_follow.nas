print("*** LOADING terrain_follow.nas ... ***");

# Terrain following radar

# Parameters:
# instrumentation/tfs/delay-sec: the TFS will look ahead to the
#                                position at which the plane will be
#                                in this amount of time given its
#                                current speed.
#
# Output:
# instrumentation/tfs/malfunction:          set to 1 if the ground was not found
# instrumentation/tfs/ground-altitude-ft:   measured ground altitude
#
# Note: in case of malfunction, the radar will keep reporting the last
# known altitude or 0 if that was negative (there is an issue when
# over deep sea that causes the last reported ground altitude to be a
# large negative value).

setprop ("instrumentation/tfs/delay-sec", 1.5);

var tfs_radar = func() {
    var speed_kt  = getprop("velocities/groundspeed-kt");
    var delay_sec = getprop("instrumentation/tfs/delay-sec")
                  + 0.5 * getprop("autopilot/settings/tf-mode");
    var range_m   = (speed_kt * 1852 / 3600) * delay_sec;

    var lat_deg = getprop ("position/latitude-deg");
    var lon_deg = getprop ("position/longitude-deg");
    var current_pos = geo.Coord.new().set_latlon (lat_deg, lon_deg);

    var hdg_deg = getprop ("orientation/heading-magnetic-deg");

    var target_pos = current_pos.apply_course_distance (hdg_deg, range_m);
    var target_altitude_m = geo.elevation (target_pos.lat(), target_pos.lon());

    # Avoid an issue when altitude-m is not set
    var altitude_m = getprop ("position/altitude-ft") / 3.2808;
    if(altitude_m == nil)
    {
        altitude_m = target_altitude_m;
    }

    if((target_altitude_m == nil)
        or (altitude_m - target_altitude_m > 1000))
    {
        setprop("instrumentation/tfs/ground-altitude-ft",
            math.max (0, getprop ("instrumentation/tfs/ground-altitude-ft")));
        setprop("instrumentation/tfs/malfunction", 1);
    }
    else
    {
        setprop("instrumentation/tfs/ground-altitude-ft",
            target_altitude_m * 3.2808);
        setprop("instrumentation/tfs/malfunction", 0);
    }

    #settimer (tfs_radar, 0.1);
}
#settimer (tfs_radar, 0.1);
