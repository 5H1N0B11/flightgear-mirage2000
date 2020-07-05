#
# Prototype to test Richard and radar-mafia's radar designs.
#
# In Richards design, the class called RadarSystem is being represented as AIToNasal, NoseRadar, OmniRadar & TerrainChecker classes.
#                     the class called AircraftRadar is represented as ActiveDiscRadar & RWR.
#                     the class called AIContact does allow for direct reading of properties, but this is forbidden outside RadarSystem. Except for Missile-code.
#
# v1: 7 Nov. 2017 - Modular
# v2: 8 Nov 2017 - Decoupled via emesary
# v3: 10 Nov 2017 - NoseRadar now finds everything inside an elevation bar on demand,
#     and stuff is stored in Nasal.
#     Most methods are reused from v2, and therefore the code is a bit messy now, especially method/variable names and AIContact.
#     Weakness:
#         1) Asking NoseRadar for a slice when locked, is very inefficient.
#         2) If RWR should be feed almost realtime data, at least some properties needs to be read all the time for all aircraft. (damn it!)
# v4: 10 Nov 2017 - Fixed weakness 1 in v3.
# v5: 11 Nov 2017 - Fixed weakness 2 in v3. And added terrain checker.
# v5.1 test for shinobi
#
#
#
# RCS check done in ActiveDiscRadar at detection time, so about every 5-10 seconds per contact.
#      Faster for locks since its important to lose lock if it turns nose to us suddenly and can no longer be seen.
# Terrain check done in TerrainChecker, 10 contacts per second. All contacts being evaluated due to rwr needs that.
# Doppler is not being done.
# Properties is only being read in the modules that represent RadarSystem.
#
#
#
#
# Notice that everything below test code line, is not decoupled, nor optimized in any way.
# Also notice that most comments at start of classes are old and not updated.
#
# Needs rcs.nas and vector.nas. Nothing else. When run, it will display a couple of example canvas dialogs on screen.
#
# GPL 2.0


var AIR = 0;
var MARINE = 1;
var SURFACE = 2;
var ORDNANCE = 3;

var GEO = 0;
var GPS = 1;

var FALSE = 0;
var TRUE = 1;

var knownShips = {
    "missile_frigate":       nil,
    "frigate":       nil,
    "USS-LakeChamplain":     nil,
    "USS-NORMANDY":     nil,
    "USS-OliverPerry":     nil,
    "USS-SanAntonio":     nil,
};

var VectorNotification = {
    new: func(type) {
        var new_class = emesary.Notification.new(type, rand());
        new_class.updateV = func (vector) {
	    	me.vector = vector;
	    	return me;
	    };
        return new_class;
    },
};

var SliceNotification = {
    new: func() {
        var new_class = emesary.Notification.new("SliceNotification", rand());
        new_class.slice = func (elev_from, elev_to, bear_from, bear_to, dist_m) {
	    	me.elev_from = elev_from;
	    	me.elev_to = elev_to;
	    	me.bear_from = bear_from;
	    	me.bear_to = bear_to;
	    	me.dist_m = dist_m;
	    	return me;
	    };
        return new_class;
    },
};





###GPSContact:
# inherits from Contact
#
# Attributes:
#   coord

###RadarContact:
# inherits from AIContact
#
# Attributes:
#   isPainted()  [asks parent radar is it the one that is painted]
#   isDetected() [asks parent radar if it still is in limitedContactVector]

###LinkContact:
# inherits from AIContact
#
# Attributes:
#   isPainted()  [asks parent radar is it the one that is painted]
#   link to linking aircraft AIContact
#   isDetected() [asks parent radar if it still is in limitedContactVector]



radar = {
# master radar class
#
# Attributes:
#   on/off
#   limitedContactVector of RadarContacts
	enabled: TRUE,
};

NoseRadar = {
	new: func (range_m, radius, rate) {
		var nr = {parents: [NoseRadar, radar]};

		nr.forRadius_deg  = radius;
		nr.forDist_m      = range_m;#range setting
		nr.vector_aicontacts = [];
		nr.vector_aicontacts_for = [];
		#nr.timer          = maketimer(rate, nr, func nr.scanFOR());

		nr.NoseRadarRecipient = emesary.Recipient.new("NoseRadarRecipient");
		nr.NoseRadarRecipient.radar = nr;
		nr.NoseRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "AINotification") {
	        	#printf("NoseRadar recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.vector_aicontacts = notification.vector;
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        } elsif (notification.NotificationType == "SliceNotification") {
	        	#printf("NoseRadar recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.scanFOR(notification.elev_from, notification.elev_to, notification.bear_from, notification.bear_to, notification.dist_m);
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        } elsif (notification.NotificationType == "ContactNotification") {
	        	#printf("NoseRadar recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.scanSingleContact(notification.vector[0]);
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(nr.NoseRadarRecipient);
		nr.FORNotification = VectorNotification.new("FORNotification");
		nr.FORNotification.updateV(nr.vector_aicontacts_for);
		#nr.timer.start();
		return nr;
	},

	scanFOR: func (elev_from, elev_to, bear_from, bear_to, dist_m) {
		#iterate:
		# check direct distance
		# check field of regard
		# sort in bearing?
		# called on demand
		me.vector_aicontacts_for = [];
		foreach(contact ; me.vector_aicontacts) {
			if (!contact.isVisible()) {  # moved to nose radar
				continue;
			}
			me.dev = contact.getDeviation();
			me.rng = contact.getRangeDirect();
			if (me.dev[0] < bear_from or me.dev[0] > bear_to) {
				continue;
			} elsif (me.dev[1] < elev_from or me.dev[1] > elev_to) {
				continue;
			} elsif (me.rng > dist_m) {
				continue;
			}
			contact.storeDeviation([me.dev[0],me.dev[1],me.rng,contact.getCoord(),contact.getHeading(), contact.getPitch(), contact.getRoll()]);
			append(me.vector_aicontacts_for, contact);
		}		
		emesary.GlobalTransmitter.NotifyAll(me.FORNotification.updateV(me.vector_aicontacts_for));
		#print("In Field of Regard: "~size(me.vector_aicontacts_for));
	},

	scanSingleContact: func (contact) {
		# called on demand
		me.vector_aicontacts_for = [];
		me.dev = contact.getDeviation();
		me.rng = contact.getRangeDirect();
		contact.storeDeviation([me.dev[0],me.dev[1],me.rng,contact.getCoord(),contact.getHeading(), contact.getPitch(), contact.getRoll()]);
		append(me.vector_aicontacts_for, contact);

		emesary.GlobalTransmitter.NotifyAll(me.FORNotification.updateV(me.vector_aicontacts_for));
		#print("In Field of Regard: "~size(me.vector_aicontacts_for));
	},
};



OmniRadar = {
	new: func (rate) {
		var nr = {parents: [OmniRadar, radar]};

		nr.vector_aicontacts = [];
		nr.vector_aicontacts_for = [];
		nr.timer          = maketimer(rate, nr, func nr.scan());

		nr.OmniRadarRecipient = emesary.Recipient.new("OmniRadarRecipient");
		nr.OmniRadarRecipient.radar = nr;
		nr.OmniRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "AINotification") {
	        	#printf("NoseRadar recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.vector_aicontacts = notification.vector;
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(nr.OmniRadarRecipient);
		nr.OmniNotification = VectorNotification.new("OmniNotification");
		nr.OmniNotification.updateV(nr.vector_aicontacts_for);
		nr.timer.start();
		return nr;
	},

	scan: func () {
		if (!enableRWR) return;
		me.vector_aicontacts_for = [];
		foreach(contact ; me.vector_aicontacts) {
			if (!contact.isVisible()) { # moved to omniradar
				continue;
			}
			me.ber = contact.getBearing();
			me.head = contact.getHeading();
			me.test = me.ber+180-me.head;
			me.tp = contact.isTransponderEnable();
			me.radar = contact.isRadarEnable();
            if (math.abs(geo.normdeg180(me.test)) < 60 or me.tp) {
            	contact.storeThreat([me.ber,me.head,contact.getCoord(),me.tp,me.radar,contact.getDeviationHeading(),contact.getRangeDirect()*M2NM]);
				append(me.vector_aicontacts_for, contact);
			}
		}		
		emesary.GlobalTransmitter.NotifyAll(me.OmniNotification.updateV(me.vector_aicontacts_for));
		#print("In omni Field: "~size(me.vector_aicontacts_for));
	},
};




TerrainChecker = {
	new: func (rate) {
		var nr = {parents: [TerrainChecker]};

		nr.vector_aicontacts = [];
		nr.timer          = maketimer(rate, nr, func nr.scan());

		nr.TerrainCheckerRecipient = emesary.Recipient.new("TerrainCheckerRecipient");
		nr.TerrainCheckerRecipient.radar = nr;
		nr.TerrainCheckerRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "AINotification") {
	        	#printf("NoseRadar recv: %s", notification.NotificationType);
	    		me.radar.vector_aicontacts = notification.vector;
	    		me.radar.index = 0;
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(nr.TerrainCheckerRecipient);
		nr.index = 0;
		nr.timer.start();
		return nr;
	},

	scan: func () {
		#this loop is really fast. But we only check 1 contact per call
		if (me.index > size(me.vector_aicontacts)-1) {
			# will happen if there is no contacts
			return;
		}
		me.contact = me.vector_aicontacts[me.index];
        me.contact.setVisible(me.terrainCheck(me.contact));
        me.index += 1;
        if (me.index > size(me.vector_aicontacts)-1) {
        	me.index = 0;
        }
	},

	terrainCheck: func (contact) {
		me.myOwnPos = contact.getAcCoord();
		me.SelectCoord = contact.getCoord();
		if(me.myOwnPos.alt() > 8900 and me.SelectCoord.alt() > 8900) {
	      # both higher than mt. everest, so not need to check.
	      return TRUE;
	    }
	    
		me.xyz = {"x":me.myOwnPos.x(),                  "y":me.myOwnPos.y(),                 "z":me.myOwnPos.z()};
		me.dir = {"x":me.SelectCoord.x()-me.myOwnPos.x(),  "y":me.SelectCoord.y()-me.myOwnPos.y(), "z":me.SelectCoord.z()-me.myOwnPos.z()};

		# Check for terrain between own aircraft and other:
		me.v = get_cart_ground_intersection(me.xyz, me.dir);
		if (me.v == nil) {
			return TRUE;
			#printf("No terrain, planes has clear view of each other");
		} else {
			me.terrain = geo.Coord.new();
			me.terrain.set_latlon(me.v.lat, me.v.lon, me.v.elevation);
			me.maxDist = me.myOwnPos.direct_distance_to(me.SelectCoord);
			me.terrainDist = me.myOwnPos.direct_distance_to(me.terrain);
			if (me.terrainDist < me.maxDist) {
		 		#print("terrain found between the planes");
		 		return FALSE;
			} else {
		  		return TRUE;
		  		#print("The planes has clear view of each other");
			}
		}
	},
};




var NONE = 0;
var SOFT = 1;#TWS mode only. Gives so much info that some missiles like Amraam can actually be fired. Unlike real lock opponent wont know he is locked. Shorter range than real lock.
var HARD = 2;#real lock. Opponent RWR will go off. Sparrow missile probably needs this kind of lock.

var max_soft_locks = 8;
var time_to_keep_bleps = 6;
var time_to_fadeout_bleps = 5;
var time_till_lose_lock = 0.5;
var time_till_lose_lock_soft = 4.5;
var sam_radius = 15;# in SAM mode it will scan the sky +- this number of degrees.
var max_tws_range = 30;# these 2 should be determined from RCS instead.
var max_lock_range = 40;

#air scan modes:
var TRACK_WHILE_SCAN = 2;# Gives velocity, angle, azimuth and range. Multiple soft locks. Short range. Fast.
#var SINGLE_TARGET_TRACK = 4;# focus on a contact. hard lock. Good for identification. Mid range.
var RANGE_WHILE_SEARCH = 1;# Gives range/angle info. Long range. Narrow bars.
#var SITUATION_AWARENESS_MODE = 3;# submode of RWS/TWS. A contact can be followed/selected while scan still being done that can show other bleps nearby.
var VELOCITY_SEARCH = 0;# gives positive closure rate. Long range.



ActiveDiscRadar = {
# inherits from Radar
# will check range, field of view/regard, ground occlusion and FCS.
# will also scan a field. And move that scan field as appropiate for scan mode.
# do not use directly, inherit and instance it.
# fast loop
#
# Attributes:
#   contact selection(s) of type Contact
#   soft/hard lock
#   painted (is the hard lock) of type Contact
	new: func () {
		var ar = {parents: [ActiveDiscRadar, radar]};
		ar.timer          = maketimer(1, ar, func ar.loop());
		ar.lock           = NONE;# NONE, SOFT, HARD
		ar.locks          = [];
		ar.follow         = [];
		ar.vector_aicontacts_for = [];
		ar.vector_aicontacts_bleps = [];
		ar.scanMode       = RANGE_WHILE_SEARCH;
		ar.scanType       = AIR;
		ar.directionX     = 1;
		ar.patternBar     = 0;
		ar.barOffset      = 0;# offset all bars up or down.

		# these should be init in the actuaal radar:
		ar.discSpeed_dps  = 1;
		ar.fovRadius_deg  = 1;
		ar.calcLoop();
		ar.calcBars();
		ar.pattern        = [-1,1,[0]];
		ar.pattern_move   = [-1,1,[0]];
		ar.forDist_m      = 1;#current radar range setting.
		
		
		ar.posE           = ar.bars[ar.pattern[2][ar.patternBar]];
		ar.posH           = ar.pattern[0];

		ar.lockX = 1;
		ar.lockY = 1;
		ar.posHLast = ar.posH;
		ar.skipLoop = 0;

		# emesary
		ar.SliceNotification = SliceNotification.new();
		ar.ContactNotification = VectorNotification.new("ContactNotification");
		ar.ActiveDiscRadarRecipient = emesary.Recipient.new("ActiveDiscRadarRecipient");
		ar.ActiveDiscRadarRecipient.radar = ar;
		ar.ActiveDiscRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "FORNotification") {
	        	#printf("DiscRadar recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.vector_aicontacts_for = notification.vector;
	    		    me.radar.forWasScanned();
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(ar.ActiveDiscRadarRecipient);
		ar.timer.start();
    	return ar;
	},

	calcBars: func {
		# must be called each time fovRadius_deg is changed.
		# the elevation bars is stacked on top of each other. from bar -4 to bar +8.
		# override this method for radar with different number of bars.
		me.bars           = [-me.fovRadius_deg*7,-me.fovRadius_deg*5,-me.fovRadius_deg*3,-me.fovRadius_deg,me.fovRadius_deg,me.fovRadius_deg*3,me.fovRadius_deg*5,me.fovRadius_deg*7];
	},

	calcLoop: func {
		# must be called each time fovRadius_deg or discSpeed_dps is changed.
		# to simplify and for performance, we move the disc one beam width in each loop,
		# therefore the loop time must be calibrated to that.
		# If FPS is so low it cannot keep up, it will start scanning 2 beam widths at a time.
		# this also means the time to scan a bar migth vary a bit depending on framerate. Is this acceptable?
		# Maybe not, but can always build a smarter system that scan beamwidth*X, where X depend on FPS.
		me.loopSpeed      = 1/(me.discSpeed_dps/(me.fovRadius_deg*2));
		me.timer.restart(me.loopSpeed);
		#print("loop: "~me.loopSpeed);
	},

	loop: func {
		if (!me.skipLoop and me.enabled) {#skipping loop while we wait for notification from NoseRadar. (I know its synchronious now, but it might change)
			me.moveDisc();
			me.scanFOV();
			if (me.lock == HARD) {
				me.purgeLock(time_till_lose_lock);
			} else {
				me.purgeLocks(time_till_lose_lock_soft);
			}
		}
	},

	forWasScanned: func {
		# this method was originally called every time a full scan of all bars was done, now its every time we receive a new bar to scan from NoseRadar.
		#ok, lets clean up old bleps:
		me.vector_aicontacts_bleps_tmp = [];
		me.elapsed = getprop("sim/time/elapsed-sec");
		foreach(contact ; me.vector_aicontacts_bleps) {
			if (me.elapsed - contact.blepTime < time_to_keep_bleps) {
				append(me.vector_aicontacts_bleps_tmp, contact);
			}
		}
		me.vector_aicontacts_bleps = me.vector_aicontacts_bleps_tmp;
		if (size(me.follow) > 0 and !me.containsVector(me.vector_aicontacts_bleps, me.follow[0])) {
			# clean up old follow/SAM that hasn't been detected for a while.
			me.follow = [];
		}
		me.skipLoop = 0;
		me.scanFOV();#since we already have moved radar disc to new bar, we need this extra scan otherwise the disc will move and we will miss the start of the bar.
		# it also mean that as long as notifications is sent and recieved synhronious from NoseRadar, scanFov will be called twice for no reason,
		# since the first time there will be nothing to detect.
	},

	purgeLocks: func (time) {
		me.locks_tmp = [];
		me.elapsed = getprop("sim/time/elapsed-sec");
		foreach(contact ; me.locks) {
			if (me.elapsed - contact.blepTime < time and contact.isInfoExtended() == 1) {
				append(me.locks_tmp, contact);
			}
		}
		me.locks = me.locks_tmp;
		if (size(me.locks) == 0) {
			me.lock = NONE;
		}
		if (size(me.follow) > 0 and !me.containsVector(me.vector_aicontacts_bleps, me.follow[0])) {
			me.follow = [];
		}
	},

	purgeLock: func (time) {
		if (size(me.locks) == 1) {
			me.elapsed = getprop("sim/time/elapsed-sec");
			if (me.elapsed - me.locks[0].blepTime > time) {
				me.locks = [];
				me.lock = NONE;
				me.follow = [];
			} elsif (me.locks[0].getRangeDirect()*M2NM > max_lock_range) {
				me.locks = [];
				me.lock = NONE;
			}
		} elsif (size(me.locks) == 0) {
			me.lock = NONE;
		}
	},

	containsVector: func (vec, item) {
		foreach(test; vec) {
			if (test == item) {
				return TRUE;
			}
		}
		return FALSE;
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

	moveDisc: func {
		# move the FOV inside the FOR
		#me.acPitch = getprop("orientation/pitch-deg");
		me.reset = 0;
		me.step = 1;
		me.pattern_move = [me.pattern[0],me.pattern[1],me.pattern[2]];# we move on a temp pattern, so we can revert to normal scan mode, after lock/follow.
		if (size(me.follow) > 0 and me.lock != HARD) {
			# scan follows selection (SAM)
			me.pattern_move[0] = me.follow[0].getDeviationHeadingFrozen()-sam_radius;
			me.pattern_move[1] = me.follow[0].getDeviationHeadingFrozen()+sam_radius;
			if (me.pattern_move[0] < -me.forRadius_deg) {
				me.pattern_move[0] = -me.forRadius_deg;
			}
			if (me.pattern_move[1] > me.forRadius_deg) {
				me.pattern_move[1] = me.forRadius_deg;
			}
		}
		if (me.lock != HARD) {
			# Normal scan
			me.reverted = 0;
			if (getprop("sim/time/delta-sec") > me.loopSpeed*1.5) {
				# hack for slow FPS
				me.step = 2;
			}		
			me.posH_new  = me.posH+me.directionX*me.fovRadius_deg*2*me.step;
			me.polarDist = math.sqrt(me.posH_new*me.posH_new+me.posE*me.posE);
			if (me.polarDist > me.forRadius_deg or (me.directionX==1 and me.posH_new > me.pattern_move[1]) or (me.directionX==-1 and me.posH_new < me.pattern_move[0])) {
				me.patternBar +=1;
				me.checkBarValid();
				me.nextBar();
				me.skipLoop = 1;
				emesary.GlobalTransmitter.NotifyAll(me.SliceNotification.slice(me.posE-me.fovRadius_deg,me.posE+me.fovRadius_deg, me.pattern_move[0],me.pattern_move[1],me.forDist_m));
			} else {
				me.posH = me.posH_new;
			}
		} else {
			# lock scan
			me.posH_n = me.locks[0].getDeviationHeadingFrozen()+me.lockX*me.fovRadius_deg*0.5;
			me.posE_n = me.locks[0].getDeviationPitchFrozen()+me.lockY*me.fovRadius_deg*0.5;
			if (me.forRadius_deg >= math.sqrt(me.posH_n*me.posH_n+me.posE_n*me.posE_n)) {
				me.posH = me.posH_n;
				me.posE = me.posE_n;
			}
			me.lockX *= -1;
			if (me.lockX == -1) {
				me.lockY *= -1;
				me.sendLockNotification();
			}
		}
		#printf("scanning %04.1f, %04.1f", me.posH, me.posE);
	},

	sendLockNotification: func {
		# this will update the lock unless its deviation angle rate is very very high, in which case we might lose the lock.
		emesary.GlobalTransmitter.NotifyAll(me.ContactNotification.updateV(me.locks));
		#emesary.GlobalTransmitter.NotifyAll(me.SliceNotification.slice(me.locks[0].getDeviationPitchFrozen()-me.fovRadius_deg*1.5,me.locks[0].getDeviationPitchFrozen()+me.fovRadius_deg*1.5, me.locks[0].getDeviationHeadingFrozen()-me.fovRadius_deg*1.5,me.locks[0].getDeviationHeadingFrozen()+me.fovRadius_deg*1.5,me.forDist_m));
	},

	checkBarValid: func {
		if (me.patternBar > size(me.pattern_move[2])-1) {
			me.patternBar = 0;
			me.reset = 1;# not used anymore
		}
	},

	nextBar: func {
		me.directionX *= -1;
		me.reverted = 1;
		me.posE = me.bars[me.pattern_move[2][me.patternBar]]+me.barOffset*me.fovRadius_deg*2;
		if (me.directionX == 1) {
			me.posH = me.pattern_move[0]+me.fovRadius_deg;
		} else {
			me.posH = me.pattern_move[1]-me.fovRadius_deg;
		}
		me.polarDist = math.sqrt(me.posH*me.posH+me.posE*me.posE);
		if (me.polarDist > me.forRadius_deg) {
			me.posH = -math.cos(math.asin(clamp(me.posE/me.pattern_move[1],-1,1)))*me.pattern_move[1]*me.directionX+me.directionX*me.fovRadius_deg;# disc set at beginning of new bar.
			if (me.posH < me.pattern_move[0] or me.posH > me.pattern_move[1]) {
				# we are so high or low on the circle and the bar is so small that there is no room to do this bar, so we skip to next.
				me.nextBar();
			}
		}
	},

	scanFOV: func {
		#iterate:
		# check sensor field of view
		# check Terrain
		# check Doppler
		# due to FG Nasal update rate, we consider FOV square.
		# only detect 1 contact, even if more are present.
		foreach(contact ; me.vector_aicontacts_for) {
			me.dev = contact.getDeviationStored();
			me.contactPosH = me.dev[0];
			me.contactPosE = me.dev[1];
			if (me.contactPosE < me.posE+me.fovRadius_deg and me.contactPosE > me.posE-me.fovRadius_deg and (me.lock != HARD or me.forDist_m > me.dev[2])) {# since we don't get updates from NoseRadar while having lock, we need to check the range.
				# in correct elevation for detection
				me.doDouble = me.step == 2 and me.reverted == 0 and me.lock != HARD;
				if (!me.doDouble and me.contactPosH < me.posH+me.fovRadius_deg and me.contactPosH > me.posH-me.fovRadius_deg) {
					# detected
					if (me.registerBlep(contact)) {#print("detect-1 "~contact.callsign);
						break;# for AESA radar we should not break
					}
				} elsif (me.doDouble and me.directionX == 1 and me.contactPosH < me.posH+me.fovRadius_deg and me.contactPosH > me.posHLast+me.fovRadius_deg) {
					# detected
					if (me.registerBlep(contact)) {#print("detect-2 "~contact.callsign);
						break;# for AESA radar we should not break
					}
				} elsif (me.doDouble and me.directionX == -1 and me.contactPosH < me.posHLast-me.fovRadius_deg and me.contactPosH > me.posH-me.fovRadius_deg) {
					# detected
					if (me.registerBlep(contact)) {#print("detect-2 "~contact.callsign);
						break;# for AESA radar we should not break
					}
				}
			}
		}
		me.posHLast = me.posH;
	},

	registerBlep: func (contact) {
		me.strength = me.targetRCSSignal(contact.getAcCoord(), me.dev[3], contact.model, contact.getHeadingFrozen(1), contact.getPitchFrozen(1), contact.getRollFrozen(1));
		#TODO: check Terrain, Doppler here.
		if (me.strength > me.dev[2]) {
			me.extInfo = (me.scanMode == TRACK_WHILE_SCAN and me.dev[2] < max_tws_range*NM2M and size(me.locks)<max_soft_locks) or me.lock == HARD;
			contact.blep(getprop("sim/time/elapsed-sec"), me.extInfo, me.strength, me.lock==HARD);
			if (me.lock != HARD) {
				if (!me.containsVector(me.vector_aicontacts_bleps, contact)) {
					append(me.vector_aicontacts_bleps, contact);
				}
				if (me.extInfo and !me.containsVector(me.locks, contact)) {
					append(me.locks, contact);
					me.lock = SOFT;
				}
			}
			return 1;
		}
		return 0;
	},

	targetRCSSignal: func(aircraftCoord, targetCoord, targetModel, targetHeading, targetPitch, targetRoll, myRadarDistance_m = 74000, myRadarStrength_rcs = 3.2) {
		#
		# test method. Belongs in rcs.nas.
		#
	    #print(targetModel);
	    me.target_front_rcs = nil;
	    if ( contains(rcs.rcs_database,targetModel) ) {
	        me.target_front_rcs = rcs.rcs_database[targetModel];
	    } else {
	        #return 1;
	        me.target_front_rcs = 5;#rcs.rcs_database["default"];# hardcode defaults to 5 to test with KXTA target scenario. TODO: change.
	    }
	    me.target_rcs = rcs.getRCS(targetCoord, targetHeading, targetPitch, targetRoll, aircraftCoord, me.target_front_rcs);

	    # standard formula
	    return myRadarDistance_m/math.pow(myRadarStrength_rcs/me.target_rcs, 1/4);
	},
};



var RWR = {
# inherits from Radar
# will check radar/transponder and ground occlusion.
# will sort according to threat level
# will detect launches (MLW) or (active) incoming missiles (MAW)
# loop (0.5 sec)
	new: func () {
		var rr = {parents: [RWR, radar]};

		rr.vector_aicontacts = [];
		rr.vector_aicontacts_threats = [];
		#rr.timer          = maketimer(2, rr, func rr.scan());

		rr.RWRRecipient = emesary.Recipient.new("RWRRecipient");
		rr.RWRRecipient.radar = rr;
		rr.RWRRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "OmniNotification") {
	        	#printf("RWR recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.vector_aicontacts = notification.vector;
	    		    me.radar.scan();
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(rr.RWRRecipient);
		#nr.FORNotification = VectorNotification.new("FORNotification");
		#nr.FORNotification.updateV(nr.vector_aicontacts_for);
		#rr.timer.start();
		return rr;
	},

	scan: func {
		# sort in threat?
		# run by notification
		# mock up code, ultra simple threat index, is just here cause rwr have special needs:
		# 1) It has almost no range restriction
		# 2) Its omnidirectional
		# 3) It might have to update fast (like 0.25 secs)
		# 4) To build a proper threat index it needs at least these properties read:
		#       model type
		#       class (AIR/SURFACE/MARINE)
		#       lock on myself
		#       missile launch
		#       transponder on/off
		#       bearing and heading
		#       IFF info
		#       ECM
		#       radar on/off
		me.vector_aicontacts_threats = [];
		foreach(contact ; me.vector_aicontacts) {
			me.t = contact.getThreatStored();#[bearing,heading,coord,transponder,radar,devBearing,dist_nm]
			#me.threatInv = contact.getRangeDirect()*M2NM;
			#me.threatInv = 55-contact.getSpeed()*0.1;
			me.threatInv = me.t[6];# this is not serious, just testing code
			append(me.vector_aicontacts_threats, [contact,me.threatInv]);# how about a setThreat on contact instead of this crap?
		}
	},
};




ExampleRadar = {
# test radar
	new: func () {
		var vr = ActiveDiscRadar.new();
		append(vr.parents, ExampleRadar);
		vr.discSpeed_dps  = 120;
		vr.fovRadius_deg  = 3.6;
		vr.calcLoop();
		vr.calcBars();
		vr.pattern        = [-60,60,[1,2,3,4,5,6]];#6/8 bars
		vr.forDist_m      = 15000;#range setting
		vr.forRadius_deg  = 60;
		vr.posE           = vr.bars[vr.pattern[2][vr.patternBar]];
		vr.posH           = vr.pattern[0];
    	return vr;
	},

	more: func {
		#test method
		me.forDist_m      *= 2;
	},

	less: func {
		#test method
		me.forDist_m      *= 0.5;
	},

	rwsHigh: func {
		#test method
		me.pattern        = [-60,60,[4,5,6,7]];#4/8 bars
		me.directionX     = 1;
		me.patternBar     = 0;
		me.posE           = me.bars[me.pattern[2][me.patternBar]];
		me.posH           = me.pattern[0];
		me.scanMode       = RANGE_WHILE_SEARCH;
		me.discSpeed_dps  = 120;
		me.lock = NONE;
		me.locks = [];
		me.calcLoop();
		me.follow = [];
	},

	rws120: func {
		#test method
		me.pattern        = [-60,60,[1,2,3,4,5,6]];#6/8 bars
		me.directionX     = 1;
		me.patternBar     = 0;
		me.posE           = me.bars[me.pattern[2][me.patternBar]];
		me.posH           = me.pattern[0];
		me.scanMode       = RANGE_WHILE_SEARCH;
		me.discSpeed_dps  = 120;
		me.lock = NONE;
		me.locks = [];
		me.calcLoop();
		#me.follow = [];
	},

	sam: func {
		#test method
		if (size(me.follow)>0 and me.lock != HARD) {
			# toggle SAM off
			me.follow = [];
		} elsif(me.lock == HARD) {
			if (size(me.locks) > 0) {
				me.follow = [me.locks[0]];
				if(me.scanMode == TRACK_WHILE_SCAN) {
					me.lock = SOFT;
				} else {
					me.lock = NONE;
					me.locks = [];
				}				
			}
		} elsif(me.scanMode == RANGE_WHILE_SEARCH) {
			if (size(me.vector_aicontacts_bleps) > 0) {
				me.lock = NONE;
				me.locks = [];
				me.follow = [me.vector_aicontacts_bleps[0]];
			}
		} elsif(me.scanMode == TRACK_WHILE_SCAN) {
			if (size(me.locks) > 0) {
				me.lock = SOFT;
				me.follow = [me.locks[0]];
			}
		}		 
	},

	next: func {
		if (size(me.follow) == 1 and size(me.locks) > 0 and me.lock != HARD) {
			me.index = me.vectorIndex(me.locks, me.follow[0]);
			if (me.index == -1) {
				me.follow = [me.locks[0]];
			} else {
				if (me.index+1 > size(me.locks)-1) {
					me.follow = [];
				} else {
					me.follow = [me.locks[me.index+1]];
				}
			}
		} elsif (size(me.follow) == 1 and size(me.vector_aicontacts_bleps) > 0) {
			me.index = me.vectorIndex(me.vector_aicontacts_bleps, me.follow[0]);
			if (me.index == -1) {
				me.follow = [me.vector_aicontacts_bleps[0]];
			} else {
				if (me.index+1 > size(me.vector_aicontacts_bleps)-1) {
					me.follow = [];
				} else {
					me.follow = [me.vector_aicontacts_bleps[me.index+1]];
				}
			}
		}
	},

	tws15: func {
		#test method
		me.pattern        = [-7.5,7.5,[1,2,3,4,5,6]];#6/8 bars
		me.directionX     = 1;
		me.patternBar     = 0;
		me.posE           = me.bars[me.pattern[2][me.patternBar]];
		me.posH           = me.pattern[0];
		me.scanMode       = TRACK_WHILE_SCAN;
		me.discSpeed_dps  = 60;
		me.calcLoop();
		me.lock = NONE;
		#me.follow = [];
	},

	tws30: func {
		#test method
		me.pattern        = [-15,15,[2,3,4,5]];#4/8 bars
		me.directionX     = 1;
		me.patternBar     = 0;
		me.posE           = me.bars[me.pattern[2][me.patternBar]];
		me.posH           = me.pattern[0];
		me.scanMode       = TRACK_WHILE_SCAN;
		me.discSpeed_dps  = 60;
		me.calcLoop();
		me.lock = NONE;
		#me.follow = [];
	},

	tws60: func {
		#test method
		me.pattern        = [-30,30,[3,4]];#2/8 bars
		me.directionX     = 1;
		me.patternBar     = 0;
		me.posE           = me.bars[me.pattern[2][me.patternBar]];
		me.posH           = me.pattern[0];
		me.scanMode       = TRACK_WHILE_SCAN;
		me.discSpeed_dps  = 60;
		me.calcLoop();
		me.lock = NONE;
		#me.follow = [];
	},

	b1: func {
		me.pattern[2] = [4];
	},

	b2: func {
		me.pattern[2] = [3,4];
	},

	b4: func {
		me.pattern[2] = [2,3,4,5];
	},

	b6: func {
		me.pattern[2] = [1,2,3,4,5,6];
	},

	b8: func {
		me.pattern[2] = [0,1,2,3,4,5,6,7];
	},

	a2: func {
		me.pattern[0] = -15;
		me.pattern[1] =  15;
	},

	a3: func {
		me.pattern[0] = -30;
		me.pattern[1] =  30;
	},

	a4: func {
		me.pattern[0] = -60;
		me.pattern[1] =  60;
	},

	a1: func {
		me.pattern[0] = -7.5;
		me.pattern[1] =  7.5;
	},

	left: func {
		#test method
		var zero = me.pattern[0]-15;
		if (zero >= -me.forRadius_deg) {
			me.pattern[0] = zero;
			me.pattern[1] = me.pattern[1]-15;
		}
	},

	right: func {
		#test method
		var one = me.pattern[1]+15;
		if (one <= me.forRadius_deg) {
			me.pattern[1] = one;
			me.pattern[0] = me.pattern[0]+15;
		}
	},

	up: func {
		#test method
		me.barOffset += 1;
		if (me.barOffset > 4) {
			me.barOffset = 4;
		}
	},

	down: func {
		#test method
		me.barOffset -= 1;
		if (me.barOffset < -4) {
			me.barOffset = -4;
		}
	},

	level: func {
		#test method
		me.barOffset = 0;
	},

	lockRandom: func {
		#test method

		# hard lock
		if (size(me.follow)>0) {
			# choose same lock as being followed with SAM
			if (me.follow[0].getRangeDirectFrozen() < max_lock_range*NM2M) {
				me.locks = [me.follow[0]];
				me.lock = HARD;
				me.vector_aicontacts_for = [me.follow[0]];
				#me.devLock = lck.getDeviation();#since we have no cursor we need to cheat a bit here.
				#me.posH = me.devLock[0];
				#me.posE = me.devLock[1];
				me.sendLockNotificationInit();
				#me.scanFOV();# this call migth not be neccesary..
			}
		} elsif (size(me.vector_aicontacts_bleps)>0) {
			# random chosen lock in range
			foreach (lck ; me.vector_aicontacts_bleps) {
				if (lck.getRangeDirectFrozen() < max_lock_range*NM2M) {
					me.locks = [lck];
					me.follow = [lck];
					me.lock = HARD;
					me.vector_aicontacts_for = [lck];
					#me.devLock = lck.getDeviation();
					#me.posH = me.devLock[0];
					#me.posE = me.devLock[1];
					me.sendLockNotificationInit();
					#me.scanFOV();# this call migth not be neccesary..
					break;
				}
			}
		}
	},

	sendLockNotificationInit: func {
		# this will update the lock if it hasn't moved too much since we last detected it.
		emesary.GlobalTransmitter.NotifyAll(me.SliceNotification.slice(me.locks[0].getDeviationPitchFrozen()-me.fovRadius_deg*5,me.locks[0].getDeviationPitchFrozen()+me.fovRadius_deg*5, me.locks[0].getDeviationHeadingFrozen()-me.fovRadius_deg*5,me.locks[0].getDeviationHeadingFrozen()+me.fovRadius_deg*5,me.forDist_m));
	},
};




###LinkRadar:
# inherits from Radar, represents a fighter-link/link16.
# Get contact name from other aircraft, and finds local RadarControl for it.
# no loop. emesary listener on aircraft for link.
#
# Attributes:
#   contact selection(s) of type LinkContact
#   imaginary hard/soft lock
#   link list of contacts of type LinkContact




#troubles:
# rescan of ai tree, how to equal same aircraft with new name (COMPARE: callsign, sign, name, model-name)
# doppler only in a2a mode
# 

# TODO: tons of features and tons of different designs to try. Like scanning a 360 azimuth without reversing direction when bar finished.




AIToNasal.new();
var nose = NoseRadar.new(15000,60,5);
var omni = OmniRadar.new(0.25);
var terrain = TerrainChecker.new(0.10);
var exampleRadar = ExampleRadar.new();
var exampleRWR   = RWR.new();

