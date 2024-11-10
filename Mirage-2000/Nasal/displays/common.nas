# Common methods used in all dispalys - inspired by the JA37 displays/common.nas

# the displays
var VTM = 0;
var VTB = 1;


var Common = {

	new: func {
		var co = { parents: [Common] };
		co.input = {
			cursor_dx:        "controls/displays/cursor-slew-x-delta",
			cursor_dy:        "controls/displays/cursor-slew-y-delta",
			cursor_clicked:   "controls/displays/cursor-click",
			hdgDisplay:       "/instrumentation/efis/mfd/true-north",
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
};

var common = Common.new();
