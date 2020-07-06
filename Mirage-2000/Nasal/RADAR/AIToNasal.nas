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



AIToNasal = {
# convert AI property tree to Nasal vector
# will send notification when some is updated (emesary?)
# listeners for adding/removing AI nodes.
# very slow loop (10 secs)
# updates AIContacts, does not replace them. (yes will make slower, but solves many issues. Can divide workload over 2 frames.)
#
# Attributes:
#   fullContactVector of AIContacts
#   index keys for fast locating: callsign, model-path??
	new: func {
		me.prop_AIModels = props.globals.getNode("ai/models");
		me.vector_aicontacts = [];
		me.callInProgress = 0;
		me.updateInProgress = 0;
		me.lookupCallsign = {};
		me.AINotification = VectorNotification.new("AINotification");
		me.AINotification.updateV(me.vector_aicontacts);

		setlistener("/ai/models/model-added", func me.callReadTree());
		setlistener("/ai/models/model-removed", func me.callReadTree());
		me.loop = maketimer(30, me, func me.callReadTree());
		me.loop.start();
	},

	callReadTree: func {
		#print("NR: listenr called");
		if (!me.callInProgress) {
			# multiple fast calls migth be done to this method, by delaying the propagation we don't have to call readTree for each call.
			me.callInProgress = 1;
			settimer(func me.readTree(), 0.15);
		}
	},

	readTree: func {
		#print("NR: readtree called");
		me.callInProgress = 0;

		me.vector_raw = me.prop_AIModels.getChildren();
		me.lookupCallsignRaw = {};

		foreach (me.prop_ai;me.vector_raw) {
			me.prop_valid = me.prop_ai.getNode("valid");
			if (me.prop_valid == nil or !me.prop_valid.getValue() or me.prop_ai.getNode("impact") != nil) {
				# its either not a valid entity or its a impact report.
                continue;
            }
            me.type = AIR;

            # find short model xml name: (better to do here, even though its slow) [In viggen its placed inside the property tree, which leads to too much code to update it when tree changes]
            me.name_prop = me.prop_ai.getName();
            me.model = me.prop_ai.getNode("sim/model/path");
            if (me.model != nil) {
              	me.path = me.model.getValue();

              	me.model = split(".", split("/", me.path)[-1])[0];
              	me.model = me.remove_suffix(me.model, "-model");
              	me.model = me.remove_suffix(me.model, "-anim");
            } else {
            	me.model = "";
            }

            # position type
            me.pos_type = nil;
            me.pos = me.prop_ai.getNode("position");
		    me.x = me.pos.getNode("global-x");
		    me.y = me.pos.getNode("global-y");
		    me.z = me.pos.getNode("global-z");
		    if(me.x == nil or me.y == nil or me.z == nil) {
		    	me.alt = me.pos.getNode("altitude-ft");
		    	me.lat = me.pos.getNode("latitude-deg");
		    	me.lon = me.pos.getNode("longitude-deg");	
		    	if(me.alt == nil or me.lat == nil or me.lon == nil) {
			      	continue;
				}
			    me.pos_type = GPS;
			    me.aircraftPos = geo.Coord.new().set_latlon(me.lat.getValue(), me.lon.getValue(), me.alt.getValue()*FT2M);
          me.alt = me.aircraftPos.alt();
		    } else {
		    	me.pos_type = GEO;
		    	me.aircraftPos = geo.Coord.new().set_xyz(me.x.getValue(), me.y.getValue(), me.z.getValue());
		    	me.alt = me.aircraftPos.alt();
		    }
		    
		    me.prop_speed = me.prop_ai.getNode("velocities/true-airspeed-kt");
		    me.prop_ord   = me.prop_ai.getNode("missile");

		    # determine type. Unsure if this should be done here, or in Radar.
		    #   For here: PRO better performance. CON might change in between calls to reread tree, and dont have doppler to determine air from ground.
            if (me.name_prop == "carrier" or me.name_prop == "ship") {
            	me.type = MARINE;
            } elsif (me.name_prop == "groundvehicle") {
            	me.type = SURFACE;
            } elsif (me.alt < 3.0) {
            	me.type = MARINE;
            } elsif (me.model != nil and contains(knownShips, me.model)) {
				me.type = MARINE;
            } elsif (me.prop_ord != nil) {
            	me.type = ORDNANCE;
            } elsif (me.prop_speed != nil and me.prop_speed.getValue() < 75) {
            	me.type = nil;# to be determined later by doppler in Radar
            }
            
            #append(me.vector_aicontacts_raw, me.aicontact);
            me.callsign = me.prop_ai.getNode("callsign");
            if (me.callsign == nil) {
            	me.callsign = "";
            } else {
            	me.callsign = me.callsign.getValue();
            }

            me.aicontact = AIContact.new(me.prop_ai, me.type, me.model, me.callsign, me.pos_type);#AIcontact needs 2 calls to work. new() [cheap] and init() [expensive]. Only new is called here, updateVector will do init().

            me.signLookup = me.lookupCallsignRaw[me.callsign];
            if (me.signLookup == nil) {
            	me.signLookup = [me.aicontact];
            } else {
            	append(me.signLookup, me.aicontact);
            }
            me.lookupCallsignRaw[me.callsign] = me.signLookup;
		}

		if (!me.updateInProgress) {
			me.updateInProgress = 1;
			settimer(func me.updateVector(), 0);
		}
	},

	remove_suffix: func(s, x) {
	      me.len = size(x);
	      if (substr(s, -me.len) == x)
	          return substr(s, 0, size(s) - me.len);
	      return s;
	},

	updateVector: func {
		# lots of iterating in this method. But still fast since its done without propertytree.
		me.updateInProgress = 0;
		me.callsignKeys = keys(me.lookupCallsignRaw);
		me.lookupCallsignNew = {};
		me.vector_aicontacts = [];
		foreach(me.callsignKey; me.callsignKeys) {
			me.callsignsRaw = me.lookupCallsignRaw[me.callsignKey];
			me.callsigns    = me.lookupCallsign[me.callsignKey];
			if (me.callsigns != nil) {
				foreach(me.newContact; me.callsignsRaw) {
					me.oldContact = me.containsVectorContact(me.callsigns, me.newContact);
					if (me.oldContact != nil) {
						me.oldContact.update(me.newContact);
						me.newContact = me.oldContact;
					}
					append(me.vector_aicontacts, me.newContact);
					if (me.lookupCallsignNew[me.callsignKey]==nil) {
						me.lookupCallsignNew[me.callsignKey] = [me.newContact];
					} else {
						append(me.lookupCallsignNew[me.callsignKey], me.newContact);
					}
					me.newContact.init();
				}
			} else {
				me.lookupCallsignNew[me.callsignKey] = me.callsignsRaw;
				foreach(me.newContact; me.callsignsRaw) {
					append(me.vector_aicontacts, me.newContact);
					me.newContact.init();
				}
			}
		}
		me.lookupCallsign = me.lookupCallsignNew;
		#print("NR: update called "~size(me.vector_aicontacts));
		emesary.GlobalTransmitter.NotifyAll(me.AINotification.updateV(me.vector_aicontacts));
	},

	containsVectorContact: func (vec, item) {
		foreach(test; vec) {
			if (test.equals(item)) {
				return test;
			}
		}
		return nil;
	},
};


