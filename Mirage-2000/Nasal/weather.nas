print("*** LOADING weather.nas ... ***");
var start = 1;
var moisture = 0;
var foglevel = 0;
var frostlevel = 0;

var dewpointC = getprop("/environment/dewpoint-degc");
var airtempC = getprop("/environment/temperature-degc");

var cabinheatset = 0; #double flow 0 - 1 
var cabinairset = 0;  #double flow 0 - 1 
var cabindewpointset = -7; #19.4 degF

props.Node.new({ "/environment/aircraft-effects/cabin-heat-set":0 });
props.globals.initNode("/environment/aircraft-effects/cabin-heat-set", cabinheatset, "DOUBLE");
props.Node.new({ "/environment/aircraft-effects/cabin-air-set":0 });
props.globals.initNode("/environment/aircraft-effects/cabin-air-set", cabinairset, "DOUBLE");
props.Node.new({ "/environment/aircraft-effects/cabin-dew-setC":0 });
props.globals.initNode("/environment/aircraft-effects/cabin-dew-setC", cabindewpointset, "DOUBLE");

#added for flight recorder
props.Node.new({ "/environment/aircraft-effects/cabinairtempC":0 });
props.globals.initNode("/environment/aircraft-effects/cabinairtempC", airtempC, "DOUBLE");
props.Node.new({ "/environment/aircraft-effects/surfacetempC":0 });
props.globals.initNode("/environment/aircraft-effects/surfacetempC", airtempC, "DOUBLE");
props.Node.new({ "/environment/aircraft-effects/cabinairdewpointC":0 });
props.globals.initNode("/environment/aircraft-effects/cabinairdewpointC", dewpointC, "DOUBLE");

var weather_effects_loop = func {
    var cabinairtempC = getprop("/environment/aircraft-effects/cabinairtempC");
    var surfacetempC = getprop("/environment/aircraft-effects/surfacetempC");
    var cabinairdewpointC = getprop("/environment/aircraft-effects/cabinairdewpointC");

    ############################################## frost/fog/heat/air

    dewpointC = getprop("/environment/dewpoint-degc");
    airtempC = getprop("/environment/temperature-degc");
    cabinairdewpointC = dewpointC;
    cabinairset = getprop("/environment/aircraft-effects/cabin-air-set");
    cabinheatset = getprop("/environment/aircraft-effects/cabin-heat-set");


    #cabinheat only pushes heat into cabin if a cabinair is open.
    #cabinair is the flow of air into cabin(it will contian heat if cabinheat is open),
    #otherwise it is just outside airtemp
    if (cabinheatset > 0) 
    {
        cabinairtempC += .04*((cabinheatset*2)*cabinairset);
        if (cabinairtempC > 32)
        {
#             if (!getprop("/fdm/jsbsim/weather"))
#                 gui.popupTip("Cabin temperature exceeding 90F/32C!");
        }
        #surfacetemp is slowly changed by cabinairtemp
        if (surfacetempC < cabinairtempC)
            surfacetempC += .03*((cabinheatset*2)*cabinairset);
        if (surfacetempC > cabinairtempC)
            surfacetempC -= .03*((cabinheatset*2)*cabinairset);
    } 
    else
    if (cabinairset > 0)
    {
        #if no cabinheat then we incrementally adjust cabintemp with outside airtemp
        if (cabinairtempC < airtempC)
            cabinairtempC += .03*cabinairset;
        if (cabinairtempC > airtempC) 
            cabinairtempC -= .03*cabinairset;
        if (surfacetempC < cabinairtempC)
            surfacetempC += .02*cabinairset;
        if (surfacetempC > cabinairtempC)
            surfacetempC -= .02*cabinairset; 
    } 

    #regardless of whether or not vents are open we
    #incremetally adjust cabintemp with outside airtemp
    if (cabinairtempC < airtempC)
        cabinairtempC += .01;
    if (cabinairtempC > airtempC) 
        cabinairtempC -= .01;
    if (cabinairdewpointC < dewpointC)
        cabinairdewpointC += .01;
    if (cabinairdewpointC > dewpointC)
        cabinairdewpointC -= .01;
    if (surfacetempC < cabinairtempC)
        surfacetempC += .01;
    if (surfacetempC > cabinairtempC)
        surfacetempC -= .01;

    #if cabinairtemp is less than dewpointtemp at startup we start out
    #with fog. If it is also freezing we switch to frost.
    #Otherwise we start calculating moisture level in the air
    if (cabinairtempC <= cabinairdewpointC) 
    {
        if (start == 1) {
            foglevel = 1;
            if (cabinairtempC <= 0) 
            {
                frostlevel = 1;
                foglevel = 0;
            }
            start = 0;
        }
        else 
        if (surfacetempC <= cabinairdewpointC)
            if (moisture < 1) moisture += .01;
    }
    else 
    {
        if (surfacetempC > cabinairdewpointC)
            if (moisture > 0) moisture -= .01;
        start = 0;
    }

    #we can't get frost unless temp is freezing
    #if it is not freezing then we get fog instead
    if (cabinairtempC <= 0) 
    {
        frostlevel = moisture * 3;
        if (foglevel > 0) foglevel -= moisture;
        if (foglevel < 0) foglevel = 0;
        if (frostlevel > 1) frostlevel = 1;
    }
    else
    {
        foglevel = moisture;
        if (frostlevel > 0) frostlevel -= moisture;
        if (frostlevel < 0) frostlevel = 0;
        if (foglevel > 1) foglevel = 1;
    }

        interpolate("/environment/aircraft-effects/frost-level", frostlevel, 4);
        interpolate("/environment/aircraft-effects/fog-level", foglevel, 4);
        #added for flight recorder
        if(!getprop("/sim/freeze/replay-state"))
        {
            setprop("/environment/aircraft-effects/cabinairtempC", cabinairtempC);
            setprop("/environment/aircraft-effects/surfacetempC", surfacetempC);
            setprop("/environment/aircraft-effects/cabinairdewpointC", cabinairdewpointC);
        }
        #added for flight recorder
        if(!getprop("/sim/freeze/replay-state"))
        {
            setprop("/environment/aircraft-effects/cabinairtempC", getprop("/environment/temperature-degc"));
            setprop("/environment/aircraft-effects/surfacetempC", getprop("/environment/temperature-degc"));
            setprop("/environment/aircraft-effects/cabinairdewpointC", getprop("/environment/dewpoint-degc"));
        }
}

