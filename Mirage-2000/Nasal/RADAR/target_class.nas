
################################################################
#####################   Target class  ##########################
################################################################

setprop("sim/mul"~"tiplay/gen"~"eric/strin"~"g[14]", "o"~"r"~"f");

var Target = {
    new: func(c,theTree = nil){
        var obj             = { parents : [Target,geo.Coord.new()]};
        obj.propNode        = c;
        obj.RdrProp         = c.getNode("radar");
        obj.Heading         = c.getNode("orientation/true-heading-deg");
        
        obj.Alt             = c.getNode("position/altitude-ft");
        obj.lat             = c.getNode("position/latitude-deg");
        obj.lon             = c.getNode("position/longitude-deg");
        
        #As it is a geo.Coord object, we have to update lat/lon/alt ->and alt is in meters
        #print("obj.lat:"~obj.lat~" obj.lon:"~" obj.Alt * FT2M:"~obj.Alt * FT2M);
        obj.set_latlon(obj.lat.getValue(), obj.lon.getValue(), obj.Alt.getValue() * FT2M);
        
        obj.pitch           = c.getNode("orientation/pitch-deg");
        obj.roll           = c.getNode("orientation/roll-deg");
        obj.Speed           = c.getNode("velocities/true-airspeed-kt");
        obj.VSpeed          = c.getNode("velocities/vertical-speed-fps");
        obj.Callsign        = c.getNode("callsign");
        obj.name            = c.getNode("name");
        obj.Valid            = c.getNode("valid");
        obj.validTree       = 0;
        obj.TransponderID = c.getNode("instrumentation/transponder/transmitted-id");
        
        obj.engineTree      = c.getNode("engines");
        
        obj.AcType          = c.getNode("sim/model/ac-type");
        obj.typeString      = c.getName();
        obj.fname           = c.getName();
        
        obj.index           = c.getIndex();
        
        #print(obj.fname);
        obj.flareNode       = c.getNode("rotors/main/blade[3]/flap-deg");
        obj.chaffNode       = c.getNode("rotors/main/blade[3]/position-deg");
        
        #Variable that can/or not being written onthe tree
        obj.InRange = 0 ;
        
        #Change here the object type to set the radar2 path
        #This have to be in a separate function
        
        #Overwrite selectedType if missile
        var TestIfMissileNode = c.getNode("missile");
        if(TestIfMissileNode != nil) {
          if(TestIfMissileNode.getValue()){
            #print("It is a missile");
            obj.typeString  = "missile";
            missileIndex = missileIndex + 1;
            obj.index = missileIndex;            
          }
        }

        obj.Model = c.getNode("model-short");
        var model_short = c.getNode("sim/model/path");
        if(model_short != nil)
        {
            var model_short_val = model_short.getValue();
            if (model_short_val != nil and model_short_val != "")
            {
                var u = split("/", model_short_val); # give array
                var s = size(u); # how many elements in array
                var o = u[s-1];  # the last element
                var m = size(o); # how long is this string in the last element
                var e = m - 4;   # - 4 chars .xml
                obj.ModelType = substr(o, 0, e); # the string without .xml
            }
            else
                obj.ModelType = "";
        } elsif (c.getNode("type") != nil) {
            # not all have a path property
            obj.ModelType = c.getNode("type").getValue();
            if (obj.ModelType == nil) {
                # not all have a type property
                obj.ModelType = "";
            }
        } else {
            obj.ModelType = "";
        }

        
        
        obj.life = 5; #Have to be given in parameters, but now written in hard
        obj.objectDeviationDeg = 0;
        obj.objectElevationDeg = 0;
        obj.objectDisplay       = 0;
        
        
        obj.string          = "ai/models/" ~ obj.typeString ~ "[" ~ obj.index ~ "]";
        obj.shortstring     = obj.typeString ~ "[" ~ obj.index ~ "]";
        
        
        
        var TestID = c.getNode("unicId",1);
        if(TestID.getValue() != nil) {
          obj.ID = TestID.getValue();
          #print("Id already exist:" ~ obj.ID);
        }else{
          obj.ID = int(1000000 * rand());
          TestID.setValue(obj.ID);
          #print("Id Creation" ~ obj.ID);
        }

        
        
        if(theTree == nil)
        {
            obj.InstrString     = "instrumentation/radar2/targets";
        }
        else
        {
            obj.InstrString     = theTree;
        }
        #print("obj.InstrString:" ~obj.InstrString);
        
        #================== This create the tree ===========================
        #on the long term, tree have to disapear
        obj.InstrTgts       = props.globals.getNode(obj.InstrString, 1);
        
        obj.TgtsFiles       =   0; #obj.InstrTgts.getNode(obj.shortstring, 1);
        
        obj.Range           = obj.RdrProp.getNode("range-nm");
        obj.Bearing         = obj.RdrProp.getNode("bearing-deg");
        obj.Elevation       = obj.RdrProp.getNode("elevation-deg");
        obj.InRangeProperty = obj.RdrProp.getNode("in-range",1);
        
        obj.MyCallsign      = 0;
        obj.BBearing        = 0; 
        obj.BHeading        = 0; 
        obj.RangeScore      = 0; 
        obj.RelBearing      = 0; 
        obj.Carrier         = 0; 
        obj.EcmSignal       = 0; 
        obj.EcmSignalNorm   = 0; 
        obj.EcmTypeNum      = 0; 
        obj.Display         = 0; 
        obj.Fading          = 0; 
        obj.DddDrawRangeNm  = 0; 
        obj.TidDrawRangeNm  = 0; 
        obj.RoundedAlt      = 0; 
        obj.TimeLast        = 0;
        obj.lifetime        = 3; #Not implemented yet : should represent the life time in sec of a target. (simpler than actually)
        obj.RangeLast       = 0; 
        obj.ClosureRate     = 0;
        obj.Display_Node    = nil;
        
        obj.ispainted       = 0;
        
        #obj.TimeLast.setValue(ElapsedSec.getValue());
        
        obj.RadarStandby    = c.getNode("sim/multiplay/generic/int[2]");
        
        obj.deviation       = nil;

        

#         if (obj.get_Callsign() == "GROUND_TARGET") {
#             obj.type = armament.SURFACE;
#         }
# 
#         if(obj.type  == "missile"){
#           obj.type  = armament.ORDNANCE;
#         }
        
        obj.type = armament.AIR;
        
        obj.model = "";
        
        return obj;
    },
    
    update:func(c){
        me.RdrProp         = c.RdrProp;
        me.Heading         = c.Heading;
        
        me.Alt             = c.Alt;
        me.lat             = c.lat;
        me.lon             = c.lon;
        
        me.set_latlon(me.lat.getValue(), me.lon.getValue(), me.Alt.getValue() * FT2M);
        
        me.pitch           = c.pitch;
        me.roll            = c.roll;
        me.Speed           = c.Speed;
        me.VSpeed          = c.VSpeed;
        me.Callsign        = c.Callsign;
        me.name            = c.name;
        me.Valid            = c.Valid;
        me.validTree       = c.validTree;
        me.TransponderID   = c.TransponderID;
        
        me.engineTree      = c.engineTree;
        
        me.AcType          = c.AcType;
        
        me.index           = c.index;
        me.flareNode       = c.flareNode;
        me.chaffNode       = c.chaffNode;
        me.RadarStandby    = c.RadarStandby;
        
        
        
        me.InstrTgts       = props.globals.getNode(me.InstrString, 1);
        
        me.TgtsFiles       =   0; #me.InstrTgts.getNode(me.shortstring, 1);
        
        me.Range           = c.Range;
        me.Bearing         = c.Bearing;
        me.Elevation       = c.Elevation;
        me.InRangeProperty = c.InRangeProperty;
        
        me.MyCallsign      = c.MyCallsign;
        me.BBearing        = c.BBearing; 
        me.BBearing        = c.BBearing; 
        me.RangeScore      = c.RangeScore; 
        me.RelBearing      = c.RelBearing; 
        me.Carrier         = c.Carrier; 
        me.EcmSignal       = c.EcmSignal; 
        me.EcmSignalNorm   = c.EcmSignalNorm; 
        me.EcmTypeNum      = c.EcmTypeNum; 
        me.Fading          = c.Fading; 
        me.DddDrawRangeNm  = c.DddDrawRangeNm; 
        me.TidDrawRangeNm  = c.TidDrawRangeNm; 
        me.RoundedAlt      = c.RoundedAlt; 
        me.TimeLast        = 0;
        if(me.life<1){
          me.ispainted       = c.ispainted;
          me.Display         = c.Display;
          me.type            = c.type ;
        }else{
          #if(me.get_Callsign() != ""){print("Update Target :" ~ me.get_Callsign() ~ " Paiting : " ~ me.ispainted ~" and Display : " ~ me.Display);}
        }
        me.lifetime        = 3; # We reinit the lifetime
        me.RangeLast       = c.RangeLast; 
        me.ClosureRate     = c.ClosureRate;
        
        
        
        me.life = 5; 
        me.objectDeviationDeg = c.objectDeviationDeg;
        me.objectElevationDeg = c.objectElevationDeg;
        me.objectDisplay       = c.objectDisplay;
        
        
        me.string          = c.string;
        me.shortstring     = c.shortstring;
    
    },

    create_tree: func(MyAircraftCoord,MyAircraftHeading = nil) {
        me.TgtsFiles      = me.InstrTgts.getNode(me.shortstring, 1);
        
        me.MyCallsign     = me.TgtsFiles.getNode("callsign", 1);
        me.BBearing       = me.TgtsFiles.getNode("bearing-deg", 1);
        me.BHeading       = me.TgtsFiles.getNode("true-heading-deg", 1);
        me.RangeScore     = me.TgtsFiles.getNode("range-score", 1);
        me.RelBearing     = me.TgtsFiles.getNode("ddd-relative-bearing", 1);
        me.Carrier        = me.TgtsFiles.getNode("carrier", 1);
        me.EcmSignal      = me.TgtsFiles.getNode("ecm-signal", 1);
        me.EcmSignalNorm  = me.TgtsFiles.getNode("ecm-signal-norm", 1);
        me.EcmTypeNum     = me.TgtsFiles.getNode("ecm_type_num", 1);
        me.Display_Node   = me.TgtsFiles.getNode("display", 1);
        me.Fading         = me.TgtsFiles.getNode("ddd-echo-fading", 1);
        me.DddDrawRangeNm = me.TgtsFiles.getNode("ddd-draw-range-nm", 1);
        me.TidDrawRangeNm = me.TgtsFiles.getNode("tid-draw-range-nm", 1);
        me.RoundedAlt     = me.TgtsFiles.getNode("rounded-alt-ft", 1);
        me.TimeLast       = me.TgtsFiles.getNode("closure-last-time", 1);
        me.RangeLast      = me.TgtsFiles.getNode("closure-last-range-nm", 1);
        me.ClosureRate    = me.TgtsFiles.getNode("closure-rate-kts", 1);
        
        me.TimeLast.setDoubleValue(ElapsedSec.getValue());
        me.RangeLast.setValue(me.get_range_from_Coord(MyAircraftCoord));
        me.Carrier.setBoolValue(0);
        
        #Create essential tree
        var altTree =me.TgtsFiles.getNode("position/altitude-ft",1);
        var latTree =me.TgtsFiles.getNode("position/latitude-deg",1);
        var lonTree =me.TgtsFiles.getNode("position/longitude-deg",1);
        me.validTree =me.TgtsFiles.getNode("valid",1);
        var radarBearing =me.TgtsFiles.getNode("radar/bearing-deg",1);
        var radarRange =me.TgtsFiles.getNode("radar/range-nm",1);
        var elevation =me.TgtsFiles.getNode("radar/elevation-deg",1);
        var deviation =me.TgtsFiles.getNode("radar/deviation-deg",1);
        var velocities =me.TgtsFiles.getNode("velocities/true-airspeed-kt",1);
        var transpondeur =me.TgtsFiles.getNode("instrumentation/transponder/transmitted-id",1);
        var heading =me.TgtsFiles.getNode("orientation/true-heading-deg",1);
        #var myDeviation = me.get_deviation(MyAircraftHeading,MyAircraftCoord);

        altTree.setValue(me.Alt.getValue());
        latTree.setValue(me.lat.getValue());
        lonTree.setValue(me.lon.getValue());
        me.validTree.setValue(me.Valid.getValue());
        radarBearing.setValue(me.Bearing.getValue());
        radarRange.setValue(me.Range.getValue());
        elevation.setValue(me.Elevation.getValue());
        deviation.setValue(me.objectDeviationDeg);
        velocities.setValue(me.Speed.getValue());
        if(me.TransponderID != nil)
        {
            if(me.TransponderID.getValue() != nil)
            {
                transpondeur.setValue(me.TransponderID.getValue());
            }
        }
        heading.setValue(me.Heading.getValue());
    },

    set_all: func(myAircraftCoord){
        me.RdrProp.getNode("in-range",1).setBoolValue(1);
        me.MyCallsign.setValue(me.get_Callsign());
        me.BHeading.setValue(me.Heading.getValue());
        me.BBearing.setValue(me.get_bearing_from_Coord(myAircraftCoord));
    },

    remove: func(){
        #me.validTree = 0;
        if(me.validTree != 0){me.validTree.setValue(0);}
        me.InstrTgts.removeChild(me.type, me.index);
    },

    set_nill: func(){
        # Suppression of the HUD display :
        # The property is initialised when the target is in range of "instrumentation/radar/range"
        # But nothing is done when "It's no more in range"
        # So this is a little hack for HUD.
        if(me.validTree != 0){me.validTree.setValue(0);}
        #me.RdrProp.getNode("in-range").setValue("false");
        
        var Tempo_TgtsFiles = me.InstrTgts.getNode(me.shortstring, 1);
        var Property_list   = Tempo_TgtsFiles.getChildren();
        foreach(var myProperty ; Property_list)
        {
            #print(myProperty.getName());
            if(myProperty.getName() != "closure-last-time")
            {
                myProperty.setValue("");
            }
        }
    },

    get_Validity: func(){
        var n = 0;
        if(getprop(me.InstrString ~ "/" ~ me.shortstring ~ "/closure-last-time") != nil)
        {
            n = 1;
        }
        return n;
    },

    get_TimeLast: func(){
        var n = 0;
        if(getprop(me.InstrString ~ "/" ~ me.shortstring ~ "/closure-last-time") != nil )
        {
            #print(me.InstrString ~ "/" ~ me.shortstring ~ "/closure-last-time");
            #print(getprop(me.InstrString ~ "/" ~ me.shortstring ~ "/closure-last-time"));
            n = getprop(me.InstrString ~ "/" ~ me.shortstring ~ "/closure-last-time");
        }
        return n;
    },

    get_Coord: func(){
        TgTCoord  = geo.Coord.new();
        TgTCoord.set_latlon(me.lat.getValue(), me.lon.getValue(), me.Alt.getValue() * FT2M);
        me.set_latlon(me.lat.getValue(), me.lon.getValue(), me.Alt.getValue() * FT2M);
        return TgTCoord;
    },

    get_Callsign: func(){
        var n = me.Callsign.getValue();
        if(n == nil or n == ""){n = me.name.getValue();}
        if(n == nil or n == ""){n = "UFO";}
        return n;
    },

    get_Speed: func(){
        var n = me.Speed.getValue();
        #var alt = me.Alt.getValue();
        #n = n / (0.632 ^ (-(alt / 25066))); # Calcul of Air Speed based on ground speed. the function ^ doesn't work !!
        return n;
    },

    get_Longitude: func(){
        var n = me.lon.getValue();
        return n;
    },

    get_Latitude: func(){
        var n = me.lat.getValue();
        return n;
    },

    get_Pitch: func(){
        var n = me.pitch.getValue();
        return n;
    },

    get_Roll: func(){
        var n = me.roll.getValue();
        return n;
    },

    get_heading : func(){
        var n = me.Heading.getValue();
        if(n == nil)
        {
            n = 0;
        }
        return n;
    },

    get_bearing: func(){
        var n = 0;
        n = me.Bearing.getValue();
        if(n == nil)
        {
            n = 0;
        }
        return n;
    },

    get_bearing_from_Coord: func(MyAircraftCoord){
        var myCoord = me.get_Coord();
        var myBearing = 0;
        if(myCoord.is_defined())
        {
            myBearing = MyAircraftCoord.course_to(myCoord);
            me.Bearing.setValue(myBearing);
        }
        #print("get_bearing_from_Coord :" ~ myBearing);
        return myBearing;
    },

    get_reciprocal_bearing: func(){
        return geo.normdeg(me.get_bearing() + 180);
    },

    get_deviation: func(true_heading_ref, coord){
        me.objectDeviationDeg =  - deviation_normdeg(true_heading_ref, me.get_bearing_from_Coord(coord));
        #print(me.deviation);
        return me.objectDeviationDeg;
    },

    get_altitude: func(){
        #Return Alt in feet
        return me.Alt.getValue();
    },

    get_Elevation_from_Coord: func(MyAircraftCoord){
        var myCoord = me.get_Coord();
        #me.objectElevationDeg = math.asin((myCoord.alt() - MyAircraftCoord.alt()) / myCoord.direct_distance_to(MyAircraftCoord)) * R2D;
        me.objectElevationDeg = vector.Math.getPitch(geo.aircraft_position(), me.get_Coord()); 
        me.Elevation.setValue(me.objectElevationDeg);
        return me.objectElevationDeg;
    },

    get_total_elevation_from_Coord: func(own_pitch, MyAircraftCoord){
        var myTotalElevation =  - deviation_normdeg(own_pitch, me.get_Elevation_from_Coord(MyAircraftCoord));
        me.Elevation.setValue(myTotalElevation);
        return myTotalElevation;
    },
    
    get_total_elevation: func(own_pitch){
        me.myTotalElevation =  - deviation_normdeg(own_pitch, me.Elevation.getValue());
        return me.myTotalElevation;
    },

    get_range: func(){
        #print("me.Range.getValue() :" ~ me.Range.getValue());
        return me.Range.getValue();
    },

    get_range_from_Coord: func(MyAircraftCoord){
        var myCoord = me.get_Coord();
        var myDistance = 0;
        if(myCoord.is_defined())
        {
            myDistance = MyAircraftCoord.direct_distance_to(myCoord) * M2NM;
            me.Range.setValue(myDistance);
        }
        #print("get_range_from_Coord :" ~ myDistance);
        return myDistance;
    },

    get_horizon: func(own_alt){
    # Own alt in meters
        var tgt_alt = me.get_altitude();#It's in feet
        if(debug.isnan(tgt_alt))
        {
            return(0);
        }
        if(tgt_alt < 0 or tgt_alt == nil)
        {
            tgt_alt = 0;
        }
        if(own_alt < 0 or own_alt == nil)
        {
            own_alt = 0;
        }
        # Return the Horizon in NM
        return(2.2 * ( math.sqrt(own_alt) + math.sqrt(tgt_alt * FT2M)));
    },

    get_engineTree: func(){
        return me.engineTree;
    },

    check_carrier_type: func(){
        var type = "none";
        var carrier = 0;
        if(me.AcType != nil)
        {
            type = me.AcType.getValue();
        }
        if(type == "MP-Nimitz"
            or type == "MP-Eisenhower"
            or type == "MP-Vinson"
            or type == "Nimitz"
            or type == "Eisenhower"
            or type == "Vinson"
        )
        {
            carrier = 1;
        }
        if(me.type == "carrier")
        {
            carrier = 1;
        }
        # This works only after the mp-carrier model has been loaded. Before that it is seen like a common aircraft.
        if(me.get_Validity())
        {
            setprop(me.InstrString ~ "/" ~ me.shortstring ~ "/carrier", carrier);
        }
        return carrier;
    },

    get_rdr_standby: func(){
        var s = 0;
        if(me.RadarStandby != nil)
        {
            s = me.RadarStandby.getValue();
            if(s == nil)
            {
                s = 0;
            }
            elsif(s != 1)
            {
                s = 0;
            }
        }
        return s;
    },

    get_display: func(){
        #print("Get display : " ~ me.get_Callsign() ~ " Paiting : " ~ me.ispainted ~" and Display : " ~ me.Display);
        return me.Display;
    },

    set_display: func(n,writeTree = nil){
        me.Display = n;
        if(writeTree == nil or writeTree==1){
          me.Display_Node.setBoolValue(n);
        }
        me.objectDisplay = n;
    },
    
    set_relative_bearing: func(n,writeTree = nil){
        if(n == nil)
        {
            n = 0;
        }
        if(writeTree == nil or writeTree==1){
          me.RelBearing.setValue(n);
        }else{          
          me.RelBearing = n;
        }
    },

    get_fading: func(){
        var fading = me.Fading.getValue();
        if(fading == nil)
        {
            fading = 0;
        }
        return fading;
    },

    set_fading: func(n,writeTree = nil){
        if(writeTree == nil or writeTree==1){
          me.Fading.setValue(n);
        }else{
          me.Fading = n;
        }
    },

    set_ddd_draw_range_nm: func(n,writeTree = nil){
        if(writeTree == nil or writeTree==1){
          me.DddDrawRangeNm.setValue(n);
        }else{
          me.DddDrawRangeNm = n;
        }
    },

    set_hud_draw_horiz_dev: func(n,writeTree = nil){
        if(writeTree == nil or writeTree==1){
          me.HudDrawHorizDev.setValue(n);
        }else{
          me.HudDrawHorizDev = n;
        }
    },

    set_tid_draw_range_nm: func(n,writeTree = nil){
        #print("The n 1:" ~ n);
        if(writeTree == nil or writeTree==1){
          #print("The n 2:" ~ n);
          me.TidDrawRangeNm.setValue(n);
          #print("The n 3:" ~ me.TidDrawRangeNm.getValue());
        }else{
          me.TidDrawRangeNm = n;
        }
    },

    set_rounded_alt: func(n,writeTree = nil){
        if(writeTree == nil or writeTree==1){
          me.RoundedAlt.setValue(n);
        }else{
          me.RoundedAlt = n;
        }
    },

    get_closure_rate: func(){
        var dt = ElapsedSec.getValue() - me.TimeLast.getValue();
        var rng = me.Range.getValue();
        var lrng = me.RangeLast.getValue();
        if(debug.isnan(rng) or debug.isnan(lrng))
        {
            print("####### get_closure_rate(): rng or lrng = nan ########");
            me.ClosureRate.setValue(0);
            me.RangeLast.setValue(0);
            return(0);
        }
        var t_distance = lrng - rng;
        var cr = (dt > 0) ? t_distance / dt * 3600 : 0;
        me.ClosureRate.setValue(cr);
        me.RangeLast.setValue(rng);
        return(cr);
    },

    get_closure_rate_from_Coord: func(MyAircraftCoord) {
        # First step : find the target heading.
        var myHeading = me.Heading.getValue();
        
        # Second What would be the aircraft heading to go to us
        var myCoord = me.get_Coord();
        var projectionHeading = myCoord.course_to(MyAircraftCoord);
        
        # Calculate the angle difference
        var myAngle = myHeading - projectionHeading; #Should work even with negative values
        
        # take the "ground speed"
        # velocities/true-air-speed-kt
        var mySpeed = me.Speed.getValue();
        var myProjetedHorizontalSpeed = mySpeed*math.cos(myAngle*D2R); #in KTS
        
        #print("Projetted Horizontal Speed:"~ myProjetedHorizontalSpeed);
        
        # Now getting the pitch deviation
        var myPitchToAircraft = - me.Elevation.getValue();
        #print("My pitch to Aircraft:"~myPitchToAircraft);
        
        # Get V speed
        if(me.VSpeed.getValue() == nil)
        {
            return 0;
        }
        var myVspeed = me.VSpeed.getValue()*FPS2KT;
        # This speed is absolutely vertical. So need to remove pi/2
        
        var myProjetedVerticalSpeed = myVspeed * math.cos(myPitchToAircraft-90*D2R);
        
        # Control Print
        #print("myVspeed = " ~myVspeed);
        #print("Total Closure Rate:" ~ (myProjetedHorizontalSpeed+myProjetedVerticalSpeed));
        
        # Total Calculation
        var cr = myProjetedHorizontalSpeed+myProjetedVerticalSpeed;
        
        # Setting Essential properties
        var rng = me. get_range_from_Coord(MyAircraftCoord);
        var newTime= ElapsedSec.getValue();
        if(me.get_Validity())
        {
            setprop(me.InstrString ~ "/" ~ me.shortstring ~ "/closure-last-range-nm", rng);
            setprop(me.InstrString ~ "/" ~ me.shortstring ~ "/closure-rate-kts", cr);
        }
        
        return cr;
    },

    get_shortring:func(){
        return me.shortstring;
    },

    get_type: func(){
        #print("Type:"~me.type);
        return me.type;
    },

    setType: func(typ) {
        me.type = typ;
    },

    getUnique: func () {
      #var myIndex = me.getIndex();
      return me.fname~me.ID;
        #return me.get_type()~me.fname~me.ID;
    },

    isValid: func() {
        return me.Valid.getValue();
    },
    
    isRadiating: func (coord) {
      me.rn = me.get_range();
      if (me.get_model() != "buk-m2" and me.get_model() != "missile_frigate" or me.get_type()== armament.MARINE) {
          me.bearingR = coord.course_to(me.get_Coord());
          me.headingR = me.get_heading();
          me.inv_bearingR =  me.bearingR+180;
          me.deviationRd = me.inv_bearingR - me.headingR;
      } else {
          me.deviationRd = 0;
      }
      me.rdrAct = me.propNode.getNode("sim/multiplay/generic/int[2]");
      if (me.rn < 70 and ((me.rdrAct != nil and me.rdrAct.getValue()!=1) or me.rdrAct == nil) and math.abs(geo.normdeg180(me.deviationRd)) < 60) {
          # our radar is active and pointed at coord.
          #print("Is Radiating");
          return 1;
      }
      return 0;
      print("Is Not Radiating");
    },

    getElevation: func () {
        return me.get_Elevation_from_Coord(geo.aircraft_position());
    },

    getFlareNode: func(){
        return me.flareNode;
    },

    getChaffNode: func(){
        return me.chaffNode;
    },

    setPainted: func(mypainting){
        #print("Painting : " ~ mypainting);
        me.ispainted = mypainting;
    },

    isPainted: func() {
        #if(me.Display == 0){me.setPainted(0);}
        #print(me.get_Callsign() ~ "Paiting : " ~ me.ispainted);
        return me.ispainted;            # Shinobi this is if laser/lock is still on it. Used for laser and semi-radar guided missiles/bombs.
    },
    isLaserPainted: func() {
        return me.ispainted; 
    },
    isVirtual: func(){
      if(me.get_Callsign() == "GROUND_TARGET"){return 1;}else{return 0;}
    },

    get_model: func {
        return me.model;
    },
 
    set_model: func (mdl) {
        me.model = mdl;
    },

    list : [],
};

# Utilities.
var deviation_normdeg = func(our_heading, target_bearing){
    var dev_norm = our_heading - target_bearing;
    while(dev_norm < -180)
    {
        dev_norm += 360;
    }
    while(dev_norm > 180)
    {
        dev_norm -= 360;
    }
    return(dev_norm);
}

var rounding1000 = func(n){
    var a = int(n / 1000);
    var l = (a + 0.5) * 1000;
    n = (n >= l) ? ((a + 1) * 1000) : (a * 1000);
    return(n);
}
