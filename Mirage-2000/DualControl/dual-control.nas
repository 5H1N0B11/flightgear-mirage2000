print("*** LOADING dual-control.nas ... ***");

# Renaming (almost :)
var DCT = dual_control_tools;

# Pilot/copilot aircraft identifiers. Used by dual_control.
var pilot_type   = "Aircraft/Mirage-2000/Models/m2000-5B.xml";
var copilot_type = "Aircraft/Mirage-2000/Models/m2000-5B-backseat.xml";

props.globals.initNode("/sim/remote/pilot-callsign", "", "STRING");

# Used by dual_control to set up the mappings for the pilot.
var pilot_connect_copilot = func(copilot) {
    print("######## pilot_connect_copilot() ########");
}

var pilot_disconnect_copilot = func() {
    print("######## pilot_disconnect_copilot() ########");
}

# Used by dual_control to set up the mappings for the copilot.
var copilot_connect_pilot = func(pilot) {
    print("######## copilot_connect_pilot() ########");
    set_copilot_wrappers(pilot);
    return [];
}

var copilot_disconnect_pilot = func() {
    print("######## copilot_disconnect_pilot() ########");
}

# Copilot Nasal wrappers
var set_copilot_wrappers = func(pilot) {
}

