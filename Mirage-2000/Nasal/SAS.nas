print("*** LOADING SAS.nas ... ***");
################################################################################
#
#                   m2005-5's STABILITY AUGMENTATION SYSTEM
#
################################################################################

var t_increment         = 0.0075;
var p_lo_speed          = 300;
var p_lo_speed_sqr      = p_lo_speed * p_lo_speed;
var p_vlo_speed         = 160;
var gear_lo_speed       = 15;
var gear_lo_speed_sqr   = gear_lo_speed * gear_lo_speed;
var roll_lo_speed       = 450;
var roll_lo_speed_sqr   = roll_lo_speed * roll_lo_speed;
var p_kp                = -0.05;
var e_smooth_factor     = 0.1;
var r_smooth_factor     = 0.2;
var r_neutral           = 0.01;#roll neutral
var p_max               = 0.2;
var p_min               = -0.2;
var max_e               = 1;
var min_e               = 0.55;
var maxG                = 9; # mirage 2000 max everyday 8.5G; overload 11G and 12G will damage the aircraft 9G is for airshow. 5.5 for Heavy loads
var minG                = -3; # -3.5
var maxAoa              = 24;
var minAoa              = -10;
var maxRoll             = 270; # in degre/sec but when heavy loaded : 150 
var last_e_tab          = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
var last_a_tab          = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
var tabG                = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];

var maxRollCat          = [270, 150];
var MaxGCat             = [9, 5.5];


#Elevator trim at 300 kts, when we switch between aoa and G
var trimAtSwitch = -0.07;

# Values around 300 kts for Gload leading the pitch
var GposInit                = [9.89, 9.89, 9.89, 9.89, 9.89, 9.89, 9.89, 9.89, 9.89, 9.89];
var GnegInit                = [-3.16, -3.16, -3.16, -3.16, -3.16, -3.16, -3.16, -3.16, -3.16, -3.16];
var last_e_tabGposInit      = [-0.85, -0.85, -0.85, -0.85, -0.85, -0.85, -0.85, -0.85, -0.85, -0.85];
var last_e_tabGnegInit      = [0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15];

# Values for aoa leading the pitch aroud 150 kts
#var aoaposInit              = [9,9,9,9,9,9,9,9,9,9];
var aoaposInit              = [18,18,18];#Test
var aoanegInit              = [-4.92,-4.92,-4.92];
#var last_e_tabaoaposInit    = [-0.86,-0.86,-0.86,-0.86,-0.86,-0.86,-0.86,-0.86,-0.86,-0.86];
var last_e_tabaoaposInit    = [-0.52,-0.52,-0.52];
var last_e_tabaoanegInit    =  [0.24,0.24,0.24];

# Values around 300 kts for Gload leading the pitch
var Gpos                = GposInit;
var Gneg                = GnegInit;
var last_e_tabGpos      = last_e_tabGposInit;
var last_e_tabGneg      = last_e_tabGnegInit;

# Values for aoa leading the pitch aroud 150 kts
var aoapos              = aoaposInit;
var aoaneg              = aoanegInit;
var last_e_tabaoapos    = last_e_tabaoaposInit;
var last_e_tabaoaneg    = last_e_tabaoanegInit;


# Value for the roll
var last_roll_rate      = [171.41, 171.41, 171.41, 171.41, 171.41, 171.41, 171.41, 171.41,171.41];
var last_a_tab_Average  = [0.518, 0.518, 0.518, 0.518, 0.518, 0.518, 0.518, 0.518, 0.518];

# Orientation and velocities
var RollRate         = props.globals.getNode("orientation/roll-rate-degps");
var PitchRate        = props.globals.getNode("orientation/pitch-rate-degps", 1);
var YawRate          = props.globals.getNode("orientation/yaw-rate-degps", 1);
var AirSpeed         = props.globals.getNode("velocities/airspeed-kt");
var GroundSpeed      = props.globals.getNode("velocities/groundspeed-kt");
var mach             = props.globals.getNode("velocities/mach");
var slideDeg         = props.globals.getNode("orientation/side-slip-deg");
var OrientationRoll  = props.globals.getNode("orientation/roll-deg");
var OrientationPitch = props.globals.getNode("orientation/pitch-deg");
var AngleOfAttack    = props.globals.getNode("orientation/alpha-deg");

var alpha            = 0;
var gload            = getprop("/accelerations/pilot-g");
var myMach           = mach.getValue();

# SAS and Autopilot Controls
var SasPitchOn   = props.globals.getNode("controls/SAS/pitch");
var SasRollOn    = props.globals.getNode("controls/SAS/roll");
var SasYawOn     = props.globals.getNode("controls/SAS/yaw");
var AutoTrim     = props.globals.getNode("controls/SAS/autotrim");
var cat          = props.globals.getNode("controls/SAS/cat");
var activated    = props.globals.getNode("controls/SAS/activated");



#var DeadZPitch   = props.globals.getNode("controls/SAS/dead-zone-pitch");
#var DeadZRoll    = props.globals.getNode("controls/SAS/dead-zone-roll");

# Autopilot Locks
var ap_alt_lock  = props.globals.getNode("autopilot/locks/altitude");
var ap_hdg_lock  = props.globals.getNode("autopilot/locks/heading");

# Inputs
var RawElev      = props.globals.getNode("controls/flight/elevator");
var RawAileron   = props.globals.getNode("controls/flight/aileron");
var RawRudder    = props.globals.getNode("controls/flight/rudder");
var RawThrottle  = props.globals.getNode("/controls/engines/engine[0]/throttle");
var AileronTrim  = props.globals.getNode("controls/flight/aileron-trim", 1);
var ElevatorTrim = props.globals.getNode("controls/flight/elevator-trim", 1);
var RudderTrim   = props.globals.getNode("controls/flight/rudder-trim", 1);
var Dlc          = props.globals.getNode("controls/flight/DLC", 1);
var Flaps        = props.globals.getNode("surface-positions/aux-flap-pos-norm", 1);
var Brakes       = props.globals.getNode("surface-positions/spoiler-pos-norm", 1);
var raw_e        = RawElev.getValue();
var wow          = getprop ("/gear/gear/wow");
var upsidedown   = abs(OrientationRoll.getValue()) < 90 ;
var Gfactor      = 1;
var AoaFactor    = 1;

# Outputs
var SasRoll      = props.globals.getNode("controls/flight/SAS-roll", 1);
var SasPitch     = props.globals.getNode("controls/flight/SAS-pitch", 1);
var SasYaw       = props.globals.getNode("controls/flight/SAS-yaw", 1);
var SasGear      = props.globals.getNode("controls/flight/SAS-gear", 1);

var airspeed       = 0;
var airspeed_sqr   = 0;
var last_e         = 0;
var last_p_var_err = 0;
var p_input        = 0;
var last_p_bias    = 0;
var last_a         = 0;
var last_r         = 0;
var w_sweep        = 0;
#var e_trim         = 0;
var etrim_indice   =0;
var atrim_indice   =0;
var steering       = 0;
var dt_mva_vec     = [0, 0, 0, 0, 0, 0, 0];
var dt_Roll_vec    = [0, 0, 0, 0, 0, 0, 0];

# Array for Gload, speed, input and raw_e
#var G_array = [[0][0][0],[0][0][0]];


# SAS initialisation
var init_SAS = func() {
    #var SAS_rudder   = nil;
    #var SAS_elevator = nil;
    #var SAS_aileron  = nil;
}

# SAS double running avoidance
var Update_SAS = func() {
    if(SAS_Loop_running == 0)
    {
        SAS_Loop_running = 1;
        call(computeSAS,[]);
    }
}



var Intake_pelles = func(){
        # Little try to make the "trappes" intake move : They move by depression
        # Formula is : q = (rho.V²)/2
        # with  : 
        #  - rho in kg/m³
        #  - V in m/s
        #  - q in pascal
        var densitykgm3 = getprop("environment/density-slugft3")*515.378818393;
        var speedms = airspeed * KT2MPS;
        var q =  (densitykgm3*speedms*speedms)/2;
        
        #print("Pression Dynamique: q:"~q~ " Pa = rho:"~densitykgm3~"kg/m³ *(V:"~speedms~"m/s) ² /2");
        
        var myRpm = getprop("engines/engine/rpm");
        var myKgCoeff = myRpm/9000*96>96?0:96-(myRpm/9000*96)+40; #This is to simulate a bias of the débit value when rpm are low
        var DebitModified = (1/2*densitykgm3 * math.sin((90-alpha)*D2R)* math.sin((90-alpha)*D2R) * 3.14*0.796*0.796 *speedms)+myKgCoeff;
        
        #print("Débit Massique : qm = " ~1/2*densitykgm3 * math.sin((90-alpha)*D2R)* math.sin((90-alpha)*D2R) * 3.14*0.796*0.796 *speedms ~ "kg/s = rho:"~densitykgm3~"kg/m³ *Section:"~math.sin((90-alpha)*D2R)* math.sin((90-alpha)*D2R)*3.14*0.796*0.796~" m²* V:"~speedms~"m.s-¹*2/3 (to take off the cones)");
        
        setprop("engines/engine[0]/massic-debit_div2",DebitModified);
        
        #For pelles/ecoppes movement
        myalt = getprop("/position/altitude-ft");
        if(myalt > 25000 and myMach > 0.6 and myMach < 1.2 and airspeed < 400 and alpha > 12)
        {
            interpolate("engines/engine[0]/pelle", alpha, 0.5);
        }
        else
        {
            interpolate("engines/engine[0]/pelle", 0, 0.5);
        }
}






# Stability Augmentation System
var computeSAS = func() {
    # Mirage 2000
    # I)Elevator :
    #   1)Few sensibility near stick neutral position <-traduce by square yaw
    #   2)Trim + elevator clipped -> at less than 80 % of stick :
    # (trim + elevator)have to be < 80%
    #   3)at speed > 300kts : the stick position is equals to a Gload. So the
    #      stick drive the G.
    #   4)at low speed :(bellow 160 kt I suppose)the important is to
    #      stabilize the aoa
    #
    # II)Roll
    #   1)Few sensibility near stick neutral position
    #   2)High Roll : Clipped to respect roll speed limitation
    #   3)Ponderation : elevator order & Gload to decrease roll speed at high
    #      aoa and/or high Gload
    #   4)To the stick order is added trim order.the stabilisation is realized
    #      in terme of angular speed roll
    #
    # III)Yaw axis
    #   1)limitation of yaw depend of the elevator
    #   2)This limitation is mesured by transveral acceleration
    #   3)Anti skid function : when "no yaw", and order is gived to the rudder
    #      to keep transversal acceleratioon to 0
    #   4)When gears are out, yaw' order authority is increased in order to
    #      cover crosswind landing
    #
    # IV)Slat
    #   1)Slats depend of the incidences
    #   2)start at aoa = 4 and are fully out at aoa = 10
    #   3)slat get in when gear are out(In emergency taht implid very low
    #      speed landing, they can get out)
    #   4)open speed is : 2, 6 sec from 0 to fullly open.
    #   5)if oil presure < 180 bars this time is 5.2 sec
    #
    # V)Gear
    # Special flightgear :
    #   1)depend of the yaw order
    #   2)The turn has to be very high for very low speed and have to decrease
    #      a lot while take off acceeleration
    var roll        = RollRate.getValue();
    var roll_rad    = roll * 0.017453293;
    airspeed        = AirSpeed.getValue();
    airspeed_sqr    = airspeed * airspeed;
    raw_e           = RawElev.getValue();
    var raw_a       = RawAileron.getValue();
    var e_trim      = ElevatorTrim.getValue();
    var a_trim      = AileronTrim.getValue();
    var r_trim      = RudderTrim.getValue();
    alpha           = AngleOfAttack.getValue();
    gload           = getprop("/accelerations/pilot-g");
    var raw_r       = RawRudder.getValue();
    var pitch_r     = PitchRate.getValue();
    myMach          = mach.getValue();
    var myBrakes    = Brakes.getValue();
    var refuelling  = getprop("/systems/refuel/contact");
    var gear        = getprop("/gear/gear/position-norm");
    wow             = getprop ("/gear/gear/wow");
    upsidedown      = abs(OrientationRoll.getValue()) < 120 ;
    var myCat       = cat.getValue();
    
 
        
 
        
      Intake_pelles();
    
      var gear_input = raw_r;
      if(GroundSpeed.getValue() > gear_lo_speed)
      {
          gear_input *= gear_lo_speed_sqr / (GroundSpeed.getValue() * GroundSpeed.getValue());
      }
      SasGear.setValue(gear_input);
        
    
    # GAZ
    # Should be on the engine part !
    # finally nope : The engine have a computer driven throttle
    # Could be changed here without touching yasim props
    #Throttle
    var myThrottle = RawThrottle.getValue();
    
    var reheatlimit = 95;
    myThrottle = myThrottle > reheatlimit / 100 ? 1 : myThrottle / (reheatlimit / 100);
    var reheat = myThrottle > reheatlimit / 100 and getprop("/controls/engines/engine[0]/n1") > 96 ? ((myThrottle - (reheatlimit / 100)) * 100) / 0.05 : 0;
    
    #var reheat = (getprop("/controls/engines/engine[0]/n1") >= reheatlimit) ? (getprop("/controls/engines/engine[0]/n1") - reheatlimit) / (100 - reheatlimit) : 0;
    setprop("/controls/engines/engine[0]/reheat", reheat);
    setprop("/controls/engines/engine[0]/SAS_throttle",myThrottle);

    # @TODO : Stall warning ! should be in instruments
    var stallwarning = "0";
    if(getprop("/gear/gear[2]/wow") == 0)
    {
        # STALL ALERT !
        if(alpha >= 29)
        {
            stallwarning = "2";
        }
        elsif(airspeed < 100)
        {
            stallwarning = "2";
        }
        # STALL WARNING
        elsif(alpha >= 20)
        {
            stallwarning = "1";
        }
        elsif(airspeed < 130)
        {
            stallwarning = "1";
        }
    }
    setprop("/sim/alarms/stall-warning", stallwarning);
    SAS_Loop_running = 0;
}
