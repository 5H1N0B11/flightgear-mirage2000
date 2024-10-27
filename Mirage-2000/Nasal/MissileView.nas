print("*** LOADING MissileView.nas ... ***");

var versionString = getprop("sim/version/flightgear");
var version = split(".", versionString);
var major = num(version[0]);
var minor = num(version[1]);
var pica  = num(version[2]);


var missile_view_handler = {
	init: func(node) {
		me.viewN = node;
		me.current = nil;
		me.legendN = props.globals.initNode("/sim/current-view/missile-view", "");
		me.dialog = props.Node.new({ "dialog-name": "missile-view" });
		me.listener = nil;
	},

	start: func {
		me.listener = setlistener("/sim/signals/ai-updated", func me._update_(), 1);
		me.reset();
		fgcommand("dialog-show", me.dialog);
	},

	stop: func {
		fgcommand("dialog-close", me.dialog);
		if (me.listener!=nil) {
			removelistener(me.listener);
			me.listener=nil;
		}
	},

	reset: func {
		me.select(0);
	},

	find: func(callsign) {
		forindex (var i; me.list) {
			if (me.list[i].callsign == callsign) {
				return i;
			}
		return nil;
		}
	},

	select: func(which, by_callsign=0) {
		if (by_callsign or num(which) == nil) {
			which = me.find(which) or 0;  # turn callsign into index
		}
		me.setup(me.list[which]);
	},

	next: func(step) {
		me._update_();
		var i = me.find(me.current);
		i = i == nil ? 0 : math.mod(i + step, size(me.list));
		me.setup(me.list[i]);
	},

	_update_: func {
		var self = { callsign: getprop("/sim/multiplay/callsign"), model:, node: props.globals, root: '/' };
		me.list = [self] ~ myModel.get_list();
		if (!me.find(me.current)) {
			me.select(0);
		}
	},

	setup: func(data) {
		var ident = '"' ~ data.callsign ~ '"';
		if (data.root == '/') {
			var zoffset = getprop("/sim/chase-distance-m");
		} else {
			var zoffset = -30;
			var load_heading = int(getprop(data.root ~ "/orientation/true-heading-deg"));
			var offset_heading = load_heading>180? 540-load_heading :(180 - load_heading);
			var offset_pitch = int(getprop(data.root ~ "/orientation/pitch-deg")) - 5;

			setprop("/sim/view[101]/config/heading-offset-deg", offset_heading);
			setprop("/sim/view[101]/config/pitch-offset-deg", offset_pitch);
		}

		me.current = data.callsign;
		me.legendN.setValue(ident);

		setprop("/sim/view[101]/config/z-offset-m", zoffset);

		if (major <= 2020) {
			me.viewN.getNode("config").setValues({
				"root":data.root,
				#legacy code, for older FG version
				"eye-lat-deg-path": data.root ~ "/position/latitude-deg",
				"eye-lon-deg-path": data.root ~ "/position/longitude-deg",
				"eye-alt-ft-path": data.root ~ "/position/altitude-ft",
				"eye-heading-deg-path": data.root ~ "/orientation/true-heading-deg",
				"target-lat-deg-path": data.root ~ "/position/latitude-deg",
				"target-lon-deg-path": data.root ~ "/position/longitude-deg",
				"target-alt-ft-path": data.root ~ "/position/altitude-ft",
				"target-heading-deg-path": data.root ~ "/orientation/true-heading-deg",
				"target-pitch-deg-path": data.root ~ "/orientation/pitch-deg",
				"target-roll-deg-path": data.root ~ "/orientation/roll-deg",
			#       "heading-offset-deg":180
			});
		} else {
			me.viewN.getNode("config").setValues({
				"root":data.root,
			});
		}
	},
};

var myModel = ai.AImodel.new();
myModel.init();

view.manager.register("Missile view",missile_view_handler);

var view_firing_missile = func(myMissile) {
	# We select the missile name
	var myMissileName = string.replace(myMissile.ai.getPath(), "/ai/models/", "");

	# We memorize the initial view number
	#   var actualView = getprop("/sim/current-view/view-number-raw");
	#     setprop("/sim/current-view/view-number-raw", 101);
	#     setprop("/sim/current-view/view-number-raw",actualView);

	# We recreate the data vector to feed the missile_view_handler
	var data = { node: myMissile.ai, callsign: myMissileName, root: myMissile.ai.getPath()};

	# We activate the AI view (on this aircraft it is the number 9)
	setprop("/sim/current-view/view-number-raw", 101);
	# setprop("/sim/current-view/heading-offset-deg", 160);

	# We feed the handler
	view.missile_view_handler.setup(data);
}

var init_missile_view = func() {
	setprop("/sim/current-view/view-number-raw", 101);
	setprop("/sim/current-view/heading-offset-deg", 0);
	var timer = maketimer(3,func(){
	setprop("/sim/current-view/view-number-raw", 0);
	});
	timer.singleShot = 1; # timer will only be run once
	timer.start();
}
