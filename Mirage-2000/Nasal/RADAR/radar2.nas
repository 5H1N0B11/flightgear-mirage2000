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
foreach(var addMe ; listOfAIRadarEchoes2) {
    append(listOfAIRadarEchoes, addMe);
}


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
        var m = { parents : [Radar] };
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
            var radarWorking = getprop(me.ElectricalPath);
            radarWorking = (radarWorking == nil) ? 0 : radarWorking;
            if(radarWorking > 24 and me.AutoUpdate)
            {
                #me.update();
                #These line bellow are error management.
                var UpdateErr = [];
#                 print("Calling radar");
                call(me.update,[],me,nil,UpdateErr);
                if(size(UpdateErr) != 0)
                {
                    print("We have Radar update Errors, but radar still running");
                    foreach(var myErrors ; UpdateErr)
                    {
                        print(myErrors);
                    }
                }
#                 print("Radar refreshing done");
            }
            #me.Global_janitor();
            settimer(loop_Update, me.UPDATE_PERIOD);
        };
        settimer(loop_Update,me.UPDATE_PERIOD);

        var loop_Sweep = func() {
            if(me.haveSweep ==1){me.maj_sweep();}
            settimer(loop_Sweep, 0.05);
        };
        settimer(loop_Sweep,0.05);
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
      
        if(me.updating_now == 1)
        {
          return;
        }else{
          me.updating_now = 1;
        }

        # First update Coord, Alt, heeading and Pitch. 
        # The code pout the aircraft properties if nothing has been passed in parameters
        # Coord update ! Should be filled with altitude
        if(tempCoord == nil)
        {
            me.MyCoord = geo.aircraft_position();
        }
        else
        {
            me.MyCoord = tempCoord;
        }
        
        me.LoopElapsed = getprop("sim/time/elapsed-sec") - me.TimeWhenUpdate;
        # This is to know when was the last time we called the update
        me.TimeWhenUpdate = getprop("sim/time/elapsed-sec");
        
        
        # Altitude update (in meters)

        me.our_alt = me.MyCoord.alt();
        
        # Heading Update (should be the airplane heading, not the radar look direction)
        if(tempHeading == nil)
        {
            me.OurHdg = getprop("orientation/heading-deg");
        }
        else
        {
            me.OurHdg = tempHeading;
        }
        
        # Pitch Update (should be the airplane heading, not the radar look direction)
        if(tempPitch == nil)
        {
            me.OurPitch = getprop("orientation/pitch-deg");
        }
        else
        {
            me.OurPitch = tempPitch;
        }
        # Variable initialized
        
        # This is the return array. Made First for Canvas, but can be usefull to a lot of other things
        var CANVASARRAY = [];
        
        #This is the missile index. It is reset on each loop.
        missileIndex = 0;
        
        var raw_list = me.Mp.getChildren();
        foreach(var c ; raw_list)
        {
            # FIXME: At that time a multiplayer node may have been deleted while still
            # existing as a displayable target in the radar targets nodes.
            # FIXED, with janitor. 5H1N0B1
            var type = me.type_selector(c);
            if(! c.getNode("valid", 1).getValue())
            {
                continue;
            }
            
            # the 2 following line are needed : If not, it would detects our own missiles...
            # this will come soon
            var HaveRadarNode = c.getNode("radar");
            #print(me.check_selected_type(c));
            #if(type == "multiplayer"
            #    or (type == "tanker" and HaveRadarNode != nil)
            #    or (type == "aircraft" and me.showAI == 1)
            #    or type == "carrier"
            #    or type == "ship"
            #    or (type == "missile" and HaveRadarNode != nil))
            #
            if(me.check_selected_type(c))
            {
                # creation of the tempo object Target
                var u = Target.new(c,me.myTree.getPath());
               

                folderName = c.getName();

                # important Shinobi:
                # expand this so multiplayer that is on sea or ground is also set correct.
                # also consider if doppler do not see them that they are either SURFACE or MARINE, depending on if they have alt = ~ 0
                # notice that GROUND_TARGET is set inside Target.new().
                me.skipDoppler = 0;
                # now we test the property folder name to guess what type it is:
                foreach (var testMe ; listOfShipNames) {
                    if (testMe == folderName) {
                        if(u.get_altitude()<100){
                          u.setType(armament.MARINE);
                          me.skipDoppler = 1;
                        }
                        break;
                          
                    }
                }

                #If not MARINE skipDoppler still == 0
                if (me.skipDoppler == 0) {
                    foreach (var testMe ; listOfGroundTargetNames) {
                        if (testMe == folderName) {
                            u.setType(armament.SURFACE);
                            me.skipDoppler = 0;
                            break;
                        }
                    }
                    
                 }
                if(u.get_type() == 0){
                # now we test the model name to guess what type it is:
                      me.pathNode = c.getNode("sim/model/path");
                      if (me.pathNode != nil) {
                          me.path = me.pathNode.getValue();
                          me.model = split(".", split("/", me.path)[-1])[0];
                          u.set_model(me.model);#used for RCS
                          foreach (var testMe ; listOfShipModels) {
                              if (testMe == me.model) {
                                # Its a ship, Mirage ground radar will pick it up
                                if(u.get_altitude()<100){
                                  u.setType(armament.MARINE);
                                  me.skipDoppler = 1;
                                }
                                break;
                              }
                          }
                          foreach (var testMe ; listOfGroundVehicleModels) {
                              if (testMe == me.model) {
                                # its a ground vehicle, Mirage ground radar will not pick it up
                                u.setType(armament.SURFACE);
                                me.skipDoppler = 0;
                                break;
                              }
                          }
                      }
                  }
                  
                 #Testing if ORDNANCE
                 if (c.getNode("missile") != nil and c.getNode("missile").getValue()) {
                    u.setType(armament.ORDNANCE);
                 }
                 #Testing Ground Target
                  if(u.get_Callsign() == "GROUND_TARGET"){
                    u.setType(armament.SURFACE);
                  }
 

                
                #print("Start Testing "~ u.get_Callsign()~"Type: " ~ u.type);
                
                              
                # set Check_List to void
                me.Check_List = [];
                # this function do all the checks and put all result of each
                # test on an array[] named Check_List

                me.go_check(u, me.skipDoppler);
                
                #print("Complete liste after update : " ~ size(completeList));
                #me.decrease_life(completeList);
                #me.sorting_and_suppr(completeList);
                
                #Displaying Check
                #print("Testing "~ u.get_Callsign()~"Check: " ~ me.get_check());
                
                #print("End Testing "~ u.get_Callsign());
                
                # then a function just check it all
                if(me.get_check())
                {
                                        
                    #Is in Range : Should be added to the main ARRAY1 (Here : ContactsList)
                    var HaveRadarNode = c.getNode("radar");

                    #Update ContactList : Only updated when target is valid
                    #Should return an Index, in order to take the object from the table and not the property tree
                    
                    if(me.UseATree){
                      u.create_tree(me.MyCoord, me.OurHdg);
                      u.set_all(me.MyCoord);
                      me.calculateScreen(u);
                    }
                    
                    #print("Update contactList");
                    me.ContactsList = me.update_array(u,me.ContactsList);
                    #me.tempo_Index = me.find_index_inArray(u,me.ContactsList);
                    #me.ContactsList[me.tempo_Index].set_display(1);
                    u.set_display(1);
                    
                    #if(me.tempo_Index != nil){ u = me.ContactsList[me.tempo_Index];}
                    
                    
                    # for Target Selection
                    # here we disable the capacity of targeting a missile. But 's possible.
                    # CANVASARRAY => ARRAY2
                    
                    
                    if(type != "missile" and !contains(weaponRadarNames, type))
                    {
                        #tgts_list => ARRAY4
                        
                        #print("Update targetList" ~ u.get_Callsign());
                        me.TargetList_Update(u);
                        me.TargetList_AddingTarget(u);
                        
                        #We should UPDATE tgts_list here
                        
                        #This shouldn't be here. See how to delet it
                        if(u.getUnique() == me.tgts_list[me.Target_Index].getUnique() and u.getUnique() == me.Target_Callsign){
                          #print("Picasso painting");
                          u.setPainted(1);
                          armament.contact = me.tgts_list[me.Target_Index];
                          #print(armament.contact.get_type());
                        }
                    }
                    append(CANVASARRAY, u); 
                    me.displayTarget();
                }
                else
                {
                    #me.tempo_Index = me.find_index_inArray(u,me.ContactsList);
                    #if(me.tempo_Index != nil){me.ContactsList[me.tempo_Index].set_display(1,me.myTree);}
                  
                 #Here we shouldn't see the target anymore. It should disapear. So this is calling the Tempo_Janitor      
                    if(u.get_Validity() == 1)
                    {
                        if(getprop("sim/time/elapsed-sec") - u.get_TimeLast() > me.MyTimeLimit)
                        {
                          me.Tempo_janitor(u);
                        }
                    }
                    
                }    
                completeList = me.update_array_no_life_reset(u,completeList);
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
            
            
        }#For Each End
;
                
        me.ContactsList = me.decrease_life(me.ContactsList);
        #print("Test");
        me.sorting_and_suppr(me.ContactsList);
        #me.ContactsList = me.cut_array(me.radarMaxSize,me.ContactsList);
        #me.Global_janitor();
        #print("Side in RADAR : "~ size(me.ContactsList));
        #foreach(contact;me.ContactsList){
        #  print("Last Check : " ~ contact.get_Callsign() ~" 's life : "~ contact.life);
        #}

        #print("size(completeList) : " ~size(completeList) ~ "; size(me.ContactsList) : " ~ size(me.ContactsList));
        me.updating_now = 0;
        return CANVASARRAY;
    },
    
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

    isNotBehindTerrain: func(SelectedObject){
        if(SelectedObject.get_Callsign()=="GROUND_TARGET"){return 1;}
        isVisible = 0;
        
        # As the script is relatively ressource consuming, then, we do a maximum of test before doing it
        if(me.get_check())
        {
            SelectCoord = SelectedObject.get_Coord();
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
                  if (terrainDist < maxDist) {
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
        }
        return isVisible;
    },

    NotBeyondHorizon: func(SelectedObject){
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
            #print( "Is radiating :" ~ SelectedObject.isRadiating(me.MyCoord));
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

    inElevation: func(SelectedObject){
        if(SelectedObject.get_Callsign()=="GROUND_TARGET"){return 1;}
        # Moving the center of this field will be ne next option
        var tempAz = me.vt_az_fld;
        var myElevation = SelectedObject.get_total_elevation_from_Coord(me.OurPitch, me.MyCoord);
        var IsInElevation = (abs(myElevation) < (tempAz / 2));
        return IsInElevation;
    },

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

    maj_sweep: func(){
        var x = (getprop("sim/time/elapsed-sec") / (me.sweep_frequency)) * (0.0844 / me.swp_diplay_width); # shorten the period time when illuminating a target
        #print("SINUS (X) = "~math.sin(x);
        me.SwpMarker = (math.sin(3.14 * x) * (me.swp_diplay_width / 0.0844)); # shorten the period amplitude when illuminating
        setprop(me.sweepProperty,me.SwpMarker);
    },

    targetRange: func(SelectedObject){
        # This is a way to shortcurt the issue that some of node have : in-range =0
        # So by giving the second fucntion our coord, we just have to calculate it
        var myRange = 0;
        myRange = SelectedObject.get_range();
        if(myRange == 0)
        {
            myRange = SelectedObject.get_range_from_Coord(me.MyCoord);
        }
        #print("myRange="~myRange);
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
        var checked = 1;
        var CheckTable = ["InRange:", "inAzimuth:", "inElevation:", "Horizon:", "RCS","Doppler:", "NotBtBehindTerrain:"];
        var i = 0;
        foreach(myCheck ; me.Check_List)
        {
            if(i<size(CheckTable)){
              #print("i : "~ i ~"|" ~ CheckTable[i] ~ " " ~ myCheck);
            }else{
              #print("i : "~ i ~"|myCheck : " ~ myCheck);
            }
            i +=1;
            checked = (myCheck and checked);
        }
        return checked;
    },
    #function in order to make it work with unified missile method in FG
    type_selector: func(SelectedObject){
        var selectedType = SelectedObject.getName();
        
        #Overwrite selectedType if missile
        var TestIfMissileNode = SelectedObject.getNode("missile");
        if(TestIfMissileNode != nil) {
          if(TestIfMissileNode.getValue()){
            #print("It is a missile");
            selectedType = "missile";
          }
        }
    
        return selectedType;
    },
    check_selected_type: func(SelectedObject)
    {
      var result = 0;
      #Variable for the selection Type test
      var selectedType = SelectedObject.getName();
      

      selectedType = me.type_selector(SelectedObject);

      #print("MY type  IS  : "~selectedType);

      #variable for the RadarNode test
      var shouldHaveRadarNode = ["tanker","aircraft","missile"];
      var HaveRadarNode = SelectedObject.getNode("radar");

      #We test the type of target
      foreach(myType;me.typeTarget)
      {
        if(myType == selectedType){
           result = 1;
        }
      }

      #We test if they have a radar Node (they should all have one, but unconventionnal model like ATC or else could have these issue)
      foreach(myType;shouldHaveRadarNode)
      {
        if(myType == selectedType and HaveRadarNode == nil){
          result = 0;
        }
      }

      return result;
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

    next_Target_Index: func(){
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

    previous_Target_Index: func(){
      if(me.az_fld == me.focused_az_fld){
        if (size(me.tgts_list) > 0) {me.tgts_list[me.Target_Index].setPainted(0);}
        me.Target_Index = me.Target_Index - 1;
        if(me.Target_Index < 0)
        {
            me.Target_Index = size(me.tgts_list)-1;
        }
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
                 setprop("/ai/closest/range", 0);
                 return;#me.Target_Index = size(me.tgts_list) - 1;
            }
            if( me.Target_Index > size(me.tgts_list) - 1)
            {
                 me.Target_Index = 0;
                 me.Target_Callsign = nil;
                 setprop("/ai/closest/range", 0);
                 return;#me.Target_Index = 0;
            }
            if (me.Target_Callsign != me.tgts_list[me.Target_Index].getUnique()) {
                me.Target_Callsign = nil;
                me.Target_Callsign = nil;
                setprop("/ai/closest/range", 0);
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
      var tempo = nil;
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
      var tempo = nil;
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

