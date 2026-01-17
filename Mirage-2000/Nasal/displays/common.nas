# Common methods used in all dispalys - inspired by the JA37 displays/common.nas

# the displays
var VTM = 0;
var VTB = 1;

var TRUE = 1;
var FALSE = 0;

var Common = {

	new: func {
		var co = { parents: [Common] };
		co.input = {
			cursor_dx        : "controls/displays/cursor-slew-x-delta",
			cursor_dy        : "controls/displays/cursor-slew-y-delta",
			cursor_clicked   : "controls/displays/cursor-click",
			hdg_magnetic     : "/orientation/heading-magnetic-deg",
			hdg_true         : "/orientation/heading-deg",
			show_true_north  : "/instrumentation/efis/mfd/true-north",
			ias              : "/velocities/airspeed-kt",
			mach             : "/velocities/mach",
			alt_instru       : "/instrumentation/altimeter/indicated-altitude-ft",
			rad_alt          : "position/altitude-agl-ft", #"/instrumentation/radar-altimeter/radar-altitude-ft",
			pitch            : "/orientation/pitch-deg",
			roll             : "/orientation/roll-deg",
		};

		foreach(var name; keys(co.input)) {
			co.input[name] = props.globals.getNode(co.input[name], 1);
		}

		co.cursor = VTM;
		return co;
	},

	# Cursor position low level updates are in JSBSim to not suffer from low refresh rate.
	# These functions are the interface with this JSBSim system.
	getCursorDelta: func {
		return [me.input.cursor_dx.getValue(), me.input.cursor_dy.getValue(), me.input.cursor_clicked.getValue()];
	},

	resetCursorDelta: func {
		me.input.cursor_dx.setValue(0);
		me.input.cursor_dy.setValue(0);
		me.input.cursor_clicked.setValue(0);
	},

	getHeadingForDisplay: func {
		me.show_true_north = me.input.show_true_north.getValue();
		me.heading_true = me.input.hdg_true.getValue();
		me.heading_mag = me.input.hdg_magnetic.getValue();
		me.heading_displayed = me.heading_mag;
		if (me.show_true_north) {
			me.heading_displayed = me.heading_true;
		}
		return [me.heading_displayed, me.show_true_north, me.heading_true - me.heading_mag, me.heading_true];
	},

	getSpeedForDisplay: func {
		me.mach = me.input.mach.getValue();
		me.mach_str = me.mach >= 0.6 ? sprintf("%0.2f", me.mach) : nil;
		return [sprintf("%d",int(me.input.ias.getValue())), me.mach_str];
	},

	getAltForDisplay: func {
		me.alt_instrument = me.input.alt_instru.getValue();
		me.alt_digits_str = sprintf("%02d", abs(int(math.mod(me.alt_instrument, 100))));
		me.alt_hundreds_str = me.alt_instrument > 0 ? sprintf("%d", int((me.alt_instrument/100))) : sprintf("-%d",abs(int((me.alt_instrument/100))));

		me.rad_alt = me.input.rad_alt.getValue();
		if (me.rad_alt < 5000) { # Or be selected be a special swith not yet done # Only show below 5000AGL
			if (abs(me.input.pitch.getValue()) < 20 and abs(me.input.roll.getValue()) < 20) { # if the angle is above 20° the radar do not work
				me.rad_alt_str = sprintf("%4d", me.rad_alt - 8); #The radar should show 0 when on Ground
			} else {
				me.rad_alt_str = "*****";
			}
		} else {
			me.rad_alt_str = nil;
		}
		return [me.alt_hundreds_str, me.alt_digits_str, me.rad_alt_str];
	},

};

var common = Common.new();
