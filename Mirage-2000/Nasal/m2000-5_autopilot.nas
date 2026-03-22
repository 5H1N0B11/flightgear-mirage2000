print("*** LOADING m2000-5_autopilot.nas ... ***");
################################################################################
#
#                 m2005-5's FLIGHT DIRECTOR/AUTOPILOT SETTINGS
#
################################################################################

var input = {
	pitch_deg                  : "/orientation/pitch-deg",
	roll_deg                   : "/orientation/roll-deg",
	alpha                      : "/orientation/alpha-deg",
	heading_magnetic_deg       : "/orientation/heading-magnetic-deg",
	altitude                   : "/position/altitude-ft",
	airspeed                   : "/velocities/airspeed-kt",
	ap_status                  : "/autopilot/locks/AP-status",
	ap_lock_altitude           : "/autopilot/locks/altitude",
	ap_lock_altitude_arm       : "/autopilot/locks/altitude-arm",
	ap_lock_heading            : "/autopilot/locks/heading",
	ap_lock_heading_arm        : "/autopilot/locks/heading-arm",
	ap_target_pitch_deg        : "/autopilot/settings/target-pitch-deg",
	ap_target_roll_deg         : "/autopilot/settings/target-roll-deg",
	ap_target_altitude         : "/autopilot/settings/target-altitude-ft",
	ap_target_heading_deg      : "/autopilot/settings/heading-bug-deg",
	ap_selected_altitude       : "/autopilot/settings/selected-altitude-ft",
	nav_source                 : "autopilot/settings/nav-source",
	nav1_heading_bug_deg       : "instrumentation/nav[0]/radials/selected-deg", # OBS (Omni-Bearing Selector) of HSI / Needle / The path
	nav2_heading_bug_deg       : "instrumentation/nav[1]/radials/selected-deg",
	nav1_has_gs                : "instrumentation/nav[0]/has-gs",
	nav2_has_gs                : "instrumentation/nav[1]/has-gs",
	nav1_nav_loc               : "instrumentation/nav[0]/nav-loc",
	nav2_nav_loc               : "instrumentation/nav[1]/nav-loc",
	nav1_hdg_needle_deflection : "/instrumentation/nav[0]/heading-needle-deflection",
	nav2_hdg_needle_deflection : "/instrumentation/nav[1]/heading-needle-deflection",
	nav1_to_flag               : "/instrumentation/nav[0]/to-flag",
	nav2_to_flag               : "/instrumentation/nav[1]/to-flag",
	nav1_from_flag             : "/instrumentation/nav[0]/from-flag",
	nav2_from_flag             : "/instrumentation/nav[1]/from-flag",
	ap_internal_ap_crs         : "/autopilot/internal/ap_crs",
	ap_internal_cdi            : "/autopilot/internal/cdi",
	ap_internal_crs_offset     : "/autopilot/internal/course-offset",
	ap_internal_crs_sel        : "/autopilot/internal/selected-crs",
	ap_internal_gs_valid       : "/autopilot/internal/gs-valid",
	ap_internal_nav_type       : "/autopilot/internal/nav-type",
	ap_internal_radial_sel     : "/autopilot/internal/radial-selected-deg",
	ap_internal_hdg_deflect    : "/autopilot/internal/heading-needle-deflection",
	ap_internal_to_flag        : "/autopilot/internal/to-flag",
	ap_internal_from_flag      : "/autopilot/internal/from-flag",
	dme_frequencies_source     : "/instrumentation/dme/frequencies/source",
};

foreach(var name; keys(input)) {
	input[name] = props.globals.getNode(input[name], 1);
}

var ap_mode = consts.AP_MODE_OFF;

var initAutopilot = func() {
	return; # nothing_to_do
}

var updateAPMode = func(btn_pressed) {
	print("Autopilot got button pressed: "~btn_pressed);

	# first test standby
	var ap_in_standby = input.ap_status.getValue() == consts.AP_STATUS_STBY;
	if (ap_in_standby) {
		if (btn_pressed == consts.BTN_STBY) {
			input.ap_status.setValue(consts.AP_STATUS_ON);
			screen.log.write("Returned to autopilot from stand-by");
		} else {
			screen.log.write("Cannot change autopilot settings when in stand-by");
		}
		return;
	}

	if (btn_pressed == consts.BTN_STBY) {
		if (ap_mode == consts.AP_MODE_OFF) {
			return;
		} else {
			input.ap_status.setValue(consts.AP_STATUS_STBY);
			screen.log.write("Autopilot set into stand-by");
		}
	} else if (btn_pressed == consts.BTN_PA) { # PA: main autopilot -> attitude
		if (ap_mode != consts.AP_MODE_OFF) {
			_changeMode(consts.AP_MODE_OFF);
		} else if (_checkAPOperationalLimits(consts.AP_MODE_ATTITUDE) == false) {
			_changeMode(consts.AP_MODE_OFF);
		} else {
			_resetAttitudeMode();
		}
	} else if (btn_pressed == consts.BTN_ALT) {
		if (ap_mode == consts.AP_MODE_ALTITUDE_HOLD) {
			_resetAttitudeMode();
		} else if (ap_mode == consts.AP_MODE_OFF or _checkAPOperationalLimits(consts.AP_MODE_ALTITUDE_HOLD) == false) {
			return;
		} else {
			_changeMode(consts.AP_MODE_ALTITUDE_HOLD);
			input.ap_lock_altitude.setValue(consts.AP_LOCK_ALTITUDE_ALT);
			var current_altitude = input.altitude.getValue();
			input.ap_target_altitude.setValue(current_altitude);
		}
	} else if (btn_pressed == consts.BTN_ALT_AFF) {
		if (ap_mode == consts.AP_MODE_ALTITUDE_SELECTED) {
			_resetAttitudeMode();
		} else if (ap_mode == consts.AP_MODE_OFF or _checkAPOperationalLimits(consts.AP_MODE_ALTITUDE_SELECTED) == false) {
			return;
		} else {
			_changeMode(consts.AP_MODE_ALTITUDE_SELECTED);
			input.ap_lock_altitude.setValue(consts.AP_LOCK_ALTITUDE_ALT);
			input.ap_target_altitude.setValue(input.ap_selected_altitude.getValue());
		}
	} else if (btn_pressed == consts.BTN_LG) {
		if (ap_mode == consts.AP_MODE_APPROACH) {
			_resetAttitudeMode();
		} else if (ap_mode == consts.AP_MODE_OFF or _checkAPOperationalLimits(consts.AP_MODE_APPROACH) == false) {
			return;
		} else {
			_changeMode(consts.AP_MODE_APPROACH);
			# NB: some stuff gets periodically set in updateAutopilot()
			input.ap_lock_heading.setValue(consts.AP_LOCK_HEADING_HDG);
			input.ap_lock_heading_arm.setValue(consts.AP_LOCK_HEADING_ARM_LOC);
			input.ap_lock_altitude.setValue(consts.AP_LOCK_ALTITUDE_GS);
			input.ap_lock_altitude_arm.setValue(consts.AP_LOCK_ALTITUDE_ARM_GS);
		}
	}
}

var _changeMode = func(new_ap_mode) {
	if (ap_mode != new_ap_mode) {
		screen.log.write("Changing autopilot mode from "~ap_mode~" to "~new_ap_mode);
	}
	ap_mode = new_ap_mode;
	if (new_ap_mode == consts.AP_MODE_ATTITUDE) {
		input.ap_status.setValue(consts.AP_STATUS_ON);
	} else if (new_ap_mode == consts.AP_MODE_OFF) {
		input.ap_status.setValue(consts.AP_STATUS_OFF);
	}
}

# Used when enabling attitude mode by enabling the autopilot or
# when returning from an advanced mode (alt, alt selected, approach)
var _resetAttitudeMode = func {
	_changeMode(consts.AP_MODE_ATTITUDE);

	# attitude pitch
	input.ap_lock_altitude.setValue(consts.AP_LOCK_ALTITUDE_PITCH);
	input.ap_target_pitch_deg.setValue(input.pitch_deg.getValue());

	# attitude roll
	var current_roll = input.roll_deg.getValue();
	if (current_roll < -10 or current_roll > 10) { # submode ROLL_HOLD
		if (current_roll < -60) {
			current_roll = -60; # between 60 and 65 degs the roll is automatically reduced
		} else if (current_roll > 60) {
			current_roll = 60;
		}
		input.ap_target_roll_deg.setValue(current_roll);
		input.ap_lock_heading.setValue(consts.AP_LOCK_HEADING_ROLL);
	} else {
		current_heading = input.heading_magnetic_deg.getValue();
		input.ap_target_heading_deg.setValue(current_heading);
		input.ap_lock_heading.setValue(consts.AP_LOCK_HEADING_HDG);
		_courseOffset(current_heading);
	}
}

# set autopilot internals based on current deviation from selected course
var _courseOffset = func(asked_course) {
	input.ap_internal_crs_sel.setValue(asked_course);

	var crs_offset = geo.normdeg180(asked_course - input.heading_magnetic_deg.getValue());
	input.ap_internal_crs_offset.setValue(crs_offset);

	crs_offset += input.ap_internal_cdi.getValue();
	input.ap_internal_ap_crs.setValue(geo.normdeg180(crs_offset));
}

# return true if everything within operational limits - false otherwise
var _checkAPOperationalLimits = func(check_mode) {
	if (check_mode == consts.AP_MODE_APPROACH) {
		var nav_source = input.nav_source.getValue();
		if (nav_source != consts.NAV_SOURCE_NAV1 and nav_source != consts.NAV_SOURCE_NAV2) {
			screen.log.write("Need to use NAV1 or NAV2 for ILS navigation, but source is: "~nav_source);
			return false;
		}
		var has_loc_gs = false;
		if (nav_source == consts.NAV_SOURCE_NAV1) {
			if (input.nav1_has_gs.getValue() and input.nav1_nav_loc.getValue()) {
				has_loc_gs = true;
			}
		} else { # we use NAV2
			if (input.nav2_has_gs.getValue() and input.nav2_nav_loc.getValue()) {
				has_loc_gs = true;
			}
		}
		if (has_loc_gs == false) {
			screen.log.write("No LOC or GS found for autopilot with nav source: "~nav_source);
			return false;
		}
	}

	var current_pitch = input.pitch_deg.getValue();
	if (current_pitch < -40 or current_pitch > 40) {
		screen.log.write("Pitch is outside of operational limits for autopilot");
		return false;
	}
	var current_roll = input.roll_deg.getValue();
	if (current_roll < -65 or current_roll > 65) {
		screen.log.write("Roll is outside of operational limits for autopilot");
		return false;
	}
	var current_aoa = input.alpha.getValue();
	if (current_aoa > 18) {
		screen.log.write("AoA is outside of operational limits for autopilot");
		return false;
	}
	if (check_mode != consts.AP_MODE_APPROACH) {
		var current_ias = input.airspeed.getValue();
		if (current_ias < 200) {
			screen.log.write("Minimum speed is outside of operational limits for autopilot");
			return false;
		}
	}
	var current_altitude = input.altitude.getValue();
	if (current_altitude > 50000) {
		screen.log.write("Altitude is over operational limits for autopilot");
		return false;
	} else if (current_altitude < 1000 and check_mode == AP_MODE_ALTITUDE_SELECTED) {
		screen.log.write("Altitude is under operational limits for autopilot");
		return false;
	} else if (current_altitude < 200 and check_mode == AP_MODE_APPROACH) {
		screen.log.write("Altitude is under operational limits for autopilot");
		return false;
	} else if (current_altitude < 500) {
		screen.log.write("Altitude is under operational limits for autopilot");
		return false;
	}
	return true;
}

# periodically updates the autopilot with stuff - triggered from main loop in m2000-5.nas
var updateAutopilot = func () {
	if (input.ap_status.getValue() != consts.AP_STATUS_ON) {
		return; # nothing to check - not if OFF or STBY
	}

	# check operational limits
	check_result = _checkAPOperationalLimits(ap_mode);
	if (check_result == false) {
		_changeMode(consts.AP_MODE_OFF);
		return;
	}

	# updates for attitude mode plus HDG submode
	if (ap_mode == consts.AP_MODE_ATTITUDE and input.ap_lock_heading.getValue == consts.AP_LOCK_HEADING_HDG) {
		_courseOffset(input.ap_target_heading_deg.getValue());
	} elsif (ap_mode == consts.AP_MODE_ALTITUDE_SELECTED) { # altitude selected mode
		input.ap_target_altitude.setValue(input.ap_selected_altitude.getValue()); # the pilot could have changed the selected altitude
	} elsif (ap_mode == consts.AP_MODE_APPROACH) {
		# update a lot of internal stuff and do _courseOffset() for NAV1 or NAV2
		input.ap_internal_gs_valid.setValue(1);
		var nav_source = input.nav_source.getValue();
		if (nav_source == consts.NAV_SOURCE_NAV1) {
			input.ap_internal_nav_type.setValue("ILS1");
			_courseOffset(input.nav1_heading_bug_deg.getValue());
			input.ap_internal_radial_sel.setValue(input.nav1_heading_bug_deg.getValue());
			input.ap_internal_hdg_deflect.setValue(input.nav1_hdg_needle_deflection.getValue());
			input.ap_internal_to_flag.setValue(input.nav1_to_flag.getValue());
			input.ap_internal_from_flag.setValue(input.nav1_from_flag.getValue());
			#input.dme_frequencies_source.setValue("/instrumentation/nav[0]/frequencies/selected-mhz"); # property path, not the value!
		} elsif (nav_source == consts.NAV_SOURCE_NAV2) {
			input.ap_internal_nav_type.setValue("ILS2");
			_courseOffset(input.nav2_heading_bug_deg.getValue());
			input.ap_internal_radial_sel.setValue(input.nav2_heading_bug_deg.getValue());
			input.ap_internal_hdg_deflect.setValue(input.nav2_hdg_needle_deflection.getValue());
			input.ap_internal_to_flag.setValue(input.nav2_to_flag.getValue());
			input.ap_internal_from_flag.setValue(input.nav2_from_flag.getValue());
			#input.dme_frequencies_source.setValue("/instrumentation/nav[1]/frequencies/selected-mhz");
		}
	}
}
