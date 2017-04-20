print("*** LOADING light.nas ... ***");
################################################################################
#
#                             m2005-5's LIGHTS SETTINGS
#
################################################################################

#----------------------------------------------------- Actual code
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

