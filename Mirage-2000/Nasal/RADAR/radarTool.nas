var RadarTool = {
  
  ##############################################################################################
  # This function will explore the proprty tree and create new contact in the raw_selection.
  ##############################################################################################
  
  get_elevation : func(lat,lon){
    #first looking if the tile is loaded
    me.local_ground_alt = geo.elevation(lat, lon);
    
    #if geo is nil, the tile is not loaded. There is no fucking way to get the ground elevation (except what I'm about to do)
    if(me.local_ground_alt == nil){
        #finding the closest navaid and take its altitude
        me.navaid_vector = findNavaidsWithinRange(lat,lon,100);
        me.local_ground_alt =   me.navaid_vector[0].elevation;
    }
    return me.local_ground_alt;
  },
  
  
  scan_update_tgt_list_func:func(){
      if(scan_update_tgt_list){
        me.temp_raw_list = me.Mp.getChildren();
        foreach(var c ; me.temp_raw_list)
        {
              # FIXME: At that time a multiplayer node may have been deleted while still
              # existing as a displayable target in the radar targets nodes.
              # FIXED, with janitor. 5H1N0B1
              var type = me.type_selector(c);
              if(c.getNode("valid") == nil or c.getNode("valid").getValue() != 1)
              {
                  continue;
              }
              
              # the 2 following line are needed : If not, it would detects our own missiles...
              # this will come soon
  #             var HaveRadarNode = c.getNode("radar");
              #print(me.check_selected_type(c));
              #if(type == "multiplayer"
              #    or (type == "tanker" and HaveRadarNode != nil)
              #    or (type == "aircraft" and me.showAI == 1)
              #    or type == "carrier"
              #    or type == "ship"
              #    or (type == "missile" and HaveRadarNode != nil))
              #
              var Tree_Name = c.getName();
              #print("folderName:" ~ c.getName());
              #print("type:" ~ type);
              
              if(me.check_selected_type(c))
              {
                  # creation of the tempo object Target
                  var u = Target.new(c,me.myTree.getPath());
                

                  folderName = c.getName();

                  #print("test : " ~ c.pathNode.getValue());
                  #print("folderName:" ~ folderName);
                  # important Shinobi:
                  # expand this so multiplayer that is on sea or ground is also set correct.
                  # also consider if doppler do not see them that they are either SURFACE or MARINE, depending on if they have alt = ~ 0
                  # notice that GROUND_TARGET is set inside Target.new().
                  u.setType(armament.AIR);
                  
                  #print("Update Type of " ~ u.get_Callsign());
                  #printf("Elevation :%f00" , me.get_elevation(u.get_Latitude(), u.get_Longitude()));
                  #print("Target Altitude:" ~u.get_altitude()*FT2M);
                  
                  #var ground_alt = geo.elevation(u.get_Latitude(), u.get_Longitude());
                  me.type_ground_alt = me.get_elevation(u.get_Latitude(), u.get_Longitude());#= ground_alt==nil?0:ground_alt;
                  
                  # We are testing if it is near the ground
                  if(me.type_ground_alt!=nil){
                    if(abs(me.type_ground_alt - u.get_altitude()*FT2M) < 60) { # in meters
                      #print("It is close to the ground");
                      me.info = geodinfo(u.get_Latitude(), u.get_Longitude());
                      if (me.info != nil and me.info[1] != nil) {
                        #print("The ground underneath the aircraft is ", me.info[1].solid == 1 ? "solid." : "water.");
                        #debug.dump(me.info);
                        if(me.info[1].solid == 1){
                          #print("SURFACE");
                          u.setType(armament.SURFACE);
                          u.skipDoppler = 0;
                        }else{
                          #print("MARINE");
                          u.setType(armament.MARINE);
                          u.skipDoppler = 1;
                        }
                      #if we can't get the geoinfo it is because the terrain didn't load. So doing a default altitude check to choose
                      }elsif(u.get_altitude()*FT2M < 10){
                          #print("MARINE");
                          u.setType(armament.MARINE);
                          u.skipDoppler = 1;
                      }else{
                          #print("SURFACE");
                          u.setType(armament.SURFACE);
                          u.skipDoppler = 0;
                      }
                    }
                  }
 
                  
                  if(u.get_type() == armament.AIR){
                  # now we test the model name to guess what type it is:
                        me.pathNode = c.getNode("sim/model/path");
                        if (me.pathNode != nil) {
                            me.path = me.pathNode.getValue();
                            me.model = split(".", split("/", me.path)[-1])[0];
                            u.set_model(me.model);#used for RCS
                        }
                        u.skipDoppler = 0;
                  }
                  
                  #Testing if ORDNANCE
                  if (c.getNode("missile") != nil and c.getNode("missile").getValue()) {
                      u.setType(armament.ORDNANCE);
                      u.skipDoppler = 0;
#                       print("missile:"~ folderName ~":"~ "armament.ORDNANCE");
                  }
                  if (c.getNode("munition") != nil and c.getNode("munition").getValue()) {
                      u.setType(armament.ORDNANCE);
#                       u.skipDoppler = 0;
#                       print("munition:" ~ folderName ~":"~ "armament.ORDNANCE");
                  }
                  #Testing Ground Target
                  if(u.get_Callsign() == "GROUND_TARGET"){
                    u.setType(armament.SURFACE);
                  }
                  #print(folderName ~ " type:" ~ u.get_type()~ " Skipping Doppler: " ~ me.skipDoppler);
#                   if(Tree_Name != "munition"){ 
#                     print("Test Important:");
                    me.update_array(u,me.raw_selection);
                    me.update_array(u,completeList);
#                   }
              }
          }
      }
      
      scan_update_tgt_list = 0;
    },
  
  
  ##############################################################################################
  # Checking if behind terrain or Not
  ##############################################################################################
  
  isNotBehindTerrain: func(SelectedObject){
        if(SelectedObject.get_Callsign()=="GROUND_TARGET"){return 1;}
        isVisible = 0;
        
        # As the script is relatively ressource consuming, then, we do a maximum of test before doing it
#         if(me.get_check())
#         {
            SelectCoord = SelectedObject.get_Coord();
            
            SelectCoord.set_alt(SelectCoord.alt()+1);
            # Because there is no terrain on earth that can be between these 2
            if(me.our_alt < 8900 and SelectCoord.alt() < 8900)
            {
              if (pickingMethod == 1) {
                  var myPos = geo.aircraft_position();

                  var xyz = {"x":myPos.x(),                  "y":myPos.y(),                 "z":myPos.z()};
                  var dir = {"x":SelectCoord.x()-myPos.x(),  "y":SelectCoord.y()-myPos.y(), "z":SelectCoord.z()-myPos.z()};

                  # Check for terrain between own aircraft and other:
                  v = get_cart_ground_intersection(xyz, dir);
                  if (v == nil) {
                    return 1;
                    #printf("No terrain, planes has clear view of each other");
                  } else {
                  var terrain = geo.Coord.new();
                  terrain.set_latlon(v.lat, v.lon, v.elevation);
                  var maxDist = myPos.direct_distance_to(SelectCoord);
                  var terrainDist = myPos.direct_distance_to(terrain);
                  if (terrainDist < maxDist-1) {
                    #print("terrain found between the planes");
                    return 0;
                  } else {
                      #print("The planes has clear view of each other");
                      return 1;
                  }
                  }
                } else {
            
            
                  # Temporary variable
                  # A (our plane) coord in meters
                  a = me.MyCoord.x();
                  b = me.MyCoord.y();
                  c = me.MyCoord.z();
                  # B (target) coord in meters
                  d = SelectCoord.x();
                  e = SelectCoord.y();
                  f = SelectCoord.z();
                  x = 0;
                  y = 0;
                  z = 0;
                  RecalculatedL = 0;
                  difa = d - a;
                  difb = e - b;
                  difc = f - c;
                  # direct Distance in meters
                  myDistance = SelectCoord.direct_distance_to(me.MyCoord);
                  Aprime = geo.Coord.new();
                  
                  # Here is to limit FPS drop on very long distance
                  L = 500;
                  if(myDistance > 50000)
                  {
                      L = myDistance / 15;
                  }
                  step = L;
                  maxLoops = int(myDistance / L);
                  
                  isVisible = 1;
                  # This loop will make travel a point between us and the target and check if there is terrain
                  for(var i = 0 ; i < maxLoops ; i += 1)
                  {
                      L = i * step;
                      K = (L * L) / (1 + (-1 / difa) * (-1 / difa) * (difb * difb + difc * difc));
                      DELTA = (-2 * a) * (-2 * a) - 4 * (a * a - K);
                      
                      if(DELTA >= 0)
                      {
                          # So 2 solutions or 0 (1 if DELTA = 0 but that 's just 2 solution in 1)
                          x1 = (-(-2 * a) + math.sqrt(DELTA)) / 2;
                          x2 = (-(-2 * a) - math.sqrt(DELTA)) / 2;
                          # So 2 y points here
                          y1 = b + (x1 - a) * (difb) / (difa);
                          y2 = b + (x2 - a) * (difb) / (difa);
                          # So 2 z points here
                          z1 = c + (x1 - a) * (difc) / (difa);
                          z2 = c + (x2 - a) * (difc) / (difa);
                          # Creation Of 2 points
                          Aprime1  = geo.Coord.new();
                          Aprime1.set_xyz(x1, y1, z1);
                          
                          Aprime2  = geo.Coord.new();
                          Aprime2.set_xyz(x2, y2, z2);
                          
                          # Here is where we choose the good
                          if(math.round((myDistance - L), 2) == math.round(Aprime1.direct_distance_to(SelectCoord), 2))
                          {
                              Aprime.set_xyz(x1, y1, z1);
                          }
                          else
                          {
                              Aprime.set_xyz(x2, y2, z2);
                          }
                          AprimeLat = Aprime.lat();
                          Aprimelon = Aprime.lon();
                          AprimeTerrainAlt = geo.elevation(AprimeLat, Aprimelon);
                          if(AprimeTerrainAlt == nil)
                          {
                              AprimeTerrainAlt = 0;
                          }
                          
                          if(AprimeTerrainAlt > Aprime.alt())
                          {
                              isVisible = 0;
                          }
                      }
                  }
                }
            }
            else
            {
                isVisible = 1;
            }
#         }
        return isVisible;
    },
    ##############################################################################################
    # Checking if the target is beyond horizon
    ##############################################################################################
    NotBeyondHorizon: func(SelectedObject){
        me.MyCoord = geo.aircraft_position();
        me.our_alt = me.MyCoord.alt();
      
      
        if(SelectedObject.get_Callsign()=="GROUND_TARGET"){return 1;}
        # if distance is beyond the earth curve
        var horizon = SelectedObject.get_horizon(me.our_alt);
        var u_rng = me.targetRange(SelectedObject);
        #print("u_rng : " ~ u_rng ~ ", Horizon : " ~ horizon);
        var InHorizon = (u_rng < horizon);
        return InHorizon;
    },

    doppler: func(SelectedObject){
      
        #if it is a radiating stuff, skip doppler
      #print("In the doppler");
      if(pylons.fcs.getSelectedWeapon() != nil){
        #print("pylons.fcs.getSelectedWeapon() != nil");
        if(pylons.fcs.getSelectedWeapon().type != "30mm Cannon"){
          #print("pylons.fcs.getSelectedWeapon().guidance:" ~pylons.fcs.getSelectedWeapon().guidance);
          if(pylons.fcs.getSelectedWeapon().guidance =="radiation"){
            #print( "Using anti radiation missile. Is target radiating :" ~ SelectedObject.isRadiating(me.MyCoord));
            if(SelectedObject.isRadiating(me.MyCoord)){
              return 1;
            }
          }
        }
      }
      
        # Test to check if the target can hide bellow us
        # Or Hide using anti doppler movements
        
        var InDoppler = 0;
        var groundNotbehind = me.isGroundNotBehind(SelectedObject);
        if(groundNotbehind)
        {
            InDoppler = 1;
        }
        if(me.HaveDoppler and (abs(SelectedObject.get_closure_rate_from_Coord(me.MyCoord)) > me.DopplerSpeedLimit))
        {
            InDoppler = 1;
        }
        if(SelectedObject.get_Callsign() == "GROUND_TARGET" or SelectedObject.check_carrier_type())
        {
            InDoppler = 1;
        }
        return InDoppler;
    },

    ##############################################################################################
    #     Checking if ground isn't behind : this is done for non doppler radar that should be blind
    #       or also a way to blind a doppler radar
    ##############################################################################################
    
    isGroundNotBehind: func(SelectedObject){

      
        var myPitch = SelectedObject.get_Elevation_from_Coord(me.MyCoord);
        var GroundNotBehind = 1; # sky is behind the target (this don't work on a valley)
        if(myPitch < 0 and me.NotBeyondHorizon(SelectedObject))
        {
            # the aircraft is bellow us, the ground could be bellow
            # Based on earth curve. Do not work with mountains
            # The script will calculate what is the ground distance for the line (us-target) to reach the ground,
            # If the earth was flat. Then the script will compare this distance to the horizon distance
            # If our distance is greater than horizon, then sky behind
            # If not, we cannot see the target unless we have a doppler radar
            var distHorizon = me.MyCoord.alt() / math.tan(abs(myPitch * D2R)) * M2NM;
            var horizon = SelectedObject.get_horizon( me.our_alt);
            var TempBool = (distHorizon > horizon);
            GroundNotBehind = (distHorizon > horizon);
        }
        return GroundNotBehind;
    },

    ##############################################################################################
    #     Checking azimuth
    ##############################################################################################
    inAzimuth: func(SelectedObject,ExceptGroundTarget = 1){
        
        if(SelectedObject.get_Callsign()=="GROUND_TARGET" and ExceptGroundTarget){return 1;}
        # Check if it's in Azimuth.
        # first we check our heading+ center az deviation + the sweep if the radar is mechanical
        tempAz = me.az_fld;
        var inMyAzimuth = 0;
        
        var myHeading = math.mod(me.fieldazCenter + me.OurHdg, 360);
        if(me.haveSweep)
        {
            myHeading = math.mod(myHeading + me.SwpMarker * (0.0844 / me.swp_diplay_width) * tempAz / 4, 360);
            mydeviation = SelectedObject.get_deviation(myHeading, me.MyCoord);
            #print("Heading:"~ myHeading ~" My deviation:"~ mydeviation);
            inMyAzimuth = (abs(mydeviation) < (tempAz / 4));
        }
        else
        {
            mydeviation = SelectedObject.get_deviation(myHeading, me.MyCoord);
            inMyAzimuth = (abs(mydeviation)<(tempAz/2));
        }
        return inMyAzimuth;
    },
    
    ##############################################################################################
    #  Don't know what this. With canvas this should be deleted
    ##############################################################################################
    #The goal of this function is to make the xml radar screen work. It is useless with Canvas
    calculateScreen: func(SelectedObject){
        # swp_diplay_width = Global
        # az_fld = Global
        # ppi_diplay_radius = Global
        
        SelectedObject.check_carrier_type();
        mydeviation = SelectedObject.get_deviation(me.OurHdg, me.MyCoord);
        #print("My Radar deviation %f", mydeviation);
        var u_rng = me.targetRange(SelectedObject);
        
        # compute mp position in our B-scan like display. (Bearing/horizontal + Range/Vertical).
        SelectedObject.set_relative_bearing(me.swp_diplay_width / me.az_fld * mydeviation,me.UseATree);
        var factor_range_radar = me.rng_diplay_width / me.rangeTab[me.rangeIndex]; # length of the distance range on the B-scan screen.
        SelectedObject.set_ddd_draw_range_nm(factor_range_radar * u_rng,me.UseATree);
        u_fading = 1;
        u_display = 1;
        
        # Compute mp position in our PPI like display.
        factor_range_radar = me.ppi_diplay_radius / me.rangeTab[me.rangeIndex]; # Length of the radius range on the PPI like screen.
        SelectedObject.set_tid_draw_range_nm(factor_range_radar * u_rng,me.UseATree);
        
        # Compute first digit of mp altitude rounded to nearest thousand. (labels).
        SelectedObject.set_rounded_alt(rounding1000(SelectedObject.get_altitude()) / 1000,me.UseATree);
        
        # Compute closure rate in Kts.
        #SelectedObject.get_closure_rate_from_Coord(me.MyCoord) * MPS2KT;
            
        # Check if u = nearest echo.
        if(SelectedObject.get_Callsign() == getprop("/ai/closest/callsign"))
        {
            #print(u.get_Callsign());
            tmp_nearest_u = SelectedObject;
            tmp_nearest_rng = u_rng;
        }
        SelectedObject.set_display(u_display, me.UseATree);
        SelectedObject.set_fading(u_fading, me.UseATree);
    },

    ##############################################################################################
    #   Checking the elevation
    ##############################################################################################
    inElevation: func(SelectedObject){
        if(SelectedObject.get_Callsign()=="GROUND_TARGET"){return 1;}
        # Moving the center of this field will be ne next option
        var tempAz = me.vt_az_fld;
        var myElevation = SelectedObject.get_total_elevation_from_Coord(me.OurPitch, me.MyCoord);
        var IsInElevation = (abs(myElevation) < (tempAz / 2));
        return IsInElevation;
    },

    ##############################################################################################
    # Checking the Range
    ##############################################################################################
    InRange: func(SelectedObject){
        if(SelectedObject.get_Callsign()=="GROUND_TARGET"){return 1;}
        # Check if it's in range
        IsInRange = 0;
        var myRange = me.targetRange(SelectedObject);
        if(myRange != 0)
        {
            #print(SelectedObject.get_Callsign() ~": Range (NM) : " ~myRange);
            IsInRange = ( myRange <= me.rangeTab[me.rangeIndex]);
        }
        return IsInRange;
    },
    
    ##############################################################################################
    # Checking the heat (n1 rotation) need improvement (like heat attenuation)
    ##############################################################################################
    heat_sensor: func(SelectedObject){
        myEngineTree = SelectedObject.get_engineTree();
        # If MP or AI has an engine tree, we will check for each engine n1>30 or rpm>1000
        if(myEngineTree != nil)
        {
            var engineList = myEngineTree.getChildren();
            foreach(var currentEngine ; engineList)
            {
                var HaveN1node = currentEngine.getNode("n1");
                var HaveRPMnode = currentEngine.getNode("rpm");
                if(HaveN1node != nil)
                {
                    n1value = HaveN1node.getValue();
                    if(n1value != nil and n1value > 30)
                    {
                        #print("N1 detected");
                        return 1;
                    }
                }
                if(HaveRPMnode != nil)
                {
                    RpMvalue = HaveRPMnode.getValue();
                    if(RpMvalue != nil and RpMvalue > 1000)
                    {
                        #print("RPM detected");
                        return 1;
                    }
                }
            }
        }
        # Here we could add a velocity test : if speed >mach 1, we can imagine that friction provides heat
    },
    

    ##############################################################################################
    #Detection of the link16 : Should allow us to see it as a friend and avoiding shooting it
    ##############################################################################################
    IsFriendlink16: func(SelectedObject){
      cs = SelectedObject.get_Callsign();
      rn = SelectedObject.get_range();
      if (getprop("link16/wingman-1")==cs or getprop("link16/wingman-2")==cs or getprop("link16/wingman-3")==cs or getprop("link16/wingman-4")==cs  or getprop("link16/wingman-5")==cs  or getprop("link16/wingman-6")==cs  or getprop("link16/wingman-7")==cs  or getprop("link16/wingman-8")==cs  or getprop("link16/wingman-9")==cs or rn > 150) {
        return 1;
      }else{
        return 0;
      }
    },
    
    ##############################################################################################
    #Transponder detection : if transponder still on, the target will be easy to detect
    ##############################################################################################
    HasTransponderOn: func(SelectedObject){
      trAct = SelectedObject.propNode.getNode("instrumentation/transponder/transmitted-id");
      rn    = SelectedObject.get_range();
      
      if(SelectedObject.propNode.getName() != "multiplayer" and rn < 55) {
        return 1;#non MP always has transponder on.
      } elsif (trAct != nil and trAct.getValue() != -9999 and rn < 55) { 
        return 1; # transponder on
      }else{
        return 0;
      }
    },
    
    targetRange: func(SelectedObject){
      me.MyCoord = geo.aircraft_position();
        # This is a way to shortcurt the issue that some of node have : in-range =0
        # So by giving the second fucntion our coord, we just have to calculate it
        var myRange = 0;
#         myRange = SelectedObject.get_range();
#         if(myRange == 0)
#         {
            myRange = SelectedObject.get_range_from_Coord(me.MyCoord);
            #print("Pouet");
#         }
        #print("targetRange : " ~ SelectedObject.get_Callsign() ~" longitude : " ~ SelectedObject.get_Longitude() ~ " latitude : " ~ SelectedObject.get_Latitude() ~" result="~myRange);
        return myRange;
    },
    
    targetBearing: func(SelectedObject){
        # This is a way to shortcurt the issue that some of node have : bearing =0
        # So by giving the second fucntion our coord, we just have to calculate it
        var myBearing = 0;
        myBearing = SelectedObject.get_bearing();
        if(myBearing == 0)
        {
            myBearing = SelectedObject.get_bearing_from_Coord(me.MyCoord);
        }
        return myBearing;
    },
    TargetWhichRadarAzimut: func(SelectedObject){
      if(SelectedObject.type == armament.SURFACE or SelectedObject.type == armament.MARINE) {
        return 180;    
      }else{
        return 60;     
      }
    }
}
