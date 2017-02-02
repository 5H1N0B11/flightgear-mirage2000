print("*** LOADING light.nas ... ***");
################################################################################
#
#                             m2005-5's LIGHTS SETTINGS
#
################################################################################

#var sbc1        = aircraft.light.new("/sim/model/lights/sbc1", [0.5, 0.3]);
#sbc1.interval   = 0.1;
#sbc1.switch(1);
#var sbc2        = aircraft.light.new("/sim/model/lights/sbc2", [0.2, 0.3], "/sim/model/lights/sbc1/state");
#sbc2.interval   = 0;
#sbc2.switch(1);

#setlistener("/sim/model/lights/sbc2/state", func(n)
#{
    #var bsbc1 = sbc1.stateN.getValue();
   # var bsbc2 = n.getBoolValue();
    #var b = 0;
    #if(bsbc1
        #and bsbc2
      #  and getprop("/controls/lighting/beacon"))
    #{
  #      b = 1;
#    }
    #else
    #{
      #  b = 0;
    #}
    #setprop("/sim/model/lights/beacon/enabled", b);
    
    #if(bsbc1
   #     and ! bsbc2
#        and getprop("/controls/lighting/strobe"))
    #{
   #     b = 1;
  #  }
#    else
    #{
   #     b = 0;
  #  }
 #   setprop("/sim/model/lights/strobe/enabled", b);
#});

#var beacon = aircraft.light.new("/sim/model/lights/beacon", [0.05, 0.05]);
#beacon.interval = 0;


#var strobe = aircraft.light.new("/sim/model/lights/strobe", [0.05, 0.05, 0.05, 1]);
#strobe.interval = 0;
#setprop("controls/lighting/ext-lighting-panel/anti-collision", 1);
#var strobe_switch = props.globals.getNode("/controls/lighting/strobe", 1);


#----------------------------------------------------- Actual code
var strobe_switch = props.globals.getNode("/systems/electrical/outputs/strobe", 1);
aircraft.light.new("/sim/model/lights/strobe", [0.03, 1.5], strobe_switch);

var strobe2_switch = props.globals.getNode("/systems/electrical/outputs/strobe2", 1);
aircraft.light.new("/sim/model/lights/strobe2", [0.03, 1.4], strobe2_switch);

#tailLight
var tailLight_switch = props.globals.getNode("/systems/electrical/outputs/tailLight", 1);
aircraft.light.new("/sim/model/lights/tailLight", [0], tailLight_switch);

#position
var position_switch = props.globals.getNode("/systems/electrical/outputs/position", 1);
aircraft.light.new("/sim/model/lights/position", [0], position_switch);

#formation
var formation_switch = props.globals.getNode("/systems/electrical/outputs/formation-lights", 1);
aircraft.light.new("/sim/model/lights/formation", [0], formation_switch);

#Landing
var landing1_switch = props.globals.getNode("/systems/electrical/outputs/landing-lights", 1);
aircraft.light.new(props.globals.getNode("/sim/model/lights/landing"), [0], landing1_switch);

var ap_blink = aircraft.light.new("/sim/model/lights/pa-blink", [0.4, 0.4], "/autopilot/locks/FD-status");

var encodeLight = func(){
  #print("strobe_switch:"~strobe_switch.getValue());
  #print("strobe2_switch:"~strobe2_switch.getValue());
  #print("tailLight_switch:"~tailLight_switch.getValue());
  #print("position_switch:"~position_switch.getValue());
  #print("formation_switch:"~formation_switch.getValue());
  #print("landing1_switch:"~landing1_switch.getValue());
  var mycomp = strobe_switch.getValue()~strobe2_switch.getValue()~tailLight_switch.getValue()~position_switch.getValue()~formation_switch.getValue()~landing1_switch.getValue();
  #print("comp:",mycomp);
  var myIntBool = bits.value(mycomp);
  setprop("sim/multiplay/generic/int[8]",myIntBool);
  #print("bits.value:"~myBool);
  #print("DecodeMyBool:"~bits.string(myBool));
  #var receivedString = bits.string(myBool,6);
  #for (var i = 0; i < size(receivedString); i += 1)
    #print("MyStrobe:"~chr(receivedString[i]));
}

