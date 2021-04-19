print("*** LOADING ground-targeting.nas ... ***");
################################################################################
#
#                     m2005-5's ADDING SNIPED TARGET
#
################################################################################

var FALSE = 0;
var TRUE = 1;

var mySnipedTarget = nil;
var Mp = props.globals.getNode("ai/models");
var MyActualview = props.globals.getNode("/sim/current-view/view-number");

var SNIPED_TARGET = "SNIPED_";

var AIM_GUIDANCE_LASER = "laser";
var AIM_GUIDANCE_GPS = "gps";
var EXOCET = "exocet"; # must be the same as short-name in payload.xml

var TGT_DESIGNATION_MODE_RADAR = 0;
var TGT_DESIGNATION_MODE_LASER = 1;
var TGT_DESIGNATION_MODE_GPS = 2;
var targetDesignationMode = TGT_DESIGNATION_MODE_RADAR;

var toggleTargetDesignationMode = func {
	targetDesignationMode += 1;
	if (targetDesignationMode > TGT_DESIGNATION_MODE_GPS) {
		targetDesignationMode = TGT_DESIGNATION_MODE_RADAR;
	}
	if (targetDesignationMode == TGT_DESIGNATION_MODE_LASER) {
		setprop("controls/armament/laser-arm-dmd", 1);
	} else {
		setprop("controls/armament/laser-arm-dmd", 0);
	}
}

# The function that create the sniped target object when the dialog box is pressed
var createSnipedTarget = func() {
	var is_new = TRUE;
	if (mySnipedTarget == nil){
		screen.log.write("Creating sniped target can take time and temp. switch view ...");
		mySnipedTarget = SnipedTarget.new();
		mySnipedTarget.init();
	} else {
		screen.log.write("Updating sniped target can take time and temp. switch view ...");
		mySnipedTarget.update();
		is_new = FALSE;
	}

	if (geo.elevation(mySnipedTarget.lat.getValue(), mySnipedTarget.long.getValue(),10000) == nil) {
		var oldView = viewSnipedTarget(mySnipedTarget);
		var timer = maketimer(10,func(){
			setprop("/sim/current-view/view-number", oldView);
		});
		timer.singleShot = 1; # timer will only be run once
		timer.start();
	}
	if (is_new == TRUE) {
		setprop("ai/models/model-added", mySnipedTarget.ai.getPath());
	}
	screen.log.write("... done");
}

var focusFLIROnSnipedTarget = func() {
	if (mySnipedTarget != nil) {
		mirage2000.flir_updater.click_coord_cam = mySnipedTarget.coord;
	}
}

var designateSnipedTarget = func() {
	if (mySnipedTarget != nil) {
		var selectedWeapon = pylons.fcs.getSelectedWeapon();
		if (selectedWeapon == nil) {
			screen.log.write("Master arm must be on and a suitable weapon must be selected.");
			return;
		}
		if (selectedWeapon.target_pnt == TRUE and (selectedWeapon.guidance == AIM_GUIDANCE_LASER or selectedWeapon.guidance == AIM_GUIDANCE_GPS)) {
			var guidance = 0;
			if (selectedWeapon.guidance == AIM_GUIDANCE_LASER) {
				guidance = 1;
				if (getprop("controls/armament/laser-arm-dmd") == 0) {
					screen.log.write("Laser must be on to designate a laser guided weapon.");
					return;
				}
			}
			var spot = radar_system.ContactTGP.new("TGP-Spot", mySnipedTarget.coord, guidance);
			armament.contactPoint = spot;
			armament.DEBUG_STATS = 1;
			armament.DEBUG_SEARCH=1;
			screen.log.write("Sniped target is now the designated target.");
		} else {
			screen.log.write("A laser or GPS guided ground targeting weapon must be selected - no sniped target designated.");
		}
	} else {
		screen.log.write("A sniped target must exist");
	}
}

var fastSnipeAndDesignateLaserTarget = func() {
	var success = sniping();
	if (success == TRUE) {
		createSnipedTarget();
		designateSnipedTarget();
	} # else is not needed because method createSnipedTarget will work always - and last method tells result already
}

# This object creates an AI object at the spot of the last click
var SnipedTarget = {
	new: func() {
		var m = { parents : [SnipedTarget]};
		m.coord = geo.Coord.new();

		# Find the next index for "models/model" and create property node.
		# Find the next index for "ai/models/aircraft" and create property node.
		# (M. Franz, see Nasal/tanker.nas)
		var n = props.globals.getNode("models", 1);
		for (var i = 0 ; 1 ; i += 1) {
			if (n.getChild("model", i, 0) == nil) {
				break;
			}
		}
		m.model = n.getChild("model", i, 1);
		var n = props.globals.getNode("ai/models", 1);
		for (var i = 0 ; 1 ; i += 1) {
			if (n.getChild("aircraft", i, 0) == nil) {
				break;
			}
		}
		m.ai = n.getChild("aircraft", i, 1);
		#m.ai.getNode("valid", 1).setBoolValue(1);

		#We will replace it by a light that will modelize the laser spot
		m.id_model = "Aircraft/Mirage-2000/Models/lights/WhiteLight_LaserSpot.xml";

		m.id = m.ai.getNode("id", 1);
		m.callsign = m.ai.getNode("callsign", 1);
		m.valid = m.ai.getNode("valid", 1);
		m.valid.setBoolValue(1);

		#coordinate tree
		m.lat = m.ai.getNode("position/latitude-deg", 1);
		m.long = m.ai.getNode("position/longitude-deg", 1);
		m.alt = m.ai.getNode("position/altitude-ft", 1);

		#Orientation tree
		m.hdgN   = m.ai.getNode("orientation/true-heading-deg", 1);
		m.pitchN = m.ai.getNode("orientation/pitch-deg", 1);
		m.rollN  = m.ai.getNode("orientation/roll-deg", 1);

		#Radar Stuff
		m.radarRangeNM = m.ai.getNode("radar/range-nm", 1);
		m.radarbearingdeg = m.ai.getNode("radar/bearing-deg", 1);
		m.radarInRange = m.ai.getNode("radar/in-range", 1);
		m.elevN = m.ai.getNode("radar/elevation-deg", 1);
		m.hOffsetN = m.ai.getNode("radar/h-offset", 1);
		m.vOffsetN = m.ai.getNode("radar/v-offset", 1);

		# Speed
		m.ktasN = m.ai.getNode("velocities/true-airspeed-kt", 1);
		m.vertN = m.ai.getNode("velocities/vertical-speed-fps", 1);

		#Data comming from the dialog box
		m.dialog_lat = props.globals.getNode("/sim/dialog/groundTargeting/primary-latitude-deg");
		m.dialog_lon = props.globals.getNode("/sim/dialog/groundTargeting/primary-longitude-deg");

		m.coord.set_latlon(m.dialog_lat.getValue(),m.dialog_lon.getValue());
		var tempAlt = geo.elevation(m.dialog_lat.getValue(), m.dialog_lon.getValue(),10000);

		m.alt.setValue(tempAlt==nil?0:tempAlt);

		m.TargetedPath = nil;

		#AI/mp target Name
		m.AI_MP_targetName = "";
		m.AI_MP_targetCoord = geo.Coord.new();

		#Distance for closest AI/MP
		m.minDist = 3000;

		return m;
	}, # END new()

	del: func() {
		me.model.remove();
		me.valid.setBoolValue(0);
	}, # END del()

	init: func() {
		if (me.dialog_lat.getValue()==nil) {
			return;
		}

		#We take the coordinates from dialog box
		me.coord.set_latlon(me.dialog_lat.getValue(),me.dialog_lon.getValue());

		var tempLat = me.coord.lat();
		var tempLon = me.coord.lon();

		var test = geo.elevation(tempLat, tempLon,10000);
		test = test ==nil?0:test;
		me.coord.set_alt(test);

		var tempAlt = me.coord.alt();

		# there must be value in it
		me.lat.setValue(tempLat);
		me.long.setValue(tempLon);
		me.alt.setValue(tempAlt*M2FT);

		me.callsign.setValue(SNIPED_TARGET);
		me.id.setValue(-2);
		me.hdgN.setValue(0);
		me.pitchN.setValue(0);
		me.rollN.setValue(0);
		me.radarRangeNM.setValue(10);
		me.radarbearingdeg.setValue(0);
		me.radarInRange.setBoolValue(1);
		me.elevN.setValue(0);
		me.hOffsetN.setValue(0);
		me.vOffsetN.setValue(0);
		me.ktasN.setValue(0);
		me.vertN.setValue(0);

		# put value in model
		# beware : No absolute value here but the way to find the property
		me.model.getNode("path", 1).setValue(me.id_model);
		me.model.getNode("latitude-deg-prop", 1).setValue(me.lat.getPath());
		me.model.getNode("longitude-deg-prop", 1).setValue(me.long.getPath());
		me.model.getNode("elevation-ft-prop", 1).setValue(me.alt.getPath());
		me.model.getNode("heading-deg-prop", 1).setValue(me.hdgN.getPath());
		me.model.getNode("pitch-deg-prop", 1).setValue(me.pitchN.getPath());
		me.model.getNode("roll-deg-prop", 1).setValue(me.rollN.getPath());
		me.model.getNode("load", 1).remove();

		me.update();
	}, # END init()

	update: func() {
		if (me.dialog_lat.getValue()==nil) {
			return;
		}

		me.coord.set_lat(me.dialog_lat.getValue());
		me.coord.set_lon(me.dialog_lon.getValue());

		var tempGeo = geo.elevation(me.coord.lat(),me.coord.lon());
		if (tempGeo != nil and tempGeo!=0) {
			me.coord.set_alt(tempGeo);
		}

		# update Position of the Object
		var tempLat = me.coord.lat();
		var tempLon = me.coord.lon();
		var tempAlt = me.coord.alt()+0.1;
		me.lat.setValue(tempLat);
		me.long.setValue(tempLon);
		me.alt.setValue(tempAlt*M2FT);

		# update Distance to aircaft
		me.ac = geo.aircraft_position();
		var alt = me.coord.alt();
		me.distance = me.ac.distance_to(me.coord);

		# update bearing
		me.bearing = me.ac.course_to(me.coord);

		# update Radar Stuff
		var dalt = alt - me.ac.alt();
		var ac_hdg = getprop("/orientation/heading-deg");
		var ac_pitch = getprop("/orientation/pitch-deg");
		var ac_contact_dist = getprop("/systems/refuel/contact-radius-m");
		var elev = math.atan2(dalt, me.distance) * R2D;

		me.radarRangeNM.setValue(me.distance * M2NM);
		me.radarbearingdeg.setValue(me.bearing);
		me.elevN.setDoubleValue(elev);
		me.hOffsetN.setDoubleValue(view.normdeg(me.bearing - ac_hdg));
		me.vOffsetN.setDoubleValue(view.normdeg(elev - ac_pitch));

		if (MyActualview.getValue() == 10) {
			screen.log.write(sprintf("Distance to target (nm): %.1f", me.radarRangeNM.getValue()));
		}

		settimer(func(){ me.update(); }, 0);
	}, # END update()

	setCoord: func(new_coord) {
		me.coord.set(new_coord);
		me.lat.setValue(me.coord.lat());
		me.long.setValue(me.coord.lon());
		me.alt.setValue(me.coord.alt()*M2FT);

		me.dialog_lat.setValue(me.coord.lat());
		me.dialog_lon.setValue(me.coord.lon());
	}, # END setCoord()
};

var sniping = func(){
	var coord = geo.click_position();
	var success = FALSE;

	if (coord != nil) {
		setprop("/sim/dialog/groundTargeting/primary-longitude-deg", coord.lon());
		setprop("/sim/dialog/groundTargeting/primary-latitude-deg", coord.lat());
		screen.log.write("Sniped");
		gui.dialog_update("ground-targeting");
		success = TRUE;
	} else {
		screen.log.write("Nothing was there to be sniped");
	}
	return success;
}

# In order to have the right terrain elevation, we have to load the tile.
# For that, we focus the view on the target
var viewSnipedTarget = func(target) {

	# We select the missile name
	var targetName = string.replace(target.ai.getPath(), "/ai/models/", "");

	# We memorize the initial view number
	var actualView = getprop("/sim/current-view/view-number");

	# We recreate the data vector to feed the missile_view_handler
	var data = { node: target.ai, callsign: targetName, root: target.ai.getPath()};

	# We activate the AI view (on this aircraft it is the number 9)
	setprop("/sim/current-view/view-number",9);

	# We feed the handler
	viewMissile.missile_view_handler.setup(data);

	return actualView;
}

var deleteSnipedTarget = func() {
	if (mySnipedTarget != nil) {
		mySnipedTarget.del();
		armament.contactPoint = nil;
		mySnipedTarget = nil;
		screen.log.write("Sniped target deleted");
	}
}

var swapCoordinates = func() {
	deleteSnipedTarget();
	var prev_secondary_lon = getprop("/sim/dialog/groundTargeting/secondary-longitude-deg");
	var prev_secondary_lat = getprop("/sim/dialog/groundTargeting/secondary-latitude-deg");

	setprop("/sim/dialog/groundTargeting/secondary-longitude-deg", getprop("/sim/dialog/groundTargeting/primary-longitude-deg"));
	setprop("/sim/dialog/groundTargeting/secondary-latitude-deg", getprop("/sim/dialog/groundTargeting/primary-latitude-deg"));

	setprop("/sim/dialog/groundTargeting/primary-longitude-deg", prev_secondary_lon);
	setprop("/sim/dialog/groundTargeting/primary-latitude-deg", prev_secondary_lat);

	screen.log.write('Coordinates swapped - create target and then designate again');
	gui.dialog_update("ground-targeting");
}
