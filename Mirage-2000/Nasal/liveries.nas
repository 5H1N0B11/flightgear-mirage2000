print("*** LOADING liveries.nas ... ***");
################################################################################
#
#                       m2005-5's LIVERIES SETTINGS
#
################################################################################

var logo_dialog = gui.OverlaySelector.new("Select Logo", "/Aircraft/Mirage-2000/Models/Logos/", "/sim/model/logos/name", nil, "sim/multiplay/generic/string");

# This following thing will add the named propertie in the recorded variable in $HOME
aircraft.data.add("/sim/model/logos/name");

aircraft.livery.init("Aircraft/Mirage-2000/Models/Liveries");
#aircraft.livery.init("Aircraft/Mirage-2000/Models/Logos");
