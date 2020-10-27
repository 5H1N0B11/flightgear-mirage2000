#


var AIR = 0;
var MARINE = 1;
var SURFACE = 2;
var ORDNANCE = 3;

var GEO = 0;
var GPS = 1;

var FALSE = 0;
var TRUE = 1;

var knownShips = {
    "missile_frigate":       nil,
    "frigate":       nil,
    "USS-LakeChamplain":     nil,
    "USS-NORMANDY":     nil,
    "USS-OliverPerry":     nil,
    "USS-SanAntonio":     nil,
};

var VectorNotification = {
    new: func(type) {
        var new_class = emesary.Notification.new(type, rand());
        new_class.updateV = func (vector) {
	    	me.vector = vector;
	    	return me;
	    };
        return new_class;
    },
};

var SliceNotification = {
    new: func() {
        var new_class = emesary.Notification.new("SliceNotification", rand());
        new_class.slice = func (elev_from, elev_to, bear_from, bear_to, dist_m) {
	    	me.elev_from = elev_from;
	    	me.elev_to = elev_to;
	    	me.bear_from = bear_from;
	    	me.bear_to = bear_to;
	    	me.dist_m = dist_m;
	    	return me;
	    };
        return new_class;
    },
};





###GPSContact:
# inherits from Contact
#
# Attributes:
#   coord

###RadarContact:
# inherits from AIContact
#
# Attributes:
#   isPainted()  [asks parent radar is it the one that is painted]
#   isDetected() [asks parent radar if it still is in limitedContactVector]

###LinkContact:
# inherits from AIContact
#
# Attributes:
#   isPainted()  [asks parent radar is it the one that is painted]
#   link to linking aircraft AIContact
#   isDetected() [asks parent radar if it still is in limitedContactVector]



Radar = {
# master radar class
#
# Attributes:
#   on/off
#   limitedContactVector of RadarContacts
	enabled: TRUE,
};
