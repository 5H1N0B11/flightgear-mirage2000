# This module makes it possible to coordinate more than one screen, which again has one or several independent pages.
# The origin of this file is from a file called the same in https://github.com/NikolaiVChr/f16:
#    https://github.com/NikolaiVChr/f16/blob/master/Nasal/MFD/display-system.nas as per 0d480e0
#
# As of Feb 2025 the display system is only used for the right MFD and therefore functionality has been cut down.

var TRUE = 1;
var FALSE = 0;

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
	}
};

# OSB text
var colorText1 = [1, 1, 1];

# also used in apg-68.nas
var colorDot2 = [1, 1, 1];

var colorBackground = [0,0,0];


var PUSHBUTTON   = 0;

#  ██████  ███████ ██    ██ ██  ██████ ███████
#  ██   ██ ██      ██    ██ ██ ██      ██
#  ██   ██ █████   ██    ██ ██ ██      █████
#  ██   ██ ██       ██  ██  ██ ██      ██
#  ██████  ███████   ████   ██  ██████ ███████
#
#

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
		device.displaySystem = nil;
		device.new = func {return nil;};
		#device.timer = maketimer(0.25, device, device.loop);
		return device;
	},

	del: func {
		me.canvas.del();
		foreach(l ; me.listeners) {
			call(func removelistener(l),[],nil,nil,var err = []);
		}
		me.listeners = [];
		#call(func me.timer.stop(),[],nil,nil,err = []);
		#me.timer = nil;
		me.del = func {};
	},

	start: func {
		#me.timer.start();#timers dont really work in modules
		#me.start=func{};
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
		me.displaySystem.update(noti);
	},

	controlAction: func {},

	setDisplaySystem: func (displaySystem) {
		me.displaySystem = displaySystem;
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


#  ███████ ██    ██ ███████ ████████ ███████ ███    ███
#  ██       ██  ██  ██         ██    ██      ████  ████
#  ███████   ████   ███████    ██    █████   ██ ████ ██
#       ██    ██         ██    ██    ██      ██  ██  ██
#  ███████    ██    ███████    ██    ███████ ██      ██
#
#

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
		me.device.addControls(PUSHBUTTON,  "OSB", 1, 20, "controls/MFD["~propertyNum~"]/button-pressed", controlPositions);
		me.device.fontSize = fontSize;

		for (var i = 1; i <= 5; i+= 1) {
			me.device.addControlText("OSB", "OSB"~i, [margin.device.buttonText, 0], i-1,-1);
		}
		for (var i = 6; i <= 10; i+= 1) {
			me.device.addControlText("OSB", "OSB"~i, [-margin.device.buttonText, 0], i-1,1);
		}
		for (var i = 11; i <= 15; i+= 1) {
			me.device.addControlText("OSB", "OSB"~i, [0, margin.device.buttonText], i-1,0,-1);
		}
		for (var i = 16; i <= 20; i+= 1) {
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

		me.initPage("PageTest");

#		me.device.doubleTimerRunning = nil;
		me.device.controlAction = func (type, controlName, propvalue) {
			me.tempLink = me.displaySystem.currPage.links[controlName];
			me.displaySystem.currPage.controlAction(controlName);
			if (me.tempLink != nil) {
#				if (me.doubleTimerRunning == nil) {
#					settimer(func me.controlActionDouble(), 0.25);
#					me.doubleTimerRunning = me.tempLink;
#					printDebug("Timer starting: ",me.doubleTimerRunning);
#				} elsif (me.doubleTimerRunning == me.tempLink) {
#					me.doubleTimerRunning = nil;
#					me.displaySystem.osbSelect = [me.tempLink, me.displaySystem.currPage];
#					me.displaySystem.selectPage("PageOSB");
#					printDebug("Doubleclick special");
#				} else {
#					me.doubleTimerRunning = nil;
					me.displaySystem.selectPage(me.tempLink);
#					printDebug("Timer interupted. Going to ",me.tempLink);
#				}
			}
		};

#		me.device.controlActionDouble = func {
#			printDebug("Timer ran: ",me.doubleTimerRunning);
#			if (me.doubleTimerRunning != nil) {
#				me.displaySystem.selectPage(me.doubleTimerRunning);
#				me.doubleTimerRunning = nil;
#			}
#		};

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

#  ████████ ███████ ███████ ████████
#     ██    ██      ██         ██
#     ██    █████   ███████    ██
#     ██    ██           ██    ██
#     ██    ███████ ███████    ██
#
#

	PageTest: {
		name: "PageTest",
		isNew: 1,
		needGroup: 1,
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
				.setTranslation(displayWidth*0.6, displayHeight*0.8)
				.setFontSize(me.device.fontSize)
				.setText("BBRAM OFPID\nSUROM OFPID");
			me.mfdsGreyTest = me.group.createChild("path")
				.set("z-index", zIndex.test.background)
				.setColor(colorDot2[0]*0.5,colorDot2[1]*0.5,colorDot2[2]*0.5)
				.moveTo(- displayWidth, - displayHeight)
				.lineTo(displayWidth*2, displayHeight*2)
				.setStrokeLineWidth(displayHeight*2)
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
			#me.device.controls["OSB16"].setControlText("SWAP");
			#me.device.controls["OSB9"].setControlText("TEST",0);
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB6") {
				me.testMFDS = !me.testMFDS;
            }
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
			"OSB9": "PageMenu",
		},
		layers: [],
	},

#  ███████ ███    ██ ██████       ██████  ███████     ██████   █████   ██████  ███████ ███████
#  ██      ████   ██ ██   ██     ██    ██ ██          ██   ██ ██   ██ ██       ██      ██
#  █████   ██ ██  ██ ██   ██     ██    ██ █████       ██████  ███████ ██   ███ █████   ███████
#  ██      ██  ██ ██ ██   ██     ██    ██ ██          ██      ██   ██ ██    ██ ██           ██
#  ███████ ██   ████ ██████       ██████  ██          ██      ██   ██  ██████  ███████ ███████
#
#

};

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


var displayWidth     = 512;#552 * 0.795;
var displayHeight    = 512;#482 * 1;
var displayWidthHalf = displayWidth  *  0.5;
var displayHeightHalf= displayHeight  *  0.5;


var main = func (module) {
	if (module != nil) print("Display-system init as module");
	# TEST CODE:
	var height = 576;#482;
	var width  = 768;#552;

	rightMFDDisplayDevice = DisplayDevice.new("RightMFDDisplayDevice", [width,height], [1, 1], "right_mfd.canvasCadre", "canvasTex.png");
	rightMFDDisplayDevice.setColorBackground(colorBackground);

	rightMFDDisplayDevice.setControlTextColors(colorText1, colorBackground);

	width *= 1;#0.795;

	var osbPositions = [
		[0, 1.5*height/7],
		[0, 2.5*height/7],
		[0, 3.5*height/7],
		[0, 4.5*height/7],
		[0, 5.5*height/7],

		[width, 1.5*height/7],
		[width, 2.5*height/7],
		[width, 3.5*height/7],
		[width, 4.5*height/7],
		[width, 5.5*height/7],

		[1.35*width/7, 0],
		[2.4*width/7, 0],
		[3.5*width/7, 0],
		[4.6*width/7, 0],
		[5.65*width/7, 0],

		[1.35*width/7, height],
		[2.4*width/7, height],
		[3.5*width/7, height],
		[4.6*width/7, height],
		[5.65*width/7, height],
	];

	var rightMFDDisplaySystem = DisplaySystem.new();

	rightMFDDisplayDevice.setDisplaySystem(rightMFDDisplaySystem);

	rightMFDDisplaySystem.initDevice(0, osbPositions, font.device.main); # if we get more devices, then we might change 0 to something else

	rightMFDDisplayDevice.addControlFeedback();

	rightMFDDisplaySystem.initPages();
	rightMFDDisplaySystem.selectPage("PageTest");

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
var debugDisplays = 0;
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
