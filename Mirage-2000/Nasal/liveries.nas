print("*** LOADING liveries.nas ... ***");
################################################################################
#
#                       m2005-5's LIVERIES SETTINGS
#
################################################################################

var logo_dialog = gui.OverlaySelector.new("Select Logo", "/Aircraft/Mirage-2000/Models/Logos/", "/sim/model/logos/name", nil, "sim/multiplay/generic/string");

# This following thing will add the named propertie in the recorded variable in $HOME
aircraft.data.add("/sim/model/logos/name");

var service_door_dialog = gui.OverlaySelector.new("Select Service-door", "/Aircraft/Mirage-2000/Models/Service-door/", "/sim/model/service-door/name", nil, "sim/multiplay/generic/string");

# This following thing will add the named property in the recorded variable in $HOME
aircraft.data.add("/sim/model/service-door/name");

aircraft.livery.init("Aircraft/Mirage-2000/Models/Liveries");
