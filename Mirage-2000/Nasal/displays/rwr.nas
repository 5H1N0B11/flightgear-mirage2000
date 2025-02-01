print("*** LOADING rwr.nas ... ***");

var FALSE = 0;
var TRUE = 1;

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
var COLOR_EM_BACKGROUND_LIT = [1, 0.6, 0.2]; # orange
var COLOR_INDICATORS_UNLIT = [0, 0, 0]; # black

var FONT_SIZE_INDICATORS = 32;
var LINE_WIDTH_INDICATORS = 1;

# flare/chaff values can change every 0.5 seconds -> cf. weapons.nas
# and sounds etc. for M2000 also have a length of 0.5 or multiples thereof
# => let the updates be done in increments of ca. every 0.5 seconds
var UPDATE_INC = 0.5;


RWRCanvas = {
	new: func (_ident, root) {
		var rwr = {parents: [RWRCanvas]};

		rwr.input = {
			flares                    : "rotors/main/blade[3]/flap-deg", # see weapons.nas
			# chaff                     : "rotors/main/blade[3]/position-deg", # not needed because same as flares
			cm_remaining              : "/ai/submodels/submodel[7]/count",
			semiactive_callsign       : "payload/armament/MAW-semiactive-callsign",
			launch_callsign           : "sound/rwr-launch",
			sound_rwr_threat_new      : "sound/rwr-threat-new",
			sound_rwr_threat_stt      : "sound/rwr-threat-stt",
			sound_rwr_maw_semi_active : "sound/rwr-maw-semi-active",
			sound_rwr_maw_active      : "sound/rwr-maw-active"
		};

		foreach(var name; keys(rwr.input)) {
			rwr.input[name] = props.globals.getNode(rwr.input[name], 1);
		}

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
		rwr._createRWRSymbols();

		rwr.dispenser_group = root.createChild("group", "dispenser_group")
		                          .setTranslation(SCREEN_WIDTH-DISPENSER_BOX_WIDTH-DISPENSER_BOX_SEPARATION, 6*DISPENSER_BOX_SEPARATION);
		rwr._createDispenserIndicators();

		rwr.prev_contacts = [];
		rwr.prev_stt = [];

		rwr.last_update_inc = 0;
		rwr.alternated = FALSE; # toggles every ca. UPDATE_INC seconds between TRUE and FALSE

		rwr.recipient = emesary.Recipient.new(_ident);
		rwr.recipient.parent_obj = rwr;

		rwr.recipient.Receive = func(notification) {
			if (notification.NotificationType == "FrameNotification") {
				me.parent_obj._update(notification);
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
	},
	_createRWRSymbols: func() {
		me.texts = setsize([], me.max_icons);
		for (var i = 0; i < me.max_icons; i+=1) {
			me.texts[i] = me.rwr_circles_group.createChild("text")
			                           .setAlignment("center-center")
			                           .setColor(COLOR_YELLOW)
			                           .setFontSize(FONT_SIZE, FONT_ASPECT_RATIO)
			                           .setFont(FONT_MONO_REGULAR)
			                           .hide();
			me.texts[i].enableUpdate();
			me.texts[i].updateText("00");
		}

		me.symbol_hat = setsize([], me.max_icons); # missile
		for (var i = 0; i < me.max_icons; i+=1) {
			me.symbol_hat[i] = me.rwr_circles_group.createChild("path")
					.moveTo(0, -FONT_DIST)
					.lineTo(FONT_DIST*0.7, -FONT_DIST*0.5)
					.moveTo(0, -FONT_DIST)
					.lineTo(-FONT_DIST*0.7, -FONT_DIST*0.5)
					.setStrokeLineWidth(LINE_WIDTH)
					.setColor(COLOR_YELLOW)
					.hide();
		}

		me.symbol_chevron = setsize([], me.max_icons); # STT / spike
		for (var i = 0; i < me.max_icons; i+=1) {
			me.symbol_chevron[i] = me.rwr_circles_group.createChild("path")
					.moveTo(0, FONT_DIST)
					.lineTo(FONT_DIST*0.7, FONT_DIST*0.5)
					.moveTo(0, FONT_DIST)
					.lineTo(-FONT_DIST*0.7, FONT_DIST*0.5)
					.setStrokeLineWidth(LINE_WIDTH)
					.setColor(COLOR_YELLOW)
					.hide();
		}
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

	_update: func (notification) {
		me.elapsed = notification.getproper("elapsed_seconds");
		if (me.elapsed - me.last_update_inc >= UPDATE_INC) {
			me.last_update_inc = me.elapsed;
			if (me.alternated == TRUE) {
				me.alternated = FALSE;
			} else {
				me.alternated = TRUE;
			}
		} else {
			return;
		}
		me._updateCounterMeasures();

		me.show_unknowns = 1; # does not change cf. https://github.com/5H1N0B11/flightgear-mirage2000/issues/244

		me.semi_callsign = me.input.semiactive_callsign.getValue();
		me.launch_callsign = me.input.launch_callsign.getValue();
		me.has_maw_active = FALSE;
		me.has_maw_semi_active = FALSE;
		if (me.launch_callsign != nil and me.launch_callsign != '') {
			me.has_maw_active = TRUE;
		}
		if (me.semi_callsign != nil and me.semi_callsign != '') {
			me.has_maw_semi_active = TRUE;
		}

		var sorter = func(a, b) {
			if (a[1] > b[1]) {
				return -1; # A should before b in the returned vector
			} elsif (a[1] == b[1]) {
				return 0; # A is equivalent to b
			} else {
				return 1; # A should after b in the returned vector
			}
		}
		me.sorted_list = sort(radar_system.f16_rwr.vector_aicontacts_threats, sorter);

		me.new_contacts = [];
		me.new_stt = [];
		me.i = 0;
		me.has_new_threat = FALSE;
		me.has_new_stt = FALSE;
		foreach(me.contact; me.sorted_list) {
			me.dbEntry = radar_system.getDBEntry(me.contact[0].getModel());
			me.typ = me.dbEntry.rwrCode;
			# first exclude what does not need to be shown
			if (me.i > me.max_icons-1) {
				break;
			}
			if (me.typ == nil) {
				me.typ = me.AIRCRAFT_UNKNOWN;
				if (!me.show_unknowns) {
					continue;
				}
			}
			if (me.typ == me.ASSET_AI) {
				if (!me.show_unknowns) {
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

			# now we know it should be shown
			me.is_blinking = FALSE;
			if (me.has_maw_active and me.launch_callsign == me.contact[0].get_Callsign()) {
				me.is_blinking = TRUE;
			} else if (me.has_maw_semi_active and me.semi_callsign == me.contact[0].get_Callsign()) {
				me.is_blinking = TRUE;
			}
			if (me.threat > 0.5 and me.typ != me.AIRCRAFT_UNKNOWN and me.typ != me.AIRCRAFT_SEARCH) {
				me.threat = me.inner_radius; # inner circle
			} else {
				me.threat = me.outer_radius; # outer circle
			}
			me.dev = -me.contact[2]+90;

			me.x = math.cos(me.dev*D2R)*me.threat;
			me.y = -math.sin(me.dev*D2R)*me.threat;
			me.texts[me.i].setTranslation(me.x,me.y);
			me.texts[me.i].updateText(me.typ);
			me.symbol_chevron[me.i].setTranslation(me.x,me.y);
			me.symbol_hat[me.i].setTranslation(me.x,me.y);

			if (me.is_blinking == TRUE and me.alternated == TRUE) {
				me.texts[me.i].show();
				me.symbol_chevron[me.i].show();
				me.symbol_hat[me.i].show();
			} else if (me.is_blinking == TRUE and me.alternated == FALSE) {
				me.texts[me.i].hide();
				me.symbol_chevron[me.i].hide();
				me.symbol_hat[me.i].hide();
			} else {
				me.texts[me.i].show();
				me.symbol_hat[me.i].hide();
				if (me.contact[0].isSpikingMe()) {
					me.symbol_chevron[me.i].show();
					append(me.new_stt, me.contact[0]);
					if (me.has_new_stt == FALSE) {
						foreach (me.old; me.prev_stt) {
							if (me.old.getUnique()==me.contact[0].getUnique()) {
								me.has_new_stt = TRUE;
								break;
							}
						}
					}
				} else {
					me.symbol_chevron[me.i].hide();
				}
			}
			# check whether new threat
			if (me.has_new_threat == FALSE) {
				foreach (me.old; me.prev_contacts) {
					if (me.old.getUnique()==me.contact[0].getUnique()) {
						me.has_new_threat = TRUE;
						break;
					}
				}
			}
			append(me.new_contacts, me.contact[0]);
			me.i += 1;
		}
		# hide every symbol, which is not needed
		for (;me.i<me.max_icons;me.i+=1) {
			me.texts[me.i].hide();
			me.symbol_hat[me.i].hide();
			me.symbol_chevron[me.i].hide();
		}

		me.prev_contacts = me.new_contacts; # the prev_contacts will be the "old" one in next call to _update
		me.prev_stt = me.new_stt;

		me.input.sound_rwr_threat_new.setValue(me.has_new_threat);
		me.input.sound_rwr_threat_stt.setValue(me.has_new_stt);

		me.input.sound_rwr_maw_active.setValue(me.has_maw_active);
		if (me.has_maw_active == FALSE and me.has_maw_semi_active == TRUE) {
			me.input.sound_rwr_maw_semi_active.setValue(TRUE);
		} else {
			me.input.sound_rwr_maw_semi_active.setValue(FALSE);
		}
	},

	_updateCounterMeasures: func() {
		# dispensing counter measures
		if (me.input.flares.getValue() == 0) {
			me.ll_box.setColor(COLOR_LL_BACKGROUND_LIT);
			me.ll_box.setColorFill(COLOR_INDICATORS_UNLIT);
			me.ll_text.setColor(COLOR_LL_BACKGROUND_LIT);
		} else {
			me.ll_box.setColor(COLOR_INDICATORS_UNLIT);
			me.ll_box.setColorFill(COLOR_LL_BACKGROUND_LIT);
			me.ll_text.setColor(COLOR_INDICATORS_UNLIT);
		}
		# remaining counter measures
		me.cm_background_line = COLOR_EM_BACKGROUND_LIT;
		me.cm_background_fill = COLOR_INDICATORS_UNLIT;
		if (me.input.cm_remaining.getValue() == 0) {
			me.cm_background_line = COLOR_INDICATORS_UNLIT;
			me.cm_background_fill = COLOR_EM_BACKGROUND_LIT;
		} else if (me.input.cm_remaining.getValue() <= 20) {
			if (me.alternated == TRUE) {
				me.cm_background_line = COLOR_INDICATORS_UNLIT;
				me.cm_background_fill = COLOR_EM_BACKGROUND_LIT;
			}
		}
		me.em_box.setColor(me.cm_background_line);
		me.em_box.setColorFill(me.cm_background_fill);
		me.em_text.setColor(me.cm_background_line);
		me.ir_box.setColor(me.cm_background_line);
		me.ir_box.setColorFill(me.cm_background_fill);
		me.ir_text.setColor(me.cm_background_line);
		# eo_box and eo_text stays the same (not implemented)
	},
};

var rwr = nil;
var cv = nil;

var setGroup = func (root) {
	root.createChild("path").horiz(SCREEN_WIDTH).vert(SCREEN_HEIGHT).horiz(-SCREEN_WIDTH).vert(-SCREEN_HEIGHT).setColorFill(0,0,0).setColor(0,0,0);
	rwr = RWRCanvas.new("RWRCanvas",root);
};
