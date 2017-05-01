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
var p_max               = 0.2;
var p_min               = -0.2;
var max_e               = 1;
var min_e               = 0.55;
var maxG                = 9; # mirage 2000 max everyday 8.5G; overload 11G and 12G will damage the aircraft 9G is for airshow. 5.5 for Heavy loads
var minG                = -4; # -3.5
var maxAoa              = 26;
var minAoa              = -15;
var maxRoll             = 290; # in degre/sec but when heavy loaded : 150 
var last_e_tab          = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
var last_a_tab          = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
var tabG                = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];

var maxRollCat          = [290, 150];
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
var aoaposInit              = [18,18,18,18,18,18,18,18,18,18];#Test
var aoanegInit              = [-4.92,-4.92,-4.92,-4.92,-4.92,-4.92,-4.92,-4.92,-4.92,-4.92];
#var last_e_tabaoaposInit    = [-0.86,-0.86,-0.86,-0.86,-0.86,-0.86,-0.86,-0.86,-0.86,-0.86];
var last_e_tabaoaposInit    = [-0.52,-0.52,-0.52,-0.52,-0.52,-0.52,-0.52,-0.52,-0.52,-0.52];
var last_e_tabaoanegInit    =  [0.24,0.24,0.24,0.24,0.24,0.24,0.24,0.24,0.24,0.24];

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

# SAS and Autopilot Controls
var SasPitchOn   = props.globals.getNode("controls/SAS/pitch");
var SasRollOn    = props.globals.getNode("controls/SAS/roll");
var SasYawOn     = props.globals.getNode("controls/SAS/yaw");
var AutoTrim     = props.globals.getNode("controls/SAS/autotrim");
var cat          = props.globals.getNode("controls/SAS/cat");


var DeadZPitch   = props.globals.getNode("controls/SAS/dead-zone-pitch");
var DeadZRoll    = props.globals.getNode("controls/SAS/dead-zone-roll");

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
var Dlc          = props.globals.getNode("controls/flight/DLC", 1);
var Flaps        = props.globals.getNode("surface-positions/aux-flap-pos-norm", 1);
var Brakes       = props.globals.getNode("surface-positions/spoiler-pos-norm", 1);

#var WSweep       = props.globals.getNode("surface-positions/wing-pos-norm", 1);

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
var steering       = 0;
var dt_mva_vec     = [0, 0, 0, 0, 0, 0, 0];
var dt_Roll_vec    = [0, 0, 0, 0, 0, 0, 0];

# wlevator Trim
if(ElevatorTrim.getValue() != nil)
{
    e_trim = ElevatorTrim.getValue();
}

var trimUp = func() {
    e_trim += (airspeed < 120.0) ? t_increment : t_increment * 14400 / airspeed_sqr;
    if(e_trim > 1)
    {
        e_trim = 1;
    }
    ElevatorTrim.setValue(e_trim);
}

var trimDown = func() {
    e_trim -= (airspeed < 120.0) ? t_increment : t_increment * 14400 / airspeed_sqr;
    if(e_trim < -1)
    {
        e_trim = -1;
    }
    ElevatorTrim.setValue(e_trim);
}

# SAS initialisation
var init_SAS = func() {
    var SAS_rudder   = nil;
    var SAS_elevator = nil;
    var SAS_aileron  = nil;
}

# SAS double running avoidance
var Update_SAS = func() {
    if(SAS_Loop_running == 0)
    {
        SAS_Loop_running = 1;
        call(computeSAS,[]);
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
    var raw_e       = RawElev.getValue();
    var raw_a       = RawAileron.getValue();
    var e_trim      = ElevatorTrim.getValue();
    var a_trim      = AileronTrim.getValue();
    var alpha       = getprop("/orientation/alpha-deg");
    var  gload      = getprop("/accelerations/pilot-g");
    var raw_r       = RawRudder.getValue();
    var pitch_r     = PitchRate.getValue();
    var myMach      = mach.getValue();
    var myBrakes    = Brakes.getValue();
    var refuelling  = getprop("/systems/refuel/contact");
    var gear        = getprop("/gear/gear/position-norm");
    var wow         = getprop ("/gear/gear/wow");
    var myCat       = cat.getValue();
    
    maxG = MaxGCat[myCat];
    maxRoll = maxRollCat[myCat];
    
    if(getprop("/autopilot/locks/AP-status") == "AP1")
    {
        SasPitch.setValue(raw_e);
        SasRoll.setValue(raw_a);
        SasYaw.setValue(raw_r);
        SasGear.setValue(raw_r);
        # electrics commands are feeded by the hydraulique circuit #1
    }
    else
    {
        var oilpress = getprop("/systems/hydraulical/circuit1_press");
        if(oilpress < 190)
        {
            raw_e = 1;
            raw_a = 0;
            raw_r = 0;
            # airbrakes should here "Not work" coz not enough pressure
        }
        if(oilpress > 190 and oilpress < 200)
        {
            raw_e = 0;
            # airbrakes should here "Not work" coz not enough pressure
        }
        if(oilpress > 200 and oilpress < 260)
        {
            last_e_tab = [last_e_tab[0], last_e_tab[0], last_e_tab[0], last_e_tab[0], last_e_tab[0], last_e_tab[0], last_e_tab[0], last_e_tab[0], last_e_tab[0], last_e_tab[0], last_e_tab[0]];
            last_a_tab = [last_a_tab[0], last_a_tab[0], last_a_tab[0], last_a_tab[0], last_a_tab[0], last_a_tab[0], last_a_tab[0], last_a_tab[0], last_a_tab[0], last_a_tab[0], last_a_tab[0]];
            # airbrakes should here "Not work" coz not enough pressure
        }
        if(oilpress > 270)
        {
            last_e_tab = size(last_e_tab) != 5?[last_e_tab[0],last_e_tab[0],last_e_tab[0],last_e_tab[0],last_e_tab[0]]:last_e_tab;
            last_a_tab = size(last_a_tab) != 2?[last_a_tab[0],last_a_tab[0]]:last_a_tab;
            # airbrakes should here "Not work" coz not enough pressure
        }
        
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
        
        # Pitch Channel
        var pitch_rate = PitchRate.getValue();
        var yaw_rate   = YawRate.getValue();
        var p_bias     = 0;
        var smooth_e   = raw_e;
        var dlc_trim   = 0;
        var gain       = 0;
        
        var p_var_err = - ((pitch_rate * math.cos(roll_rad)) + (yaw_rate * math.sin(roll_rad)));
        p_bias = (p_var_err - last_p_var_err);
        p_bias = last_p_bias + p_kp * (p_var_err - last_p_var_err);
        last_p_var_err = p_var_err;
        last_p_bias = p_bias;
        if(p_bias > p_max)
        {
            p_bias = p_max
        }
        elsif(p_bias < p_min)
        {
            p_bias = p_min
        }
        #print("p_bias="~ p_bias ~" p_var_err:" ~ p_var_err ~ "- last_p_var_err:" ~ last_p_var_err  ~ "="~ (p_var_err - last_p_var_err));
        
        ####################
        #print("airspeed:" ~ airspeed ~ " raw_e:"~raw_e);

        # Filtering neutral position
        var p_neutral = 0.05;
        raw_e = (abs(raw_e) < p_neutral) ? 0 : (raw_e * (1 - p_neutral) / 1) + p_neutral * abs(raw_e) / raw_e;
        
        # Input p_input
        #p_input = raw_e != 0 ? raw_e * raw_e * abs(raw_e) / raw_e : 0;
        p_input = raw_e;

        # Take only a third of the order if refuelling
        #p_input = (p_input != 0 and refuelling and abs(p_input) > 0.30) ? 0.30 * abs(p_input) / p_input : p_input;

        var Gfactor = 1;
        var AoaFactor = 1;
        # Gpos Gneg last_e_tabGpos last_e_tabGneg
        # G factor and Aoa Factor will be calculated in every speed
        #we need here to add a condition when upside down
        
        var upsidedown = abs(OrientationRoll.getValue()) < 90 ;
        #if(upsidedown){print("Upside down");}
        
            if(raw_e < 0)
            {
                # Tab G pos and last_e_tabGpos ================================================================================================================================================
                if(last_e < 0.1
                    and gload > 0
                    and (abs(last_e) > 0.4
                        or abs(p_input) == 1
                        or gload > maxG * 0.2
                    )
                    and abs(last_e_tab[0] - last_e_tab[1]) > 0
                    and airspeed > 10
                    and myBrakes == 0
                    and wow == 0
                    and upsidedown)
                {
                    shiftTab(Gpos, gload);
                    shiftTab(last_e_tabGpos, last_e);
                    
                    Gpos[0] = averageTab(Gpos);
                    last_e_tabGpos[0] = averageTab(last_e_tabGpos);
                }
                
                var Mygload = Gpos[0];
                last_e = last_e_tabGpos[0];

                # Calculate the G factor
                Gfactor = abs(last_e / Mygload);
                
                # Tab aoa pos and Tab last_e_tabaoapos =======================================================================================================================================
                if(last_e < 0.1
                    and alpha > 0
                    and (abs(last_e) > 0.9
                        or abs(p_input) == 1
                        or alpha > maxAoa * 0.5
                    )
                    and abs(last_e_tab[0] - last_e_tab[1]) > 0
                    and airspeed > 10
                    and myBrakes == 0
                    and wow == 0
                    and upsidedown)
                {
                    shiftTab(aoapos, alpha);
                    shiftTab(last_e_tabaoapos, last_e);
                    
                    aoapos[0] = averageTab(aoapos);
                    last_e_tabaoapos[0] = averageTab(last_e_tabaoapos);
                }
                
                var Myalpha = aoapos[0];
                last_e = last_e_tabaoapos[0];
                
                # Calculate the AoaFactor
                AoaFactor = abs(last_e / Myalpha);
            }
            else
            {
                #print("Descent:");
                # Tab Gneg and last_e_tabGneg ================================================================================================================================================
                if(last_e > 0.1
                    and gload < 0
                    and (abs(last_e) > 0.4
                        or abs(p_input) == 1
                        or gload < minG * 0.2
                    )
                    and abs(last_e_tab[0] - last_e_tab[1]) > 0
                    and airspeed > 10
                    and myBrakes == 0
                    and wow == 0
                    and upsidedown) 
                {
                    shiftTab(Gneg, gload);
                    shiftTab(last_e_tabGneg, last_e);
                    
                    Gneg[0] = averageTab(Gneg);
                    last_e_tabGneg[0] = averageTab(last_e_tabGneg);
                }
                
                var Mygload = Gneg[0];
                last_e = last_e_tabGneg[0];

                #   Calculate the G factor
                Gfactor = abs(last_e / Mygload);

                 # Tab aoaneg and last_e_tabaoaneg ================================================================================================================================================
                if(last_e > 0.1
                    and alpha < 0
                    and (abs(last_e) > 0.9
                        or abs(p_input) == 1
                        or alpha < minAoa * 0.5
                    )
                    and abs(last_e_tab[0] - last_e_tab[1]) > 0
                    and airspeed > 10
                    and myBrakes == 0
                    and wow == 0
                    and upsidedown)
                {
                    shiftTab(aoaneg, alpha);
                    shiftTab(last_e_tabaoaneg, last_e);
                    
                    aoaneg[0] = averageTab(aoaneg);
                    last_e_tabaoaneg[0] = averageTab(last_e_tabaoaneg);
                }
                
                var Myalpha = aoaneg[0];  
                last_e = last_e_tabaoaneg[0];

                # Calculate the AoaFactor
                AoaFactor = abs(last_e / Myalpha);
            }

        #This is to calculate a kind of border between aoa driving and G driving
        var myCoeef = (airspeed - 280) / 40 > 1 ? 1 : (airspeed - 280) / 40 < 0 ? 0 : (airspeed - 280) / 40;
        
        #print("Gfactor*p_input : " ~ Gfactor*p_input);
        #print("AoaFactor*p_input : " ~ AoaFactor*p_input);
        #if(Mygload>maxG){print("Over G");}
        myCoeef = Mygload > maxG ? 1 : myCoeef;
        
        # This calculation is done and produce a "Gfactor" which is a part of the precedent Gfactor claculation and aoa calculation
        # If over G, then Gfactor take it over
        Gfactor = myCoeef * Gfactor + (1 - myCoeef) * AoaFactor;
        
        #print("My test :"~ myCoeef);
        # Avoid strange thing that could lead to an oscillation
        Gfactor = (Gfactor < 0.002) ? 0.002 : Gfactor;
        Gfactor = (airspeed < 10 and wow) ? 1 : Gfactor;

        # If airspeed > 300 Mach the stick drive the G  at airspeed < 300 the stick drive the aoa
        if(raw_e < 0)
        {
            # Prevent Stalling when landing
            var myMaxAoa = airspeed < 130 and gear == 1 ? maxAoa / 2 : maxAoa;
            
            # New new method :
            var IdealG =  myCoeef * abs(p_input * maxG) + (1 - myCoeef) * abs(p_input * myMaxAoa);
            p_input = -IdealG * Gfactor;
            if(getprop("/controls/bugs/command-bug"))
            {
                print("p_input:" ~ p_input ~ " gload:" ~ gload  ~ " raw_e:" ~ raw_e ~" maxG:" ~ maxG ~" myMach:"~myMach ~ " IdealG:" ~raw_e * maxG ~ " Ideal Aoa" ~raw_e * maxAoa~" Gfactor:"~ Gfactor);
            }
        }
        else
        {
            # New new method :
            var IdealG =  myCoeef * abs(p_input * minG) + (1-myCoeef) * abs(p_input * (upsidedown?minAoa:minAoa*2));
            p_input = IdealG * Gfactor;
            if(getprop("/controls/bugs/command-bug"))
            {
                print("p_input:" ~ p_input ~ " gload:" ~ gload  ~ " raw_e:" ~ raw_e ~" minG:" ~ minG ~" myMach:"~myMach ~ " IdealG:" ~raw_e * minG ~" Gfactor:"~ Gfactor);
            }
        }
        
        # Remove Calculation anomalies
        p_biasTemp = airspeed > 340                     ? p_bias * Gfactor  : p_bias;
        p_input += (airspeed < 340 or abs(raw_e) < 0.5) and upsidedown   ? p_biasTemp        : 0;
        p_input = (p_input <= 0 and raw_e >= 0)         ?  0                : p_input;
        p_input = (p_input >= 0 and raw_e <= 0)         ?  0                : p_input;
        p_input = (p_input >  1)                        ?  1                : p_input;
        p_input = (p_input < -1)                        ? -1                : p_input;
        #print("p_input:" ~ p_input);
        
        
        #p_input = p_input != 0 ? last_e + (last_e - p_input) * e_smooth_factor : p_input;

        # Average : only for the latency
        if(myBrakes == 0)
        {
            shiftTab(last_e_tab, p_input);
            last_e_tab[0] = averageTab(last_e_tab);
            p_input = last_e_tab[0];
        }

        #print("Moyenne p_input:" ~ p_input ~ " Futur G  = p_input * gload / last_e :" ~ p_input * gload / last_e);
        #if p_input<0.001
        
        # Reinitialisation of the different matrix if we detect something strange
        p_input = abs(p_input) < 0.005 ? 0 : p_input;
        if(abs(p_input) < 0.005 and abs(raw_e) > 0.99)
        {
            init_matrix();
            # here is to limit to 0
            #p_input = (raw_e == 0 and p_input != 0) ? 0 : p_input * p_input / p_input;
        }
        
        last_e = p_input;
        SasPitch.setValue(p_input);
        # Autotrim
        # Only if abs(p_input) < 0.01
        # Only is SAS is working
        # Only if wow == 0
        # Only if not inverted
        if(AutoTrim.getValue())
        {
            if(abs(raw_e) < 0.01
                and wow == 0
                and abs(OrientationPitch.getValue()) < 45
                and abs(OrientationRoll.getValue()) < 45
                and myBrakes == 0
                and gear == 0)
            {
                var indice = abs(pitch_rate) > 2 ? 0.05 : 0.001;
                if(pitch_rate > 0)
                {
                    interpolate("controls/flight/elevator-trim", e_trim + indice, 0.2);
                    #ElevatorTrim.setValue(e_trim+indice);
                }
                else
                {
                    interpolate("controls/flight/elevator-trim", e_trim - indice, 0.2);
                    #ElevatorTrim.setValue(e_trim-indice);
                }
            }
            if(abs(raw_e) > 0.5 and airspeed > 150 and gear == 1)
            {
                if(abs(e_trim)>0.01)
                {
                    interpolate("controls/flight/elevator-trim", 0, 0.2);
                }
                else
                {
                    interpolate("controls/flight/elevator-trim",0 , 0.2);
                    #ElevatorTrim.setValue(0);
                }
            }
        }

        #####################

        # Roll Channel
        var sas_roll = 0;
        var myMaxRoll = maxRoll;

        # Filtering neutral position
        var r_neutral = 0.1;
        raw_a = abs(raw_a) < r_neutral ? 0 : (raw_a * (1 - r_neutral) / 1) + r_neutral * abs(raw_a) / raw_a;
        sas_roll = raw_a;

        # input sas_roll an square it, while keeping its sign # Or Cube
        #sas_roll = (raw_a != 0)?(raw_a * raw_a) * abs(raw_a)/raw_a:0;
        #sas_roll = raw_a * raw_a * raw_a;
        
        myMaxRoll = abs(raw_a) < 0.95 ? maxRoll / 2 : myMaxRoll;
        myMaxRoll = abs(raw_a) < 0.80 ? maxRoll / 3 : myMaxRoll;
        myMaxRoll = abs(raw_a) < 0.50 ? maxRoll / 6 : myMaxRoll;

        # decrease sas_roll with pitch
        sas_roll = (sas_roll != 0) ? (abs(sas_roll) - abs(raw_e * 0.60)) * abs(sas_roll) / sas_roll : 0;

        # decrease sas_roll with low speed and high aoa
        if(alpha > 10 and myMach < 0.26)
        {
            myMaxRoll = myMaxRoll / 2;
        }
        # lowering the roll at high alt
        if(myalt > 45000)
        {
            myMaxRoll = myMaxRoll / 2;
        }

        # decrease sas_roll with airbrakes
        sas_roll = (sas_roll != 0) ? sas_roll * (1 - (myBrakes * 0.90)) : 0;

        # decrease sas_roll with gear
        sas_roll = sas_roll * (1 - (gear * 0.50));

        # Take only a third of the order if refuelling
        sas_roll = (sas_roll != 0 and refuelling and abs(sas_roll) > 0.30) ? 0.30 * abs(sas_roll) / sas_roll : sas_roll;

        #print("sas_roll before roll filter and after p_input filter:" ~ sas_roll);

        # The goal is to add attenuation due to speed
        if(myMach > 1.4)
        {
            sas_roll *= 1.4 / (myMach * myMach);
        }
        #######################
        # Roll factor Calculation
        # Tab  last_roll_rate
        #print("Roll Average");
        #print("abs(last_a_tab[0] - last_a_tab[1]) = "~ abs(last_a_tab[0] - last_a_tab[1]));
        #if(abs(roll) > 1 and abs(last_a) > 0.2 and abs(last_a_tab[0] - last_a_tab[1]) > 0 and airspeed > 10 and myBrakes == 0)
        if(abs(roll) >1 and airspeed > 10 and myBrakes == 0 and wow == 0)
        {
            shiftTab(last_roll_rate, abs(roll));
        }
        last_roll_rate[0] = averageTab(last_roll_rate);
        var Myroll = last_roll_rate[0];

        # Tab last_a_tab
        #print("last_a_tab Average");
        #if(abs(roll)>1 and abs(last_a)>0.2 and abs(last_a_tab[0]-last_a_tab[1])>0 and airspeed>10 and myBrakes==0)
        if(abs(roll) > 1 and airspeed > 10 and myBrakes == 0 and wow == 0)
        {
            #print("Test Roll");
            shiftTab(last_a_tab_Average, abs(last_a));
        }
        last_a_tab_Average[0] = averageTab(last_a_tab_Average);
        last_a = last_a_tab_Average[0];

        #print("last_a/roll="~last_a~"/"~roll~"="~last_a / roll);
        # Calculate the G factor
        var Rollfactor = abs(last_a / Myroll);

        # Avoid strange thing that could lead to an oscillation
        Rollfactor = (Rollfactor < 0.0002) ? 0.0002 : Rollfactor;
        Rollfactor = (airspeed < 10 and wow) ? 1 : Rollfactor;

        # New new method :
        var IdealRoll = sas_roll * myMaxRoll;
        sas_roll = IdealRoll * Rollfactor;
        #print("sas_roll:" ~ sas_roll ~ " roll:" ~ roll ~" raw_a:" ~ raw_a ~" myMaxRoll:" ~ myMaxRoll ~ " IdealRoll = "~ IdealRoll ~" RollFactor:"~Rollfactor);

        # sas_roll = sas_roll!=0?(abs(sas_roll)-abs(p_bias)*Rollfactor)*abs(sas_roll)/sas_roll:0;
        sas_roll = (sas_roll <= 0 and raw_a >= 0) ?  0 : sas_roll;
        sas_roll = (sas_roll >= 0 and raw_a <= 0) ?  0 : sas_roll;
        sas_roll = (sas_roll > 1 )                ?  1 : sas_roll;
        sas_roll = (sas_roll < -1)                ? -1 : sas_roll;

        # Average : only for the latency
        shiftTab(last_a_tab, sas_roll);
        last_a_tab[0] = averageTab(last_a_tab);
        sas_roll = last_a_tab[0];
        
        #if sas_roll < 0.001
        sas_roll = abs(sas_roll) < 0.001 ? 0 : sas_roll;
        
        last_a = sas_roll;
        SasRoll.setValue(sas_roll);
        
        # Autotrim
        # Only if abs(raw_a) < 0.01
        # Only is SAS is working
        # Only if wow == 0
        # Only if not verticle
        if(AutoTrim.getValue())
        {
            if(abs(raw_a)<0.01 and wow==0 and abs(OrientationPitch.getValue())<45 and abs(OrientationRoll.getValue())<45)
            {
                var indice = abs(roll) > 1 ? 0.005 : 0.001;
                if(roll < 0)
                {
                    AileronTrim.setValue(a_trim + indice);
                }
                else
                {
                    AileronTrim.setValue(a_trim - indice);
                }
            }
            if(abs(raw_a) > 0.5)
            {
                AileronTrim.setValue(0);
            }
        }

        #####################
        # Yaw Channel
        var smooth_r = raw_r;
        if(raw_r != 0)
        {
            smooth_r = last_r + ((raw_r - last_r) * r_smooth_factor);
            last_r = smooth_r;
        }
        SasYaw.setValue(smooth_r);

        # Gear Channel
        # Appli Quadratic law from low speed
        # Actually, this is working in the good way with gear.
        # We should/could add an antiskid effect to prevent little slidding
        var gear_input = raw_r;
        if(GroundSpeed.getValue() > gear_lo_speed)
        {
            gear_input *= gear_lo_speed_sqr / (GroundSpeed.getValue() * GroundSpeed.getValue());
        }
        SasGear.setValue(gear_input);
    }
    
    # To calculate the best slats position
    
    #print(getprop("/controls/gear/gear-down") );
    if(getprop("/controls/gear/gear-down") == 0)
    {
        var slats = 0;
        #print("alpha:"~alpha);
        if(alpha >= 2)
        {
            var gload = getprop("/accelerations/pilot-g");
            #print("gload:"~gload);
            if(gload < 9)
            {
                var slats = (alpha - 3)/ 6;
            }
        }
        setprop("/controls/flight/flaps", slats);
    }

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

var averageTab = func(myTab) {
    var average = 0;
    for(var i = 0; i < size(myTab); i += 1)
    {
        average += myTab[i];
        #print("myTab["~ i~"] = "~myTab[i]~" And size() = "~size(myTab));
    }
    average *= 1/size(myTab);
    #print("Average : " ~average);
    return average;
}

var shiftTab = func(myTab, mynewvalue){
    var myTabElement = mynewvalue;
    for(var i = 0; i < size(myTab); i += 1)
    {
        var tempo = myTab[i];
        #print("Tempo:"~tempo ~ "myTabElement:"~myTabElement ~"myTab["~ i~"]="~myTab[i] );
        myTab[i] = myTabElement;
        myTabElement = tempo;
        #print("myTab["~ i~"] = "~myTab[i]~" And size() = "~size(myTab));
    }
    return myTab;
}

var averageTabFirstSign = func(myTab){
    var average = 0;
    var mySign  = (myTab[0]) < 0 ? -1 : 1;
    myCount     = 0;

    for(var i = 0; i < size(myTab); i += 1)
    {
        # If myTab[i]< 0 and myTab[0]<0 then do the average. same with > 0
        average += myTab[i] * mySign > 0 ? myTab[i] : 0;
        myCount += myTab[i] * mySign > 0 ? 1 : 0;
        #print("myTab["~ i~"] = "~myTab[i]~" And size() = "~size(myTab));
    }
    average *= 1/myCount;
    #print("Average first sign: " ~average);
    return average;
}

var averageABS = func(myTab){
    var average = 0;
    for(var i = 0; i < size(myTab); i += 1)
    {
        average += abs(myTab[i]);
        #print("myTab["~ i~"] = "~myTab[i]~" And size() = "~size(myTab));
    }
    average *= 1 / size(myTab);
    #print("Average : " ~average);
    return average;
}

var init_matrix = func(){
    # Values around 300 kts for Gload leading the pitch
    Gpos                = GposInit;
    Gneg                = GnegInit;
    last_e_tabGpos      = last_e_tabGposInit;
    last_e_tabGneg      = last_e_tabGnegInit;

    # Values for aoa leading the pitch aroud 150 kts
    aoapos              = aoaposInit;
    aoaneg              = aoanegInit;
    last_e_tabaoapos    = last_e_tabaoaposInit;
    last_e_tabaoaneg    = last_e_tabaoanegInit;
    print("Fly By Wire Matrix has been INIT");
}
