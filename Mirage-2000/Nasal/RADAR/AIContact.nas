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




#FROM missile-code.nas
#It should be implemented here : To DO
# Contact should implement the following interface:
#
#done get_type()      - (AIR, MARINE, SURFACE or ORDNANCE)
#done getUnique()     - Used when comparing 2 targets to each other and determining if they are the same target.
#done isValid()       - If this target is valid
#done getElevation()
#done get_bearing()
#done get_Roll()
#done get_Callsign()
#done get_range()
#done get_Coord()
#done get_Latitude()
#done get_Longitude()
#done get_altitude()
#done get_Pitch()
#done get_Speed()
#done get_heading()
#done get_uBody()
#done get_vBody()
#done get_wBody()
#done getFlareNode()  - Used for flares.
#done getChaffNode()  - Used for chaff.
#done isPainted()     - Tells if this target is still being radar tracked by the launch platform, only used in semi-radar guided missiles.
#done isLaserPainted()     - Tells if this target is still being tracked by the launch platform, only used by laser guided ordnance.
#done isRadiating(coord) - Tell if anti-radiation missile is hit by radiation from target. coord is the weapon position.
#done isVirtual()     - Tells if the target is just a position, and should not be considered for damage.
# get_display()

Contact = {
# Attributes:
	getCoord: func {
	   	return geo.Coord.new();
	},
};






AIContact = {
# Attributes:
#   replaceNode() [in AI tree]
	new: func (prop, type, model, callsign, pos_type) {
		var c = {parents: [AIContact, Contact]};

		# general:
		c.prop     = prop;
		c.type     = type;
		c.model    = model;
		c.callsign = callsign;
		c.pos_type = pos_type;
		c.needInit = 1;
		c.azi      = 0;
		c.visible = 1;

		# active radar:
		c.blepTime = 0;
		c.coordFrozen = geo.Coord.new();

    	return c;
	},

	init: func {
		if (me.needInit == 0) {
			# init is expensive. Avoid it if not needed.
			return;
		}
		me.needInit = 0;
		# read all properties and store them for fast lookup.
    me.valid = me.prop.getNode("valid");
		me.pos = me.prop.getNode("position");
		me.ori = me.prop.getNode("orientation");
		me.x = me.pos.getNode("global-x");
    	me.y = me.pos.getNode("global-y");
    	me.z = me.pos.getNode("global-z");
    	me.alt = me.pos.getNode("altitude-ft");
    	me.lat = me.pos.getNode("latitude-deg");
    	me.lon = me.pos.getNode("longitude-deg");
    	me.heading = me.ori.getNode("true-heading-deg");
    	me.pitch = me.ori.getNode("pitch-deg");
    	me.roll = me.ori.getNode("roll-deg");
    	me.acHeading = props.globals.getNode("orientation/heading-deg");
    	me.acPitch = props.globals.getNode("orientation/pitch-deg");
    	me.acRoll = props.globals.getNode("orientation/roll-deg");
    	me.aalt = props.globals.getNode("position/altitude-ft");
    	me.alat = props.globals.getNode("position/latitude-deg");
    	me.alon = props.globals.getNode("position/longitude-deg");
    	me.speed = me.prop.getNode("velocities/true-airspeed-kt");
    	me.tp = me.pos.getNode("instrumentation/transponder/inputs/mode");
    	me.rdr = me.pos.getNode("sim/multiplay/generic/int[2]");
      me.ubody = me.speed.getNode("uBody-fps");
      me.vbody = me.speed.getNode("vBody-fps");
      me.wbody = me.speed.getNode("wBody-fps");
      me.aubody = props.globals.getNode("velocities/uBody-fps");
      me.avbody = props.globals.getNode("velocities/vBody-fps");
      me.awbody = props.globals.getNode("velocities/wBody-fps");
      me.flareNode = me.prop.getNode("rotors/main/blade[3]/flap-deg");
      me.chaffNode = me.prop.getNode("rotors/main/blade[3]/position-deg");
      me.ispainted = 0;
	},

	update: func (newC) {
		if (me.prop.getPath() != newC.prop.getPath()) {
			me.prop = newC.prop;
			me.needInit = 1;
		}
		me.type = newC.type;
		me.model = newC.model;
		me.callsign = newC.callsign;
	},

	equals: func (item) {
		if (item.prop.getName() == me.prop.getName() and item.type == me.type and item.model == me.model and item.callsign == me.callsign) {
			return TRUE;
		}
		return FALSE;
	},

	getCoord: func {
		if (me.pos_type = GEO) {
	    	me.coord = geo.Coord.new().set_xyz(me.x.getValue(), me.y.getValue(), me.z.getValue());
	    	return me.coord;
	    } else {
	    	if(me.alt == nil or me.lat == nil or me.lon == nil) {
		      	return geo.Coord.new();
		    }
		    me.coord = geo.Coord.new().set_latlon(me.lat.getValue(), me.lon.getValue(), me.alt.getValue()*FT2M);
		    return me.coord;
	    }	
	},

	getAcCoord: func {
		# this is much faster than calling geo.aircraft_position(). Shouldn't be in this class though, but since its prototype code..
		me.accoord = geo.Coord.new().set_latlon(me.alat.getValue(), me.alon.getValue(), me.aalt.getValue()*FT2M);
	    return me.accoord;
	},

	getDeviationPitch: func {
		me.getCoord();
		me.getAcCoord();
		me.pitched = vector.Math.getPitch(me.accoord, me.coord);
		return me.pitched - me.acPitch.getValue();
	},

	getDeviationHeading: func {
		me.getCoord();
		me.getAcCoord();
		return geo.normdeg180(me.accoord.course_to(me.coord)-me.acHeading.getValue());
	},

	getRangeDirect: func {# meters
		me.getCoord();
		me.getAcCoord();
		return me.accoord.direct_distance_to(me.coord);
	},

	getPitch: func {
		if (me.pitch == nil) {
			return 0;
		}
		return me.pitch.getValue();
	},

	getRoll: func {
		if (me.roll == nil) {
			return 0;
		}
		return me.roll.getValue();
	},

	getHeading: func {
		if (me.heading == nil) {
			return 0;
		}
		return me.heading.getValue();
	},

	getSpeed: func {
		if (me.speed == nil) {
			return 0;
		}
		return me.speed.getValue();
	},

	getBearing: func {
		me.getAcCoord();
		return me.accoord.course_to(me.getCoord());
	},

	getDeviation: func {
		# optimized method that return both heading and pitch deviation, to limit property calls
		# [bearingDev, elevationDev, distDirect, coord]
		me.getCoord();
		me.getAcCoord();
		return [geo.normdeg180(me.accoord.course_to(me.coord)-me.acHeading.getValue()), vector.Math.getPitch(me.accoord, me.coord) - me.acPitch.getValue(),me.accoord.direct_distance_to(me.coord),me.coord];
	},

	isTransponderEnable: func {
		if (me.tp == nil) {
			return 1;
		}
		return me.tp.getValue() != 0;
	},

	isRadarEnable: func {
		if (me.rdr == nil) {
			return 1;
		}
		return me.rdr.getValue();
	},

	isVisible: func {#terrain check
		return me.visible;
	},

	setVisible: func (vis) {
		me.visible = vis;
	},

	storeDeviation: func (dev) {
		# [bearingDev, elevationDev, distDirect, coord, heading, pitch, roll]
		# should really be a hash instead of vector
		me.devStored = dev;
	},
	
	getDeviationStored: func {
		return me.devStored;
	},

	storeThreat: func (threat) {
		# [bearing,heading,coord,transponder,radar,devheading]
		# should really be a hash instead of vector
		me.threatStored = threat;
	},
	
	getThreatStored: func {
		return me.threatStored;
	},

	blep: func (time, azimuth, strength, lock) {
		me.blepTime = time;
		#me.headingFrozen = me.getHeading();
		me.azi = azimuth;# If azimuth is available (only lock and TWS gives it)
		me.strength = strength;#rcs
		#if (lock) {
		#	me.d = me.getDeviation();
		#	me.storeDeviation([me.d[0], me.d[1], me.d[2], me.coord, me.getHeading(), me.getPitch(), me.getRoll()]);
		#}
		me.setPainted(lock);
		me.coordFrozen = me.devStored[3]; #me.getCoord(); this is just cause Im am too lazy to change methods.
	},

	# in the radars, only call methods below this line:

	isInfoExtended: func {
		# If this contact is either locked or picked up by TWS (at medium range), return true.
		#
		# extended means the following should be available to display in cockpit: (beside the deviation angles and range)
		# heading, velocity, pitch
		#
		return me.azi;
	},

	getDeviationPitchFrozen: func {
		me.getAcCoord();
		me.pitched = vector.Math.getPitch(me.accoord, me.coordFrozen);
		return me.pitched - me.acPitch.getValue();
		#return me.devStored[1];
	},

	getDeviationHeadingFrozen: func {#is really bearing, should be renamed.
		me.getAcCoord();
		return me.accoord.course_to(me.coordFrozen)-me.acHeading.getValue();
		#return me.devStored[0];
	},

	getHeadingFrozen: func (override=0) {
		if (me.azi or override) {
			#return me.headingFrozen;
			return me.devStored[4];
		} else {
			return nil;
		}
	},

	getPitchFrozen: func (override=0) {
		if (me.azi or override) {
			#return me.headingFrozen;
			return me.devStored[5];
		} else {
			return nil;
		}
	},

	getRollFrozen: func (override=0) {
		if (me.azi or override) {
			#return me.headingFrozen;
			return me.devStored[6];
		} else {
			return nil;
		}
	},

	getRangeDirectFrozen: func {# meters
		me.getAcCoord();
		return me.accoord.direct_distance_to(me.coordFrozen);
		#return me.devStored[2];
	},

	getRangeFrozen: func {# meters
		me.getAcCoord();
		return me.accoord.distance_to(me.coordFrozen);
		#return me.devStored[3];
	},
  get_type:func(){
    return me.type;
  },
  isValid:func(){
    return me.valid.getValue();
  },
  getElevation:func(){
    return me.devStored[1];
  },
  get_bearing:func(){
    return me.devStored[0];
  },
  get_Roll:func(){
    return me.getRoll();
  },
  get_Callsign:func(){
    return me.callsign;
  },
  get_range:func(){ #in nm
    return me.getRangeDirectFrozen()*M2NM;
  },
  get_Coord:func(){
    return me.getCoord();
  },
  get_Pitch:func(){
    return me.getPitch();
  },
  get_Speed:func(){
    return me.getSpeed();
  },
  get_heading:func(){
    return me.devStored[4];
  },
  get_uBody: func {
    var body = nil;
    if (me.ubody != nil) {
      body = me.ubody.getValue();
    }
    if(body == nil) {
      body = me.get_Speed()*KT2FPS;
    }
    return body;
  },    
  get_vBody: func {
    var body = nil;
    if (me.ubody != nil) {
      body = me.vbody.getValue();
    }
    if(body == nil) {
      body = 0;
    }
    return body;
  },    
  get_wBody: func {
    var body = nil;
    if (me.ubody != nil) {
      body = me.wbody.getValue();
    }
    if(body == nil) {
      body = 0;
    }
    return body;
  },
  getFlareNode: func(){
    return me.flareNode;
  },
  getChaffNode: func(){
    return me.chaffNode;
  },
  setPainted: func(mypainting){
    if(mypainting == radar.HARD){
      me.ispainted = mypainting;
    }
  },
  isPainted: func() {
      return me.ispainted;            # Shinobi this is if laser/lock is still on it. Used for laser and semi-radar guided missiles/bombs.
  },
  isLaserPainted: func() {
      return me.ispainted; 
  },
  setVirtual: func (virt) {
      me.virtual = virt;
  },
  isVirtual: func(){
    if(me.get_Callsign() == "GROUND_TARGET"){return 1;}else{return 0;}
  },
  isRadiating: func (coord) {
    me.rn = me.get_range();
    if (me.get_model() != "buk-m2" and me.get_model() != "missile_frigate" or me.get_type()== armament.MARINE) {
        me.bearingR = coord.course_to(me.get_Coord());
        me.headingR = me.get_heading();
        me.inv_bearingR =  me.bearingR+180;
        me.deviationRd = me.inv_bearingR - me.headingR;
    } else {
        me.deviationRd = 0;
    }
    me.rdrAct = me.propNode.getNode("sim/multiplay/generic/int[2]");
    if (me.rn < 70 and ((me.rdrAct != nil and me.rdrAct.getValue()!=1) or me.rdrAct == nil) and math.abs(geo.normdeg180(me.deviationRd)) < 60) {
        # our radar is active and pointed at coord.
        #print("Is Radiating");
        return 1;
    }
    return 0;
    print("Is Not Radiating");
  },
  get_Latitude:func(){
    return me.coord.lat();
  },
  get_Longitude:func(){
    return me.coord.lon();
  },
  get_altitude:func(){
    return me.coord.alt()* M2FT;
  },

  get_closure_speed:func(){
	me.getCoord();
	me.getAcCoord();
	
    # Compute the closing speed of the target to the aircraft position.
    #  Get the deviation.
    me.dev = [geo.normdeg180(me.coord.course_to(me.accoord) - me.getHeading()), 
              vector.Math.getPitch(me.coord, me.accoord) - me.pitch.getValue()];
    
    #  Create a matrix to rotate the support vector towards the plane in the unrolled uvw target referential.
    me.rotation = vector.Math.pitchMatrix(me.dev[1]);
    me.rotation = vector.Math.multiplyMatrices(vector.Math.yawMatrix(me.dev[0]), me.rotation);
    me.uvwTarget = vector.Math.multiplyMatrixWithVector(me.rotation, [1, 0, 0]);

    #  Get the uvw speeds and un-roll them.
    me.uvwBody = [me.get_uBody(), me.get_vBody(), me.get_wBody()];
    me.rotation = vector.Math.rollMatrix(me.get_Roll());
    me.uvwBody = vector.Math.multiplyMatrixWithVector(me.rotation, me.uvwBody);
    
    #  Project the velocity vector on the aircraft vector.
    me.cloSpeed = vector.Math.orthogonalProjection(me.uvwBody, me.uvwTarget);
    
    
    # Compute the closing speed of the aircraft to the target position.
    #  Get the deviation.
    me.dev = [geo.normdeg180(me.accoord.course_to(me.coord) - me.acHeading.getValue()),
              vector.Math.getPitch(me.accoord, me.coord) - me.acPitch.getValue()];

    #  Create a matrix to rotate the support vector towards the target in the unrolled uvw plane referential.
    me.rotation = vector.Math.pitchMatrix(me.dev[1]);
    me.rotation = vector.Math.multiplyMatrices(vector.Math.yawMatrix(me.dev[0]), me.rotation);    
    me.uvwTarget = vector.Math.multiplyMatrixWithVector(me.rotation, [1, 0, 0]);
    
    #  Get the uvw speeds and un-roll them.
    me.uvwBody = [me.aubody.getValue(), me.avbody.getValue(), me.awbody.getValue()];
    me.rotation = vector.Math.rollMatrix(me.acRoll.getValue());
    me.uvwBody = vector.Math.multiplyMatrixWithVector(me.rotation, me.uvwBody);
    
    #  Project the velocity vector on the target vector.
    me.cloSpeed += vector.Math.orthogonalProjection(me.uvwBody, me.uvwTarget);
    
    
    # Convert to kts.
    return me.cloSpeed * FPS2KT;
  }
};




