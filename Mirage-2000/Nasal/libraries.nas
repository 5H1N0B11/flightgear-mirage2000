# Mirage 2000 System Libraries

setlistener("/sim/signals/fdm-initialized", func {
	systemsInit();
#	systemsLoop.start(); # Uncomment this when you add something to the loop
});

# Call any initialize functions for systems you need
var systemsInit = func {
}

# Basic systems timer, can run any system loop you need
var systemsLoop = maketimer(0.1, func {
});

# It's magic, I don't know how it works!
var doMagicStartup = func {
	setprop("/instrumentation/mfd/modeL", 0);
	setprop("/instrumentation/mfd/modeR", 3);
	setprop("/controls/engines/engine[0]/cutoff", 0);
	setprop("/engines/engine[0]/out-of-fuel", 0);
	setprop("/engines/engine[0]/run", 1);

	setprop("/engines/engine[0]/cutoff", 0);
	setprop("/engines/engine[0]/starter", 0);

	setprop("/fdm/jsbsim/propulsion/set-running", 0);
}