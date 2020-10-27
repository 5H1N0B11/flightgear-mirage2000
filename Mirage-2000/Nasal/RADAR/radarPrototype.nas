###LinkRadar:
# inherits from Radar, represents a fighter-link/link16.
# Get contact name from other aircraft, and finds local RadarControl for it.
# no loop. emesary listener on aircraft for link.
#
# Attributes:
#   contact selection(s) of type LinkContact
#   imaginary hard/soft lock
#   link list of contacts of type LinkContact


#troubles:
# rescan of ai tree, how to equal same aircraft with new name (COMPARE: callsign, sign, name, model-name)
# doppler only in a2a mode
# 

# TODO: tons of features and tons of different designs to try. Like scanning a 360 azimuth without reversing direction when bar finished.

AIToNasal.new();
var omni = OmniRadar.new(0.25);
var terrain = TerrainChecker


.new(0.10);
var nose = NoseRadar.new(15000,60,5);
var exampleRadar = ExampleRadar.new();
var exampleRWR   = RWR.new();

