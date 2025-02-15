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

var LAYER_SERVICEABLE = "LayerServiceable";

var PAGE_SMS = "PageSMS";
var PAGE_SMS_MENU_ITEM = "SMS";
var PAGE_RWR = "PageRWR";
var PAGE_RWR_MENU_ITEM = "RWR";
var PAGE_MAP = "PageMap";
var PAGE_MAP_MENU_ITEM = "Map";

var Z_INDEX = "z-index";

var margin = {
	device: {
		buttonText: 10,
		fillHeight: 1,
		outline: 1,
	},
};

var lineWidth = {
	device: {
		outline: 2,
	},
	layer_serviceable: {
		lines: 6,
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
		main: 20,
	},
	page_sms: {
		pylons_text: 20,
		cat_text: 24,
	},
	page_rwr: {
		threat_text: 36,
		symbols_dist: 24, # a relative value for the size of symbology around the threat text
		indicators_text: 32,
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
	},
};


# also used in apg-68.nas
var colorDot2 = [1, 1, 1];

var COLOR_WHITE = [1, 1, 1];
var COLOR_YELLOW = [1, 1, 0];
var COLOR_AMBER = [1, 0.6, 0.2];
var COLOR_RED = [1, 0, 0];
var COLOR_GREEN = [0, 1, 0];
var COLOR_LIGHT_BLUE = [0.2, 0.6, 1];
var COLOR_BLACK = [0, 0, 0];

var PUSHBUTTON   = 0;

var variantID = getprop("sim/variant-id"); # -5 = 1; -5B/-5B-backseat = 2; D = 3

# flare/chaff values can change every 0.5 seconds -> cf. weapons.nas
# and sounds etc. for M2000 also have a length of 0.5 or multiples thereof
# => let the updates be done in increments of ca. every 0.5 seconds
var UPDATE_INC = 0.5;



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
								.set("font","LiberationFonts/LiberationMono-Regular.ttf");
		}
		me.controls.master.setControlText = func (text, positive = 1, outline = 0, rear = 0, blink = 0) {
			# rear is adjustment of the fill in x axis

			# store for later SWAP option
			me.contentText = text;
			me.contentPositive = positive;
			me.contentOutline = outline;

			if (text == nil or text == "") {
				me.letters.setVisible(0);
				me.outline.setVisible(0);
				me.fill.setVisible(0);
				#me.fill.setColor((!positive)?me.device.colorFront:me.device.colorBack);
				#me.fill.setColorFill((!positive)?me.device.colorFront:me.device.colorBack);
				return;
			}
			me.letters.setVisible(1);
			me.letters.setText(text);
			me.letters.setColor(positive?me.device.colorFront:me.device.colorBack);
			me.outline.setVisible(positive and outline);
			me.fill.setVisible(1);
			me.fill.setColor((!positive)?me.device.colorFront:me.device.colorBack);
			me.fill.setColorFill((!positive)?me.device.colorFront:me.device.colorBack);
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
				.setStrokeLineJoin("round") # "miter", "round" or "bevel"
				.moveTo(me.tempX-me.letterWidth*2*alignmentH-me.letterWidth*2-me.myCenter[0]-margin.device.outline, me.tempY-me.letterHeight*alignmentV*0.5-me.letterHeight*0.5-margin.device.outline-me.myCenter[1])
				.horiz(me.letterWidth*4+margin.device.outline*2)
				.vert(me.letterHeight*1.0+margin.device.outline*2)
				.horiz(-me.letterWidth*4-margin.device.outline*2)
				.vert(-me.letterHeight*1.0-margin.device.outline*2)
				.close()
				.setColor(me.colorFront)
				.hide()
				.setStrokeLineWidth(lineWidth.device.outline)
				.setTranslation(me.myCenter);
		me.controls[controlName].fill = me.controlGrp.createChild("path")
				.set(Z_INDEX, zIndex.deviceOSB.fill)
				.setStrokeLineJoin("round") # "miter", "round" or "bevel"
				.moveTo(me.tempX-me.letterWidth*2*alignmentH-me.letterWidth*2-me.myCenter[0], me.tempY-me.letterHeight*alignmentV*0.5-me.letterHeight*0.5-margin.device.fillHeight-me.myCenter[1])
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

	setControlTextColors: func (foreground, background) {
		me.colorFront = foreground;
		me.colorBack  = background;
	},

	initPage: func (page) {
		printDebug(me.name," init page ",page.name);
		if (page.needGroup) {
			me.tempGrp = me.canvas.createGroup()
							.set(Z_INDEX, zIndex.device.page)
							.set("font","LiberationFonts/LiberationMono-Regular.ttf")
							.hide();
			page.group = me.tempGrp;
		}
		page.device = me;
	},

	initLayer: func (layer) {
		printDebug(me.name," init layer ",layer.name);
		me.tempGrp = me.canvas.createGroup()
						.set(Z_INDEX, zIndex.device.layer)
						.set("font","LiberationFonts/LiberationMono-Regular.ttf")
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
		me.device.addControls(PUSHBUTTON, "OSB", 1, 25, "controls/MFD["~propertyNum~"]/button-pressed", controlPositions);
		me.device.fontSize = fontSize;

		for (var i = 1; i <= 5; i+= 1) { # top row
			me.device.addControlText("OSB", "OSB"~i, [0, margin.device.buttonText], i-1,0,-1);
		}
		for (var i = 6; i <= 9; i+= 1) { # bottom row
			me.device.addControlText("OSB", "OSB"~i, [0, -margin.device.buttonText], i-1,0,1);
		}
		for (var i = 10; i <= 17; i+= 1) { # left column
			me.device.addControlText("OSB", "OSB"~i, [margin.device.buttonText, 0], i-1,-1);
		}
		for (var i = 18; i <= 25; i+= 1) { # right column
			me.device.addControlText("OSB", "OSB"~i, [-margin.device.buttonText, 0], i-1,1);
		}
	},

	initPage: func (pageName) {
		if (DisplaySystem[pageName] == nil) {print(pageName," does not exist");return;}
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

		me.initPage(PAGE_SMS);
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
		if (me.pages[pageName] == nil) {print(me.device.name," page not found: ",pageName);return;}
		if (me["currPage"] != nil) {
			if (me.pages[pageName] == me.currPage) {
				#print(me.device.name," page wont switch to itself: ",pageName);
				return;
			}
			if(me.currPage.needGroup) me.currPage.group.hide();
			me.currPage.exit();
			foreach(var layer; me.currPage.layers) {
				me.fetchLayer(layer).group.hide();
			}
		}
		me.currPage = me.pages[pageName];
		if(me.currPage.needGroup) me.currPage.group.show();
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
			printDebug(me.name," on ",me.device.name," is being setup");
			me._setup_aircraft_outline();
			me._setup_pylon_boxes_and_text();

			me.cat_text = me.group.createChild("text", "cat_text")
				.setFontSize(font.page_sms.cat_text)
				.setColor(COLOR_GREEN)
				.setAlignment("left-center")
				.setText("CAT")
				.setTranslation(DISPLAY_WIDTH/2 - 250, 250);
			me.cat_text.enableUpdate();
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
				.setText("")
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
				.setText("")
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
				.setText("")
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
				.setText("")
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
				.setText("")
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
				.setText("")
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
				.setText("")
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
				.setText("")
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
				.setText("")
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
				.setText("")
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
				.setText("")
				.setTranslation(DISPLAY_WIDTH/2 + (132+48), 108 + 24/2);
			me.caR_text.enableUpdate();
		},

		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = FALSE;
			}
			me.device.resetControls();
			me.device.controls["OSB3"].setControlText(PAGE_RWR_MENU_ITEM);
		},

		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
		},

		update: func (noti = nil) {
			if (noti.FrameCount != 3) {
				return;
			}

			me.catNumber = pylons.fcs.getCategory();
			me.cat_text.setText(sprintf("CAT %s", me.catNumber==1?"I":(me.catNumber==2?"II":"III")));

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

			if (variantID == 1) {
				me.caL_text.setText(sprintf("%3d", pylons.fcs.getAmmo()/2));
				me.caR_text.setText(sprintf("%3d", pylons.fcs.getAmmo()/2));
			} elsif (variantID == 3) {
				if (pylons.pylon1 != nil and pylons.pylon1.currentSet != nil) {
					if (pylons.pylon1.currentSet.name == "CC422") {
						me.caL_text.setText(sprintf("%3d", pylons.fcs.getAmmo()));
					} else {
						me.caL_text.setText("");
					}
				}
				me.caR_text.setText("");
			} else {
				me.caL_text.setText("");
				me.caR_text.setText("");
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
				text_obj.setText("");
			} else {
				me.size_content = size(pylon.currentSet.content);
				me.sms_helper = pylons.pylonSetsSMSHelper[pylon.currentSet.name];
				if (me.sms_helper[1] == TRUE) {
					text_obj.setText(me.size_content~" "~me.sms_helper[0]);
				} else {
					text_obj.setText(me.sms_helper[0]);
				}
			}
		},

		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},

		links: {
			"OSB3": PAGE_RWR,
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
			me.fadeTime = 7; #seconds

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
				.setColor(COLOR_LIGHT_BLUE);
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
				.setColor(COLOR_LIGHT_BLUE)
				.setColorFill(COLOR_BLACK)
				.rect(0, 0, me.DISPENSER_BOX_WIDTH, me.DISPENSER_BOX_WIDTH)
				.setStrokeLineWidth(lineWidth.page_rwr.lines_indicators);
			me.ll_text = me.dispenser_group.createChild("text", "ll_text")
				.setFontSize(font.page_rwr.indicators_text)
				.setColor(COLOR_LIGHT_BLUE)
				.setAlignment("center-center")
				.setText("LL")
				.setTranslation(me.DISPENSER_BOX_WIDTH/2, me.DISPENSER_BOX_WIDTH/2);

			# Contremesures Électromagnétiques/Chaff
			var add_down = me.DISPENSER_BOX_WIDTH + me.DISPENSER_BOX_SEPARATION;
			me.em_box  = me.dispenser_group.createChild("path", "em_box")
				.setColor(COLOR_AMBER)
				.setColorFill(COLOR_BLACK)
				.rect(0, add_down, me.DISPENSER_BOX_WIDTH, me.DISPENSER_BOX_WIDTH)
				.setStrokeLineWidth(lineWidth.page_rwr.lines_indicators);
			me.em_text = me.dispenser_group.createChild("text", "em_text")
				.setFontSize(font.page_rwr.indicators_text)
				.setColor(COLOR_AMBER)
				.setAlignment("center-center")
				.setText("EM")
				.setTranslation(me.DISPENSER_BOX_WIDTH/2, add_down + me.DISPENSER_BOX_WIDTH/2);
			# IR (Contremesures Infrarouges/Flares)
			var add_down = 2*(me.DISPENSER_BOX_WIDTH + me.DISPENSER_BOX_SEPARATION);
			me.ir_box  = me.dispenser_group.createChild("path", "ir_box")
				.setColor(COLOR_AMBER)
				.setColorFill(COLOR_BLACK)
				.rect(0, add_down, me.DISPENSER_BOX_WIDTH, me.DISPENSER_BOX_WIDTH)
				.setStrokeLineWidth(lineWidth.page_rwr.lines_indicators);
			me.ir_text = me.dispenser_group.createChild("text", "ir_text")
				.setFontSize(font.page_rwr.indicators_text)
				.setColor(COLOR_AMBER)
				.setAlignment("center-center")
				.setText("IR")
				.setTranslation(me.DISPENSER_BOX_WIDTH/2, add_down + me.DISPENSER_BOX_WIDTH/2);
			# EO (Contremesures Électro-optiques/Electro-Optical
			var add_down = 3*(me.DISPENSER_BOX_WIDTH + me.DISPENSER_BOX_SEPARATION);
			me.eo_box  = me.dispenser_group.createChild("path", "eo_box")
				.setColor(COLOR_AMBER)
				.setColorFill(COLOR_BLACK)
				.rect(0, add_down, me.DISPENSER_BOX_WIDTH, me.DISPENSER_BOX_WIDTH)
				.setStrokeLineWidth(lineWidth.page_rwr.lines_indicators);
			me.eo_text = me.dispenser_group.createChild("text", "eo_text")
				.setFontSize(font.page_rwr.indicators_text)
				.setColor(COLOR_AMBER)
				.setAlignment("center-center")
				.setText("EO")
				.setTranslation(me.DISPENSER_BOX_WIDTH/2, add_down + me.DISPENSER_BOX_WIDTH/2);
		},

		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = FALSE;
			}
			me.device.resetControls();
			me.device.controls["OSB3"].setControlText(PAGE_MAP_MENU_ITEM);
		},

		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
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
				if (me.typ == me.AIRCRAFT_UNKNOWN or me.typ == me.AIRCRAFT_SEARCH) {
					me.threat = me.unknown_threat_radius;
				} else if (me.threat > 0.5) {
					me.threat = me.high_threat_radius;
				} else {
					me.threat = me.lower_threat_radius;
				}
				me.dev = -me.contact[2]+90;

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
				me.ll_box.setColor(COLOR_LIGHT_BLUE);
				me.ll_box.setColorFill(COLOR_BLACK);
				me.ll_text.setColor(COLOR_LIGHT_BLUE);
			} else {
				me.ll_box.setColor(COLOR_BLACK);
				me.ll_box.setColorFill(COLOR_LIGHT_BLUE);
				me.ll_text.setColor(COLOR_BLACK);
			}
			# remaining counter measures
			me.cm_background_line = COLOR_AMBER;
			me.cm_background_fill = COLOR_BLACK;
			if (me.input.cm_remaining.getValue() == 0) {
				me.cm_background_line = COLOR_BLACK;
				me.cm_background_fill = COLOR_AMBER;
			} else if (me.input.cm_remaining.getValue() <= 20) {
				if (me.alternated == TRUE) {
					me.cm_background_line = COLOR_BLACK;
					me.cm_background_fill = COLOR_AMBER;
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
			printDebug("Exit ",me.name~" on ",me.device.name);
		},

		links: {
			"OSB3": PAGE_MAP,
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
			printDebug(me.name," on ",me.device.name," is being setup");

			me.mapStuff = me.group.createChild("group").set(Z_INDEX, zIndex.page_map.map);
			me.g_front = me.mapStuff.createChild("group");
			me.g_back = me.mapStuff.createChild("group");

			me.myHeadingProp = props.globals.getNode("orientation/heading-deg");

			me.group.setCenter(DISPLAY_WIDTH/2,DISPLAY_HEIGHT/2);

			##MAP stuff : Set up of the tiles
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
			# simple aircraft icon at current position/center of the map
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

			me.tiles_front = make_tiles(me.g_front);
			me.tiles_back  = make_tiles(me.g_back);

			me.use_front = 1;

			me.last_tile = [-1,-1];
			me.last_type = me.type;

			me.MIN_ZOOM = 5;
			me.MAX_ZOOM = 15;
			me.zoom = 10;
		},

		_changeZoomMap: func(d) {
			new_zoom = math.max(me.MIN_ZOOM, math.min(me.MAX_ZOOM, me.zoom + d));
			if (new_zoom != me.zoom) {
				me.zoom = new_zoom;
				printDebug("zoom: "~me.zoom);
				if (me.zoom == me.MIN_ZOOM) {
					me.device.controls["OSB25"].setControlText("");
				} elsif (me.zoom == me.MAX_ZOOM) {
					me.device.controls["OSB24"].setControlText("");
				} else {
					me.device.controls["OSB24"].setControlText("Zoom In");
					me.device.controls["OSB25"].setControlText("Zoom Out");
				}
			}
		},

		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = FALSE;
			}
			me.device.resetControls();
			me.device.controls["OSB3"].setControlText(PAGE_SMS_MENU_ITEM);
			me.device.controls["OSB24"].setControlText("Zoom In");
			me.device.controls["OSB25"].setControlText("Zoom Out");
		},

		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB24") {
				me._changeZoomMap(1);
			} elsif (controlName == "OSB25") {
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
			me.g_front.setVisible(me.use_front);
			me.g_back.setVisible(!me.use_front);

			me.use_front = math.mod(me.use_front + 1, 2);

			for (var x = 0; x < me.num_tiles[0]; x += 1) {
				for (var y = 0; y < me.num_tiles[1]; y += 1) {
					if (me.use_front) {
						me.tiles_back[x][y].setTranslation(int((me.ox + x) * me.tile_size + 0.5), int((me.oy + y) * me.tile_size + 0.5));
					}
					else {
						me.tiles_front[x][y].setTranslation(int((me.ox + x) * me.tile_size + 0.5), int((me.oy + y) * me.tile_size + 0.5));
					}
				}
			}

			if (me.tile_index[0] != me.last_tile[0] or me.tile_index[1] != me.last_tile[1] or me.type != me.last_type) {
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
								# var message = "Requesting %s...";
								http.save(img_url, img_path)
									.done(func {
										# var message = "Received image %s";
									})
									.fail(func (r) {
										# var message = "Failed to get image %s %s: %s";
										me.tiles_back[x-1][y-1].setFile("");
										me.tiles_front[x-1][y-1].setFile("");
									});
							}
							else {
								if (me.pos.z == me.zoom) {
									me.tiles_back[x][y].setFile(img_path);
									me.tiles_front[x][y].setFile(img_path);
								}
							}
						})();
					}
				}

				me.last_tile = me.tile_index;
				me.last_type = me.type;
			}
		},

		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},

		links: {
			"OSB3": PAGE_SMS,
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
	if (module != nil) print("Display-system init as module");

	rightMFDDisplayDevice = DisplayDevice.new("RightMFDDisplayDevice", [DISPLAY_WIDTH, DISPLAY_HEIGHT], [1, 1], "right_mfd.canvasCadre", "canvasTex.png");
	rightMFDDisplayDevice.setColorBackground(COLOR_BLACK);

	rightMFDDisplayDevice.setControlTextColors(COLOR_WHITE, COLOR_BLACK);

	var osbPositions = [
		# top row = bt-h1 ... bt-h5 in xml
		[(0.075+0*0.2125)*DISPLAY_WIDTH, 0], # OSB1
		[(0.075+1*0.2125)*DISPLAY_WIDTH, 0], # OSB2
		[(0.075+2*0.2125)*DISPLAY_WIDTH, 0], # OSB3
		[(0.075+3*0.2125)*DISPLAY_WIDTH, 0], # OSB4
		[(0.075+4*0.2125)*DISPLAY_WIDTH, 0], # OSB5

		# bottom row = bt-b1 ... bt-b4 in xml
		[(0.2375+0*0.175)*DISPLAY_WIDTH, DISPLAY_HEIGHT], # OSB6
		[(0.2375+1*0.175)*DISPLAY_WIDTH, DISPLAY_HEIGHT], # OSB7
		[(0.2375+2*0.175)*DISPLAY_WIDTH, DISPLAY_HEIGHT], # OSB8
		[(0.2375+3*0.175)*DISPLAY_WIDTH, DISPLAY_HEIGHT], # OSB9

		# These are not buttons, but rocker-switches - left row = pot-l1 ... pot-l4
		[0, 1.5/6.4*DISPLAY_HEIGHT], # OSB10
		[0, 1.5/6.4*DISPLAY_HEIGHT +24],
		[0, 3.0/6.4*DISPLAY_HEIGHT], # OSB12
		[0, 3.0/6.4*DISPLAY_HEIGHT +24],
		[0, 4.5/6.4*DISPLAY_HEIGHT], # OSB14
		[0, 4.5/6.4*DISPLAY_HEIGHT +24],
		[0, 6.0/6.4*DISPLAY_HEIGHT], # OSB16
		[0, 6.0/6.4*DISPLAY_HEIGHT +24],

		# right row = pot-r1 ... pot-r4
		[DISPLAY_WIDTH, 1.5/6.4*DISPLAY_HEIGHT], # OSB18
		[DISPLAY_WIDTH, 1.5/6.4*DISPLAY_HEIGHT +24],
		[DISPLAY_WIDTH, 3.0/6.4*DISPLAY_HEIGHT], # OSB20
		[DISPLAY_WIDTH, 3.0/6.4*DISPLAY_HEIGHT +24],
		[DISPLAY_WIDTH, 4.5/6.4*DISPLAY_HEIGHT], # OSB22
		[DISPLAY_WIDTH, 4.5/6.4*DISPLAY_HEIGHT +24],
		[DISPLAY_WIDTH, 6.0/6.4*DISPLAY_HEIGHT], # OSB24
		[DISPLAY_WIDTH, 6.0/6.4*DISPLAY_HEIGHT +24],
	];

	var rightMFDDisplaySystem = DisplaySystem.new();

	rightMFDDisplayDevice.setDisplaySystem(rightMFDDisplaySystem);

	rightMFDDisplaySystem.initDevice(0, osbPositions, font.device.main);

	rightMFDDisplayDevice.addControlFeedback();

	rightMFDDisplaySystem.initPages();
	rightMFDDisplaySystem.selectPage(PAGE_SMS);

	m2000_mfd = M2000MFDRecipient.new("M2000");
	emesary.GlobalTransmitter.Register(m2000_mfd);
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


main(nil);# disable this line if running as module
