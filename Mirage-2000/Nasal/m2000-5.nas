print("*** LOADING m2000-5.nas ... ***");
################################################################################
#
#							   m2005-5's SYSTEMS SETTINGS
#
################################################################################
#
# Typhonn systems
# crazy dj nasal from many sources...
# and also, almursi work
# and 5H1N0B1

var FALSE = 0;
var TRUE = 1;

var deltaT                = 1.0;
var Elapsed_time_Seconds  = 0;
var Elapsed_time_previous = 0;
var LastTime              = 0;
# Elapsed for time > 0.25 sec
var Elapsed               = 0;
var myErr                 = [];
var myFramerate           = {a:0,b:0,c:0,d:0,e:0,f:0};#a = 0.1, b=0.2, c = 0.5, d=1, e=1.5 ; f = 2
var EjectionKey           = 0;


var msgB = "Please land before changing payload.";


#====== OBJECT CREATION =======

setprop("/instrumentation/radar/az-fieldCenter", 0);

var prop = "payload/armament/fire-control";
var actuator_fc = compat_failure_modes.set_unserviceable(prop);
FailureMgr.add_failure_mode(prop, "Fire control", actuator_fc);

var bingo_calculator = nil;


############################################################
# Global loop function
# If you need to run nasal as loop, add it in this function
############################################################
var global_system_loop = func{
	mirage2000.weather_effects_loop();
}

#===============================


var InitListener = setlistener("/sim/signals/fdm-initialized", func() {
	_mainInitLoop();
	removelistener(InitListener);
});

# Main init loop
# Perhaps in the future, make an object for each subsystems, in the same way
# of "engine"
var _mainInitLoop = func() {
	hack.init();
	# Loop Updated inside
	#print("Electrical ... Check");
	electrics.Electrical_init();

	# Loop Updated inside
	#print("Fuel ... Check");
	#fuel.Fuel_init();

	# Loop Updated below
	# print("Stability Augmentation System ... Check");
	# mirage2000.init_SAS();

	print("Intrumentation ... Check");
	instrumentation.initIns();

	#print("Radar ... Check");

	print("Flight Director ... Check");
	mirage2000.init_set();

	print("Transponder ... Check");
	init_Transpondeur();

	print("blackout ... Check");
	blackout.blackout_init();

	print("VTM canvas ... Check");

	print("MFD ... Check");
	mirage2000.setCentralMFD();
	if (getprop("/instrumentation/efis/Mode")) {
		mirage2000.mfdSelection();
	}
	print("Missile view ... Check");
	viewMissile.init_missile_view();

	environment.environment();
	#Should be replaced by an object creation
	#settimer(func() {mirage2000.createMap();},10);

	bingo_calculator = instrumentation.BingoCalculator.new();
	bingo_calculator.update();

	rtExec_loop(); # to make the ememsary FrameNotification work

	_setupCustomStickBindings();

	print("System loop ... Check");
	_updateMain();
} # END _mainInitLoop()

var _setupCustomStickBindings = func {
	call(func {
		append(joystick.buttonBindings, joystick.NasalHoldButton.new  ("Cursor Click", 'setprop("controls/displays/cursor-click",1);', 'setprop("controls/displays/cursor-click",0);'));
		append(joystick.axisBindings,   joystick.PropertyScaleAxis.new("Cursor Vertical", "/controls/displays/cursor-slew-y"));
		append(joystick.axisBindings,   joystick.PropertyScaleAxis.new("Cursor Horizontal", "/controls/displays/cursor-slew-x"));
	},nil,var err=[]);
}


var _updateMain = func {
	settimer(mirage2000._updateFunction, 0);
}

#This update function needs to be re-done properly
var _updateFunction = func() {
	AbsoluteTime = getprop("/sim/time/elapsed-sec");
	#Things to update, order by refresh rate.

	var AP_Alt = getprop("/autopilot/locks/altitude");

	########################### rate 0
	# mirage2000.Update_SAS(); #we need to check what is still here, and what we can convert in xml

	#	 if (getprop("payload/armament/es/flags/deploy-id-10")!= nil) {
	#		 setprop("instrumentation/ejection/force", 7-5*getprop("payload/armament/es/flags/deploy-id-10"));
	#	 } else {
	#		 setprop("instrumentation/ejection/force", 7);
	#	 }

	# Flight Director (autopilot)
	if (getprop("/autopilot/locks/AP-status") == "AP1") {
		call(mirage2000.update_fd,nil,nil,nil, myErr= []);
		if (size(myErr)>0) {
			foreach(var i;myErr) {
				print(i);
			}
		}
	}

	################## Rate 0.1 ##################
	if (AbsoluteTime - myFramerate.a > 0.05) {
		call(mirage2000.theShakeEffect,nil,nil,nil, myErr);
		myFramerate.a = AbsoluteTime;
	}

	################## Rate 0.25 ##################
	if (AbsoluteTime - myFramerate.b > 0.25) {
		mirage2000.mfd_update_main();
		mirage2000.Intake_pelles();
		instrumentation.checkStallWarning();
		myFramerate.b = AbsoluteTime;
	}


	################## rate 0.5 ###############################
	if (AbsoluteTime - myFramerate.c > 0.5) {
		#call(m2000_load.Encode_Load,nil,nil,nil, myErr);
		call(m2000_mp.Encode_Bool,nil,nil,nil, myErr);
		#if (getprop("autopilot/settings/tf-mode")) { <- need to find what is enabling it
		#8 second prevision do not need to be updated each fps
		if (AP_Alt =="TF") {
			call(mirage2000.tfs_radar,nil,nil,nil, myErr= []);
			if (size(myErr)) {
				foreach(var i;myErr) {
					print(i);
				}
			}
		}
		bingo_calculator.update(); # needs high frequency due to blinking

		#mirage2000.weather_effects_loop();
		#environment.environment();
		#call(environment.low_loop,nil,nil,nil, myErr);
		#if (size(myErr)>0) {
		#	#debug.printerror(myErr);
		#}
		myFramerate.c = AbsoluteTime;
	}


	###################### rate 1 ###########################
	if (AbsoluteTime - myFramerate.d > 1) {
		#call(mirage2000.fuel_managment,nil,nil,nil, myErr);
		if (getprop("/autopilot/locks/AP-status") != "AP1") {
			call(mirage2000.update_fd,nil,nil,nil, myErr= []);
			if (size(myErr)>0) {
				foreach(var i;myErr) {
					print(i);
				}
			}
		}
		myFramerate.d = AbsoluteTime;
		mp_messaging();
		_checkGroundMode();
	}

	###################### rate 1.5 ###########################
	if (AbsoluteTime - myFramerate.e > 1.5) {
		call(environment.environment,nil,nil,nil, myErr);
		if (size(myErr)>0) {
			#debug.printerror(myErr);
		}
		call(environment.max_cloud_layer,nil,nil,nil, myErr);
		if (size(myErr)>0) {
		 #debug.printerror(myErr);
		}

		myFramerate.e = AbsoluteTime;
	}

	###################### rate 2 ###########################
	if (AbsoluteTime - myFramerate.f > 2) {
		if (AP_Alt =="TF") {
			call(mirage2000.long_view_avoiding,nil,nil,nil, myErr);
			if (size(myErr)>0) {
				foreach(var i;myErr) {
					print(i);
				}
			}
		}
		instrumentation.checkConfigurationCategory();

		myFramerate.f = AbsoluteTime;
	}

	# Update at the end
	call(mirage2000._updateMain,nil,nil,nil, myErr);
} # END _updateFunction()

var init_Transpondeur = func() {
	# Init Transponder
	var poweroften = [1, 10, 100, 1000];
	var idcode = getprop('/instrumentation/transponder/id-code');

	if (idcode != nil) {
		for(var i = 0 ; i < 4 ; i += 1) {
			setprop("/instrumentation/transponder/inputs/digit[" ~ i ~ "]", int(math.mod(idcode / poweroften[i], 10)));
		}
	}
}

controls.deployChute = func(v) {
	doors.parachute.toggle();
	# Deploy
	if (v > 0) {
		if (getprop("controls/flight/chute_deployed") != 1)
		{
			setprop("controls/flight/chute_deployed", 1);
			setprop("controls/flight/chute_open", 1);
		}else{
			setprop("controls/flight/chute_deployed", 0);
			setprop("controls/flight/chute_open", 0);
		}
		chuteLoop.start();
	}
	# Jettison
	if (v < 0) {
		var voltage = getprop("systems/electrical/outputs/chute_jett");
		if (voltage > 20) {
			setprop("controls/flight/chute_jettisoned", 1);
			setprop("controls/flight/chute_open", 0);
			chuteLoop.stop();
		}
	}
}

var chuteAngle = func {
	var chute_open = getprop('controls/flight/chute_open');
	if (chute_open != '1') {
		setprop("fdm/jsbsim/external_reactions/chute/magnitude", 0);
		chuteLoop.stop();
		return();
	}
	var speed = getprop('/velocities/airspeed-kt');
	var aircraftpitch = getprop('/orientation/pitch-deg[0]');
	var aircraftyaw = getprop('/orientation/side-slip-deg');
	var chuteyaw = getprop("orientation/chute_yaw");
	var aircraftroll = getprop('/orientation/roll-deg');

	if (speed > 250) {
		setprop("controls/flight/chute_jettisoned", 1); # Model Shear Pin
		setprop("fdm/jsbsim/external_reactions/chute/magnitude", 0);
		chuteLoop.stop();
		return();
	}
	# Chute Pitch
	var chutepitch = aircraftpitch * -1;
	setprop("orientation/chute_pitch", chutepitch);

	# Damped yaw from Vivian's A4 work
	var n = 0.01;
	if (aircraftyaw == nil) {
		aircraftyaw = 0;
	}
	if (chuteyaw == nil) {
		chuteyaw = 0;
	}
	var chuteyaw = (aircraftyaw * n) + (chuteyaw * (1 - n));
	setprop("orientation/chute_yaw", chuteyaw);

	# Chute Roll - no twisting for now
	var chuteroll = aircraftroll;
	setprop("orientation/chute_roll", chuteroll * rand() * -1);

	var pressure = getprop("fdm/jsbsim/aero/qbar-psf"); # dynamic pressure
        var chuteArea = 200; # squarefeet of chute canopy
        var dragCoeff = 0.50;
        var force     = pressure * chuteArea * dragCoeff;
        setprop("fdm/jsbsim/external_reactions/chute/magnitude", force);
}

var chuteRepack = func {
	setprop('controls/flight/chute_open', 0);
	setprop('controls/flight/chute_deployed', 0);
	setprop('controls/flight/chute_jettisoned', 0);
}

var chuteLoop = maketimer(0.05, chuteAngle);

var fuel_managment = func() {
	var Externaltank = getprop("/consumables/fuel/tank[2]/empty");
	Externaltank *= getprop("/consumables/fuel/tank[3]/empty");
	Externaltank *= getprop("/consumables/fuel/tank[4]/empty");
	# If only one external Tank is still not empty, then...
	# systems/refuel/contact = false si pas refuel en cours
	if (getprop("/systems/refuel/contact")) {
		setprop("/consumables/fuel/tank[0]/selected", 1);
		setprop("/consumables/fuel/tank[1]/selected", 1);

		if (getprop("/consumables/fuel/tank[2]/capacity-m3") != 0) {
			setprop("/consumables/fuel/tank[2]/selected", 1);
		}
		if (getprop("/consumables/fuel/tank[3]/capacity-m3") != 0) {
			setprop("/consumables/fuel/tank[3]/selected", 1);
		}
		if (getprop("/consumables/fuel/tank[4]/capacity-m3") != 0) {
			setprop("/consumables/fuel/tank[4]/selected", 1);
		}
	}
	elsif (Externaltank) {
		setprop("/consumables/fuel/tank[0]/selected", 1);
		setprop("/consumables/fuel/tank[1]/selected", 1);
	}
	else {
		setprop("/consumables/fuel/tank[0]/selected", 0);
		setprop("/consumables/fuel/tank[1]/selected", 0);
		if (getprop("/consumables/fuel/tank[2]/level-kg") > 0) {
			setprop("/consumables/fuel/tank[2]/selected", 1);
		}
		if (getprop("/consumables/fuel/tank[3]/level-kg") > 0) {
			setprop("/consumables/fuel/tank[3]/selected", 1);
		}
		if (getprop("/consumables/fuel/tank[4]/level-kg") > 0) {
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
	var rSpeed  = getprop("/velocities/airspeed-kt") or 0;
	var G       = getprop("/accelerations/pilot-g");
	var alpha   = getprop("/orientation/alpha-deg");
	var mach    = getprop("velocities/mach");
	var wow     = getprop("/gear/gear[1]/wow");
	var gun     = getprop("controls/armament/Gun_trigger");
	var myTime  = getprop("/sim/time/elapsed-sec");

	#sf = ((rSpeed / 500000 + G / 25000 + alpha / 20000 ) / 3) ;
	# I want to find a way to improve vibration amplitude with sf, but to tired actually to make it.

	if (shakeEffect2000.getBoolValue() and (((G > 9 or alpha > 25) and rSpeed > 30) or (mach > 0.99 and mach < 1.01) or (wow and rSpeed > 100) or gun)) {
		setprop("controls/cabin/shaking", math.sin(48 * myTime) / 333.333);
	}
	else {
		setprop("controls/cabin/shaking", 0);
	}
}

var setCentralMFD = func() {
	setprop("/instrumentation/efis/Mode", 1);
	if (getprop("/instrumentation/efis/Mode")) {
		mirage2000.mfdSelection();
	}
}

# to prevent dynamic view to act like helicopter due to defining <rotors>:
dynamic_view.register(func {me.default_plane();});



var test = func() {
	if (! contains(globals, "m2000_mp")) {
		var err = [];
		var myTree = props.globals.getNode("/sim");
		var raw_list = myTree.getChildren();
		foreach(var c ; raw_list) {
			if (c.getName() == "fg-aircraft") {
				myAircraftTree = "/sim/" ~ c.getName()~"["~c.getIndex()~"]";
				print(myAircraftTree);
				var err = [];
				var file = getprop(myAircraftTree) ~ "/Mirage-2000/Nasal/MP.nas";
				print(file);
				var code = call(func compile(io.readfile(file), file), nil, err);
				print("Path 0. Error : " ~size(err));
				if (size(err) == 0) {
					call(func {io.load_nasal(file, "m2000_mp");},nil, err);
					if (size(err)) {
						print("Path 0a. Error : ");
						foreach(lin;err) print(lin);
					} else {
						break;
					}
				} else {
					print("Path 0b. Error : ");
					foreach(lin;err) print(lin);
				}
			}
		}
	}
}


# There is already function code_ct in damage.nas, which does most of the work across the OPRF fleet
# with a 1 second timer.
# Therefore, this method only needs to do M2000 specific stuff.
var mp_messaging = func() {
	if (getprop("/payload/armament/msg")) {
		if (!getprop("/gear/gear[0]/wow")) {
			call(func{fgcommand('dialog-close', props.Node.new({"dialog-name": "payload-5"}))},nil,var err2 = []);
			call(func{fgcommand('dialog-close', props.Node.new({"dialog-name": "payload-d"}))},nil,var err2 = []);
			call(func{fgcommand('dialog-close', props.Node.new({"dialog-name": "mission-preplanning"}))},nil,var err2 = []);
		}
	}
}


var ejection = func() {
	print("Ejection");
	if (getprop("instrumentation/ejection/done")==1) {
		return;
	}
	EjectionKey = EjectionKey +1;
	print("EjectionKey:"~EjectionKey);

	if (EjectionKey<3) {
		settimer(mirage2000.init_EjectionKey, 2.0);
		return;
	}

	setprop("instrumentation/ejection/done",1);

	var es = armament.AIM.new(10, "es","gamma", nil ,[-3.65,0,0.7]);

	es.releaseAtNothing();
	viewMissile.view_firing_missile(es);
	setprop("sim/view[0]/enabled",0);
	# settimer(func {crash.exp();},3.5);
}

var init_EjectionKey = func() {
	EjectionKey = 0;
}


var setFlightMode = func (mode) {
	setprop("/instrumentation/flightmode/selected", mode);
	viewReset();
}

var viewReset = func () {
	if (getprop("/sim/current-view/view-number-raw") == 0) {
		var mode = getprop("/instrumentation/flightmode/selected");
		setprop("sim/current-view/heading-offset-deg", 0);
		setprop("sim/current-view/roll-offset-deg", 0);
		# degs must be before -m
		setprop("/sim/current-view/x-offset-m",0);
		if (mode == constants.FLIGHT_MODE_GROUND) {
			setprop("sim/current-view/pitch-offset-deg", -15);
			setprop("/sim/current-view/y-offset-m",0.100); # if seat too high then the horizon line is not visible
			setprop("/sim/current-view/z-offset-m",-2.9);
			setprop("/sim/current-view/field-of-view",75);
		} else if (mode == constants.FLIGHT_MODE_APPROACH or mode == constants.FLIGHT_MODE_GROUND) {
			setprop("sim/current-view/pitch-offset-deg", -15);
			setprop("/sim/current-view/y-offset-m",0.1400);
			setprop("/sim/current-view/z-offset-m",-2.9);
			setprop("/sim/current-view/field-of-view",75);
		} elsif (mode == constants.FLIGHT_MODE_NAVIGATION) {
			setprop("sim/current-view/pitch-offset-deg", -12);
			setprop("/sim/current-view/y-offset-m",0.025);
			setprop("/sim/current-view/z-offset-m",-2.9);
			setprop("/sim/current-view/field-of-view",83);
		} elsif (mode == constants.FLIGHT_MODE_ATTACK) {
			setprop("sim/current-view/pitch-offset-deg", -15);
			setprop("/sim/current-view/y-offset-m",0.099);
			setprop("/sim/current-view/z-offset-m",-2.77);
			setprop("/sim/current-view/field-of-view",65);
		}
	}
}

var viewLeftMFD = func() {
	if (getprop("/sim/current-view/view-number-raw") == 0) {
		setprop("sim/current-view/heading-offset-deg", 0);
		setprop("sim/current-view/pitch-offset-deg", -12);
		setprop("sim/current-view/roll-offset-deg", 0);
		setprop("/sim/current-view/x-offset-m", -0.12);
		setprop("/sim/current-view/y-offset-m",-0.22);
		setprop("/sim/current-view/z-offset-m",-3.04);
		setprop("/sim/current-view/field-of-view",80);
	}
}

var viewRightMFD = func() {
	if (getprop("/sim/current-view/view-number-raw") == 0) {
		setprop("sim/current-view/heading-offset-deg", 0);
		setprop("sim/current-view/pitch-offset-deg", -12);
		setprop("sim/current-view/roll-offset-deg", 0);
		setprop("/sim/current-view/x-offset-m", 0.12);
		setprop("/sim/current-view/y-offset-m",-0.24);
		setprop("/sim/current-view/z-offset-m",-3.04);
		setprop("/sim/current-view/field-of-view",80);
	}
}

var viewVTM = func() {
	if (getprop("/sim/current-view/view-number-raw") == 0) {
		setprop("sim/current-view/heading-offset-deg", 0);
		setprop("sim/current-view/pitch-offset-deg", -12);
		setprop("sim/current-view/roll-offset-deg", 0);
		setprop("/sim/current-view/x-offset-m", 0);
		setprop("/sim/current-view/y-offset-m",-0.07);
		setprop("/sim/current-view/z-offset-m",-3.18);
		setprop("/sim/current-view/field-of-view",80);
	}
}

var toggleNavApproachMode = func {
	var mode = getprop("/instrumentation/flightmode/selected");
	if (mode == constants.FLIGHT_MODE_APPROACH) {
		setFlightMode(constants.FLIGHT_MODE_NAVIGATION);
	} else if (mode == constants.FLIGHT_MODE_NAVIGATION) {
		setFlightMode(constants.FLIGHT_MODE_APPROACH);
	} else if (mode == constants.FLIGHT_MODE_ATTACK) {
		setFlightMode(constants.FLIGHT_MODE_NAVIGATION);
	}
	# else nothing to do - cannot toggle from GROUND
}

var _checkGroundMode = func {
	var mode = getprop("/instrumentation/flightmode/selected");
	if (mode != constants.FLIGHT_MODE_GROUND and getprop("/gear/gear[1]/wow")) {
		setFlightMode(constants.FLIGHT_MODE_GROUND);
	}
}

var masterarm = func {
	var now = getprop("controls/armament/master-arm-switch");
	now += 1;
	if (now > 1) {
		now = 0;
	}
	setprop("controls/armament/master-arm-switch", now);
	screen.log.write("Master-arm "~(getprop("controls/armament/master-arm-switch")==0?"OFF":(getprop("controls/armament/master-arm-switch")==1?"ON":"SIM")), 0.5, 0.5, 1);
}

var toggleDropModeCCxP = func {
	var mode = pylons.fcs.getDropMode();
	if (mode == 0) { # CCRP = 0, CCIP =
		pylons.fcs.setDropMode(1);
	} else {
		pylons.fcs.setDropMode(0);
	}
}

var _selectNewWeapon = func (mode) {
	pylons.fcs.cycleLoadedWeapon();
	if (mode == constants.FLIGHT_MODE_ATTACK and pylons.fcs.getSelectedType() == nil) {
		setFlightMode(constants.FLIGHT_MODE_NAVIGATION);
	} else if (mode == constants.FLIGHT_MODE_NAVIGATION and pylons.fcs.getSelectedType() != nil) {
		setFlightMode(constants.FLIGHT_MODE_ATTACK);
	}
}

var cycleLoadedWeapon = func {
	var mode = getprop("/instrumentation/flightmode/selected");
	if (mode == constants.FLIGHT_MODE_NAVIGATION) {
		# just try to get into ATTACK mode, but do not switch weapon if already selected
		if (pylons.fcs.getSelectedType() != nil) {
			setFlightMode(constants.FLIGHT_MODE_ATTACK);
		} else {
			_selectNewWeapon(mode);
		}
	} else {
		_selectNewWeapon(mode);
	}
}

var changeGearsPosition = func(is_up) {
	if (is_up == TRUE and (getprop("/gear/gear[1]/wow") or getprop("/gear/gear[2]/wow"))) {
		return; # we do not want to shift position on ground!
	}
	if (is_up == TRUE) {
		var mode = getprop("/instrumentation/flightmode/selected");
		if (mode == constants.FLIGHT_MODE_GROUND) {
			setFlightMode(constants.FLIGHT_MODE_NAVIGATION);
		}
		setprop("/controls/gear/gear-down", 0);
	} else {
		setprop("/controls/gear/gear-down", 1);
		setprop("/controls/flight/flaps", 0);
	}
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

var autostart = func{
	if (getprop("sim/time/elapsed-sec") < 10) {
		return;
	}
	long_starting();
	return; # this is a dirty and lazy way of doing it

	if (!getprop("/controls/engines/engine[0]/cutoff")) {
		me.autostart_status = 0;
		# Cut Off
		setprop("/controls/switches/hide-cutoff", 1);
		setprop("/controls/engines/engine/cutoff", 1);
	}
	else {
		setprop("/controls/engines/engine[0]/cutoff",1);

		# Place here all the switch 'on' needed for the autostart
		# First electrics switchs
		setprop("/controls/switches/battery-switch", 1);
		setprop("/controls/switches/transformator-switch", 1);
		setprop("/controls/switches/ALT1-switch", 1);
		setprop("/controls/switches/ALT2-switch", 1);

		# Launching process
		# Cut Off
		setprop("/controls/switches/hide-cutoff", 0);
		setprop("/controls/engines/engine/cutoff", 0);
		# Fuel Pumps
		setprop("/controls/switches/pump-BPG", 1);
		setprop("/controls/switches/pump-BPD", 1);
		# This isn't a pump, but it's here is the starting process.
		# Vent is to clear fuel of the engine, allumage is to burn it.
		# So 1 is allumage 0 vent.
		setprop("/controls/switches/vent-allumage", 1);
		setprop("/controls/switches/pump-BP", 1);
		setprop("/controls/switches/hide-starter",1);
		setprop("/controls/engines/engine/starter",1);
		mystarter();
	}
}

var long_starting = func() {
	#Placing the view on take off view
	if (getprop("/sim/current-view/view-number-raw") == 0) {
		setprop("/sim/current-view/x-offset-m",0);
		setprop("/sim/current-view/y-offset-m",0.1019);
		setprop("/sim/current-view/z-offset-m",-2.9);
		setprop("/sim/current-view/field-of-view",83);

		#zooming on fuel, electrics and alerts
		setprop("/sim/current-view/pitch-offset-deg",-40);
		setprop("/sim/current-view/heading-offset-deg",338);
		setprop("/sim/current-view/field-of-view",36);
	}

	settimer(func {
		setprop("/controls/switches/battery-switch",1);
	}, 3);

	settimer(func {
		setprop("/controls/switches/transformator-switch",1);
	}, 4);

	settimer(func {
		setprop("/controls/switches/ALT1-switch",1);
		setprop("/controls/switches/ALT2-switch",1);
	}, 4);

	#Zooming on starting panel
	settimer(func {
		if (getprop("/sim/current-view/view-number-raw") == 0) {
			setprop("/sim/current-view/pitch-offset-deg",-62);
			setprop("/sim/current-view/heading-offset-deg",312);
			setprop("/sim/current-view/field-of-view",21.6);
		}
	}, 5);

	# Cut Off
	settimer(func {
		setprop("/controls/switches/hide-cutoff", 1);
	}, 5);
	settimer(func {
		setprop("/controls/engines/engine/cutoff", 0);
	}, 6);

	settimer(func {
		setprop("/controls/switches/hide-cutoff",  0);
	}, 7);

	# Fuel Pumps
	settimer(func {
		setprop("/controls/switches/pump-BPG", 1);
	}, 8);
	settimer(func {
		setprop("/controls/switches/pump-BPD", 1);
	}, 9);

	# This isn't a pump, but it's here is the starting process.
	# Vent is to clear fuel of the engine, allumage is to burn it.
	# So 1 is allumage 0 vent.
	settimer(func {
		setprop("/controls/switches/vent-allumage", 1);
	}, 10);
	settimer(func {
		setprop("/controls/switches/hide-starter",1);
		setprop("/controls/switches/pump-BP", 1);
	}, 11);

	#Starting the engine
	settimer(func {
		setprop("/controls/engines/engine/starter",1);
		mystarter();
	}, 13);

	#zooming on fuel, electrics and alerts
	settimer(func {
		if (getprop("/sim/current-view/view-number-raw") == 0) {
			setprop("/sim/current-view/pitch-offset-deg",-38);
			setprop("/sim/current-view/heading-offset-deg",338);
			setprop("/sim/current-view/field-of-view",36);
		}
	}, 15);

	# Close the canopy one notch
	settimer(func {
		doors.move_canopy();
	}, 42);

	#puting back the view on take off view
	settimer(func {
		setFlightMode(constants.FLIGHT_MODE_GROUND);
	}, 45);

	#turning on the air conditioning
	setprop("/controls/ventilation/airconditioning-enabled",1);
	setprop("/environment/aircraft-effects/cabin-heat-set",1);
	setprop("/environment/aircraft-effects/cabin-air-set",1);
	setprop("/controls/ventilation/windshield-hot-air-knob",1);
}


setprop("/sim/multiplay/visibility-range-nm", 200);


#  #This is the starup listener. It will put a value into n1 and n2 in order start jsbsim engine without playing with cutoff
#var starterlistener = setlistener("/controls/engines/engine/starter", func() {
# var starterlistener = setlistener("/fdm/jsbsim/propulsion/starter_cmd", func() {
var mystarter = func() {
	if (getprop("/fdm/jsbsim/propulsion/engine/n1")<0.5 and  getprop("/fdm/jsbsim/propulsion/engine/n2")<0.5
	   and getprop("/controls/switches/pump-BP") and getprop("/controls/switches/vent-allumage")) {
		setprop("/fdm/jsbsim/propulsion/engine/n1",1);
		setprop("/fdm/jsbsim/propulsion/engine/n2",25);
		setprop("engines/engine[0]/out-of-fuel",0);
	}
}

setprop("consumables/fuel/tank[8]/capacity-gal_us",0);
setprop("consumables/fuel/tank[9]/capacity-gal_us",0);
setprop("consumables/fuel/tank[10]/capacity-gal_us",0);
setprop("consumables/fuel/tank[11]/capacity-gal_us",0);
setprop("consumables/fuel/tank[12]/capacity-gal_us",0);
