print("*** LOADING MiscRwr.nas ... ***");
################################################################################
#
#                        m2005-5's RADAR SETTINGS SOON DEPRECIATED
#
################################################################################

var StandByTgtMarker  = 0;
var Target_Index      = 0;
var tableuBound       = 0;



var activate_ECM = func(){
    if(getprop("instrumentation/ecm/on-off") != "true" )
    {
        setprop("instrumentation/ecm/on-off", "true");
    }
    else
    {
        setprop("instrumentation/ecm/on-off", "false");
    }
}



