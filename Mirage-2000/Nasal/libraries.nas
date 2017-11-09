# Mirage 2000 System Libraries

var doMagicStartup = func {
	setprop("/controls/engines/engine[0]/starter", "true");
	settimer(func {
		setprop("/controls/engines/engine[0]/cutoff", "false");
	}, 10);
}