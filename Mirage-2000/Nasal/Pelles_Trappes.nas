print("*** LOADING SAS.nas ... ***");
################################################################################
#
#                   m2005-5's Pelles and trappes calculation
#
################################################################################


var AirSpeed         = props.globals.getNode("velocities/airspeed-kt");
var mach             = props.globals.getNode("velocities/mach");
var AngleOfAttack    = props.globals.getNode("orientation/alpha-deg");
var density      = props.globals.getNode("environment/density-slugft3", 1);
var rpm          = props.globals.getNode("engines/engine/rpm",1);
var wow          = props.globals.getNode("/gear/gear/wow",1);


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
        var densitykgm3 = density.getValue()*515.378818393;
        var speedms = AirSpeed.getValue() * KT2MPS;
        var q =  (densitykgm3*speedms*speedms)/2;
        
        #print("Pression Dynamique: q:"~q~ " Pa = rho:"~densitykgm3~"kg/m³ *(V:"~speedms~"m/s) ² /2");
        
        #var myRpm = getprop("engines/engine/rpm");
        var myKgCoeff = rpm.getValue()/9000*96>96?0:96-(rpm.getValue()/9000*96)+40; #This is to simulate a bias of the débit value when rpm are low
        var DebitModified = (1/2*densitykgm3 * math.sin((90-AngleOfAttack.getValue())*D2R)* math.sin((90-AngleOfAttack.getValue())*D2R) * 3.14*0.796*0.796 *speedms)+myKgCoeff;
        
        #print("Débit Massique : qm = " ~1/2*densitykgm3 * math.sin((90-alpha)*D2R)* math.sin((90-alpha)*D2R) * 3.14*0.796*0.796 *speedms ~ "kg/s = rho:"~densitykgm3~"kg/m³ *Section:"~math.sin((90-alpha)*D2R)* math.sin((90-alpha)*D2R)*3.14*0.796*0.796~" m²* V:"~speedms~"m.s-¹*2/3 (to take off the cones)");
        
        setprop("engines/engine[0]/massic-debit_div2",DebitModified);
        
        
        #For pelles/ecoppes movement
        myalt = getprop("/position/altitude-ft");
        if(myalt > 25000 and mach.getValue() > 0.6 and mach.getValue() < 1.2 and AirSpeed.getValue() < 400 and AngleOfAttack.getValue() > 12)
        {
            interpolate("engines/engine[0]/pelle", AngleOfAttack.getValue(), 0.5);
        }else{
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
    
    Intake_pelles();
}




