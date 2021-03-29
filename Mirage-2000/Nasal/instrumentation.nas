print("*** LOADING instrumentation.nas ... ***");
################################################################################
#
#                       m2005-5's INSTRUMENTS SETTINGS
#
################################################################################

var blinking     = 0;
var viewNum      = 1;
var isHUDvisible = 1;
var wow              = props.globals.getNode("/gear/gear/wow",1);
var AngleOfAttack    = props.globals.getNode("orientation/alpha-deg");
var AirSpeed         = props.globals.getNode("velocities/airspeed-kt");



# When we call this fonction, it switch the menu on/off
var enableGuiLoad = func()
{
    var searchname = "fuel-and-payload";
    var state = 0;
    
    foreach(var menu ; props.globals.getNode("/sim/menubar/default").getChildren("menu"))
    {
        foreach(var item ; menu.getChildren("item"))
        {
            foreach(var name ; item.getChildren("name"))
            {
                if(name.getValue() == searchname)
                {
                    state = item.getNode("enabled").getBoolValue();
                    item.getNode("enabled").setBoolValue(! state);
                }
            }
        }
    }
}


var bingo = {
    new : func
    {
      var me  = { parents : [bingo]};     
      me.input = {
        blinking_bingo_low:           "/instrumentation/consumables/bingo_low",  #--"Blinking variable"
        bingo:                        "/instrumentation/consumables/bingo_fuel",
        remaining_Distance_in_Route:   "/autopilot/route-manager/distance-remaining-nm",
        remaining_fuel:               "/consumables/fuel/total-fuel-kg",
      };
      foreach(var name; keys(me.input))
        me.input[name] = props.globals.getNode(me.input[name], 1);
      #We put that for now.
      me.input.bingo.setValue(480);
      return me;
    },
    make_it_blink : func{
      me.input.blinking_bingo_low.setValue(!me.input.blinking_bingo_low.getValue());
    },
    auto_calculate_bingo : func(simple = 1){
      # Consommations moyennes: 4kg / Nm en High Altitude. 7kg / Nm en BA (Low Alt) or Average Consumption 36 kg/min these consumption have to be checked
      # first -> Calculation of the last airport (route manager)
      # So this is trying to calculate the fuel for the remaining distance.
      # distance  * Consumption inlow alt in kg + 15 mins * average fuel consuption/min * 36 kg of margins?
      # We could have calculate in order to have 15 minutes of margin to the closest airport all along the route
      if(simple){
        if(me.input.remaining_Distance_in_Route.getValue() == nil){
          me.input.bingo.setValue(0);
        }else{
          me.input.bingo.setValue(me.input.remaining_Distance_in_Route.getValue()* 7 + 15 *36);
        }
      }else{
          # We could do here the complicated method
          # For that : route should exist.
          # All along the route, we should have enough fuel + 15 minutes to reach the nearest airport
          # I don't know how to do that. maybe cutting the route in 5 or 10 nm coords point and check this for closest airport.
          #this function will takes time
      }
      
    },
    update : func {
      # We do not need a high refresh rate. 4 refresh per scond should be enough
      #print("me.input.remaining_fuel.getValue():"~ me.input.remaining_fuel.getValue());
      #print("me.input.bingo.getValue():"~ me.input.bingo.getValue());
      if(me.input.remaining_fuel.getValue()<me.input.bingo.getValue()){ #bingo fuel
        #We could add a sound here : "bingo fuel" for the first time we are here
        me.make_it_blink();
      }else{
        me.input.blinking_bingo_low.setValue(0);
      }
      #settimer(me.update,0.25);
      
    },
    

};

 
      


# var bingo = func(moy)
# {
#     var lastWPtime = getprop("/instrumentation/gps/wp/wp[1]/TTW-sec");
#     print("/autopilot/route-manager/ete : " ~ getprop("/autopilot/route-manager/ete") ~ " instrumentation/gps/wp/wp[1]/TTW-sec : " ~ getprop("/instrumentation/gps/wp/wp[1]/TTW-sec"));
#     
#     Consommations moyennes: 4kg / Nm en HA. 7kg / Nm en BA (LA) or Average Consumption 36 kg/min
#     first -> Calculation of the last airport (route manager)
#     var remaining = getprop("/autopilot/route-manager/distance-remaining-nm");
#     
#     That means at Low Alt :
#     var bingo = remaining * 7;
#     
#     Add 30 min to the process
#     bingo = bingo + 36 * 30;
#     setprop("/instrumentation/consumables/bingo_fuel", bingo);
#     if(blinking == 0)
#     {
#         clignote();
#     }
#     
#     This is a simplified calculation of bingo fuel : We have to add a an
#     alternate airport in the calculation, but here it seeems to be a bit
#     complicated
#     Bingo :
#     Today Federal Aviation Regulations determine the amount of fuel an
#     aircraft must carry. Using Instrument Flight Rules (IFR), an aircraft
#     must carry enough fuel to:
#     - Complete the flight to the landing destination.
#     - Fly from that airport to an alternate airport.
#     - Fly after that for 45 minutes at normal cruising speed for that aircraft.
#     if(lastWPtime != nil and lastWPtime != "NaN")
#     {
#        lastWPtime = lastWPtime/60;
#        var bingo = moy * (lastWPtime + 45);
#        setprop("/instrumentation/consumables/bingo_fuel", bingo);
#        if(blinking == 0)
#        {
#            clignote();
#        }
#     }
# }

# This is for bingo fuel blinking light
# var clignote = func()
# {
#     # checking if bingo is reached :
#     if(getprop("/consumables/fuel/total-fuel-kg") < getprop("/instrumentation/consumables/bingo_fuel"))
#     {
#         if(getprop("/instrumentation/consumables/bingo_low") == 1)
#         {
#             # if light on then light off
#             setprop("/instrumentation/consumables/bingo_low", 0);
#         }
#         else
#         {
#             # if light off then light on
#             setprop("/instrumentation/consumables/bingo_low", 1);
#         }
#         blinking = 1;
#         settimer(clignote, 0.25);
#     }
#     else
#     {
#         # light off
#         setprop("/instrumentation/consumables/bingo_low", 0);
#         blinking = 0;
#     }
# }

var gearBox = func() {
    # Gear green Light management
    var energy = getprop("/systems/electrical/outputs/instrument-lights");
    if(getprop("/gear/gear[2]/position-norm") == 1 and energy)
    {
        setprop("/instrumentation/gearBox/rightgear", 1);
    }
    else
    {
        setprop("/instrumentation/gearBox/rightgear", 0);
    }
    
    if(getprop("/gear/gear[1]/position-norm") == 1 and energy)
    {
        setprop("/instrumentation/gearBox/leftgear", 1);
    }
    else
    {
        setprop("/instrumentation/gearBox/leftgear", 0);
    }
    
    if(getprop("/gear/gear[0]/position-norm") == 1 and energy)
    {
        setprop("/instrumentation/gearBox/nozegear", 1);
    }
    else
    {
        setprop("/instrumentation/gearBox/nozegear", 0);
    }
    
    # Gear Red Light
    if(energy and getprop("/gear/gear[0]/position-norm") != 1 and getprop("/gear/gear[0]/position-norm") != 0)
    {
        setprop("/instrumentation/gearBox/gearRed", 1);
    }
    else
    {
        setprop("/instrumentation/gearBox/gearRed", 0);
    }
    
    # AirBrakes
    if(energy and getprop("/fdm/jsbsim/fcs/airbrake-norm-sum") != 0)
    {
        setprop("/instrumentation/gearBox/AirBrakes", 1);
    }
    else
    {
        setprop("/instrumentation/gearBox/AirBrakes", 0);
    }
    
    # Brakes
    if(energy and getprop("/controls/gear/brake-left") != 0)
    {
        setprop("/instrumentation/gearBox/brakes", 1);
    }
    else
    {
        setprop("/instrumentation/gearBox/brakes", 0);
    }
}

var Tacan = func() {
    if(getprop("instrumentation/tacan/frequencies/selected-channel[4]") == "X")
    {
        setprop("instrumentation/tacan/frequencies/XPos", 1);
    }
    else
    {
        setprop("instrumentation/tacan/frequencies/XPos", -1);
    }
}


var display_heading = func(){
    var trackingNorth = getprop("instrumentation/efis/mfd/true-north");
    var magneticNorth = getprop("orientation/heading-magnetic-deg");
    var trueNorth = getprop("orientation/heading-deg");
    var bugbug = getprop("autopilot/internal/fdm-heading-bug-error-deg");
    
    if(getprop("instrumentation/efis/mfd/true-north")){
      setprop("instrumentation/mfd/heading-displayed",trueNorth);
      if(bugbug != nil){setprop("instrumentation/mfd/bug-heading-displayed",math.mod(bugbug + magneticNorth-trueNorth, 360));}
    }else{
      #To prevent bug detected by Chris
      magneticNorth = magneticNorth==nil?0:magneticNorth;
      setprop("instrumentation/mfd/heading-displayed",magneticNorth);
      if(bugbug != nil){setprop("instrumentation/mfd/bug-heading-displayed",bugbug);}
    }
    
    settimer(display_heading, 0.2);
}

display_heading();

var initIns = func()
{
    gearBox();
    Tacan();

    settimer(initIns, 0.5);
}

#Light Stuff can be considered as a part of the instrumentation--------------------------------------------------------
#----------------------------------------------------- Actual code--------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------
var strobe_switch = props.globals.getNode("/systems/electrical/outputs/strobe", 1);
aircraft.light.new("/sim/model/lights/strobe", [0.03, 1.5], strobe_switch);

var strobe2_switch = props.globals.getNode("/systems/electrical/outputs/strobe2", 1);
aircraft.light.new("/sim/model/lights/strobe2", [0.03, 1.4], strobe2_switch);

# tailLight
var tailLight_switch = props.globals.getNode("/systems/electrical/outputs/tailLight", 1);
aircraft.light.new("/sim/model/lights/tailLight", [0], tailLight_switch);

# position
var position_switch = props.globals.getNode("/systems/electrical/outputs/position", 1);
aircraft.light.new("/sim/model/lights/position", [0], position_switch);

# formation
var formation_switch = props.globals.getNode("/systems/electrical/outputs/formation-lights", 1);
aircraft.light.new("/sim/model/lights/formation", [0], formation_switch);

# Landing
var landing1_switch = props.globals.getNode("/systems/electrical/outputs/landing-lights", 1);
aircraft.light.new(props.globals.getNode("/sim/model/lights/landing"), [0], landing1_switch);

var ap_blink = aircraft.light.new("/sim/model/lights/pa-blink", [0.4, 0.4], "/autopilot/locks/FD-status");

var encodeLight = func(){
    var mycomp = strobe_switch.getValue() ~ strobe2_switch.getValue() ~ tailLight_switch.getValue() ~ position_switch.getValue() ~ formation_switch.getValue() ~ landing1_switch.getValue();
    var myIntBool = bits.value(mycomp);
    setprop("sim/multiplay/generic/int[8]", myIntBool);
}
#----------------------------------------------------------------------------------------------------------------#----------------------------------------------------------------------------------------------------------------#----------------------------------------------------------------------------------------------------------------
#Was before in the file named : MiscRwr.nas
var activate_ECM = func(){
    if(getprop("instrumentation/ecm/on-off") != "true" )
    {
        setprop("instrumentation/ecm/on-off", "true");
    }
    else
    {
        setprop("instrumentation/ecm/on-off", "false");
    }
}


var stallwarning = func(){
    # @TODO : Stall warning ! should be in instruments
    var stallwarning = "0";
    if(wow.getValue() == 0)
    {
        # STALL ALERT !
        if(AngleOfAttack.getValue() >= 29 or AirSpeed.getValue() < 100)
        {
            stallwarning = "2";
        }
        # STALL WARNING
        elsif(AngleOfAttack.getValue() >= 20 or AirSpeed.getValue() < 130)
        {
            stallwarning = "1";
        }
    }
    setprop("/sim/alarms/stall-warning", stallwarning);
}
