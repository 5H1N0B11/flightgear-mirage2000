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
    var searchname = ["fuel-and-payload", "iff"];
    var state = 1;
    if (getprop("payload/armament/msg")) {
	state = 0;
    }

    foreach(var menu ; props.globals.getNode("/sim/menubar/default").getChildren("menu"))
    {
        foreach(var item ; menu.getChildren("item"))
        {
            foreach(var name ; item.getChildren("name"))
            {
                if (vecindex(searchname, name.getValue()) != nil)
                {
                    # state = item.getNode("enabled").getBoolValue();
                    item.getNode("enabled").setBoolValue(state);
                }
            }
        }
    }
}

setlistener("/gear/gear/WOW", enableGuiLoad);
setlistener("/payload/armament/msg", enableGuiLoad);

var BingoCalculator = {
	new : func {
		var me  = {
			parents : [BingoCalculator]
		};
		me.input = {
			blinking_bingo_low:           "/instrumentation/consumables/bingo_low", # Blinking variable
			bingo:                        "/instrumentation/consumables/bingo_fuel",
			remaining_fuel:               "/consumables/fuel/total-fuel-kg",
		};
		foreach(var name; keys(me.input)) {
			me.input[name] = props.globals.getNode(me.input[name], 1);
		}
		me.input.bingo.setValue(480); # default value
		return me;
	},

	_makeItBlink : func {
		me.input.blinking_bingo_low.setValue(!me.input.blinking_bingo_low.getValue());
	},

	update : func { # called in loop in m2000-5.nas
		if (me.input.remaining_fuel.getValue()<me.input.bingo.getValue()) { #bingo fuel
			me._makeItBlink();
		} else {
			me.input.blinking_bingo_low.setValue(0);
		}
	},
};


var gearBox = func() {
    # Gear green Light management
    var energy = getprop("/systems/electrical/outputs/instrument-lights");
    if (getprop("/gear/gear[2]/position-norm") == 1 and energy)
    {
        setprop("/instrumentation/gearBox/rightgear", 1);
    }
    else
    {
        setprop("/instrumentation/gearBox/rightgear", 0);
    }

    if (getprop("/gear/gear[1]/position-norm") == 1 and energy)
    {
        setprop("/instrumentation/gearBox/leftgear", 1);
    }
    else
    {
        setprop("/instrumentation/gearBox/leftgear", 0);
    }

    if (getprop("/gear/gear[0]/position-norm") == 1 and energy)
    {
        setprop("/instrumentation/gearBox/nozegear", 1);
    }
    else
    {
        setprop("/instrumentation/gearBox/nozegear", 0);
    }

    # Gear Red Light
    if (energy and getprop("/gear/gear[0]/position-norm") != 1 and getprop("/gear/gear[0]/position-norm") != 0)
    {
        setprop("/instrumentation/gearBox/gearRed", 1);
    }
    else
    {
        setprop("/instrumentation/gearBox/gearRed", 0);
    }

    # AirBrakes
    if (energy and getprop("/fdm/jsbsim/fcs/airbrake-norm-sum") != 0)
    {
        setprop("/instrumentation/gearBox/AirBrakes", 1);
    }
    else
    {
        setprop("/instrumentation/gearBox/AirBrakes", 0);
    }

    # Brakes
    if (energy and getprop("/controls/gear/brake-left") != 0)
    {
        setprop("/instrumentation/gearBox/brakes", 1);
    }
    else
    {
        setprop("/instrumentation/gearBox/brakes", 0);
    }
}

var Tacan = func() {
    if (getprop("instrumentation/tacan/frequencies/selected-channel[4]") == "X")
    {
        setprop("instrumentation/tacan/frequencies/XPos", 1);
    }
    else
    {
        setprop("instrumentation/tacan/frequencies/XPos", -1);
    }
}


var display_heading = func() {
    var trackingNorth = getprop("instrumentation/efis/mfd/true-north");
    var magneticNorth = getprop("orientation/heading-magnetic-deg");
    var trueNorth = getprop("orientation/heading-deg");
    var bugbug = getprop("autopilot/internal/fdm-heading-bug-error-deg");

    if (getprop("instrumentation/efis/mfd/true-north")) {
      setprop("instrumentation/mfd/heading-displayed",trueNorth);
      if (bugbug != nil) {setprop("instrumentation/mfd/bug-heading-displayed",math.mod(bugbug + magneticNorth-trueNorth, 360));}
    } else {
      #To prevent bug detected by Chris
      magneticNorth = magneticNorth==nil?0:magneticNorth;
      setprop("instrumentation/mfd/heading-displayed",magneticNorth);
      if (bugbug != nil) {setprop("instrumentation/mfd/bug-heading-displayed",bugbug);}
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

var encodeLight = func() {
    var mycomp = strobe_switch.getValue() ~ strobe2_switch.getValue() ~ tailLight_switch.getValue() ~ position_switch.getValue() ~ formation_switch.getValue() ~ landing1_switch.getValue();
    var myIntBool = bits.value(mycomp);
    setprop("sim/multiplay/generic/int[8]", myIntBool);
}
#----------------------------------------------------------------------------------------------------------------#----------------------------------------------------------------------------------------------------------------#----------------------------------------------------------------------------------------------------------------
#Was before in the file named : MiscRwr.nas
var activate_ECM = func() {
    if (getprop("instrumentation/ecm/on-off") != "true" )
    {
        setprop("instrumentation/ecm/on-off", "true");
    }
    else
    {
        setprop("instrumentation/ecm/on-off", "false");
    }
}

var checkStallWarning = func() {
	var stallwarning = "0";
	if (wow.getValue() == 0) {
		# STALL ALERT !
		if (AngleOfAttack.getValue() >= 29 or AirSpeed.getValue() < 100) {
			stallwarning = "2";
		}
		# STALL WARNING
		elsif (AngleOfAttack.getValue() >= 20 or AirSpeed.getValue() < 130) {
			stallwarning = "1";
		}
	}
	setprop("/sim/alarms/stall-warning", stallwarning);
}

var checkConfigurationCategory = func() {
	var mismatch = 0;
	if (pylons.fcs != nil) {
		var config = getprop("fdm/jsbsim/fbw/mode");
		if (pylons.fcs.getCategory() > 1 and config == 0) {
			mismatch = 1;
		} elsif (pylons.fcs.getCategory() == 1 and config > 0) {
			mismatch = 1;
		}
	}
	setprop("instrumentation/failures-panel/conf-cat-mismatch", mismatch);
}
