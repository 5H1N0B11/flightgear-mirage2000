# Mirage 2000 specific part
var iff_knob = func {
	mode = getprop("/controls/iff/channel-select");
	if (mode == 0) {
		setprop("/instrumentation/iff/channel", getprop("/instrumentation/iff/channel_A"));
	} elsif (mode == 1) {
		setprop("/instrumentation/iff/channel", getprop("/instrumentation/iff/channel_B"));
	} elsif (mode == -1) {
		setprop("/instrumentation/iff/channel_A_hold", getprop("/instrumentation/iff/channel_A"));
		setprop("/instrumentation/iff/channel_B_hold", getprop("/instrumentation/iff/channel_B"));
	} elsif (mode == 2 and getprop("/controls/iff/iff-power") == 1) {
		setprop("instrumentation/iff/channel_A", 0);
		setprop("instrumentation/iff/channel_B", 0);
		setprop("instrumentation/iff/channel", 0);
	}
}

var hold_reset = func {
	setprop("/instrumentation/iff/channel_A_hold", 0);
	setprop("/instrumentation/iff/channel_B_hold", 0);
	iff_knob();
}


var iff_init = setlistener("/sim/fdm-initialized", func {
	setprop("/instrumentation/iff/channel_A", getprop("/instrumentation/iff/channel_A_hold"));
	setprop("/instrumentation/iff/channel_B", getprop("/instrumentation/iff/channel_B_hold"));

	setlistener("/controls/iff/channel-select", iff_knob, 1, 0);
	setlistener("/instrumentation/iff/channel_A", hold_reset, 1, 0);
	setlistener("/instrumentation/iff/channel_B", hold_reset, 1, 0);
	removelistener(iff_init);
});
