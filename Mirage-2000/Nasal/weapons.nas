print("*** LOADING weapons.nas ... ***");
################################################################################
#
#                        m2005-5's WEAPONS SETTINGS
#
################################################################################

var dt = 0;
var isFiring = 0;
var splashdt = 0;
var tokenFlare = 0;
var tokenMessageFlare = 0;
var MPMessaging = props.globals.getNode("/payload/armament/msg", 1);

# fire_MG = func(b) {
#     return 1;
#     var time = getprop("/sim/time/elapsed-sec");
#
#     # Here is the gun things : the firing should last 0,5 sec or 1 sec, and in
#     # the future should be selectionable
#     if(getprop("/controls/armament/stick-selector") == 1
#         and getprop("/ai/submodels/submodel/count") > 0
#         and isFiring == 0)
#     {
#         isFiring = 1;
#         setprop("/controls/armament/Gun_trigger", 1);
#         settimer(stopFiring, 0.5);
#     }
#     print("m2000_load.weaponARRAY_Index : "~ m2000_load.weaponARRAY_Index);
#     if(m2000_load.weaponARRAY_Index > 1){
#         if(b == 1)
#         {
#             # To limit: one missile/second
#             # var time = getprop("/sim/time/elapsed-sec");
#             if(time - dt > 1)
#             {
#                 dt = time;
#                 var pylon = getprop("/controls/armament/missile/current-pylon");
#                 m2000_load.dropLoad(pylon);
#                 print("Should fire Missile");
#             }
#         }
#     }
# }
#
# var stopFiring = func() {
#     setprop("/controls/armament/Gun_trigger", 0);
#     isFiring = 0;
# }
#
reload_Cannon = func() {
	setprop("/ai/submodels/submodel/count",    125);
	setprop("/ai/submodels/submodel[1]/count", 125);
	setprop("/ai/submodels/submodel[7]/count",120);
	setprop("/ai/submodels/submodel[8]/count",120);
	screen.log.write("Guns have been reloaded : 125");
	screen.log.write("Flares have been reloaded : 120");
}

Cannon_rate = func() {
	var rate = getprop("/ai/submodels/submodel/delay");
	setprop("/ai/submodels/submodel[1]/delay", rate);
	if (rate > 0.07) {
		Cannon_lQ_HQ_trigger("LQ");
	} else {
		Cannon_lQ_HQ_trigger("HQ");
	}
}

Cannon_lQ_HQ_trigger = func(Qual) {
	var path = getprop("/ai/submodels/submodel/submodel");

	#if(path == "Aircraft/Mirage-2000/Models/Effects/guns/LQ-submodels.xml"){
	if (Qual == "HQ") {
		#path = "Aircraft/Mirage-2000/Models/Effects/guns/bullet-submodel.xml";
		setprop("controls/armament/gunQuality",1);
	} else {
		#path = "Aircraft/Mirage-2000/Models/Effects/guns/LQ-submodels.xml";
		setprop("controls/armament/gunQuality",0);
	}
	print("Submodels Path" ~ path);
	setprop("/ai/submodels/submodel/submodel", path);
	setprop("/ai/submodels/submodel[1]/submodel", path);
}


############ Cannon impact messages #####################

var hits_count = 0;
var hit_timer  = nil;
var hit_callsign = "";
var TRUE = 1;
var FALSE = 0;

var Mp = props.globals.getNode("ai/models");
var valid_mp_types = {
	multiplayer: 1, tanker: 1, aircraft: 1, ship: 1, groundvehicle: 1,
};

# Find a MP aircraft close to a given point (code from the Mirage 2000)
var findmultiplayer = func(targetCoord, dist) {
	if(targetCoord == nil) {
		return nil;
	}

	var raw_list = Mp.getChildren();
	var SelectedMP = nil;
	foreach (var c ; raw_list) {
		var is_valid = c.getNode("valid");
		if (is_valid == nil or !is_valid.getBoolValue()) {
			continue;
		}

		var type = c.getName();

		var position = c.getNode("position");
		var name = c.getValue("callsign");
		if	(name == nil or name == "") {
			# fallback, for some AI objects
			var name = c.getValue("name");
		}
		if(position == nil or name == nil or name == "" or !contains(valid_mp_types, type)) {
			continue;
		}

		var lat = position.getValue("latitude-deg");
		var lon = position.getValue("longitude-deg");
		var elev = position.getValue("altitude-ft") * FT2M;

		if(lat == nil or lon == nil or elev == nil) {
			continue;
		}

		MpCoord = geo.Coord.new().set_latlon(lat, lon, elev);
		var tempoDist = MpCoord.direct_distance_to(targetCoord);
		if(dist > tempoDist) {
			dist = tempoDist;
			SelectedMP = name;
		}
	}
	return SelectedMP;
}

var impact_listener = func {
	var ballistic_name = props.globals.getNode("/ai/models/model-impact").getValue();
	var ballistic = props.globals.getNode(ballistic_name, 0);
	if (ballistic != nil and ballistic.getName() != "munition") {
		var typeNode = ballistic.getNode("impact/type");
		if (typeNode != nil and typeNode.getValue() != "terrain") {
			var lat = ballistic.getNode("impact/latitude-deg").getValue();
			var lon = ballistic.getNode("impact/longitude-deg").getValue();
			var elev = ballistic.getNode("impact/elevation-m").getValue();
			var impactPos = geo.Coord.new().set_latlon(lat, lon, elev);
			var target = findmultiplayer(impactPos, 80);

			if (target != nil) {
				var typeOrd = ballistic.getNode("name").getValue();
				if (target == hit_callsign) {
					# Previous impacts on same target
					hits_count += 1;
				} else {
					if (hit_timer != nil) {
						# Previous impacts on different target, flush them first
						hit_timer.stop();
						hitmessage(typeOrd);
					}
					hits_count = 1;
					hit_callsign = target;
					hit_timer = maketimer(1, func {hitmessage(typeOrd);});
					hit_timer.singleShot = 1;
					hit_timer.start();
				}
			}
		}
	}
}

var hitmessage = func(typeOrd) {
	var phrase = typeOrd ~ " hit: " ~ hit_callsign ~ ": " ~ hits_count ~ " hits";
	if (getprop("payload/armament/msg") == TRUE) {
		#armament.defeatSpamFilter(phrase);
		var msg = notifications.ArmamentNotification.new("mhit", 4, -1*(damage.shells[typeOrd][0]+1));
		msg.RelativeAltitude = 0;
		msg.Bearing = 0;
		msg.Distance = hits_count;
		msg.RemoteCallsign = hit_callsign;
		notifications.hitBridgedTransmitter.NotifyAll(msg);
		damage.damageLog.push("You hit "~hit_callsign~" with "~typeOrd~", "~hits_count~" times.");
	} else {
		setprop("/sim/messages/atc", phrase);
	}
	hit_callsign = "";
	hit_timer = nil;
	hits_count = 0;
}

# setup impact listener
setlistener("/ai/models/model-impact", impact_listener, 0, 0);

var flare = func(){
	if (tokenFlare==0) {
		if (tokenMessageFlare==0) {
			tokenMessageFlare=1;
			settimer(message_Flare,1);
		}
		tokenFlare= 1;
		setprop("rotors/main/blade[3]/flap-deg", rand());    #flare
		setprop("rotors/main/blade[3]/position-deg", rand());#chaff
		damage.flare_released();
		settimer(initFlare,0.5);
		settimer(initToken,1);
	}
}

var initFlare = func(){
	setprop("rotors/main/blade[3]/flap-deg", 0);   #flare
	setprop("rotors/main/blade[3]/position-deg", 0);#chaff
}
var initToken = func(){
	tokenFlare= 0;
}

var message_Flare = func() {
	var flares_remaining = getprop("/ai/submodels/submodel[7]/count");
	flares_remaining = flares_remaining == nil ? 0 : flares_remaining;
	screen.log.write("Flares : " ~ flares_remaining);
	tokenMessageFlare =0;
}
