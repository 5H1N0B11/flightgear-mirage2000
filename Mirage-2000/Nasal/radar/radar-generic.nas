# Direct copy of lines 0 - 1058 from apg-68.nas in F-16 as per 2024-10-06.
# Same for lines 2926 - 3348: TerrainMapper/Ground Mapper

# Changes from original:
#  * Around line 300 3 times: steerpoints.sending == nil replaced with 1 == 1



############# BEGIN SOMEWHAT GENERIC CLASSES ###########################################



# Field of regard requests
var FOR_ROUND  = 0;# TODO: be able to ask noseradar for round field of regard.
var FOR_SQUARE = 1;
#Pulses
var DOPPLER = 1;
var MONO = 0;

var overlapHorizontal = 1.5;


#   █████  ██ ██████  ██████   ██████  ██████  ███    ██ ███████     ██████   █████  ██████   █████  ██████
#  ██   ██ ██ ██   ██ ██   ██ ██    ██ ██   ██ ████   ██ ██          ██   ██ ██   ██ ██   ██ ██   ██ ██   ██
#  ███████ ██ ██████  ██████  ██    ██ ██████  ██ ██  ██ █████       ██████  ███████ ██   ██ ███████ ██████
#  ██   ██ ██ ██   ██ ██   ██ ██    ██ ██   ██ ██  ██ ██ ██          ██   ██ ██   ██ ██   ██ ██   ██ ██   ██
#  ██   ██ ██ ██   ██ ██████   ██████  ██   ██ ██   ████ ███████     ██   ██ ██   ██ ██████  ██   ██ ██   ██
#
#
var AirborneRadar = {
	#
	# This is an base class for an airborne forward looking radar
	# The class RadarMode uses this. Subclass as needed.
	#
	# TODO: Cleaner calls to optional ground mapper
	#
	fieldOfRegardType: FOR_SQUARE,
	fieldOfRegardMaxAz: 60,
	fieldOfRegardMaxElev: 60,
	fieldOfRegardMinElev: -60,
	currentMode: nil, # vector of cascading modes ending with current submode
	currentModeIndex: nil,
	rootMode: 0,
	mainModes: nil,
	instantFoVradius: 2.0,#average of horiz/vert radius
	instantVertFoVradius: 2.5,# real vert radius (could be used by ground mapper)
	instantHoriFoVradius: 1.5,# real hori radius (not used)
	rcsRefDistance: 70,
	rcsRefValue: 3.2,
	#closureReject: -1, # The minimum kt closure speed it will pick up, else rejected.
	#positionEuler: [0,0,0,0],# euler direction
	positionDirection: [1,0,0],# vector direction
	positionCart: [0,0,0,0],
	eulerX: 0,
	eulerY: 0,
	horizonStabilized: 1, # When true antennae ignore roll (and pitch until its high)
	vector_aicontacts_for: [],# vector of contacts found in field of regard
	vector_aicontacts_bleps: [],# vector of not timed out bleps
	chaffList: [],
	chaffSeenList: [],
	chaffFilter: 0.60,# 1=filters all chaff, 0=sees all chaff all the time
	timer: nil,
	timerMedium: nil,
	timerSlow: nil,
	timeToKeepBleps: 13,
	elapsed: elapsedProp.getValue(),
	lastElapsed: elapsedProp.getValue(),
	debug: 0,
	newAirborne: func (mainModes, child) {
		var rdr = {parents: [child, AirborneRadar, Radar]};

		rdr.mainModes = mainModes;

		foreach (modes ; mainModes) {
			foreach (mode ; modes) {
				# this needs to be set on submodes also...hmmm
				mode.radar = rdr;
			}
		}

		rdr.currentModeIndex = setsize([], size(mainModes));
		forindex (var i; rdr.currentModeIndex) {
			rdr.currentModeIndex[i] = 0;
		}

		rdr.setCurrentMode(rdr.mainModes[0][0], nil);

		rdr.SliceNotification = SliceNotification.new();
		rdr.ContactNotification = VectorNotification.new("ContactNotification");
		rdr.ActiveDiscRadarRecipient = emesary.Recipient.new("ActiveDiscRadarRecipient");
		rdr.ActiveDiscRadarRecipient.radar = rdr;
		rdr.ActiveDiscRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "FORNotification") {
	        	#printf("DiscRadar recv: %s", notification.NotificationType);
	            #if (rdr.enabled == 1) { no, lets keep this part running, so we have fresh data when its re-enabled
	    		    rdr.vector_aicontacts_for = notification.vector;
	    		    rdr.purgeBleps();
	    		    #print("size(rdr.vector_aicontacts_for)=",size(rdr.vector_aicontacts_for));
	    	    #}
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        if (notification.NotificationType == "ChaffReleaseNotification") {
	    		rdr.chaffList ~= notification.vector;
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(rdr.ActiveDiscRadarRecipient);
		rdr.timer = maketimer(scanInterval, rdr, func rdr.loop());
		rdr.timerSlow = maketimer(0.75, rdr, func rdr.loopSlow());
		rdr.timerMedium = maketimer(0.25, rdr, func rdr.loopMedium());
		rdr.timerMedium.start();
		rdr.timerSlow.start();
		rdr.timer.start();
    	return rdr;
	},
	getTiltKnob: func {
		me.theKnob = antennae_knob_prop.getValue();
		if (math.abs(me.theKnob) < 0.01) {
			antennae_knob_prop.setValue(0);
			me.theKnob = 0;
		}
		return me.theKnob*60;
	},
	increaseRange: func {
		if (me["gmapper"] != nil) me.gmapper.clear();
		me.currentMode.increaseRange();
	},
	decreaseRange: func {
		if (me["gmapper"] != nil) me.gmapper.clear();
		me.currentMode.decreaseRange();
	},
	designate: func (designate_contact) {
		me.currentMode.designate(designate_contact);
	},
	designateRandom: func {
		# Use this method mostly for testing
		if (size(me.vector_aicontacts_bleps) > 0) {
			me.designate(me.vector_aicontacts_bleps[-1]);
		}
	},
	undesignate: func {
		me.currentMode.undesignate();
	},
	getPriorityTarget: func {
		if (!me.enabled) return nil;
		return me.currentMode.getPriority();
	},
	cycleDesignate: func {
		me.currentMode.cycleDesignate();
	},
	cycleMode: func {
		me.currentModeIndex[me.rootMode] += 1;
		if (me.currentModeIndex[me.rootMode] >= size(me.mainModes[me.rootMode])) {
			me.currentModeIndex[me.rootMode] = 0;
		}
		me.newMode = me.mainModes[me.rootMode][me.currentModeIndex[me.rootMode]];
		me.newMode.setRange(me.currentMode.getRange());
		me.oldMode = me.currentMode;
		me.setCurrentMode(me.newMode, me.oldMode["priorityTarget"]);
	},
	cycleRootMode: func {
		me.rootMode += 1;
		if (me.rootMode >= size(me.mainModes)) {
			me.rootMode = 0;
		}

		me.newMode = me.mainModes[me.rootMode][me.currentModeIndex[me.rootMode]];
		#me.newMode.setRange(me.currentMode.getRange());
		me.oldMode = me.currentMode;
		me.setCurrentMode(me.newMode, me.oldMode["priorityTarget"]);
	},
	cycleAZ: func {
		if (me["gmapper"] != nil) me.gmapper.clear();
		me.clearShowScan();
		me.currentMode.cycleAZ();
	},
	cycleBars: func {
		me.currentMode.cycleBars();
		me.clearShowScan();
	},
	getDeviation: func {
		return me.currentMode.getDeviation();
	},
	setCursorDeviation: func (cursor_az) {
		return me.currentMode.setCursorDeviation(cursor_az);
	},
	getCursorDeviation: func {
		return me.currentMode.getCursorDeviation();
	},
	setCursorDistance: func (nm) {
		# Return if the cursor should be distance zeroed.
		return me.currentMode.setCursorDistance(nm);;
	},
	getCursorAltitudeLimits: func {
		if (!me.enabled) return nil;
		return me.currentMode.getCursorAltitudeLimits();
	},
	getBars: func {
		return me.currentMode.getBars();
	},
	getAzimuthRadius: func {
		return me.currentMode.getAz();
	},
	getMode: func {
		return me.currentMode.shortName;
	},
	setCurrentMode: func (new_mode, priority = nil) {
		me.olderMode = me.currentMode;
		me.currentMode = new_mode;
		new_mode.radar = me;
		#new_mode.setCursorDeviation(me.currentMode.getCursorDeviation()); # no need since submodes don't overwrite this
		new_mode.designatePriority(priority);
		if (me.olderMode != nil) me.olderMode.leaveMode();
		new_mode.enterMode();
		settimer(func me.clearShowScan(), 0.5);
	},
	setRootMode: func (mode_number, priority = nil) {
		me.rootMode = mode_number;
		if (me.rootMode >= size(me.mainModes)) {
			me.rootMode = 0;
		}

		me.newMode = me.mainModes[me.rootMode][me.currentModeIndex[me.rootMode]];
		#me.newMode.setRange(me.currentMode.getRange());
		me.oldMode = me.currentMode;
		me.setCurrentMode(me.newMode, priority);
	},
	getRange: func {
		return me.currentMode.getRange();
	},
	getCaretPosition: func {
		if (me["eulerX"] == nil or me["eulerY"] == nil) {
			return [0,0];
		} elsif (me.horizonStabilized) {
			return [me.eulerX/me.fieldOfRegardMaxAz,me.eulerY/me.fieldOfRegardMaxElev];
		} else {
			return [me.eulerX/me.fieldOfRegardMaxAz,me.eulerY/me.fieldOfRegardMaxElev];
		}
	},
	setAntennae: func (local_dir) {
		# remember to set horizonStabilized when calling this.

		# convert from coordinates to polar
		me.eulerDir = vector.Math.cartesianToEuler(local_dir);

		# Make sure if pitch is 90 or -90 that heading gets set to something sensible
		me.eulerX = me.eulerDir[0]==nil?0:geo.normdeg180(me.eulerDir[0]);
		me.eulerY = me.eulerDir[1];

		# Make array: [heading_degs, pitch_degs, heading_norm, pitch_norm], for convinience, not used atm.
		#me.positionEuler = [me.eulerX,me.eulerDir[1],me.eulerX/me.fieldOfRegardMaxAz,me.eulerDir[1]/me.fieldOfRegardMaxElev];

		# Make the antennae direction-vector be length 1.0
		me.positionDirection = vector.Math.normalize(local_dir);

		# Decompose the antennae direction-vector into seperate angles for Azimuth and Elevation
		me.posAZDeg = -90+R2D*math.acos(vector.Math.normalize(vector.Math.projVectorOnPlane([0,0,1],me.positionDirection))[1]);
		me.posElDeg = R2D*math.asin(vector.Math.normalize(vector.Math.projVectorOnPlane([0,1,0],me.positionDirection))[2]);

		# Make an array that holds: [azimuth_norm, elevation_norm, azimuth_deg, elevation_deg]
		me.positionCart = [me.posAZDeg/me.fieldOfRegardMaxAz, me.posElDeg/me.fieldOfRegardMaxElev,me.posAZDeg,me.posElDeg];

		# Note: that all these numbers can be either relative to aircraft or relative to scenery.
		# Its the modes responsibility to call this method with antennae local_dir that is either relative to
		# aircraft, or to landscape so that they match how scanFOV compares the antennae direction to target positions.
		#
		# Make sure that scanFOV() knows what coord system you are operating in. By setting me.horizonStabilized.
	},
	installMapper: func (gmapper) {
		me.gmapper = gmapper;
	},
	isEnabled: func {
		return 1;
	},
	loop: func {
		me.enabled = me.isEnabled();
		setprop("instrumentation/radar/radar-standby", !me.enabled);
		# calc dt here, so we don't get a massive dt when going from disabled to enabled:
		me.elapsed = elapsedProp.getValue();
		me.dt = me.elapsed - me.lastElapsed;
		me.lastElapsed = me.elapsed;
		if (me.enabled) {
			if (me.currentMode.painter and me.currentMode.detectAIR) {
				# We need faster updates to not lose track of oblique flying locks close by when in STT.
				me.ContactNotification.vector = [me.getPriorityTarget()];
				emesary.GlobalTransmitter.NotifyAll(me.ContactNotification);
			}

			while (me.dt > 0.001) {
				# mode tells us how to move disc and to scan
				me.dt = me.currentMode.step(me.dt);# mode already knows where in pattern we are and AZ and bars.

				# we then step to the new position, and scan for each step
				me.scanFOV();
				me.showScan();
			}

		} elsif (size(me.vector_aicontacts_bleps)) {
			# So that when radar is restarted there is not old bleps.
			me.purgeAllBleps();
		}
	},
	loopMedium: func {
		#
		# It send out what target we are Single-target-track locked onto if any so the target get RWR warning.
		# It also sends out on datalink what we are STT/SAM/TWS locked onto.
		# In addition it notifies the weapons what we have targeted.
		# Plus it sets the MP property for radar standby so others can see us on RWR.
		if (me.enabled) {
			me.focus = me.getPriorityTarget();
			if (me.focus != nil and me.focus.callsign != "") {
				if (me.currentMode.painter) sttSend.setValue(left(md5(me.focus.callsign), 4));
				else sttSend.setValue("");
				if (1 == 1) {
			        datalink.send_data({"contacts":[{"callsign":me.focus.callsign,"iff":0}]});
			    }
			} else {
				sttSend.setValue("");
				if (1 == 1) {
		            datalink.clear_data();
		        }
			}
			armament.contact = me.focus;
			stbySend.setIntValue(0);
		} else {
			armament.contact = nil;
			sttSend.setValue("");
			stbySend.setIntValue(1);
			if (1 == 1) {
	            datalink.clear_data();
	        }
		}

		me.debug = getprop("debug-radar/debug-main");
	},
	loopSlow: func {
		#
		# Here we ask the NoseRadar for a slice of the sky once in a while.
		#
		if (me.enabled and !(me.currentMode.painter and me.currentMode.detectAIR)) {
			emesary.GlobalTransmitter.NotifyAll(me.SliceNotification.slice(self.getPitch(), self.getHeading(), math.max(-me.fieldOfRegardMinElev, me.fieldOfRegardMaxElev)*1.414, me.fieldOfRegardMaxAz*1.414, me.getRange()*NM2M, !me.currentMode.detectAIR, !me.currentMode.detectSURFACE, !me.currentMode.detectMARINE));
		}
	},
	scanFOV: func {
		#
		# Here we test for IFF and test the radar beam against targets to see if the radar picks them up.
		#
		# Note that this can happen in aircraft coords (ACM modes) or in landscape coords (the other modes).
		me.doIFF = getprop("instrumentation/radar/iff");
    	setprop("instrumentation/radar/iff",0);
    	if (me.doIFF) iff.last_interogate = systime();
    	if (me["gmapper"] != nil) me.gmapper.scanGM(me.eulerX, me.eulerY, me.instantVertFoVradius, me.instantFoVradius,
    		 me.currentMode.bars == 1 or (me.currentMode.bars == 4 and me.currentMode["nextPatternNode"] == 0) or (me.currentMode.bars == 3 and me.currentMode["nextPatternNode"] == 7) or (me.currentMode.bars == 2 and me.currentMode["nextPatternNode"] == 1),
    		 me.currentMode.bars == 1 or (me.currentMode.bars == 4 and me.currentMode["nextPatternNode"] == 2) or (me.currentMode.bars == 3 and me.currentMode["nextPatternNode"] == 3) or (me.currentMode.bars == 2 and me.currentMode["nextPatternNode"] == 3));# The last two parameter is hack

    	# test for passive ECM (chaff)
		#
		me.closestChaff = 1000000;# meters
		if (size(me.chaffList)) {
			if (me.horizonStabilized) {
				me.globalAntennaeDir = vector.Math.yawVector(-self.getHeading(), me.positionDirection);
			} else {
				me.globalAntennaeDir = vector.Math.rollPitchYawVector(self.getRoll(), self.getPitch(), -self.getHeading(), me.positionDirection);
			}

			foreach (me.chaff ; me.chaffList) {
				if (rand() < me.chaffFilter or me.chaff.meters < 10000+10000*rand()) continue;# some chaff are filtered out.
				me.globalToTarget = vector.Math.pitchYawVector(me.chaff.pitch, -me.chaff.bearing, [1,0,0]);

				# Degrees from center of radar beam to center of chaff cloud
				me.beamDeviation = vector.Math.angleBetweenVectors(me.globalAntennaeDir, me.globalToTarget);

				if (me.beamDeviation < me.instantFoVradius) {
					if (me.chaff.meters < me.closestChaff) {
						me.closestChaff = me.chaff.meters;
					}
					me.registerChaff(me.chaff);# for displays
					#print("REGISTER CHAFF");
				}# elsif(me.debug > -1) {
					# This is too detailed for most debugging, remove later
				#	setprop("debug-radar/main-beam-deviation-chaff", me.beamDeviation);
				#}
			}
		}

    	me.testedPrio = 0;
		foreach(contact ; me.vector_aicontacts_for) {
			if (me.doIFF == 1) {
	            me.iffr = iff.interrogate(contact.prop);
	            if (me.iffr) {
	                contact.iff = me.elapsed;
	            } else {
	                contact.iff = -me.elapsed;
	            }
	        }
			if (me.elapsed - contact.getLastBlepTime() < me.currentMode.minimumTimePerReturn) {
				if(me.debug > 1 and me.currentMode.painter and contact == me.getPriorityTarget()) {
					me.testedPrio = 1;
				}
				continue;# To prevent double detecting in overlapping beams
			}

			me.dev = contact.getDeviationStored();

			if (me.horizonStabilized) {
				# ignore roll and pitch

				# Vector that points to target in radar coordinates as if aircraft it was not rolled or pitched.
				me.globalToTarget = vector.Math.eulerToCartesian3X(-me.dev.bearing,me.dev.elevationGlobal,0);

				# Vector that points to target in radar coordinates as if aircraft it was not yawed, rolled or pitched.
				me.localToTarget = vector.Math.yawVector(self.getHeading(), me.globalToTarget);
			} else {
				# Vector that points to target in local radar coordinates.
				me.localToTarget = vector.Math.eulerToCartesian3X(-me.dev.azimuthLocal,me.dev.elevationLocal,0);
			}

			# Degrees from center of radar beam to target, note that positionDirection must match the coord system defined by horizonStabilized.
			me.beamDeviation = vector.Math.angleBetweenVectors(me.positionDirection, me.localToTarget);

			if(me.debug > 1 and me.currentMode.painter and contact == me.getPriorityTarget()) {
				# This is too detailed for most debugging, remove later
				setprop("debug-radar/main-beam-deviation", me.beamDeviation);
				me.testedPrio = 1;
			}
			if (me.beamDeviation < me.instantFoVradius and (me.dev.rangeDirect_m < me.closestChaff or rand() < me.chaffFilter) ) {#  and (me.closureReject == -1 or me.dev.closureSpeed > me.closureReject)
				# TODO: Refine the chaff conditional (ALOT)
				me.registerBlep(contact, me.dev, me.currentMode.painter, me.currentMode.pulse);
				#print("REGISTER BLEP");

				# Return here, so that each instant FoV max gets 1 target:
				# TODO: refine by testing angle between contacts seen in this FoV
				break;
			}
		}

		if(me.debug > 1 and me.currentMode.painter and !me.testedPrio) {
			setprop("debug-radar/main-beam-deviation", "--unseen-lock--");
		}
	},
	registerBlep: func (contact, dev, stt, doppler = 1) {
		if (!contact.isVisible()) return 0;
		if (doppler) {
			if (contact.isHiddenFromDoppler()) {
				return 0;
			}
			if (math.abs(dev.closureSpeed) < me.currentMode.minClosure) {
				return 0;
			}
		}

		me.maxDistVisible = me.currentMode.rcsFactor * me.targetRCSSignal(self.getCoord(), dev.coord, contact.model, dev.heading, dev.pitch, dev.roll,me.rcsRefDistance*NM2M,me.rcsRefValue);

		if (me.maxDistVisible > dev.rangeDirect_m) {
			me.extInfo = me.currentMode.getSearchInfo(contact);# if the scan gives heading info etc..

			if (me.extInfo == nil) {
				return 0;
			}
			contact.blep(me.elapsed, me.extInfo, me.maxDistVisible, stt);
			if (!me.containsVectorContact(me.vector_aicontacts_bleps, contact)) {
				append(me.vector_aicontacts_bleps, contact);
			}
			return 1;
		}
		return 0;
	},
	registerChaff: func (chaff) {
		chaff.seenTime = me.elapsed;
		if (!me.containsVector(me.chaffSeenList, chaff)) {
			append(me.chaffSeenList, chaff);
		}
	},
	purgeBleps: func {
		#ok, lets clean up old bleps:
		me.vector_aicontacts_bleps_tmp = [];
		me.elapsed = elapsedProp.getValue();
		foreach(contact ; me.vector_aicontacts_bleps) {
			me.bleps_cleaned = [];
			foreach (me.blep;contact.getBleps()) {
				if (me.elapsed - me.blep.getBlepTime() < me.currentMode.timeToFadeBleps) {
					append(me.bleps_cleaned, me.blep);
				}
			}
			contact.setBleps(me.bleps_cleaned);
			if (size(me.bleps_cleaned)) {
				append(me.vector_aicontacts_bleps_tmp, contact);
				me.currentMode.testContact(contact);# TODO: do this smarter
			} else {
				me.currentMode.prunedContact(contact);
			}
		}
		#print("Purged ", size(me.vector_aicontacts_bleps) - size(me.vector_aicontacts_bleps_tmp), " bleps   remains:",size(me.vector_aicontacts_bleps_tmp), " orig ",size(me.vector_aicontacts_bleps));
		me.vector_aicontacts_bleps = me.vector_aicontacts_bleps_tmp;

		#lets purge the old chaff also, both seen and unseen
		me.wnd = wndprop.getValue();
		me.chaffLifetime = math.max(0, me.wnd==0?25:25*(1-me.wnd/50));
		me.chaffList_tmp = [];
		foreach(me.evilchaff ; me.chaffList) {
			if (me.elapsed - me.evilchaff.releaseTime < me.chaffLifetime) {
				append(me.chaffList_tmp, me.evilchaff);
			}
		}
		me.chaffList = me.chaffList_tmp;

		me.chaffSeenList_tmp = [];
		foreach(me.evilchaff ; me.chaffSeenList) {
			if (me.elapsed - me.evilchaff.releaseTime < me.chaffLifetime or me.elapsed - me.evilchaff.seenTime < me.timeToKeepBleps) {
				append(me.chaffSeenList_tmp, me.evilchaff);
			}
		}
		me.chaffSeenList = me.chaffSeenList_tmp;
	},
	purgeAllBleps: func {
		#ok, lets delete all bleps:
		foreach(contact ; me.vector_aicontacts_bleps) {
			contact.setBleps([]);
			me.currentMode.prunedContact(contact);
		}
		me.vector_aicontacts_bleps = [];
		me.chaffSeenList = [];
	},
	targetRCSSignal: func(aircraftCoord, targetCoord, targetModel, targetHeading, targetPitch, targetRoll, myRadarDistance_m = 74000, myRadarStrength_rcs = 3.2) {
		#
		# test method. Belongs in rcs.nas.
		#
	    me.target_front_rcs = getDBEntry(targetModel).rcsFrontal;
	    me.target_rcs = rcs.getRCS(targetCoord, targetHeading, targetPitch, targetRoll, aircraftCoord, me.target_front_rcs);

	    # standard formula
	    return myRadarDistance_m/math.pow(myRadarStrength_rcs/me.target_rcs, 1/4);
	},
	getActiveBleps: func {
		return me.vector_aicontacts_bleps;
	},
	getActiveChaff: func {
		return me.chaffSeenList;
	},
	showScan: func {
		if (me.debug > 0) {
			if (me["canvas2"] == nil) {
	            me.canvas2 = canvas.Window.new([512,512],"dialog").set('title',"Scan").getCanvas(1);
				me.canvas_root2 = me.canvas2.createGroup().setTranslation(256,256);
				me.canvas2.setColorBackground(0.25,0.25,1);
			}

			if (me.elapsed - me.currentMode.lastFrameStart < 0.1) {
				me.clearShowScan();
			}
			me.canvas_root2.createChild("path")
				.setTranslation(256*me.eulerX/60, -256*me.eulerY/60)
				.moveTo(0, 256*me.instantFoVradius/60)
				.lineTo(0, -256*me.instantFoVradius/60)
				.setColor(1,1,1);
		}
	},
	clearShowScan: func {
		if (me["canvas2"] == nil or me.debug < 1) return;
		me.canvas_root2.removeAllChildren();
		if (me.horizonStabilized) {
			me.canvas_root2.createChild("path")
				.moveTo(-250, 0)
				.lineTo(250, 0)
				.setColor(1,1,0)
				.setStrokeLineWidth(4);
		} else {
			me.canvas_root2.createChild("path")
				.moveTo(256*-5/60, 256*-1.5/60)
				.lineTo(256*5/60, 256*-1.5/60)
				.lineTo(256*5/60,  256*15/60)
				.lineTo(256*-5/60,  256*15/60)
				.lineTo(256*-5/60, 256*-1.5/60)
				.setColor(1,1,0)
				.setStrokeLineWidth(4);
		}
	},
	containsVector: func (vec, item) {
		foreach(test; vec) {
			if (test == item) {
				return 1;
			}
		}
		return 0;
	},

	containsVectorContact: func (vec, item) {
		foreach(test; vec) {
			if (test.equals(item)) {
				return 1;
			}
		}
		return 0;
	},

	vectorIndex: func (vec, item) {
		me.i = 0;
		foreach(test; vec) {
			if (test == item) {
				return me.i;
			}
			me.i += 1;
		}
		return -1;
	},
	del: func {
        emesary.GlobalTransmitter.DeRegister(me.ActiveDiscRadarRecipient);
    },
};










var SPOT_SCAN = -1; # must be -1





#  ██████   █████  ██████   █████  ██████      ███    ███  ██████  ██████  ███████
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██     ████  ████ ██    ██ ██   ██ ██
#  ██████  ███████ ██   ██ ███████ ██████      ██ ████ ██ ██    ██ ██   ██ █████
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██     ██  ██  ██ ██    ██ ██   ██ ██
#  ██   ██ ██   ██ ██████  ██   ██ ██   ██     ██      ██  ██████  ██████  ███████
#
#
var RadarMode = {
	#
	# Subclass and modify as needed.
	#
	radar: nil,
	range: 40,
	minRange: 5,
	maxRange: 160,
	az: 60,
	bars: 1,
	azimuthTilt: 0,# modes set these depending on where they want the pattern to be centered.
	elevationTilt: 0,
	barHeight: 0.80,# multiple of instantFoVradius
	barPattern:  [ [[-1,0],[1,0]] ],     # The second is multitude of instantFoVradius, the first is multitudes of me.az
	barPatternMin: [0],
	barPatternMax: [0],
	nextPatternNode: 0,
	scanPriorityEveryFrame: 0,# Related to SPOT_SCAN.
	timeToFadeBleps: 13,
	rootName: "Base",
	shortName: "",
	longName: "",
	superMode: nil,
	minimumTimePerReturn: 0.5,
	rcsFactor: 0.9,
	lastFrameStart: -1,
	lastFrameDuration: 5,
	detectAIR: 1,
	detectSURFACE: 0,
	detectMARINE: 0,
	pulse: DOPPLER, # MONO or DOPPLER
	minClosure: 0, # kt
	cursorAz: 0,
	cursorNm: 20,
	upperAngle: 10,
	lowerAngle: 10,
	painter: 0, # if the mode when having a priority target will produce a hard lock on target.
	mapper: 0,
	discSpeed_dps: 1,# current disc speed. Must never be zero.
	setRange: func (range) {
		me.testMulti = me.maxRange/range;
		if (int(me.testMulti) != me.testMulti) {
			# max range is not dividable by range, so we don't change range
			return 0;
		}
		me.range = math.min(me.maxRange, range);
		me.range = math.max(me.minRange, me.range);
		return range == me.range;
	},
	getRange: func {
		return me.range;
	},
	_increaseRange: func {
		me.range*=2;
		if (me.range>me.maxRange) {
			me.range*=0.5;
			return 0;
		}
		return 1;
	},
	_decreaseRange: func {
		me.range *= 0.5;
		if (me.range < me.minRange) {
			me.range *= 2;
			return 0;
		}
		return 1;
	},
	getDeviation: func {
		# how much the pattern is deviated from straight ahead in azimuth
		return me.azimuthTilt;
	},
	getBars: func {
		return me.bars;
	},
	getAz: func {
		return me.az;
	},
	constrainAz: func () {
		# Convinience method that the modes can use.
		if (me.az == me.radar.fieldOfRegardMaxAz) {
			me.azimuthTilt = 0;
		} elsif (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
			me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
		} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
			me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
		}
	},
	getPriority: func {
		return me["priorityTarget"];
	},
	computePattern: func {
		# Translate the normalized pattern nodes into degrees. Since me.az or maybe me.bars have tendency to change rapidly
		# We do this every step. Its fast anyway.
		me.currentPattern = [];
		foreach (me.eulerNorm ; me.barPattern[me.bars-1]) {
			me.patternNode = [me.eulerNorm[0]*me.az, me.eulerNorm[1]*me.radar.instantFoVradius*me.barHeight];
			append(me.currentPattern, me.patternNode);
		}
		return me.currentPattern;
	},
	step: func (dt) {
		me.radar.horizonStabilized = 1;# Might be unset inside preStep()

		# Individual modes override this method and get ready for the step.
		# Inside this they typically set 'azimuthTilt' and 'elevationTilt' for moving the pattern around.
		me.preStep();

		# Lets figure out the desired antennae tilts
	 	me.azimuthTiltIntern = me.azimuthTilt;
	 	me.elevationTiltIntern = me.elevationTilt;
		if (me.nextPatternNode == SPOT_SCAN and me.priorityTarget != nil) {
			# We never do spot scans in ACM modes so no check for horizonStabilized here.
			me.lastBlep = me.priorityTarget.getLastBlep();
			if (me.lastBlep != nil) {
				me.azimuthTiltIntern = me.lastBlep.getAZDeviation();
				me.elevationTiltIntern = me.lastBlep.getElev();
			} else {
				me.priorityTarget = nil;
				me.undesignate();
				me.nextPatternNode == 0;
			}
		} elsif (me.nextPatternNode == SPOT_SCAN) {
			# We cannot do spot scan on stuff we cannot see, reverting back to pattern
			me.nextPatternNode = 0;
		}

		# now lets check where we want to move the disc to
		me.currentPattern      = me.computePattern();
		me.targetAzimuthTilt   = me.azimuthTiltIntern+(me.nextPatternNode!=SPOT_SCAN?me.currentPattern[me.nextPatternNode][0]:0);
		me.targetElevationTilt = me.elevationTiltIntern+(me.nextPatternNode!=SPOT_SCAN?me.currentPattern[me.nextPatternNode][1]:0);

		# The pattern min/max pitch when not tilted.
		me.min = me.barPatternMin[me.bars-1]*me.barHeight*me.radar.instantFoVradius;
		me.max = me.barPatternMax[me.bars-1]*me.barHeight*me.radar.instantFoVradius;

		# We check if radar gimbal mount can turn enough.
		me.gimbalInBounds = 1;
		if (me.radar.horizonStabilized) {
			# figure out if we reach the gimbal limit
	 		me.actualMin = self.getPitch()+me.radar.fieldOfRegardMinElev;
	 		me.actualMax = self.getPitch()+me.radar.fieldOfRegardMaxElev;
	 		if (me.targetElevationTilt < me.actualMin) {
	 			me.gimbalInBounds = 0;
	 		} elsif (me.targetElevationTilt > me.actualMax) {
	 			me.gimbalInBounds = 0;
	 		}
 		}
 		if (!me.gimbalInBounds) {
 			# Don't move the antennae if it cannot reach whats requested.
 			# This basically stop the radar from working while still not on standby
 			# until better attitude is reached.
 			#
 			# It used to attempt to scan in edge of FoR but thats not really helpful to a pilot.
 			# If need to scan while extreme attitudes then the are specific modes for that (in some aircraft).
 			me.radar.setAntennae(me.radar.positionDirection);
 			#print("db-Out of gimbal bounds");
	 		return 0;
	 	}

	 	# For help with cursor limits we need to compute these
		if (me.radar.horizonStabilized and me.gimbalInBounds) {
			me.lowerAngle = me.min+me.elevationTiltIntern;
			me.upperAngle = me.max+me.elevationTiltIntern;
		} else {
			me.lowerAngle = 0;
			me.upperAngle = 0;
		}

	 	# Lets get a status for where we are in relation to where we are going
		me.targetDir = vector.Math.pitchYawVector(me.targetElevationTilt, -me.targetAzimuthTilt, [1,0,0]);# A vector for where we want the disc to go
		me.angleToNextNode = vector.Math.angleBetweenVectors(me.radar.positionDirection, me.targetDir);# Lets test how far from the target tilts we are.

		# Move the disc
		if (me.angleToNextNode < me.radar.instantFoVradius) {
			# We have reached our target
			me.radar.setAntennae(me.targetDir);
			me.nextPatternNode += 1;
			if (me.nextPatternNode >= size(me.currentPattern)) {
				me.nextPatternNode = (me.scanPriorityEveryFrame and me.priorityTarget!=nil)?SPOT_SCAN:0;
				me.frameCompleted();
			}
			#print("db-node:", me.nextPatternNode);
			# Now the antennae has been moved and we return how much leftover dt there is to the main radar.
			return dt-me.angleToNextNode/me.discSpeed_dps;# Since we move disc seperately in axes, this is not strictly correct, but close enough.
		}

		# Lets move each axis of the radar seperate, as most radars likely has 2 joints anyway.
		me.maxMove = math.min(me.radar.instantFoVradius*overlapHorizontal, me.discSpeed_dps*dt);# 1.75 instead of 2 is because the FoV is round so we overlap em a bit

		# Azimuth
		me.distance_deg = me.targetAzimuthTilt - me.radar.eulerX;
		if (me.distance_deg >= 0) {
			me.moveX =  math.min(me.maxMove, me.distance_deg);
		} else {
			me.moveX = math.max(-me.maxMove, me.distance_deg);
		}
		me.newX = me.radar.eulerX + me.moveX;

		# Elevation
		me.distance_deg = me.targetElevationTilt - me.radar.eulerY;
		if (me.distance_deg >= 0) {
			me.moveY =  math.min(me.maxMove, me.distance_deg);
		} else {
			me.moveY =  math.max(-me.maxMove, me.distance_deg);
		}
		me.newY = me.radar.eulerY + me.moveY;

		# Convert the angles to a vector and set the new antennae position
		me.newPos = vector.Math.pitchYawVector(me.newY, -me.newX, [1,0,0]);
		me.radar.setAntennae(me.newPos);

		# As the two joins move at the same time, we find out which moved the most
		me.movedMax = math.max(math.abs(me.moveX), math.abs(me.moveY));
		if (me.movedMax == 0) {
			# This should really not happen, we return 0 to make sure the while loop don't get infinite.
			print("me.movedMax == 0");
			return 0;
		}
		if (me.movedMax > me.discSpeed_dps) {
			print("me.movedMax > me.discSpeed_dps");
			return 0;
		}
		return dt-me.movedMax/me.discSpeed_dps;
	},
	frameCompleted: func {
		if (me.lastFrameStart != -1) {
			me.lastFrameDuration = me.radar.elapsed - me.lastFrameStart;
		}
		me.lastFrameStart = me.radar.elapsed;
	},
	setCursorDeviation: func (cursor_az) {
		me.cursorAz = cursor_az;
	},
	getCursorDeviation: func {
		return me.cursorAz;
	},
	setCursorDistance: func (nm) {
		# Return if the cursor should be distance zeroed.
		return 0;
	},
	getCursorAltitudeLimits: func {
		# Used in F-16 with two numbers next to cursor that indicates min/max for radar pattern in altitude above sealevel.
		# It needs: me.lowerAngle, me.upperAngle and me.cursorNm
		me.vectorToDist = [math.cos(me.upperAngle*D2R), 0, math.sin(me.upperAngle*D2R)];
		me.selfC = self.getCoord();
		me.geo = vector.Math.vectorToGeoVector(me.vectorToDist, me.selfC);
		me.geo = vector.Math.product(me.cursorNm*NM2M, vector.Math.normalize(me.geo.vector));
		me.up = geo.Coord.new();
		me.up.set_xyz(me.selfC.x()+me.geo[0],me.selfC.y()+me.geo[1],me.selfC.z()+me.geo[2]);
		me.vectorToDist = [math.cos(me.lowerAngle*D2R), 0, math.sin(me.lowerAngle*D2R)];
		me.geo = vector.Math.vectorToGeoVector(me.vectorToDist, me.selfC);
		me.geo = vector.Math.product(me.cursorNm*NM2M, vector.Math.normalize(me.geo.vector));
		me.down = geo.Coord.new();
		me.down.set_xyz(me.selfC.x()+me.geo[0],me.selfC.y()+me.geo[1],me.selfC.z()+me.geo[2]);
		return [me.up.alt()*M2FT, me.down.alt()*M2FT];
	},
	leaveMode: func {
		# Warning: In this method do not set anything on me.radar only on me.
		me.lastFrameStart = -1;
	},
	enterMode: func {
	},
	designatePriority: func (contact) {},
	cycleDesignate: func {},
	testContact: func (contact) {},
	prunedContact: func (c) {
		if (c.equalsFast(me["priorityTarget"])) {
			me.priorityTarget = nil;
		}
	},
};#                                    END Radar Mode class






#  ██████   █████  ████████  █████  ██      ██ ███    ██ ██   ██
#  ██   ██ ██   ██    ██    ██   ██ ██      ██ ████   ██ ██  ██
#  ██   ██ ███████    ██    ███████ ██      ██ ██ ██  ██ █████
#  ██   ██ ██   ██    ██    ██   ██ ██      ██ ██  ██ ██ ██  ██
#  ██████  ██   ██    ██    ██   ██ ███████ ██ ██   ████ ██   ██
#
#
DatalinkRadar = {
	# I check the sky 360 deg for anything on datalink
	#
	# I will set 'blue' and 'blueIndex' on contacts.
	# blue==1: On our datalink
	# blue==2: Targeted by someone on our datalink
	#
	# Direct line of sight required for ~1000MHz signal.
	#
	# This class is only semi generic!
	new: func (rate, max_dist_fighter_nm, max_dist_station_nm) {
		var dlnk = {parents: [DatalinkRadar, Radar]};

		dlnk.max_dist_fighter_nm = max_dist_fighter_nm;
		dlnk.max_dist_station_nm = max_dist_station_nm;

		datalink.can_transmit = func(callsign, mp_prop, mp_index) {
		    dlnk.contactSender = callsignToContact.get(callsign);
		    if (dlnk.contactSender == nil) return 0;
		    if (!dlnk.contactSender.isValid()) return 0;
		    if (!dlnk.contactSender.isVisible()) return 0;

		    dlnk.isContactStation = isKnownSurface(dlnk.contactSender.getModel()) or isKnownShip(dlnk.contactSender.getModel()) or isKnownAwacs(dlnk.contactSender.getModel());
		    dlnk.max_dist_nm = dlnk.isContactStation?dlnk.max_dist_station_nm:dlnk.max_dist_fighter_nm;

		    return dlnk.contactSender.get_range() < dlnk.max_dist_nm;
		}


		dlnk.index = 0;
		dlnk.vector_aicontacts = [];
		dlnk.vector_aicontacts_for = [];
		dlnk.timer          = maketimer(rate, dlnk, func dlnk.scan());

		dlnk.DatalinkRadarRecipient = emesary.Recipient.new("DatalinkRadarRecipient");
		dlnk.DatalinkRadarRecipient.radar = dlnk;
		dlnk.DatalinkRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "AINotification") {
	        	#printf("DLNKRadar recv: %s", notification.NotificationType);
	        	#printf("DLNKRadar notified of %d contacts", size(notification.vector));
    		    me.radar.vector_aicontacts = notification.vector;
    		    me.radar.index = 0;
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(dlnk.DatalinkRadarRecipient);
		dlnk.DatalinkNotification = VectorNotification.new("DatalinkNotification");
		dlnk.DatalinkNotification.updateV(dlnk.vector_aicontacts_for);
		dlnk.timer.start();
		return dlnk;
	},

	scan: func () {
		if (!me.enabled) return;

		#this loop is really fast. But we only check 1 contact per call
		if (me.index >= size(me.vector_aicontacts)) {
			# will happen if there is no contacts or if contact(s) went away
			me.index = 0;
			return;
		}
		me.contact = me.vector_aicontacts[me.index];
		me.wasBlue = me.contact["blue"];
		me.cs = me.contact.get_Callsign();
		if (me.wasBlue == nil) me.wasBlue = 0;

		if (!me.contact.isValid()) {
			me.contact.blue = 0;
			if (me.wasBlue > 0) {
				#print(me.cs," is invalid and purged from Datalink");
				me.new_vector_aicontacts_for = [];
				foreach (me.c ; me.vector_aicontacts_for) {
					if (!me.c.equals(me.contact) and !me.c.equalsFast(me.contact)) {
						append(me.new_vector_aicontacts_for, me.c);
					}
				}
				me.vector_aicontacts_for = me.new_vector_aicontacts_for;
			}
		} else {


	        if (!me.contact.isValid()) {
	        	me.lnk = nil;
	        } else {
	        	me.lnk = datalink.get_data(damage.processCallsign(me.cs));
	        }

	        if (me.lnk != nil and me.lnk.on_link() == 1) {
	            me.blue = 1;
	            me.blueIndex = me.lnk.index()+1;
	        } elsif (me.cs == getprop("link16/wingman-4")) { # Hack that the F16 need. Just ignore it, as nil wont cause expection.
	            me.blue = 1;
	            me.blueIndex = 0;
	        } else {
	        	me.blue = 0;
	            me.blueIndex = -1;
	        }
	        if (!me.blue and me.lnk != nil and me.lnk.tracked() == 1) {
	        	me.dl_idx = me.lnk.tracked_by_index();
	        	if (me.dl_idx != nil and me.dl_idx > -1) {
		            me.blue = 2;
		            me.blueIndex = me.dl_idx+1;
			    }
	        }

	        me.contact.blue = me.blue;
	        if (me.blue > 0) {
	        	me.contact.blueIndex = me.blueIndex;
				if (!AirborneRadar.containsVectorContact(me.vector_aicontacts_for, me.contact)) {
					append(me.vector_aicontacts_for, me.contact);
					emesary.GlobalTransmitter.NotifyAll(me.DatalinkNotification.updateV(me.vector_aicontacts_for));
				}
			} elsif (me.wasBlue > 0) {
				me.new_vector_aicontacts_for = [];
				foreach (me.c ; me.vector_aicontacts_for) {
					if (!me.c.equals(me.contact) and !me.c.equalsFast(me.contact)) {
						append(me.new_vector_aicontacts_for, me.c);
					}
				}
				me.vector_aicontacts_for = me.new_vector_aicontacts_for;
			}
		}
		me.index += 1;
        if (me.index > size(me.vector_aicontacts)-1) {
        	me.index = 0;

        	# Lets not keep contacts no longer in our scene
        	me.new_vector_aicontacts_for = [];
			foreach (me.c ; me.vector_aicontacts_for) {
				if (AirborneRadar.containsVectorContact(me.vector_aicontacts, me.c)) {
					append(me.new_vector_aicontacts_for, me.c);
				}
			}
			me.vector_aicontacts_for = me.new_vector_aicontacts_for;

        	emesary.GlobalTransmitter.NotifyAll(me.DatalinkNotification.updateV(me.vector_aicontacts_for));
        }
	},
	del: func {
        emesary.GlobalTransmitter.DeRegister(me.DatalinkRadarRecipient);
    },
};





#   ██████  ██████   ██████  ██    ██ ███    ██ ██████      ███    ███  █████  ██████  ██████  ███████ ██████
#  ██       ██   ██ ██    ██ ██    ██ ████   ██ ██   ██     ████  ████ ██   ██ ██   ██ ██   ██ ██      ██   ██
#  ██   ███ ██████  ██    ██ ██    ██ ██ ██  ██ ██   ██     ██ ████ ██ ███████ ██████  ██████  █████   ██████
#  ██    ██ ██   ██ ██    ██ ██    ██ ██  ██ ██ ██   ██     ██  ██  ██ ██   ██ ██      ██      ██      ██   ██
#   ██████  ██   ██  ██████   ██████  ██   ████ ██████      ██      ██ ██   ██ ██      ██      ███████ ██   ██
#
#
var TerrainMapper = {
	new: func (radar, rate) {
		var tm = {parents: [TerrainMapper, Radar]};
		tm.radar = radar;
		tm.timer = maketimer(rate, tm, func tm.loop());
		tm.timer.start();
		radar.installMapper(tm);
		tm.lowestElev = 0;
		tm.highestElev = 5000;
		tm.minElev = 35000;
		tm.maxElev = 0;
		tm.cleaned = 0;
		tm.exp = 0;
		tm.debug = 0;
		tm.t_geo = 0;
		tm.t_pix = 0;
		return tm;
	},
	##################################################################################################
	##################################################################################################
	#
	# TODO:
	#   Remove image painting from this class
	#   EXP mode
	#   Optimize
	#   Find reason for failing Coord._lat
	#   Pixel rounding error review (fills too few x)
	#
	azData: {
				radius: nil,
				az: 0,
				fromDist: nil,
				toDist: nil,
				domainNm: nil,
				domainFwdNm: nil,
				rangeFwdNm: nil,
				returns: nil,
			},
	scanGM: func (eulerX, eulerY, verticalInstantFoV, horizontalInstantFoV, bottomBar, topBar) {
		# GM test code
		if (displays.fcrFrz) return;
		if (me.radar.currentMode.mapper and me.enabled and me.radar.horizonStabilized and me["gmPic"] != nil and !me.exp) {
			if (me.debug > 3) {
				me.t0 = systime();
			}
			me.debug = getprop("debug-radar/debug-mapper");
			me.mapperHeading = eulerX+self.getHeading();
			me.discDirforGMTop = vector.Math.pitchYawVector(eulerY+verticalInstantFoV,-me.mapperHeading,[1,0,0]);
			me.discDirforGMBot = vector.Math.pitchYawVector(eulerY-verticalInstantFoV,-me.mapperHeading,[1,0,0]);
			if (me.debug) {
				setprop("debug-radar/mapper-pitch-high", eulerY+verticalInstantFoV);
				setprop("debug-radar/mapper-pitch", eulerY);
				setprop("debug-radar/mapper-pitch-low", eulerY-verticalInstantFoV);
			}

			me.selfCoord = self.getCoord();

			me.radarBeamGeoVectorTop = vector.Math.vectorToGeoVector(me.discDirforGMTop, me.selfCoord);
			me.radarBeamGeoVectorBot = vector.Math.vectorToGeoVector(me.discDirforGMBot, me.selfCoord);

			me.xyzSelf = {"x":me.selfCoord.x(), "y":me.selfCoord.y(), "z":me.selfCoord.z()};

            # Check for terrain at top and bottom of radar instant FoV
            me.terrainGeodTop = get_cart_ground_intersection(me.xyzSelf, me.radarBeamGeoVectorTop);
            me.terrainGeodBot = get_cart_ground_intersection(me.xyzSelf, me.radarBeamGeoVectorBot);
            #if (me.debug) {
			#	setprop("debug-radar/mapper-last-deg", math.abs(eulerX-me.azData.az));
			#}
            me.azData.az = eulerX;
            me.azData.radius = horizontalInstantFoV;
            me.azData.returns = [];
            if (me.terrainGeodBot != nil) {
            	me.terrainCoordBot = geo.Coord.new().set_latlon(me.terrainGeodBot.lat, me.terrainGeodBot.lon, me.terrainGeodBot.elevation);
            	me.azData.fromDist = me.selfCoord.distance_to(me.terrainCoordBot)*M2NM;
            	if (!me.testRange(me.azData.fromDist, me.radar.getRange(), me.azData.az)) return;
            	if (me.terrainGeodTop != nil) {
            		me.terrainCoordTop = geo.Coord.new().set_latlon(me.terrainGeodTop.lat, me.terrainGeodTop.lon, me.terrainGeodTop.elevation);
            		if (me.debug) {
						setprop("debug-radar/mapper-domain-lost-nm", "works");
					}
            	} else {
            		# The upper part of this instantFoV does not hit terrain here. So we manually add a little bit.
            		me.terrainCoordTop = geo.Coord.new(me.terrainCoordBot);
            		if (me.azData.domainNm != nil) {
            			me.topRange = me.azData.domainNm;
            		} else {
            			me.topRange = me.radar.getRange() * 1.25 - me.azData.fromDist;
            		}
            		me.topRange = math.max(me.topRange, 15);
            		if (me.debug) {
						setprop("debug-radar/mapper-domain-lost-nm", me.topRange);
					}
            		me.terrainCoordTop.apply_course_distance(me.mapperHeading, me.topRange*NM2M);
            	}
            	me.azData.toDist = me.selfCoord.distance_to(me.terrainCoordTop)*M2NM;
            	me.azData.domainNm = me.azData.toDist-me.azData.fromDist;
            	me.azCos = math.cos(me.azData.az*D2R);
            	me.azData.rangeFwdNm = me.azData.fromDist*me.azCos;
            	me.azData.domainFwdNm = me.azData.domainNm*me.azCos;
            	me.pixelsBetweenTopAndBot = math.ceil(me.gmPicSize*me.azData.domainFwdNm/me.radar.getRange());
				me.maskAlt  = 0;
				me.maskStep = -1;

				# Amount each step changes in altitude meters for center of beam.
				# Curvature of earth is negliable.
				# Each steps has different angle in reality, but its minute.
				me.maskAltPerStep = math.tan(eulerY*D2R)*NM2M*me.azData.domainNm/me.pixelsBetweenTopAndBot;

            	for (var i = 0; i <= me.pixelsBetweenTopAndBot; i += 1) {
            		me.testCoord = me.interpolateCoords(me.terrainCoordBot, me.terrainCoordTop, i/me.pixelsBetweenTopAndBot);
            		me.gm_geod = geodinfo(me.testCoord.lat(), me.testCoord.lon(), 10000);
            		if (debug.isnan(me.testCoord._lat)) {
            			#print("self ",me.selfCoord._lat);
            			print("test ",me.testCoord._lat," , ",me.testCoord.lat()," , ",me.testCoord.alt());
            			#print("bot  ",me.terrainCoordBot._x," , ",me.terrainCoordBot._y," , ",me.terrainCoordBot._z,"  ,  ",me.terrainGeodBot.elevation*M2FT);
            			#print(i);
            			append(me.azData.returns, 0);
            			continue;
            		}
            		me.gmReturn = 0;
            		if (me.gm_geod != nil) {
            			if (me.gm_geod[0] > me.maskAlt+(i - me.maskStep)*me.maskAltPerStep) {
            				# Terrain not masked by previous terrain
            				me.maskAlt = me.gm_geod[0];
            				me.maskStep = i;
            				me.gmReturn = me.backScatter(me.gm_geod);
            			} else {
            				me.gmReturn = -1;
            			}
            		} else {
            			me.gmReturn = -2;
            		}
            		append(me.azData.returns, me.gmReturn);
            	}
            	#me.debugOutput();
            	if (me.debug > 3) {
            		me.t1 = systime();
            	}
            	me.paintImage(me.azData, bottomBar, topBar);
            	if (me.debug > 3) {
	            	me.t2 = systime();
	            	me.t_geo += me.t1-me.t0;
	            	me.t_pix += me.t2-me.t1;
	            }
            }
            if (me.dirty) {
            	me.gmPic.dirtyPixels();
            	me.dirty = 0;
            }
		}
	},
	setImage: func (image, origin_x, origin_y, dimension, monochrome, gainNode) {
		if (me["gmPic"] == nil) {
			#me.canvas = canvas.Window.new([512,512],"dialog").set('title',"GM").getCanvas(1);
			#me.canvas_root = me.canvas.createGroup();
			#me.canvas.setColorBackground(0,0,0,1);
			me.gainNode = gainNode;
			me.gmPic = image;
            me.dirty = 0;
            me.gmPicSize  = dimension;
            me.mono = monochrome;
            me.gm_x_origin = origin_x;
            me.gm_y_origin = origin_y;
            #me.gmPic.setPixel(me.gm_x_origin, me.gm_y_origin, [0,0,1,1]);#blue pixel at ownship
            return 1;
		} else {
			return 0;
		}
	},
	removeImage: func {
		me.gmPic = nil;
	},
	paintImage: func (azData, bottomBar, topBar) {

		me.iStart = math.floor(me.gmPicSize*azData.rangeFwdNm/me.radar.getRange());

		if (me.debug) {
			setprop("debug-radar/mapper-steps", size(azData.returns));
			setprop("debug-radar/mapper-domain-fwd-nm", azData.domainFwdNm);
		}

		# If top or bottom or only 1 bar, pad ahead/behind with nil. This will clear old returns on screen.
		if (bottomBar and me.iStart > 0) {
			azData.returns = setsize([], me.iStart) ~ azData.returns;
			me.iStart = 0;
		}
		me.behindPad = (int)((1-me.azData.rangeFwdNm/me.radar.getRange())*me.gmPicSize*1.3);
		if (topBar and me.behindPad > 0) {
			azData.returns = azData.returns ~ setsize([], me.behindPad);
		}

		me.jStart = math.tan((azData.az-azData.radius)*D2R);
		me.jMid   = math.tan(azData.az*D2R);
		me.jEnd   = math.tan((azData.az+azData.radius)*D2R);
		me.jFactor = me.jEnd-me.jStart;

		#me.firstY = 0;
		#me.firstX = 0;

		for (var i = 0; i < size(azData.returns); i+=1 ) {
			me.debugColor = nil;
			if (me.debug > 2) {
				if (azData.returns[i] == nil) {
					me.debugColor = [0,0,1,1];# Blue for not hit by FoV
				} elsif (azData.returns[i] == -1) {
					me.debugColor = [1,1,0,1];# Yellow for terrain masked
				} elsif (azData.returns[i] == -2) {
					me.debugColor = [1,0,0,1];# Red for terrasunk
				} else {
					me.gmColor = math.pow(math.clamp(azData.returns[i],0,1), me.gainNode.getValue());
				}
			} else {
				me.gmColor = azData.returns[i]==nil?0:math.pow(math.clamp(azData.returns[i],0,1), me.gainNode.getValue());
			}

			me.gmY  = me.gm_y_origin+me.iStart+i;
			me.gmX  = math.floor(me.gm_x_origin+me.jMid*(i+me.iStart));
			me.gmX0 = me.gm_x_origin+me.jStart*(i+me.iStart);
			me.gmXj = math.round(me.gmX0+(i+me.iStart)*me.jFactor-0.5);
			me.gmX0 = math.min(me.gmX, math.round(me.gmX0));
			#if (me.firstY == 0) {
			#	me.firstY = math.max(me.gmY, 0)-me.gm_y_origin;
			#	me.firstX = me.gmXj;
			#}
			for (var j = me.gmX0; j <= me.gmXj; j += 1) {
				if (j >= 0 and j <= me.gmPicSize-1 and me.gmY <= me.gmPicSize-1) {
					me.gmPic.setPixel(j, math.max(me.gmY, 0), me.debugColor==nil?[me.gmColor*me.mono,me.gmColor,me.gmColor*me.mono,1]:me.debugColor);
					me.dirty = 1;
				}
			}
		}
		#if (bottomBar and me.firstY != 0) {
		#	# Clear the field below the bottom bar as we might have risen in alitude so its old data shown closer to ownship that can confuse pilot.
		#	for (var y = me.firstY-1; y >= 0; y-=1 ) {
		#		#var x = math.clamp(me.gm_x_origin + (y/me.firstY) * me.firstX, 0, 63);
		#		if (me.firstX > 31)    {me.gmPic.setPixel(me.firstX,   y, [0,0,0,1]);me.gmPic.setPixel(me.firstX-1, y, [0,0,0,1]);me.gmPic.setPixel(me.firstX-2, y, [0,0,0,1]);}
		#		elsif (me.firstX < 31) {me.gmPic.setPixel(me.firstX+1, y, [0,0,0,1]);me.gmPic.setPixel(me.firstX+2, y, [0,0,0,1]);me.gmPic.setPixel(me.firstX+3, y, [0,0,0,1]);}
		#		else                    me.gmPic.setPixel(me.firstX,   y, [0,0,0,1]);
		#	}
		#}
	},
	expChanged: func (exp) {
		if (me["gmPic"] == nil or exp == me.exp) return;
		me.exp = exp;
		if (me.exp) {
			me.gmPic.fillRect([0,0,me.gmPicSize,me.gmPicSize], [0.0*me.mono,0.0,0.0*me.mono,0]);# why does it allow 64??
			me.gmPic.dirtyPixels();
			me.dirty = 0;
		} else {
			me.cleanImage();
		}
	},
	cleanImage: func {
		if (me["gmPic"] == nil) return;
		me.gmPic.fillRect([0,0,me.gmPicSize,me.gmPicSize], [0,0,0,0]);# why does it allow 64??
		#me.gmPic.setPixel(me.gm_x_origin, me.gm_y_origin, [0,0,1,1]);#blue pixel at ownship
		me.gmPic.dirtyPixels();
		me.dirty = 0;
	},
	loop: func {
		if (displays.fcrFrz) return;
		if (me.enabled and me.radar.currentMode.mapper and me["gmPic"] != nil and me.dirty) {
			me.gmPic.dirtyPixels();
		}
		if (!me.radar.enabled and !me.cleaned) {
			me.cleanImage();
			me.cleaned = 1;
		} else {
			me.cleaned = 0;
		}
		if (me.debug > 3) {
			printf("geo=%8.6f pix=%8.6f",me.t_geo, me.t_pix);
			me.t_geo = 0;
			me.t_pix = 0;
		}
	},
	clear: func {
		#me.lowestElev = 0;
		#me.highestElev = 1000*math.ceil(getprop("position/ground-elev-ft")*0.001);
		#me.minElev = 35000;
		#me.maxElev = 0;
		me.cleanImage();
	},
	testRange: func (range, maxRange, az) {
		if (range > maxRange) {
			return 0;
		}
		az = math.abs(az)*D2R;
		if (math.sin(az)*range > maxRange*0.5) {
			return 0;
		}
		return 1;
	},
	debugOutput: func {
		if (me.radar.currentMode.bars == 4 and me.radar.currentMode["nextPatternNode"] != nil) {
        	if (me.radar.currentMode.nextPatternNode == 0) {
        		me.barCount = "4th";
        	} elsif (me.radar.currentMode.nextPatternNode == 1) {
        		me.barCount = "   ";return;
        	} elsif (me.radar.currentMode.nextPatternNode == 2) {
        		me.barCount = "1st";
        	} elsif (me.radar.currentMode.nextPatternNode == 3) {
        		me.barCount = "   ";return;
        	} elsif (me.radar.currentMode.nextPatternNode == 4) {
        		me.barCount = "2nd";
        	} elsif (me.radar.currentMode.nextPatternNode == 5) {
        		me.barCount = "   ";return;
        	} elsif (me.radar.currentMode.nextPatternNode == 6) {
        		me.barCount = "3rd";
        	} elsif (me.radar.currentMode.nextPatternNode == 7) {
        		me.barCount = "   ";return;
        	} else {
        		me.barCount = "Unk";return;
        	}
        	printf("AGL %5dft. Bar %s. Distance to bottom %.1fnm. Bottom to top %6.2fnm. Pitch %5.2f to %5.2f degs",getprop("position/altitude-agl-ft"), me.barCount, me.selfCoord.direct_distance_to(me.terrainCoordBot)*M2NM, me.terrainCoordBot.direct_distance_to(me.terrainCoordTop)*M2NM,me.eulerY-me.radar.instantFoVradius,me.radar.eulerY+me.radar.instantFoVradius);
        }
	},
	backScatter: func (gm_geod) {
		if (gm_geod == nil) {
			me.reflection = 0;
		} else {
			if (gm_geod[1] == nil) {
				me.reflection = 1;
			} elsif (!gm_geod[1].solid) {
				me.reflection = 0.05;
				if (me.gm_geod[0] != nil) {
					me.testElev = me.gm_geod[0]*M2FT;
					if (me.testElev < me.minElev) {
						me.minElev = me.testElev;
					}
				}
			} else {
				me.retur = me.howReflective(gm_geod[1]);
				if (me.retur == 0) {
					me.retur = gm_geod[1].bumpiness;
				}
				me.testElev = me.gm_geod[0]*M2FT;
				if (me.testElev < me.minElev) {
					me.minElev = me.testElev;
				}
				if (me.testElev > me.maxElev) {
					me.maxElev = me.testElev;
				}
				me.reflection = math.min(1, me.extrapolate(me.testElev, me.lowestElev, me.highestElev, 0.15, 0.6)+me.retur*0.4);
			}
		}
		return me.reflection;
	},
	frameDone: func {
		if (me.minElev != 35000 or me.maxElev != 0) {
			me.highestElev = (me.highestElev*1.5+me.maxElev)/2.5;# a simple lowpass filter to prevent it from changing too abrupt.
			me.lowestElev = (me.lowestElev*1.5+math.max(0, math.min(me.maxElev-1000, me.minElev)))/2.5;# prevent somewhat flat terrain to show as very undulated.
		}
		if (me.debug) setprop("debug-radar/mapper-elevation-min", me.lowestElev);
		if (me.debug) setprop("debug-radar/mapper-elevation-max", me.highestElev);

		me.minElev = 35000;
		me.maxElev = 0;
	},
	howReflective: func(info) {
		# from AJS-37
	    foreach (var name; info.names) {
	        if (contains(me.urban_names, name)) return 1;
	    }
	    foreach (var name; info.names) {
	        if (contains(me.natural_names, name)) return me.natural_names[name];
	    }
    	return 0;
    },
    urban_names: {
		# from AJS-37
	    "Urban": 1,
	    "BuiltUpCover": 1,
	    "Construction": 1,
	    "Industrial": 1,
	    "Port": 1,
	    "Town": 1,
	    "SubUrban": 1,
	},
	natural_names: {
		# TODO: find more real data on this. Best source so far: AP3456 – 11-x - Radar
	    "Cliffs": 0.8,  # tend to be steep, hence greater return
	    "Asphalt": 0.7, # very granular hence good backscatter
	    "Airport": 0.5, #
	    "Rock": 0.6,    # tend to be somewhat steep, hence some solid backscatter
	    "RainForest": 0.35,
	    "MixedForest": 0.35,# wood does very little backscatter, but trees are upright, so good opportunity for specular return
	    "AgroForest": 0.25,
	    "SnowCover": 0.2,   # snow is very diffuse, hence very little backscatter
	    "PolarIce": 0.4,
	    "PackIce": 0.25,    # very smooth like the water it formed on, hence little return
	    "Glacier": 0.5,
	},
	interpolateCoords: func (start, end, fraction) {
		if (fraction == 0) {
			return geo.Coord.new(start);
		}
		if (fraction == 1) return geo.Coord.new(end);
		me.xx = (start.x()*(1-fraction)+end.x()*fraction);
		me.yy = (start.y()*(1-fraction)+end.y()*fraction);
		me.zz = (start.z()*(1-fraction)+end.z()*fraction);

		me.cc = geo.Coord.new();
		me.cc.set_xyz(me.xx,me.yy,me.zz);

		return me.cc;
	},
	extrapolate: func (x, x1, x2, y1, y2) {
    	return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
	},
	##################################################################################################
	##################################################################################################
	##################################################################################################
	##################################################################################################
};





