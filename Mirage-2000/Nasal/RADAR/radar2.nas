print("*** LOADING radar2.nas ... ***");
################################################################################
#
#                        m2005-5's RADAR SETTINGS
#
################################################################################

# Radar
# Fabien BARBIER (5H1N0B1) September 2015
# inspired by Alexis Bory (xiii)

#var UPDATE_PERIOD = 0.1; # update interval for engine init() functions

var ElapsedSec        = props.globals.getNode("sim/time/elapsed-sec");

var wcs_mode          = "rws" ; # FIXME should handled as properties choice, not harcoded.
var tmp_nearest_rng   = nil;
var tmp_nearest_u     = nil;
var nearest_rng       = 0;
var nearest_u         = nil;
var missileIndex = 0;
var MytargetVariable = nil;
var completeList     = [];
var tempo            = nil;
#var LoopElapsed =0;


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
#print("Version is "~ versionString ~ " So Picking method : "~pickingMethod);

  
var weaponRadarNames = {
    # 
    # this should match weaponNames in ext_stores.nas
    # Its a list of folders inside ai/models that has weapons.
    #
    "AGM65": nil,
    "AIM-54": nil,
    "aim-7": nil,
    "aim-9": nil,
    "AIM120": nil,
    "GBU12": nil,
    "GBU16": nil,
    "MATRA-R530": nil,
    "MatraMica": nil,
    "MatraMicaIR": nil,
    "MatraR550Magic2": nil,
    "Meteor": nil,
    "R74": nil,
    "SCALP": nil,
    "SeaEagle": nil,
    "Exocet": nil,
};
listOfGroundTargetNames = ["groundvehicle"];
listOfShipNames      = ["carrier", "ship"];
listOfAIRadarEchoes  = ["multiplayer", "tanker", "aircraft", "carrier", "ship", "missile", "groundvehicle"];
listOfAIRadarEchoes2 = keys(weaponRadarNames);
listOfGroundVehicleModels = ["buk-m2", "depot", "truck", "tower", "germansemidetached1","GROUND_TARGET"];
#listOfGroundVehicleModels = ["GROUND_TARGET"];
listOfShipModels          = ["frigate", "missile_frigate", "USS-LakeChamplain", "USS-NORMANDY", "USS-OliverPerry", "USS-SanAntonio"];
# 
listOfShipModels_hash = {
  "carrier":"MARINE",
  "ship"   :"MARINE",
  "frigate":"MARINE", 
  "missile_frigate":"MARINE", 
  "USS-LakeChamplain":"MARINE", 
  "USS-NORMANDY":"MARINE", 
  "USS-OliverPerry":"MARINE", 
  "USS-SanAntonio":"MARINE",
};
listOfGroundTargetNames_hash = {
  "groundvehicle":"GROUND_TARGET",
  "buk-m2":"GROUND_TARGET",
  "depot":"GROUND_TARGET",
  "truck":"GROUND_TARGET",
  "tower":"GROUND_TARGET",
  "germansemidetached1":"GROUND_TARGET",
  "GROUND_TARGET":"GROUND_TARGET",
};
var shouldHaveRadarNodearray = ["tanker","aircraft","missile"];
#   
  
#WTF ?
foreach(var addMe ; listOfAIRadarEchoes2) {
    append(listOfAIRadarEchoes, addMe);
}

var scan_update_tgt_list = 1;
# use listeners to define when to update the radar return list.
setlistener("/ai/models/model-added", func(v){
    if (!scan_update_tgt_list) {
        scan_update_tgt_list = 1;
    }
});

setlistener("/ai/models/model-removed", func(v){
    if (!scan_update_tgt_list) {
        scan_update_tgt_list = 1;
    }
});

var extraUpdate = func {
    # need this to get targets type reevaluated once in a while.
    scan_update_tgt_list = 1;
    settimer(extraUpdate,7.5);
}
extraUpdate();

var link16_array = [];

var updatelink16 = func(){
  #print("Link16");
  link16_array = [];
  var mylink16 = props.globals.getNode("/link16");
  if(mylink16 != nil){
    var mylink16_raw_list = mylink16.getChildren();
    foreach(var callsign_Ally ; mylink16_raw_list)
    {
      append(link16_array,callsign_Ally.getValue());
      #print("Toto:"~callsign_Ally.getValue());
    }
  }
  mirage2000.myRadar3.ContactsList  = [];
  mirage2000.myRadar3.tgts_list     = [];
  mirage2000.myRadar3.Target_Index  = -1;
  #settimer(updatelink16,60);
}
#settimer(updatelink16,10);




# radar : check : InRange, inAzimuth, inElevation, NotBeyondHorizon, doppler, isNotBehindTerrain
# rwr   : check : InhisRange (radardist), inHisElevation, inHisAzimuth, NotBeyondHorizon, isNotBehindTerrain
# heat  : check : InRange, inAzimuth, inElevation, NotBeyondHorizon, heat_sensor, isNotBehindTerrain
# laser : check : InRange, inAzimuth, inElevation, NotBeyondHorizon, isNotBehindTerrain
# cam  : check : InRange, inAzimuth, inElevation, NotBeyondHorizon, isNotBehindTerrain
# transponder : check :   radar, transponderOn (not yet implemented)

#var Mp = props.globals.getNode("ai/models");

# radar class
var Radar = {
    new: func(
        NewRangeTab = nil,             # array with all the different possible range
        NewRangeIndex = nil,           # range indexshould not be greater than NewRangeTab
        NewTypeTarget = nil,           # array of different kind of object that can be seen.
        NewRadarType = nil,            # array that indicate wich type of detector we have "radar","laser",
        NewshowAI = nil,               # show or not AI. (It will be depreciated)
        NewUnfocused_az_fld = nil,     # total angle of radar
        Newfocused_az_fld = nil,       # total angle of focused radar
        NewFieldAzimuthCenter = nil,   # 0-360.For rear radar. 0 is the default value.
        NewVerticalAzimuth = nil,      # 0-180
        NewhaveSweep = nil,            # boolean 1 or 0. Has a Sweep or not 
        NewHaveDoppler = nil,          # boolean 1 or 0. Has a Doppler or not
        newDopplerSpeedLimit = nil,    # value in kts. This the min speed a doppler radar can detect. the less it is, more your doppler radar is recent and precise
        NewMyTimeLimit = nil,
        NewJanitorTime = nil,          # time a target will disapear from the radar
        NewAutoUpdate = nil,           # boolean 1 or 0. When to 1, it runs the update function in the init loop.
        NewElectricalPath = nil,       # path of the property that allow the radar to be feed by electricity
        path = nil,                    # general path of the radar. it where we should have multiple targets array, targets[0], targets[1] where the number is the number of detection means present on the aircraft
        forcePath = nil,               # force the full tree. That prevent to use targets[1] when targets[0] is existing already.
        NewSourcePath = nil)
    {
        # if we want to use a different source than AI
        var m = { parents : [Radar,RadarTool] };
        # variable that can be passed in parameters
        m.rangeTab          = (NewRangeTab == nil) ? [10, 20, 40, 60, 160] : NewRangeTab; # radar Ranges in nm
        m.rangeIndex        = (NewRangeIndex == nil) ? 0 : math.mod(NewRangeIndex, size(m.rangeTab)); # tab starts at index 1 so here it's 20
        m.HaveDoppler       = (NewHaveDoppler == nil) ? 1 : NewHaveDoppler;
        m.DopplerSpeedLimit = (newDopplerSpeedLimit == nil) ? 50 : newDopplerSpeedLimit; # in Knot
        m.MyTimeLimit       = (NewMyTimeLimit == nil) ? 2 : NewMyTimeLimit; # in seconds
        m.janitorTime       = (NewJanitorTime == nil) ? 5 : NewJanitorTime;
        m.haveSweep         = (NewhaveSweep == nil) ? 1 : NewhaveSweep;
        m.typeTarget        = (NewTypeTarget == nil) ? listOfAIRadarEchoes : NewTypeTarget;
        m.showAI            = (NewshowAI == nil) ? 1 : NewshowAI;
        m.radarHeading      = 0; # in this we fix the radar position in the nose. We will change it to make rear radar or RWR etc
        m.unfocused_az_fld  = (NewUnfocused_az_fld == nil) ? 120 : NewUnfocused_az_fld;
        m.focused_az_fld    = (Newfocused_az_fld == nil) ? 60 : Newfocused_az_fld;
        m.vt_az_fld         = (NewVerticalAzimuth == nil) ? 120 : NewVerticalAzimuth;
        m.fieldazCenter     = (NewFieldAzimuthCenter == nil) ? 0 : NewFieldAzimuthCenter;
        m.AutoUpdate        = (NewAutoUpdate == nil) ? 1 : NewAutoUpdate;
        m.ElectricalPath    = (NewElectricalPath == nil) ? "/systems/electrical/outputs/radar" : NewElectricalPath;
        m.detectionTypetab  = (NewRadarType == nil) ? "radar" : NewRadarType; # old : m.detectionTypetab = ["radar","laser"];
        m.source            = (NewSourcePath == nil) ? "ai/models" : NewSourcePath;
        m.Mp               = props.globals.getNode(m.source);
        
        #m.detectionTypeIndex = 0;
        
        # variables that need to be initialised
        m.loop_running  = 0;
        m.LoopElapsed = 0;
       
        m.MyCoord       = geo.aircraft_position(); # this is when the radar is on our own aircraft. This part have to change if we want to put the radar on a missile/AI
        m.az_fld        = m.unfocused_az_fld;
        #m.vt_az_fld     = m.az_fld;

        m.raw_selection   = [];
        # for Target Selection
        m.tgts_list       = [];
        m.ContactsList    = [];
        m.Target_Index    = -1 ; # for Target Selection
        m.Target_Callsign = nil;
        m.radarMaxSize    = 20;
        m.selectedArmament= nil; #Actually useless : The idea is to allow the radar to occult everything that is not for the current loaded weapon
        
        # source behavior
        m.OurHdg        = 0;
        m.OurPitch      = 0;
        m.our_alt       = 0;

        m.Check_List  = [];
        m.TimeWhenUpdate = 0;

        # sweep : if have no sweep, we do not have to call internal very specific properties (This is one of the last part to tune)
        m.SwpMarker         = 0;
        m.sweep_frequency   = 0;
        m.SwpDisplayWidth   = 0;
        m.PpiDisplayRadius  =0;
        m.swp_diplay_width  = 0;
        m.rng_diplay_width  = 0;
        m.ppi_diplay_radius = 0;
        m.isdeleting = 0;
        
        m.tempo_Index = 0;

        if(m.haveSweep == 1)
        {
            m.sweepProperty     = "instrumentation/radar2/sweep-marker-norm";
            m.sweep_frequency   = m.MyTimeLimit / 4; # in seconds
            m.SwpDisplayWidth   = props.globals.getNode("instrumentation/radar2/sweep-width-m");
            m.PpiDisplayRadius  = props.globals.getNode("instrumentation/radar2/radius-ppi-display-m");
            m.swp_diplay_width  = m.SwpDisplayWidth.getValue(); # length of the max azimuth  range on the screen
            m.rng_diplay_width  = m.SwpDisplayWidth.getValue(); # length of the max range vertical width on the
            m.ppi_diplay_radius = m.PpiDisplayRadius.getValue(); # length of the radial size
        }

        # separate each "targets" Properties in case of multidetection systems
        m.tree = (path == nil) ? "instrumentation/radar2/" : path;
        var n = props.globals.getNode(m.tree, 1);
        for(var i = 0 ; 1 ; i += 1)
        {
            if(n.getChild("targets", i, 0) == nil)
            {
                break;
            }
        }
        m.myTree = forcePath==nil?n.getChild("targets", i, 1):props.globals.getNode(forcePath, 1);
        m.UseATree = 1;

        #print(m.myTree.getPath());
        
        # update interval for engine init() functions
        m.updating_now = 0;
        m.UPDATE_PERIOD = 0.05; 
        
            #Some are not need there
            m.input = {
              pitch:      "/orientation/pitch-deg",
              roll:       "/orientation/roll-deg",
              hdg:        "/orientation/heading-magnetic-deg",
              hdgReal:    "/orientation/heading-deg",
              hdgBug:     "/autopilot/settings/heading-bug-deg",
              hdgDisplay: "/instrumentation/efis/mfd/true-north",
              speed_n:    "velocities/speed-north-fps",
              speed_e:    "velocities/speed-east-fps",
              speed_d:    "velocities/speed-down-fps",
              alpha:      "/orientation/alpha-deg",
              beta:       "/orientation/side-slip-deg",
              gload:      "/accelerations/pilot-g",
              ias:        "/velocities/airspeed-kt",
              mach:       "/velocities/mach",
              gs:         "/velocities/groundspeed-kt",
              vs:         "/velocities/vertical-speed-fps",
              alt:        "/position/altitude-ft",
              alt_instru: "/instrumentation/altimeter/indicated-altitude-ft",
              rad_alt:    "position/altitude-agl-ft", #"/instrumentation/radar-altimeter/radar-altitude-ft",
              wow_nlg:    "/gear/gear[1]/wow",
              gearPos:    "/gear/gear[1]/position-norm",
              airspeed:   "/velocities/airspeed-kt",
              target_spd: "/autopilot/settings/target-speed-kt",
              acc:        "/fdm/jsbsim/accelerations/udot-ft_sec2",
              acc_yas:    "/fdm/yasim/accelerations/a-x",
              NavFreq:    "/instrumentation/nav/frequencies/selected-mhz",
              destRunway: "/autopilot/route-manager/destination/runway",
              destAirport:"/autopilot/route-manager/destination/airport",
              distNextWay:"/autopilot/route-manager/wp/dist",
              NextWayNum :"/autopilot/route-manager/current-wp",
              NextWayTrueBearing:"/autopilot/route-manager/wp/true-bearing-deg",
              NextWayBearing:"/autopilot/route-manager/wp/bearing-deg",
              AutopilotStatus:"/autopilot/locks/AP-status",
              currentWp     : "/autopilot/route-manager/current-wp",
              ILS_valid     :"/instrumentation/nav/data-is-valid",
              NavHeadingRunwayILS:"/instrumentation/nav/heading-deg",
              ILS_gs_in_range :"/instrumentation/nav/gs-in-range",
              ILS_gs_deg:  "/instrumentation/nav/gs-direct-deg",
              NavHeadingNeedleDeflectionILS:"/instrumentation/nav/heading-needle-deflection-norm",
              MasterArm      :"/controls/armament/master-arm",
              TimeToTarget   :"/sim/dialog/groundtTargeting/time-to-target",
              AbsoluteElapsedtime : "sim/time/elapsed-sec",
            };
    
            foreach(var name; keys(m.input))
              m.input[name] = props.globals.getNode(m.input[name], 1);
        
        
        
        # return our new object
        return m;
    },

    ############### LOOP MANAGEMENT ##################
    # creates an engine update loop (optional)
    ##################################################
    init: func(){
        if(me.loop_running)
        {
            return;
        }
        me.loop_running = 1;
        
        # init Radar Distance
        
        # launch only On time : this is an auto updated loop.
        if(me.haveSweep == 1)
        {
            me.maj_sweep();
        }

        var loop_Update = func() {
            
            #rwr stuff
            if (rwr.rwr != nil) {
              if (size(rwrList)>0) {
                rwr.rwr.update(rwrList,"normal");
              } else {
                rwr.rwr.update(rwrList16,"normal");
              }
            }  
            
            var radarWorking = getprop(me.ElectricalPath);
            radarWorking = (radarWorking == nil) ? 0 : radarWorking;
            if(radarWorking > 24 and me.AutoUpdate)
            {
              setprop("sim/multiplay/generic/int[2]",0);
              #me.update();
              #These line bellow are error management.
              var UpdateErr = [];
#                 print("Calling radar");
              call(me.scan_update_tgt_list_func,[],me,nil,UpdateErr);
              
              call(me.update,[],me,nil,UpdateErr);
              if(size(UpdateErr) > 0)
              {
                print("We have Radar update Errors, but radar still running");
                foreach(var myErrors ; UpdateErr)
                {
                  print(myErrors);
                }
              }
#                 print("Radar refreshing done");
            }else{
              setprop("sim/multiplay/generic/int[2]",1);
              me.ContactsList  = [];
              me.tgts_list     = [];
              me.Target_Index    = -1;
            }
            #me.Global_janitor();
            
            # RWR launch
            RWR_APG.run();
            
            if(me.isdeleting == 0){settimer(loop_Update, me.UPDATE_PERIOD)};
        };
        if(me.isdeleting == 0){settimer(loop_Update, me.UPDATE_PERIOD)};

        var loop_Sweep = func() {
            if(me.haveSweep ==1){me.maj_sweep();}
            settimer(loop_Sweep, 0.05);
        };
        if(me.isdeleting == 0){settimer(loop_Sweep,0.05);}
    },
    
    delete: func(){
      me.AutoUpdate = 0;
      me.isdeleting = 1;
      tmp_nearest_rng   = nil;
      tmp_nearest_u     = nil;
      nearest_rng       = 0;
      nearest_u         = nil;
      missileIndex = 0;
      MytargetVariable = nil;
      completeList     = [];
      me.ContactsList  = [];
      
      
      #rwr Stuff
      rwrList   = [];
      rwrList16 = [];
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
                  me.skipDoppler = 0;
                  # now we test the property folder name to guess what type it is:
                  #Should be done with an hash
                  if(listOfShipModels_hash[folderName] != nil and u.get_altitude()<100){
                    #print(folderName ~":Not Marine");
                    u.setType(armament.MARINE);
                    me.skipDoppler = 1;
                  }

                  #If not MARINE skipDoppler still == 0
                  if(listOfGroundTargetNames_hash[folderName] != nil){
                    u.setType(armament.SURFACE);
                    me.skipDoppler = 0;
                  }
                  
                  if(u.get_type() == 0){
                  # now we test the model name to guess what type it is:
                        me.pathNode = c.getNode("sim/model/path");
                        if (me.pathNode != nil) {
                            me.path = me.pathNode.getValue();
                            me.model = split(".", split("/", me.path)[-1])[0];
                            u.set_model(me.model);#used for RCS
                            
                            if(listOfShipModels_hash[me.model] != nil and u.get_altitude()<100){
                              # Its a ship, Mirage ground radar will pick it up
                              u.setType(armament.MARINE);
                              me.skipDoppler = 1;
                            }            

                            if(listOfGroundTargetNames_hash[me.model] != nil){
                              # its a ground vehicle, Mirage ground radar will not pick it up
                              u.setType(armament.SURFACE);
                              me.skipDoppler = 0;
                            }
                        }
                  }
                  #Testing if ORDNANCE
                  if (c.getNode("missile") != nil and c.getNode("missile").getValue()) {
                      u.setType(armament.ORDNANCE);
                      me.skipDoppler = 0;
#                       print("missile:"~ folderName ~":"~ "armament.ORDNANCE");
                  }
                  if (c.getNode("munition") != nil and c.getNode("munition").getValue()) {
                      u.setType(armament.ORDNANCE);
                      me.skipDoppler = 0;
#                       print("munition:" ~ folderName ~":"~ "armament.ORDNANCE");
                  }
                  #Testing Ground Target
                  if(u.get_Callsign() == "GROUND_TARGET"){
                    u.setType(armament.SURFACE);
                  }
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
    
    
    ############
    #  UPDATE  #
    ############
    
    
    ## How the radar should work : 
    ## 1 - use the tree via getNode
    ## 2 - ARRAY1 : Stock contact in an array. This array should never be deleted and contact never be removed from it.
    ## 3 - ARRAY1 : Update this array (new coord etc all data of the contact), and above all, update if "Display" or not.
    ## 4 - ARRAY2 : Stock only "Display" Contact. This array can be tempo and contact can/have to be REMOVED once it is not "Display"
    ## 5 - ARRAY3 : Stock Contact contact that can be targeted. Contact must not be deleted. (in case of a firing missile, the contact stocked here is the 
    #       one that is updated. If we lose this contact, we cannont have action on the missile anymore (lost of the contact or anything else)
    ## 6 - ARRAY3 : Update this array (new coord etc all data of the contact), and above all, update if "Display" or not.
    ## 7 - ARRAY4 : Stock and update array with "Display" target. <-This is for target selection. Unavailable Target => must be REMOVED
    ## 8 - ARRAY5 : Stock and update selected Target. Put the tag Painted on it. (Use an array here allow multiple selection and firing all the target in the same time)
    
    ## Schematic : 
    ##   PROPERTY TREE                "Display"
    ##        =============> ARRAY1  =========> ARRAY2
    ##                          |
    ##                          | Target stock          "Display"
    ##                            =============>ARRAY3 ==========> ARRAY4
    ##                                            |
    ##                                            |   Painted/selected
    ##                                             ====================> ARRAY5
    
    ## STOCRAGE ARRAY :     functions : add, update
    ##  ARRAY1, ARRAY3
    ##
    ## DIPLAY ARRAY :       functions : add, update, remove
    ##  ARRAY2, ARRAY4, ARRAY5
    
    ## Simplification : Only use ARRAY1, ARRAY2 and ARRAY5
    
    
    
    update: func(tempCoord = nil, tempHeading = nil, tempPitch = nil) {
      

        #Double Run prevention
        if(me.updating_now == 1){return;}else{me.updating_now = 1;}
        
        #Interval calculation
        me.LoopElapsed = me.input.AbsoluteElapsedtime.getValue() - me.TimeWhenUpdate;
        # This is to know when was the last time we called the update
        me.TimeWhenUpdate = me.input.AbsoluteElapsedtime.getValue();
        
        
        # First update Coord, Alt, heeading and Pitch. 
        # The code pout the aircraft properties if nothing has been passed in parameters
        # Coord update ! Should be filled with altitude
        if(tempCoord == nil){me.MyCoord = geo.aircraft_position();}else{me.MyCoord = tempCoord;}

        # Altitude update (in meters)
        me.our_alt = me.MyCoord.alt();
        
        # Heading Update (should be the airplane heading, not the radar look direction)
        if(tempHeading == nil){me.OurHdg = me.input.hdgReal.getValue();}else{me.OurHdg = tempHeading;}
        
        # Pitch Update (should be the airplane heading, not the radar look direction)
        if(tempPitch == nil){me.OurPitch = me.input.pitch.getValue();}else{me.OurPitch = tempPitch;}
        # Variable initialized
        
        # This is the return array. Made First for Canvas, but can be usefull to a lot of other things
#         var CANVASARRAY = [];
        
        #This is the missile index. It is reset on each loop.
        me.missileIndex = 0;
        
#         var raw_list = me.Mp.getChildren();
        foreach(me.update_u  ; me.raw_selection)
        {
           
 

                
                #print("Start Testing "~ u.get_Callsign()~"Type: " ~ u.type);
                
                              
                # set Check_List to void
                me.Check_List = [];
                # this function do all the checks and put all result of each
                # test on an array[] named Check_List

                me.go_check(me.update_u, me.skipDoppler);
                
                #print("Complete liste after update : " ~ size(completeList));
                #me.decrease_life(completeList);
                #me.sorting_and_suppr(completeList);
                
                #Displaying Check
                #print("Testing "~ u.get_Callsign()~"Check: " ~ me.get_check());
                
                #print("End Testing "~ u.get_Callsign());
                
                # then a function just check it all
                if(me.get_check() and me.update_u.isValid())
                {
                                        
                    #Is in Range : Should be added to the main ARRAY1 (Here : ContactsList)
#                     var HaveRadarNode = c.getNode("radar");

                    #Update ContactList : Only updated when target is valid
                    #Should return an Index, in order to take the object from the table and not the property tree
                    
                    if(me.UseATree){
                      me.update_u.create_tree(me.MyCoord, me.OurHdg);
                      me.update_u.set_all(me.MyCoord);
                      me.calculateScreen(me.update_u);
                    }
                    
                    #print("Update contactList");
#                     me.ContactsList = 
                    me.update_array(me.update_u,me.ContactsList);
                    #me.tempo_Index = me.find_index_inArray(u,me.ContactsList);
                    #me.ContactsList[me.tempo_Index].set_display(1);
                    me.update_u.set_display(1);
                    
                    #if(me.tempo_Index != nil){ u = me.ContactsList[me.tempo_Index];}
                    
                    
                    # for Target Selection
                    # here we disable the capacity of targeting a missile. But 's possible.
                    # CANVASARRAY => ARRAY2
                    
                    
                    #print("isFriend :" ~ u.isFriend());
                    if(me.update_u.get_type != armament.ORDNANCE and !contains(weaponRadarNames, me.update_u.get_Callsign) and !me.update_u.isFriend())
                    {
                        #tgts_list => ARRAY4
                        
#                       print("Update targetList" ~ u.get_Callsign());
                        
                        me.TargetList_Update(me.update_u);
                        me.TargetList_AddingTarget(me.update_u);
                        
                        #We should UPDATE tgts_list here
                        

                        if(size(me.tgts_list)>me.Target_Index){
                          #This shouldn't be here. See how to delete it
                          if(me.update_u.getUnique() == me.tgts_list[me.Target_Index].getUnique() and me.update_u.getUnique() == me.Target_Callsign){
                            #print("Picasso painting");
                            me.update_u.setPainted(1);
                            armament.contact = me.tgts_list[me.Target_Index];
                            #print(armament.contact.get_type());
                          }
                        }else{
                          me.next_Target_Index();
                        }
                    }
#                     append(CANVASARRAY, u); 
                    me.displayTarget();
                }
                else
                {
                    #me.tempo_Index = me.find_index_inArray(u,me.ContactsList);
                    #if(me.tempo_Index != nil){me.ContactsList[me.tempo_Index].set_display(1,me.myTree);}
                  
                 #Here we shouldn't see the target anymore. It should disapear. So this is calling the Tempo_Janitor      
                    if(me.update_u.get_Validity() == 1)
                    {
                        if(me.input.AbsoluteElapsedtime.getValue() - me.update_u.get_TimeLast() > me.MyTimeLimit)
                        {
                          me.Tempo_janitor(me.update_u);
                        }
                    }
                    
                }    
#                 completeList = me.update_array_no_life_reset(u,completeList);
            }
            #Temporary adding this in order to make the whole new firesystem work
            #print("Update completeList");
            
#             if(u.get_Callsign() == "GROUND_TARGET"){
#               if(me.inAzimuth(u,0) == 0){
#                 u.set_display(0,me.myTree);
#               }else{
#                 u.set_display(1,me.myTree);
#               }
#             }
            
            
        #For Each End
                
        me.ContactsList = me.decrease_life(me.ContactsList);
        #print("Test");
        #me.sorting_and_suppr(me.ContactsList);
        #me.ContactsList = me.cut_array(me.radarMaxSize,me.ContactsList);
        #me.Global_janitor();
        #print("Side in RADAR : "~ size(me.ContactsList));
        #foreach(contact;me.ContactsList){
        #  print("Last Check : " ~ contact.get_Callsign() ~" 's life : "~ contact.life);
        #}

        #print("size(completeList) : " ~size(completeList) ~ "; size(me.ContactsList) : " ~ size(me.ContactsList));
        me.updating_now = 0;
        

        
#         return CANVASARRAY;
    },
    


    
    maj_sweep: func(){
        var x = (getprop("sim/time/elapsed-sec") / (me.sweep_frequency)) * (0.0844 / me.swp_diplay_width); # shorten the period time when illuminating a target
        #print("SINUS (X) = "~math.sin(x);
        me.SwpMarker = (math.sin(3.14 * x) * (me.swp_diplay_width / 0.0844)); # shorten the period amplitude when illuminating
        setprop(me.sweepProperty,me.SwpMarker);
    },


    TargetList_Update: func(SelectedObject){
      forindex(i; me.tgts_list){
        #print("Target list update");
        if(me.tgts_list[i].get_Callsign()==SelectedObject.get_Callsign()){
          me.tgts_list[i].update(SelectedObject);
          return i;
        }
      }
      return nil;
    },
    
    
    TargetList_AddingTarget: func(SelectedObject){
        # This is selectioned target management.
        if(me.TargetList_LookingForATarget(SelectedObject) == 0)
        {
            append(me.tgts_list, SelectedObject);
        }
    },

    TargetList_RemovingTarget: func(SelectedObject){
        # This is selectioned target management.
        if(me.TargetList_LookingForATarget(SelectedObject) > 5)
        {
            # Then kill it
            var TempoTgts_list = [];
            foreach(var TempTarget ; me.tgts_list)
            {
                if(TempTarget.get_shortring() != SelectedObject.get_shortring())
                {
                    append(TempoTgts_list, TempTarget);
                }else{
                  #TempTarget.setPainted(0);
                }
            }
            #me.tgts_list = TempoTgts_list;
        }
    },

    TargetList_LookingForATarget: func(SelectedObject){
        # This is selectioned target management.
        # Target list janitor
        foreach(var TempTarget ; me.tgts_list)
        {
            if(TempTarget.get_shortring() == SelectedObject.get_shortring())
            {
                return TempTarget.get_TimeLast();
            }
        }
        return 0;
    },

    get_check: func(){
        # This function allow to display multi check
        me.checked = 1;
        me.CheckTable = ["InRange:", "inAzimuth:", "inElevation:", "Horizon:", "RCS","Doppler:", "NotBtBehindTerrain:"];
        var i = 0;
        foreach(myCheck ; me.Check_List)
        {
            if(i<size(me.CheckTable)){
              #print("i : "~ i ~"|" ~ me.CheckTable[i] ~ " " ~ myCheck);
            }else{
              #print("i : "~ i ~"|myCheck : " ~ myCheck);
            }
            i +=1;
            me.checked = (myCheck and me.checked);
        }
        return me.checked;
    },
    #function in order to make it work with unified missile method in FG
    type_selector: func(SelectedObject){
        me.type_selector_selectedType = SelectedObject.getName();
        
        #Overwrite selectedType if missile
        me.type_selector_TestIfMissileNode = SelectedObject.getNode("missile");
        if(me.type_selector_TestIfMissileNode != nil) {
          if(me.type_selector_TestIfMissileNode.getValue()){
            #print("It is a missile");
            me.type_selector_selectedType = "missile";
          }
        }
    
        return me.type_selector_selectedType;
    },
    check_selected_type: func(SelectedObject)
    {
      me.check_selected_type_result = 0;
      #Variable for the selection Type test
      me.check_selected_type_selectedType = SelectedObject.getName();
      

      me.check_selected_type_selectedType = me.type_selector(SelectedObject);

      #print("MY type  IS  : "~selectedType);

      #variable for the RadarNode test
      var shouldHaveRadarNode = ["tanker","aircraft","missile"];
      var HaveRadarNode = SelectedObject.getNode("radar");

      #We test the type of target
      foreach(myType;me.typeTarget)
      {
        if(myType == me.check_selected_type_selectedType){
           me.check_selected_type_result = 1;
        }
      }

      #We test if they have a radar Node (they should all have one, but unconventionnal model like ATC or else could have these issue)
      foreach(myType;shouldHaveRadarNode)
      {
        if(myType == me.check_selected_type_selectedType and HaveRadarNode == nil){
          me.check_selected_type_result = 0;
        }
      }

      return me.check_selected_type_result;
    },

    go_check: func(SelectedObject, skipDoppler){
        #if radar : check : InRange, inAzimuth, inElevation, NotBeyondHorizon, doppler, isNotBehindTerrain
        #if Rwr   : check : InhisRange (radardist), inHisElevation, inHisAzimuth, NotBeyondHorizon, isNotBehindTerrain
        #if heat  : check : InRange, inAzimuth, inElevation, NotBeyondHorizon, heat_sensor, isNotBehindTerrain
        #if laser : check : InRange, inAzimuth, inElevation, NotBeyondHorizon, isNotBehindTerrain
        #if cam  : check : InRange, inAzimuth, inElevation, NotBeyondHorizon, isNotBehindTerrain
        # Need to add the fonction flare_sensivity : is there flare near aircraft and should we get fooled by it
    
        append(me.Check_List, me.InRange(SelectedObject));
        if(me.Check_List[0] == 0)
        {
            return;
        }
        append(me.Check_List, me.inAzimuth(SelectedObject));
        if(me.Check_List[1] == 0)
        {
            return;
        }
        append(me.Check_List, me.inElevation(SelectedObject));
        if(me.Check_List[2] == 0)
        {
            return;
        }
        append(me.Check_List, me.NotBeyondHorizon(SelectedObject));
        if(me.Check_List[3] == 0)
        {
            return;
        }
        append(me.Check_List, rcs.inRadarRange(SelectedObject, 60, 3.2));# Radar RDY: 60 NM for 3.2 RCS
        if(me.Check_List[4] == 0)
        {
            return;
        }
        #me.heat_sensor(SelectedObject);
        if( me.detectionTypetab=="laser" or skipDoppler == 1)
        {
          #print("Skip Doppler");
          append(me.Check_List, 1);
         }else{
          append(me.Check_List, me.doppler(SelectedObject));
         }
        if(me.Check_List[5] == 0)
        {
            return;
        }
        
        # Has to be last coz it will call the get_checked function
        append(me.Check_List, me.isNotBehindTerrain(SelectedObject));
    },

    Tempo_janitor:func(SelectedObject){
        SelectedObject.set_nill();
        me.TargetList_RemovingTarget(SelectedObject);
    },
    
    Global_janitor: func(){
        #Action on tree. Too complicated. has to be corrected or removed
        # This function is made to remove all persistent non relevant data on radar2 tree
        #var myRadarNode = props.globals.getNode("instrumentation/radar2/targets", 1);
        var raw_list = me.myTree.getChildren();
        foreach(var Tempo_TgtsFiles ; raw_list)
        {
            #print(Tempo_TgtsFiles.getName());
            if(Tempo_TgtsFiles.getNode("display", 1).getValue() != nil)
            {
                var myTime = Tempo_TgtsFiles.getNode("closure-last-time", 1);
                if(getprop("sim/time/elapsed-sec") - myTime.getValue() > me.janitorTime)
                {
                    var Property_list = Tempo_TgtsFiles.getChildren();
                    foreach(var myProperty ; Property_list )
                    {
                        #print(myProperty.getName());
                        if(myProperty.getName() != "closure-last-time")
                        {
                            myProperty.setValue("");
                        }
                    }
                }
            }
        }
    },
    #increase radar distance
    switch_distance_ics: func(){
        me.rangeIndex = math.mod(me.rangeIndex + 1, size(me.rangeTab));
    },
    #decrease radar distance
    switch_distance_dcs: func(){
        me.rangeIndex = math.mod(me.rangeIndex - 1, size(me.rangeTab));
    },
    #get radar distance
    get_radar_distance: func(){
        return me.rangeTab[me.rangeIndex];
    },
    
    radar_mode_toggle: func(){
        # FIXME: Modes props should provide their own data instead of being hardcoded.
        # Toggles between the available modes.
        foreach(var n ; props.globals.getNode("instrumentation/radar/mode").getChildren())
        {
            if(n.getBoolValue())
            {
                wcs_mode = n.getName();
            }
        }
        if(wcs_mode == "rws")
        {
            setprop("instrumentation/radar/mode/rws", 0);
            setprop("instrumentation/radar/mode/tws-auto", 1);
            wcs_mode = "tws-auto";
            me.az_fld=me.focused_az_fld;
            me.vt_az_fld=me.focused_az_fld;
            me.swp_diplay_width = 0.0422;
            #me.tgts_list = [];
        }
        elsif(wcs_mode == "tws-auto")
        {
            setprop("instrumentation/radar/mode/tws-auto", 0);
            setprop("instrumentation/radar/mode/rws", 1);
            wcs_mode = "pulse-srch";
            me.az_fld=me.unfocused_az_fld;
            me.vt_az_fld=me.unfocused_az_fld;
            me.swp_diplay_width = 0.0844;
        }
        me.displayTarget();
        return me.az_fld;
    },

    next_Target_Index_Old: func(){
      if(me.az_fld == me.focused_az_fld){  
      if (size(me.tgts_list) > 0) {me.tgts_list[me.Target_Index].setPainted(0);}
        me.Target_Index = me.Target_Index + 1;
        if(me.Target_Index > (size(me.tgts_list)-1))
        {
            me.Target_Index = 0;
        }
        if (size(me.tgts_list) > 0) {
        
          ###  Verification of each valid elements
          var tempo = 0;
          foreach(tgts;me.tgts_list){
            tempo = tgts.get_display()==1?tempo+1:tempo;
          }
          if(tempo ==0){
            me.Target_Index = 0;
            me.Target_Callsign = nil;
            setprop("/ai/closest/range", 0);
            return;
          }
          
          if(me.tgts_list[me.Target_Index].get_display()!=1){
            me.next_Target_Index();
          }
          
          me.Target_Callsign = me.tgts_list[me.Target_Index].getUnique();
          me.tgts_list[me.Target_Index].setPainted(1);
        } else {
          me.Target_Callsign = nil;
          return
        } 
      }
        #if(me.tgts_list[me.Target_Index].get_display()!=1){
          #me.Target_Index = me.Target_Index==0?size(me.tgts_list)-1:me.Target_Index - 1; 
          #me.next_Target_Index();
        #}
    },
    
    next_loop: func(index,factor){
      var number = 0;
      for(i=1;i<size(me.tgts_list);i = i + 1){
        number = math.mod(index + (i * factor), size(me.tgts_list));
        if(me.tgts_list[number].get_display() == 1){ return number;}
      }
      return index;
    },
    
    next_Target_Index: func(){
      if(me.az_fld == me.focused_az_fld){
        #Stuff to un paint previous target
        if (size(me.tgts_list) > 0) {me.tgts_list[me.Target_Index].setPainted(0);}
        
        #Stuff to decrease the index
        me.Target_Index = me.next_loop(me.Target_Index, 1);

        #Stuff to do with new index        
        if (size(me.tgts_list) > 0) {
          me.Target_Callsign = me.tgts_list[me.Target_Index].getUnique();
          me.tgts_list[me.Target_Index].setPainted(1);
        } else {
          me.Target_Callsign = nil;
        }
      }

    },
    
    previous_Target_Index: func(){
      if(me.az_fld == me.focused_az_fld){
        #Stuff to un paint previous target
        if (size(me.tgts_list) > 0) {me.tgts_list[me.Target_Index].setPainted(0);}
        
        #Stuff to decrease the index
        me.Target_Index = me.next_loop(me.Target_Index, -1);
        
        #Stuff to do with new index        
        if (size(me.tgts_list) > 0) {
          me.Target_Callsign = me.tgts_list[me.Target_Index].getUnique();
          me.tgts_list[me.Target_Index].setPainted(1);
        } else {
          me.Target_Callsign = nil;
        }
      }

    },

    displayTarget: func(){
        # 60 here is the illuminating or selecting cone. This has to be reworked
        # 1 To not to depend of a written value. 2 To take account that some radar do not need focus to get target
        # perhaps introduce a "selecting" target variable
        # This is very mirage specific. We should find a way to remove it
        if(size(me.tgts_list) != 0 and me.az_fld == me.focused_az_fld and me.tgts_list != nil)
        {
            if( me.Target_Index < 0)
            {
                 me.Target_Index = size(me.tgts_list) - 1;
                 me.Target_Callsign = nil;
#                  setprop("/ai/closest/range", 0);
                 return;#me.Target_Index = size(me.tgts_list) - 1;
            }
            if( me.Target_Index > size(me.tgts_list) - 1)
            {
                 me.Target_Index = 0;
                 me.Target_Callsign = nil;
#                  setprop("/ai/closest/range", 0);
                 return;#me.Target_Index = 0;
            }
            if (me.Target_Callsign != me.tgts_list[me.Target_Index].getUnique()) {
                me.Target_Callsign = nil;
                me.Target_Callsign = nil;
#                 setprop("/ai/closest/range", 0);
                return;
             }
            
            var MyTarget = me.tgts_list[ me.Target_Index];
            me.tgts_list[ me.Target_Index].setPainted(1);
            closeRange   = me.targetRange(MyTarget);
            heading      = MyTarget.get_heading();
            altitude     = MyTarget.get_altitude();
            speed        = MyTarget.get_Speed();
            callsign     = MyTarget.get_Callsign();
            longitude    = MyTarget.get_Longitude();
            latitude     = MyTarget.get_Latitude();
            bearing      = me.targetBearing(MyTarget);
            if(speed == nil)
            {
                speed = 0;
            }
            setprop("/ai/closest/range", closeRange);
            setprop("/ai/closest/bearing", bearing);
            setprop("/ai/closest/heading", heading);
            setprop("/ai/closest/altitude", altitude);
            setprop("/ai/closest/speed", speed);
            setprop("/ai/closest/callsign", callsign);
            setprop("/ai/closest/longitude", longitude);
            setprop("/ai/closest/latitude", latitude);
        }else{
            if(me.az_fld != me.focused_az_fld){
              if (size(me.tgts_list) > 0) {
                me.tgts_list[me.Target_Index].setPainted(0);
                armament.contact = nil;
              }
            }
            setprop("/ai/closest/range", 0);
        }
    },
    
    
    
    ###########################################################################
    ###   Update element of the actual diplayed array
    update_Element_of_array: func(SelectedObject,myArray){
      #print("Normal Update bellow");
      forindex(i; myArray){
        if(myArray[i].getUnique()==SelectedObject.getUnique()){
          myArray[i].update(SelectedObject);
          return myArray;
        }
      }
      return myArray;
    },
    
    ###   add element to the array
    add_Element_to_Array: func(SelectedObject,myArray){
      append(myArray,SelectedObject);
      return myArray;
    },   
    
    ###   update array : update element, or add it if there aren't present
    update_array: func(SelectedObject,myArray){
      tempo = nil;
      if(size(myArray) > 0){
        myArray = me.update_Element_of_array(SelectedObject,myArray);
        tempo = me.find_index_inArray(SelectedObject,myArray);
      }
      
      if(tempo == nil){;
        myArray = me.add_Element_to_Array(SelectedObject,myArray);
      }
      return myArray;
    },
    
    find_index_inArray: func(SelectedObject,myArray){
          forindex(i; myArray){
            #print("myArray[i].getUnique() : " ~ myArray[i].getUnique() ~" And SelectedObject.getUnique() : "~SelectedObject.getUnique());
            if(myArray[i].getUnique()==SelectedObject.getUnique()){return i;}
          }
        return nil; 
    },
    
    update_array_no_life_reset: func(SelectedObject,myArray){
      tempo = nil;
      if(size(myArray) > 0){
          #The idea is to keep the values of the variables and not reseting them
          #This way it does not impact the radar
          myIndex = me.find_index_inArray(SelectedObject,myArray);
        
        if(myIndex != nil and myArray[myIndex].Display_Node != nil){
          var mypaint = myArray[myIndex].isPainted();
          var myDisplay = myArray[myIndex].get_display();
          var myLife = myArray[myIndex].life;
        }
        
          me.update_array(SelectedObject,myArray);
          
        if(myIndex != nil and myArray[myIndex].Display_Node != nil){
          myArray[myIndex].setPainted(mypaint);
          myArray[myIndex].set_display(myDisplay, me.UseATree);
          myArray[myIndex].life = myLife;
        }
      }else{
          me.update_array(SelectedObject,myArray);
      }
      
      return myArray;
      
    },
    
    #############################################################################
    
    
    #decrease life of element. < 0 then it's not displayed anymore
    #should call a remove_element function to remove element from array
    decrease_life: func(myArray){
      var i = 0;
      foreach(contact;myArray){
        contact.life = contact.life - me.LoopElapsed;
        #print("Elapsed = " ~ me.LoopElapsed ~" Then " ~ contact.get_Callsign() ~ " 's life : "~ contact.life);
        
        if(contact.life<3){
          #print("Elapsed = " ~ me.LoopElapsed ~" Then " ~ contact.get_Callsign() ~ " 's life : "~ contact.life);
          contact.set_display(0, me.UseATree);
          contact.setPainted(0);
        }
      }
      return myArray;
    },
 
 
    #This function should sort and suppr
    sorting_and_suppr: func(myArray){
    #print("Test2 : size : " ~ size(me.ContactsList));
      for(var i=0;i<size(myArray)-1;i = i + 1){
        #print("Test3");
        for(var j=0;j<size(myArray)-1;j = j + 1){
          #print(myArray[i].get_Callsign() ~ " : " ~ myArray[i].life ~ " vs " ~ myArray[j].get_Callsign() ~ " : " ~ myArray[j].life);
          if(myArray[i].life<myArray[j].life){
            var u = myArray[i];
            myArray[i] = myArray[j];
            myArray[j] = u; 
          }
        }
      }
    },
    
    cut_array : func(ChoosenSize, Myarray){
      var tempArray = [];
      for(var i=0;i<size(Myarray)-1;i = i + 1){
        if(i>ChoosenSize){
          append(tempArray, Myarray[i]);
        }
      }
      return tempArray;
    },
    
 
    GetTarget: func(){
        if(me.tgts_list == nil)
        {
            return nil;
        }
        if(size(me.tgts_list) <= 0)
        {
            return nil;
        }
        if(me.Target_Index < 0)
        {
            return nil;#me.Target_Index = size(me.tgts_list) - 1;
        }
        if(me.Target_Index > size(me.tgts_list) - 1)
        {
            return nil;#me.Target_Index = 0;
        }
        if (me.Target_Callsign == me.tgts_list[me.Target_Index].getUnique()) {
          me.tgts_list[me.Target_Index].setPainted(1);
          return me.tgts_list[me.Target_Index];
        } else {
          me.Target_Callsign = nil;
          return nil;
        }
        #return me.tgts_list[me.Target_Index];
    },
    #toggle_Type: func(){
    #  me.detectionTypeIndex = math.mod(me.detectionTypeIndex + 1, size(me.detectionTypetab));
    #  setprop("/sim/messages/atc", "Toggle Detection Type : "~ me.detectionTypetab[me.detectionTypeIndex]);
    #},

    myRadarList : [],
};

# Utilities.
var deviation_normdeg = func(our_heading, target_bearing){
    var dev_norm = our_heading - target_bearing;
    while(dev_norm < -180)
    {
        dev_norm += 360;
    }
    while(dev_norm > 180)
    {
        dev_norm -= 360;
    }
    return(dev_norm);
}

var rounding1000 = func(n){
    var a = int(n / 1000);
    var l = (a + 0.5) * 1000;
    n = (n >= l) ? ((a + 1) * 1000) : (a * 1000);
    return(n);
}

#RWR stuff, thank to Leto
var rwrList   = [];
var rwrList16 = [];

var RWR_APG = {
#     parents : [RWR_APG,RadarTool],
    run: func () {
        me.parents = [RadarTool];
      
        rwrList = [];
        rwrList16 = [];
        me.MyCoord = geo.aircraft_position();
#         printf("clist %d", size(completeList));
        foreach(me.u;completeList) {
            me.cs = me.u.get_Callsign();
#             print("Will test  : "~ me.u.get_Callsign()~" as Type: " ~ me.u.type);
            me.rn = me.u.get_range();
            me.l16 = 0;
            if (me.u.isFriend() or me.rn > 150) {
                me.l16 = 1;
            }
            me.bearing = geo.aircraft_position().course_to(me.u.get_Coord());
            me.trAct = me.u.propNode.getNode("instrumentation/transponder/transmitted-id");
            me.show = 0;
            me.heading = me.u.get_heading();  
            me.inv_bearing =  me.bearing+180;
            me.deviation = me.inv_bearing - me.heading;
            me.dev = math.abs(geo.normdeg180(me.deviation));
            if (me.u.get_display()) {
                me.show = 1;#in radar cone
            } elsif(me.HasTransponderOn(me.u)){
              # transponder on
              me.show = 1;
            }else{
              me.rdrAct = me.u.propNode.getNode("sim/multiplay/generic/int[2]");
              
              me.rwrTargetAzimuth = me.TargetWhichRadarAzimut(me.u);
              #print(me.rwrTargetAzimuth);
              
              if (((me.rdrAct != nil and me.rdrAct.getValue()!=1) or me.rdrAct == nil) and math.abs(geo.normdeg180(me.deviation)) < me.rwrTargetAzimuth and me.NotBeyondHorizon(me.u) and me.isNotBehindTerrain(me.u) ) {
                  # we detect its radar is pointed at us and active
                  me.show = 1;
              }
            }
            if(!me.u.isValid()){me.show = 0;}
            #print("should show : " ~ me.u.get_Callsign()~" as Type: " ~ me.u.type ~ " Show : "~ me.show ~ " Name:"~me.u.propNode.getName()~" Model:"~me.u.get_model() ~ " isValid:"~me.u.isValid());
            
            if (me.show == 1) {
                me.threat = 0;
                if (me.u.get_model() != "missile_frigate" and me.u.propNode.getName() != "carrier" and me.u.get_model() != "fleet" and me.u.get_model() != "buk-m2") {
                    me.threat += ((180-me.dev)/180)*0.30;
                    me.spd = (60-me.u.get_Speed())/60;
                    me.threat -= me.spd>0?me.spd:0;
                } elsif (me.u.get_model == "missile_frigate" or me.u.get_model == "fleet") {
                    me.threat += 0.30;
                } else {
                    me.threat += 0.30;
                }
                me.danger = 50;
                if (me.u.get_model() == "missile_frigate" or me.u.get_model() == "fleet") {
                    me.danger = 75
                } elsif (me.u.get_model() == "buk-m2") {
                    me.danger = 35;
                } elsif (me.u.propNode.getName() == "carrier") {
                    me.danger = 60;
                }
                
                me.threat += ((me.danger-me.rn)/me.danger)>0?((me.danger-me.rn)/me.danger)*0.60:0;
                me.clo = me.u.get_closure_rate_from_Coord(me.MyCoord);
                me.threat += me.clo>0?(me.clo/500)*0.10:0;
                if (me.threat > 1) me.threat = 1;
                #printf("%s threat:%.2f range:%d dev:%d", me.u.get_Callsign(),me.threat,me.u.get_range(),me.dev);
                if (me.threat <= 0) continue;
                #printf("%s threat:%.2f range:%d dev:%d", u.get_Callsign(),threat,u.get_range(),dev);
                if (!me.l16) {
                    append(rwrList,[me.u,me.threat]);
                } else {
                    append(rwrList16,[me.u,me.threat]);
                }
            } else {
                #printf("%s ----", u.get_Callsign());
            }
        }
    },
};


