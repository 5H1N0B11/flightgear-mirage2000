# This module makes it possible to coordinate more than one screen, which again has one or several independent pages.
# The origin of this file is from a file called the same in https://github.com/NikolaiVChr/f16:
#    https://github.com/NikolaiVChr/f16/blob/master/Nasal/MFD/display-system.nas as per 0d480e0
#
# As of Feb 2025 the display system is only used for the right MFD and therefore functionality has been cut down.
#
# ---------
# Page:
# * Each page has the following functions:
#    * new:
#    * setup: called once and creates the canvas elements
#    * enter: what happens when the page is called and displayed
#             Typically resetting controls (me.device.resetControls();) and then
#             assign (me.device.controls["OSB3"].setControlText("TEST");)
#    * controlAction: what should happen if a contol is pressed
#    * update: redraw upon notification
#    * exit: clean-up
#    * links: {} -> dictionary of key=OSB-button and value = name of page to navigate to
#                          (this works because of line "me.device.controlAction = func (...) ", which is then
#                           overridden in Pages - but the first method is still called)
#    * layers: [] -> list
#
# ---------
#
# OSB = On Screen Button


var TRUE = 1;
var FALSE = 0;

var DISPLAY_WIDTH = 768;
var DISPLAY_HEIGHT = 576;

var DISPLAY_ROW_HEIGHT_1 = 1.5/6.4 * DISPLAY_HEIGHT;
var DISPLAY_ROW_HEIGHT_2 = 3.0/6.4 * DISPLAY_HEIGHT;
var DISPLAY_ROW_HEIGHT_3 = 4.6/6.4 * DISPLAY_HEIGHT;
var DISPLAY_ROW_HEIGHT_4 = 6.0/6.4 * DISPLAY_HEIGHT;

var LAYER_SERVICEABLE = "LayerServiceable";

var PAGE_HUB = "PageHub";
var PAGE_HUB_MENU_ITEM = "Hub";
var PAGE_EHSI = "PageEHSI"; # Electronic Horizontal Situation Indicator (EHSI)
var PAGE_EHSI_MENU_ITEM = "EHSI";
var PAGE_EADI = "PageEADI"; # Electronic Attitude Direction Indicator (EADI)
var PAGE_EADI_MENU_ITEM = "EADI";
var PAGE_SMS = "PageSMS";
var PAGE_SMS_MENU_ITEM = "SMS";
var PAGE_RWR = "PageRWR";
var PAGE_RWR_MENU_ITEM = "RWR";
var PAGE_MAP = "PageMap";
var PAGE_MAP_MENU_ITEM = "Map";
var PAGE_PPA = "PagePPA";
var PAGE_PPA_MENU_ITEM = "PPA";

var Z_INDEX = "z-index";

var margin = {
	device: {
		button_text: 10,
		button_text_top: 10, # extra margin
		fillHeight: 2,
		outline: 2,
		between_menu_item: 32, # for left and right hand buttons
		to_virtual_item: 48, # ca. 1.5*between_menu_item
		row_text: 60,
	},
};

var lineWidth = {
	device: {
		outline: 2,
	},
	layer_serviceable: {
		lines: 6,
	},
	page_ehsi: {
		triangle: 2,
		course_needle: 4,
		arrow: 4,
		text_box: 2,
	},
	page_eadi: {
		sphere_outline: 2,
		pitch_scale: 4,
	},
	page_sms: {
		aircraft_outline: 2,
		pylons_box: 2,
	},
	page_rwr: {
		lines_rwr: 4,
		lines_indicators: 1,
	},
};

var font = {
	device: {
		main: 24,
		row_text: 24,
	},
	page_ehsi: {
		compass: 16,
		text: 24,
	},
	page_eadi: {
		text: 24,
		text_big: 32,
	},
	page_sms: {
		pylons_text: 20,
		fbw_mode_text: 20,
	},
	page_ppa: {
		wpn_text: 32,
		ammo_text: 32,
		damage_text: 20,
	},
	page_rwr: {
		threat_text: 36,
		symbols_dist: 24, # a relative value for the size of symbology around the threat text
		indicators_text: 32,
	},
	page_map: {
		load_message: 64,
	}
};

var zIndex = {
	device: {
		osb: 100,
		page: 5,
		layer: 200,
	},
	deviceOSB: {
		text: 10,
		outline: 11,
		fill: 9,
		feedback: 7,
	},
	page_sms: {
		aircraft_outline: 15,
		pylons_box: 30,
		pylons_text: 20,
		menu_foreground: 10,
		menu_background: 5,
	},
	page_map: {
		map: 10,
		svg: 15,
		load_message: 16,
		row_text: 12,
	},
};

var FONT_MONO_REGULAR = "LiberationFonts/LiberationMono-Regular.ttf";
var FONT_MONO_BOLD = "LiberationFonts/LiberationMono-Bold.ttf";

# also used in apg-68.nas
var colorDot2 = [1, 1, 1];

var COLOR_WHITE = [1, 1, 1];
var COLOR_BLACK = [0, 0, 0];
var COLOR_YELLOW = [1, 1, 0];
var COLOR_AMBER = [1, 0.75, 0];
var COLOR_MAGENTA = [1, 0, 1];
var COLOR_CYAN = [0, 1, 1];
var COLOR_RED = [1, 0, 0];
var COLOR_GREEN = [0, 1, 0];
var COLOR_BLUE = [0, 0, 1];

var COLOR_AMBER = [1, 0.6, 0.2];
var COLOR_LIGHT_BLUE = [0.2, 0.6, 1];

var PUSHBUTTON = 0;

var variantID = getprop("sim/variant-id");

# flare/chaff values can change every 0.5 seconds -> cf. weapons.nas
# and sounds etc. for M2000 also have a length of 0.5 or multiples thereof
# => let the updates be done in increments of ca. every 0.5 seconds
var UPDATE_INC = 0.5;

var OSB1 = "OSB1";
var OSB2 = "OSB2";
var OSB3 = "OSB3";
var OSB4 = "OSB4";
var OSB5 = "OSB5";
var OSB6 = "OSB6";
var OSB7 = "OSB7";
var OSB8 = "OSB8";
var OSB9 = "OSB9";
var OSB10 = "OSB10";
var OSB11 = "OSB11";
var OSB12 = "OSB12";
var OSB13 = "OSB13";
var OSB14 = "OSB14";
var OSB15 = "OSB15";
var OSB16 = "OSB16";
var OSB17 = "OSB17";
var OSB18 = "OSB18";
var OSB19 = "OSB19";
var OSB20 = "OSB20";
var OSB21 = "OSB21";
var OSB22 = "OSB22";
var OSB23 = "OSB23";
var OSB24 = "OSB24";
var OSB25 = "OSB25";
var OSB26 = "OSB26";
var OSB27 = "OSB27";
var OSB28 = "OSB28";
var OSB29 = "OSB29";
var OSB30 = "OSB30";
var OSB31 = "OSB31";
var OSB32 = "OSB32";
var OSB33 = "OSB33";

var OSB_PLUS = " + "; # extra whitespace on purpose to get away from border
var OSB_MINUS = " - ";

# below mostly used for logic in PPA
var WPN_KIND_CANNON = "cannon";
var WPN_KIND_FALL = "fall"; # free fall bombs (guided or unguided)
var WPN_KIND_ARMAT = "armat";


#  ██████  ██ ███████ ██████  ██       █████  ██    ██     ██████  ███████ ██    ██ ██  ██████ ███████
#  ██   ██ ██ ██      ██   ██ ██      ██   ██  ██  ██      ██   ██ ██      ██    ██ ██ ██      ██
#  ██   ██ ██ ███████ ██████  ██      ███████   ████       ██   ██ █████   ██    ██ ██ ██      █████
#  ██   ██ ██      ██ ██      ██      ██   ██    ██        ██   ██ ██       ██  ██  ██ ██      ██
#  ██████  ██ ███████ ██      ███████ ██   ██    ██        ██████  ███████   ████   ██  ██████ ███████


var DisplayDevice = {
	new: func (name, resolution, uvMap, node, texture) {
		var device = {parents : [DisplayDevice] };
		device.canvas = canvas.new({
                			"name": name,
                           	"size": resolution,
                            "view": resolution,
                    		"mipmapping": 1
                    	});
		device.resolution = resolution;
		device.canvas.addPlacement({"node": node, "texture": texture});
		device.controls = {master:{"device": device}};
		device.controlPositions = {};
		device.listeners = [];
		device.uvMap = uvMap;
		device.name = name;
		device.system = nil;
		device.new = func {return nil;};
		return device;
	},

	del: func {
		me.canvas.del();
		foreach(l ; me.listeners) {
			call(func removelistener(l),[],nil,nil,var err = []);
		}
		me.listeners = [];
		me.del = func {};
	},

	start: func {
	},

	loop: func {
		me.update(notifications.frameNotification);
	},

	setColorBackground: func (colorBackground) {
		me.canvas.setColorBackground(colorBackground);
	},

	addControls: func (type, prefix, from, to, property, positions) {
		if (contains(DisplayDevice, prefix)) {print("Illegal prefix");return;}
		me[prefix] = func (node) {
			me.tempActionValue = node.getValue();

			if (me.tempActionValue > 0) {
				me.cntlFeedback.setTranslation(me.controlPositions[prefix][me.tempActionValue-1]);
				me.cntlFeedback.setVisible(1 == 1);
				me.cntlFeedback.update();
				me.controlAction(type, prefix~(me.tempActionValue), me.tempActionValue);
			} else {
				me.cntlFeedback.hide();
				me.cntlFeedback.update();
			}
		};
		me.controlPositions[prefix] = positions;
		for(var i = from; i <= to; i += 1) {
			me.controls[prefix~i] = {
				parents: [me.controls.master],
				name: prefix~i,
			};
		}
		if (me["controlGrp"] == nil) {
			me.controlGrp = me.canvas.createGroup()
								.set(Z_INDEX, zIndex.device.osb)
								.set("font", FONT_MONO_REGULAR);
		}
		me.controls.master.setControlText = func (text, positive = TRUE, outline = FALSE, hub = FALSE) {
			# positive - draw with colorFront, swap with colorBackground
			# outline - draw a border around the text
			# hub - draw in a different colour to indicate that this is the current page and will lead to the navigation hub page

			# store for later SWAP option
			me.contentText = text;
			me.contentPositive = positive;
			me.contentOutline = outline;

			if (text == nil or text == "") {
				me.letters.setVisible(FALSE);
				me.outline.setVisible(FALSE);
				me.fill.setVisible(FALSE);
				#me.fill.setColor((!positive)?me.device.colorFront:me.device.colorBack);
				#me.fill.setColorFill((!positive)?me.device.colorFront:me.device.colorBack);
				return;
			}
			var front_colour = hub == TRUE ? me.device.colorNavigation : me.device.colorFront;
			front_colour = positive ? front_colour: me.device.colorBack;
			var back_colour = hub == TRUE ? me.device.colorNavigation : me.device.colorFront;
			back_colour = (!positive)? back_colour : me.device.colorBack;
			me.letters.setVisible(TRUE);
			me.letters.setText(text);
			me.letters.setColor(front_colour);
			me.outline.setVisible(positive == TRUE and outline == TRUE);
			me.fill.setVisible(TRUE);
			me.fill.setColor(back_colour);
			me.fill.setColorFill(back_colour);
			me.linebreak = find("\n", text) != -1?2:1;
			me.lettersCount = size(text);
			if (me.linebreak == 2) {
				me.split = split("\n", text);
				if (size(me.split)>1) me.lettersCount = math.max(size(me.split[0]),size(me.split[1]));
			}
			me.fill.setScale(me.lettersCount/4,me.linebreak);
			me.outline.setScale(1.05*me.lettersCount/4,me.linebreak);
		};
		append(me.listeners, setlistener(property, me[prefix],0,0));
	},

	resetControls: func {
		me.tempKeys = keys(me.controls);
		foreach(var key; me.tempKeys) {
			if (me.controls[key]["parents"]!= nil) me.controls[key].setControlText("");
		}
	},

	update: func (noti) {
		me.system.update(noti);
	},

	controlAction: func {},

	setDisplaySystem: func (displaySystem) {
		me.system = displaySystem;
		displaySystem.setDevice(me);
	},

	addControlText: func (prefix, controlName, pos, posIndex, alignmentH=0, alignmentV=0) {
		me.tempX = me.controlPositions[prefix][posIndex][0]+pos[0];
		me.tempY = me.controlPositions[prefix][posIndex][1]+pos[1];

		me.alignment  = alignmentH==0?"center-":(alignmentH==-1?"left-":"right-");
		me.alignment ~= alignmentV==0?"center":(alignmentV==-1?"top":"bottom");
		me.letterWidth  = 0.6 * me.fontSize;
		me.letterHeight = 0.8 * me.fontSize;
		me.myCenter = [me.tempX, me.tempY];
		me.controls[controlName].letters = me.controlGrp.createChild("text")
				.set(Z_INDEX, zIndex.deviceOSB.text)
				.setAlignment(me.alignment)
				.setTranslation(me.tempX, me.tempY)
				.setFontSize(me.fontSize, 1)
				.setText("right(controlName,4)")
				.setColor(me.colorFront);
		me.controls[controlName].outline = me.controlGrp.createChild("path")
				.set(Z_INDEX, zIndex.deviceOSB.outline)
				.setStrokeLineJoin("miter") # "miter", "round" or "bevel"
				.moveTo(me.tempX-me.letterWidth*2*alignmentH-me.letterWidth*2-me.myCenter[0]-margin.device.outline,
					me.tempY-me.letterHeight*alignmentV*0.5-me.letterHeight*0.5-margin.device.outline-me.myCenter[1])
				.horiz(me.letterWidth*4+margin.device.outline*2)
				.vert(me.letterHeight*1.0+margin.device.outline*2)
				.horiz(-me.letterWidth*4-margin.device.outline*2)
				.vert(-me.letterHeight*1.0-margin.device.outline*2)
				.close()
				.setColor(COLOR_GREEN)
				.hide()
				.setStrokeLineWidth(lineWidth.device.outline)
				.setTranslation(me.myCenter);
		me.controls[controlName].fill = me.controlGrp.createChild("path")
				.set(Z_INDEX, zIndex.deviceOSB.fill)
				.setStrokeLineJoin("miter") # "miter", "round" or "bevel"
				.moveTo(me.tempX-me.letterWidth*2*alignmentH-me.letterWidth*2-me.myCenter[0],
					me.tempY-me.letterHeight*alignmentV*0.5-me.letterHeight*0.5-margin.device.fillHeight-me.myCenter[1])
				.horiz(me.letterWidth*4)
				.vert(me.letterHeight*1.0+margin.device.fillHeight)
				.horiz(-me.letterWidth*4)
				.vert(-me.letterHeight*1.0-margin.device.fillHeight)
				.close()
				.setColorFill(me.colorBack)
				.setColor(me.colorBack)
				.setStrokeLineWidth(lineWidth.device.outline)
				.setTranslation(me.myCenter);
	},

	addControlFeedback: func {
		me.feedbackRadius = 35;
		me.cntlFeedback = me.controlGrp.createChild("path")
	            .moveTo(-me.feedbackRadius,0)
	            .arcSmallCW(me.feedbackRadius,me.feedbackRadius, 0,  me.feedbackRadius*2, 0)
	            .arcSmallCW(me.feedbackRadius,me.feedbackRadius, 0, -me.feedbackRadius*2, 0)
	            .close()
	            .setStrokeLineWidth(2)
	            .set(Z_INDEX, zIndex.deviceOSB.feedback)
	            .setColor(colorDot2[0],colorDot2[1],colorDot2[2],0.15)
	            .setColorFill(colorDot2[0],colorDot2[1],colorDot2[2],0.3)
	            .hide();
	},

	setControlTextColors: func (foreground, background, navigation) {
		me.colorFront = foreground;
		me.colorBack  = background;
		me.colorNavigation = navigation;
	},

	initPage: func (page) {
		# printDebug(me.name," init page ",page.name);
		if (page.needGroup) {
			me.tempGrp = me.canvas.createGroup()
							.set(Z_INDEX, zIndex.device.page)
							.set("font", FONT_MONO_REGULAR)
							.hide();
			page.group = me.tempGrp;
		}
		page.device = me;
	},

	initLayer: func (layer) {
		# printDebug(me.name," init layer ",layer.name);
		me.tempGrp = me.canvas.createGroup()
						.set(Z_INDEX, zIndex.device.layer)
						.set("font", FONT_MONO_REGULAR)
						.hide();
		layer.group = me.tempGrp;
		layer.device = me;
		layer.setup();
	},
};


#  ██████  ██ ███████ ██████  ██       █████  ██    ██     ███████ ██    ██ ███████ ████████ ███████ ███    ███
#  ██   ██ ██ ██      ██   ██ ██      ██   ██  ██  ██      ██       ██  ██  ██         ██    ██      ████  ████
#  ██   ██ ██ ███████ ██████  ██      ███████   ████       ███████   ████   ███████    ██    █████   ██ ████ ██
#  ██   ██ ██      ██ ██      ██      ██   ██    ██             ██    ██         ██    ██    ██      ██  ██  ██
#  ██████  ██ ███████ ██      ███████ ██   ██    ██        ███████    ██    ███████    ██    ███████ ██      ██


var DisplaySystem = {
	new: func () {
		var system = {parents : [DisplaySystem] };
		system.new = func {return nil;};
		return system;
	},

	del: func {

	},

	setDevice: func (device) {
		me.device = device;
	},

	initDevice: func (propertyNum, controlPositions, fontSize) {
		me.device.addControls(PUSHBUTTON, "OSB", 1, 33, "controls/MFD["~propertyNum~"]/button-pressed", controlPositions);
		me.device.fontSize = fontSize;

		for (var i = 1; i <= 5; i+= 1) { # top row
			me.device.addControlText("OSB", "OSB"~i, [0, margin.device.button_text], i-1, 0, -1);
		}
		for (var i = 6; i <= 9; i+= 1) { # bottom row
			me.device.addControlText("OSB", "OSB"~i, [0, -margin.device.button_text], i-1, 0, 1);
		}
		for (var i = 10; i <= 21; i+= 1) { # left column
			me.device.addControlText("OSB", "OSB"~i, [margin.device.button_text, 0], i-1, -1, 0);
		}
		for (var i = 22; i <= 33; i+= 1) { # right column
			me.device.addControlText("OSB", "OSB"~i, [-margin.device.button_text, 0], i-1, 1, 0);
		}
	},

	initPage: func (pageName) {
		if (DisplaySystem[pageName] == nil) {
			print(pageName," does not exist");
			return;
		}
		me.tempPageInstance = DisplaySystem[pageName].new();
		me.device.initPage(me.tempPageInstance);
		me.pages[me.tempPageInstance.name] = me.tempPageInstance;
	},

	initLayer: func (layerName) {
		me.tempLayerInstance = DisplaySystem[layerName].new();
		me.device.initLayer(me.tempLayerInstance);
		me.layers[me.tempLayerInstance.name] = me.tempLayerInstance;
	},

	initPages: func () {
		me.pages = {};
		me.layers = {};

		me.initPage(PAGE_HUB);
		me.initPage(PAGE_EHSI);
		me.initPage(PAGE_EADI);
		me.initPage(PAGE_SMS);
		me.initPage(PAGE_PPA);
		me.initPage(PAGE_RWR);
		me.initPage(PAGE_MAP);

		me.initLayer(LAYER_SERVICEABLE);

		me.device.controlAction = func (type, controlName, propvalue) {
			me.tempLink = me.system.currPage.links[controlName];
			me.system.currPage.controlAction(controlName);
			if (me.tempLink != nil) {
				me.system.selectPage(me.tempLink);
			}
		};
	},

	fetchLayer: func (layerName) {
		if (me.layers[layerName] == nil) {
			print("\n",me.device.name,": no such layer ",layerName);
			print("Available layers: ");
			foreach(var layer; keys(me.layers)) {
				print(layer);
			}
			print();
		}
		return me.layers[layerName];
	},

	update: func (noti) {
		me.currPage.update(noti);
		foreach(var layer; me.currPage.layers) {
			me.fetchLayer(layer).update(noti);
		}
	},

	selectPage: func (pageName) {
		if (me.pages[pageName] == nil) {
			print(me.device.name," page not found: ",pageName);
			return;
		}
		if (me["currPage"] != nil) {
			if (me.pages[pageName] == me.currPage) {
				#print(me.device.name," page wont switch to itself: ",pageName);
				return;
			}
			if (me.currPage.needGroup) {
				me.currPage.group.hide();
			}
			me.currPage.exit();
			foreach (var layer; me.currPage.layers) {
				me.fetchLayer(layer).group.hide();
			}
		}
		me.currPage = me.pages[pageName];
		if (me.currPage.needGroup) {
			me.currPage.group.show();
		}
		me.currPage.enter();
		#me.currPage.update(nil);
		foreach(var layer; me.currPage.layers) {
			me.fetchLayer(layer).group.show();
		}
	},


#  ██       █████  ██    ██ ███████ ██████      ███████ ███████ ██████  ██    ██ ██  ██████ ███████  █████  ██████  ██      ███████
#  ██      ██   ██  ██  ██  ██      ██   ██     ██      ██      ██   ██ ██    ██ ██ ██      ██      ██   ██ ██   ██ ██      ██
#  ██      ███████   ████   █████   ██████      ███████ █████   ██████  ██    ██ ██ ██      █████   ███████ ██████  ██      █████
#  ██      ██   ██    ██    ██      ██   ██          ██ ██      ██   ██  ██  ██  ██ ██      ██      ██   ██ ██   ██ ██      ██
#  ███████ ██   ██    ██    ███████ ██   ██     ███████ ███████ ██   ██   ████   ██  ██████ ███████ ██   ██ ██████  ███████ ███████


	LayerServiceable: {
		name: LAYER_SERVICEABLE,
		new: func {
			var layer = {parents:[DisplaySystem.LayerServiceable]};
			layer.offset = 0;
			return layer;
		},

		setup: func {
			me.group.setTranslation(DISPLAY_WIDTH/2, DISPLAY_HEIGHT/2);

			me.serviceable_markers = me.group.createChild("path")
				.moveTo(-50, 50)
				.lineTo(-25, -50)
				.moveTo(-25, 50)
				.lineTo(0, -50)
				.moveTo(0, 50)
				.lineTo(25, -50)
				.moveTo(25, 50)
				.lineTo(50, -50)
				.setStrokeLineWidth(lineWidth.layer_serviceable.lines)
				.setColor(COLOR_RED);
			me.serviceable_markers.hide();
		},

		update: func (noti = nil) {
			if (noti.FrameCount != 3) {
				return;
			}
			me.serviceable_markers.setVisible(noti.getproper("wow"));
		},
	},




#    ██████   █████   ██████  ███████     ██   ██ ██    ██ ██████
#    ██   ██ ██   ██ ██       ██          ██   ██ ██    ██ ██   ██
#    ██████  ███████ ██   ███ █████       ███████ ██    ██ ██████
#    ██      ██   ██ ██    ██ ██          ██   ██ ██    ██ ██   ██
#    ██      ██   ██  ██████  ███████     ██   ██  ██████  ██████


	PageHub: {
		name: PAGE_HUB,
		isNew: TRUE,
		needGroup: TRUE,

		new: func {
			me.instance = {parents:[DisplaySystem.PageHub]};
			me.instance.group = nil;
			return me.instance;
		},

		setup: func {
			var variantID = getprop("sim/variant-id");
			var variant_text = "Dassault Mirage 2000-5"; # constants.VARIANT_5
			if (variantID == constants.VARIANT_5B) {
				variant_text = "Dassault Mirage 2000-5B";
			} elsif (variantID == constants.VARIANT_N) {
				variant_text = "Dassault Mirage 2000N-ish";
			} elsif (variantID == constants.VARIANT_D) {
				variant_text = "Dassault Mirage 2000D";
			}
			me.info_text = me.group.createChild("text", "info_text")
				.setFontSize(font.page_ppa.wpn_text)
				.setColor(COLOR_CYAN)
				.setAlignment("center-center")
				.setText(variant_text)
				.setTranslation(DISPLAY_WIDTH/2, DISPLAY_HEIGHT/2 + 80);
		},

		enter: func {
			# printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = FALSE;
			}
			me.device.resetControls();
			me.device.controls[OSB6].setControlText(PAGE_SMS_MENU_ITEM);
			me.device.controls[OSB7].setControlText(PAGE_PPA_MENU_ITEM);
			me.device.controls[OSB8].setControlText(PAGE_RWR_MENU_ITEM);
			me.device.controls[OSB22].setControlText(PAGE_EHSI_MENU_ITEM);
			me.device.controls[OSB25].setControlText(PAGE_EADI_MENU_ITEM);
			me.device.controls[OSB28].setControlText(PAGE_MAP_MENU_ITEM);
		},

		controlAction: func (controlName) {
			if (controlName == OSB6) {
				me.device.system.selectPage(PAGE_SMS);
			} elsif (controlName == OSB7) {
				me.device.system.selectPage(PAGE_PPA);
			} elsif (controlName == OSB8) {
				me.device.system.selectPage(PAGE_RWR);
			} elsif (controlName == OSB22) {
				me.device.system.selectPage(PAGE_EHSI);
			} elsif (controlName == OSB25) {
				me.device.system.selectPage(PAGE_EADI);
			} elsif (controlName == OSB28) {
				me.device.system.selectPage(PAGE_MAP);
			}
		},

		update: func(noti = nil) {
			if (noti.FrameCount != 3) {
				return;
			}
		},

		exit: func {
		},

		links: {
		},

		layers: [LAYER_SERVICEABLE],
	},



#    ██████   █████   ██████  ███████     ███████ ██   ██ ███████ ██
#    ██   ██ ██   ██ ██       ██          ██      ██   ██ ██      ██
#    ██████  ███████ ██   ███ █████       █████   ███████ ███████ ██
#    ██      ██   ██ ██    ██ ██          ██      ██   ██      ██ ██
#    ██      ██   ██  ██████  ███████     ███████ ██   ██ ███████ ██


	PageEHSI: {
		name: PAGE_EHSI,
		isNew: TRUE,
		needGroup: TRUE,

		new: func {
			me.instance = {parents:[DisplaySystem.PageEHSI]};
			me.instance.group = nil;
			return me.instance;
		},

		setup: func {
			me.input = {
				wind_deg               : "/environment/wind-from-heading-deg",
				wind_kt                : "/environment/wind-speed-kt",
				ground_speed           : "velocities/groundspeed-kt",
				nav1_heading_bug_deg   : "instrumentation/nav[0]/radials/selected-deg", # OBS (Omni-Bearing Selector) of HSI / Needle / The path
				nav2_heading_bug_deg   : "instrumentation/nav[1]/radials/selected-deg",
				nav1_heading_deg       : "instrumentation/nav[0]/heading-deg",
				nav2_heading_deg       : "instrumentation/nav[1]/heading-deg",
				nav1_gs_direct_deg     : "instrumentation/nav[0]/gs-direct-deg",
				nav2_gs_direct_deg     : "instrumentation/nav[1]/gs-direct-deg",
				nav1_in_range          : "instrumentation/nav[0]/in-range",
				nav2_in_range          : "instrumentation/nav[1]/in-range",
				nav1_nav_id            : "instrumentation/nav[0]/nav-id",
				nav2_nav_id            : "instrumentation/nav[1]/nav-id",
				nav1_nav_distance      : "instrumentation/nav[0]/nav-distance",
				nav2_nav_distance      : "instrumentation/nav[1]/nav-distance",
				nav1_has_gs            : "instrumentation/nav[0]/has-gs",
				nav2_has_gs            : "instrumentation/nav[1]/has-gs",
				nav1_gs_in_range       : "instrumentation/nav[0]/gs-in-range",
				nav2_gs_in_range       : "instrumentation/nav[1]/gs-in-range",
				nav1_gs_distance       : "instrumentation/nav[0]/gs-distance",
				nav2_gs_distance       : "instrumentation/nav[1]/gs-distance",
				tacan_in_range         : "instrumentation/tacan/in-range",
				tacan_bearing          : "instrumentation/tacan/indicated-bearing-true-deg",
				tacan_distance         : "instrumentation/tacan/indicated-distance-nm",
				tacan_channel          : "instrumentation/tacan/display/channel",
			};

			foreach(var name; keys(me.input)) {
				me.input[name] = props.globals.getNode(me.input[name], 1);
			}

			# graphics stuff
			me.radius = 0.6 * DISPLAY_HEIGHT/2;
			me._createCompass();
			me._createWind();
			me._createLeftSideTexts();

			# content stuff
			me.mode = 0; # VOR = 0, DATA = 1, TAC = 2
			me.nav_number = 1; # Either NAV1 or NAV2 toggled with OSB5

			me.osb13 = "TH";
			me.osb14 = "MH";
			me.osb16 = "VOR";
			me.osb17 = "DATA";
			me.osb18 = "TAC";
			me.osb25 = OSB_PLUS;
			me.osb26 = OSB_MINUS;
		},

		_createCompass: func() {
			# cf. https://wiki.flightgear.org/CompassRose
			me.compass_group = me.group.createChild("group", "compass_group")
				.setTranslation(DISPLAY_WIDTH/2, DISPLAY_HEIGHT*0.6);
			var style_hsi = canvas.CompassRose.Style.new();
			style_hsi.setMarkLength(0.1)
				.setMarkOffset(-1)
				.setSubdivisions(1)
				.setSubdivisionLength(0.5)
				.setFontSize(font.page_ehsi.compass);
			canvas.CompassRose.draw(me.compass_group, me.radius, style_hsi)
				.setColor(COLOR_WHITE);

			me.course_needle = me.compass_group.createChild("path")
				.setColor(COLOR_GREEN)
				.setStrokeLineWidth(lineWidth.page_ehsi.course_needle)
				.moveTo(0, -me.radius)
				.lineTo(0, -me.radius+24)
				.moveTo(0, -me.radius+24) # triangle start
				.lineTo(-10, -me.radius+40)
				.moveTo(0, -me.radius+24)
				.lineTo(10, -me.radius+40)
				.moveTo(-10, -me.radius+40)
				.lineTo(10, -me.radius+40)
				.moveTo(-6, -me.radius+40) # left long line
				.lineTo(-6, me.radius-24)
				.moveTo(6, -me.radius+40) # right long line
				.lineTo(6, me.radius-24)
				.moveTo(-6, me.radius-24) # horizontal line between long lines
				.lineTo(6, me.radius-24)
				.moveTo(0, me.radius-24) # he tail
				.lineTo(0, me.radius);

			me.destination_needle = me.compass_group.createChild("path")
				.setColor(COLOR_CYAN)
				.setStrokeLineWidth(lineWidth.page_ehsi.course_needle)
				.moveTo(0, -me.radius)
				.lineTo(0, me.radius)
				.moveTo(0, -me.radius)
				.lineTo(-16, -me.radius+32)
				.moveTo(0, -me.radius)
				.lineTo(16, -me.radius+32);

			# triangles marking every 45 degs
			me.triangles_group = me.group.createChild("group", "triangles_group")
			                             .setTranslation(DISPLAY_WIDTH/2, DISPLAY_HEIGHT*0.55);
			var delta = 2 * D2R;
			var angle = 0;
			var dist = me.radius * 1.1;
			var dist2 = me.radius * 1.2;
			var triangle = nil;
			for (i = 0; i < 8; i += 1) {
				angle = i * 45 * D2R;
				triangle = me.triangles_group.createChild("path")
					.setColor(COLOR_WHITE)
					.setStrokeLineWidth(lineWidth.page_ehsi.triangle)
					.moveTo(math.sin(angle) * dist, math.cos(angle) * dist)
					.lineTo(math.sin(angle-delta) * dist2, math.cos(angle-delta) * dist2)
					.moveTo(math.sin(angle-delta) * dist2, math.cos(angle-delta) * dist2)
					.lineTo(math.sin(angle+delta) * dist2, math.cos(angle+delta) * dist2)
					.moveTo(math.sin(angle+delta) * dist2, math.cos(angle+delta) * dist2)
					.lineTo(math.sin(angle) * dist, math.cos(angle) * dist)
			}
		},

		_createWind: func {
			me.wind_group = me.group.createChild("group", "wind_group")
				.setTranslation(536,510);
			me.wind_arrow = me.wind_group.createChild("path")
				.setColor(COLOR_CYAN)
				.setStrokeLineWidth(lineWidth.page_ehsi.arrow)
				.moveTo(0, -16)
				.lineTo(0, 16)
				.moveTo(0, -16)
				.lineTo(-3, 0)
				.moveTo(0, -16)
				.lineTo(3, 0);

			me.wind_text = me.group.createChild("text", "wind_text")
				.setFontSize(font.page_ehsi.text)
				.setColor(COLOR_CYAN)
				.setAlignment("left-center")
				.setTranslation(536+20, 510);
			me.wind_text.enableUpdate();
		},

		_createLeftSideTexts: func {
			me.mode_box = me.group.createChild("path", "mode_box")
				.setColor(COLOR_CYAN)
				.setColorFill(COLOR_BLACK)
				.rect(180 - 64, 108 - 12, 128, 24)
				.setStrokeLineWidth(lineWidth.page_ehsi.text_box);
			me.mode_text = me.group.createChild("text", "mode_text")
				.setFontSize(font.page_ehsi.text)
				.setColor(COLOR_CYAN)
				.setAlignment("center-center")
				.setTranslation(180, 108);
			me.mode_text.enableUpdate();

			me.distance_text = me.group.createChild("text", "distance_text")
				.setFontSize(font.page_ehsi.text)
				.setColor(COLOR_CYAN)
				.setAlignment("right-center")
				.setTranslation(240, 140);
			me.distance_text.enableUpdate();
			me.nav_id_text = me.group.createChild("text", "nav_id_text")
				.setFontSize(font.page_ehsi.text)
				.setColor(COLOR_WHITE)
				.setAlignment("right-center")
				.setTranslation(172, 512);
			me.nav_id_text.enableUpdate();
			me.time_text = me.group.createChild("text", "time_text")
				.setFontSize(font.page_ehsi.text)
				.setColor(COLOR_CYAN)
				.setAlignment("right-center")
				.setTranslation(260, 512);
			me.time_text.enableUpdate();
			me.tacan_text = me.group.createChild("text", "tacan_text")
				.setFontSize(font.page_ehsi.text)
				.setColor(COLOR_WHITE)
				.setAlignment("left-center")
				.setTranslation(60, 544);
			me.tacan_text.enableUpdate();
		},

		enter: func {
			# printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = FALSE;
			}
			me.device.resetControls();
			me.device.controls[OSB2].setControlText(PAGE_EHSI_MENU_ITEM, TRUE, FALSE, TRUE);
		},

		_changeMode: func(delta) {
			me.mode += delta;
			if (me.mode < 0) {
				me.mode = 0;
			} elsif (me.mode > 2) {
				me.mode = 2;
			}
		},

		_changeSelectedCourse: func(delta) {
			if (me.nav_number == 1) {
				me.input.nav1_heading_bug_deg.setValue(geo.normdeg(me.input.nav1_heading_bug_deg.getValue() + delta));
			} else {
				me.input.nav2_heading_bug_deg.setValue(geo.normdeg(me.input.nav2_heading_bug_deg.getValue() + delta));
			}
		},

		controlAction: func (controlName) {
			if (controlName == OSB2) {
				me.device.system.selectPage(PAGE_HUB);
			} elsif (controlName == OSB5) {
				me.nav_number = me.nav_number == 1 ? 2 : 1;
			} elsif (controlName == OSB13) {
				me.input.show_true_north.setValue(TRUE);
			} elsif (controlName == OSB14) {
				me.input.show_true_north.setValue(FALSE);
			} elsif (controlName == OSB16) {
				me._changeMode(-1);
			} elsif (controlName == OSB17) {
				me._changeMode(1);
			} elsif (controlName == OSB25) {
				me._changeSelectedCourse(10);
			} elsif (controlName == OSB26) {
				me._changeSelectedCourse(-1);
			}
		},

		_updateCompassStuff: func() {
			me.compass_group.setRotation(geo.normdeg(0 - me.heading_displayed[0])*D2R); # yeah, the diff from North

			# selected course needle
			if (me.nav_number == 1) {
				me.course_selected = me.input.nav1_heading_bug_deg.getValue();
			} else {
				me.course_selected = me.input.nav2_heading_bug_deg.getValue();
			}
			me.course_needle.setRotation(geo.normdeg(me.course_selected)*D2R); # in relation to the compass -> positive

			# destination needle
			var visible = FALSE;
			if (me.mode == 0) {
				if (me.nav_number == 1 and me.input.nav1_in_range.getValue()) {
					visible = TRUE;
					me.destination_needle.setRotation(me._correctTrueHeading(me.input.nav1_heading_deg.getValue())*D2R);
				} elsif (me.nav_number == 2 and me.input.nav2_in_range.getValue()) {
					visible = TRUE;
					me.destination_needle.setRotation(me._correctTrueHeading(me.input.nav2_heading_deg.getValue())*D2R);
				}
			} elsif (me.mode == 2) {
				if (me.input.tacan_in_range.getValue()) {
					visible = TRUE;
					me.destination_needle.setRotation(me._correctTrueHeading(me.input.tacan_bearing.getValue())*D2R);
				}
			} else { # DATA
				visible = FALSE;
			}
			me.destination_needle.setVisible(visible);
		},

		_updateWindStuff: func() {
			me.wind_arrow.setRotation(me._relativeHeading(me.input.wind_deg.getValue())*D2R);
			me.wind_text.updateText(sprintf("%.0f", me.input.wind_kt.getValue()));
		},

		_relativeHeading: func(other_heading) { # where other heading is TRUE and we want th heading relative to the aircraft
			return geo.normdeg(0 - me.heading_displayed[0] + me._correctTrueHeading(other_heading));
		},

		_correctTrueHeading: func(a_true_heading) { # we have a heading in True and want to have it either true or magnetic
			return geo.normdeg(me.heading_displayed[1] == TRUE ? a_true_heading : a_true_heading - me.heading_displayed[2]);
		},

		_updateLeftSideTexts: func {
			var distance_m = 0;
			var distance_display = '...N';
			var time_display = '...M';
			var nav_id_display = '';
			var mode_display = "DATA";
			var nav_id_text_color = COLOR_WHITE;
			var tacan_text_color = COLOR_WHITE;

			if (me.mode == 0) {
				mode_display = "VOR";
				nav_id_text_color = COLOR_CYAN;
				if (me.nav_number == 1 and me.input.nav1_in_range.getValue()) {
					nav_id_display = me.input.nav1_nav_id.getValue();
					if (me.input.nav1_has_gs.getValue() and me.input.nav1_gs_in_range.getValue()) {
						mode_display = "ILS";
						distance_m = me.input.nav1_gs_distance.getValue();
					} else {
						distance_m = me.input.nav1_nav_distance.getValue();
					}
					distance_display = sprintf("%.1fN", distance_m*M2NM);
					time_display = me._calcTimeToDestinationString(distance_m);
				} elsif (me.nav_number == 2 and me.input.nav2_in_range.getValue()) {
					nav_id_display = me.input.nav2_nav_id.getValue();
					if (me.input.nav2_has_gs.getValue() and me.input.nav2_gs_in_range.getValue()) {
						mode_display = "ILS";
						distance_m = me.input.nav2_gs_distance.getValue();
					} else {
						distance_m = me.input.nav2_nav_distance.getValue();
					}
					distance_display = sprintf("%.1fN", distance_m*M2NM);
					time_display = me._calcTimeToDestinationString(distance_m);
				}
			} elsif (me.mode == 1) {
				mode_display = "DATA";
			} elsif (me.mode == 2) {
				mode_display = "TAC";
				if (me.input.tacan_in_range.getValue()) {
					distance_m = me.input.tacan_distance.getValue()*NM2M;
					distance_display = sprintf("%.1fN", distance_m*M2NM);
					time_display = me._calcTimeToDestinationString(distance_m);
				}
				tacan_text_color = COLOR_CYAN;
			}
			me.mode_text.updateText(mode_display);
			me.nav_id_text.updateText(nav_id_display);
			me.nav_id_text.setColor(nav_id_text_color);
			me.distance_text.updateText(distance_display);
			me.time_text.updateText(time_display);
			me.tacan_text.updateText(me.input.tacan_channel.getValue());
			me.tacan_text.setColor(tacan_text_color);
		},

		_calcTimeToDestinationString: func (distance_m) { # how much time left as a string mm:ss
			var speed_ms = me.input.ground_speed.getValue()*KT2MPS;
			var value = speed_ms > 50 ? speed_ms : 206; # ca. 400 kt
			value = distance_m / value; # how many seconds
			var minutes = math.floor(value/60);
			var seconds = math.round(value - minutes*60);
			return sprintf("%d:%02d", minutes, seconds);
		},

		update: func(noti = nil) {
			if (noti.FrameCount != 3) {
				return;
			}

			me.heading_displayed = displays.common.getHeadingForDisplay();

			# button stuff
			me.osb5 = me.nav_number == 1 ? "NAV1" : "NAV2";
			me.osb13_selected = FALSE;
			me.osb14_selected = FALSE;
			me.osb16_selected = FALSE;
			me.osb17_selected = FALSE;
			me.osb18_selected = FALSE;
			if (me.heading_displayed[1] == TRUE) {
				me.osb13_selected = TRUE;
			} else {
				me.osb14_selected = TRUE;
			}
			if (me.mode == 0) {
				me.osb16_selected = TRUE;
			} elsif (me.mode == 1) {
				me.osb17_selected = TRUE;
			} else {
				me.osb18_selected = TRUE;
			}
			me.device.controls[OSB5].setControlText(me.osb5);
			me.device.controls[OSB13].setControlText(me.osb13, TRUE, me.osb13_selected);
			me.device.controls[OSB14].setControlText(me.osb14, TRUE, me.osb14_selected);
			me.device.controls[OSB16].setControlText(me.osb16, TRUE, me.osb16_selected);
			me.device.controls[OSB17].setControlText(me.osb17, TRUE, me.osb17_selected);
			me.device.controls[OSB18].setControlText(me.osb18, TRUE, me.osb18_selected);
			me.device.controls[OSB25].setControlText(me.osb25);
			me.device.controls[OSB26].setControlText(me.osb26);

			# drawing stuff
			me._updateCompassStuff();
			me._updateWindStuff();
			me._updateLeftSideTexts();
		},

		exit: func {
		},

		links: {
			OSB3: PAGE_EADI,
		},

		layers: [LAYER_SERVICEABLE],
	},


#    ██████   █████   ██████  ███████     ███████  █████  ██████  ██
#    ██   ██ ██   ██ ██       ██          ██      ██   ██ ██   ██ ██
#    ██████  ███████ ██   ███ █████       █████   ███████ ██   ██ ██
#    ██      ██   ██ ██    ██ ██          ██      ██   ██ ██   ██ ██
#    ██      ██   ██  ██████  ███████     ███████ ██   ██ ██████  ██


	PageEADI: {
		name: PAGE_EADI,
		isNew: TRUE,
		needGroup: TRUE,

		new: func {
			me.instance = {parents:[DisplaySystem.PageEADI]};
			me.instance.group = nil;
			return me.instance;
		},

		setup: func {
			me.radius = 0.5 * DISPLAY_HEIGHT/2;

			me._createSphere();
			me._createSpeedHdgAltTexts();
		},

		_createSphere: func {
			me.sphere_group = me.group.createChild("group", "sphere_group")
				.setTranslation(DISPLAY_WIDTH/2, DISPLAY_HEIGHT*0.6);

			me.lower_sphere = me.sphere_group.createChild("path", "lower_sphere")
				.setColor(COLOR_WHITE)
				.setColorFill(COLOR_AMBER)
				.setStrokeLineWidth(lineWidth.page_eadi.sphere_outline)
				.moveTo(-me.radius, 0)
				.arcSmallCCW(me.radius, me.radius, 0, me.radius*2, 0);
			me.upper_sphere = me.sphere_group.createChild("path", "upper_sphere")
				.setColor(COLOR_WHITE)
				.setColorFill(COLOR_LIGHT_BLUE)
				.moveTo(-me.radius, 0)
				.setStrokeLineWidth(lineWidth.page_eadi.sphere_outline)
				.arcSmallCW(me.radius, me.radius, 0, me.radius*2, 0);
		},

		_createSpeedHdgAltTexts: func {
			me.speed_ias_text = me.group.createChild("text", "speed_ias_text")
				.setFontSize(font.page_eadi.text_big)
				.setColor(COLOR_CYAN)
				.setAlignment("right-bottom")
				.setTranslation(160, 132);
			me.speed_ias_text.enableUpdate();
			me.speed_mach_text = me.group.createChild("text", "speed_mach_text")
				.setFontSize(font.page_eadi.text)
				.setColor(COLOR_CYAN)
				.setAlignment("right-center")
				.setTranslation(160, 152);
			me.speed_mach_text.enableUpdate();

			me.hdg_text = me.group.createChild("text", "hdg_text")
				.setFontSize(font.page_eadi.text)
				.setColor(COLOR_CYAN)
				.setAlignment("center-center")
				.setTranslation(DISPLAY_WIDTH/2, 100);
			me.hdg_text.enableUpdate();

			me.alt_hundreds_text = me.group.createChild("text", "alt_hundreds_text")
				.setFontSize(font.page_eadi.text_big)
				.setColor(COLOR_CYAN)
				.setAlignment("right-bottom")
				.setTranslation(DISPLAY_WIDTH - 208, 132);
			me.alt_hundreds_text.enableUpdate();
			me.alt_digits_text = me.group.createChild("text", "alt_digits_text")
				.setFontSize(font.page_eadi.text)
				.setColor(COLOR_CYAN)
				.setAlignment("right-bottom")
				.setTranslation(DISPLAY_WIDTH - 180, 132);
			me.alt_digits_text.enableUpdate();
			me.alt_radar_text = me.group.createChild("text", "alt_radar_text")
				.setFontSize(font.page_eadi.text)
				.setColor(COLOR_CYAN)
				.setAlignment("right-center")
				.setTranslation(DISPLAY_WIDTH - 178, 152);
			me.alt_radar_text.enableUpdate();
			me.the_H = me.group.createChild("text", "the_H")
				.setFontSize(font.page_eadi.text)
				.setColor(COLOR_CYAN)
				.setText("H")
				.setAlignment("left-center")
				.setTranslation(DISPLAY_WIDTH - 178, 152);
		},

		enter: func {
			# printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = FALSE;
			}
			me.device.resetControls();
			me.device.controls[OSB2].setControlText(PAGE_EADI_MENU_ITEM, TRUE, FALSE, TRUE);
		},

		controlAction: func (controlName) {
			if (controlName == OSB2) {
				me.device.system.selectPage(PAGE_HUB);
			}
		},

		_updateSpeedHdgAltTexts: func {
			var speed_display = displays.common.getSpeedForDisplay();
			me.speed_ias_text.updateText(speed_display[0]);
			if (speed_display[1] != nil) {
				me.speed_mach_text.updateText(speed_display[1]);
				me.speed_mach_text.show();
			} else {
				me.speed_mach_text.hide();
			}

			me.heading_displayed = math.round(displays.common.getHeadingForDisplay()[0]);
			me.hdg_text.updateText(sprintf("%03d", me.heading_displayed));

			me.alt_for_display = displays.common.getAltForDisplay();
			me.alt_hundreds_text.updateText(me.alt_for_display[0]);
			me.alt_digits_text.updateText(me.alt_for_display[1]);
			if (me.alt_for_display[2] != nil) { 
				me.alt_radar_text.updateText(me.alt_for_display[2]);
				me.alt_radar_text.show();
				me.the_H.show();
			} else {
				me.alt_radar_text.hide();
				me.the_H.hide();
			}
		},

		update: func(noti = nil) {
			if (noti.FrameCount != 3) {
				return;
			}
			me._updateSpeedHdgAltTexts();
		},

		exit: func {
		},

		links: {
			OSB3: PAGE_SMS,
		},

		layers: [LAYER_SERVICEABLE],
	},


#  ██████   █████   ██████  ███████     ███████ ███    ███ ███████
#  ██   ██ ██   ██ ██       ██          ██      ████  ████ ██
#  ██████  ███████ ██   ███ █████       ███████ ██ ████ ██ ███████
#  ██      ██   ██ ██    ██ ██               ██ ██  ██  ██      ██
#  ██      ██   ██  ██████  ███████     ███████ ██      ██ ███████


	PageSMS: {
		name: PAGE_SMS,
		isNew: TRUE,
		needGroup: TRUE,

		new: func {
			me.instance = {parents:[DisplaySystem.PageSMS]};
			me.instance.group = nil;
			return me.instance;
		},

		setup: func {
			# printDebug(me.name," on ",me.device.name," is being setup");

			me.input = {
				fbw_mode                  : "fdm/jsbsim/fbw/mode",
			};

			foreach(var name; keys(me.input)) {
				me.input[name] = props.globals.getNode(me.input[name], 1);
			}

			me._setup_aircraft_outline();
			me._setup_pylon_boxes_and_text();

			me.fbw_mode_text = me.group.createChild("text", "fbw_mode_text")
				.setFontSize(font.page_sms.fbw_mode_text)
				.setColor(COLOR_CYAN)
				.setAlignment("right-center")
				.setTranslation(DISPLAY_WIDTH/2 - 150, 250);
			me.fbw_mode_text.enableUpdate();
			me.FBW_AA_MENU_ITEM = "A/A";
			me.FBW_CHARGES_MENU_ITEM = "CHARGES";
		},

		_setup_aircraft_outline: func {
			me.aircraft_outline_left = me.group.createChild("path")
				.set(Z_INDEX, zIndex.page_sms.aircraft_outline)
				.setColor(COLOR_WHITE)
				.setStrokeLineWidth(lineWidth.page_sms.aircraft_outline)
				.moveTo(DISPLAY_WIDTH/2 - 60, 96)
				.lineTo(DISPLAY_WIDTH/2 - 51.6, 192)
				.moveTo(DISPLAY_WIDTH/2 - 48, 228)
				.lineTo(DISPLAY_WIDTH/2 - 33.6, 384)
				.moveTo(DISPLAY_WIDTH/2 - 30, 420)
				.lineTo(DISPLAY_WIDTH/2 - 24, 480)
				.moveTo(DISPLAY_WIDTH/2 - 55, 144)
				.lineTo(DISPLAY_WIDTH/2 - 192, 396)
				.lineTo(DISPLAY_WIDTH/2 - 192, 432)
				.lineTo(DISPLAY_WIDTH/2 - 26.4, 444);

			me.aircraft_outline_right = me.group.createChild("path")
				.set(Z_INDEX, zIndex.page_sms.aircraft_outline)
				.setColor(COLOR_WHITE)
				.setStrokeLineWidth(lineWidth.page_sms.aircraft_outline)
				.moveTo(DISPLAY_WIDTH/2 + 60, 96)
				.lineTo(DISPLAY_WIDTH/2 + 51.6, 192)
				.moveTo(DISPLAY_WIDTH/2 + 48, 228)
				.lineTo(DISPLAY_WIDTH/2 + 33.6, 384)
				.moveTo(DISPLAY_WIDTH/2 + 30, 420)
				.lineTo(DISPLAY_WIDTH/2 + 24, 480)
				.moveTo(DISPLAY_WIDTH/2 + 55, 144)
				.lineTo(DISPLAY_WIDTH/2 + 192, 396)
				.lineTo(DISPLAY_WIDTH/2 + 192, 432)
				.lineTo(DISPLAY_WIDTH/2 + 26.4, 444);
		},

		_setup_pylon_boxes_and_text: func {
			# Pylon 1L (position 0)
			me.p1L_box = me.group.createChild("path", "p1L_box")
				.setColor(COLOR_YELLOW)
				.setColorFill(COLOR_BLACK)
				.rect(DISPLAY_WIDTH/2 - (10+72), 196, 72, 24)
				.setStrokeLineWidth(lineWidth.page_sms.pylons_box)
				.hide();
			me.p1L_text = me.group.createChild("text", "p1L_text")
				.setFontSize(font.page_sms.pylons_text)
				.setColor(COLOR_YELLOW)
				.setAlignment("left-center")
				.setTranslation(DISPLAY_WIDTH/2 - (10+72), 196 + 24/2);
			me.p1L_text.enableUpdate();

			# Pylon 1R (position 6)
			me.p1R_box = me.group.createChild("path", "p1R_box")
				.setColor(COLOR_YELLOW)
				.setColorFill(COLOR_BLACK)
				.rect(DISPLAY_WIDTH/2 + 10, 196, 72, 24)
				.setStrokeLineWidth(lineWidth.page_sms.pylons_box)
				.hide();
			me.p1R_text = me.group.createChild("text", "p1R_text")
				.setFontSize(font.page_sms.pylons_text)
				.setColor(COLOR_YELLOW)
				.setAlignment("right-center")
				.setTranslation(DISPLAY_WIDTH/2 + (10+72), 196 + 24/2);
			me.p1R_text.enableUpdate();

			# Pylon 3C (position 3)
			me.p3C_box = me.group.createChild("path", "p3C_box")
				.setColor(COLOR_YELLOW)
				.setColorFill(COLOR_BLACK)
				.rect(DISPLAY_WIDTH/2 -36, 264, 72, 24)
				.setStrokeLineWidth(lineWidth.page_sms.pylons_box)
				.hide();
			me.p3C_text = me.group.createChild("text", "p3C_text")
				.setFontSize(font.page_sms.pylons_text)
				.setColor(COLOR_YELLOW)
				.setAlignment("center-center")
				.setTranslation(DISPLAY_WIDTH/2, 264 + 24/2);
			me.p3C_text.enableUpdate();

			# Pylon 3L (position 4)
			me.p3L_box = me.group.createChild("path", "p3L_box")
				.setColor(COLOR_YELLOW)
				.setColorFill(COLOR_BLACK)
				.rect(DISPLAY_WIDTH/2 - (60+72), 324, 72, 24)
				.setStrokeLineWidth(lineWidth.page_sms.pylons_box)
				.hide();
			me.p3L_text = me.group.createChild("text", "p3L_text")
				.setFontSize(font.page_sms.pylons_text)
				.setColor(COLOR_YELLOW)
				.setAlignment("left-center")
				.setTranslation(DISPLAY_WIDTH/2 - (60+72), 324 + 24/2);
			me.p3L_text.enableUpdate();

			# Pylon 3R (position 2)
			me.p3R_box = me.group.createChild("path", "p3R_box")
				.setColor(COLOR_YELLOW)
				.setColorFill(COLOR_BLACK)
				.rect(DISPLAY_WIDTH/2 + 60, 324, 72, 24)
				.setStrokeLineWidth(lineWidth.page_sms.pylons_box)
				.hide();
			me.p3R_text = me.group.createChild("text", "p3R_text")
				.setFontSize(font.page_sms.pylons_text)
				.setColor(COLOR_YELLOW)
				.setAlignment("right-center")
				.setTranslation(DISPLAY_WIDTH/2 + (60+72), 324 + 24/2);
			me.p3R_text.enableUpdate();

			# Pylon 2L (position 1)
			me.p2L_box = me.group.createChild("path", "p2L_box")
				.setColor(COLOR_YELLOW)
				.setColorFill(COLOR_BLACK)
				.rect(DISPLAY_WIDTH/2 - (114+72), 400, 72, 24)
				.setStrokeLineWidth(lineWidth.page_sms.pylons_box)
				.hide();
			me.p2L_text = me.group.createChild("text", "p2L_text")
				.setFontSize(font.page_sms.pylons_text)
				.setColor(COLOR_YELLOW)
				.setAlignment("left-center")
				.setTranslation(DISPLAY_WIDTH/2 - (114+72), 400 + 24/2);
			me.p2L_text.enableUpdate();

			# Pylon 2R (position 5)
			me.p2R_box = me.group.createChild("path", "p2R_box")
				.setColor(COLOR_YELLOW)
				.setColorFill(COLOR_BLACK)
				.rect(DISPLAY_WIDTH/2 + 114, 400, 72, 24)
				.setStrokeLineWidth(lineWidth.page_sms.pylons_box)
				.hide();
			me.p2R_text = me.group.createChild("text", "p2R_text")
				.setFontSize(font.page_sms.pylons_text)
				.setColor(COLOR_YELLOW)
				.setAlignment("right-center")
				.setTranslation(DISPLAY_WIDTH/2 + (114+72), 400 + 24/2);
			me.p2R_text.enableUpdate();

			# Pylon 4L (position 7)
			me.p4L_box = me.group.createChild("path", "p4L_box")
				.setColor(COLOR_YELLOW)
				.setColorFill(COLOR_BLACK)
				.rect(DISPLAY_WIDTH/2 - (10+72), 390, 72, 24)
				.setStrokeLineWidth(lineWidth.page_sms.pylons_box)
				.hide();
			me.p4L_text = me.group.createChild("text", "p4L_text")
				.setFontSize(font.page_sms.pylons_text)
				.setColor(COLOR_YELLOW)
				.setAlignment("left-center")
				.setTranslation(DISPLAY_WIDTH/2 - (10+72), 390 + 24/2);
			me.p4L_text.enableUpdate();

			# Pylon 4R (position 8)
			me.p4R_box = me.group.createChild("path", "p4R_box")
				.setColor(COLOR_YELLOW)
				.setColorFill(COLOR_BLACK)
				.rect(DISPLAY_WIDTH/2 + 10, 390, 72, 24)
				.setStrokeLineWidth(lineWidth.page_sms.pylons_box)
				.hide();
			me.p4R_text = me.group.createChild("text", "p4R_text")
				.setFontSize(font.page_sms.pylons_text)
				.setColor(COLOR_YELLOW)
				.setAlignment("right-center")
				.setTranslation(DISPLAY_WIDTH/2 + (10+72), 390 + 24/2);
			me.p4R_text.enableUpdate();

			# Cannon left (also used for number of bullets in gun pod)
			me.caL_box = me.group.createChild("path", "caL_box")
				.setColor(COLOR_YELLOW)
				.setColorFill(COLOR_BLACK)
				.rect(DISPLAY_WIDTH/2 - (132+48), 108, 48, 24)
				.setStrokeLineWidth(lineWidth.page_sms.pylons_box)
				.hide();
			me.caL_text = me.group.createChild("text", "caL_text")
				.setFontSize(font.page_sms.pylons_text)
				.setColor(COLOR_YELLOW)
				.setAlignment("right-center") # yes it is a deviation from what we do otherwise
				.setTranslation(DISPLAY_WIDTH/2 - 132, 108 + 24/2);
			me.caL_text.enableUpdate();

			# Cannon right
			me.caR_box = me.group.createChild("path", "caR_box")
				.setColor(COLOR_YELLOW)
				.setColorFill(COLOR_BLACK)
				.rect(DISPLAY_WIDTH/2 + 132, 108, 48, 24)
				.setStrokeLineWidth(lineWidth.page_sms.pylons_box)
				.hide();
			me.caR_text = me.group.createChild("text", "caR_text")
				.setFontSize(font.page_sms.pylons_text)
				.setColor(COLOR_YELLOW)
				.setAlignment("right-center") # yes it is a deviation from what we do otherwise
				.setTranslation(DISPLAY_WIDTH/2 + (132+48), 108 + 24/2);
			me.caR_text.enableUpdate();
		},

		enter: func {
			# printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = FALSE;
			}
			me.device.resetControls();
			me.device.controls[OSB2].setControlText(PAGE_SMS_MENU_ITEM, TRUE, FALSE, TRUE);
			me._toggle_fbw_mode(me.input.fbw_mode.getValue());
		},

		controlAction: func (controlName) {
			# printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == OSB2) {
				me.device.system.selectPage(PAGE_HUB);
			} elsif (controlName == OSB32) {
				me._toggle_fbw_mode(0);
			} elsif (controlName == OSB33) {
				me._toggle_fbw_mode(1);
			}
		},

		_toggle_fbw_mode: func (mode) {
			me.input.fbw_mode.setValue(mode);
			if (mode == 0) {
				me.device.controls[OSB32].setControlText(me.FBW_AA_MENU_ITEM, TRUE, TRUE);
				me.device.controls[OSB33].setControlText(me.FBW_CHARGES_MENU_ITEM, TRUE, FALSE);
			} else {
				me.device.controls[OSB32].setControlText(me.FBW_AA_MENU_ITEM, TRUE, FALSE);
				me.device.controls[OSB33].setControlText(me.FBW_CHARGES_MENU_ITEM, TRUE, TRUE);
			}
		},

		update: func (noti = nil) {
			if (noti.FrameCount != 3) {
				return;
			}

			me.catNumber = pylons.fcs.getCategory(); # catNumber is 1 or 2 - mode is 0 or 1
			me.fbw_mode_text.updateText(sprintf("Load type:\n%s", me.catNumber==1?"A/A":"Charges"));
			if (me.catNumber != me.input.fbw_mode.getValue() + 1) {
				me.fbw_mode_text.setColor(COLOR_RED);
			} else {
				me.fbw_mode_text.setColor(COLOR_CYAN);
			}

			var sel = pylons.fcs.getSelectedPylonNumber();
			me.p1L_box.setVisible(sel==0);
			me.p1R_box.setVisible(sel==6);
			me.p2L_box.setVisible(sel==1);
			me.p2R_box.setVisible(sel==5);
			me.p3C_box.setVisible(sel==3);
			me.p3L_box.setVisible(sel==2);
			me.p3R_box.setVisible(sel==4);
			me.p4L_box.setVisible(sel==7);
			me.p4R_box.setVisible(sel==8);
			me.caL_box.setVisible(sel==9);
			me.caR_box.setVisible(sel==9);

			if (variantID == constants.VARIANT_5) {
				me.caL_text.updateText(sprintf("%3d", pylons.pylonI.getAmmo()/2));
				me.caR_text.updateText(sprintf("%3d", pylons.pylonI.getAmmo()/2));
			} elsif (variantID == constants.VARIANT_D) {
				if (pylons.has_cc442() == TRUE) {
					me.caL_text.updateText(sprintf("%3d", pylons.pylon1.getAmmo()));
				} else {
					me.caL_text.updateText("");
				}
				me.caR_text.updateText("");
			} else {
				me.caL_text.updateText("");
				me.caR_text.updateText("");
			}

			me._setTextOnStation(me.p1L_text, pylons.pylon1);
			me._setTextOnStation(me.p2L_text, pylons.pylon2);
			me._setTextOnStation(me.p3L_text, pylons.pylon3);
			me._setTextOnStation(me.p3C_text, pylons.pylon4);
			me._setTextOnStation(me.p3R_text, pylons.pylon5);
			me._setTextOnStation(me.p2R_text, pylons.pylon6);
			me._setTextOnStation(me.p1R_text, pylons.pylon7);
			me._setTextOnStation(me.p4L_text, pylons.pylon8);
			me._setTextOnStation(me.p4R_text, pylons.pylon9);
		},

		_setTextOnStation: func (text_obj, pylon) {
			if (pylon == nil or pylon.currentSet == nil or size(pylon.currentSet.content) == 0) {
				text_obj.updateText("");
			} else {
				me.size_weapons = 0;
				foreach (me.weapon; pylon.weapons) {
					if (me.weapon != nil) {
						me.size_weapons += 1;
					}
				}
				if (me.size_weapons == 0) {
					text_obj.updateText("");
				} else {
					me.sms_helper = pylons.pylonSetsSMSHelper[pylon.currentSet.name];
					if (me.sms_helper[1] == TRUE) {
						text_obj.updateText(me.size_weapons~" "~me.sms_helper[0]);
					} else {
						text_obj.updateText(me.sms_helper[0]);
					}
				}
			}
		},

		exit: func {
			# printDebug("Exit ",me.name~" on ",me.device.name);
		},

		links: {
			OSB3: PAGE_PPA,
		},

		layers: [LAYER_SERVICEABLE],
	},


#  ██████   █████   ██████  ███████     ██████  ██████   █████
#  ██   ██ ██   ██ ██       ██          ██   ██ ██   ██ ██   ██
#  ██████  ███████ ██   ███ █████       ██████  ██████  ███████
#  ██      ██   ██ ██    ██ ██          ██      ██      ██   ██
#  ██      ██   ██  ██████  ███████     ██      ██      ██   ██


	PagePPA: { # Poste de Préparation Armement
		name: PAGE_PPA,
		isNew: TRUE,
		needGroup: TRUE,

		new: func {
			me.instance = {parents:[DisplaySystem.PagePPA]};
			me.instance.group = nil;
			return me.instance;
		},

		setup: func {
			me.input = {
				cannon_rate_0              : "/ai/submodels/submodel/delay",
				damage                     : "payload/armament/msg",
				antiradar_target_type      : "controls/armament/antiradar-target-type",
				cannon_air_ground          : "controls/armament/cannon-air-ground",
				cannon_air_air_incitation  : "controls/armament/cannon-air-air-incitation",
				cannon_air_air_wingspan    : "controls/armament/cannon-air-air-wingspan",
			};

			foreach(var name; keys(me.input)) {
				me.input[name] = props.globals.getNode(me.input[name], 1);
			}

			me.wow = FALSE;

			me.fuze = 0; # there are no real fuze settings in OPRF, so just faking

			me.wpn_text = me.group.createChild("text", "wpn_text")
				.setFontSize(font.page_ppa.wpn_text)
				.setColor(COLOR_CYAN)
				.setAlignment("center-center")
				.setTranslation(DISPLAY_WIDTH/2, DISPLAY_HEIGHT/2 + 80);
			me.wpn_text.enableUpdate();
			me.ammo_text = me.group.createChild("text", "ammo_text")
				.setFontSize(font.page_ppa.ammo_text)
				.setColor(COLOR_CYAN)
				.setAlignment("center-center")
				.setTranslation(DISPLAY_WIDTH/2, DISPLAY_HEIGHT/2 + 120);
			me.ammo_text.enableUpdate();
			me.row_1_right_text = me.group.createChild("text", "row_1_right_text")
				.setFontSize(font.device.row_text)
				.setColor(COLOR_GREEN)
				.setAlignment("right-center")
				.setTranslation(DISPLAY_WIDTH - margin.device.row_text, DISPLAY_ROW_HEIGHT_1);
			me.row_1_right_text.enableUpdate();
			me.row_2_right_text = me.group.createChild("text", "row_2_right_text")
				.setFontSize(font.device.row_text)
				.setColor(COLOR_GREEN)
				.setAlignment("right-center")
				.setTranslation(DISPLAY_WIDTH - margin.device.row_text, DISPLAY_ROW_HEIGHT_2);
			me.row_2_right_text.enableUpdate();
			me.row_3_right_text = me.group.createChild("text", "row_3_right_text")
				.setFontSize(font.device.row_text)
				.setColor(COLOR_GREEN)
				.setAlignment("right-center")
				.setTranslation(DISPLAY_WIDTH - margin.device.row_text, DISPLAY_ROW_HEIGHT_3);
			me.row_3_right_text.enableUpdate();
			me.row_4_right_text = me.group.createChild("text", "row_4_right_text")
				.setFontSize(font.device.row_text)
				.setColor(COLOR_GREEN)
				.setAlignment("right-center")
				.setTranslation(DISPLAY_WIDTH - margin.device.row_text, DISPLAY_ROW_HEIGHT_4);
			me.row_4_right_text.enableUpdate();
			me.damage_label = me.group.createChild("text", "damage_label")
				.setFontSize(font.page_ppa.damage_text)
				.setColor(COLOR_WHITE)
				.setAlignment("right-center")
				.setTranslation(DISPLAY_WIDTH/2, 100)
				.setText("Damage:");
			me.damage_text = me.group.createChild("text", "damage_text")
				.setFontSize(font.page_ppa.damage_text)
				.setColor(COLOR_CYAN)
				.setAlignment("left-center")
				.setTranslation(DISPLAY_WIDTH/2 + 10, 100);
			me.damage_text.enableUpdate();
		},

		_changeWingspan: func(increase) {
			me.input.cannon_air_air_wingspan.setValue(me.input.cannon_air_air_wingspan.getValue() + increase);
			if (me.input.cannon_air_air_wingspan.getValue() > 40) {
				me.input.cannon_air_air_wingspan.setValue(7); # value is between 7 and 40 metres
			}
		},

		enter: func {
			# printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = FALSE;
			}
			me.device.resetControls();
			me.device.controls[OSB2].setControlText(PAGE_PPA_MENU_ITEM, TRUE, FALSE, TRUE);
		},

		controlAction: func (controlName) {
			# printDebug(me.name,": ",controlName," activated on ",me.device.name);
			me.wpn = pylons.fcs.getSelectedWeapon();
			if (controlName == OSB2) {
				me.device.system.selectPage(PAGE_HUB);
			} elsif (controlName == OSB6) {
				if (me.wpn_kind == WPN_KIND_FALL) {
					me.fuze += 1;
					if (me.fuze > 2) {
						me.fuze = 0;
					}
				} else if (me.wpn_kind == WPN_KIND_ARMAT) {
					if (me.wow == TRUE) { # cannot change in flight
						me.input.antiradar_target_type.setValue(me.input.antiradar_target_type.getValue() + 1);
						if (me.input.antiradar_target_type.getValue() >2) {
							me.input.antiradar_target_type.setValue(0);
						}
					}
				} elsif (me.wpn_kind == WPN_KIND_CANNON) {
					if (me.input.cannon_air_air_incitation.getValue() == TRUE) {
						me.input.cannon_air_air_incitation.setValue(FALSE);
					} else {
						me.input.cannon_air_air_incitation.setValue(TRUE);
					}
				}
			} elsif (controlName == OSB9) {
				if (me.wpn != nil and contains(me.wpn, "powerOnRequired") and me.wpn["powerOnRequired"] == TRUE) {
					me.wpn.togglePowerOn();
				}
			} elsif (controlName == OSB12) {
				if (me.wpn_kind == WPN_KIND_CANNON) {
					_changeCannonRate(TRUE);
				}
			} elsif (controlName == OSB23) {
				if (me.wpn_kind == WPN_KIND_CANNON) {
					_changeCannonRate(FALSE);
				}
			} elsif (controlName == OSB25) {
				if (me.wpn_kind == WPN_KIND_CANNON) {
					me.input.cannon_air_ground.setValue(FALSE); # air to air
				}
			} elsif (controlName == OSB26) {
				if (me.wpn_kind == WPN_KIND_CANNON) {
					me.input.cannon_air_ground.setValue(TRUE); # air to ground
				}
			} elsif (controlName == OSB28) {
				if (me.wpn_kind == WPN_KIND_FALL) {
					if (me.rp < 18) {
						pylons.fcs.setRippleMode(me.rp + 1);
					}
				}
			} elsif (controlName == OSB29) {
				if (me.wpn_kind == WPN_KIND_FALL) {
					if (me.rp > 1) {
						pylons.fcs.setRippleMode(me.rp - 1);
					}
				}
			} elsif (controlName == OSB32) {
				if (me.wpn_kind == WPN_KIND_CANNON) {
					me._changeWingspan(1);
				} else if (me.wpn_kind == WPN_KIND_FALL) {
					if (me.rpd == 5) {
						pylons.fcs.setRippleDist(10);
					} elsif (me.rpd < 200) {
						pylons.fcs.setRippleDist(me.rpd + 10);
					}
				}
			} elsif (controlName == OSB33) {
				if (me.wpn_kind == WPN_KIND_CANNON) {
					me._changeWingspan(5);
				} else if (me.wpn_kind == WPN_KIND_FALL) {
					if (me.rpd == 10) {
						pylons.fcs.setRippleDist(5);
					} elsif (me.rpd > 10) {
						pylons.fcs.setRippleDist(me.rpd - 10);
					}
				}
			}
		},

		update: func (noti = nil) {
			if (noti.FrameCount != 3) {
				return;
			}
			if (noti.getproper("wow")) {
				me.wow = TRUE;
			} else {
				me.wow = FALSE;
			}
			me.wpn = pylons.fcs.getSelectedWeapon();
			me.pylon = pylons.fcs.getSelectedPylon();

			me.wpn_kind = "";  # class of weapons for use just here

			me.osb6 = "";
			me.osb6_selected = FALSE;
			me.osb9 = ""; # reserved for Power On/Off
			me.osb9_selected = FALSE;
			me.osb22 = "";
			me.osb22_selected = FALSE;
			me.osb23 = "";
			me.osb23_selected = FALSE;
			me.osb25 = "";
			me.osb25_selected = FALSE;
			me.osb26 = "";
			me.osb26_selected = FALSE;
			me.osb28 = "";
			me.osb29 = "";
			me.osb32 = "";
			me.osb33 = "";

			me.row_1_right_text.hide();
			me.row_2_right_text.hide();
			me.row_3_right_text.hide();
			me.row_4_right_text.hide();

			if (me.wpn == nil) {
				me.wpn_text.updateText("No weapon selected");
				me.ammo_text.updateText("");
			} else {
				me.wpn_text.updateText(me.wpn.type);
				me.ammo_text.updateText("Ammo: "~pylons.fcs.getAmmo());

				if (contains(me.wpn, "powerOnRequired") and me.wpn["powerOnRequired"] == TRUE) { # most guided weapons - therefore use a generic approach
					me.osb9 = me.wpn.isPowerOn()?"PWR ON":"PWR OFF";
					me.osb9_selected = TRUE;
				}

				if (me.wpn.type == "CC422" or me.wpn.type == "30mm Cannon") {
					me.wpn_kind = WPN_KIND_CANNON;
					me.cannon_rate = me.input.cannon_rate_0.getValue();
					if (me.wpn.type == "30mm Cannon") {
						me.osb22 = "High";
						me.osb23 = "Low";
						if (me.cannon_rate > 0.04) {
							me.osb23_selected = TRUE;
						} else {
							me.osb22_selected = TRUE;
						}
						me.row_1_right_text.updateText("Fire rate:");
						me.row_1_right_text.show();
					} # else: the rate cannot be changed in the CC422 gun pod

					me.osb25 = "A/A";
					me.osb26 = "A/G";
					if (me.input.cannon_air_ground.getValue()) {
						me.osb26_selected = TRUE;
					} else {
						me.osb25_selected = TRUE;
					}
					me.row_2_right_text.updateText("Mode:");
					me.row_2_right_text.show();

					me.osb32 = "+1";
					me.osb33 = "+5";
					me.row_4_right_text.updateText("Wingspan: "~me.input.cannon_air_air_wingspan.getValue());
					me.row_4_right_text.show();

					if (me.input.cannon_air_air_incitation.getValue() == TRUE) {
						me.osb6 = "PRED";
					} else {
						me.osb6 = "CCLT";
					}
					me.osb6_selected = TRUE;
				} else if (me.wpn.type == "Mk-82" or me.wpn.type == "Mk-82SE" or me.wpn.type == "GBU-12" or me.wpn.type == "GBU-24") {
					me.wpn_kind = WPN_KIND_FALL;

					me.row_3_right_text.show();
					me.rp = pylons.fcs.getRippleMode();
					me.row_3_right_text.updateText("Ripple: "~me.rp);
					if (me.rp < 18) { # according to RAZBAM manual page 506
						me.osb28 = OSB_PLUS;
					}
					if (me.rp > 1) { # the Mirage can set it to 0, but setRippleMode in fire-control.nas will keep a min of 1
						me.osb29 = OSB_MINUS;
					}

					if (me.rp > 1) {
						me.rpd = pylons.fcs.getRippleDist();
						me.row_4_right_text.show();
						me.row_4_right_text.updateText("Dist m: "~me.rpd);
						if (me.rpd < 200) { # according to RAZBAM manual page 508 200m is max
							me.osb32 = OSB_PLUS;
						}
						if (me.rpd > 5) { # according to RAZBAM manual page 508 it could be set to 0, but we cannot model that easily. Therefore 5
							me.osb33 = OSB_MINUS;
						}
					}

					# fuze is just for display - has no meaning in OPRF (not the same as arming time)
					if (me.fuze == 0) {
						me.osb6 = "INST.";
					} elsif (me.fuze == 1) {
						me.osb6 = "RET.";
					} else {
						me.osb6 = "INERT.";
					}
					me.osb6_selected = TRUE;
				} else if (me.wpn.type == "AS-37-Armat") {
					me.wpn_kind = WPN_KIND_ARMAT;
					if (me.input.antiradar_target_type.getValue() == 0) {
						me.osb6 = "GROUND";
					} elsif (me.input.antiradar_target_type.getValue() == 1) {
						me.osb6 = "SHIP";
					} else {
						me.osb6 = "SAM";
					}
					me.osb6_selected = TRUE;
				}
			}

			if (me.input.damage.getValue()) {
				me.damage_text.updateText("On");
				me.damage_text.setColor(COLOR_GREEN);
			} else {
				me.damage_text.updateText("Off");
				me.damage_text.setColor(COLOR_CYAN);
			}

			me.device.controls[OSB6].setControlText(me.osb6, TRUE, me.osb6_selected);
			me.device.controls[OSB9].setControlText(me.osb9, TRUE, me.osb9_selected);
			me.device.controls[OSB22].setControlText(me.osb22, TRUE, me.osb22_selected);
			me.device.controls[OSB23].setControlText(me.osb23, TRUE, me.osb23_selected);
			me.device.controls[OSB25].setControlText(me.osb25, TRUE, me.osb25_selected);
			me.device.controls[OSB26].setControlText(me.osb26, TRUE, me.osb26_selected);
			me.device.controls[OSB28].setControlText(me.osb28);
			me.device.controls[OSB29].setControlText(me.osb29);
			me.device.controls[OSB32].setControlText(me.osb32);
			me.device.controls[OSB33].setControlText(me.osb33);
		},

		exit: func {
			# printDebug("Exit ",me.name~" on ",me.device.name);
		},

		links: {
			OSB3: PAGE_RWR,
		},

		layers: [LAYER_SERVICEABLE],
	},


#  ██████   █████   ██████  ███████     ██████  ██     ██ ██████
#  ██   ██ ██   ██ ██       ██          ██   ██ ██     ██ ██   ██
#  ██████  ███████ ██   ███ █████       ██████  ██  █  ██ ██████
#  ██      ██   ██ ██    ██ ██          ██   ██ ██ ███ ██ ██   ██
#  ██      ██   ██  ██████  ███████     ██   ██  ███ ███  ██   ██

	PageRWR: {
		name: PAGE_RWR,
		isNew: TRUE,
		needGroup: TRUE,

		new: func {
			me.instance = {parents:[DisplaySystem.PageRWR]};
			me.instance.group = nil;
			return me.instance;
		},

		setup: func {
			me.input = {
				flares                    : "rotors/main/blade[3]/flap-deg", # see weapons.nas
				# chaff                     : "rotors/main/blade[3]/position-deg", # not needed because same as flares
				cm_remaining              : "/ai/submodels/submodel[7]/count",
				semiactive_callsign       : "payload/armament/MAW-semiactive-callsign",
				maw_active                : "payload/armament/MAW-active",
				maw_bearing               : "payload/armament/MAW-bearing",
				launch_callsign           : "sound/rwr-launch",
				sound_rwr_threat_new      : "sound/rwr-threat-new",
				sound_rwr_threat_stt      : "sound/rwr-threat-stt",
				sound_rwr_maw_semi_active : "sound/rwr-maw-semi-active",
				sound_rwr_maw_active      : "sound/rwr-maw-active",
				heading_true              : "orientation/heading-deg",
			};

			foreach(var name; keys(me.input)) {
				me.input[name] = props.globals.getNode(me.input[name], 1);
			}

			me.max_icons = 12; # what is displayed as threats. +1 for 1 tracked missile (i.e. 12+1 = 13)
			me.radius = 0.8 * DISPLAY_HEIGHT/2; # we want a bit of space around the circle
			me.high_threat_radius = me.radius*0.45; # where to put the high threat symbols
			me.missile_radius = me.radius*0.2; # where to put the missile(s)
			me.lower_threat_radius = me.radius*0.8; # where to put the lower threat symbols
			me.unknown_threat_radius = me.radius*0.9; # where to put threats that are unknown or searching
			me.circle_radius_middle = me.radius*0.55;

			# for active separation
			me.sep1_radius = me.radius*0.400;
			me.sep2_radius = me.radius*0.525;
			me.sep3_radius = me.radius*0.775;

			me.AIRCRAFT_UNKNOWN  = "U";
			me.ASSET_AI          = "AI";
			me.AIRCRAFT_SEARCH   = "S";

			me.TICK_LENGTH_SHORT = 10;
			me.TICK_LENGTH_LONG = 20;

			me.DISPENSER_BOX_WIDTH = 60;
			me.DISPENSER_BOX_SEPARATION = 16;


			me.rwr_circles_group = me.group.createChild("group", "rwr_circles_group")
				.setTranslation(DISPLAY_WIDTH/2, DISPLAY_HEIGHT/2); # in the middle of the screen
			me._createRWRCircles();
			me._createRWRSymbols();

			me.dispenser_group = me.group.createChild("group", "dispenser_group")
				.setTranslation(DISPLAY_WIDTH-me.DISPENSER_BOX_WIDTH-me.DISPENSER_BOX_SEPARATION, 6*me.DISPENSER_BOX_SEPARATION);
			me._createDispenserIndicators();

			me.prev_contacts = [];
			me.prev_stt = [];

			me.last_update_inc = 0;
			me.alternated = FALSE; # toggles every ca. UPDATE_INC seconds between TRUE and FALSE

			# whether or not to show unknowns
			me.show_unknowns = TRUE;
			me.SHOW_UNKNOWNS_MENU_ITEM = "Y";
			me.HIDE_UNKNOWNS_MENU_ITEM = "N";

			me.row_4_left_text = me.group.createChild("text", "row_4_right_text")
				.setFontSize(font.device.row_text)
				.setColor(COLOR_GREEN)
				.setAlignment("left-center")
				.setTranslation(margin.device.row_text, DISPLAY_ROW_HEIGHT_4)
				.setText("Show unk.");

			# whether to reduce overlapping (at the expense of angle accuracy)
			me.separate = FALSE;
			me.SEPARATE_ACTIVE_MENU_ITEM = "Y";
			me.SEPARATE_NONE_MENU_ITEM = "N";

			me.row_1_left_text = me.group.createChild("text", "row_4_right_text")
				.setFontSize(font.device.row_text)
				.setColor(COLOR_GREEN)
				.setAlignment("left-center")
				.setTranslation(margin.device.row_text, DISPLAY_ROW_HEIGHT_1)
				.setText("Sep.");
		},

		_createRWRCircles: func() {
			me.rwr_circles_group.createChild("path") # cross in the middle
				.moveTo(-me.TICK_LENGTH_SHORT, 0)
				.lineTo(me.TICK_LENGTH_SHORT, 0)
				.moveTo(0, -me.TICK_LENGTH_SHORT)
				.lineTo(0, me.TICK_LENGTH_SHORT)
				.setStrokeLineWidth(lineWidth.page_rwr.lines_rwr)
				.setColor(COLOR_WHITE);
			me.rwr_circles_group.createChild("path") # middle circle
				.moveTo(-me.circle_radius_middle, 0)
				.arcSmallCW(me.circle_radius_middle, me.circle_radius_middle, 0, me.circle_radius_middle*2, 0)
				.arcSmallCW(me.circle_radius_middle, me.circle_radius_middle, 0, -me.circle_radius_middle*2, 0)
				.setStrokeLineWidth(lineWidth.page_rwr.lines_rwr)
				.setColor(COLOR_CYAN);
			me.rwr_circles_group.createChild("path") # outer circle
				.moveTo(-me.radius, 0)
				.arcSmallCW(me.radius, me.radius, 0, me.radius*2, 0)
				.arcSmallCW(me.radius, me.radius, 0, -me.radius*2, 0)
				.setStrokeLineWidth(lineWidth.page_rwr.lines_rwr)
				.setColor(COLOR_WHITE);
			me.rwr_circles_group.createChild("path") # large ticks around the circle
				.moveTo(me.radius, 0)
				.horiz(me.TICK_LENGTH_LONG) # 90
				.moveTo(-me.radius, 0)
				.horiz(-me.TICK_LENGTH_LONG) # 270
				.moveTo(0, me.radius)
				.vert(me.TICK_LENGTH_LONG) # 180
				.moveTo(0, -me.radius)
				.vert(-me.TICK_LENGTH_LONG) # 0 / 360
				.setStrokeLineWidth(lineWidth.page_rwr.lines_rwr * 2)
				.setColor(COLOR_WHITE);
			var rad_30 = 30 * D2R;
			var rad_60 = 60 * D2R;
			me.rwr_circles_group.createChild("path") # ticks like clock at outer ring
				.moveTo(me.radius*math.cos(rad_30),me.radius*math.sin(-rad_30))
				.lineTo((me.radius+me.TICK_LENGTH_SHORT)*math.cos(rad_30),(me.radius+me.TICK_LENGTH_SHORT)*math.sin(-rad_30))
				.moveTo(me.radius*math.cos(rad_60),me.radius*math.sin(-rad_60))
				.lineTo((me.radius+me.TICK_LENGTH_SHORT)*math.cos(rad_60),(me.radius+me.TICK_LENGTH_SHORT)*math.sin(-rad_60))
				.moveTo(me.radius*math.cos(rad_30),me.radius*math.sin(rad_30))
				.lineTo((me.radius+me.TICK_LENGTH_SHORT)*math.cos(rad_30),(me.radius+me.TICK_LENGTH_SHORT)*math.sin(rad_30))
				.moveTo(me.radius*math.cos(rad_60),me.radius*math.sin(rad_60))
				.lineTo((me.radius+me.TICK_LENGTH_SHORT)*math.cos(rad_60),(me.radius+me.TICK_LENGTH_SHORT)*math.sin(rad_60))

				.moveTo(-me.radius*math.cos(rad_30),me.radius*math.sin(-rad_30))
				.lineTo(-(me.radius+me.TICK_LENGTH_SHORT)*math.cos(rad_30),(me.radius+me.TICK_LENGTH_SHORT)*math.sin(-rad_30))
				.moveTo(-me.radius*math.cos(rad_60),me.radius*math.sin(-rad_60))
				.lineTo(-(me.radius+me.TICK_LENGTH_SHORT)*math.cos(rad_60),(me.radius+me.TICK_LENGTH_SHORT)*math.sin(-rad_60))
				.moveTo(-me.radius*math.cos(rad_30),me.radius*math.sin(rad_30))
				.lineTo(-(me.radius+me.TICK_LENGTH_SHORT)*math.cos(rad_30),(me.radius+me.TICK_LENGTH_SHORT)*math.sin(rad_30))
				.moveTo(-me.radius*math.cos(rad_60),me.radius*math.sin(rad_60))
				.lineTo(-(me.radius+me.TICK_LENGTH_SHORT)*math.cos(rad_60),(me.radius+me.TICK_LENGTH_SHORT)*math.sin(rad_60))
				.setStrokeLineWidth(lineWidth.page_rwr.lines_rwr)
				.setColor(COLOR_WHITE);
		},
		_createRWRSymbols: func() {
			me.texts = setsize([], me.max_icons+1);
			for (var i = 0; i < me.max_icons+1; i+=1) {
				me.texts[i] = me.rwr_circles_group.createChild("text")
					.setAlignment("center-center")
					.setColor(COLOR_YELLOW)
					.setFontSize(font.page_rwr.threat_text)
					.hide();
				me.texts[i].enableUpdate();
				if (i == me.max_icons) {
					me.texts[i].updateText("W"); # will not change -> missile
				} else {
					me.texts[i].updateText("00");
				}
			}

			me.symbol_hat = setsize([], me.max_icons+1); # supporting active missile
			for (var i = 0; i < me.max_icons+1; i+=1) {
				me.symbol_hat[i] = me.rwr_circles_group.createChild("path")
					.moveTo(0, -font.page_rwr.symbols_dist)
					.lineTo(font.page_rwr.symbols_dist*0.9, -font.page_rwr.symbols_dist*0.6)
					.moveTo(0, -font.page_rwr.symbols_dist)
					.lineTo(-font.page_rwr.symbols_dist*0.9, -font.page_rwr.symbols_dist*0.6)
					.setStrokeLineWidth(lineWidth.page_rwr.lines_rwr)
					.setColor(COLOR_YELLOW)
					.hide();
			}

			me.symbol_chevron = setsize([], me.max_icons+1); # STT / spike
			for (var i = 0; i < me.max_icons+1; i+=1) {
				me.symbol_chevron[i] = me.rwr_circles_group.createChild("path")
					.moveTo(0, font.page_rwr.symbols_dist)
					.lineTo(font.page_rwr.symbols_dist*0.9, font.page_rwr.symbols_dist*0.6)
					.moveTo(0, font.page_rwr.symbols_dist)
					.lineTo(-font.page_rwr.symbols_dist*0.9, font.page_rwr.symbols_dist*0.6)
					.setStrokeLineWidth(lineWidth.page_rwr.lines_rwr)
					.setColor(COLOR_YELLOW)
					.hide();
			}
		},

		_createDispenserIndicators: func {
			# Lance-Leurres (Decoy Dispenser)
			me.ll_box  = me.dispenser_group.createChild("path", "ll_box")
				.setColor(COLOR_CYAN)
				.setColorFill(COLOR_BLACK)
				.rect(0, 0, me.DISPENSER_BOX_WIDTH, me.DISPENSER_BOX_WIDTH)
				.setStrokeLineWidth(lineWidth.page_rwr.lines_indicators);
			me.ll_text = me.dispenser_group.createChild("text", "ll_text")
				.setFontSize(font.page_rwr.indicators_text)
				.setColor(COLOR_CYAN)
				.setAlignment("center-center")
				.setText("LL")
				.setTranslation(me.DISPENSER_BOX_WIDTH/2, me.DISPENSER_BOX_WIDTH/2);

			# Contremesures Électromagnétiques/Chaff
			var add_down = me.DISPENSER_BOX_WIDTH + me.DISPENSER_BOX_SEPARATION;
			me.em_box  = me.dispenser_group.createChild("path", "em_box")
				.setColor(COLOR_MAGENTA)
				.setColorFill(COLOR_BLACK)
				.rect(0, add_down, me.DISPENSER_BOX_WIDTH, me.DISPENSER_BOX_WIDTH)
				.setStrokeLineWidth(lineWidth.page_rwr.lines_indicators);
			me.em_text = me.dispenser_group.createChild("text", "em_text")
				.setFontSize(font.page_rwr.indicators_text)
				.setColor(COLOR_MAGENTA)
				.setAlignment("center-center")
				.setText("EM")
				.setTranslation(me.DISPENSER_BOX_WIDTH/2, add_down + me.DISPENSER_BOX_WIDTH/2);
			# IR (Contremesures Infrarouges/Flares)
			var add_down = 2*(me.DISPENSER_BOX_WIDTH + me.DISPENSER_BOX_SEPARATION);
			me.ir_box  = me.dispenser_group.createChild("path", "ir_box")
				.setColor(COLOR_MAGENTA)
				.setColorFill(COLOR_BLACK)
				.rect(0, add_down, me.DISPENSER_BOX_WIDTH, me.DISPENSER_BOX_WIDTH)
				.setStrokeLineWidth(lineWidth.page_rwr.lines_indicators);
			me.ir_text = me.dispenser_group.createChild("text", "ir_text")
				.setFontSize(font.page_rwr.indicators_text)
				.setColor(COLOR_MAGENTA)
				.setAlignment("center-center")
				.setText("IR")
				.setTranslation(me.DISPENSER_BOX_WIDTH/2, add_down + me.DISPENSER_BOX_WIDTH/2);
			# EO (Contremesures Électro-optiques/Electro-Optical
			var add_down = 3*(me.DISPENSER_BOX_WIDTH + me.DISPENSER_BOX_SEPARATION);
			me.eo_box  = me.dispenser_group.createChild("path", "eo_box")
				.setColor(COLOR_MAGENTA)
				.setColorFill(COLOR_BLACK)
				.rect(0, add_down, me.DISPENSER_BOX_WIDTH, me.DISPENSER_BOX_WIDTH)
				.setStrokeLineWidth(lineWidth.page_rwr.lines_indicators);
			me.eo_text = me.dispenser_group.createChild("text", "eo_text")
				.setFontSize(font.page_rwr.indicators_text)
				.setColor(COLOR_MAGENTA)
				.setAlignment("center-center")
				.setText("EO")
				.setTranslation(me.DISPENSER_BOX_WIDTH/2, add_down + me.DISPENSER_BOX_WIDTH/2);
		},

		enter: func {
			# printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = FALSE;
			}
			me.device.resetControls();
			me.device.controls[OSB2].setControlText(PAGE_RWR_MENU_ITEM, TRUE, FALSE, TRUE);

			me._toggle_show_unknowns(me.show_unknowns);
			me._toggle_separate(me.separate);
		},

		controlAction: func (controlName) {
			# printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == OSB2) {
				me.device.system.selectPage(PAGE_HUB);
			} elsif (controlName == OSB10) {
				me._toggle_separate(TRUE);
			} elsif (controlName == OSB11) {
				me._toggle_separate(FALSE);
			}
			if (controlName == OSB20) {
				me._toggle_show_unknowns(TRUE);
			} elsif (controlName == OSB21) {
				me._toggle_show_unknowns(FALSE);
			}
		},

		_toggle_show_unknowns: func (show) {
			me.show_unknowns = show;
			if (me.show_unknowns) {
				me.device.controls[OSB20].setControlText(me.SHOW_UNKNOWNS_MENU_ITEM, TRUE, TRUE);
				me.device.controls[OSB20].setControlText(me.HIDE_UNKNOWNS_MENU_ITEM, TRUE, FALSE);
			} else {
				me.device.controls[OSB20].setControlText(me.SHOW_UNKNOWNS_MENU_ITEM, TRUE, FALSE);
				me.device.controls[OSB21].setControlText(me.HIDE_UNKNOWNS_MENU_ITEM, TRUE, TRUE);
			}
		},

		_toggle_separate: func (do_separate) {
			me.separate = do_separate;
			if (me.separate) {
				me.device.controls[OSB10].setControlText(me.SEPARATE_ACTIVE_MENU_ITEM, TRUE, TRUE);
				me.device.controls[OSB11].setControlText(me.SEPARATE_NONE_MENU_ITEM, TRUE, FALSE);
			} else {
				me.device.controls[OSB10].setControlText(me.SEPARATE_ACTIVE_MENU_ITEM, TRUE, FALSE);
				me.device.controls[OSB11].setControlText(me.SEPARATE_NONE_MENU_ITEM, TRUE, TRUE);
			}
		},

		_assign_sep_spot: func {
			# Copy from F16
			# me.dev        angle_deg
			# me.sep_spots  0 to 2  45, 20, 15
			# me.threat     0 to 2
			# me.sep_angles
			# return   me.dev,  me.threat
			me.newdev = me.dev;
			me._assign_ideal_sep_spot();
			me.plus = me.sep_angles[me.threat];
			me.dir  = 0;
			me.count = 1;
			while(me.sep_spots[me.threat][me.spot] and me.count < size(me.sep_spots[me.threat])) {

				if (me.dir == 0) me.dir = 1;
				elsif (me.dir > 0) me.dir = -me.dir;
				elsif (me.dir < 0) me.dir = -me.dir+1;

				me.newdev = me.dev + me.plus * me.dir;

				me._assign_ideal_sep_spot();
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

		_assign_ideal_sep_spot: func {
			me.spot = math.round(geo.normdeg(me.newdev)/me.sep_angles[me.threat]);
			if (me.spot >= size(me.sep_spots[me.threat])) {
				me.spot = 0;
			}
		},

		update: func (noti = nil ) {
			me.elapsed = noti.getproper("elapsed_seconds");
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
			# let us see whether we are ready at all first
			if (noti.getproper("wow")) {
				return;
			}

			me._updateCounterMeasures();

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

			me.sep_spots = [[0,0,0,0,0,0,0,0],#45 degs  8
							[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],# 20 degs  18
							[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]];# 15 degs  24
			me.sep_angles = [45,20,15];

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
				me.dev = -me.contact[2]+90;
				if (me.separate == TRUE) {
					if (me.typ == me.AIRCRAFT_UNKNOWN or me.typ == me.AIRCRAFT_SEARCH) {
						me.threat = 2.;
					} else if (me.threat > 0.5) {
						me.threat = 0.;
					} else if (me.threat > 0.25) {
						me.threat = 1.;
					} else {
						me.threat = 2.;
					}
					me._assign_sep_spot();
				} else {
					if (me.typ == me.AIRCRAFT_UNKNOWN or me.typ == me.AIRCRAFT_SEARCH) {
						me.threat = me.unknown_threat_radius;
					} else if (me.threat > 0.5) {
						me.threat = me.high_threat_radius;
					} else {
						me.threat = me.lower_threat_radius;
					}
				}

				me.x = math.cos(me.dev*D2R)*me.threat;
				me.y = -math.sin(me.dev*D2R)*me.threat;
				me.texts[me.i].setTranslation(me.x, me.y);
				me.texts[me.i].updateText(me.typ);
				me.symbol_chevron[me.i].setTranslation(me.x, me.y);
				me.symbol_hat[me.i].setTranslation(me.x, me.y);

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

			# show the active missile (only one can be shown in OPRF)
			if (me.input.maw_active.getValue() and me.alternated == TRUE) { # we show blinking when FALSE to make it more visible
				me.dev = -geo.normdeg180(me.input.maw_bearing.getValue() - me.input.heading_true.getValue()) + 90;
				me.x = math.cos(me.dev*D2R)*me.missile_radius;
				me.y = -math.sin(me.dev*D2R)*me.missile_radius;
				me.texts[me.max_icons].setTranslation(me.x, me.y);
				me.symbol_chevron[me.max_icons].setTranslation(me.x, me.y);
				me.symbol_hat[me.max_icons].setTranslation(me.x, me.y);

				me.texts[me.max_icons].show();
				me.symbol_hat[me.max_icons].show();
				me.symbol_chevron[me.max_icons].show();
			} else {
				me.texts[me.max_icons].hide();
				me.symbol_hat[me.max_icons].hide();
				me.symbol_chevron[me.max_icons].hide();
			}

			# set the sounds
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
				me.ll_box.setColor(COLOR_CYAN);
				me.ll_box.setColorFill(COLOR_BLACK);
				me.ll_text.setColor(COLOR_CYAN);
			} else {
				me.ll_box.setColor(COLOR_BLACK);
				me.ll_box.setColorFill(COLOR_CYAN);
				me.ll_text.setColor(COLOR_BLACK);
			}
			# remaining counter measures
			me.cm_background_line = COLOR_MAGENTA;
			me.cm_background_fill = COLOR_BLACK;
			if (me.input.cm_remaining.getValue() == 0) {
				me.cm_background_line = COLOR_BLACK;
				me.cm_background_fill = COLOR_MAGENTA;
			} else if (me.input.cm_remaining.getValue() <= 20) {
				if (me.alternated == TRUE) {
					me.cm_background_line = COLOR_BLACK;
					me.cm_background_fill = COLOR_MAGENTA;
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

		exit: func {
			# printDebug("Exit ",me.name~" on ",me.device.name);
		},

		links: {
			OSB3: PAGE_MAP,
		},

		layers: [LAYER_SERVICEABLE],
	},


#  ██████   █████   ██████  ███████     ███    ███  █████  ██████
#  ██   ██ ██   ██ ██       ██          ████  ████ ██   ██ ██   ██
#  ██████  ███████ ██   ███ █████       ██ ████ ██ ███████ ██████
#  ██      ██   ██ ██    ██ ██          ██  ██  ██ ██   ██ ██
#  ██      ██   ██  ██████  ███████     ██      ██ ██   ██ ██


	PageMap: {
		name: PAGE_MAP,
		isNew: TRUE,
		needGroup: TRUE,

		new: func {
			me.instance = {parents:[DisplaySystem.PageMap]};
			me.instance.group = nil;
			return me.instance;
		},

		setup: func {
			# printDebug(me.name," on ",me.device.name," is being setup");

			me.map_stuff = me.group.createChild("group").set(Z_INDEX, zIndex.page_map.map);

			me.myHeadingProp = props.globals.getNode("orientation/heading-deg");

			me.group.setCenter(DISPLAY_WIDTH/2,DISPLAY_HEIGHT/2);

			# MAP stuff : Set up of the tiles
			me.tile_size = 256;
			me.num_tiles = [4, 3];

			me.type = "map";
			me.home =  props.globals.getNode("/sim/fg-home");
			me.maps_base = me.home.getValue() ~ '/cache/maps';

			#----------------  Make the url where to take the tiles ------------
			# https://wiki.openstreetmap.org/wiki/Raster_tile_providers

			me.makeUrl  = string.compileTemplate('http://{server}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png');
			me.servers = ["a", "b", "c"];
			me.makePath = string.compileTemplate(me.maps_base ~ '/osm-{type}/{z}/{x}/{y}.png');

			#Setting up red little aircraft
			me.center_tile_offset = [
				(me.num_tiles[0] - 1) / 2,
				(me.num_tiles[1] - 1) / 2
			];
			me.filename = "Aircraft/Mirage-2000/Models/Interior/Instruments/mfd/littleaircraftRed.svg";
			me.svg_symbol = me.group.createChild("group").set(Z_INDEX, zIndex.page_map.svg);
			canvas.parsesvg(me.svg_symbol, me.filename);
			me.svg_symbol.setScale(0.05);
			me.svg_symbol.setTranslation((DISPLAY_WIDTH/2)-20,DISPLAY_HEIGHT/2-45);
			me.myVector = me.svg_symbol.getBoundingBox();
			me.svg_symbol.updateCenter();

			var make_tiles = func (canvas_group) {
				var tiles = setsize([], me.num_tiles[0]);
				for (var x = 0; x < me.num_tiles[0]; x += 1) {
					tiles[x] = setsize([], me.num_tiles[1]);
					for (var y = 0; y < me.num_tiles[1]; y += 1) {
						tiles[x][y] = canvas_group.createChild("image", "map-tile");
					}
				}
				return tiles;
			}

			me.map_tiles = make_tiles(me.map_stuff);

			me.last_tile = nil;
			me.last_type = me.type;

			me.MIN_ZOOM = 5;
			me.MAX_ZOOM = 15;
			me.zoom = 10;
			me.last_zoom = me.zoom;

			me.row_4_right_text = me.group.createChild("text", "row_4_right_text")
				.set(Z_INDEX, zIndex.page_map.row_text)
				.setFontSize(font.device.row_text)
				.setColor(COLOR_GREEN)
				.setColorFill(COLOR_BLACK)
				.setAlignment("right-center")
				.setTranslation(DISPLAY_WIDTH - margin.device.row_text, DISPLAY_ROW_HEIGHT_4)
				.setText("Zoom");

			# text to display when there are problems loading map tiles
			me.load_message_text = "";
			me.load_message = me.group.createChild("text", "load_message")
				.set(Z_INDEX, zIndex.page_map.load_message)
				.setColor(COLOR_MAGENTA)
				.setFont(FONT_MONO_BOLD)
				.setFontSize(font.page_map.load_message)
				.setAlignment("center-center")
				.setTranslation(DISPLAY_WIDTH/2, DISPLAY_HEIGHT - 150);
			me.load_message.enableUpdate();
		},

		_changeZoomMap: func(d) {
			new_zoom = math.max(me.MIN_ZOOM, math.min(me.MAX_ZOOM, me.zoom + d));
			if (new_zoom != me.zoom) {
				me.zoom = new_zoom;
				if (me.zoom == me.MIN_ZOOM) {
					me.device.controls[OSB33].setControlText("");
				} elsif (me.zoom == me.MAX_ZOOM) {
					me.device.controls[OSB32].setControlText("");
				} else {
					me.device.controls[OSB32].setControlText("In");
					me.device.controls[OSB33].setControlText("Out");
				}
			}
		},

		enter: func {
			# printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = FALSE;
			}
			me.device.resetControls();
			me.device.controls[OSB2].setControlText(PAGE_MAP_MENU_ITEM, TRUE, FALSE, TRUE);
			me.device.controls[OSB32].setControlText("In");
			me.device.controls[OSB33].setControlText("Out");
		},

		controlAction: func (controlName) {
			# printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == OSB2) {
				me.device.system.selectPage(PAGE_HUB);
			} elsif (controlName == OSB32) {
				me._changeZoomMap(1);
			} elsif (controlName == OSB33) {
				me._changeZoomMap(-1);
			}
		},

		update: func(noti = nil) {
			if (noti.FrameCount != 3) {
				return;
			}

			me.svg_symbol.setRotation(me.myHeadingProp.getValue()*D2R);
			me.myCoord = geo.aircraft_position();

			me.n = math.pow(2, me.zoom);
			me.offset = [
				me.n * ((me.myCoord.lon() + 180) / 360) - me.center_tile_offset[0],
				(1 - math.ln(math.tan(me.myCoord.lat() * math.pi/180) + 1 / math.cos(me.myCoord.lat() * math.pi/180)) / math.pi) / 2 * me.n - me.center_tile_offset[1]
			];
			me.tile_index = [int(me.offset[0]), int(me.offset[1])];

			me.ox = me.tile_index[0] - me.offset[0];
			me.oy = me.tile_index[1] - me.offset[1];

			for (var x = 0; x < me.num_tiles[0]; x += 1) {
				for (var y = 0; y < me.num_tiles[1]; y += 1) {
					me.map_tiles[x][y].setTranslation(int((me.ox + x) * me.tile_size + 0.5), int((me.oy + y) * me.tile_size + 0.5));
				}
			}
			if (me.last_tile == nil or me.load_message_text != "" or me.tile_index[0] != me.last_tile[0] or me.tile_index[1] != me.last_tile[1] or me.type != me.last_type or me.zoom != me.last_zoom) {
				var map_load_issues = FALSE;
				me.load_message_text = ""; # reset - will only be updated if there is an error
				for (var x = 0; x < me.num_tiles[0]; x += 1) {
					for (var y = 0; y < me.num_tiles[1]; y += 1) {
						me.server_index = math.round(rand() * (size(me.servers) - 1));
						me.server_name = me.servers[me.server_index];
						me.pos = {
							z: me.zoom,
							x: int(me.offset[0] + x),
							y: int(me.offset[1] + y),
							type: me.type,
							server: me.server_name
						};

						(func {
							var img_path = me.makePath(me.pos);
							if (io.stat(img_path) == nil) {
								var img_url = me.makeUrl(me.pos);
								http.save(img_url, img_path)
									.done(func {
										# nothing to do
									})
									.fail(func (r) {
										me.load_message_text = "Map loading ...";
									});
							}
							else {
								me.map_tiles[x][y].setFile(img_path);
							}
						})();
					}
				}
				me.load_message.updateText(me.load_message_text);
				me.last_tile = me.tile_index;
				me.last_type = me.type;
				me.last_zoom = me.zoom;
			}
		},

		exit: func {
			# printDebug("Exit ",me.name~" on ",me.device.name);
		},

		links: {
			OSB3: PAGE_EHSI,
		},

		layers: [LAYER_SERVICEABLE],
	}
};


#   ██████  ██    ██ ███████ ██████   █████  ██      ██          ███████ ███████ ████████ ██    ██ ██████
#  ██    ██ ██    ██ ██      ██   ██ ██   ██ ██      ██          ██      ██         ██    ██    ██ ██   ██
#  ██    ██ ██    ██ █████   ██████  ███████ ██      ██          ███████ █████      ██    ██    ██ ██████
#  ██    ██  ██  ██  ██      ██   ██ ██   ██ ██      ██               ██ ██         ██    ██    ██ ██
#   ██████    ████   ███████ ██   ██ ██   ██ ███████ ███████     ███████ ███████    ██     ██████  ██


var rightMFDDisplayDevice = nil;

var M2000MFDRecipient =
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident~".MFD");

        new_class.Receive = func(notification)
        {
            if (notification == nil)
            {
                print("bad notification nil");
                return emesary.Transmitter.ReceiptStatus_NotProcessed;
            }

            if (notification.NotificationType == "FrameNotification")
            {
                rightMFDDisplayDevice.update(notification);
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        new_class.del = func {
        	emesary.GlobalTransmitter.DeRegister(me);
        };
        return new_class;
    },
};

var m2000_mfd = nil;


var main = func (module) {
	if (module != nil) {
		print("Display-system init as module");
	}

	var variantID = getprop("sim/variant-id");
	if (variantID == constants.VARIANT_D) {
		return; # nothing to do
	}

	rightMFDDisplayDevice = DisplayDevice.new("RightMFDDisplayDevice", [DISPLAY_WIDTH, DISPLAY_HEIGHT], [1, 1], "right_mfd.canvasCadre", "canvasTex.png");
	rightMFDDisplayDevice.setColorBackground(COLOR_BLACK);

	rightMFDDisplayDevice.setControlTextColors(COLOR_WHITE, COLOR_BLACK, COLOR_CYAN);

	var osbPositions = [
		# top row = bt-h1 ... bt-h5 in xml
		[(0.075+0*0.2125)*DISPLAY_WIDTH, margin.device.button_text_top], # OSB1
		[(0.075+1*0.2125)*DISPLAY_WIDTH, margin.device.button_text_top], # OSB2
		[(0.075+2*0.2125)*DISPLAY_WIDTH, margin.device.button_text_top], # OSB3
		[(0.075+3*0.2125)*DISPLAY_WIDTH, margin.device.button_text_top], # OSB4
		[(0.075+4*0.2125)*DISPLAY_WIDTH, margin.device.button_text_top], # OSB5

		# bottom row = bt-b1 ... bt-b4 in xml
		[(0.2375+0*0.175)*DISPLAY_WIDTH, DISPLAY_HEIGHT], # OSB6
		[(0.2375+1*0.175)*DISPLAY_WIDTH, DISPLAY_HEIGHT], # OSB7
		[(0.2375+2*0.175)*DISPLAY_WIDTH, DISPLAY_HEIGHT], # OSB8
		[(0.2375+3*0.175)*DISPLAY_WIDTH, DISPLAY_HEIGHT], # OSB9

		# These are not buttons, but rocker-switches - left row = pot-l1 ... pot-l4
		[0, DISPLAY_ROW_HEIGHT_1 - margin.device.between_menu_item/2], # OSB10
		[0, DISPLAY_ROW_HEIGHT_1 + margin.device.between_menu_item/2],
		[0, DISPLAY_ROW_HEIGHT_1 + margin.device.to_virtual_item],
		[0, DISPLAY_ROW_HEIGHT_2 - margin.device.between_menu_item/2], # OSB13
		[0, DISPLAY_ROW_HEIGHT_2 + margin.device.between_menu_item/2],
		[0, DISPLAY_ROW_HEIGHT_2 + margin.device.to_virtual_item],
		[0, DISPLAY_ROW_HEIGHT_3 - margin.device.between_menu_item/2], # OSB16
		[0, DISPLAY_ROW_HEIGHT_3 + margin.device.between_menu_item/2],
		[0, DISPLAY_ROW_HEIGHT_3 + margin.device.to_virtual_item],
		[0, DISPLAY_ROW_HEIGHT_4 - margin.device.to_virtual_item], # OSB19
		[0, DISPLAY_ROW_HEIGHT_4 - margin.device.between_menu_item/2],
		[0, DISPLAY_ROW_HEIGHT_4 + margin.device.between_menu_item/2],

		# right row = pot-r1 ... pot-r4
		[DISPLAY_WIDTH, DISPLAY_ROW_HEIGHT_1 - margin.device.between_menu_item/2], # OSB22
		[DISPLAY_WIDTH, DISPLAY_ROW_HEIGHT_1 + margin.device.between_menu_item/2],
		[DISPLAY_WIDTH, DISPLAY_ROW_HEIGHT_1 + margin.device.to_virtual_item],
		[DISPLAY_WIDTH, DISPLAY_ROW_HEIGHT_2 - margin.device.between_menu_item/2], # OSB25
		[DISPLAY_WIDTH, DISPLAY_ROW_HEIGHT_2 + margin.device.between_menu_item/2],
		[DISPLAY_WIDTH, DISPLAY_ROW_HEIGHT_2 + margin.device.to_virtual_item],
		[DISPLAY_WIDTH, DISPLAY_ROW_HEIGHT_3 - margin.device.between_menu_item/2], # OSB28
		[DISPLAY_WIDTH, DISPLAY_ROW_HEIGHT_3 + margin.device.between_menu_item/2],
		[DISPLAY_WIDTH, DISPLAY_ROW_HEIGHT_3 + margin.device.to_virtual_item],
		[DISPLAY_WIDTH, DISPLAY_ROW_HEIGHT_4 - margin.device.to_virtual_item],#OSB31
		[DISPLAY_WIDTH, DISPLAY_ROW_HEIGHT_4 - margin.device.between_menu_item/2],
		[DISPLAY_WIDTH, DISPLAY_ROW_HEIGHT_4 + margin.device.between_menu_item/2],
	];

	var rightMFDDisplaySystem = DisplaySystem.new();

	rightMFDDisplayDevice.setDisplaySystem(rightMFDDisplaySystem);

	rightMFDDisplaySystem.initDevice(0, osbPositions, font.device.main);

	rightMFDDisplayDevice.addControlFeedback();

	rightMFDDisplaySystem.initPages();
	rightMFDDisplaySystem.selectPage(PAGE_HUB);

	m2000_mfd = M2000MFDRecipient.new("M2000");
	emesary.GlobalTransmitter.Register(m2000_mfd);

	# to be sure we have consistent rates for cannon fire
	_changeCannonRate(TRUE);
}

var _changeCannonRate = func (air_to_air) { # 1 or 0
	# https://en.wikipedia.org/wiki/Dassault_Mirage_2000 states 1800/min (0.033) or 1200/min (0.05).
	# https://en.wikipedia.org/wiki/DEFA_cannon states:
	#     * DEFA 554 for the single-seat Mirage 2000 and DEFA 553 for 2000D RMV
	#     * DEFA 554 1,100 rpm (low) or 1,800 rpm (high)
	#     * 553: 1,300 rpm
	# => going with DEFA 554 and 0.033 - 0.055 for the -5 and fixed 0.046 for the D (CC442 gun pod)
	var rate = 0.0;
	if (variantID == constants.VARIANT_D) {
		rate = 0.046; # no difference between A/A and A/G
	} else if (air_to_air == TRUE) {
		rate = 0.033;
	} else {
		rate = 0.055;
	}
	setprop("/ai/submodels/submodel/delay", rate);
	setprop("/ai/submodels/submodel[1]/delay", rate);
}

var unload = func {
	if (leftMFD != nil) {
		leftMFD.del();
		leftMFD = nil;
	}
	if (rightMFDDisplayDevice != nil) {
		rightMFDDisplayDevice.del();
		rightMFDDisplayDevice = nil;
	}
	DisplayDevice = nil;
	DisplaySystem = nil;
	m2000_mfd.del();
	radar_system.mapper.removeImage();
	radar_system.FlirSensor.removeImage();
}

var print2 = func {
	# workaround to avoid regression in 2020.3.19: call(print,arg) crashes sim.
	var out = "";
	foreach(ar;arg) {
		out ~= ar;
	}
	print(out);
};
var debugDisplays = TRUE;
var printDebug = func {
	if (debugDisplays) {
		var err = [];
		call(print2,arg,nil,nil,err);
		if(size(err)>0) print (err[0]);
		if(size(err)>1) print (err[1]);
	}
};
var printfDebug = func {if (debugDisplays) {var str = call(sprintf,arg,nil,nil,var err = []);if(size(err))print (err[0]);else print (str);}};
# Note calling printf directly with call() will sometimes crash the sim, so we call sprintf instead.


main(nil); # disable this line if running as module
