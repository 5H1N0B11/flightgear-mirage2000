print("*** LOADING transpondeur.nas ... ***");
################################################################################
#
#                     m2005-5's TRANSPONDER SETTINGS
#
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
################################################################################

# set to the default we want at initialization
setprop("/instrumentation/transponder/inputs/knob-mode", 0);

var toggleIdentification = func() {
    if (getprop("/instrumentation/transponder/switch/IDENTIFICATION") == 1) {
        # On enleve le mode ALTITUDE
        setprop("/instrumentation/transponder/switch/ALTITUDE", 0);
        # set knob-mode to ON
        setprop("/instrumentation/transponder/inputs/knob-mode", 4);
    } else {
        if (getprop("/instrumentation/transponder/switch/ALTITUDE") == 0) {
            setprop("/instrumentation/transponder/inputs/knob-mode", 0);
        }
    }
}

var toggleAltitude = func() {
    if (getprop("/instrumentation/transponder/switch/ALTITUDE") == 1) {
        # On enleve le mode IDENTIFICATION
        setprop("/instrumentation/transponder/switch/IDENTIFICATION", 0);
        # set knob-mode to ALTITUDE
        setprop("/instrumentation/transponder/inputs/knob-mode", 5);
    } else {
        if (getprop("/instrumentation/transponder/switch/IDENTIFICATION") == 0) {
            setprop("/instrumentation/transponder/inputs/knob-mode", 0);
        }
    }
}

var toggleMoletteIFFMaster = func() { # Off = 0, SBY = 1, N = 2, EMER = 3
    # Mode OFF
    if (getprop("/instrumentation/transponder/switch/MoletteIFFMaster") == 0) {
        setprop("/instrumentation/transponder/inputs/knob-mode", 0);
    }
    # Mode SBY
    if (getprop("/instrumentation/transponder/switch/MoletteIFFMaster") == 1) {
        setprop("/instrumentation/transponder/inputs/knob-mode", 1);
    }
    # Mode N
    if (getprop("/instrumentation/transponder/switch/MoletteIFFMaster") == 2) {
        if (getprop("/instrumentation/transponder/switch/IDENTIFICATION") == 1) {
            setprop("/instrumentation/transponder/inputs/knob-mode", 4);
        } else if (getprop("/instrumentation/transponder/switch/ALTITUDE") == 1) {
            setprop("/instrumentation/transponder/inputs/knob-mode", 5);
        } else {
            setprop("/instrumentation/transponder/switch/IDENTIFICATION", 1);
            setprop("/instrumentation/transponder/inputs/knob-mode", 4);
        }
    }
    # Emergency - according to DCS Razbam docs page 255 sets MODES 1, 2, 3A
    if (getprop("/instrumentation/transponder/switch/MoletteIFFMaster") == 3) {
        setprop("/instrumentation/transponder/inputs/knob-mode", 4);
        setprop("/instrumentation/transponder/switch/ALTITUDE", 0);
        setprop("/instrumentation/transponder/switch/IDENTIFICATION", 1);
    }
}
