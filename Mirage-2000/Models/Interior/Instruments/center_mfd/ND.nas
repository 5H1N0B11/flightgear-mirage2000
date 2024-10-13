print("*** LOADING ND.nas ... ***");
################################################################################
#
#                     m2005-5's NAV DISPLAY SETTINGS
#
################################################################################

# storage container for all ND instances
var nd_display = {};
var IsIntialised = 0;
var ND = 0;
var NDCpt = 0;

# configure aircraft specific cockpit/ND switches here
# these are to be found in the property branch you specify
# via the NavDisplay.new() call
# the backend code in navdisplay.mfd should NEVER contain any aircraft-specific
# properties, or it will break other aircraft using different properties
# instead, make up an identifier (hash key) and map it to the property used
# in your aircraft, relative to your ND root in the backend code, only ever
# refer to the handle/key instead via the me.get_switch('toggle_range') method
# which would internally look up the matching aircraft property,
# e.g. '/instrumentation/efis'/inputs/range-nm'
#
# note: it is NOT sufficient to just add new switches here, the backend code
# in navdisplay.mfd also needs to know what to do with them !
# refer to incomplete symbol implementations to learn how they work
# (e.g. WXR, STA)

var myCockpit_switches = {
	# symbolic alias : relative property (as used in bindings), initial value, type
	'toggle_range':         { path: '/inputs/range-nm',    value: 40,    type: 'INT' },
	'toggle_weather':       { path: '/inputs/wxr',         value: 0,     type: 'BOOL' },
	'toggle_airports':      { path: '/inputs/arpt',        value: 0,     type: 'BOOL' },
	'toggle_stations':      { path: '/inputs/sta',         value: 0,     type: 'BOOL' },
	'toggle_waypoints':     { path: '/inputs/wpt',         value: 0,     type: 'BOOL' },
	'toggle_position':      { path: '/inputs/pos',         value: 0,     type: 'BOOL' },
	'toggle_data':          { path: '/inputs/data',        value: 0,     type: 'BOOL' },
	'toggle_terrain':       { path: '/inputs/terr',        value: 0,     type: 'BOOL' },
	'toggle_traffic':       { path: '/inputs/tfc',         value: 0,     type: 'BOOL' },
	'toggle_centered':      { path: '/inputs/nd-centered', value: 0,     type: 'BOOL' },
	'toggle_lh_vor_adf':    { path: '/inputs/lh-vor-adf',  value: 0,     type: 'INT' },
	'toggle_rh_vor_adf':    { path: '/inputs/rh-vor-adf',  value: 0,     type: 'INT' },
	'toggle_display_mode':  { path: '/mfd/display-mode',   value: 'MAP', type: 'STRING' },
	'toggle_display_type':  { path: '/mfd/display-type',   value: 'LCD', type: 'STRING' },
	'toggle_true_north':    { path: '/mfd/true-north',     value: 1,     type: 'BOOL' },
	'toggle_rangearc':      { path: '/mfd/rangearc',       value: 0,     type: 'BOOL' },
	'toggle_track_heading': { path: '/hdg-trk-selected',   value: 0,     type: 'BOOL' },
	# add new switches here
};

# entry point, this will set up all ND instances
var CANVAS_init = func() {
	# get a handle to the NavDisplay in canvas namespace (for now),
	# see $FG_ROOT/Nasal/canvas/map/navdisplay.mfd
	ND = canvas.NavDisplay;
	IsIntialised = 1;

	# set up a  new ND instance, under 'instrumentation/efis' and use the
	# myCockpit_switches hash to map control properties
	NDCpt = ND.new("instrumentation/efis", myCockpit_switches);

	nd_display.cpt = canvas.new({
		"name":       "ND",
		"size":       [256, 256],
		"view":       [1024, 1024],
		"mipmapping": 1
	});
	nd_display.cpt.addPlacement({ "node": "center_mfd.blackbkd" });
	var group = nd_display.cpt.createGroup();
	NDCpt.newMFD(group, nd_display.cpt);
}

var showNd = func(pilot='cpt') {
	# The optional second arguments enables creating a window decoration
	var dlg = canvas.Window.new([400, 400], "dialog");
	dlg.setCanvas( nd_display[pilot] );
}

var mdfselection = func() {
	if(getprop("/instrumentation/efis/Mode") and IsIntialised != 1) {
		mirage2000.CANVAS_init();
	} else {
		if(IsIntialised == 1) {
			ND.del;
			NDCpt.del;
			nd_display.cpt.del;
		}
	}
}
