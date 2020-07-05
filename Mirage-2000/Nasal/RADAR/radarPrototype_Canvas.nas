


#############################
# test code below this line #
#############################





var enable = 1;
var enableRWR = 1;
var enableRWRs = 1;




var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }









RadarViewPPI = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		var window = canvas.Window.new([256, 256],"dialog")
				.set('x', 256)
				.set('y', 350)
                .set('title', "Radar PPI");
		var root = window.getCanvas(1).createGroup();
		window.getCanvas(1).setColorBackground(0,0,0);
		me.rootCenter = root.createChild("group")
				.setTranslation(128,256);
		me.rootCenterBleps = root.createChild("group")
				.setTranslation(128,256);
		me.sweepDistance = 128/math.cos(30*D2R);
		me.sweep = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-me.sweepDistance)
				.setStrokeLineWidth(2.5)
				.setColor(1,1,1);
		me.sweepA = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-me.sweepDistance)
				.setStrokeLineWidth(1)
				.setColor(0.5,0.5,1);
		me.sweepB = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-me.sweepDistance)
				.setStrokeLineWidth(1)
				.setColor(0.5,0.5,1);
		me.text = root.createChild("text")
	      .setAlignment("left-top")
      	  .setFontSize(12, 1.0)
	      .setColor(1, 1, 1);
	    me.text2 = root.createChild("text")
	      .setAlignment("left-top")
      	  .setFontSize(12, 1.0)
      	  .setTranslation(0,15)
	      .setColor(1, 1, 1);
	    me.text3 = root.createChild("text")
	      .setAlignment("left-top")
      	  .setFontSize(12, 1.0)
      	  .setTranslation(0,30)
	      .setColor(1, 1, 1);
		me.loop();
	},

	loop: func {
		if (!enable) {settimer(func me.loop(), 0.3); return;}
		me.sweep.setRotation(exampleRadar.posH*D2R);
		if (exampleRadar.lock!=HARD) {
			me.sweepA.show();
			me.sweepB.show();
			me.sweepA.setRotation(exampleRadar.pattern_move[0]*D2R);
			me.sweepB.setRotation(exampleRadar.pattern_move[1]*D2R);
		} else {
			me.sweepA.hide();
			me.sweepB.hide();
		}
		me.elapsed = getprop("sim/time/elapsed-sec");
		me.rootCenterBleps.removeAllChildren();
		foreach(contact; exampleRadar.vector_aicontacts_bleps) {
			if (me.elapsed - contact.blepTime < 5) {
				me.distPixels = contact.getRangeFrozen()*(me.sweepDistance/exampleRadar.forDist_m);

				me.rootCenterBleps.createChild("path")
					.moveTo(0,0)
					.vert(2)
					.setStrokeLineWidth(2)
					.setColor(1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps,1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps,1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps)
					.setTranslation(-me.distPixels*math.cos(contact.getDeviationHeadingFrozen()*D2R+math.pi/2),-me.distPixels*math.sin(contact.getDeviationHeadingFrozen()*D2R+math.pi/2))
					.update();

				if (exampleRadar.containsVector(exampleRadar.locks, contact)) {
					me.rot = contact.getHeadingFrozen();
					if (me.rot == nil) {
						#can happen in transition between TWS to RWS
					} else {
						me.rot = me.rot-getprop("orientation/heading-deg");
						me.rootCenterBleps.createChild("path")
							.moveTo(-5,-5)
							.vert(10)
							.horiz(10)
							.vert(-10)
							.horiz(-10)
							.moveTo(0,-5)
							.vert(-5)
							.setStrokeLineWidth(1)
							.setColor(exampleRadar.lock == HARD?[1,0,0]:[1,1,0])
							.setTranslation(-me.distPixels*math.cos(contact.getDeviationHeadingFrozen()*D2R+math.pi/2),-me.distPixels*math.sin(contact.getDeviationHeadingFrozen()*D2R+math.pi/2))
							.setRotation(me.rot*D2R)
							.update();
					}
				}
				if (exampleRadar.containsVector(exampleRadar.follow, contact)) {
					me.rootCenterBleps.createChild("path")
						.moveTo(-7,-7)
						.vert(14)
						.horiz(14)
						.vert(-14)
						.horiz(-14)
						.setStrokeLineWidth(1)
						.setColor([0.5,0,1])
						.setTranslation(-me.distPixels*math.cos(contact.getDeviationHeadingFrozen()*D2R+math.pi/2),-me.distPixels*math.sin(contact.getDeviationHeadingFrozen()*D2R+math.pi/2))
						.update();
				}
			}
		}
		if (exampleRadar.patternBar<size(exampleRadar.pattern[2])) {
			# the if is due to just after changing bars and before radar loop has run, patternBar can be out of bounds of pattern.
			me.text.setText(sprintf("Bar %+d    Range %d NM", exampleRadar.pattern[2][exampleRadar.patternBar]<4?exampleRadar.pattern[2][exampleRadar.patternBar]-4:exampleRadar.pattern[2][exampleRadar.patternBar]-3,exampleRadar.forDist_m*M2NM));
		}
		me.md = exampleRadar.scanMode==TRACK_WHILE_SCAN?"TWS":"RWS";
		if (size(exampleRadar.follow) > 0 and exampleRadar.lock != HARD) {
			me.md = me.md~"-SAM";
		}
		me.text2.setText(sprintf("Lock=%d (%s)  %s", size(exampleRadar.locks), exampleRadar.lock==NONE?"NONE":exampleRadar.lock==SOFT?"SOFT":"HARD",me.md));
		me.text3.setText(sprintf("Select: %s", size(exampleRadar.follow)>0?exampleRadar.follow[0].callsign:""));
		settimer(func me.loop(), exampleRadar.loopSpeed);
	},
};

RadarViewBScope = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		var window = canvas.Window.new([256, 256],"dialog")
				.set('x', 550)
                .set('title', "Radar B-Scope");
		var root = window.getCanvas(1).createGroup();
		window.getCanvas(1).setColorBackground(0,0,0);
		me.rootCenter = root.createChild("group")
				.setTranslation(128,256);
		me.rootCenterBleps = root.createChild("group")
				.setTranslation(128,256);
		me.sweep = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-256)
				.setStrokeLineWidth(2.5)
				.setColor(1,1,1);
		me.sweepA = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-256)
				.setStrokeLineWidth(1)
				.setColor(0.5,0.5,1);
		me.sweepB = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-256)
				.setStrokeLineWidth(1)
				.setColor(0.5,0.5,1);
		
	    me.b = root.createChild("text")
	      .setAlignment("left-center")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(0,100)
	      .setColor(1, 1, 1);
	    me.a = root.createChild("text")
	      .setAlignment("left-center")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(0,150)
	      .setColor(1, 1, 1);
		me.loop();
	},

	loop: func {
		if (!enable) {settimer(func me.loop(), 0.3); return;}
		me.sweep.setTranslation(128*exampleRadar.posH/60,0);
		if (exampleRadar.lock!=HARD) {
			me.sweepA.show();
			me.sweepB.show();
			me.sweepA.setTranslation(128*exampleRadar.pattern_move[0]/60,0);
			me.sweepB.setTranslation(128*exampleRadar.pattern_move[1]/60,0);
		} else {
			me.sweepA.hide();
			me.sweepB.hide();
		}
		me.elapsed = getprop("sim/time/elapsed-sec");
		me.rootCenterBleps.removeAllChildren();
		foreach(contact; exampleRadar.vector_aicontacts_bleps) {
			if (me.elapsed - contact.blepTime < 5) {
				me.distPixels = contact.getRangeFrozen()*(256/exampleRadar.forDist_m);

				me.rootCenterBleps.createChild("path")
					.moveTo(0,0)
					.vert(2)
					.setStrokeLineWidth(2)
					.setColor(1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps,1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps,1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps)
					.setTranslation(128*contact.getDeviationHeadingFrozen()/60,-me.distPixels)
					.update();
				if (exampleRadar.containsVector(exampleRadar.locks, contact)) {
					me.rot = contact.getHeadingFrozen();
					if (me.rot == nil) {
						#can happen in transition between TWS to RWS
					} else {
						me.rot = me.rot-getprop("orientation/heading-deg")-contact.getDeviationHeadingFrozen();
						me.rootCenterBleps.createChild("path")
							.moveTo(-5,-5)
							.vert(10)
							.horiz(10)
							.vert(-10)
							.horiz(-10)
							.moveTo(0,-5)
							.vert(-5)
							.setStrokeLineWidth(1)
							.setColor(exampleRadar.lock == HARD?[1,0,0]:[1,1,0])
							.setTranslation(128*contact.getDeviationHeadingFrozen()/60,-me.distPixels)
							.setRotation(me.rot*D2R)
							.update();
					}
				}
				if (exampleRadar.containsVector(exampleRadar.follow, contact)) {
					me.rootCenterBleps.createChild("path")
						.moveTo(-7,-7)
						.vert(14)
						.horiz(14)
						.vert(-14)
						.horiz(-14)
						.setStrokeLineWidth(1)
						.setColor([0.5,0,1])
						.setTranslation(128*contact.getDeviationHeadingFrozen()/60,-me.distPixels)
						.update();
				}
			}
		}
		
		var a = 0;
		if (exampleRadar.pattern[1] < 8) {
			a = 1;
		} elsif (exampleRadar.pattern[1] < 20) {
			a = 2;
		} elsif (exampleRadar.pattern[1] < 35) {
			a = 3;
		} elsif (exampleRadar.pattern[1] < 70) {
			a = 4;
		}
		var b = size(exampleRadar.pattern[2]);
		me.b.setText("B"~b);
		me.a.setText("A"~a);
		settimer(func me.loop(), exampleRadar.loopSpeed);
	},
};

RadarViewCScope = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		var window = canvas.Window.new([256, 256],"dialog")
				.set('x', 825)
                .set('title', "Radar C-Scope");
		var root = window.getCanvas(1).createGroup();
		window.getCanvas(1).setColorBackground(0,0,0);
		me.rootCenter = root.createChild("group")
				.setTranslation(128,256);
		me.rootCenter2 = root.createChild("group")
				.setTranslation(0,128);
		me.rootCenterBleps = root.createChild("group")
				.setTranslation(128,128);
		me.sweep = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-20)
				.setStrokeLineWidth(2.5)
				.setColor(1,1,1);
		me.sweep2 = me.rootCenter2.createChild("path")
				.moveTo(0,0)
				.horiz(20)
				.setStrokeLineWidth(2.5)
				.setColor(1,1,1);
		
	    root.createChild("path")
	       .moveTo(0, 128)
           .arcSmallCW(128, 128, 0, 256, 0)
           .arcSmallCW(128, 128, 0, -256, 0)
           .setStrokeLineWidth(1)
           .setColor(1, 1, 1);
		me.loop();
	},

	loop: func {
		if (!enable) {settimer(func me.loop(), 0.3); return;}
		me.sweep.setTranslation(128*exampleRadar.posH/60,0);
		me.sweep2.setTranslation(0, -128*exampleRadar.posE/60);
		me.elapsed = getprop("sim/time/elapsed-sec");
		me.rootCenterBleps.removeAllChildren();
		#me.rootCenterBleps.createChild("path")# thsi will show where the disc is pointed for debug purposes.
		#			.moveTo(0,0)
		#			.vert(2)
		#			.setStrokeLineWidth(2)
		#			.setColor(0.5,0.5,0.5)
		#			.setTranslation(128*exampleRadar.posH/60,-128*exampleRadar.posE/60)
		#			.update();
		foreach(contact; exampleRadar.vector_aicontacts_bleps) {
			if (me.elapsed - contact.blepTime < 5) {
				me.rootCenterBleps.createChild("path")
					.moveTo(0,0)
					.vert(2)
					.setStrokeLineWidth(2)
					.setColor(1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps,1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps,1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps)
					.setTranslation(128*contact.getDeviationHeadingFrozen()/60,-128*contact.getDeviationPitchFrozen()/60)
					.update();
				if (exampleRadar.containsVector(exampleRadar.locks, contact)) {
					me.rootCenterBleps.createChild("path")
						.moveTo(-5,-5)
						.vert(10)
						.horiz(10)
						.vert(-10)
						.horiz(-10)
						.setStrokeLineWidth(1)
						.setColor(exampleRadar.lock == HARD?[1,0,0]:[1,1,0])
						.setTranslation(128*contact.getDeviationHeadingFrozen()/60,-128*contact.getDeviationPitchFrozen()/60)
						.update();
				}
				if (exampleRadar.containsVector(exampleRadar.follow, contact)) {
					me.rootCenterBleps.createChild("path")
						.moveTo(-7,-7)
						.vert(14)
						.horiz(14)
						.vert(-14)
						.horiz(-14)
						.setStrokeLineWidth(1)
						.setColor([0.5,0,1])
						.setTranslation(128*contact.getDeviationHeadingFrozen()/60,-128*contact.getDeviationPitchFrozen()/60)
						.update();
				}
			}
		}
		

		settimer(func me.loop(), exampleRadar.loopSpeed);
	},
};


RadarViewAScope = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		
		var window = canvas.Window.new([256, 256],"dialog")
				.set('x', 825)
				.set('y', 350)
                .set('title', "Radar A-Scope");
		var root = window.getCanvas(1).createGroup();
		window.getCanvas(1).setColorBackground(0,0,0);
		me.rootCenter = root.createChild("group")
				.setTranslation(0,250);
		me.line = [];
		for (var i = 0;i<256;i+=1) {
			append(me.line, me.rootCenter.createChild("path")
					.moveTo(0,0)
					.vert(300)
					.setStrokeLineWidth(1)
					.setColor(1,1,1));
		}
		me.values = setsize([], 256);
		me.loop();
	},

	loop: func {
		if (!enable) {settimer(func me.loop(), 0.3); return;}
		for (var i = 0;i<256;i+=1) {
			me.values[i] = 0;
		}
		me.elapsed = getprop("sim/time/elapsed-sec");
		foreach(contact; exampleRadar.vector_aicontacts_bleps) {
			if (me.elapsed - contact.blepTime < 5) {
				me.range = contact.getRangeDirectFrozen();
				if (me.range==0) me.range=1;
				me.distPixels = 2/math.pow(me.range/contact.strength,2);
				me.index = int(256*(contact.getDeviationHeadingFrozen()+60)/120);
				if (me.index<=255 and me.index>= 0) {
					me.values[me.index] += me.distPixels;
					if (me.index+1<=255)
						me.values[me.index+1] += me.distPixels*0.5;
					if (me.index+2<=255)
						me.values[me.index+2] += me.distPixels*0.25;
					if (me.index-1>=0)
						me.values[me.index-1] += me.distPixels*0.5;
					if (me.index-2>=0)
						me.values[me.index-2] += me.distPixels*0.25;
				}
			}
		}
		for (var i = 0;i<256;i+=1) {
			me.line[i].setTranslation(i,-clamp(me.values[i],0,256));
		}
		settimer(func me.loop(), exampleRadar.loopSpeed);
	},
};


RWRView = {
	new: func {
		var window = canvas.Window.new([256, 256],"dialog")
				.set('x', 550)
				.set('y', 350)
                .set('title', "RWR");
		var root = window.getCanvas(1).createGroup();
		window.getCanvas(1).setColorBackground(0,0,0);
		me.rootCenter = root.createChild("group")
				.setTranslation(128,128);
		
	    root.createChild("path")
	       .moveTo(0, 128)
           .arcSmallCW(128, 128, 0, 256, 0)
           .arcSmallCW(128, 128, 0, -256, 0)
           .setStrokeLineWidth(1)
           .setColor(1, 1, 1);
        root.createChild("path")
	       .moveTo(128-43, 128)
           .arcSmallCW(43, 43, 0, 86, 0)
           .arcSmallCW(43, 43, 0, -86, 0)
           .setStrokeLineWidth(1)
           .setColor(0.25, 0.25, 0.25);
        root.createChild("path")
	       .moveTo(128-85, 128)
           .arcSmallCW(85, 85, 0, 170, 0)
           .arcSmallCW(85, 85, 0, -170, 0)
           .setStrokeLineWidth(1)
           .setColor(0.25, 0.25, 0.25);
		me.loop();
	},

	loop: func {
		if (!enableRWRs) {settimer(func me.loop(), 0.3); return;}
		me.rootCenter.removeAllChildren();#print("threats:");
		foreach(contact; exampleRWR.vector_aicontacts_threats) {
			me.threat = contact[1];#print(me.threat);
			if (me.threat < 5) {
				me.threat = 43;# inner circle
			} elsif (me.threat < 30) {
				me.threat = 85;# outer circle
			} else {
				continue;
			}
			me.dev = -contact[0].getThreatStored()[5]+90;
			me.x = math.cos(me.dev*D2R)*me.threat;
			me.y = -math.sin(me.dev*D2R)*me.threat;
			me.rootCenter.createChild("text")
				.setText("15")
				.setTranslation(me.x,me.y)
				.setAlignment("center-center")
				.setColor(1,0,0)
      	  		.setFontSize(10, 1.0);
      	  	me.rootCenter.createChild("path")
					.moveTo(0,-10)
					.lineTo(7,-7)
					.moveTo(0,-10)
					.lineTo(-7,-7)
					.setStrokeLineWidth(1)
					.setColor(1,0,0)
					.setTranslation(me.x,me.y)
					.update();
		}
		

		settimer(func me.loop(), 2);
	},
};



#
# I made this fire-control shell, to get me thinking about way to design such a thing plus pylons.
#

var pylonWsets = {
	a: {id: "2 x AIM-9", content: ["AIM-9","AIM-9"], launcherDragArea: 0.25, launcherMass: 20, launcherJettisonable: 0},
	b: {id: "2 x AIM-120", content: ["AIM-120","AIM-120"], launcherDragArea: 0.25, launcherMass: 20, launcherJettisonable: 0},
	c: {id: "1 x AIM-7", content: ["AIM-7"], launcherDragArea: 0.25, launcherMass: 20, launcherJettisonable: 0},
	d: {id: "1 x GBU-82", content: ["GBU-82"], launcherDragArea: 0.25, launcherMass: 20, launcherJettisonable: 0},
};

var loadAirSuperiority  = [500, "a","b"];# load 500 round into cannon, set 'a' onto left wing pylon, and set 'b' onto right wing pylon.

FireControl = {
# select pylon(s)
# propagate trigger/jettison commands to pylons
# assign targets to arms hanging on pylons
# load entire full sets onto pylons (like in F15)
# no loop.
#
# Attributes:
#   pylon list
#   pylon fire order
};

myFireControl = {

	new: func {
		var fc = {parents: [myFireControl, FireControl]};
		# link to the radar
		fc.activeRadar    = exampleRadar;
		# number of total stations
		fc.stationCount     = 3;
		# the pylon instances
		fc.vector_pylons  = [SubModelStation.new(0, 500), Pylon.new(1,"Left wing", pylonWsets), Pylon.new(2,"Right wing", pylonWsets)];
		# property for trigger
		fc.prop_trigger   = props.globals.getNode("controls/armament/trigger");
		# when trigger is pulled, fire command is sent to these armaments
		fc.triggerArms    = [[1,0]];#first arm on first pylon
		# current selected armaments. Can send radar contact info to these arms.
		fc.selectedArms   = [[1,0]];
		# order to select between arms types
		fc.orderArmTypes  = ["AIM-9","AIM-7","AIM-120","GBU-82"];
		# order to fire from pylons
		fc.orderPylons    = [0,1,2];#cannon, left then right

		return fc;
	},

	jettisonAll: func {
		# drops everything from all pylons.
	},

	jettison: func {
		# drops current selected arms
	},

	addTrigger: func {
		# the currently selected arms is added to list arms that will fire when trigger is pulled.
	},

	removeTrigger: func {
		# the currently selected arms is removed from list arms that will fire when trigger is pulled.
	},

	autoTrigger: func (enable) {
		# selected arms is auto set to trigger
	},

	assign: func {
		# assign current selected radar contact to current selected arms
	},

	autoAssign: func (enable) {
		# If ON then all contacts in Field of Regard is propegated to selected Arms. (used for heatseekers when radar is off)
	},

	clear: func {
		# select nothing
	},

	setMasterMode: func (mode) {
		# Set master arm OFF, ON, REDUCED, SIM.
	},

	cycleArm: func {
		# cycle between arms of same type
	},

	cycleType: func {
		# cycle between different types of arms. Will also clear trigger list.
	},

	selectType: func {
		# select specific type explicit. Will also clear trigger list.
	},

	selectArm: func {
		# select specific arm explicit
	},

	getSelectedArms: func {
		# get the missile-code instance of selected arms. Returns vector.
	},

	loadFullSets: func (loadSets) {
		# load a full complement onto aircraft.
	},
};

###Station
#

###SubModelStation:
# inherits from station
# Implements a fixed station.
#  cannon/rockets and methods to give them commands.
#  should be able to hold submodels
#  no loop, but lots of listeners.
#
# Attributes:
#  drag, weight, submodel(s)

###Pylon:
# inherits from station
# Implements a pylon.
#  missiles/bombs/rockets and methods to give them commands.
#  sets jsbsim/yasim point mass and drag. Mass is combined of all missile-code instances + launcher mass. Same with drag.
#  interacts with GUI payload dialog  ("2 x AIM9L", "1 x GBU-82"), auto-adjusts the name when munitions is fired/jettisoned.
#  should be able to hold missile-code arms.
#  no loop, but lots of listeners.
#
# Attributes:
#   missile-code instance(s) [each with a unique id number that corresponds to a 3D position]
#   pylon id number
#   jsb pointmass id number
#   GUI payload id number
#   individiual positions for 3D (from xml)
#   possible sets that can be loaded ("2 x AIM9L", "1 x GBU-82") At loadtime, this can be many, so store in Nasal :(







var window = nil;
var buttonWindow = func {
	# a test gui for radar modes
	window = canvas.Window.new([200,475],"dialog").set('title',"Radar modes");
	var myCanvas = window.createCanvas().set("background", canvas.style.getColor("bg_color"));
	var root = myCanvas.createGroup();
	var myLayout0 = canvas.HBoxLayout.new();
	var myLayout = canvas.VBoxLayout.new();
	var myLayout2 = canvas.VBoxLayout.new();
	myCanvas.setLayout(myLayout0);
	myLayout0.addItem(myLayout);
	myLayout0.addItem(myLayout2);
#	var button0 = canvas.gui.widgets.Button.new(root, canvas.style, {})
#		.setText("RWS high")
#		.setFixedSize(75, 25);
#	button0.listen("clicked", func {
#		exampleRadar.rwsHigh();
#	});
#	myLayout.addItem(button0);
	var button1 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("RWS")
		.setFixedSize(75, 25);
	button1.listen("clicked", func {
		exampleRadar.rws120();
	});
	myLayout.addItem(button1);
	var button2 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("TWS 15")
		.setFixedSize(75, 25);
	button2.listen("clicked", func {
		exampleRadar.tws15();
	});
	myLayout.addItem(button2);
	var button3 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("TWS 30")
		.setFixedSize(75, 25);
	button3.listen("clicked", func {
		exampleRadar.tws30();
	});
	myLayout.addItem(button3);
	var button4 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("TWS 60")
		.setFixedSize(75, 25);
	button4.listen("clicked", func {
		exampleRadar.tws60();
	});
	myLayout.addItem(button4);
	var button5 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Left")
		.setFixedSize(75, 25);
	button5.listen("clicked", func {
		exampleRadar.left();
	});
	myLayout.addItem(button5);
	var button6 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Right")
		.setFixedSize(75, 25);
	button6.listen("clicked", func {
		exampleRadar.right();
	});
	myLayout.addItem(button6);
	var button7 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Range+")
		.setFixedSize(75, 20);
	button7.listen("clicked", func {
		exampleRadar.more();
	});
	myLayout.addItem(button7);
	var button8 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Range-")
		.setFixedSize(75, 20);
	button8.listen("clicked", func {
		exampleRadar.less();
	});
	myLayout.addItem(button8);
	var button9 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Lock")
		.setFixedSize(75, 25);
	button9.listen("clicked", func {
		exampleRadar.lockRandom();
	});
	myLayout.addItem(button9);
	var button10 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Select|SAM")
		.setFixedSize(75, 25);
	button10.listen("clicked", func {
		exampleRadar.sam();
	});
	myLayout.addItem(button10);
	var button11 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Next")
		.setFixedSize(75, 25);
	button11.listen("clicked", func {
		exampleRadar.next();
	});
	myLayout.addItem(button11);
	var button12 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Up")
		.setFixedSize(75, 25);
	button12.listen("clicked", func {
		exampleRadar.up();
	});
	myLayout.addItem(button12);
	var button13 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Down")
		.setFixedSize(75, 25);
	button13.listen("clicked", func {
		exampleRadar.down();
	});
	myLayout.addItem(button13);
	var button14 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Level")
		.setFixedSize(75, 25);
	button14.listen("clicked", func {
		exampleRadar.level();
	});
	myLayout.addItem(button14);

	var button15b = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("1 Bar")
		.setFixedSize(75, 25);
	button15b.listen("clicked", func {
		exampleRadar.b1();
	});
	myLayout2.addItem(button15b);
	var button15 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("2 Bars")
		.setFixedSize(75, 25);
	button15.listen("clicked", func {
		exampleRadar.b2();
	});
	myLayout2.addItem(button15);
	var button16 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("4 Bars")
		.setFixedSize(75, 25);
	button16.listen("clicked", func {
		exampleRadar.b4();
	});
	myLayout2.addItem(button16);
	var button17 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("6 Bars")
		.setFixedSize(75, 25);
	button17.listen("clicked", func {
		exampleRadar.b6();
	});
	myLayout2.addItem(button17);
	var button18 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("8 Bars")
		.setFixedSize(75, 25);
	button18.listen("clicked", func {
		exampleRadar.b8();
	});
	myLayout2.addItem(button18);
	var button19 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("A1")
		.setFixedSize(75, 25);
	button19.listen("clicked", func {
		exampleRadar.a1();
	});
	myLayout2.addItem(button19);
	var button20 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("A2")
		.setFixedSize(75, 25);
	button20.listen("clicked", func {
		exampleRadar.a2();
	});
	myLayout2.addItem(button20);
	var button21 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("A3")
		.setFixedSize(75, 25);
	button21.listen("clicked", func {
		exampleRadar.a3();
	});
	myLayout2.addItem(button21);
	var button22 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("A4")
		.setFixedSize(75, 25);
	button22.listen("clicked", func {
		exampleRadar.a4();
	});
	button23 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Screens")
		.setFixedSize(75, 20);
	button23.listen("clicked", func {
		enable = !enable;
		if (enable == 0) button23.setText("Scr OFF");
		else button23.setText("Scr ON");
	});
	myLayout2.addItem(button23);
	button24 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("RWRScreen")
		.setFixedSize(75, 20);
	button24.listen("clicked", func {
		enableRWRs = !enableRWRs;
		if (enableRWRs == 0) button24.setText("RWRscr OFF");
		else button24.setText("RWRscr ON");
	});
	myLayout2.addItem(button24);
	button25 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("RWR ON")
		.setFixedSize(75, 20);
	button25.listen("clicked", func {
		enableRWR = !enableRWR;
		if (enableRWR == 0) button25.setText("RWR OFF");
		else button25.setText("RWR ON");
	});
	myLayout2.addItem(button25);
	button26 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Radar ON")
		.setFixedSize(75, 20);
	button26.listen("clicked", func {
		exampleRadar.enabled = !exampleRadar.enabled;
		if (exampleRadar.enabled == 0) button26.setText("RDR OFF");
		else button26.setText("RDR ON");
	});
	myLayout2.addItem(button26);
};

var button23 = nil;
var button24 = nil;
var button25 = nil;
var button26 = nil;

var Launch_Canvas = func (){

RadarViewPPI.new();
RadarViewBScope.new();
RadarViewCScope.new();
RadarViewAScope.new();
RWRView.new();
buttonWindow();
}

Launch_Canvas();
