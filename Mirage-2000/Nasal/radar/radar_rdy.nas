print("*** LOADING radar_rdy.nas ... ***");



# =============================================================================================
# =============================================================================================
# =============================================================================================
#
# ************** New radar based on F-16 / F-14 design by Leto
#
# =============================================================================================
# =============================================================================================
# =============================================================================================


#  ██████   █████  ██████   █████  ██████      ██████  ██████  ██   ██
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██     ██   ██ ██   ██  ██ ██
#  ██████  ███████ ██   ██ ███████ ██████      ██████  ██   ██   ███
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██     ██   ██ ██   ██    █
#  ██   ██ ██   ██ ██████  ██   ██ ██   ██     ██   ██ ██████     █

var RDY = {
	# This class controls the overall modes plus whether it is on at all.
	# There is currently only one root modes is  0: GM (Ground Map)
	#
	instantFoVradius: 3.90*0.5,#average of horiz/vert radius - TODO find m2000 specific values (copy from F16)
	instantVertFoVradius: 4.55*0.5,# real vert radius (used by ground mapper) - TODO find m2000 specific values (copy from F16)
	instantHoriFoVradius: 3.25*0.5,# real hori radius (not used) - TODO find m2000 specific values (copy from F16)
	rcsRefDistance: 70, # TODO find m2000 specific values (copy from F16)
	rcsRefValue: 3.2, # TODO find m2000 specific values (copy from F16)
	targetHistory: 3,# Not used in TWS - TODO find m2000 specific values (copy from F16)
	isEnabled: func {
		var radarWorking = getprop("/systems/electrical/outputs/radar");
		return radarWorking != nil and radarWorking > 24;
	},
	setAGMode: func {
		if (me.rootMode != 0) {
			me.rootMode = 0;
			me.oldMode = me.currentMode;

			me.newMode = me.mainModes[me.rootMode][me.currentModeIndex[me.rootMode]];
			me.setCurrentMode(me.newMode, me.oldMode["priorityTarget"]);
		}
	},
	showAZ: func {
		me.currentMode.showAZ();
	},
	showAZinHSD: func {
		me.currentMode.showAZinHSD();
	},
};


# ███    ███  █████  ██ ███    ██     ███    ███  ██████  ██████  ███████
# ████  ████ ██   ██ ██ ████   ██     ████  ████ ██    ██ ██   ██ ██
# ██ ████ ██ ███████ ██ ██ ██  ██     ██ ████ ██ ██    ██ ██   ██ █████
# ██  ██  ██ ██   ██ ██ ██  ██ ██     ██  ██  ██ ██    ██ ██   ██ ██
# ██      ██ ██   ██ ██ ██   ████     ██      ██  ██████  ██████  ███████

# Direct copy from F-16 as per 2024-10-06 - TODO find m2000 specific values (copy from F16)

# All other radar modes will inherit from this one

var MainMode = {
	minRange: 10, # MLU T1 .. should we make this 10 for block 10/30/YF? TODO
	maxRange: 160,
	bars: 4,
	barPattern:  [ [[-1,0],[1,0]],                    # These are multitudes of [me.az, instantFoVradius]
	               [[-1,-1],[1,-1],[1,1],[-1,1]],
	               [[-1,0],[1,0],[1,2],[-1,2],[-1,0],[1,0],[1,-2],[-1,-2]],
	               [[1,-3],[1,3],[-1,3],[-1,1],[1,1],[1,-1],[-1,-1],[-1,-3]] ],
	barPatternMin: [0,-1, -2, -3],
	barPatternMax: [0, 1,  2,  3],
	rootName: "CRM",
	shortName: "",
	longName: "",
	EXPsupport: 0,#if support zoom
	EXPsearch: 1,# if zoom should include search targets
	EXPfixedAim: 0,# If map underneath should move instead of cursor when slewing
	showAZ: func {
		return me.az != me.radar.fieldOfRegardMaxAz; # If this return false, then they are also not shown in PPI.
	},
	showAZinHSD: func {
		return 1;
	},
	showBars: func {
		return 1;
	},
	showRangeOptions: func {
		return 1;
	},
	setCursorDistance: func (nm) {
		# Return if the cursor should be distance zeroed.
		me.cursorNm = nm;
		if (nm < me.radar.getRange()*0.05) {
			return me.decreaseRange();
		} elsif (nm > me.radar.getRange()*0.95) {
			return me.increaseRange();
		}
		return 0;
	},
	frameCompleted: func {
		if (me.lastFrameStart != -1) {
			me.lastFrameDuration = me.radar.elapsed - me.lastFrameStart;
			me.timeToFadeBleps = me.radar.targetHistory*me.lastFrameDuration;
		}
		me.lastFrameStart = me.radar.elapsed;
	},
};



#   ██████  ███    ███
#  ██       ████  ████
#  ██   ███ ██ ████ ██
#  ██    ██ ██  ██  ██
#   ██████  ██      ██

# Direct copy from F-16 as per 2024-10-06 - TODO find m2000 specific values (copy from F16)

var RDYGMMode = {
	rootName: "GM",
	longName: "Ground Map",
	discSpeed_dps: 55,
	detectAIR: 0,
	detectSURFACE: 1,
	detectMARINE: 0,
	mapper: 1,
	new: func (subMode, radar = nil) {
		var mode = {parents: [RDYGMMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		subMode.shortName = mode.shortName;
		subMode.rootName = mode.rootName;
		return mode;
	},
	frameCompleted: func {
		#print("frame ",me.radar.elapsed-me.lastFrameStart);
		if (me.lastFrameStart != -1) {
			me.lastFrameDuration = me.radar.elapsed - me.lastFrameStart;
			me.timeToFadeBleps = me.radar.targetHistory*me.lastFrameDuration;
		}
		me.lastFrameStart = me.radar.elapsed;
		if (me.radar["gmapper"] != nil) {
			me.radar.gmapper.frameDone();
		}
	},
	setExp: func (exp) {
		me.exp = exp;
		if (me.radar["gmapper"] != nil) me.radar.gmapper.expChanged(exp);
	},
	isEXP: func {
		return me.exp;
	},
	showAZ: func {
		return !me.isEXP();
	},
	setExpPosition: func (azimuth, distance_nm) {
		me.expAz = azimuth;
		me.expDistNm = distance_nm;
	},
	getEXPBoundary: func {
		if (me.exp and 0) {
			me.expWidthNm = me.getEXPsize();
			me.expCart = [me.expDistNm*math.sin(me.expAz*D2R), me.expDistNm*math.cos(me.expAz*D2R)];
			me.expCornerCartBegin = [me.expCart[0]-me.expWidthNm*0.5, me.expCart[1]-me.expWidthNm*0.5];
			me.expCornerCartEnd   = [me.expCart[0]+me.expWidthNm*0.5, me.expCart[1]-me.expWidthNm*0.5];
			me.expCornerDist1 = math.sqrt(me.expCornerCartBegin[0]*me.expCornerCartBegin[0]+me.expCornerCartBegin[1]*me.expCornerCartBegin[1]);
			me.expCornerDist2 = math.sqrt(me.expCornerCartEnd[0]*me.expCornerCartEnd[0]+me.expCornerCartEnd[1]*me.expCornerCartEnd[1]);
			me.azStart = math.asin(math.clamp(me.expCornerCartBegin[0]/me.expCornerDist1,0,1))*R2D;
			me.azEnd = math.asin(math.clamp(me.expCornerCartEnd[0]/me.expCornerDist2,0,1))*R2D;
			if (me.expCornerDist1 > me.expCornerDist2) {
				me.expCornerCartBegin[1] += me.expWidthNm;
				me.cornerRangeNm = math.sqrt(me.expCornerCartBegin[0]*me.expCornerCartBegin[0]+me.expCornerCartBegin[1]*me.expCornerCartBegin[1]);
				me.expMinRange = me.expCornerCartEnd[1];
			} else {
				me.expCornerCartEnd[1] += me.expWidthNm;
				me.cornerRangeNm = math.sqrt(me.expCornerCartEnd[0]*me.expCornerCartEnd[0]+me.expCornerCartEnd[1]*me.expCornerCartEnd[1]);
				me.expMinRange = me.expCornerCartBegin[1];
			}
			# deg start/end and min and max range in nm:
			return [me.azStart, me.azEnd, me.expMinRange, me.cornerRangeNm];
		} else {
			return nil;
		}
	},
	preStep: func {
	},
};

# Direct copy from F-16 as per 2024-10-06 - TODO find m2000 specific values (copy from F16)

var RDYGMFTTMode = {
	longName: "Ground Map Mode - Fixed Target Track",
	detectSURFACE: 1,
	detectMARINE: 0,
	mapper: 1,
	new: func (radar = nil) {
		var mode = {parents: [RDYGMFTTMode, MainMode, RadarMode]};
		mode.radar = radar;
		return mode;
	},
	getPriority: func {
		if (me.priorityTarget == nil or (rand() > 0.95 and me.priorityTarget.getSpeed() < 11)) {
			return me.priorityTarget;
		} else {
			return me.priorityTarget.getNearbyVirtualContact(60);
		}
	},
};




# ██ ███    ██ ██ ████████ ██  █████  ██      ██ ███████  █████  ████████ ██  ██████  ███    ██
# ██ ████   ██ ██    ██    ██ ██   ██ ██      ██      ██ ██   ██    ██    ██ ██    ██ ████   ██
# ██ ██ ██  ██ ██    ██    ██ ███████ ██      ██    ██   ███████    ██    ██ ██    ██ ██ ██  ██
# ██ ██  ██ ██ ██    ██    ██ ██   ██ ██      ██  ██     ██   ██    ██    ██ ██    ██ ██  ██ ██
# ██ ██   ████ ██    ██    ██ ██   ██ ███████ ██ ███████ ██   ██    ██    ██  ██████  ██   ████

# the following are needed for AirborneRadar in radar-generic.nas
var scanInterval = 0.05; # 20hz for main radar - TODO m2000 specific value
var wndprop = props.globals.getNode("environment/wind-speed-kt",0);


# start generic radar systems from radar-system.nas
var baser = AIToNasal.new();
var partitioner = NoseRadar.new();
var omni = OmniRadar.new(1.0, 150, -1);
var terrain = TerrainChecker.new(0.05, 1, 30);
var callsignToContact = CallsignToContact.new();
var dlnkRadar = DatalinkRadar.new(0.03, 110, 225); # this is in radar-generic.nas
var ecm = ECMChecker.new(0.05, 6);

var gmMode = RDYGMMode.new(RDYGMFTTMode.new());
var rdyRadar = AirborneRadar.newAirborne([[gmMode]], RDY);

# needed utility function
var getCompleteList = func {
	return baser.vector_aicontacts_last;
}

