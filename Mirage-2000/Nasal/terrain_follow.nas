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



#This is done for detecting a terrain between aircraft and target. Since 2017.2.1, a new method allow to do the same, faster, and with more precision. (See isNotBehindTerrain function)
var versionString = getprop("sim/version/flightgear");
var version = split(".", versionString);
var major = num(version[0]);
var minor = num(version[1]);
var pica  = num(version[2]);
var pickingMethod = 0;
if ((major == 2017 and minor == 2 and pica >= 1) or (major == 2017 and minor > 2) or major > 2017) {
    pickingMethod = 1;
}

var myPos = nil;
var xyz = nil;
var dir = nil;
var v = nil;
var distance_Target = nil;
var terrain = geo.Coord.new();



setprop ("instrumentation/tfs/delay-sec", 4);

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
    var altitude_m = getprop ("position/altitude-ft") * FT2M;
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
        #If there is terrain between target alt, we increase it by 100 feet. until there is no more terrain
        target_pos.set_alt(target_altitude_m);
        while(check_terrain_avoiding(target_pos)!=nil){
          #print(target_altitude_m);
          target_altitude_m = target_altitude_m + 30;
          target_pos.set_alt(target_altitude_m);   
        }
        
        setprop("instrumentation/tfs/ground-altitude-ft",
            target_altitude_m * M2FT);
        setprop("instrumentation/tfs/malfunction", 0);
    }

    #settimer (tfs_radar, 0.1);
}
#settimer (tfs_radar, 0.1);

var check_terrain_avoiding = func(coord){
  if(pickingMethod != 1){return nil;}
  #We check that there is no terrain between our aircraft and our futur target altitude
  myPos = geo.aircraft_position();
  xyz = {"x":myPos.x(),                  "y":myPos.y(),                 "z":myPos.z()};
  dir = {"x":coord.x()-myPos.x(),  "y":coord.y()-myPos.y(), "z":coord.z()-myPos.z()};
  
  distance_Target = myPos.direct_distance_to(coord);

  # Check for terrain between own aircraft and other:
  v = get_cart_ground_intersection(xyz, dir);
  if(v ==nil){return v;}

  terrain.set_latlon(v.lat, v.lon, v.elevation);
  if(myPos.direct_distance_to(terrain)>distance_Target){
      return nil;
  }else{return 1;}    
 
}












