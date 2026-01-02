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
			cursor_dx:        "controls/displays/cursor-slew-x-delta",
			cursor_dy:        "controls/displays/cursor-slew-y-delta",
			cursor_clicked:   "controls/displays/cursor-click",
			hdg_magnetic:     "/orientation/heading-magnetic-deg",
			hdg_true:          "/orientation/heading-deg",
			show_true_north:  "/instrumentation/efis/mfd/true-north",
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
		var show_true_north = me.input.show_true_north.getValue();
		var heading_true = me.input.hdg_true.getValue();
		var heading_mag = me.input.hdg_magnetic.getValue();
		var heading_displayed = heading_mag;
		if (show_true_north) {
			heading_displayed = heading_true;
		}
		return [heading_displayed, show_true_north, heading_true - heading_mag];
	},

};

var common = Common.new();
