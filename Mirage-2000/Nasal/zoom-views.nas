print("*** LOADING zoom-views.nas ... ***");
################################################################################
#
#                     m2005-5's VIEW and ZOOMING
#
################################################################################

# IDG Distance Zooming
# Copyright (c) 2018 Joshua Davidson (it0uchpods)
# Function add by 5H1N0B1
# Based on PropertyRule file by onox

var distance = 0;
var min_dist = 0;
var max_dist = 0;
var canChangeZOffset = 0;
var decStep = -5;
var incStep = 5;
var viewName = "XX";

var fovZoom = func(d) {
	viewName = getprop("/sim/current-view/name");
	canChangeZOffset = getprop("/sim/current-view/type") == "lookat" and viewName != "Tower View" and viewName != "Fly-By View" and viewName != "Chase View" and viewName != "Chase View Without Yaw" and viewName != "Walk View";
	
	if (getprop("/sim/current-view/z-offset-m") <= -50) {
		decStep = -10;
	} else {
		decStep = -5;
	}
	
	if (getprop("/sim/current-view/z-offset-m") < -50) { # Not a typo, the conditions are different
		incStep = 10;
	} else {
		incStep = 5;
	}
	
	if (d == -1) {
		if (canChangeZOffset) {
			distance = getprop("/sim/current-view/z-offset-m");
			min_dist = getprop("/sim/current-view/z-offset-min-m");
			
			distance = math.round(std.min(-min_dist, distance + incStep) / incStep, 0.1) * incStep;
			setprop("/sim/current-view/z-offset-m", distance);
			
			gui.popupTip(sprintf("%d meters", abs(distance)));
		} else {
			view.decrease();
		}
	} else if (d == 1) {
		if (canChangeZOffset) {
			distance = getprop("/sim/current-view/z-offset-m");
			max_dist = getprop("/sim/current-view/z-offset-max-m");
			
			distance = math.round(std.max(-max_dist, distance + decStep) / decStep, 0.1) * decStep;
			setprop("/sim/current-view/z-offset-m", distance);
			
			gui.popupTip(sprintf("%d meters", abs(distance)));
		} else {
			view.increase();
		}
	} else if (d == 0) {
		if (canChangeZOffset) {
			setprop("/sim/current-view/z-offset-m", getprop("/sim/current-view/z-offset-default") * -1);
			gui.popupTip(sprintf("%d meters", getprop("/sim/current-view/z-offset-default")));
		} else {
			setprop("/sim/current-view/field-of-view", getprop("/sim/view/config/default-field-of-view-deg"));
			gui.popupTip(sprintf("FOV: %.1f", getprop("/sim/current-view/field-of-view")))
		}
	}
}



var SnipingEnabling= setlistener("/payload/armament/station/id-6-set",func {
                    setprop("/sim/view[102]/enabled",(getprop("/payload/armament/station/id-6-set")=="PDLCT"));
                  }, 1, 0);
var viewEnabling= setlistener("/sim/current-view/name",func {
                    setprop("/aircraft/flir/target/view-enabled",(getprop("/sim/current-view/name")=="Sniping cam"));
                  }, 1, 0);
var ALS_IR_Enabling= setlistener("/aircraft/flir/target/view-enabled",func {
                    setprop("/sim/rendering/als-filters/use-filtering",getprop("/aircraft/flir/target/view-enabled"));
                    setprop("/sim/rendering/als-filters/use-IR-vision",getprop("/aircraft/flir/target/view-enabled"));
                  }, 1, 0);
var ALS_IR_Disabling = setlistener("/sim/rendering/als-filters/use-IR-vision",func {
                    if (!getprop("/aircraft/flir/target/view-enabled")) {
                      setprop("/sim/rendering/als-filters/use-IR-vision",0);
                    }
                  }, 1, 0);
