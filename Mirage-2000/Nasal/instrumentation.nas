print("*** LOADING instrumentation.nas ... ***");
################################################################################
#
#                       m2005-5's INSTRUMENTS SETTINGS
#
################################################################################

var blinking     = 0;
var viewNum      = 1;
var isHUDvisible = 1;

# displays hud if avionics is on
var viewHUD = func()
{
    voltsHud = getprop("/systems/electrical/volts");
    var internalHUD_selected = getprop("/controls/hud");
    if(voltsHud > 12 and internalHUD_selected)
    {
        setprop("/sim/hud/visibility[1]", 1);
    }
    else
    {
        setprop("/sim/hud/visibility[1]", 0);
    }
}

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

var convertTemp = func()
{
    # '''' hardball's note
    # ' why not move all conversion functions in a single file ?
    var degF = getprop("/engines/engine[0]/egt-degf");
    if(degF != nil)
    {
        var degC = (degF - 32) * 5 / 9;
        setprop("engines/engine[0]/egt-degC", degC);
    }
}

var average_fuel = func()
{
    # 1 litter of fuel = 0.87 kg and 1 gallon = 3.7854118 litters
    # in kg...
    var consumption = getprop("/engines/engine[0]/fuel-flow-gph");
    var time = getprop("/sim/time/elapsed-sec");
    
    # refreshing time in sec
    if(int(int(time) / 1) == int(time) / 1 )
    {
        if(consumption != nil)
        {
            # in kg fuel per hour
            consumption = consumption * 3.7854118 * 0.87;
            
            # Per min
            consumption = consumption / 60;
            
            # Old name, need to be changed
            setprop("instrumentation/consumables/consumption_per_min", consumption);
            
            # Average Consumption 36 kg/min
            bingo(50);
        }
    }
    var remain_fuel = getprop("/consumables/fuel/total-fuel-kg");
    if(remain_fuel != nil)
    {
        remain_fuel -= 100;
        if(remain_fuel < 0)
        {
            remain_fuel = 0;
        }
        setprop("/instrumentation/consumables/remain_fuel", remain_fuel);
    }
}

var bingo = func(moy)
{
    var lastWPtime = getprop("/instrumentation/gps/wp/wp[1]/TTW-sec");
    #print("/autopilot/route-manager/ete : " ~ getprop("/autopilot/route-manager/ete") ~ " instrumentation/gps/wp/wp[1]/TTW-sec : " ~ getprop("/instrumentation/gps/wp/wp[1]/TTW-sec"));
    
    # Consommations moyennes: 4kg / Nm en HA. 7kg / Nm en BA (LA) or Average Consumption 36 kg/min
    # first -> Calculation of the last airport (route manager)
    var remaining = getprop("/autopilot/route-manager/distance-remaining-nm");
    
    # That means at Low Alt :
    var bingo = remaining * 7;
    
    # Add 30 min to the process
    bingo = bingo + 36 * 30;
    setprop("/instrumentation/consumables/bingo_fuel", bingo);
    if(blinking == 0)
    {
        clignote();
    }
    
    # This is a simplified calculation of bingo fuel : We have to add a an
    # alternate airport in the calculation, but here it seeems to be a bit
    # complicated
    # Bingo :
    # Today Federal Aviation Regulations determine the amount of fuel an
    # aircraft must carry. Using Instrument Flight Rules (IFR), an aircraft
    # must carry enough fuel to:
    # - Complete the flight to the landing destination.
    # - Fly from that airport to an alternate airport.
    # - Fly after that for 45 minutes at normal cruising speed for that aircraft.
    #if(lastWPtime != nil and lastWPtime != "NaN")
    #{
    #    lastWPtime = lastWPtime/60;
    #    var bingo = moy * (lastWPtime + 45);
    #    setprop("/instrumentation/consumables/bingo_fuel", bingo);
    #    if(blinking == 0)
    #    {
    #        clignote();
    #    }
    #}
}

# This is for bingo fuel blinking light
var clignote = func()
{
    # checking if bingo is reached :
    if(getprop("/consumables/fuel/total-fuel-kg") < getprop("/instrumentation/consumables/bingo_fuel"))
    {
        if(getprop("/instrumentation/consumables/bingo_low") == 1)
        {
            # if light on then light off
            setprop("/instrumentation/consumables/bingo_low", 0);
        }
        else
        {
            # if light off then light on
            setprop("/instrumentation/consumables/bingo_low", 1);
        }
        blinking = 1;
        settimer(clignote, 0.25);
    }
    else
    {
        # light off
        setprop("/instrumentation/consumables/bingo_low", 0);
        blinking = 0;
    }
}

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
    if(energy and getprop("/surface-positions/spoiler-pos-norm") != 0)
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
      setprop("instrumentation/mfd/heading-displayed",getprop("orientation/heading-magnetic-deg"));
      if(bugbug != nil){setprop("instrumentation/mfd/bug-heading-displayed",bugbug);}
    }
    
    settimer(display_heading, 0.2);
}

display_heading();

var initIns = func()
{
    convertTemp();
    average_fuel();
    viewHUD();
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
