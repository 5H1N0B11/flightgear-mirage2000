print("*** LOADING transpondeur.nas ... ***");
################################################################################
#
#                     m2005-5's TRANSPONDER SETTINGS
#
#
#
# The code for the built-in transponder (F12) can be found:
# https://gitlab.com/flightgear/flightgear/-/blob/next/src/Instrumentation/transponder.hxx
# https://gitlab.com/flightgear/flightgear/-/blob/next/src/Instrumentation/transponder.cxx
# fgdata/gui/dialogs/radios.xml
#
# Other docs:
# https://wiki.flightgear.org/Transponder
# https://forum.flightgear.org/viewtopic.php?f=4&t=43585
#
# /instrumentation/transponder/inputs/knob-mode is also set by the FG
# built-in transponder -> menu equipment-radio settings (F12) -> "Mode"
# Therefore the code below adjusts the built-in according to the settings
# on the panel.
# The values of knob-mode correspond to the UI as follows:
# OFF = 0
# STANDBY = 1
# TEST = 2
# GROUND = 3
# ON = 4
# ALTITUDE = 5
#
#
#


################################################################################

# set to the default we want at initialization
setprop("/instrumentation/transponder/inputs/knob-mode", 0);

var TRUE = 1;
var FALSE = 0;

var TRANSPONDER_MASTER_OFF = 0;
var TRANSPONDER_MASTER_SBY = 1;
var TRANSPONDER_MASTER_ON = 2; # "N"
var TRANSPONDER_MASTER_EMER = 3;

KNOB_MODE_OFF = 0;
KNOB_MODE_STANDBY = 1;
KNOB_MODE_TEST = 2;
KNOB_MODE_GROUND = 3;
KNOB_MODE_ON = 4;
KNOB_MODE_ALTITUDE = 5;

var IFF_CHANNEL_SELECT_A = 1;
var IFF_CHANNEL_SELECT_B = 2;
var IFF_CHANNEL_SELECT_ZERO = 3;

var node = {
	transponder_master:           props.globals.getNode("/instrumentation/transponder/switch/master"),
	transponder_identification:   props.globals.getNode("/instrumentation/transponder/switch/identification"),
	transponder_altitude:         props.globals.getNode("/instrumentation/transponder/switch/altitude"),
	transponder_knob_mode:        props.globals.getNode("/instrumentation/transponder/inputs/knob-mode"),
	iff_channel:                  props.globals.getNode("/instrumentation/iff/channel"),
	iff_channel_a:                props.globals.getNode("/instrumentation/iff/channel_A"),
	iff_channel_b:                props.globals.getNode("/instrumentation/iff/channel_B"),
	iff_reply:                    props.globals.getNode("/instrumentation/iff/reply"),
	iff_power:                    props.globals.getNode("/instrumentation/iff/power"),
	iff_channel_select:           props.globals.getNode("/instrumentation/iff/channel_select"),
};


var toggleIdentification = func() {
	if (node.transponder_identification.getValue() == TRUE) {
		# On enleve le mode ALTITUDE
		node.transponder_altitude.setValue(FALSE);
	}
	toggleMoletteMaster();
};

var toggleAltitude = func() {
	if (node.transponder_altitude.getValue() == TRUE) {
		# On enleve le mode IDENTIFICATION
		node.transponder_identification.setValue(FALSE);
	}
	toggleMoletteMaster();
};

var toggleMoletteMaster = func() { # Off = 0, SBY = 1, N = 2, EMER = 3
	# Mode OFF
	if (node.transponder_master.getValue() == TRANSPONDER_MASTER_OFF) {
		node.transponder_knob_mode.setValue(KNOB_MODE_OFF);
	}
	# Mode SBY
	if (node.transponder_master.getValue() == TRANSPONDER_MASTER_SBY) {
		node.transponder_knob_mode.setValue(KNOB_MODE_STANDBY);
	}
	# Mode N
	if (node.transponder_master.getValue() == TRANSPONDER_MASTER_ON) {
		if (node.transponder_identification.getValue() == TRUE) {
			node.transponder_knob_mode.setValue(KNOB_MODE_ON);
		} else if (node.transponder_altitude.getValue() == TRUE) {
			node.transponder_knob_mode.setValue(KNOB_MODE_ALTITUDE);
		} else {
			node.transponder_identification.setValue(TRUE);
			node.transponder_knob_mode.setValue(KNOB_MODE_ON);
		}
	}
	# Emergency - according to DCS Razbam docs page 255 sets MODES 1, 2, 3A
	if (node.transponder_master.getValue() == TRANSPONDER_MASTER_EMER) {
		node.transponder_knob_mode.setValue(KNOB_MODE_ON);
		node.transponder_altitude.setValue(FALSE);
		node.transponder_identification.setValue(TRUE);
	}
	runLogicMode4(); # it is influenced by whether it is mode N or not
};

# See the description in the manual for the implemented logic
# Works together with iff.nas
var runLogicMode4 = func() {
	if (node.iff_channel_select.getValue() == IFF_CHANNEL_SELECT_A) {
		node.iff_channel.setValue(node.iff_channel_a.getValue());
	} elsif (node.iff_channel_select.getValue() == IFF_CHANNEL_SELECT_B) {
		node.iff_channel.setValue(node.iff_channel_b.getValue());
	} else {
		node.iff_channel.setValue(0);
		if (node.iff_channel_select.getValue() == IFF_CHANNEL_SELECT_ZERO) {
			node.iff_channel_a.setValue(0);
			node.iff_channel_b.setValue(0);
		}
	}

	# finally - check whether overall power can be on - i.e. responding to
	if (node.transponder_master.getValue() == TRANSPONDER_MASTER_ON and node.iff_reply.getValue() == TRUE and (
		node.iff_channel_select.getValue() == IFF_CHANNEL_SELECT_A or node.iff_channel_select.getValue() == IFF_CHANNEL_SELECT_B)) {
		node.iff_power.setValue(TRUE);
	} else {
		node.iff_power.setValue(FALSE);
	}
};
