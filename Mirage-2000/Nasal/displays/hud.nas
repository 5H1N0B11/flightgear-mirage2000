print("*** LOADING HUD.nas ... ***");
################################################################################
#
#                     m2005-5's HUD AI/MP SETTINGS
#
################################################################################
#panel with revi:
#      <x-m> -3.653 </x-m>
#      <y-m>  0.000 </y-m>
#      <z-m> -0.297 </z-m>
#      <pitch-deg> -14 </pitch-deg>
#revi:
#      <x-m> 0.456 </x-m>
#      <y-m> 0.000 </y-m>
#      <z-m> 0.159 </z-m>
#the canvas is wider than the actual hud : so display start at 16,7% of the hud and end at 84,3% (100%-16.7%)
#vertical is 100%
#the HUD is slanted. Angle : 40%
#Canvs start upper right
#x is positive rightwards. y is positive downwards
#480,480 --> (140,-150) - (150,200)
#Canvas coordinates :
#X: 80 to 400
#Y: 27.36 to 456.89

#HUD Position : x,y,z
#left lower corner (-0.07606, -0.07327, -0.03237)
#right upper corner (0.05357, 0.07327, 0.11536)
#Center HUD : (-0.12963,0,0.08299)

#OFFSET1 panel.xml :<offsets><x-m> 0.456 </x-m> <y-m> 0.000 </y-m><z-m> 0.159 </z-m></offsets>
#OFFSET2 interior.xml <offsets><x-m> -3.653 </x-m> <y-m>  0.000 </y-m>  <z-m> -0.297 </z-m>      <pitch-deg> -14 </pitch-deg>    </offsets>

var FALSE = 0;
var TRUE = 1;

var APPROACH_AOA = 14;
var TAKEOFF_AOA = 13;

var DROP_MODE_CCRP = 0; # see fire-control.nas
var DROP_MODE_CCIP = 1;

var CANNON_30MM = "30mm Cannon";
var CC422 = "CC422"; # gun pod
var ASMP = "ASMP";
var AIM_GUIDANCE_UNGUIDED = "unguided";
var AIM_GUIDANCE_RADIATION = "radiation";
var AIM_CLASS_GMP = "GMP";
var GBU12 = "GBU12"; # must correspond to short-name in payload.xml
var GBU24 = "GBU24"; # must correspond to short-name in payload.xml

# mostly for stuff that is changed manually by the pilot and therefore does not need to be updated so often
# e.g. the flightmode
var UPDATE_INC = 0.8;

var COLOR_GREEN = [0,1,0,1];

var MAX_ANTIRAD_TARGETS = 8;
var ANTIRAD_SYMBOLS_DIST = 24;
var ANTIRAD_RING = 80; # radius


var FONT_NARROW = "LiberationFonts/LiberationSansNarrow-Bold.ttf";
var FONT_REGULAR = "LiberationFonts/LiberationMono-Regular.ttf";
var FONT_BOLD = "LiberationFonts/LiberationMono-Bold.ttf";

var FONT_SIZE_DEFAULT = 18;
var FONT_SIZE_CHEVRON = 60;
var FONT_SIZE_LADDER = 30; # also used for minor parts of altitude and mach
var FONT_SIZE_ALPHA = 35;
var FONT_SIZE_WAYPOINT = 30;
var FONT_SIZE_ANTIRAD = 30;
var FONT_SIZE_DISTANCE_TARGET = 24;
var FONT_SIZE_SPEED = 45; # also used for hundreds part of altitude

var MAX_LADDER_SPAN = 200;
var LADDER_SCALE = 7.5;

var HEADSCALE_VERTICAL_PLACE = -450;
var HEADSCALE_APPROACH_TRANSLATE = 300;
var HEADSCALE_TICK_SPACING = 45;


# ==============================================================================
# Head up display
# ==============================================================================

var HUD = {
	canvas_settings: {
		"name": "HUD",
		"size": [1024,1024],#<-- size of the texture
		"view": [1024,1024], #<- Size of the coordinate systems (the bigger the sharpener)
		"mipmapping": 0
	},

	new: func(_ident, placement) {
		var m = {
			parents: [HUD],
			canvas: canvas.new(HUD.canvas_settings)
		};

		HudMath.init([-3.3935,-0.067,0.12032], [-3.3935,0.067,-0.041679], [1024,1024], [0,1.0], [0.8265,0.0], 0);

		m.sy = 1024/2;
		m.sx = 1024/2;

		m.viewPlacement = 480;
		m.min = -m.viewPlacement * 0.846;
		m.max = m.viewPlacement * 0.846;

		m.MaxX = 420; #the canvas is 420 *2;
		m.MaxY = 512; #the canvas is 420 *2;

		m.red = 0.3;
		m.green = 1.0;
		m.blue = 0.3;

		m.canvas.addPlacement(placement);
		m.canvas.setColorBackground(m.red, m.green, m.blue, 0.00);

		m.root = m.canvas.createGroup()
		                 .setTranslation(HudMath.getCenterOrigin())
		                 .set("font", FONT_REGULAR) # cannot use setFont etc.
		                 .setDouble("character-size", FONT_SIZE_DEFAULT)
		                 .setDouble("character-aspect-ration", 0.9);

		m.alternated = TRUE; # to be able to flash stuff every other UPDATE_INC

		m.loads_hash =  { # Cannot use CANNON_30MM and CC422 constants
			"30mm Cannon": "CAN",
			"CC422": "CAN",
			"Magic-2": "MAG",
			"S530D":"530",
			"MICA-IR":"MIC-I",
			"MICA-EM":"MIC-E",
			"GBU-12": "GBU12",
			"SCALP": "SCALP",
			"APACHE": "APACHE",
			"AM39-Exocet":"AM39",
			"AS-37-Armat":"AS37A",
			"AS30L" :"AS30",
			"Mk-82" : "Mk82",
			"Mk-82SE":"Mk82S",
			"GBU-24":"GBU24"
		};

		m.pylonsSide_hash = {
			0 : "L",
			1 : "L",
			2 : "L",
			7 : "L",
			3 : "C",
			4 : "R",
			5 : "R",
			6 : "R",
			8 : "R",
		};

		m.input = {
			pitch:      "/orientation/pitch-deg",
			roll:       "/orientation/roll-deg",
			hdg:        "/orientation/heading-magnetic-deg",
			hdgReal:    "/orientation/heading-deg",
			hdgBug:     "/autopilot/settings/heading-bug-deg",
			hdgDisplay: "/instrumentation/efis/mfd/true-north",
			speed_n:    "velocities/speed-north-fps",
			speed_e:    "velocities/speed-east-fps",
			speed_d:    "velocities/speed-down-fps",
			uBody_fps:  "velocities/uBody-fps",
			alpha:      "/orientation/alpha-deg",
			beta:       "/orientation/side-slip-deg",
			gload:      "/accelerations/pilot-g",
			gs:         "/velocities/groundspeed-kt",
			vs:         "/velocities/vertical-speed-fps",
			alt:        "/position/altitude-ft",
			wow_nlg:    "/gear/gear[1]/wow",
			gearPos:    "/gear/gear[1]/position-norm",
			airspeed:   "/velocities/airspeed-kt",
			target_spd: "/autopilot/settings/target-speed-kt",
			acc:        "/fdm/jsbsim/accelerations/udot-ft_sec2",
			afterburner: "/engines/engine[0]/afterburner",
			NavFreq:    "/instrumentation/nav/frequencies/selected-mhz",
			destRunway: "/autopilot/route-manager/destination/runway",
			destAirport:"/autopilot/route-manager/destination/airport",
			distNextWay:"/autopilot/route-manager/wp/dist",
			NextWayNum :"/autopilot/route-manager/current-wp",
			NextWayTrueBearing:"/autopilot/route-manager/wp/true-bearing-deg",
			NextWayBearing:"/autopilot/route-manager/wp/bearing-deg",
			AutopilotStatus:"/autopilot/locks/AP-status",
			currentWp     : "/autopilot/route-manager/current-wp",
			ILS_valid     :"/instrumentation/nav/data-is-valid",
			NavHeadingRunwayILS:"/instrumentation/nav/heading-deg",
			ILS_gs_in_range :"/instrumentation/nav/gs-in-range",
			ILS_gs_deg:  "/instrumentation/nav/gs-direct-deg",
			NavHeadingNeedleDeflectionILS:"/instrumentation/nav/heading-needle-deflection-norm",
			x_offset_m:    "/sim/current-view/x-offset-m",
			y_offset_m:    "/sim/current-view/y-offset-m",
			z_offset_m:    "/sim/current-view/z-offset-m",
			TimeToTarget   :"/sim/dialog/groundTargeting/time-to-target",
			IsRadarWorking : "/systems/electrical/outputs/radar",
			gun_rate       : "/ai/submodels/submodel[1]/delay",
			bullseye_lat   : "/instrumentation/bullseye/bulls-eye-lat",
			bullseye_lon   : "instrumentation/bullseye/bulls-eye-lon",
			bullseye_def   : "instrumentation/bullseye/bulls-eye-defined",
			HUD_POWER_VOLT : "/systems/electrical/outputs/HUD",
			flightmode     : "/instrumentation/flightmode/selected",
			semiactive_callsign       : "payload/armament/MAW-semiactive-callsign",
			launch_callsign           : "sound/rwr-launch",
			antiradar_target_type     : "controls/armament/antiradar-target-type",
			cannon_air_ground         : "controls/armament/cannon-air-ground",
			cannon_air_air_wingspan   : "controls/armament/cannon-air-air-wingspan"
		};

		foreach(var name; keys(m.input)) {
			m.input[name] = props.globals.getNode(m.input[name], 1);
		}

		#fpv
		m.fpv = m.root.createChild("path")
		              .setColor(COLOR_GREEN)
		              .moveTo(15, 0)
		              .horiz(40)
		              .moveTo(15, 0)
		              .arcSmallCW(15,15, 0, -30, 0)
		              .arcSmallCW(15,15, 0, 30, 0)
		              .moveTo(-15, 0)
		              .horiz(-40)
		              .moveTo(0, -15)
		              .vert(-15)
		              .setStrokeLineWidth(4);

		m.AutopilotStar = m.root.createChild("text")
		                        .setColor(COLOR_GREEN)
		                        .setTranslation(150,0)
		                        .setFontSize(50)
		                        .setAlignment("center-center")
		                        .setText("*");

		#Little House pointing Waypoint
		m.HouseSize = 4;
		m.HeadingHouse = m.root.createChild("path")
		                       .setColor(COLOR_GREEN)
		                       .setStrokeLineWidth(5)
		                       .moveTo(-20,0)
		                       .vert(-30)
		                       .lineTo(0,-50)
		                       .lineTo(20,-30)
		                       .vert(30);

		m._createChevrons();

		#bore cross
		m.boreCross = m.root.createChild("path")
		                    .setColor(COLOR_GREEN)
		                    .moveTo(-20, 0)
		                    .horiz(40)
		                    .moveTo(0, -20)
		                    .vert(40)
		                    .setStrokeLineWidth(4);

		#WP cross
		m.WaypointCross = m.root.createChild("path")
		                        .setColor(COLOR_GREEN)
		                        .moveTo(-20, 0)
		                        .horiz(12)
		                        .moveTo(8, 0)
		                        .horiz(12)
		                        .moveTo(0, -20)
		                        .vert(12)
		                        .moveTo(0, 8)
		                        .vert(12)
		                        .setStrokeLineWidth(4);

		# Horizon groups
		m.horizon_group = m.root.createChild("group");
		m.h_rot   = m.horizon_group.createTransform();
		m.horizon_sub_group = m.horizon_group.createChild("group");

		# Horizon and pitch lines
		m.horizon_sub_group.createChild("path")
		                   .setColor(COLOR_GREEN)
		                   .moveTo(-700, 0)
		                   .horiz(1400)
		                   .setStrokeLineWidth(4);
		m.ladder_group = m.horizon_sub_group.createChild("group");
		m._recalculateLadder();

		m._createApproachStuff(); # depends on horizon_sub_group

		m._createHeadingScaleStuff();

		m._createSpeedAndAltitudeStuff();

		m._createAlphaAoA();

		m.alphaGloadGroup = m.root.createChild("group");
		m.gload_text = m.alphaGloadGroup.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(- MAX_LADDER_SPAN-50,-120)
			.setFontSize(FONT_SIZE_ALPHA)
			.setAlignment("right-center");
		m.gload_text.enableUpdate();

		m.alpha_text = m.alphaGloadGroup.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(- MAX_LADDER_SPAN-50,-90)
			.setFontSize(FONT_SIZE_ALPHA)
			.setAlignment("right-center");
		m.alpha_text.enableUpdate();

		m.alphaGloadGroup.hide();

		m.loads_type_text = m.root.createChild("text")
		                          .setColor(COLOR_GREEN)
		                          .setTranslation(- MAX_LADDER_SPAN-90,-150)
		                          .setFontSize(FONT_SIZE_ALPHA)
		                          .setAlignment("right-center");
		m.loads_type_text.enableUpdate();
		m.loads_type_text.hide();

		# Bullet count when CAN is selected
		m.bullet_CountGroup = m.root.createChild("group");
		m.left_bullet_count = m.bullet_CountGroup.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(-MAX_LADDER_SPAN+60,100)
			.setFontSize(FONT_SIZE_ALPHA)
			.setFont(FONT_BOLD)
			.setAlignment("center-center");
		m.left_bullet_count.enableUpdate();

		m.right_bullet_count = m.bullet_CountGroup.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(MAX_LADDER_SPAN-60,100)
			.setFontSize(FONT_SIZE_ALPHA)
			.setFont(FONT_BOLD)
			.setAlignment("center-center");
		m.right_bullet_count.enableUpdate();
		m.bullet_CountGroup.hide();

		# Pylon selection letters
		m.pylons_Group = m.root.createChild("group");
		m.left_pylons = m.pylons_Group.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(-MAX_LADDER_SPAN+60,100)
			.setFontSize(FONT_SIZE_ALPHA)
			.setFont(FONT_BOLD)
			.setAlignment("center-center")
			.setText("G");
		m.right_pylons = m.pylons_Group.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(MAX_LADDER_SPAN-60,100)
			.setFontSize(FONT_SIZE_ALPHA)
			.setFont(FONT_BOLD)
			.setAlignment("center-center")
			.setText("D");
		m.center_pylons = m.pylons_Group.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(0,100)
			.setFontSize(FONT_SIZE_ALPHA)
			.setFont(FONT_BOLD)
			.setAlignment("center-center")
			.setText("C");
		m.pylons_Group.hide();

		# Pylon selection letters
		m.pylons_Circle_Group = m.root.createChild("group");
		m.left_circle = m.pylons_Circle_Group.createChild("path")
			.setColor(COLOR_GREEN)
			.moveTo(-MAX_LADDER_SPAN+60+25, 100)
			.arcSmallCW(25,25, 0, -50, 0)
			.arcSmallCW(25,25, 0, 50, 0)
			.setStrokeLineWidth(5);
		m.right_circle = m.pylons_Circle_Group.createChild("path")
			.setColor(COLOR_GREEN)
			.moveTo(MAX_LADDER_SPAN-60+25, 100)
			.arcSmallCW(25,25, 0, -50, 0)
			.arcSmallCW(25,25, 0, 50, 0)
			.setStrokeLineWidth(5);
		m.center_circle = m.pylons_Circle_Group.createChild("path")
			.setColor(COLOR_GREEN)
			.moveTo(25, 100)
			.arcSmallCW(25,25, 0, -50, 0)
			.arcSmallCW(25,25, 0, 50, 0)
			.setStrokeLineWidth(5);
		m.pylons_Circle_Group.hide();

		m._createGroundFlightMode();

		#Waypoint Group
		m.waypointGroup = m.root.createChild("group");

		m.waypointSimpleGroup = m.root.createChild("group");
		#Distance to next Waypoint
		m.waypoint_dist_simple = m.waypointSimpleGroup.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation( MAX_LADDER_SPAN + 45 ,HEADSCALE_VERTICAL_PLACE*2/5)
			.setFontSize(FONT_SIZE_WAYPOINT)
			.setAlignment("right-center");
		m.waypoint_dist_simple.enableUpdate();

		#next Waypoint NUMBER
		m.waypoint_number_simple = m.waypointSimpleGroup.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation( MAX_LADDER_SPAN + 85 ,HEADSCALE_VERTICAL_PLACE*2/5)
			.setFontSize(FONT_SIZE_WAYPOINT)
			.setAlignment("left-center");
		m.waypoint_number_simple.enableUpdate();

		#Distance to next Waypoint
		m.waypoint_dist = m.waypointGroup.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation( MAX_LADDER_SPAN + 80 ,HEADSCALE_VERTICAL_PLACE*2/5)
			.setFontSize(FONT_SIZE_WAYPOINT)
			.setAlignment("left-center");
		m.waypoint_dist.enableUpdate();

		#next Waypoint NUMBER
		m.waypoint_number = m.waypointGroup.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation( MAX_LADDER_SPAN + 80 ,HEADSCALE_VERTICAL_PLACE*2/5-25)
			.setFontSize(FONT_SIZE_WAYPOINT)
			.setAlignment("left-center");
		m.waypoint_number.enableUpdate();

		m.dest = m.waypointGroup.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation( MAX_LADDER_SPAN + 55 ,HEADSCALE_VERTICAL_PLACE*2/5-25)
			.setFontSize(FONT_SIZE_WAYPOINT)
			.setAlignment("right-center");
		m.dest.enableUpdate();

		#heading to the next Waypoint
		m.waypoint_heading = m.waypointGroup.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation( MAX_LADDER_SPAN + 65 ,HEADSCALE_VERTICAL_PLACE*2/5)
			.setFontSize(FONT_SIZE_WAYPOINT)
			.setAlignment("right-center");
		m.waypoint_heading.enableUpdate();

		m.radarStuffGroup = m.root.createChild("group");

		#eegs funnel:
		m.eegsGroup = m.root.createChild("group");
		m.averageDt = 0.10;
		m.funnelParts = 1.5 / m.averageDt;
		m.eegsRightX = [0];
		m.eegsRightY = [0];
		m.eegsLeftX  = [0];
		m.eegsLeftY  = [0];
		m.gunPos  = nil;
		m.shellPosXInit = [0];
		m.shellPosYInit =  [0];
		m.shellPosDistInit = [0];
		m.wingspan = 10;
		m._resetGunPos();

		m.eegsRightX = m._makeVector(m.funnelParts,0);
		m.eegsRightY = m._makeVector(m.funnelParts,0);
		m.eegsLeftX  = m._makeVector(m.funnelParts,0);
		m.eegsLeftY  = m._makeVector(m.funnelParts,0);

		m.eegsMe = {ac: geo.Coord.new(), eegsPos: geo.Coord.new(),shellPosX: m._makeVector(m.funnelParts,0),shellPosY: m._makeVector(m.funnelParts,0),shellPosDist: m._makeVector(m.funnelParts,0)};

		m.lastTime = systime();
		m.eegsLoop = maketimer(m.averageDt, m, m._displayEEGS);
		m.eegsLoop.simulatedTime = 1;

		m.selected_runway = 0;

		#######################  Triangles ##########################################

		var TriangleSize = 30;
		m.TriangleGroupe = m.radarStuffGroup.createChild("group");

		# le triangle donne le cap relatif
		m.triangle = m.TriangleGroupe.createChild("path")
			.setColor(COLOR_GREEN)
			.setStrokeLineWidth(3)
			.moveTo(0, TriangleSize*-1)
			.lineTo(TriangleSize*0.866, TriangleSize*0.5)
			.lineTo(TriangleSize*-0.866, TriangleSize*0.5)
			.lineTo(0, TriangleSize*-1);
		TriangleSize = TriangleSize*0.7;

		m.triangle2 = m.TriangleGroupe.createChild("path")
			.setColor(COLOR_GREEN)
			.setStrokeLineWidth(3)
			.moveTo(0, TriangleSize*-1)
			.lineTo(TriangleSize*0.866, TriangleSize*0.5)
			.lineTo(TriangleSize*-0.866, TriangleSize*0.5)
			.lineTo(0, TriangleSize*-1.1);
			m.triangleRot =  m.TriangleGroupe.createTransform();

		m.TriangleGroupe.hide();

		m.Square_Group = m.radarStuffGroup.createChild("group");

		m.locked_square  = m.Square_Group.createChild("path")
			.setColor(COLOR_GREEN)
			.move(-25,-25)
			.vert(50)
			.horiz(50)
			.vert(-50)
			.horiz(-50)
			.setStrokeLineWidth(6);

		m.locked_square_dash  = m.Square_Group.createChild("path")
			.setColor(COLOR_GREEN)
			.move(-25,-25)
			.vert(50)
			.horiz(50)
			.vert(-50)
			.horiz(-50)
			.setStrokeDashArray([10,10])
			.setStrokeLineWidth(5);
		m.Square_Group.hide();

		m.missileFireRange = m.root.createChild("group");
		m.MaxFireRange = m.missileFireRange.createChild("path")
			.setColor(COLOR_GREEN)
			.moveTo(200,0)
			.horiz(-20)
			.setStrokeLineWidth(4);
		m.MinFireRange = m.missileFireRange.createChild("path")
			.setColor(COLOR_GREEN)
			.moveTo(200,0)
			.horiz(-20)
			.setStrokeLineWidth(4);
		m.NEZFireRange = m.missileFireRange.createChild("path")
			.setColor(COLOR_GREEN)
			.moveTo(200,0)
			.horiz(-40)
			.setStrokeLineWidth(4);
		m.missileFireRange.hide();

		m.distanceToTargetLineGroup = m.root.createChild("group");
		m.distanceToTargetLineMin = -100;
		m.distanceToTargetLineMax = 100;
		m.distanceToTargetLine = m.distanceToTargetLineGroup.createChild("path")
			.setColor(COLOR_GREEN)
			.moveTo(200,m.distanceToTargetLineMin)
			.horiz(30)
			.moveTo(200,m.distanceToTargetLineMin)
			.vert(m.distanceToTargetLineMax-m.distanceToTargetLineMin)
			.horiz(30)
			.setStrokeLineWidth(4);

		m.distanceToTargetLineTextGroup = m.distanceToTargetLineGroup.createChild("group");
		m.distanceToTargetLineChevron = m.distanceToTargetLineTextGroup.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(200,0)
			.setFontSize(FONT_SIZE_DISTANCE_TARGET)
			.setAlignment("left-center")
			.setText("<");
		m.distance_to_target_line_chevron_text = m.distanceToTargetLineTextGroup.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(230,0)
			.setFontSize(FONT_SIZE_DISTANCE_TARGET)
			.setAlignment("left-center");
		 m.distance_to_target_line_chevron_text.enableUpdate();

		m.distanceToTargetLineGroup.hide();

		m.root.setColor(m.red,m.green,m.blue,1);

		m.lastWP = m.input.currentWp.getValue();
		m.RunwayCoord =  geo.Coord.new();
		m.RunwaysCoordCornerLeft = geo.Coord.new();
		m.RunwaysCoordCornerRight = geo.Coord.new();
		m.RunwaysCoordEndCornerLeft = geo.Coord.new();
		m.RunwaysCoordEndCornerRight = geo.Coord.new();
		m.bullseyeGeo = geo.Coord.new();
		m.NXTWP = geo.Coord.new();

		m.last_update_inc = 0;
		m.last_long_update_inc = 0;

		m.flightmode_cached = nil; # value from input.flightmode cached
		m.last_flightmode = nil; # only used to check need for recalculation

		m._createAntiRadSymbology();
		m._createCCIPSymbology();
		m._createCCRPSymbology();

		# Emesary notification stuff
		m.recipient = emesary.Recipient.new(_ident);
		m.recipient.parent_obj = m;

		m.recipient.Receive = func(notification) {
			if (notification.NotificationType == "FrameNotification") {
				me.parent_obj._update(notification);
				return emesary.Transmitter.ReceiptStatus_OK;
			}
			return emesary.Transmitter.ReceiptStatus_NotProcessed;
		};
		emesary.GlobalTransmitter.Register(m.recipient);

		return m;
	}, # END new

	_createHeadingScaleStuff: func () {
		me.heading_stuff_group = me.root.createChild("group");
		me.heading_scale_group = me.heading_stuff_group.createChild("group");

		me.heading_stuff_group.set("clip-frame", canvas.Element.LOCAL);
		me.heading_stuff_group.set("clip", "rect(-500px, 150px, -400px, -150px)");# top,right,bottom,left

		me.head_scale = me.heading_scale_group.createChild("path")
		                                  .setColor(COLOR_GREEN)
		                                  .moveTo(-HEADSCALE_TICK_SPACING*2, HEADSCALE_VERTICAL_PLACE)
		                                  .vert(-15)
		                                  .moveTo(0, HEADSCALE_VERTICAL_PLACE)
		                                  .vert(-15)
		                                  .moveTo(HEADSCALE_TICK_SPACING*2, HEADSCALE_VERTICAL_PLACE)
		                                  .vert(-15)
		                                  .moveTo(HEADSCALE_TICK_SPACING*4, HEADSCALE_VERTICAL_PLACE)
		                                  .vert(-15)
		                                  .moveTo(-HEADSCALE_TICK_SPACING, HEADSCALE_VERTICAL_PLACE)
		                                  .vert(-5)
		                                  .moveTo(HEADSCALE_TICK_SPACING, HEADSCALE_VERTICAL_PLACE)
		                                  .vert(-5)
		                                  .moveTo(-HEADSCALE_TICK_SPACING*3, HEADSCALE_VERTICAL_PLACE)
		                                  .vert(-5)
		                                  .moveTo(HEADSCALE_TICK_SPACING*3, HEADSCALE_VERTICAL_PLACE)
		                                  .vert(-5)
		                                  .setStrokeLineWidth(5)
		                                  .show();

		#Heading middle number on horizon line
		me.hdgMH = me.heading_scale_group.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(0,HEADSCALE_VERTICAL_PLACE -15)
			.setFontSize(FONT_SIZE_LADDER)
			.setAlignment("center-bottom");
		me.hdgMH.enableUpdate();

		# Heading left number on horizon line
		me.hdgLH = me.heading_scale_group.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(-HEADSCALE_TICK_SPACING*2,HEADSCALE_VERTICAL_PLACE -15)
			.setFontSize(FONT_SIZE_LADDER)
			.setAlignment("center-bottom");
		me.hdgLH.enableUpdate();

		# Heading right number on horizon line
		me.hdgRH = me.heading_scale_group.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(HEADSCALE_TICK_SPACING*2,HEADSCALE_VERTICAL_PLACE -15)
			.setFontSize(FONT_SIZE_LADDER)
			.setAlignment("center-bottom");
		me.hdgRH.enableUpdate();

		# Heading right right number on horizon line
		me.hdgRRH = me.heading_scale_group.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(HEADSCALE_TICK_SPACING*4,HEADSCALE_VERTICAL_PLACE -15)
			.setFontSize(FONT_SIZE_LADDER)
			.setAlignment("center-bottom");
		me.hdgRRH.enableUpdate();

		#Point the The Selected Route. it's at the middle of the HUD
		me.TriangleSize = 4;
		me.head_scale_route_pointer = me.heading_stuff_group.createChild("path")
			.setColor(COLOR_GREEN)
			.setStrokeLineWidth(3)
			.moveTo(0, HEADSCALE_VERTICAL_PLACE)
			.lineTo(me.TriangleSize*-5/2, (HEADSCALE_VERTICAL_PLACE)+(me.TriangleSize*5))
			.lineTo(me.TriangleSize*5/2,(HEADSCALE_VERTICAL_PLACE)+(me.TriangleSize*5))
			.lineTo(0, HEADSCALE_VERTICAL_PLACE);

		#a line represent the middle and the actual heading
		me.heading_pointer_line = me.heading_stuff_group.createChild("path")
			.setColor(COLOR_GREEN)
			.setStrokeLineWidth(4)
			.moveTo(0, HEADSCALE_VERTICAL_PLACE + 2)
			.vert(20);
	}, # END _createHeadingScaleStuff

	_createSpeedAndAltitudeStuff: func () {
		me.speed_and_alt_group = me.root.createChild("group");

		me.speed = me.speed_and_alt_group.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(- MAX_LADDER_SPAN,HEADSCALE_VERTICAL_PLACE)
			.setFontSize(FONT_SIZE_SPEED)
			.setAlignment("right-bottom");
		me.speed.enableUpdate();

		me.speed_mach = me.speed_and_alt_group.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(- MAX_LADDER_SPAN,HEADSCALE_VERTICAL_PLACE+25)
			.setFontSize(FONT_SIZE_LADDER)
			.setAlignment("right-bottom");
		me.speed_mach.enableUpdate();

		me.hundred_feet_alt = me.speed_and_alt_group.createChild("text")
			.setTranslation(MAX_LADDER_SPAN + 60 ,HEADSCALE_VERTICAL_PLACE)
			.setFontSize(FONT_SIZE_SPEED)
			.setAlignment("right-bottom");
		me.hundred_feet_alt.enableUpdate();

		me.feet_alt = me.speed_and_alt_group.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(MAX_LADDER_SPAN + 60,HEADSCALE_VERTICAL_PLACE)
			.setFontSize(FONT_SIZE_LADDER)
			.setAlignment("left-bottom");
		me.feet_alt.enableUpdate();

		me.ground_alt = me.speed_and_alt_group.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(MAX_LADDER_SPAN + 95,HEADSCALE_VERTICAL_PLACE+25)
			.setFontSize(FONT_SIZE_LADDER)
			.setAlignment("right-bottom");
		me.ground_alt.enableUpdate();

		# Heading right right number on horizon line
		me.the_H = me.speed_and_alt_group.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(MAX_LADDER_SPAN + 100,HEADSCALE_VERTICAL_PLACE+25)
			.setFontSize(FONT_SIZE_LADDER)
			.setAlignment("left-bottom")
			.setText("H");
	}, # END _createSpeedAndAltitudeStuff

	_createChevrons: func() { # Chevrons = Acceleration Vector (AV)
		me.chevron_factor = 50;
		me.chevronGroup = me.root.createChild("group");
		me.chevronGroupAB = me.chevronGroup.createChild("group");

		me.LeftChevron = me.chevronGroup.createChild("text")
		                              .setColor(COLOR_GREEN)
		                              .setTranslation(-150,0)
		                              .setFontSize(FONT_SIZE_CHEVRON)
		                              .setAlignment("center-center")
		                              .setText(">");
		me.LeftChevronAB = me.chevronGroupAB.createChild("text")
		                              .setColor(COLOR_GREEN)
		                              .setTranslation(-180,0)
		                              .setFontSize(FONT_SIZE_CHEVRON)
		                              .setAlignment("center-center")
		                              .setText(">");

		me.RightChevron = me.chevronGroup.createChild("text")
		                               .setColor(COLOR_GREEN)
		                               .setTranslation(150,0)
		                               .setFontSize(FONT_SIZE_CHEVRON)
		                               .setAlignment("center-center")
		                               .setText("<");
		me.RightChevronAB = me.chevronGroupAB.createChild("text")
		                               .setColor(COLOR_GREEN)
		                               .setTranslation(180,0)
		                               .setFontSize(FONT_SIZE_CHEVRON)
		                               .setAlignment("center-center")
		                               .setText("<");
	}, # END _createChevrons

	_createAlphaAoA: func() {
		me.alpha_group = me.root.createChild("group");

		#alpha
		me.alpha = me.alpha_group.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(- MAX_LADDER_SPAN-70, HEADSCALE_VERTICAL_PLACE+50)
			.setFontSize(FONT_SIZE_ALPHA)
			.setAlignment("right-center")
			.setText("α");

		#aoa
		me.aoa = me.alpha_group.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(- MAX_LADDER_SPAN-50, HEADSCALE_VERTICAL_PLACE+50)
			.setFontSize(FONT_SIZE_ALPHA)
			.setAlignment("left-center");
		me.aoa.enableUpdate();
	}, # END _createAlphaAoA

	_createApproachStuff: func() {
		# AoA brackets
		var bracket_size = HudMath.getPosFromDegs(0,- APPROACH_AOA)[1]- HudMath.getPosFromDegs(0,- (APPROACH_AOA - 1))[1];
		me.approach_aoa_brackets = me.root.createChild("group");
		me.left_bracket = me.approach_aoa_brackets.createChild("path")
		                          .setColor(COLOR_GREEN)
		                          .moveTo(-140, -bracket_size/2)
		                          .horiz(10)
		                          .vert(bracket_size)
		                          .horiz(-10)
		                          .setStrokeLineWidth(2);
		me.right_bracket = me.approach_aoa_brackets.createChild("path")
		                          .setColor(COLOR_GREEN)
		                          .moveTo(140, -bracket_size/2)
		                          .horiz(-10)
		                          .vert(bracket_size)
		                          .horiz(10)
		                          .setStrokeLineWidth(2);

		#ILS stuff
		me.ILS_scale_dependant = me.horizon_sub_group.createChild("group");

		# line for runway on the horizon
		me.runway_horizon_line = me.ILS_scale_dependant.createChild("path")
		                                                .setColor(COLOR_GREEN)
		                                                .move(0,0)
		                                                .vert(-30)
		                                                .setStrokeLineWidth(4);

		me.ILS_localizer_deviation = me.ILS_scale_dependant.createChild("path")
		                                                 .setColor(COLOR_GREEN)
		                                                 .move(0,0)
		                                                 .vert(1500)
		                                                 .setStrokeDashArray([30, 30, 30, 30, 30])
		                                                 .setStrokeLineWidth(4);
		me.ILS_localizer_deviation.setCenter(0,0);

		#Part of the ILS not dependant of the SCALE
		me.ILS_scale_independant = me.root.createChild("group");
		me.ILS_square  = me.ILS_scale_independant.createChild("path")
		                                       .setColor(COLOR_GREEN)
		                                       .move(-25,-25)
		                                       .vert(50)
		                                       .horiz(50)
		                                       .vert(-50)
		                                       .horiz(-50)
		                                       .setStrokeLineWidth(4);

		# Synthetic runway rectangle - content will be set in _drawSyntheticRunway method on demand
		me.runway_group = me.root.createChild("group");
	}, # END _createApproachStuff

	_createGroundFlightMode: func() {
		me.acceleration_box_group = me.root.createChild("group");

		me.acceleration_box_text = me.acceleration_box_group.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(0,0)
			.setFontSize(FONT_SIZE_ALPHA)
			.setAlignment("center-center");
		me.acceleration_box_text.enableUpdate();

		me.acceleration_box_box = me.acceleration_box_group.createChild("path")
			.setColor(COLOR_GREEN)
			.moveTo(-70, -25)
			.horiz(140)
			.vert(50)
			.horiz(-140)
			.vert(-50)
			.setStrokeLineWidth(4);
		me.acceleration_box_group.setTranslation(0,HEADSCALE_VERTICAL_PLACE*2/5);

		me.inverted_t = me.root.createChild("path")
		                    .setColor(COLOR_GREEN)
		                    .moveTo(-MAX_LADDER_SPAN/2, 0)
		                    .horiz(MAX_LADDER_SPAN)
		                    .moveTo(0, 0)
		                    .vert(-MAX_LADDER_SPAN/15*2)
		                    .setStrokeLineWidth(6);
	}, # END _createGroundFlightMode

	_createCCRPSymbology: func() {
		me.CCRP = me.root.createChild("group");

		me.CCRP_piper_group = me.CCRP.createChild("group");

		me.CCRP_piper = me.CCRP_piper_group.createChild("path")
			.setColor(COLOR_GREEN)
			.moveTo(24, 0)
			.lineTo(0,32)
			.lineTo(-24,0)
			.lineTo(0,-32)
			.lineTo(24,0)
			.moveTo(1,1)
			.lineTo(1,-1)
			.lineTo(-1,-1)
			.lineTo(-1,1)
			.moveTo(24, 0)
			.lineTo(44,0)
			.moveTo(-24, 0)
			.lineTo(-44,0)
			.setStrokeLineWidth(4);

		me.CCRP_deviation = me.CCRP_piper_group.createChild("path")
			.setColor(COLOR_GREEN)
			.moveTo(34, 0)
			.lineTo(80,0)
			.moveTo(-34, 0)
			.lineTo(-80,0)
			.setStrokeLineWidth(4);

		me.CCRP_release_cue = me.CCRP.createChild("path")
			.setColor(COLOR_GREEN)
			.moveTo(55, 0)
			.horiz(-110)
			.setStrokeLineWidth(4);

		# Distance to target
		me.CCRP_impact_dist = me.CCRP.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(MAX_LADDER_SPAN + 90,-150)
			.setFontSize(FONT_SIZE_ALPHA)
			.setAlignment("left-center");
		me.CCRP_impact_dist.enableUpdate();

		me.CCRP_no_go_cross = me.CCRP.createChild("path")
			.setColor(COLOR_GREEN)
			.moveTo(80, 80)
			.lineTo(-80,-80)
			.moveTo(-80, 80)
			.lineTo(80,-80)
			.setStrokeLineWidth(4);
	}, # END _createCCRPSymbology

	_createCCIPSymbology: func() {
		me.CCIP = me.root.createChild("group");
		# Bomb Fall Line (BFL)
		me.CCIP_BFL = me.CCIP.createChild("group");

		#Bomb impact - a hexagon with wings on each side - each side in the hexagon is 24
		me.CCIP_piper = me.CCIP.createChild("path")
			.setColor(COLOR_GREEN)
			.moveTo(24, 0)
			.horiz(40) # right wing
			.moveTo(24, 0)
			.lineTo(12,20)
			.lineTo(-12,20)
			.lineTo(-24,0)
			.lineTo(-12,-20)
			.lineTo(12,-20)
			.lineTo(24,0)
			.moveTo(-24, 0)
			.horiz(-40) # left wing
			.setStrokeLineWidth(4);

		me.CCIP_safe_alt = me.CCIP.createChild("path") # pull up cue
			.setColor(COLOR_GREEN)
			.moveTo(15, 0)
			.horiz(40)
			.vert(-15)
			.moveTo(-15, 0)
			.horiz(-40)
			.vert(-15)
			.setStrokeLineWidth(4);

		# Distance to impact
		me.CCIP_impact_dist = me.CCIP.createChild("text")
			.setColor(COLOR_GREEN)
			.setTranslation(MAX_LADDER_SPAN + 90,-150)
			.setFontSize(FONT_SIZE_ALPHA)
			.setAlignment("left-center");
		me.CCIP_impact_dist.enableUpdate();

		me.CCIP_no_go_cross = me.CCIP.createChild("path")
			.setColor(COLOR_GREEN)
			.moveTo(80, 80)
			.lineTo(-80,-80)
			.moveTo(-80, 80)
			.lineTo(80,-80)
			.setStrokeLineWidth(4);
	}, # END _createCCIPSymbology

	_createAntiRadSymbology: func() { # Anti radar missile (antirad)
		me.antirad_grp = me.root.createChild("group");

		me.antirad_cue_core = me.antirad_grp.createChild("group");

		var ANTIRAD_TICK = 20;

		me.antirad_cue_core_ring = me.antirad_cue_core.createChild("path")
			.setColor(COLOR_GREEN)
			.circle(ANTIRAD_RING, 0, 0)
			.setStrokeLineWidth(4);

		me.antirad_cue_core_ticks = me.antirad_cue_core.createChild("path")
			.setColor(COLOR_GREEN)
			.moveTo(0, ANTIRAD_RING) # top
			.lineTo(0, ANTIRAD_RING - ANTIRAD_TICK)
			.moveTo(0, -ANTIRAD_RING) # bottom
			.lineTo(0, -ANTIRAD_RING + ANTIRAD_TICK)
			.moveTo(-ANTIRAD_RING, 0) # left
			.lineTo(-ANTIRAD_RING + ANTIRAD_TICK, 0)
			.moveTo(ANTIRAD_RING, 0) # right
			.lineTo(ANTIRAD_RING - ANTIRAD_TICK, 0)
			.setStrokeLineWidth(4);

		me.antirad_cue_locked = me.antirad_grp.createChild("path")
			.setColor(COLOR_GREEN)
			.circle(ANTIRAD_RING + 10, 0, 0)
			.setStrokeLineWidth(4);

		me.antirad_texts = setsize([], MAX_ANTIRAD_TARGETS);
		for (var i = 0; i < MAX_ANTIRAD_TARGETS; i+=1) {
			me.antirad_texts[i] = me.antirad_grp.createChild("text")
				.setAlignment("center-center")
				.setColor(COLOR_GREEN)
				.setFontSize(FONT_SIZE_ANTIRAD)
				.hide();
			me.antirad_texts[i].enableUpdate();
		}

		me.antirad_circle = setsize([], MAX_ANTIRAD_TARGETS); # circle around
		for (var i = 0; i < MAX_ANTIRAD_TARGETS; i+=1) {
			me.antirad_circle[i] = me.antirad_grp.createChild("path")
				.moveTo(-30, 0)
				.arcSmallCW(30, 30, 0, 60, 0)
				.arcSmallCW(30, 30, 0, -60, 0)
				.setStrokeLineWidth(2)
				.setColor(COLOR_GREEN)
				.hide();
		}

		me.antirad_symbol_hat = setsize([], MAX_ANTIRAD_TARGETS); # supporting active missile
		for (var i = 0; i < MAX_ANTIRAD_TARGETS; i+=1) {
			me.antirad_symbol_hat[i] = me.antirad_grp.createChild("path")
				.moveTo(0, -ANTIRAD_SYMBOLS_DIST)
				.lineTo(ANTIRAD_SYMBOLS_DIST*0.9, -ANTIRAD_SYMBOLS_DIST*0.6)
				.moveTo(0, -ANTIRAD_SYMBOLS_DIST)
				.lineTo(-ANTIRAD_SYMBOLS_DIST*0.9, -ANTIRAD_SYMBOLS_DIST*0.6)
				.setStrokeLineWidth(4)
				.setColor(COLOR_GREEN)
				.hide();
		}

		me.antirad_symbol_chevron = setsize([], MAX_ANTIRAD_TARGETS); # STT / spike
		for (var i = 0; i < MAX_ANTIRAD_TARGETS; i+=1) {
			me.antirad_symbol_chevron[i] = me.antirad_grp.createChild("path")
				.moveTo(0, ANTIRAD_SYMBOLS_DIST)
				.lineTo(ANTIRAD_SYMBOLS_DIST*0.9, ANTIRAD_SYMBOLS_DIST*0.6)
				.moveTo(0, ANTIRAD_SYMBOLS_DIST)
				.lineTo(-ANTIRAD_SYMBOLS_DIST*0.9, ANTIRAD_SYMBOLS_DIST*0.6)
				.setStrokeLineWidth(4)
				.setColor(COLOR_GREEN)
				.hide();
		}

	}, # END _createAntiRadSymbology

	_weapon_has_guidance_prop: func() {
		# check whether the property "guidance" is available in the selected weapon
		if (me.selected_weapon != nil and contains(me.selected_weapon, "guidance")) {
			return TRUE;
		}
		return FALSE;
	}, # END _weapon_has_guidance_prop

	_update: func(noti = nil) {
		if (me.input.HUD_POWER_VOLT.getValue()<23) {
			me.root.setVisible(0);
		} else {
			me.root.setVisible(1);
		}

		me.elapsed = noti.getproper("elapsed_seconds");
		if (me.elapsed - me.last_update_inc >= UPDATE_INC) {
			me.last_update_inc = me.elapsed;
			if (me.alternated == TRUE) {
				me.alternated = FALSE;
			} else {
				me.alternated = TRUE;
			}

			me.last_flightmode = me.flightmode_cached;
			me.flightmode_cached = me.input.flightmode.getValue();
			if (me.last_flightmode == nil or me.flightmode_cached != me.last_flightmode) {
				me._recalculateLadder();
			}
		} else if (me.elapsed - me.last_long_update_inc >= 10*UPDATE_INC) {
			me.last_long_update_inc = me.elapsed;
			me._recalculateLadder(); # Force update to account for manual change of seat/view
		}
		me.master_arm = noti.getproper("master_arm");

		me.aircraft_position = geo.aircraft_position();
		me.hydra = FALSE; # for rocket
		me.strf = me.input.cannon_air_ground.getValue(); # Air to ground fire : based on mode chosen in PPA
		HudMath.reCalc();

		# loading Flightplan
		me.fp = flightplan();

		#Choose the heading to display
		me.heading_displayed = displays.common.getHeadingForDisplay()[0];

		#-----------------Test of paralax
		me.vy = me.input.x_offset_m.getValue();
		me.pixel_per_meter_x = HudMath.pixelPerMeterX; # (340*0.695633)/0.15848;
		me.pixel_side = me.pixel_per_meter_x * me.vy;
		me.root.setTranslation(HudMath.getCenterOrigin()[0] + me.pixel_side, HudMath.getCenterOrigin()[1]);
		me.root.update();

		me.eegsShow = FALSE;
		me.selected_weapon = pylons.fcs.getSelectedWeapon();

		me.show_CCIP = FALSE;
		me.show_CCRP = FALSE;
		me.CCRP_piper_group_visibilty = TRUE;
		me.CCRP_cue_visbility = FALSE;
		me.CCRP_no_go_cross_visibility = FALSE;
		me.bore_pos =  HudMath.getBorePos();

		var target_contacts_list = radar_system.apg68Radar.getActiveBleps();

		if (me.flightmode_cached == consts.FLIGHT_MODE_ATTACK and me.selected_weapon != nil) {
			if (me.selected_weapon.type == ASMP) {
				# nothing to do
			} else if (me.selected_weapon.type == CANNON_30MM or me.selected_weapon.type == CC422) {
				me.eegsShow = TRUE;
			} else if (me.selected_weapon.class == AIM_CLASS_GMP) {
				if (me._weapon_has_guidance_prop() == TRUE and me.selected_weapon.guidance == AIM_GUIDANCE_UNGUIDED) {
					if (pylons.fcs.getDropMode() == DROP_MODE_CCIP) {
						me.show_CCIP = me._displayCCIPMode();
					} else {
						if (target_contacts_list != nil and size(target_contacts_list) > 0 and radar_system.apg68Radar.getPriorityTarget() != nil) {
							me.show_CCRP = me._displayCCRPMode(me.bore_pos);
						} # else nothing to do until a target has been chosen
					}
				} else if (me.selected_weapon.typeShort == GBU12 or me.selected_weapon.typeShort == GBU24) {
					me.show_CCRP = me._displayCCRPMode(me.bore_pos);
				}
			}
		}

		#CCRP visibility :
		#piper when we have a target
		#Cue line when time to target < 15
		#Cross when speed <350
		#target and house (to be defined)
		me.CCRP.setVisible(me.show_CCRP);
		me.CCRP_piper_group.setVisible(me.CCRP_piper_group_visibilty);
		me.CCRP_release_cue.setVisible(me.CCRP_cue_visbility);
		me.CCRP_no_go_cross.setVisible(me.CCRP_no_go_cross_visibility);

		me.CCIP.setVisible(me.show_CCIP);

		me.horizStuff = HudMath.getStaticHorizon();
		me.horizon_group.setTranslation(me.horizStuff[0]);
		me.h_rot.setRotation(me.horizStuff[1]);
		me.horizon_sub_group.setTranslation(me.horizStuff[2]);

		#############################################################
		#Calculate the GPS coord of the next WP
		me._calcNextWaypointCoordinate();

		if (me.input.bullseye_def.getValue()) {
			if (me.input.bullseye_lat.getValue() != nil and me.input.bullseye_lon.getValue() != nil) {
				me.bullseyeGeo.set_latlon(me.input.bullseye_lat.getValue(),me.input.bullseye_lon.getValue());
			}
		}

		#Display the Next WP ##################################################
		#Should be displayed for :
		#1-Next waypoint
		#2-bulleseye
		#3-ground target
		me.displayWaypointCrossShow = FALSE;
		me.display_house_show = 0;
		me.waypointGroupshow = 0;
		me.waypointSimpleGroupShow = 0;

		if (me.input.gearPos.getValue() == 0) { # if masterArm is not selected
			#if there is a route selected and Bulleye isn't selected
			if ( me.NXTWP.is_defined()) {#if waypoint is active
				me._displayWaypointCross(me.NXTWP);  # displaying the ground cross
				me._displayHouse(me.NXTWP);         # displaying the little house
				me._displayWaypoint(me.NXTWP,"DEST",me.input.NextWayNum.getValue());
			}
			if (me.input.bullseye_def.getValue()) {
				me._displayWaypointCross(me.bullseyeGeo);  # displaying the ground cross
				me._displayHouse(me.bullseyeGeo);         # displaying the little house
				me._displayWaypoint(me.bullseyeGeo,"BE ",nil);
			}
		}

		me.WaypointCross.setVisible(me.displayWaypointCrossShow);
		me.HeadingHouse.setVisible(me.display_house_show);
		me.waypointGroup.setVisible(me.waypointGroupshow);
		me.waypointSimpleGroup.setVisible(0);

		###################################################

		me._displayBoreCross(me.bore_pos);

		me._displayFPV();

		me._displayChevron();

		me._displayGroundFlightMode();

		me._displayApproachFlightMode();

		me.alt_for_display = displays.common.getAltForDisplay();

		me._displayRadarAltimeter(me.alt_for_display[2]);

		me._displaySpeedAltGroup(me.alt_for_display[0], me.alt_for_display[1]);

		me._displayAlpha();

		me._displayGload();

		me._displayLoadsType();

		me._displayBulletCount();

		me._displaySelectedPylons();

		#Displaying the circles, the squares or even the triangles (triangles will be for a IR lock without radar)
		me._displayTarget();
		me._displayHeatTarget();

		me._displayAntiRadTargets();

		# -------------------- displayHeadingHorizonScale ---------------
		me._displayHeadingHorizonScale();

		#---------------------- EEGS --------------------
		if (!me.eegsShow) {
			me.eegsGroup.setVisible(me.eegsShow);
		}
		if (me.eegsShow and !me.eegsLoop.isRunning) {
			me.eegsLoop.start();
		} elsif (!me.eegsShow and me.eegsLoop.isRunning) {
			me.eegsLoop.stop();
		}

		me.lastWP = me.input.currentWp.getValue();
	}, # END update

	_displayCCIPMode: func() {
		me.ccipPos = me.selected_weapon.getCCIPadv(18, 0.20);
		if (me.ccipPos != nil) {
			me.hud_pos = HudMath.getPosFromCoord(me.ccipPos[0]);
			if (me.hud_pos != nil) {
				me.pos_x = me.hud_pos[0];
				me.pos_y = me.hud_pos[1];
				me.CCIP_piper.setTranslation(me.pos_x,me.pos_y);

				# Updating : clear all previous stuff
				me.CCIP_BFL.removeAllChildren();

				# Drawing the line
				me.CCIP_BFL_line = me.CCIP_BFL.createChild("path")
				                              .setColor(COLOR_GREEN)
				                              .moveTo(me.fpvCalc)
				                              .lineTo(me.pos_x, me.pos_y)
				                              .setStrokeLineWidth(4);
				me.CCIP_BFL_line.setVisible(1);
				me.CCIP_BFL_line.update();

				# Calculate safe altitude - me.selected_weapon.reportDist*2 is an arbitrary choice
				me.safe_alt = int(me.ccipPos[0].alt() + me.selected_weapon.reportDist * 2);
				me.safe_alt_percent = me.safe_alt / (me.input.alt.getValue());
				me.safe_y_pos = me.fpvCalc[1]-(me.fpvCalc[1]-me.pos_y)*(1-math.clamp(me.safe_alt_percent,0,1));
				me.safe_diff_factor = (me.safe_y_pos - me.fpvCalc[1]) / (me.pos_y - me.fpvCalc[1]);
				me.safe_x_pos = me.fpvCalc[0] - (me.fpvCalc[0] - me.pos_x) * me.safe_diff_factor;
				me.CCIP_safe_alt.setTranslation(me.safe_x_pos, me.safe_y_pos);

				# Distance to ground impact : only working if radar is on
				if (me.input.IsRadarWorking.getValue()>24) {
					me.CCIP_impact_dist.updateText(sprintf("%.1f KM", me.ccipPos[0].direct_distance_to(geo.aircraft_position())/1000));
				} else {
					me.CCIP_impact_dist.updateText("n/a KM");
				}
				# No go : too dangerous to drop the bomb
				me.CCIP_no_go_cross.setVisible(me.safe_alt_percent>0.85);
				return TRUE;
			}
		}
		return FALSE;
	}, # END _displayCCIPMode()

	_displayCCRPMode: func(bore_pos) {
		me.DistanceToShoot = nil; # the distance the aircraft travels before bombs are released - not the distance to the target

		var maxFallTime = 45;
		if (me.selected_weapon.Tgt != nil and me.selected_weapon.Tgt.isVirtual() == FALSE) {
			var maxFallTime = me.input.TimeToTarget.getValue();
		}

		me.DistanceToShoot = me.selected_weapon.getCCRP(maxFallTime, 0.1);

		if (me.DistanceToShoot != nil ) {
			# This should be the CCRP function
			# We need the house and the nav point display to display the target.
			# The CCRP piper is a fixed point and replaces the FPV

			# CCRP steering cues:
			# They appear only after a target point has been selected. They are centered on the
			# CCRP piper and rotate to show deviation from the course to target. The aircraft is
			# flying directly to the target when they are level.

			if (me.DistanceToShoot/ (me.input.gs.getValue() * KT2MPS) < 15) {
				me.hud_pos = HudMath.getPosFromCoord(me.selected_weapon.Tgt.get_Coord());
				if (me.hud_pos != nil) {
					me.pos_x = me.hud_pos[0];
					me.pos_y = me.hud_pos[1];
					me.CCRP_release_percent = (me.DistanceToShoot/ (me.input.gs.getValue() * KT2MPS))/30;
					me.CCRP_release_cue.setTranslation(bore_pos[0], bore_pos[1]-(bore_pos[1]-me.pos_y)*(math.clamp(me.CCRP_release_percent,0,1)));
					me.CCRP_cue_visbility = TRUE;
				}
			}
			# Distance to ground impact : only working if radar is on
			if (me.input.IsRadarWorking.getValue()>24) {
				me.CCRP_impact_dist.updateText(sprintf("%.1f KM", me.DistanceToShoot/1000));
			} else {
				me.CCRP_impact_dist.updateText("n/a KM");
			}
		}

		# The no-go CCRP is when speed < 350 kts.
		if (me.input.airspeed.getValue() < 350) {
			me.CCRP_no_go_cross_visibility = TRUE;
		}

		# There is a target so the piper and the deviation should get displayed.
		# The rotation is dispalyed with some exagerations at small deviations and less at larger deviations
		me.CCRP_piper_group.setTranslation(HudMath.getBorePos());
		if (me.selected_weapon.Tgt != nil) {
			var deviation = 0.;
			if (me.selected_weapon.Tgt.isVirtual() == TRUE) {
				deviation = geo.normdeg180(geo.aircraft_position().course_to(me.selected_weapon.Tgt.get_Coord()) - me.input.hdgReal.getValue());
			} else {
				deviation = me.selected_weapon.Tgt.getDeviation()[0];
			}
			if (deviation < 5) {
				deviation = deviation * 5;
			} else if (deviation < 10) {
				deviation = 25 + (deviation - 5) * 3;
			} else if (deviation < 30) {
				deviation = 40 + (deviation - 10) * 1.5;
			} else if (deviation < 60) {
				deviation = 70 + (deviation - 30) * 0.5;
			} else {
				deviation = 85;
			}
			me.CCRP_deviation.setRotation(deviation*D2R);
		}
		return TRUE;
	}, # END _displayCCRPMode()

	_displayHeadingHorizonScale: func() {
		me.headOffset = me.heading_displayed/10 - int (me.heading_displayed/10);
		me.headScaleOffset = me.headOffset;
		me.middleText = _roundabout(me.heading_displayed/10);
		me.middleText = me.middleText == 36?0:me.middleText;
		me.leftText = me.middleText == 0?35:me.middleText-1;
		me.rightText = me.middleText == 35?0:me.middleText+1;
		me.rightRightText = me.rightText == 35?0:me.rightText+1;

		if (me.headOffset > 0.5) {
			me.middleOffset = -(me.headScaleOffset-1)*HEADSCALE_TICK_SPACING*2;
		} else {
			me.middleOffset = -me.headScaleOffset*HEADSCALE_TICK_SPACING*2;
		}
		me.hdgRH.updateText(sprintf("%02d", me.rightText));
		me.hdgMH.updateText(sprintf("%02d", me.middleText));
		me.hdgLH.updateText(sprintf("%02d", me.leftText));
		me.hdgRRH.updateText(sprintf("%02d", me.rightRightText));

		# heading bug
		headOffset = -(geo.normdeg180(me.heading_displayed - me.input.hdgBug.getValue() ))*HEADSCALE_TICK_SPACING/5;
		me.head_scale_route_pointer.setTranslation(headOffset,0);

		me.heading_scale_group.setTranslation(me.middleOffset , 0);
		me.heading_scale_group.update();

		me.heading_stuff_group.setTranslation(0 , me.flightmode_cached == consts.FLIGHT_MODE_APPROACH ? HEADSCALE_APPROACH_TRANSLATE : 0);
	}, # END _displayHeadingHorizonScale()

	# flight path vector (FPV)
	_displayFPV: func() {
		me.fpvCalc = HudMath.getFlightPathIndicatorPosWind();
		me.fpv.setTranslation(me.fpvCalc);
		if (me.input.AutopilotStatus.getValue()=="AP1") {
			me.AutopilotStar.setTranslation(me.fpvCalc);
			me.AutopilotStar.show();
		} else {
			me.AutopilotStar.hide();
		}
	}, # END _displayFPV

	#This should be called with a geo.coord object.
	#Doing that way it could be used for waypoint, bullseye and ground target
	_displayHouse: func(coord) {
		if (coord != nil) {
			if (!me._isInCanvas(HudMath.getPosFromCoord(coord)[0],HudMath.getPosFromCoord(coord)[1]) or me.aircraft_position.direct_distance_to(coord)*M2NM >=10 ) {
				# Depends on which heading we want to display
				if (me.input.hdgDisplay.getValue()) {
					me.houseTranslation = -(geo.normdeg180(me.heading_displayed - me.aircraft_position.course_to(coord)))*HEADSCALE_TICK_SPACING/5;
				} else {
					me.houseTranslation = -(geo.normdeg180(me.heading_displayed - me.aircraft_position.course_to(coord)))*HEADSCALE_TICK_SPACING/5;
				}

			me.HeadingHouse.setTranslation(math.clamp(me.houseTranslation,-MAX_LADDER_SPAN,MAX_LADDER_SPAN),me.fpvCalc[1]);
			if (abs(me.houseTranslation/(HEADSCALE_TICK_SPACING/5))>90) {
				me.HeadingHouse.setRotation(me.horizStuff[1]+(180* D2R));
			} else {
				me.HeadingHouse.setRotation(me.horizStuff[1]);
			}
			me.display_house_show = 1;
			return;
			}
		}
	}, # END _displayHouse()

	_displayChevron: func() {
		if (me.input.afterburner.getValue()) {
			me.chevronGroupAB.show();
		} else {
			me.chevronGroupAB.hide();
		}
		me.chevronGroup.setTranslation(me.fpvCalc[0],me.fpvCalc[1]-me.input.acc.getValue()*FT2M*me.chevron_factor);
	}, # END _displayChevron()

	_displayGroundFlightMode: func() {
		if (me.flightmode_cached == consts.FLIGHT_MODE_GROUND) {
			me.acceleration_box_text.updateText(sprintf("%.2f", int(me.input.acc.getValue()*FT2M/9.8*1000+1)/1000));
			me.acceleration_box_group.show();
			me.inverted_t.setTranslation(0, HudMath.getCenterPosFromDegs(0,-TAKEOFF_AOA)[1]);
			me.inverted_t.show();
		} else {
			me.acceleration_box_group.hide();
			me.inverted_t.hide();
		}
	}, # END _displayGroundFlightMode()

	_displayApproachFlightMode: func() {
		if (me.flightmode_cached == consts.FLIGHT_MODE_APPROACH) {
			me.approach_aoa_brackets.setTranslation(0, HudMath.getCenterPosFromDegs(0, -APPROACH_AOA)[1]);
			me.approach_aoa_brackets.show();

			me._displayILSStuff();
			me._displayILSSquare();
			me._displayRunway();
		} else {
			me.approach_aoa_brackets.hide();

			me.ILS_scale_dependant.hide();
			me.ILS_scale_independant.hide();
			me.runway_group.removeAllChildren();
		}
	}, # END _displayApproachFlightMode()

	_displayILSStuff: func() {
		if (me.input.ILS_valid.getValue()) {
			me.runwayPosHrizonOnHUD = HudMath.getPixelPerDegreeXAvg(7.5)*-(geo.normdeg180(me.heading_displayed - me.input.NavHeadingRunwayILS.getValue() ));

			me.ILS_scale_dependant.setTranslation(me.runwayPosHrizonOnHUD,0);
			me.ILS_localizer_deviation.setRotation(-45*me.input.NavHeadingNeedleDeflectionILS.getValue()*D2R);
			me.ILS_scale_dependant.update();
			me.ILS_scale_dependant.show();
		} else {
			me.ILS_scale_dependant.hide();
		}
	}, # END _displayILSStuff()

	_displayILSSquare: func() {
		if (me.input.ILS_gs_in_range.getValue()) {
			me.ILS_square.setTranslation(0,HudMath.getCenterPosFromDegs(0,-me.input.ILS_gs_deg.getValue()-me.input.pitch.getValue())[1]);
			me.ILS_scale_independant.show();
		} else {
			me.ILS_scale_independant.hide();
		}
	}, # END _displayILSSquare()

	_displayRunway: func() {
		#2. SYNTHETIC RUNWAY. The synthetic runway symbol is an aid for locating the real runway, especially during low visibility conditions.
		#It is only visible when:
		# in flightmode = FLIGHT_MOE_APPROACH
		#a. The INS is on.
		#b. The airport is the current fly-to waypoint.
		#c. The runway data (heading and glideslope) were entered.
		#d. Both localizer and glideslope have been captured
		#e. The runway is less than 10 nautical miles away.
		#f. Lateral deviation is less than 7º.
		# The synthetic runway is removed from the HUD as soon as there is weight on the landing gear’s wheels.

		#First trying with ILS
		me.selected_runway = "0";
		#print("-- Lengths of the runways at ", info.name, " (", info.id, ") --");
		me.info = airportinfo();
		foreach(var rwy; keys(me.info.runways)) {
			if (sprintf("%.2f",me.info.runways[rwy].ils_frequency_mhz) == sprintf("%.2f",me.input.NavFreq.getValue())) {
				me.selected_runway = rwy;
				break;
			}
		}
		#Then, trying with route manager
		if (me.selected_runway == "0") {
			if (me.input.destRunway.getValue() != "") {
				if (me.fp.getPlanSize() == me.fp.indexOfWP(me.fp.currentWP())+1) {
					me.info = airportinfo(me.input.destAirport.getValue());
					me.selected_runway = me.input.destRunway.getValue();
				}
			}
		}
		#print("Test : ",me.selected_runway != "0");
		if (me.selected_runway != "0") {
			var (courseToAiport, distToAirport) = courseAndDistance(me.info);
			if (distToAirport < 10) {
				me._drawSyntheticRunway();
			} else {
				me.runway_group.removeAllChildren();
			}
		} else {
			me.runway_group.removeAllChildren();
		}
	}, # END _displayRunway()

	_drawSyntheticRunway: func() {
		#Calculating GPS coord of the runway's corners
		#No need to recalculate GPS position everytime, only when the destination airport is changed
		if (me.RunwayCoord.lat != me.info.runways[me.selected_runway].lat or me.RunwayCoord.lpn != me.info.runways[me.selected_runway].lon) {
			me.RunwayCoord.set_latlon(me.info.runways[me.selected_runway].lat, me.info.runways[me.selected_runway].lon, me.info.elevation);

			me.RunwaysCoordCornerLeft.set_latlon(me.info.runways[me.selected_runway].lat, me.info.runways[me.selected_runway].lon, me.info.elevation);
			me.RunwaysCoordCornerLeft.apply_course_distance((me.info.runways[me.selected_runway].heading)-90,(me.info.runways[me.selected_runway].width)/2);

			me.RunwaysCoordCornerRight.set_latlon(me.info.runways[me.selected_runway].lat, me.info.runways[me.selected_runway].lon, me.info.elevation);
			me.RunwaysCoordCornerRight.apply_course_distance((me.info.runways[me.selected_runway].heading)+90,(me.info.runways[me.selected_runway].width)/2);

			me.RunwaysCoordEndCornerLeft.set_latlon(me.info.runways[me.selected_runway].lat, me.info.runways[me.selected_runway].lon, me.info.elevation);
			me.RunwaysCoordEndCornerLeft.apply_course_distance((me.info.runways[me.selected_runway].heading)-90,(me.info.runways[me.selected_runway].width)/2);
			me.RunwaysCoordEndCornerLeft.apply_course_distance((me.info.runways[me.selected_runway].heading),me.info.runways[me.selected_runway].length);

			me.RunwaysCoordEndCornerRight.set_latlon(me.info.runways[me.selected_runway].lat, me.info.runways[me.selected_runway].lon, me.info.elevation);
			me.RunwaysCoordEndCornerRight.apply_course_distance((me.info.runways[me.selected_runway].heading)+90,(me.info.runways[me.selected_runway].width)/2);
			me.RunwaysCoordEndCornerRight.apply_course_distance((me.info.runways[me.selected_runway].heading),me.info.runways[me.selected_runway].length);
		}

		#Calculating the HUD coord of the runways coord
		me.MyRunwayCoordCornerLeftTripos      = HudMath.getPosFromCoord(me.RunwaysCoordCornerLeft);
		me.MyRunwayCoordCornerRightTripos     = HudMath.getPosFromCoord(me.RunwaysCoordCornerRight);
		me.MyRunwayCoordCornerEndLeftTripos   = HudMath.getPosFromCoord(me.RunwaysCoordEndCornerLeft);
		me.MyRunwayCoordCornerEndRightTripos  = HudMath.getPosFromCoord(me.RunwaysCoordEndCornerRight);

		#Updating : clear all previous stuff
		me.runway_group.removeAllChildren();
		#drawing the runway
		me.runways_drawing = me.runway_group.createChild("path")
		                                    .setColor(COLOR_GREEN)
		                                    .moveTo(me.MyRunwayCoordCornerLeftTripos[0],me.MyRunwayCoordCornerLeftTripos[1])
		                                    .lineTo(me.MyRunwayCoordCornerRightTripos[0],me.MyRunwayCoordCornerRightTripos[1])
		                                    .lineTo(me.MyRunwayCoordCornerEndRightTripos[0],me.MyRunwayCoordCornerEndRightTripos[1])
		                                    .lineTo(me.MyRunwayCoordCornerEndLeftTripos[0],me.MyRunwayCoordCornerEndLeftTripos[1])
		                                    .lineTo(me.MyRunwayCoordCornerLeftTripos[0],me.MyRunwayCoordCornerLeftTripos[1])
		                                    .setStrokeLineWidth(4);

		me.runway_group.update();
	}, # END _drawSyntheticRunway

	_displaySpeedAltGroup: func(alt_hundreds_str, alt_digits_str) {
		var speed_display = displays.common.getSpeedForDisplay();
		me.speed.updateText(speed_display[0]);
		if (speed_display[1] != nil) {
			me.speed_mach.updateText(speed_display[1]);
			me.speed_mach.show();
		} else {
			me.speed_mach.hide();
		}

		me.feet_alt.updateText(alt_digits_str);
		me.hundred_feet_alt.updateText(alt_hundreds_str);

		me.speed_and_alt_group.setTranslation(0 , me.flightmode_cached == consts.FLIGHT_MODE_APPROACH ? HEADSCALE_APPROACH_TRANSLATE : 0);
		me.speed_and_alt_group.update();
	}, # END _displaySpeedAltGroup

	_displayRadarAltimeter: func(rad_alt_str) {
		if (rad_alt_str != nil) {
			me.ground_alt.updateText(rad_alt_str);
			me.ground_alt.show();
			me.the_H.show();
		} else {
			me.ground_alt.hide();
			me.the_H.hide();
		}
	}, # END _displayRadarAltimeter

	_displayAlpha: func() {
		if ((me.flightmode_cached == consts.FLIGHT_MODE_NAVIGATION or me.flightmode_cached == consts.FLIGHT_MODE_APPROACH) and me.input.alpha.getValue() > 2) {
			me.aoa.updateText(sprintf("%0.1f",me.input.alpha.getValue()));
			me.alpha_group.show();
		} else {
			me.alpha_group.hide();
		}
	},

	_displayGload: func() {
		if (me.flightmode_cached == consts.FLIGHT_MODE_ATTACK) {
			me.gload_text.updateText(sprintf("%0.1fG",me.input.gload.getValue()));
			me.alpha_text.updateText(sprintf("%0.1fα",me.input.alpha.getValue()));
			me.alphaGloadGroup.show();
		} else {
			me.alphaGloadGroup.hide();
		}
	},

	_displayLoadsType: func() {
		if (me.flightmode_cached == consts.FLIGHT_MODE_ATTACK and me.selected_weapon != nil) {
			if (me.master_arm or me.alternated == TRUE) {
				me.loads_type_text.updateText(me.loads_hash[me.selected_weapon.type]);
			} else {
				me.loads_type_text.updateText(""); # flash to indicate master arm is off
			}
			me.loads_type_text.show();
		} else {
			me.loads_type_text.hide();
		}
	},

	_displayBulletCount: func{
		if (me.flightmode_cached == consts.FLIGHT_MODE_ATTACK and me.selected_weapon != nil) {
			if (me.selected_weapon.type == CANNON_30MM) {
				me.left_bullet_count.updateText(sprintf("%3d", pylons.fcs.getAmmo()/2));
				me.right_bullet_count.updateText(sprintf("%3d", pylons.fcs.getAmmo()/2));
				me.bullet_CountGroup.show();
			} else if (me.selected_weapon.type == CC422) {
				me.left_bullet_count.updateText(sprintf("%3d", pylons.fcs.getAmmo()));
				me.right_bullet_count.updateText("");
				me.bullet_CountGroup.show();
			} else {
				me.bullet_CountGroup.hide();
			}
		} else {
			me.bullet_CountGroup.hide();
		}
	},

	_displaySelectedPylons: func {
		#Showing the circle around the L or R if the weapons is under the wings.
		#A circle around a C is also done for center loads, but I couldn't find any docs on that, so it is conjecture
		if (me.flightmode_cached == consts.FLIGHT_MODE_ATTACK and me.selected_weapon != nil) {
			if (me.selected_weapon.type != CANNON_30MM and me.selected_weapon.type != CC422) {
				#Init the vector
				me.pylonRemainAmmo_hash = {
					"L": 0,
					"C": 0,
					"R": 0,
				};
				me.pylons_Group.show();
				me.pylons_Circle_Group.show();
				#create the remainingAmmo vector and starting to count L and R
				me.RemainingAmmoVector = pylons.fcs.getAllAmmo(pylons.fcs.getSelectedType());
				for (i = 0 ; i < size(me.RemainingAmmoVector)-1 ; i += 1) {
					me.pylonRemainAmmo_hash[me.pylonsSide_hash[i]] += me.RemainingAmmoVector[i];
				}
				#Showing the pylon
				if (me.pylonRemainAmmo_hash["L"]>0) {me.left_pylons.show();} else {me.left_pylons.hide();}
				if (me.pylonRemainAmmo_hash["C"]>0) {me.center_pylons.show();} else {me.center_pylons.hide();}
				if (me.pylonRemainAmmo_hash["R"]>0) {me.right_pylons.show();} else {me.right_pylons.hide();}

				#Showing the Circle for the selected pylon
				if (me.pylonsSide_hash[pylons.fcs.getSelectedPylonNumber()] == "L") {me.left_circle.show();} else {me.left_circle.hide();}
				if (me.pylonsSide_hash[pylons.fcs.getSelectedPylonNumber()] == "C") {me.center_circle.show();} else {me.center_circle.hide();}
				if (me.pylonsSide_hash[pylons.fcs.getSelectedPylonNumber()] == "R") {me.right_circle.show();} else {me.right_circle.hide();}
			} else {
				me.pylons_Group.hide();
				me.pylons_Circle_Group.hide();
			}
		} else {
			me.pylons_Group.hide();
			me.pylons_Circle_Group.hide();
		}
	},

	_displayWaypoint: func(coord, TEXT, NextNUM) {
		#coord is a geo object of the current destination
		#TEXT is what will be written to describe our target : BE (Bullseye) ou DEST (route)
		#NextNUM is the next waypoint/bullseye number (most of the time it's the waypoint number)
		if (coord != nil) {
			if (me.aircraft_position.direct_distance_to(coord)*M2NM>10) {
				me.waypoint_dist.updateText(sprintf("%d N",int(me.aircraft_position.direct_distance_to(coord)*M2NM)));
				me.waypoint_dist_simple.updateText(sprintf("%d N",int(me.aircraft_position.direct_distance_to(coord)*M2NM)));
			} else {
				me.waypoint_dist.updateText(sprintf("%0.1f N",me.aircraft_position.direct_distance_to(coord)*M2NM));
				me.waypoint_dist_simple.updateText(sprintf("%0.1f N",me.aircraft_position.direct_distance_to(coord)*M2NM));
			}
			if (NextNUM != nil) {
				me.waypoint_number.updateText(sprintf("%02d",NextNUM));
				me.waypoint_number_simple.updateText(sprintf("%02d",NextNUM));
			}
			me.dest.updateText(TEXT);

			if (me.input.hdgDisplay.getValue()) {
				me.waypoint_heading.updateText(sprintf("%03d/",me.aircraft_position.course_to(coord)));
			} else {
				me.waypoint_heading.updateText(sprintf("%03d/",me.aircraft_position.course_to(coord)));
			}
			me.waypointGroupshow = 1;
		}
	},

	_displayHeatTarget: func() {
		if (me.selected_weapon == nil or me.flightmode_cached != consts.FLIGHT_MODE_ATTACK) {
			me.TriangleGroupe.hide();
			return;
		}
		if (me._weapon_has_guidance_prop() == FALSE or (me._weapon_has_guidance_prop() == TRUE and me.selected_weapon.guidance != "heat")) {
			me.TriangleGroupe.hide();
			return;
		}

		#Starting to search (Shouldn't be there but in the controls)
		me.selected_weapon.start();
		var coords = me.selected_weapon.getSeekerInfo();
		if (coords != nil) {
			var seekerTripos = HudMath.getCenterPosFromDegs(coords[0],coords[1]);
			me.TriangleGroupe.show();
			me.triangle.setTranslation(seekerTripos);
			me.triangle2.setTranslation(seekerTripos);
		} else {
			me.TriangleGroupe.hide();
		}
	}, # END _displayHeatTarget

	_displayTarget: func() {
		#To put a triangle on the selected target
		#This should be changed by calling directly the radar object (in case of multi targeting)

		me.showDistanceToken = FALSE;

		if (me.flightmode_cached == consts.FLIGHT_MODE_ATTACK) {
			me.raw_list = radar_system.apg68Radar.getActiveBleps();
			me.designatedDistanceFT = nil;

			foreach(var contact; me.raw_list) {
				var triPos = HudMath.getPosFromCoord(contact.getCoord());
				#1- Show Rectangle : have been painted (or selected ?)
				#2- Show double triangle : IR missile LOCK without radar
				#3- Show circle : the radar see it, without focusing
				#4- Do not show anything : nothing see it

				#1 Rectangle :
				if (contact.equalsFast(radar_system.apg68Radar.getPriorityTarget())) {

					#Here for displaying the square (painting)
					me.showDistanceToken = TRUE;
					#Show square group
					me.Square_Group.show();
					me.locked_square.setTranslation(triPos);
					me.locked_square_dash.setTranslation(math.clamp(triPos[0],-me.MaxX*0.8,me.MaxX*0.8), math.clamp(triPos[1],-me.MaxY*0.8,me.MaxY*0.8));
					#hide triangle and circle
					#me.TriangleGroupe.hide();

					me.distanceToTargetLineGroup.show();
					me._displayDistanceToTargetLine(contact);

					if (math.abs(triPos[0])<2000 and math.abs(triPos[1])<2000) {#only show it when target is in front
						me.designatedDistanceFT = contact.getCoord().direct_distance_to(geo.aircraft_position())*M2FT;
					}
					break;
				}
			}
		}
		#The token has 1 when we have a selected target
		#if we don't have target :
		if (me.showDistanceToken == FALSE) {
			me.Square_Group.hide();
			me.distanceToTargetLineGroup.hide();
			me.missileFireRange.hide();
		}
	}, # END _displayTarget

	_displayAntiRadTargets: func() {
		me.antirad_i = 0;

		me.antirad_cue_core.hide();
		me.antirad_cue_locked.hide();
		if (me.flightmode_cached == consts.FLIGHT_MODE_ATTACK and me._weapon_has_guidance_prop() == TRUE and me.selected_weapon.guidance == AIM_GUIDANCE_RADIATION and me.selected_weapon.isPowerOn()) {
			me.antirad_cue_core.show();
			if (pylons.fcs.isLock()) {
				me.antirad_cue_locked.show();
			}

			me.antirad_high_threat = FALSE;
			me.antirad_pos = nil;
			me.antirad_y = 0.;

			me.antirad_semi_callsign = me.input.semiactive_callsign.getValue();
			me.antirad_launch_callsign = me.input.launch_callsign.getValue();
			me.has_hat = FALSE;
			me.searchable_items = [];
			foreach(me.antirad_contact; radar_system.f16_rwr.vector_aicontacts_threats) {
				me.antirad_db_entry = radar_system.getDBEntry(me.antirad_contact[0].getModel());
				# first exclude what does not need to be shown
				if (me.antirad_i >= MAX_ANTIRAD_TARGETS) {
					break;
				}
				if (me.antirad_db_entry.rwrCode == nil) {
					continue;
				}
				if (me.antirad_contact[0].get_range() > 50) { # own choice as documented in the M2000 manual
					continue;
				}
				if (me.antirad_db_entry.rwrCode == "S" and me.input.antiradar_target_type.getValue() > 0) {
					continue;
				} else if (me.antirad_db_entry.rwrCode == "SH" and me.input.antiradar_target_type.getValue() != 1) {
					continue;
				} else if (me.input.antiradar_target_type.getValue() == 2) {
					if (me.antirad_db_entry.rwrCode != "3" and me.antirad_db_entry.rwrCode != "5" and me.antirad_db_entry.rwrCode != "20" and me.antirad_db_entry.rwrCode != "P") {
						continue;
					}
				}
				if (me.antirad_contact[1] >= 0.5) {
					me.antirad_high_threat = TRUE;
				} else {
					me.antirad_high_threat = FALSE;
				}
				me.antirad_pos = HudMath.getPosFromCoord(me.antirad_contact[0].getCoord());
				if (!me._isInCanvas(me.antirad_pos[0], me.antirad_pos[1])) {
					continue;
				}

				# make the seeker find the radiation if within the recticle, but only the first found
				if (size(me.searchable_items) == 0) {
					if (math.abs(me.antirad_pos[0]) <= ANTIRAD_RING and math.abs(me.antirad_pos[1] <= ANTIRAD_RING)) {
						append(me.searchable_items, me.antirad_contact[0]);
						# print("found "~me.antirad_contact[0].get_Callsign());
					}
				}

				me.has_hat = FALSE;
				if (me.antirad_launch_callsign != nil and me.antirad_launch_callsign != '' and me.antirad_launch_callsign == me.antirad_contact[0].get_Callsign()) {
					me.has_hat = TRUE;
				} else if (me.antirad_semi_callsign != nil and me.antirad_semi_callsign != '' and me.antirad_semi_callsign == me.antirad_contact[0].get_Callsign()) {
					me.has_hat = TRUE;
				}

				me.antirad_texts[me.antirad_i].setTranslation(me.antirad_pos[0], me.antirad_pos[1]);
				me.antirad_texts[me.antirad_i].updateText(me.antirad_db_entry.rwrCode);
				me.antirad_texts[me.antirad_i].show();
				me.antirad_circle[me.antirad_i].setTranslation(me.antirad_pos[0], me.antirad_pos[1]);
				me.antirad_circle[me.antirad_i].show();
				if (me.has_hat) {
					me.antirad_symbol_hat[me.antirad_i].setTranslation(me.antirad_pos[0], me.antirad_pos[1]);
					me.antirad_symbol_hat[me.antirad_i].show();
				} else {
					me.antirad_symbol_hat[me.antirad_i].hide();
				}
				if (me.antirad_contact[0].isSpikingMe()) {
					me.antirad_symbol_chevron[me.antirad_i].setTranslation(me.antirad_pos[0], me.antirad_pos[1]);
					me.antirad_symbol_chevron[me.antirad_i].show();
				} else {
					me.antirad_symbol_chevron[me.antirad_i].hide();
				}
				me.antirad_i += 1; # will only be increased if it was used - i.e. not continued
			}
			me.selected_weapon.setContacts(me.searchable_items);

			# hide every symbol, which is not needed
			for (;me.antirad_i < MAX_ANTIRAD_TARGETS; me.antirad_i+=1) {
				me.antirad_texts[me.antirad_i].hide();
				me.antirad_circle[me.antirad_i].hide();
				me.antirad_symbol_hat[me.antirad_i].hide();
				me.antirad_symbol_chevron[me.antirad_i].hide();
			}
		} else {
			for (; me.antirad_i < MAX_ANTIRAD_TARGETS; me.antirad_i+=1) {
				me.antirad_texts[me.antirad_i].hide();
				me.antirad_circle[me.antirad_i].hide();
				me.antirad_symbol_hat[me.antirad_i].hide();
				me.antirad_symbol_chevron[me.antirad_i].hide();
			}
		}
	}, # END _displayAntiRadTargets

	_displayDistanceToTargetLine : func(contact) {
		me.MaxRadarRange = radar_system.apg68Radar.getRange();
		var direct_distance_m = contact.getRangeDirect();
		var myString ="";
		#< 10 nm should be a float
		#< 1200 m should be in meters
		if (direct_distance_m <= me.MaxRadarRange * NM2M) {
			#Text for distance to target
			if (direct_distance_m < 1200) {
				myString = sprintf("%dm",direct_distance_m);
			} elsif (direct_distance_m < 10 * NM2M) {
				myString = sprintf("%.1fnm",direct_distance_m * M2NM);
			} else {
				myString = sprintf("%dnm",direct_distance_m * M2NM);
			}

			if (me._displayDLZ(me.MaxRadarRange)) {
				me.missileFireRange.show();
			} else {
				me.missileFireRange.hide();
			}
			me.distance_to_target_line_chevron_text.updateText(myString);
			me.distanceToTargetLineTextGroup.setTranslation(0,(me.distanceToTargetLineMax-me.distanceToTargetLineMin)-(direct_distance_m * M2NM *(me.distanceToTargetLineMax-me.distanceToTargetLineMin)/ me.MaxRadarRange)-100);
		}
	},

	_displayDLZ: func() {
		if (me.selected_weapon != nil and me.flightmode_cached == consts.FLIGHT_MODE_ATTACK) {
			#Testings
			if (me.selected_weapon.type != CANNON_30MM and me.selected_weapon.type != CC422) {
				if (me.selected_weapon.class == "A" and me.selected_weapon.parents[0] == armament.AIM) {

					me.myDLZ = pylons.getDLZ();

					if (me.myDLZ != nil) {
						# Max
						me.MaxFireRange.setTranslation(0, math.clamp((me.distanceToTargetLineMax-me.distanceToTargetLineMin)-(me.myDLZ[0]*(me.distanceToTargetLineMax-me.distanceToTargetLineMin)/ me.MaxRadarRange)-100,me.distanceToTargetLineMin,me.distanceToTargetLineMax));

						# MinFireRange
						me.MinFireRange.setTranslation(0, math.clamp((me.distanceToTargetLineMax-me.distanceToTargetLineMin)-(me.myDLZ[3]*(me.distanceToTargetLineMax-me.distanceToTargetLineMin)/ me.MaxRadarRange)-100,me.distanceToTargetLineMin,me.distanceToTargetLineMax));

						# NEZFireRange (No Escape Zone)
						me.NEZFireRange.setTranslation(0, math.clamp((me.distanceToTargetLineMax-me.distanceToTargetLineMin)-(me.myDLZ[2]*(me.distanceToTargetLineMax-me.distanceToTargetLineMin)/ me.MaxRadarRange)-100,me.distanceToTargetLineMin,me.distanceToTargetLineMax));

						me.NEZFireRange.show();
						return TRUE;
					}
				} elsif (me.selected_weapon.class == "GM" or me.selected_weapon.class == "M") {
					me.MaxFireRange.setTranslation(0, math.clamp((me.distanceToTargetLineMax-me.distanceToTargetLineMin)-(me.selected_weapon.max_fire_range_nm*(me.distanceToTargetLineMax-me.distanceToTargetLineMin)/ me.MaxRadarRange)-100,me.distanceToTargetLineMin,me.distanceToTargetLineMax));

					#MmiFireRange
					me.MinFireRange.setTranslation(0, math.clamp((me.distanceToTargetLineMax-me.distanceToTargetLineMin)-(me.selected_weapon.min_fire_range_nm*(me.distanceToTargetLineMax-me.distanceToTargetLineMin)/ me.MaxRadarRange)-100,me.distanceToTargetLineMin,me.distanceToTargetLineMax));

					me.NEZFireRange.hide();
					return TRUE;
				}
			}
		}
		return FALSE;
	},

	_displayBoreCross: func(bore_pos) {
		if (me.flightmode_cached == consts.FLIGHT_MODE_ATTACK and pylons.fcs.getSelectedWeapon() !=nil) {
			if (me.selected_weapon.type == CANNON_30MM or me.selected_weapon.type == CC422) { # if weapons selected
				me.boreCross.setTranslation(bore_pos);
				me.boreCross.show();
			} else {
				me.boreCross.hide();
			}
		} else {
			me.boreCross.hide();
		}
	}, # END _displayBoreCross()

	_displayWaypointCross: func(coord) {
		if (coord != nil) { #The aircraft should be flying ... This need to be done before in hud mode selection
			if (me.aircraft_position.direct_distance_to(coord)*M2NM<10) {
				me.WaypointCross.setTranslation(HudMath.getPosFromCoord(coord));
				me.displayWaypointCrossShow = TRUE;
				return;
			}
		}
	},

	_calcNextWaypointCoordinate: func() {
		if (me.fp.currentWP() != nil) {
			#Sometime you can set up an altitude to your waypoint. if it's the case we take it.
			me.NxtElevation = getprop("/autopilot/route-manager/route/wp[" ~ me.input.currentWp.getValue() ~ "]/altitude-m");

			#print("me.NxtWP_latDeg:",me.NxtWP_latDeg, " me.NxtWP_lonDeg:",me.NxtWP_lonDeg);
			#if the altitude isn't set, just take the ground alt.
			var Geo_Elevation = geo.elevation(me.fp.currentWP().lat , me.fp.currentWP().lon);
			Geo_Elevation = Geo_Elevation == nil ? 0: Geo_Elevation;
			#print("Geo_Elevation:",Geo_Elevation," me.NxtElevation:",me.NxtElevation);

			#if no altitude, then take ground alt
			if ( me.NxtElevation  != nil) {
			Geo_Elevation = me.NxtElevation  > Geo_Elevation ? me.NxtElevation : Geo_Elevation ;
			me.NXTWP.set_latlon(me.fp.currentWP().lat , me.fp.currentWP().lon ,  Geo_Elevation + 2);
			}

		}
	},

	_resetGunPos: func {
		me.gunPos   = [];
		for (i = 0;i < me.funnelParts*4;i+=1) {
		var tmp = [];
		for (var myloopy = 0;myloopy <= i+1;myloopy+=1) {
			append(tmp,nil);
		}
		append(me.gunPos, tmp);
		}
	},

	_makeVector: func (siz,content) {
		var vec = setsize([],siz*4);
		var k = 0;
		while(k<siz*4) {
			vec[k] = content;
			k += 1;
		}
		return vec;
	},

	_displayEEGS: func() {
		#note: this stuff is expensive like hell to compute, but..lets do it anyway.
		#var me.funnelParts = 40;#max 10
		me.wingspan = me.input.cannon_air_air_wingspan.getValue();
		var st = systime();
		me.eegsMe.dt = st-me.lastTime;
		if (me.eegsMe.dt > me.averageDt*3) {
			me.lastTime = st;
			me._resetGunPos();
			me.eegsGroup.removeAllChildren();
		} else {
			#printf("dt %05.3f",me.eegsMe.dt);
			me.lastTime = st;

			me.eegsMe.hdg   = me.input.hdgReal.getValue();
			me.eegsMe.pitch = me.input.pitch.getValue();
			me.eegsMe.roll  = me.input.roll.getValue();

			var hdp = {roll:me.eegsMe.roll, current_view_z_offset_m: me.input.z_offset_m.getValue()};


			me.eegsMe.ac = geo.aircraft_position();
			me.eegsMe.allow = 1;
			me.drawEEGSPipper = 0;
			me.drawEEGS300 = 0;
			me.drawEEGS600 = 0;
			me.strfRange = 4500 * M2FT;
			if (me.strf or me.hydra) {
				me.groundDistanceFT = nil;
				var l = 0;
				for (l = 0;l < me.funnelParts*4;l+=1) {
					# compute display positions of funnel on hud
					var pos = me.gunPos[l][0];
					if (pos == nil) {
						me.eegsMe.allow = 0;
					} else {
						var ac  = me.gunPos[l][0][1];
						pos     = me.gunPos[l][0][0];
						var el = geo.elevation(pos.lat(),pos.lon());
						if (el == nil) {
							el = 0;
						}

						if (l != 0 and el > pos.alt()) {
							var hitPos = geo.Coord.new(pos);
							hitPos.set_alt(el);
							me.groundDistanceFT = (el-pos.alt())*M2FT;#ac.direct_distance_to(hitPos)*M2FT;
							me.strfRange = hitPos.direct_distance_to(me.eegsMe.ac)*M2FT;
							l = l;
							break;
						}
					}
				}
				# compute display positions of pipper on hud
				if (me.eegsMe.allow and me.groundDistanceFT != nil) {
					for (var ll = l-1;ll <= l;ll+=1) {
						var ac    = me.gunPos[ll][0][1];
						var pos   = me.gunPos[ll][0][0];
						var pitch = me.gunPos[ll][0][2];

						me.eegsMe.posTemp = HudMath.getPosFromCoord(pos,ac);
						me.eegsMe.shellPosDist[ll] = ac.direct_distance_to(pos)*M2FT;
						me.eegsMe.shellPosX[ll] = me.eegsMe.posTemp[0];#me.eegsMe.xcS;
						me.eegsMe.shellPosY[ll] = me.eegsMe.posTemp[1];#me.eegsMe.ycS;

						if (l == ll and me.strfRange*FT2M < 4500) {
							var highdist = me.eegsMe.shellPosDist[ll];
							var lowdist = me.eegsMe.shellPosDist[ll-1];
							me.groundDistanceFT = me.groundDistanceFT/math.cos(90-pitch*D2R);
							me.eegsPipperX = HudMath.extrapolate(highdist-me.groundDistanceFT,lowdist,highdist,me.eegsMe.shellPosX[ll-1],me.eegsMe.shellPosX[ll]);
							me.eegsPipperY = HudMath.extrapolate(highdist-me.groundDistanceFT,lowdist,highdist,me.eegsMe.shellPosY[ll-1],me.eegsMe.shellPosY[ll]);
							me.drawEEGSPipper = 1;
						}
					}
				}
			} else {
				for (var l = 0;l < me.funnelParts;l+=1) {
					# compute display positions of funnel on hud
					var pos = me.gunPos[l][l+1];
					if (pos == nil) {
						me.eegsMe.allow = 0;
					} else {
						var ac  = me.gunPos[l][l][1];
						pos     = me.gunPos[l][l][0];

						var ps = HudMath.getPosFromCoord(pos, ac);
						me.eegsMe.xcS = ps[0];
						me.eegsMe.ycS = ps[1];
						me.eegsMe.shellPosDist[l] = ac.direct_distance_to(pos)*M2FT;
						me.eegsMe.shellPosX[l] = me.eegsMe.xcS;
						me.eegsMe.shellPosY[l] = me.eegsMe.ycS;
						if (me.designatedDistanceFT != nil and !me.drawEEGSPipper) {
						if (l != 0 and me.eegsMe.shellPosDist[l] >= me.designatedDistanceFT and me.eegsMe.shellPosDist[l]>me.eegsMe.shellPosDist[l-1]) {
							var highdist = me.eegsMe.shellPosDist[l];
							var lowdist = me.eegsMe.shellPosDist[l-1];
							var fractionX = HudMath.extrapolate(me.designatedDistanceFT,lowdist,highdist,me.eegsMe.shellPosX[l-1],me.eegsMe.shellPosX[l]);
							var fractionY = HudMath.extrapolate(me.designatedDistanceFT,lowdist,highdist,me.eegsMe.shellPosY[l-1],me.eegsMe.shellPosY[l]);
							me.eegsRightX[0] = fractionX;
							me.eegsRightY[0] = fractionY;
							me.drawEEGSPipper = 1;
						}
						}
						if (!me.drawEEGS300) {
						if (l != 0 and me.eegsMe.shellPosDist[l] >= 300*M2FT and me.eegsMe.shellPosDist[l]>me.eegsMe.shellPosDist[l-1]) {
							var highdist = me.eegsMe.shellPosDist[l];
							var lowdist = me.eegsMe.shellPosDist[l-1];
							var fractionX = HudMath.extrapolate(300*M2FT,lowdist,highdist,me.eegsMe.shellPosX[l-1],me.eegsMe.shellPosX[l]);
							var fractionY = HudMath.extrapolate(300*M2FT,lowdist,highdist,me.eegsMe.shellPosY[l-1],me.eegsMe.shellPosY[l]);
							me.eegsRightX[1] = fractionX;
							me.eegsRightY[1] = fractionY;
							me.drawEEGS300 = 1;
						}
						}
						if (!me.drawEEGS600) {
						if (l != 0 and me.eegsMe.shellPosDist[l] >= 600*M2FT and me.eegsMe.shellPosDist[l]>me.eegsMe.shellPosDist[l-1]) {
							var highdist = me.eegsMe.shellPosDist[l];
							var lowdist = me.eegsMe.shellPosDist[l-1];
							var fractionX = HudMath.extrapolate(600*M2FT,lowdist,highdist,me.eegsMe.shellPosX[l-1],me.eegsMe.shellPosX[l]);
							var fractionY = HudMath.extrapolate(600*M2FT,lowdist,highdist,me.eegsMe.shellPosY[l-1],me.eegsMe.shellPosY[l]);
							me.eegsRightX[2] = fractionX;
							me.eegsRightY[2] = fractionY;
							me.drawEEGS600 = 1;
						}
						}
					}
				}
			}
			if (me.eegsMe.allow and !(me.strf or me.hydra)) {
				# draw the funnel
				for (var k = 0;k<me.funnelParts;k+=1) {

					me.eegsLeftX[k]  = me.eegsMe.shellPosX[k];
					me.eegsLeftY[k]  = me.eegsMe.shellPosY[k];
				}
				me.eegsGroup.removeAllChildren();
				for (var i = 0; i < me.funnelParts-1; i+=1) {
					me.fnnl = me.eegsGroup.createChild("path")
						.setColor(COLOR_GREEN)
						.moveTo(me.eegsLeftX[i], me.eegsLeftY[i])
						.lineTo(me.eegsLeftX[i+1], me.eegsLeftY[i+1])
						.setStrokeLineWidth(4);
					if (i==0) {
						me.fnnl.setStrokeDashArray([5,5]);
					}
				}
				if (me.drawEEGSPipper) {
					me.EEGSdeg = math.max(0,HudMath.extrapolate(me.designatedDistanceFT*FT2M,1200,300,360,0))*D2R;
					me.EEGSdegPos = [math.sin(me.EEGSdeg)*40,40-math.cos(me.EEGSdeg)*40];

					#drawing mini and centra point
					me.eegsGroup.createChild("path")
							.moveTo(me.eegsRightX[0],me.eegsRightY[0])
							.lineTo(me.eegsRightX[0],me.eegsRightY[0])
							.moveTo(me.eegsRightX[0], me.eegsRightY[0]-40)
							.lineTo(me.eegsRightX[0], me.eegsRightY[0]-55)
							.moveTo(me.eegsRightX[0], me.eegsRightY[0]+40)
							.lineTo(me.eegsRightX[0], me.eegsRightY[0]+55)
							.moveTo(me.eegsRightX[0]-40, me.eegsRightY[0])
							.lineTo(me.eegsRightX[0]-55, me.eegsRightY[0])
							.moveTo(me.eegsRightX[0]+40, me.eegsRightY[0])
							.lineTo(me.eegsRightX[0]+55, me.eegsRightY[0])
							.setColor(COLOR_GREEN)
							.setStrokeLineWidth(4);

					#drawing mini and centra point
					if (me.designatedDistanceFT*FT2M <1200) {
					me.eegsGroup.createChild("path")
							.moveTo(me.eegsRightX[0],me.eegsRightY[0]-40)
							.lineTo(me.eegsRightX[0], me.eegsRightY[0]-55)
							.setCenter(me.eegsRightX[0],me.eegsRightY[0])
							.setColor(COLOR_GREEN)
							.setStrokeLineWidth(4)
							.setRotation(me.EEGSdeg);
					}

					if (me.EEGSdeg<180*D2R) {
						me.eegsGroup.createChild("path")
							.setColor(COLOR_GREEN)
							.moveTo(me.eegsRightX[0], me.eegsRightY[0]-40)
							.arcSmallCW(40,40,0,me.EEGSdegPos[0],me.EEGSdegPos[1])
							.setStrokeLineWidth(4);
					} elsif (me.EEGSdeg>=360*D2R) {
						me.eegsGroup.createChild("path")
							.setColor(COLOR_GREEN)
							.moveTo(me.eegsRightX[0], me.eegsRightY[0]-40)
							.arcSmallCW(40,40,0,0,80)
							.arcSmallCW(40,40,0,0,-80)
							.setStrokeLineWidth(4);
					} else {
						me.eegsGroup.createChild("path")
							.setColor(COLOR_GREEN)
							.moveTo(me.eegsRightX[0], me.eegsRightY[0]-40)
							.arcLargeCW(40,40,0,me.EEGSdegPos[0],me.EEGSdegPos[1])
							.setStrokeLineWidth(4);
					}
				}
				if (me.drawEEGS300 and !me.drawEEGSPipper) {
					var halfspan = math.atan2(me.wingspan*0.5,300)*R2D*HudMath.getPixelPerDegreeAvg(2.0);
					me.eegsGroup.createChild("path")
						.setColor(COLOR_GREEN)
						.moveTo(me.eegsRightX[1]-halfspan, me.eegsRightY[1])
						.horiz(halfspan*2)
						.setStrokeLineWidth(4);
				}
				if (me.drawEEGS600 and !me.drawEEGSPipper) {
					var halfspan = math.atan2(me.wingspan*0.5,600)*R2D*HudMath.getPixelPerDegreeAvg(2.0);
					me.eegsGroup.createChild("path")
						.setColor(COLOR_GREEN)
						.moveTo(me.eegsRightX[2]-halfspan, me.eegsRightY[2])
						.horiz(halfspan*2)
						.setStrokeLineWidth(4);
				}
				me.eegsGroup.update();
			}

			#Same Piper as the A/A it should be done in a function
			if (me.eegsMe.allow and (me.strf or me.hydra)) {
				me.eegsGroup.removeAllChildren();
				if (me.drawEEGSPipper and me.strfRange*FT2M <= 4000) {
					me.EEGSdeg = math.max(0,HudMath.extrapolate(me.strfRange*FT2M,2400,600,360,0))*D2R;
					me.EEGSdegPos = [math.sin(me.EEGSdeg)*40,40-math.cos(me.EEGSdeg)*40];

					#drawing mini line and centra point
					me.eegsGroup.createChild("path")
							.moveTo(me.eegsPipperX,me.eegsPipperY)
							.lineTo(me.eegsPipperX,me.eegsPipperY)
							.arcSmallCW(3, 3, 0, 3*2, 0)
							.arcSmallCW(3, 3, 0, -3*2, 0)
							.moveTo(me.eegsPipperX, me.eegsPipperY-40)
							.lineTo(me.eegsPipperX, me.eegsPipperY-55)
							.moveTo(me.eegsPipperX, me.eegsPipperY+40)
							.lineTo(me.eegsPipperX, me.eegsPipperY+55)
							.moveTo(me.eegsPipperX-40, me.eegsPipperY)
							.lineTo(me.eegsPipperX-55, me.eegsPipperY)
							.moveTo(me.eegsPipperX+40, me.eegsPipperY)
							.lineTo(me.eegsPipperX+55, me.eegsPipperY)
							.setColor(COLOR_GREEN)
							.setStrokeLineWidth(4);

							# Distance to target
					me.eegsGroup.createChild("text")
					.setColor(COLOR_GREEN)
					.setTranslation(MAX_LADDER_SPAN,-120)
					.setFontSize(FONT_SIZE_ALPHA)
					.setAlignment("left-center")
					.setText(sprintf("%.1f KM", me.strfRange*FT2M/1000));

						#drawing piper
					if (me.strfRange*FT2M <4000) {
					me.eegsGroup.createChild("path")
							.moveTo(me.eegsPipperX,me.eegsPipperY-40)
							.lineTo(me.eegsPipperX, me.eegsPipperY-55)
							.setCenter(me.eegsPipperX,me.eegsPipperY)
							.setColor(COLOR_GREEN)
							.setStrokeLineWidth(4)
							.setRotation(me.EEGSdeg);
					}

					if (me.EEGSdeg<180*D2R) {
						me.eegsGroup.createChild("path")
							.setColor(COLOR_GREEN)
							.moveTo(me.eegsPipperX, me.eegsPipperY-40)
							.arcSmallCW(40,40,0,me.EEGSdegPos[0],me.EEGSdegPos[1])
							.setStrokeLineWidth(4);
					} elsif (me.EEGSdeg>=360*D2R) {
						me.eegsGroup.createChild("path")
							.setColor(COLOR_GREEN)
							.moveTo(me.eegsPipperX, me.eegsPipperY-40)
							.arcSmallCW(40,40,0,0,80)
							.arcSmallCW(40,40,0,0,-80)
							.setStrokeLineWidth(4);
					} else {
						me.eegsGroup.createChild("path")
							.setColor(COLOR_GREEN)
							.moveTo(me.eegsPipperX, me.eegsPipperY-40)
							.arcLargeCW(40,40,0,me.EEGSdegPos[0],me.EEGSdegPos[1])
							.setStrokeLineWidth(4);
					}
				}
				me.eegsGroup.update();
			}
			#calc shell positions
			me.eegsMe.vel = me.input.uBody_fps.getValue() + 3363.0 ; #3363.0 = speed

			me.eegsMe.geodPos = aircraftToCart({x:-0, y:0, z: me.input.y_offset_m.getValue()});#position (meters) of gun in aircraft (x and z inverted)
			me.eegsMe.eegsPos.set_xyz(me.eegsMe.geodPos.x, me.eegsMe.geodPos.y, me.eegsMe.geodPos.z);
			me.eegsMe.altC = me.eegsMe.eegsPos.alt();

			me.eegsMe.rs = armament.AIM.rho_sndspeed(me.eegsMe.altC*M2FT);#simplified
			me.eegsMe.rho = me.eegsMe.rs[0];
			me.eegsMe.mass =  0.9369635/ armament.slugs_to_lbm;#0.9369635=lbs

			var multi = (me.strf or me.hydra) ? 4 : 1;
			for (var j = 0;j < me.funnelParts*multi;j+=1) {
				#calc new speed
				me.eegsMe.Cd = _drag(me.eegsMe.vel/ me.eegsMe.rs[1],0.193); #0.193=cd
				me.eegsMe.q = 0.5 * me.eegsMe.rho * me.eegsMe.vel * me.eegsMe.vel;
				me.eegsMe.deacc = (me.eegsMe.Cd * me.eegsMe.q * 0.007609) / me.eegsMe.mass; #0.007609=eda
				me.eegsMe.vel -= me.eegsMe.deacc * me.averageDt;
				me.eegsMe.speed_down_fps       = -math.sin(me.eegsMe.pitch * D2R) * (me.eegsMe.vel);
				me.eegsMe.speed_horizontal_fps = math.cos(me.eegsMe.pitch * D2R) * (me.eegsMe.vel);

				me.eegsMe.speed_down_fps += 9.81 *M2FT *me.averageDt;

				me.eegsMe.altC -= (me.eegsMe.speed_down_fps*me.averageDt)*FT2M;

				me.eegsMe.dist = (me.eegsMe.speed_horizontal_fps*me.averageDt)*FT2M;

				me.eegsMe.eegsPos.apply_course_distance(me.eegsMe.hdg, me.eegsMe.dist);
				me.eegsMe.eegsPos.set_alt(me.eegsMe.altC);

				me.old = me.gunPos[j];
				me.gunPos[j] = [[geo.Coord.new(me.eegsMe.eegsPos),me.eegsMe.ac, me.eegsMe.pitch]];
				for (var m = 0;m<j+1;m+=1) {
					append(me.gunPos[j], me.old[m]);
				}
				me.eegsMe.vel = math.sqrt(me.eegsMe.speed_down_fps*me.eegsMe.speed_down_fps+me.eegsMe.speed_horizontal_fps*me.eegsMe.speed_horizontal_fps);
				me.eegsMe.pitch = math.atan2(-me.eegsMe.speed_down_fps,me.eegsMe.speed_horizontal_fps)*R2D;
			}
		}
		me.eegsGroup.show();
	},

	_isInCanvas: func(x,y) {
		return abs(x)<me.MaxX and abs(y)<me.MaxY;
	},

	############## When pilot view is changed the whole scale needs to be redrawn ##########################
	_recalculateLadder: func() {
		me.ladder_group.removeAllChildren();
		for (var myladder = 5;myladder <= 90;myladder+=5) {
			var ladder_vert = HudMath.getPixelPerDegreeAvg(LADDER_SCALE)*myladder;
			if (myladder/10 == int(myladder/10)) {
				#Text bellow 0 left
				me.ladder_group.createChild("text")
				             .setColor(COLOR_GREEN)
				             .setAlignment("right-bottom")
				             .setTranslation(-MAX_LADDER_SPAN -10, ladder_vert)
				             .setFontSize(FONT_SIZE_LADDER)
				             .setText(myladder);
				#Text bellow 0 right
				me.ladder_group.createChild("text")
				             .setColor(COLOR_GREEN)
				             .setAlignment("left-bottom")
				             .setTranslation(MAX_LADDER_SPAN + 10, ladder_vert)
				             .setFontSize(FONT_SIZE_LADDER)
				             .setText(myladder);

				#Text above 0 left
				me.ladder_group.createChild("text")
				             .setColor(COLOR_GREEN)
				             .setAlignment("right-bottom")
				             .setTranslation(-MAX_LADDER_SPAN - 10, -ladder_vert + MAX_LADDER_SPAN/15)
				             .setFontSize(FONT_SIZE_LADDER)
				             .setText(myladder);
				#Text above 0 right
				me.ladder_group.createChild("text")
				             .setColor(COLOR_GREEN)
				             .setAlignment("left-bottom")
				             .setTranslation(MAX_LADDER_SPAN + 10, -ladder_vert + MAX_LADDER_SPAN/15)
				             .setFontSize(FONT_SIZE_LADDER)
				             .setText(myladder);
			}

			# half line below 0 (left part)
			me.ladder_group.createChild("path")
			             .setColor(COLOR_GREEN)
			             .moveTo(-MAX_LADDER_SPAN, ladder_vert)
			             .vert(-MAX_LADDER_SPAN/15)
			             .setStrokeLineWidth(4);

			me.ladder_group.createChild("path")
			             .setColor(COLOR_GREEN)
			             .moveTo(-MAX_LADDER_SPAN, ladder_vert)
			             .horiz(MAX_LADDER_SPAN*2/15)
			             .setStrokeLineWidth(4);
			me.ladder_group.createChild("path")
			             .setColor(COLOR_GREEN)
			             .moveTo(-abs(MAX_LADDER_SPAN - MAX_LADDER_SPAN*2/15*2), ladder_vert)
			             .horiz(MAX_LADDER_SPAN*2/15)
			             .setStrokeLineWidth(4);
			me.ladder_group.createChild("path")
			             .setColor(COLOR_GREEN)
			             .moveTo(-abs(MAX_LADDER_SPAN - MAX_LADDER_SPAN*2/15*4), ladder_vert)
			             .horiz(MAX_LADDER_SPAN*2/15)
			             .setStrokeLineWidth(4);

			# half line below 0 (right part)
			me.ladder_group.createChild("path")
			             .setColor(COLOR_GREEN)
			             .moveTo(MAX_LADDER_SPAN, ladder_vert)
			             .vert(-MAX_LADDER_SPAN/15)
			             .setStrokeLineWidth(4);

			me.ladder_group.createChild("path")
			             .setColor(COLOR_GREEN)
			             .moveTo(MAX_LADDER_SPAN, ladder_vert)
			             .horiz(-MAX_LADDER_SPAN*2/15)
			             .setStrokeLineWidth(4);
			me.ladder_group.createChild("path")
			             .setColor(COLOR_GREEN)
			             .moveTo(abs(MAX_LADDER_SPAN - MAX_LADDER_SPAN*2/15*2), ladder_vert)
			             .horiz(-MAX_LADDER_SPAN*2/15)
			             .setStrokeLineWidth(4);
			me.ladder_group.createChild("path")
			             .setColor(COLOR_GREEN)
			             .moveTo(abs(MAX_LADDER_SPAN - MAX_LADDER_SPAN*2/15*4), ladder_vert)
			             .horiz(-MAX_LADDER_SPAN*2/15)
			             .setStrokeLineWidth(4);

			# half line above 0 (left part)
			me.ladder_group.createChild("path")
			             .setColor(COLOR_GREEN)
			             .moveTo(-MAX_LADDER_SPAN, -ladder_vert)
			             .vert(MAX_LADDER_SPAN/15)
			             .setStrokeLineWidth(4);

			me.ladder_group.createChild("path")
			             .setColor(COLOR_GREEN)
			             .moveTo(-MAX_LADDER_SPAN, -ladder_vert)
			             .horiz(MAX_LADDER_SPAN/3*2)
			             .setStrokeLineWidth(4);

			# half line above (right part)
			me.ladder_group.createChild("path")
			             .setColor(COLOR_GREEN)
			             .moveTo(MAX_LADDER_SPAN, -ladder_vert)
			             .horiz(-MAX_LADDER_SPAN/3*2)
			             .setStrokeLineWidth(4);
			me.ladder_group.createChild("path")
			             .setColor(COLOR_GREEN)
			             .moveTo(MAX_LADDER_SPAN, -ladder_vert)
			             .vert(MAX_LADDER_SPAN/15)
			             .setStrokeLineWidth(4);
		}
	}, # END _recalculateladder
};

var _drag = func (Mach, _cd) {
	if (Mach < 0.7)
		return 0.0125 * Mach + _cd;
	elsif (Mach < 1.2)
		return 0.3742 * math.pow(Mach, 2) - 0.252 * Mach + 0.0021 + _cd;
	else
		return 0.2965 * math.pow(Mach, -1.1506) + _cd;
};

var _roundabout = func(x) {
	var y = x - int(x);
	return y < 0.5 ? int(x) : 1 + int(x) ;
};

var variantID = getprop("sim/variant-id");
var hud_pilot = nil;
if (variantID == consts.VARIANT_D) {
	hub_pilot = hud.HUD.new("hud_pilot", {"node": "vth_d.canvas", "texture": "canvasTex.png"});
} else {
	hud_pilot = hud.HUD.new("hud_pilot", {"node": "revi.canvasHUD", "texture": "hud.png"});
}
