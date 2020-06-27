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
var EjectionKey = 0;


var msgB = "Please land before changing payload.";



#======   OBJECT CREATION =======

# Need some simplification in the way to manage the interval

#var RDM=radar.Radar.new(NewRangeTab:[5, 10, 20, 30, 60],NewRangeIndex:1,NewHaveDoppler:0,forcePath:"instrumentation/radar2/targets",NewAutoUpdate:1);
#var RDM_DOPPLER_MODE=radar.Radar.new(NewRangeTab:[5, 10, 15, 20],NewRangeIndex:1,NewHaveDoppler:1,forcePath:"instrumentation/radar2/targets",NewAutoUpdate:1);
#var RDI
#var RDY

var myRadar3 = radar.Radar.new(NewRangeTab:[10, 20, 40, 60, 160], NewRangeIndex:1, forcePath:"instrumentation/radar2/targets", NewAutoUpdate:1);
#var LaserDetection = radar.Radar.new(NewRangeTab:[20], NewVerticalAzimuth:180, NewRangeIndex:0, NewTypeTarget:["aircraft", "multiplayer", "carrier", "ship", "missile", "aim120", "aim-9"], NewRadarType:"laser", NewhaveSweep:0, NewAutoUpdate:0, forcePath:"instrumentation/radar2/targets");
setprop("/instrumentation/radar/az-fieldCenter", 0);

var hud_pilot = hud.HUD.new({"node": "revi.canvasHUD", "texture": "hud.png"});
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
    print("Fuel ... Check");
    settimer(fuel.Fuel_init, 1.0);
    
    # Loop Updated below
    print("Stability Augmentation System ... Check");
    settimer(mirage2000.init_SAS, 2.0);
    
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
    print("Missile view Check");
    settimer(view.init_missile_view, 3);
    
    settimer(environment.environment, 20);
    #Should be replaced by an object creation
    #settimer(func(){mirage2000.createMap();},10);
    
    if (getprop("sim/disable-custom-view") == 1) view.manager.register("Cockpit View", pilot_view_limiter);
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
    
    
#     if (getprop("payload/armament/es/flags/deploy-id-10")!= nil) {
#       setprop("instrumentation/ejection/force", 7-5*getprop("payload/armament/es/flags/deploy-id-10"));
#     } else {
#       setprop("instrumentation/ejection/force", 7);
#     }
    
    
    # Flight Director (autopilot)
    if(getprop("/autopilot/locks/AP-status") == "AP1")
    {
        call(mirage2000.update_fd,nil,nil,nil, myErr= []);
        if(size(myErr)>0){
          foreach(var i;myErr) {
            print(i);
          }
        }
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
      mp_messaging();
      #mirage2000.weather_effects_loop();
      #environment.environment();
      
#       call(environment.low_loop,nil,nil,nil, myErr);
#       if(size(myErr)>0){
#         #debug.printerror(myErr);
#       }
    }
    


    ###################### rate 1 ###########################
    if(AbsoluteTime - myFramerate.d > 1)
    {
      call(mirage2000.fuel_managment,nil,nil,nil, myErr);
      if(getprop("/autopilot/locks/AP-status") != "AP1"){
        call(mirage2000.update_fd,nil,nil,nil, myErr= []);
        if(size(myErr)>0){
          foreach(var i;myErr) {
            print(i);
          }
        }
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


var mp_messaging = func(){
  if(getprop("/payload/armament/msg")){
          #call(func{fgcommand('dialog-close', multiplayer.dialog.dialog.prop())},nil,var err= []);# props.Node.new({"dialog-name": "location-in-air"}));
      call(func{multiplayer.dialog.del();},nil,var err= []);
      if (!getprop("/gear/gear[0]/wow")) {
        #call(func{fgcommand('dialog-close', props.Node.new({"dialog-name": "map"}))},nil,var err2 = []);
        #call(func{fgcommand('dialog-close', props.Node.new({"dialog-name": "map-canvas"}))},nil,var err2 = []);
        call(func{fgcommand('dialog-close', props.Node.new({"dialog-name": "WeightAndFuel"}))},nil,var err2 = []);        
        call(func{fgcommand('dialog-close', props.Node.new({"dialog-name": "system-failures"}))},nil,var err2 = []);
        call(func{fgcommand('dialog-close', props.Node.new({"dialog-name": "instrument-failures"}))},nil,var err2 = []);  
      }      
      setprop("sim/freeze/fuel",0);
      setprop("/sim/speed-up", 1);
      setprop("/gui/map/draw-traffic", 0);
      setprop("/sim/gui/dialogs/map-canvas/draw-TFC", 0);
      setprop("/sim/rendering/als-filters/use-filtering", 1);
      setprop("/controls/SAS/activated", 1);
      setprop("/sim/freeze/master", 0);
      setprop("/sim/view[100]/enabled", 0);
    
    
  }
}


var ejection = func(){
 print("Ejection");
        if (getprop("instrumentation/ejection/done")==1) {
            return;
        }
        EjectionKey = EjectionKey +1;
        print("EjectionKey:"~EjectionKey);
        
        if(EjectionKey<3){
          settimer(mirage2000.init_EjectionKey, 2.0);
          return;
        }
        
        setprop("instrumentation/ejection/done",1);
        
        var es = armament.AIM.new(10, "es","gamma", nil ,[-3.65,0,0.7]);

        es.releaseAtNothing();
        view.view_firing_missile(es);
        setprop("sim/view[0]/enabled",0);
#       settimer(func {crash.exp();},3.5);
}

var init_EjectionKey = func(){
  EjectionKey = 0;
}



# pilot view that translates left or right depending on view direction.
var pilot_view_limiter = {
  new : func {
    return { parents: [pilot_view_limiter] };
  },
  init : func {
    me.hdgN = props.globals.getNode("/sim/current-view/heading-offset-deg");
    me.xoffsetN = props.globals.getNode("/sim/current-view/x-offset-m");
    me.xoffset_lowpass = aircraft.lowpass.new(0.1);
    me.last_offset = 0;
    me.needs_start = 0;
  },
  start : func {
    var limits = view.current.getNode("config/limits", 1);
    me.active = props.globals.getNode("sim/disable-custom-view");
    me.left = {
      heading_max : math.abs(limits.getNode("left/heading-max-deg", 1).getValue() or 1000),
      threshold : math.abs(limits.getNode("left/x-offset-threshold-deg", 1).getValue() or 0),
      xoffset_max : math.abs(limits.getNode("left/x-offset-max-m", 1).getValue() or 0),
      xoffset_t_max : math.abs(limits.getNode("left/x-offset-threshold-max-m", 1).getValue() or 0),
    };
    me.right = {
      heading_max : -math.abs(limits.getNode("right/heading-max-deg", 1).getValue() or 1000),
      threshold : -math.abs(limits.getNode("right/x-offset-threshold-deg", 1).getValue() or 0),
      xoffset_max : -math.abs(limits.getNode("right/x-offset-max-m", 1).getValue() or 0),
      xoffset_t_max : -math.abs(limits.getNode("right/x-offset-threshold-max-m", 1).getValue() or 0),
    };
    me.left.scale = me.left.xoffset_t_max / me.left.threshold;
    me.right.scale = me.right.xoffset_t_max / me.right.threshold;
    me.last_hdg = geo.normdeg180(me.hdgN.getValue());
    me.enable_xoffset = me.right.xoffset_t_max > 0.001 or me.left.xoffset_t_max > 0.001;

    me.needs_start = 0;
  },
  update : func {
    print("View = " ~ me.active.getValue());
    if (getprop("/devices/status/keyboard/ctrl"))
      return;

    if( getprop("/sim/signals/reinit") )
    {
      me.needs_start = 1;
      return;
    }
    else if( me.needs_start )
      me.start();

    var hdg = geo.normdeg180(me.hdgN.getValue());
    if (math.abs(me.last_hdg - hdg) > 180) { # avoid wrap-around skips
      me.hdgN.setDoubleValue(hdg = me.last_hdg);
      #print("wrap skip");
    } elsif (hdg > me.left.heading_max) {
      me.hdgN.setDoubleValue(hdg = me.left.heading_max);
      #print("wrap left");
    } elsif (hdg < me.right.heading_max) {
      me.hdgN.setDoubleValue(hdg = me.right.heading_max);
      #print("wrap right");
    }
    me.last_hdg = hdg;

    # translate view on X axis to look far right or far left
    if (me.enable_xoffset) {
      var offset = 0;
      #print(hdg~" "~me.left.threshold);
      if (hdg > 0 and hdg < me.left.threshold)
        offset = -hdg * me.left.scale;
      elsif (hdg > 0)
        offset = -(me.left.xoffset_t_max+(me.left.xoffset_max-me.left.xoffset_t_max)*(hdg-me.left.threshold)/(me.left.heading_max-me.left.threshold));
      elsif (hdg < 0 and hdg > me.right.threshold)
        offset = -hdg * me.right.scale;
      elsif (hdg < 0)
        offset = -(me.right.xoffset_t_max+(me.right.xoffset_max-me.right.xoffset_t_max)*(hdg-me.right.threshold)/(me.right.heading_max-me.right.threshold));

      var new_offset = me.xoffset_lowpass.filter(offset);
      me.xoffsetN.setDoubleValue(me.xoffsetN.getValue() - me.last_offset + new_offset);
      me.last_offset = new_offset;
    }
    return 0;
  },
};


var flightmode = func (){
  #print("Called");
  if(getprop("/sim/current-view/view-number") == 0) {
    if(getprop("/instrumentation/flightmode/app")){
      setprop("/sim/current-view/x-offset-m",0);
      setprop("/sim/current-view/y-offset-m",0.1019);
      setprop("/sim/current-view/z-offset-m",-2.9);  
      
    }elsif(getprop("/instrumentation/flightmode/to")){
      
      setprop("/sim/current-view/x-offset-m",0);
      setprop("/sim/current-view/y-offset-m",0.1019);
      setprop("/sim/current-view/z-offset-m",-2.9);

      
    }elsif(getprop("/instrumentation/flightmode/nav")){
      setprop("/sim/current-view/x-offset-m",0);
      setprop("/sim/current-view/y-offset-m",0.025);
      setprop("/sim/current-view/z-offset-m",-2.9);
      
    }elsif(getprop("/instrumentation/flightmode/arm")){
      setprop("/sim/current-view/x-offset-m",0);
      setprop("/sim/current-view/y-offset-m",0.099);
      setprop("/sim/current-view/z-offset-m",-2.67);
      
    }else{
      setprop("/sim/current-view/x-offset-m",0);
      setprop("/sim/current-view/y-offset-m",0.025);
      setprop("/sim/current-view/z-offset-m",-2.9);

    }
 }
 gui.dialog_update("flightmode");
}

var call_flightmode = func(calling){
  #This function is made to auto switch flight mode when masterarm is switched or gear is switched
  var app=0;
  var to=0;
  var nav=0;
  var arm=0;
  if(calling == "m"){
      if(getprop("controls/armament/master-arm")==1){
        arm = 1;
      }else{
        nav = 1;
      }
  }elsif(calling == "g"){nav = 1;
  }elsif(calling == "G"){to = 1;}
     ## if(getprop("controls/gear/gear-down")){
#         to = 1;
#       }else{
#         nav = 1;
#       }
#   }
  setprop("/instrumentation/flightmode/app",app);
  setprop("/instrumentation/flightmode/to",to);
  setprop("/instrumentation/flightmode/nav",nav);
  setprop("/instrumentation/flightmode/arm",arm);
  
  flightmode();
}
var quickstart = func() {
  settimer(func { 
    setprop("controls/engines/engine[0]/cutoff",0);
        setprop("engines/engine[0]/out-of-fuel",0);
        setprop("engines/engine[0]/cutoff",0);
        
        setprop("fdm/jsbsim/propulsion/starter_cmd",1);
        setprop("fdm/jsbsim/propulsion/cutoff_cmd",1);
        setprop("fdm/jsbsim/propulsion/set-running",0);
        
    }, 0.2);
}

 autostart = func{
        if(getprop("sim/time/elapsed-sec") < 10)
        {
            return;
        }
        if(!getprop("/controls/engines/engine[0]/cutoff"))
        {
            me.autostart_status = 0;
            # Cut Off
            setprop("/controls/switches/hide-cutoff", 1);
            setprop("/controls/engines/engine/cutoff", 1);
        }
        else
        {
            setprop("/controls/engines/engine[0]/cutoff",1);
            
            # Place here all the switch 'on' needed for the autostart
            
            # First electrics switchs
            setprop("/controls/switches/battery-switch",       1);
            setprop("/controls/switches/transformator-switch", 1);
            setprop("/controls/switches/ALT1-switch",          1);
            setprop("/controls/switches/ALT2-switch",          1);
            
            # Launching process
            # Cut Off
            setprop("/controls/switches/hide-cutoff",  0);
            setprop("/controls/engines/engine/cutoff", 0);
            # Fuel Pumps
            setprop("/controls/switches/pump-BPG", 1);
            setprop("/controls/switches/pump-BPD", 1);
            # This isn't a pump, but it's here is the starting process.
            # Vent is to clear fuel of the engine, allumage is to burn it.
            # So 1 is allumage 0 vent.
            setprop("/controls/switches/vent-allumage", 1);
            setprop("/controls/switches/pump-BP",       1);
            
            # Starter
            quickstart();
        }
 }

