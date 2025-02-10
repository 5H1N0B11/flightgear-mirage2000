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

var PAGE_TEST = "PageTest";
var PAGE_SMS = "PageSMS";

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
	},
};

var font = {
	device: {
		main: 20,
	},
};

var zIndex = {
	device: {
		osb: 100,
		page: 5,
		layer: 200,
	},
	deviceObs: {
		text: 10,
		outline: 11,
		fill: 9,
		feedback: 7,
	},
	test: {
		foreground: 10,
		background: 5,
	},
	page_sms: {
		aircraft_outline: 15,
		menu_foreground: 10,
		menu_background: 5,
	}
};

# OSB text
var colorText1 = [1, 1, 1];

# also used in apg-68.nas
var colorDot2 = [1, 1, 1];

var colorBackground = [0,0,0];

var COLOR_WHITE = [1, 1, 1];

var COLOR_RED = [1, 0, 0]; # red


var PUSHBUTTON   = 0;


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
				#printDebug(me.name,": ",prefix, " action :", me.tempActionValue);
				me.cntlFeedback.setTranslation(me.controlPositions[prefix][me.tempActionValue-1]);
				me.cntlFeedback.setVisible(1 == 1);
				me.cntlFeedback.update();
				#print("fb ON  ",me.controlPositions[prefix][me.tempActionValue-1][0],",",me.controlPositions[prefix][me.tempActionValue-1][1]);
				me.controlAction(type, prefix~(me.tempActionValue), me.tempActionValue);
			} else {
				me.cntlFeedback.hide();
				me.cntlFeedback.update();
				#print("fb OFF  ");
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
								.set("z-index", zIndex.device.osb)
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
				.set("z-index", zIndex.deviceObs.text)
				.setAlignment(me.alignment)
				.setTranslation(me.tempX, me.tempY)
				.setFontSize(me.fontSize, 1)
				.setText("right(controlName,4)")
				.setColor(me.colorFront);
		me.controls[controlName].outline = me.controlGrp.createChild("path")
				.set("z-index", zIndex.deviceObs.outline)
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
				.set("z-index", zIndex.deviceObs.fill)
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
	            .set("z-index",zIndex.deviceObs.feedback)
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
							.set("z-index", zIndex.device.page)
							.set("font","LiberationFonts/LiberationMono-Regular.ttf")
							.hide();
			page.group = me.tempGrp;
		}
		page.device = me;
	},

	initLayer: func (layer) {
		printDebug(me.name," init layer ",layer.name);
		me.tempGrp = me.canvas.createGroup()
						.set("z-index", zIndex.device.layer)
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
		me.device.addControls(PUSHBUTTON, "OSB", 1, 9, "controls/MFD["~propertyNum~"]/button-pressed", controlPositions);
		me.device.fontSize = fontSize;

		for (var i = 1; i <= 5; i+= 1) { # top row
			me.device.addControlText("OSB", "OSB"~i, [0, margin.device.buttonText], i-1,0,-1);
		}
		for (var i = 6; i <= 9; i+= 1) { # bottom row
			me.device.addControlText("OSB", "OSB"~i, [0, -margin.device.buttonText], i-1,0,1);
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

		me.initPage(PAGE_TEST);
		me.initPage(PAGE_SMS);

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
		},

		update: func (noti = nil) {
		},
	},


#  ██████   █████   ██████  ███████     ████████ ███████ ███████ ████████
#  ██   ██ ██   ██ ██       ██             ██    ██      ██         ██
#  ██████  ███████ ██   ███ █████          ██    █████   ███████    ██
#  ██      ██   ██ ██    ██ ██             ██    ██           ██    ██
#  ██      ██   ██  ██████  ███████        ██    ███████ ███████    ██


	PageTest: {
		name: PAGE_TEST,
		isNew: TRUE,
		needGroup: TRUE,
		new: func {
			me.instance = {parents:[DisplaySystem.PageTest]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			me.pageText = me.group.createChild("text")
				.set("z-index", zIndex.test.foreground)
				.setColor(colorText1)
				.setAlignment("left-center")
				.setTranslation(DISPLAY_WIDTH*0.6, DISPLAY_HEIGHT*0.8)
				.setFontSize(me.device.fontSize)
				.setText("BBRAM OFPID\nSUROM OFPID");
			me.mfdsGreyTest = me.group.createChild("path")
				.set("z-index", zIndex.test.background)
				.setColor(colorDot2[0]*0.5,colorDot2[1]*0.5,colorDot2[2]*0.5)
				.moveTo(- DISPLAY_WIDTH, - DISPLAY_HEIGHT)
				.lineTo(DISPLAY_WIDTH*2, DISPLAY_HEIGHT*2)
				.setStrokeLineWidth(DISPLAY_HEIGHT*2)
				.hide();
			me.testMFDS = TRUE;
		},
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB7"].setControlText("SMS");
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			#if (controlName == "OSB7") {
			#	me.device.system.selectPage(PAGE_SMS);
			#}
		},
		update: func (noti = nil) {
			#me.device.controls["OSB6"].setControlText("MFDS",1,me.testMFDS);
			me.mfdsGreyTest.setVisible(me.testMFDS);
			me.pageText.setVisible(me.testMFDS);
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB7": PAGE_SMS,
		},
		layers: [],
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
		},

		_setup_aircraft_outline: func {
			me.aircraft_outline_left = me.group.createChild("path")
				.set(Z_INDEX, zIndex.page_sms.aircraft_outline)
				.setColor(COLOR_WHITE)
				.setStrokeLineWidth(lineWidth.page_sms.aircraft_outline)
				.moveTo(DISPLAY_WIDTH/2 - 60, 96)
				.lineTo(DISPLAY_WIDTH/2 - 51.6, 192)
				.moveTo(DISPLAY_WIDTH/2 - 48, 228)
				.lineTo(DISPLAY_WIDTH/2 - 31.2, 396)
				.moveTo(DISPLAY_WIDTH/2 - 28.8, 432)
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
				.lineTo(DISPLAY_WIDTH/2 + 31.2, 396)
				.moveTo(DISPLAY_WIDTH/2 + 28.8, 432)
				.lineTo(DISPLAY_WIDTH/2 + 24, 480)
				.moveTo(DISPLAY_WIDTH/2 + 55, 144)
				.lineTo(DISPLAY_WIDTH/2 + 192, 396)
				.lineTo(DISPLAY_WIDTH/2 + 192, 432)
				.lineTo(DISPLAY_WIDTH/2 + 26.4, 444);
		},

		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = FALSE;
			}
			me.device.resetControls();
			me.device.controls["OSB3"].setControlText("TEST");
		},

		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
		},

		update: func (noti = nil) {
		},

		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},

		links: {
			"OSB3": PAGE_TEST,
		},

		layers: [LAYER_SERVICEABLE],
	},
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
	rightMFDDisplayDevice.setColorBackground(colorBackground);

	rightMFDDisplayDevice.setControlTextColors(colorText1, colorBackground);

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
		# [0, 1.5/6.4*DISPLAY_HEIGHT],
		# [0, 3.0/6.4*DISPLAY_HEIGHT],
		# [0, 4.5/6.4*DISPLAY_HEIGHT],
		# [0, 6.0/6.4*DISPLAY_HEIGHT],

		# right row = pot-r1 ... pot-r4
		# [DISPLAY_WIDTH, 1.5/6.4*DISPLAY_HEIGHT],
		# [DISPLAY_WIDTH, 3.0/6.4*DISPLAY_HEIGHT],
		# [DISPLAY_WIDTH, 4.5/6.4*DISPLAY_HEIGHT],
		# [DISPLAY_WIDTH, 6.0/6.4*DISPLAY_HEIGHT],
	];

	var rightMFDDisplaySystem = DisplaySystem.new();

	rightMFDDisplayDevice.setDisplaySystem(rightMFDDisplaySystem);

	rightMFDDisplaySystem.initDevice(0, osbPositions, font.device.main);

	rightMFDDisplayDevice.addControlFeedback();

	rightMFDDisplaySystem.initPages();
	rightMFDDisplaySystem.selectPage(PAGE_TEST);

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


#main(nil);# disable this line if running as module
