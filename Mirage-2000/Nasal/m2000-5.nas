print("*** LOADING m2000-5.nas ... ***");
################################################################################
#
#                       m2005-5's SYSTEMS SETTINGS
#
################################################################################
#
# Typhonn systems
# crazy dj nasal from many sources...
# and also, almursi work
# and 5H1N0B1

var deltaT                = 1.0;
var SAS_Loop_running      = 0;
var Elapsed_time_Seconds  = 0;
var Elapsed_time_previous = 0;
var LastTime              = 0;
# Elapsed for time > 0.25 sec
var Elapsed               = 0;
var myErr                 = [];
var myFramerate           = {a:0,b:0,c:0,d:0,e:0,f:0};#a = 0.1, b=0.2, c = 0.5, d=1, e=1.5 ; f = 2


var msgB = "Please land before changing payload.";



#======   OBJECT CREATION =======

# Need some simplification in the way to manage the interval
var engine1 = engines.Jet.new(0, 0, 0.01, 20, 3, 5, 30, 15);

#var RDM=radar.Radar.new(NewRangeTab:[5, 10, 20, 30, 60],NewRangeIndex:1,NewHaveDoppler:0,forcePath:"instrumentation/radar2/targets",NewAutoUpdate:1);
#var RDM_DOPPLER_MODE=radar.Radar.new(NewRangeTab:[5, 10, 15, 20],NewRangeIndex:1,NewHaveDoppler:1,forcePath:"instrumentation/radar2/targets",NewAutoUpdate:1);
#var RDI
#var RDY

var myRadar3 = radar.Radar.new(NewRangeTab:[10, 20, 40, 60, 160], NewRangeIndex:1, forcePath:"instrumentation/radar2/targets", NewAutoUpdate:1);
#var LaserDetection = radar.Radar.new(NewRangeTab:[20], NewVerticalAzimuth:180, NewRangeIndex:0, NewTypeTarget:["aircraft", "multiplayer", "carrier", "ship", "missile", "aim120", "aim-9"], NewRadarType:"laser", NewhaveSweep:0, NewAutoUpdate:0, forcePath:"instrumentation/radar2/targets");
setprop("/instrumentation/radar/az-fieldCenter", 0);

var hud_pilot = hud.HUD.new({"node": "canvasHUD", "texture": "hud.png"});
# var rwr = hud.HUD.new({"node": "canvasRWR", "texture": "hud.png"});

var prop = "payload/armament/fire-control";
var actuator_fc = compat_failure_modes.set_unserviceable(prop);
FailureMgr.add_failure_mode(prop, "Fire control", actuator_fc);


############################################################
# Global loop function
# If you need to run nasal as loop, add it in this function
############################################################
var global_system_loop = func{
    mirage2000.weather_effects_loop();
}

#===============================



var InitListener = setlistener("/sim/signals/fdm-initialized", func() {
    settimer(main_Init_Loop, 5.0);
    removelistener(InitListener);
});

# Main init loop
# Perhaps in the future, make an object for each subsystems, in the same way
# of "engine"
var main_Init_Loop = func()
{
  # Loop Updated inside
    print("Electrical ... Check");
    settimer(electrics.Electrical_init, 1.0);
    
    # Loop Updated inside
    print("Hydraulical ... Check");
    settimer(hydraulics.Hydraulical_init, 1.0);
    
    # Loop Updated inside
    print("Fuel ... Check");
    settimer(fuel.Fuel_init, 1.0);
    
    # Loop Updated below
    print("Stability Augmentation System ... Check");
    settimer(mirage2000.init_SAS, 2.0);
    
    print("Engine ... Check");
    engine1.init();
    
    print("Intrumentation ... Check");
    settimer(instrumentation.initIns, 2.0);
    
    print("Radar ... Check");
    myRadar3.init();
    #LaserDetection.init();  
    
    print("Flight Director ... Check");
    settimer(mirage2000.init_set, 4.0);
    
    print("MFD ...Check");
    settimer(mirage2000.update_main, 4.0);
    
    print("Transponder ... Check");
    settimer(init_Transpondeur, 4.0);
    
    print("system loop ... Check");
    settimer(UpdateMain, 8.0);
    
    print("blackout ... Check");
    settimer(blackout.blackout_init, 10);
    
    print("minihud ... Check");
    settimer(hud.minihud, 10);
    
        
    print("HUD canvas...Check");
    hud_pilot.update();
    
    print("MFD ... Check");
    settimer(mirage2000.setCentralMFD, 10);
    if(getprop("/instrumentation/efis/Mode"))
    {
        mirage2000.mdfselection();
    }
    
    
    settimer(environment.environment, 20);
    #Should be replaced by an object creation
    #settimer(func(){mirage2000.createMap();},10);
}

var UpdateMain = func
{
    settimer(mirage2000.updatefunction, 0);
}

var updatefunction = func()
{  
    AbsoluteTime = getprop("/sim/time/elapsed-sec");
    #Things to update, order by refresh rate.
    
    var AP_Alt = getprop("/autopilot/locks/altitude");
    
    ########################### rate 0
    mirage2000.Update_SAS();
    
    
    
    # Flight Director (autopilot)
    if(getprop("/autopilot/locks/AP-status") == "AP1")
    {
        call(mirage2000.update_fd,nil,nil,nil, myErr);
    }


    ################## Rate 0.1 ##################
    if(AbsoluteTime - myFramerate.a > 0.05){
      #call(hud_pilot.update,nil,nil,nil, myErr);
      hud_pilot.update();
      call(mirage2000.theShakeEffect,nil,nil,nil, myErr);
      myFramerate.a = AbsoluteTime;
    }
    
    
    ################## rate 0.5 ###############################

    if(AbsoluteTime - myFramerate.c > 0.5)
    {
      #call(m2000_load.Encode_Load,nil,nil,nil, myErr);
      call(m2000_mp.Encode_Bool,nil,nil,nil, myErr);
      myFramerate.b = AbsoluteTime;
      #if(getprop("autopilot/settings/tf-mode")){ <- need to find what is enabling it
      #8 second prevision do not need to be updated each fps
      if(AP_Alt =="TF"){
        call(mirage2000.tfs_radar,nil,nil,nil, myErr= []);
        if(size(myErr)) {
          foreach(var i;myErr) {
            print(i);
          }
        }
      }
      #mirage2000.weather_effects_loop();
      #environment.environment();
    }
    


    ###################### rate 1 ###########################
    if(AbsoluteTime - myFramerate.d > 1)
    {
      call(mirage2000.fuel_managment,nil,nil,nil, myErr);
      if(getprop("/autopilot/locks/AP-status") != "AP1"){
        call(mirage2000.update_fd,nil,nil,nil, myErr);
      }
      myFramerate.d = AbsoluteTime;
    }
    
    ###################### rate 1.5 ###########################
    if(AbsoluteTime - myFramerate.e > 1.5)
    {
      call(environment.environment,nil,nil,nil, myErr);
      if(size(myErr)>0){
        #debug.printerror(myErr);
      }
      call(environment.max_cloud_layer,nil,nil,nil, myErr);
      if(size(myErr)>0){
        #debug.printerror(myErr);
      }
      myFramerate.e = AbsoluteTime;
    }
    ###################### rate 2 ###########################
    if(AbsoluteTime - myFramerate.f > 2)
    {
      if(AP_Alt =="TF"){
        call(mirage2000.long_view_avoiding,nil,nil,nil, myErr);
        if(size(myErr)>0){
          foreach(var i;myErr) {
            print(i);
          }
        }
      }    
      myFramerate.f = AbsoluteTime;
    }
    
    
    
    
    

    # Update at the end
    call(mirage2000.UpdateMain,nil,nil,nil, myErr);
}

var init_Transpondeur = func()
{
    # Init Transponder
    var poweroften = [1, 10, 100, 1000];
    var idcode = getprop('/instrumentation/transponder/id-code');
    
    if(idcode != nil)
    {
      for(var i = 0 ; i < 4 ; i += 1)
      {
        setprop("/instrumentation/transponder/inputs/digit[" ~ i ~ "]", int(math.mod(idcode / poweroften[i], 10)));
      }
    }
}

controls.deployChute = func(v)
{
    # Deploy
    if(v > 0)
    {
        setprop("controls/flight/chute_deployed", 1);
        setprop("controls/flight/chute_open", 1);
        chuteAngle();
    }
    # Jettison
    if(v < 0)
    {
        var voltage = getprop("systems/electrical/outputs/chute_jett");
        if(voltage > 20)
        {
            setprop("controls/flight/chute_jettisoned", 1);
            setprop("controls/flight/chute_open", 0);
        }
    }
}

var chuteAngle = func
{
    var chute_open = getprop('controls/flight/chute_open');
    
    if(chute_open != '1')
    {
        return();
    }
    var speed = getprop('/velocities/airspeed-kt');
    var aircraftpitch = getprop('/orientation/pitch-deg[0]');
    var aircraftyaw = getprop('/orientation/side-slip-deg');
    var chuteyaw = getprop("orientation/chute_yaw");
    var aircraftroll = getprop('/orientation/roll-deg');
    
    if(speed > 210)
    {
        setprop("controls/flight/chute_jettisoned", 1); # Model Shear Pin
        return();
    }
    
    # Chute Pitch
    var chutepitch = aircraftpitch * -1;
    setprop("orientation/chute_pitch", chutepitch);
    
    # Damped yaw from Vivian's A4 work
    var n = 0.01;
    if(aircraftyaw == nil)
    {
        aircraftyaw = 0;
    }
    if(chuteyaw == nil)
    {
        chuteyaw = 0;
    }
    var chuteyaw = (aircraftyaw * n) + (chuteyaw * (1 - n));
    setprop("orientation/chute_yaw", chuteyaw);
    
    # Chute Roll - no twisting for now
    var chuteroll = aircraftroll;
    setprop("orientation/chute_roll", chuteroll * rand() * -1);
    
    return registerTimerControlsNil(chuteAngle);  # Keep watching
}

var chuteRepack = func
{
    setprop('controls/flight/chute_open',       0);
    setprop('controls/flight/chute_deployed',   0);
    setprop('controls/flight/chute_jettisoned', 0);
}

var fuel_managment = func()
{
    var Externaltank = getprop("/consumables/fuel/tank[2]/empty");
    Externaltank *= getprop("/consumables/fuel/tank[3]/empty");
    Externaltank *= getprop("/consumables/fuel/tank[4]/empty");
    # If only one external Tank is still not empty, then...
    # systems/refuel/contact = false si pas refuel en cours
    if(getprop("/systems/refuel/contact"))
    {
        setprop("/consumables/fuel/tank[0]/selected", 1);
        setprop("/consumables/fuel/tank[1]/selected", 1);
        
        if(getprop("/consumables/fuel/tank[2]/capacity-m3") != 0)
        {
            setprop("/consumables/fuel/tank[2]/selected", 1);
        }
        if(getprop("/consumables/fuel/tank[3]/capacity-m3") != 0)
        {
            setprop("/consumables/fuel/tank[3]/selected", 1);
        }
        if(getprop("/consumables/fuel/tank[4]/capacity-m3") != 0)
        {
            setprop("/consumables/fuel/tank[4]/selected", 1);
        }
    }
    elsif(Externaltank)
    {
        setprop("/consumables/fuel/tank[0]/selected", 1);
        setprop("/consumables/fuel/tank[1]/selected", 1);
    }
    else
    {
        setprop("/consumables/fuel/tank[0]/selected", 0);
        setprop("/consumables/fuel/tank[1]/selected", 0);
        if(getprop("/consumables/fuel/tank[2]/level-kg") > 0)
        {
            setprop("/consumables/fuel/tank[2]/selected", 1);
        }
        if(getprop("/consumables/fuel/tank[3]/level-kg") > 0)
        {
            setprop("/consumables/fuel/tank[3]/selected", 1);
        }
        if(getprop("/consumables/fuel/tank[4]/level-kg") > 0)
        {
            setprop("/consumables/fuel/tank[4]/selected", 1);
        }
    }
}

# 5H1N0B1's NOTE : Shake Effect : Taken to the 707 :
#######################################################################################
#   Lake of Constance Hangar :: M.Kraus
#   Boeing 707 for Flightgear February 2014
#   This file is licenced under the terms of the GNU General Public Licence V2 or later
#######################################################################################

############################ roll out and shake effect ##################################
var shakeEffect2000 = props.globals.initNode("controls/cabin/shake-effect", 0, "BOOL");
var shake2000       = props.globals.initNode("controls/cabin/shaking", 0, "DOUBLE");

var theShakeEffect = func() {
    #ge_a_r = getprop("sim/multiplay/generic/float[1]") or 0;
    rSpeed          = getprop("/velocities/airspeed-kt") or 0;
    var G           = getprop("/accelerations/pilot-g");
    var alpha       = getprop("/orientation/alpha-deg");
    var mach        = getprop("velocities/mach");
    var wow         = getprop("/gear/gear[1]/wow");
    var gun         = getprop("controls/armament/Gun_trigger");
    var myTime      = getprop("/sim/time/elapsed-sec");
    
    #sf = ((rSpeed / 500000 + G / 25000 + alpha / 20000 ) / 3) ;
    # I want to find a way to improve vibration amplitude with sf, but to tired actually to make it.
    
    if(shakeEffect2000.getBoolValue() and (((G > 9 or alpha > 25) and rSpeed > 30) or (mach > 0.99 and mach < 1.01) or (wow and rSpeed > 100) or gun))
    {
        #print("it is working.");
        setprop("controls/cabin/shaking", math.sin(48 * myTime) / 333.333);
    }
    else
    {
        setprop("controls/cabin/shaking", 0);
    }
}

var setCentralMFD = func() {
    setprop("/instrumentation/efis/Mode", 1);
    if(getprop("/instrumentation/efis/Mode"))
    {
        mirage2000.mdfselection();
    }
}

# to prevent dynamic view to act like helicopter due to defining <rotors>:
dynamic_view.register(func {me.default_plane();});




var test = func(){
      if(! contains(globals, "m2000_mp"))
      {
        var err = [];
        var myTree = props.globals.getNode("/sim");
        var raw_list = myTree.getChildren();
        foreach(var c ; raw_list)
        {
          if(c.getName() == "fg-aircraft"){
            myAircraftTree = "/sim/" ~ c.getName()~"["~c.getIndex()~"]";
            print(myAircraftTree);
            var err = [];
            var file = getprop(myAircraftTree) ~ "/Mirage-2000/Nasal/MP.nas";
            print(file);
            var code = call(func compile(io.readfile(file), file), nil, err);
            print("Path 0. Error : " ~size(err));
            if(size(err) == 0)
            {
              call(func {io.load_nasal(file, "m2000_mp");},nil, err);
              if (size(err)) {
                print("Path 0a. Error : ");
                foreach(lin;err) print(lin);
                }else{
                  break;}
            }else {
              print("Path 0b. Error : ");
              foreach(lin;err) print(lin);
            }
          }
        }
      }
} 
