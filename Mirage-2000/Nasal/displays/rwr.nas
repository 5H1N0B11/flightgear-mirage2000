print("*** LOADING rwr.nas ... ***");


var RWR_COLOR_BLUE = [0.2, 0.6, 1];
var COLOR_WHITE = [1, 1, 1];
var COLOR_YELLOW = [1, 1, 0.4]; # a bit to the white side - for text and symbols

var TICK_LENGTH_SHORT = 10;
var TICK_LENGTH_LONG = 20;

var LINE_WIDTH = 4;

var FONT_SIZE = 36;
var FONT_ASPECT_RATIO = 1;
var FONT_MONO_REGULAR = "LiberationFonts/LiberationMono-Regular.ttf";
var FONT_DIST = 24; # a relative value for the size of symbology around the threat text

var SCREEN_WIDTH = 768;
var SCREEN_HEIGHT = 576;

var DISPENSER_BOX_WIDTH = 60;
var DISPENSER_BOX_SEPARATION = 16;

var COLOR_LL_BACKGROUND_LIT = [0.2, 0.6, 1]; # same as for RWR_COLOR_BLUE
var COLOR_EM_BACKGROUND_LIT = [1, 0.6, 0.2]; #orange
var COLOR_INDICATORS_UNLIT = [0, 0, 0]; # black

var FONT_SIZE_INDICATORS = 32;
var LINE_WIDTH_INDICATORS = 1;


RWRCanvas = {
	new: func (_ident, root) {
		var rwr = {parents: [RWRCanvas]};
		rwr.max_icons = 12;
		rwr.radius = 0.8 * SCREEN_HEIGHT/2; # we want a bit of space around the circle
		rwr.inner_radius = rwr.radius*0.30; # where to put the high threat symbols
		rwr.outer_radius = rwr.radius*0.75; # where to put the lower threat symbols
		rwr.circle_radius_middle = rwr.radius*0.5;
		rwr.fadeTime = 7; #seconds
		rwr.AIRCRAFT_UNKNOWN  = "U";
		rwr.ASSET_AI          = "AI";
		rwr.AIRCRAFT_SEARCH   = "S";

		rwr.rwr_circles_group = root.createChild("group", "rwr_circles_group")
		                            .setTranslation(SCREEN_WIDTH/2, SCREEN_HEIGHT/2); # in the middle of the screen
		rwr._createRWRCircles();
		rwr.dispenser_group = root.createChild("group", "dispenser_group")
		                          .setTranslation(SCREEN_WIDTH-DISPENSER_BOX_WIDTH-DISPENSER_BOX_SEPARATION, 6*DISPENSER_BOX_SEPARATION);
		# rwr._createDispenserIndicators();

		rwr.shownList = [];

		# recipient that will be registered on the global transmitter and connect this
		# subsystem to allow subsystem notifications to be received
		rwr.recipient = emesary.Recipient.new(_ident);
		rwr.recipient.parent_obj = rwr;

		rwr.recipient.Receive = func(notification)
		{
			if (notification.NotificationType == "FrameNotification" and notification.FrameCount == 2)
			{
				me.parent_obj._update(radar_system.f16_rwr.vector_aicontacts_threats);
				return emesary.Transmitter.ReceiptStatus_OK;
			}
			return emesary.Transmitter.ReceiptStatus_NotProcessed;
		};
		emesary.GlobalTransmitter.Register(rwr.recipient);

		return rwr;
	},

	_createRWRCircles: func() {
		me.rwr_circles_group.createChild("path") # cross in the middle
		                    .moveTo(-TICK_LENGTH_SHORT, 0)
		                    .lineTo(TICK_LENGTH_SHORT, 0)
		                    .moveTo(0, -TICK_LENGTH_SHORT)
		                    .lineTo(0, TICK_LENGTH_SHORT)
		                    .setStrokeLineWidth(LINE_WIDTH)
		                    .setColor(COLOR_WHITE);
		me.rwr_circles_group.createChild("path") # middle circle
		                    .moveTo(-me.circle_radius_middle, 0)
		                    .arcSmallCW(me.circle_radius_middle, me.circle_radius_middle, 0, me.circle_radius_middle*2, 0)
		                    .arcSmallCW(me.circle_radius_middle, me.circle_radius_middle, 0, -me.circle_radius_middle*2, 0)
		                    .setStrokeLineWidth(LINE_WIDTH)
		                    .setColor(RWR_COLOR_BLUE);
		me.rwr_circles_group.createChild("path") # outer circle
		                    .moveTo(-me.radius, 0)
		                    .arcSmallCW(me.radius, me.radius, 0, me.radius*2, 0)
		                    .arcSmallCW(me.radius, me.radius, 0, -me.radius*2, 0)
		                    .setStrokeLineWidth(LINE_WIDTH)
		                    .setColor(COLOR_WHITE);
		me.rwr_circles_group.createChild("path") # large ticks around the circle
		                    .moveTo(me.radius, 0)
		                    .horiz(TICK_LENGTH_LONG) # 90
		                    .moveTo(-me.radius, 0)
		                    .horiz(-TICK_LENGTH_LONG) # 270
		                    .moveTo(0, me.radius)
		                    .vert(TICK_LENGTH_LONG) # 180
		                    .moveTo(0, -me.radius)
		                    .vert(-TICK_LENGTH_LONG) # 0 / 360
		                    .setStrokeLineWidth(LINE_WIDTH * 2)
		                    .setColor(COLOR_WHITE);
		var rad_30 = 30 * D2R;
		var rad_60 = 60 * D2R;
		me.rwr_circles_group.createChild("path") # ticks like clock at outer ring
			.moveTo(me.radius*math.cos(rad_30),me.radius*math.sin(-rad_30))
			.lineTo((me.radius+TICK_LENGTH_SHORT)*math.cos(rad_30),(me.radius+TICK_LENGTH_SHORT)*math.sin(-rad_30))
			.moveTo(me.radius*math.cos(rad_60),me.radius*math.sin(-rad_60))
			.lineTo((me.radius+TICK_LENGTH_SHORT)*math.cos(rad_60),(me.radius+TICK_LENGTH_SHORT)*math.sin(-rad_60))
			.moveTo(me.radius*math.cos(rad_30),me.radius*math.sin(rad_30))
			.lineTo((me.radius+TICK_LENGTH_SHORT)*math.cos(rad_30),(me.radius+TICK_LENGTH_SHORT)*math.sin(rad_30))
			.moveTo(me.radius*math.cos(rad_60),me.radius*math.sin(rad_60))
			.lineTo((me.radius+TICK_LENGTH_SHORT)*math.cos(rad_60),(me.radius+TICK_LENGTH_SHORT)*math.sin(rad_60))

			.moveTo(-me.radius*math.cos(rad_30),me.radius*math.sin(-rad_30))
			.lineTo(-(me.radius+TICK_LENGTH_SHORT)*math.cos(rad_30),(me.radius+TICK_LENGTH_SHORT)*math.sin(-rad_30))
			.moveTo(-me.radius*math.cos(rad_60),me.radius*math.sin(-rad_60))
			.lineTo(-(me.radius+TICK_LENGTH_SHORT)*math.cos(rad_60),(me.radius+TICK_LENGTH_SHORT)*math.sin(-rad_60))
			.moveTo(-me.radius*math.cos(rad_30),me.radius*math.sin(rad_30))
			.lineTo(-(me.radius+TICK_LENGTH_SHORT)*math.cos(rad_30),(me.radius+TICK_LENGTH_SHORT)*math.sin(rad_30))
			.moveTo(-me.radius*math.cos(rad_60),me.radius*math.sin(rad_60))
			.lineTo(-(me.radius+TICK_LENGTH_SHORT)*math.cos(rad_60),(me.radius+TICK_LENGTH_SHORT)*math.sin(rad_60))
			.setStrokeLineWidth(LINE_WIDTH)
			.setColor(COLOR_WHITE);
		me.texts = setsize([], me.max_icons);
		for (var i = 0; i < me.max_icons; i+=1) {
			me.texts[i] = me.rwr_circles_group.createChild("text")
			                           .setText("00")
			                           .setAlignment("center-center")
			                           .setColor(COLOR_YELLOW)
			                           .setFontSize(FONT_SIZE, FONT_ASPECT_RATIO)
			                           .setFont(FONT_MONO_REGULAR)
			                           .hide();
		}
		me.symbol_hat = setsize([], me.max_icons);
		for (var i = 0; i < me.max_icons; i+=1) {
			me.symbol_hat[i] = me.rwr_circles_group.createChild("path")
					.moveTo(0,-FONT_DIST)
					.lineTo(FONT_DIST*0.7,-FONT_DIST*0.5)
					.moveTo(0,-FONT_DIST)
					.lineTo(-FONT_DIST*0.7,-FONT_DIST*0.5)
					.setStrokeLineWidth(LINE_WIDTH)
					.setColor(COLOR_YELLOW)
					.hide();
		}
		me.symbol_launch = setsize([], me.max_icons);
		for (var i = 0; i < me.max_icons; i+=1) {
			me.symbol_launch[i] = me.rwr_circles_group.createChild("path")
					.moveTo(FONT_DIST*1.2, 0)
					.arcSmallCW(FONT_DIST*1.2, FONT_DIST*1.2, 0, -FONT_DIST*2.4, 0)
					.arcSmallCW(FONT_DIST*1.2, FONT_DIST*1.2, 0, FONT_DIST*2.4, 0)
					.setStrokeLineWidth(LINE_WIDTH)
					.setColor(COLOR_YELLOW)
					.hide();
		}
		me.symbol_new = setsize([], me.max_icons);
		for (var i = 0; i < me.max_icons; i+=1) {
			me.symbol_new[i] = me.rwr_circles_group.createChild("path")
					.moveTo(FONT_DIST*1.2, 0)
					.arcSmallCCW(FONT_DIST*1.2, FONT_DIST*1.2, 0, -FONT_DIST*2.4, 0)
					.setStrokeLineWidth(LINE_WIDTH)
					.setColor(COLOR_YELLOW)
					.hide();
		}
		me.symbol_priority = me.rwr_circles_group.createChild("path")
					.moveTo(0, FONT_DIST*1.2)
					.lineTo(FONT_DIST*1.2, 0)
					.lineTo(0,-FONT_DIST*1.2)
					.lineTo(-FONT_DIST*1.2,0)
					.lineTo(0, FONT_DIST*1.2)
					.setStrokeLineWidth(LINE_WIDTH)
					.setColor(COLOR_YELLOW)
					.hide();
	},

	_createDispenserIndicators: func {
		# Lance-Leurres (Decoy Dispenser)
		me.ll_box  = me.dispenser_group.createChild("path", "ll_box")
		                               .setColor(COLOR_LL_BACKGROUND_LIT)
		                               .setColorFill(COLOR_INDICATORS_UNLIT)
		                               .rect(0, 0,
		                                     DISPENSER_BOX_WIDTH, DISPENSER_BOX_WIDTH)
		                               .setStrokeLineWidth(LINE_WIDTH_INDICATORS);
		me.ll_text = me.dispenser_group.createChild("text", "ll_text")
		                               .setFontSize(FONT_SIZE_INDICATORS, FONT_ASPECT_RATIO)
		                               .setFont(FONT_MONO_REGULAR)
		                               .setColor(COLOR_LL_BACKGROUND_LIT)
		                               .setAlignment("center-center")
		                               .setText("LL")
		                               .setTranslation(DISPENSER_BOX_WIDTH/2,
		                                               DISPENSER_BOX_WIDTH/2);

		# Contremesures Électromagnétiques/Chaff
		var add_down = DISPENSER_BOX_WIDTH + DISPENSER_BOX_SEPARATION;
		me.em_box  = me.dispenser_group.createChild("path", "em_box")
		                               .setColor(COLOR_EM_BACKGROUND_LIT)
		                               .setColorFill(COLOR_INDICATORS_UNLIT)
		                               .rect(0, add_down,
		                                     DISPENSER_BOX_WIDTH, DISPENSER_BOX_WIDTH)
		                               .setStrokeLineWidth(LINE_WIDTH_INDICATORS);
		me.em_text = me.dispenser_group.createChild("text", "em_text")
		                               .setFontSize(FONT_SIZE_INDICATORS, FONT_ASPECT_RATIO)
		                               .setFont(FONT_MONO_REGULAR)
		                               .setColor(COLOR_EM_BACKGROUND_LIT)
		                               .setAlignment("center-center")
		                               .setText("EM")
		                               .setTranslation(DISPENSER_BOX_WIDTH/2,
		                                               add_down + DISPENSER_BOX_WIDTH/2);
		# IR (Contremesures Infrarouges/Flares)
		var add_down = 2*(DISPENSER_BOX_WIDTH + DISPENSER_BOX_SEPARATION);
		me.ir_box  = me.dispenser_group.createChild("path", "ir_box")
		                               .setColor(COLOR_EM_BACKGROUND_LIT)
		                               .setColorFill(COLOR_INDICATORS_UNLIT)
		                               .rect(0, add_down,
		                                     DISPENSER_BOX_WIDTH, DISPENSER_BOX_WIDTH)
		                               .setStrokeLineWidth(LINE_WIDTH_INDICATORS);
		me.ir_text = me.dispenser_group.createChild("text", "ir_text")
		                               .setFontSize(FONT_SIZE_INDICATORS, FONT_ASPECT_RATIO)
		                               .setFont(FONT_MONO_REGULAR)
		                               .setColor(COLOR_EM_BACKGROUND_LIT)
		                               .setAlignment("center-center")
		                               .setText("IR")
		                               .setTranslation(DISPENSER_BOX_WIDTH/2,
		                                               add_down + DISPENSER_BOX_WIDTH/2);
		# EO (Contremesures Électro-optiques/Electro-Optical
		var add_down = 3*(DISPENSER_BOX_WIDTH + DISPENSER_BOX_SEPARATION);
		me.eo_box  = me.dispenser_group.createChild("path", "eo_box")
		                               .setColor(COLOR_EM_BACKGROUND_LIT)
		                               .setColorFill(COLOR_INDICATORS_UNLIT)
		                               .rect(0, add_down,
		                                     DISPENSER_BOX_WIDTH, DISPENSER_BOX_WIDTH)
		                               .setStrokeLineWidth(LINE_WIDTH_INDICATORS);
		me.eo_text = me.dispenser_group.createChild("text", "eo_text")
		                               .setFontSize(FONT_SIZE_INDICATORS, FONT_ASPECT_RATIO)
		                               .setFont(FONT_MONO_REGULAR)
		                               .setColor(COLOR_EM_BACKGROUND_LIT)
		                               .setAlignment("center-center")
		                               .setText("EO")
		                               .setTranslation(DISPENSER_BOX_WIDTH/2,
		                                               add_down + DISPENSER_BOX_WIDTH/2);
	},

	_assignSepSpot: func {
		# me.dev        angle_deg
		# me.sep_spots  0 to 2  45, 20, 15
		# me.threat     0 to 2
		# me.sep_angles
		# return   me.dev,  me.threat
		me.newdev = me.dev;
		me._assignIdealSepSpot();
		me.plus = me.sep_angles[me.threat];
		me.dir  = 0;
		me.count = 1;
		while(me.sep_spots[me.threat][me.spot] and me.count < size(me.sep_spots[me.threat])) {

			if (me.dir == 0) me.dir = 1;
			elsif (me.dir > 0) me.dir = -me.dir;
			elsif (me.dir < 0) me.dir = -me.dir+1;

			#printf("%2s: Spot %d taken. Trying %d direction.",me.typ, me.spot, me.dir);

			me.newdev = me.dev + me.plus * me.dir;

			me._assignIdealSepSpot();
			me.count += 1;
		}

		me.sep_spots[me.threat][me.spot] += 1;

		# finished assigning spot
		#printf("%2s: Spot %d assigned. Ring=%d",me.typ, me.spot, me.threat);
		me.dev = me.spot * me.plus;
		if (me.threat == 0) {
			me.threat = me.sep1_radius;
		} elsif (me.threat == 1) {
			me.threat = me.sep2_radius;
		} elsif (me.threat == 2) {
			me.threat = me.sep3_radius;
		}
	},

	_assignIdealSepSpot: func {
		me.spot = math.round(geo.normdeg(me.newdev)/me.sep_angles[me.threat]);
		if (me.spot >= size(me.sep_spots[me.threat])) me.spot = 0;
	},
	
	_update: func (list) {
		me.sep = 0; # not yet implemented - in F16 getprop("f16/ews/rwr-separate");
		me.showUnknowns = 1;
		me.elapsed = getprop("sim/time/elapsed-sec");
		me.pri5 = 0;  #only used to align with F16
		var sorter = func(a, b) {
			if(a[1] > b[1]){
				return -1; # A should before b in the returned vector
			}elsif(a[1] == b[1]){
				return 0; # A is equivalent to b
			}else{
				return 1; # A should after b in the returned vector
			}
		}
		me.sortedlist = sort(list, sorter);

		me.sep_spots = [[0,0,0,0,0,0,0,0], #45 degs  8
						[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], # 20 degs  18
						[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]; # 15 degs  24
		me.sep_angles = [45,20,15];

		me.newList = [];
		me.i = 0;
		me.prio = 0;
		me.newsound = 0;
		me.priCount = 0; # only added to align with F16 - not used
		me.priFlash = 0; # only added to align with F16 - not used
		me.unkFlash = 0; # aligned with F16 - although in the M2000 it is a sound not a flash
		foreach(me.contact; me.sortedlist) {
			me.dbEntry = radar_system.getDBEntry(me.contact[0].getModel());
			me.typ = me.dbEntry.rwrCode;
			if (me.i > me.max_icons-1) {
				break;
			}
			if (me.typ == nil) {
				me.typ = me.AIRCRAFT_UNKNOWN;
				if (!me.showUnknowns) {
					me.unkFlash = 1;
					continue;
				}
			}
			if (me.typ == me.ASSET_AI) {
				if (!me.showUnknowns) {
					#me.unkFlash = 1; # We don't flash for AI, that would just be distracting
					continue;
				}
			}
			if (me.contact[0].get_range() > 170) { # deviates from F16, which has 150
				continue;
			}

			me.threat = me.contact[1];

			if (me.threat <= 0) {
				continue;
			}

			if (me.pri5 and me.priCount >= 5) {
				me.priFlash = 1;
				continue;
			}
			me.priCount += 1;

			if (!me.sep) {

				if (me.threat > 0.5 and me.typ != me.AIRCRAFT_UNKNOWN and me.typ != me.AIRCRAFT_SEARCH) {
					me.threat = me.inner_radius;# inner circle
				} else {
					me.threat = me.outer_radius;# outer circle
				}

				me.dev = -me.contact[2]+90;
			} else {
				me.dev = -me.contact[2]+90;

				if (me.threat > 0.5 and me.typ != me.AIRCRAFT_UNKNOWN and me.typ != me.AIRCRAFT_SEARCH) {
					me.threat = 0;
				} elsif (me.threat > 0.25) {
					me.threat = 1;
				} else {
					me.threat = 2;
				}
				me._assignSepSpot();
			}

			me.x = math.cos(me.dev*D2R)*me.threat;
			me.y = -math.sin(me.dev*D2R)*me.threat;
			me.texts[me.i].setTranslation(me.x,me.y);
			me.texts[me.i].setText(me.typ);
			me.texts[me.i].show();
			if (me.prio == 0 and me.typ != me.ASSET_AI and me.typ != me.AIRCRAFT_UNKNOWN) {#
				me.symbol_priority.setTranslation(me.x,me.y);
				me.symbol_priority.show();
				me.prio = 1;
			}
			if (me.contact[0].getType() == armament.AIR) {
				#air-borne
				me.symbol_hat[me.i].setTranslation(me.x,me.y);
				me.symbol_hat[me.i].show();
			} else {
				me.symbol_hat[me.i].hide();
			}
			if (me.contact[0].get_Callsign()==getprop("sound/rwr-launch") and 10*(me.elapsed-int(me.elapsed))>5) {#blink 2Hz
				me.symbol_launch[me.i].setTranslation(me.x,me.y);
				me.symbol_launch[me.i].show();
			} else {
				me.symbol_launch[me.i].hide();
			}
			me.popupNew = me.elapsed;
			foreach(me.old; me.shownList) {
				if(me.old[0].getUnique()==me.contact[0].getUnique()) {
					me.popupNew = me.old[1];
					break;
				}
			}
			if (me.popupNew == me.elapsed) {
				me.newsound = 1;
			}
			if (me.popupNew > me.elapsed-me.fadeTime) {
				me.symbol_new[me.i].setTranslation(me.x,me.y);
				me.symbol_new[me.i].show();
				me.symbol_new[me.i].update();
			} else {
				me.symbol_new[me.i].hide();
			}
			#printf("display %s %d",contact[0].get_Callsign(), me.threat);
			append(me.newList, [me.contact[0],me.popupNew]);
			me.i += 1;
		}
		me.shownList = me.newList;
		for (;me.i<me.max_icons;me.i+=1) {
			me.texts[me.i].hide();
			me.symbol_hat[me.i].hide();
			me.symbol_new[me.i].hide();
			me.symbol_launch[me.i].hide();
		}
		if (me.prio == 0) {
			me.symbol_priority.hide();
		}
		if (me.newsound == 1) setprop("sound/rwr-new", !getprop("sound/rwr-new"));
		setprop("sound/rwr-pri", me.prio);
		setprop("sound/rwr-unk", me.unkFlash);
	},
};
var rwr = nil;
var cv = nil;

var setGroup = func (root) {
	root.createChild("path").horiz(SCREEN_WIDTH).vert(SCREEN_HEIGHT).horiz(-SCREEN_WIDTH).vert(-SCREEN_HEIGHT).setColorFill(0,0,0).setColor(0,0,0);
	rwr = RWRCanvas.new("RWRCanvas",root);
};
