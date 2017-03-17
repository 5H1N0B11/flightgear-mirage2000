print("*** LOADING Loading_missiles.nas ... ***");
################################################################################
#
#                     m2005-5's LOADS AND MISSILES SETTINGS
#
################################################################################

var Loading_missile = func(name)
{
    print("Loading_Missile :"~name);
    var address           = "test";
    var NoSmoke           = "test2";
    var Explosion         = "/Aircraft/Mirage-2000/Missiles/MatraMica/explosion.xml";
    var maxdetectionrngnm = 0;
    var fovdeg            = 0;
    var detectionfovdeg   = 0;
    var trackmaxdeg       = 0;
    var maxg              = 0;
    var thrustlbs1        = 0;#stage 1
    var thrustlbs2        = 0;#stage 2
    var thrust1durationsec= 0;
    var thrust2durationsec= 0;
    var weightlaunchlbs   = 0;
    var dragcoeff         = 0;
    var dragarea          = 0;
    var maxExplosionRange = 0;
    var maxspeed          = 0;
    var life              = 0;
    var fox               = "nothing";
    var rail              = "true";
    var cruisealt         = 0;
    var min_guiding_speed_mach   = 0.8;
    var seeker_angular_speed_dps = 30;   # you want this (much) higher for your modern missiles
    var arming_time_sec          = 1.2;
    var guidance          = "radar";
    var railLength        = 2.667;
    var railForward       = 1;
    var fuel_lbm          = 0;
    var lock_on_sun_deg   = 5; # for AIM-9 newer than variant B, it is 5 degrees.

    if(name == "Matra MICA")
    {
        # MICA max range 80 km for actual version. ->43 nm.. at mach 4 it's about 59 sec. I put a life of 120, and thurst duration to 3/4 the travel time, and have vectorial thurst (So 27 G more than a similar missile wich have not vectorial thurst)
        address = "/Aircraft/Mirage-2000/Missiles/MatraMica/MatraMica_smoke.xml";
        NoSmoke = "/Aircraft/Mirage-2000/Missiles/MatraMica/MatraMica.xml";
        Explosion = "/Aircraft/Mirage-2000/Missiles/MatraMica/explosion.xml";
        maxdetectionrngnm = 45;                      #  Not real Impact yet
        fovdeg = 30;                                 # seeker optical FOV
        detectionfovdeg = 180;                       # Search pattern diameter (rosette scan)
        trackmaxdeg = 135;                           # Seeker max total angular rotation
        maxg = 50;                                   # In turn
        thrustlbs1 = 2800;
        thrustlbs2 = 300;
        thrust1durationsec = 10;
        thrust2durationsec = 20;
        weightlaunchlbs = 216;
        weightwarheadlbs = 30;
        seeker_angular_speed_dps = 60;
        dragcoeff = 0.19;                           # guess; original 0.05
        dragarea = 0.30;                            # sq ft
        maxExplosionRange = 65;                      # in meter ! Due to the code, more the speed is important, more we need to have this figure high
        maxspeed = 4;                                # In Mach
        life = 110;
        fox = "Fox 3";
        rail = "true";
        cruisealt = 55000;
        fuel_lbm = 140;
        min_guiding_speed_mach = 0.7;
    }
    elsif(name == "AIM120")
    {
        # AIM 120 max range 72 km for actual version. ->39 nm.. at mach 4 it's about 53 sec. I put a life of 115, and thurst duration oo 3/4 the travel time.
        address = "/Aircraft/Mirage-2000/Missiles/AIM-120/AIM-120_smoke.xml";
        NoSmoke = "/Aircraft/Mirage-2000/Missiles/AIM-120/AIM-120.xml";
        maxdetectionrngnm = 38.8;                     # Not real Impact yet A little more than the MICA
        fovdeg = 30;                                  # seeker optical FOV
        detectionfovdeg = 180;                        # Search pattern diameter (rosette scan)
        trackmaxdeg = 135;                            # Seeker max total angular rotation
        weightlaunchlbs = 291;
        weightwarheadlbs = 44;
        maxExplosionRange = 65;                       # in meter !!Due to the code, more the speed is important, more we need to have this figure high
        maxspeed = 4;                                 # In Mach
        life = 110;
        fox = "Fox 3";
        rail = "false";
        cruisealt = 50000;
        maxg = 30;
        min_guiding_speed_mach = 0.7;
        arming_time_sec = 1.6;
        seeker_angular_speed_dps = 30;
        thrustlbs1 = 2700;
        thrustlbs2 = 280;
        thrust1durationsec = 10;
        thrust2durationsec = 18;
        dragcoeff = 0.2;
        dragarea = 0.2739;
        fuel_lbm = 130;
    }
    elsif(name == "Matra R550 Magic 2")
    {
        # Magic 2 max range 15 km for actual version. ->8 nm.. at mach 2.7 it's about 16 sec. I put a life of 35, and thurst duration to 3/4 the travel time.
        address = "/Aircraft/Mirage-2000/Missiles/MatraR550Magic2/MatraR550Magic2_smoke.xml";
        NoSmoke = "/Aircraft/Mirage-2000/Missiles/MatraR550Magic2/MatraR550Magic2.xml";
        maxdetectionrngnm = 8;                        # Not real Impact yet
        fovdeg = 25;                                  # seeker optical FOV
        detectionfovdeg = 180;                        # Search pattern diameter (rosette scan)
        trackmaxdeg = 110;                            # Seeker max total angular rotation
        maxg = 27;                                    # In turn
        thrustlbs1 = 2500;                            # guess
        thrustlbs2 = 0;
        thrust1durationsec =  4.5;
        thrust2durationsec =  0;
        weightlaunchlbs = 169;
        weightwarheadlbs = 27;
        seeker_angular_speed_dps = 50;
        dragcoeff = 0.51;                             # guess; original 0.05
        dragarea = 0.150;                             # sq ft
        maxExplosionRange = 65;                       # Due to the code, more the speed is important, more we need to have this figure high
        maxspeed = 2.7;                               # In Mach
        life = 45;
        fox = "Fox 2";
        rail = "true";
        cruisealt = 0;
        guidance = "heat";
        fuel_lbm = 60;
    }
    elsif(name == "Matra MICA IR")
    {
        # MICA max range 80 km for actual version. ->43 nm.. at mach 4 it's about 59 sec. I put a life of 120, and thurst duration to 3/4 the travel time, and have vectorial thurst (So 27 G more than a similar missile wich have not vectorial thurst)
        address = "/Aircraft/Mirage-2000/Missiles/MatraMicaIR/MatraMica_smoke.xml";
        NoSmoke = "/Aircraft/Mirage-2000/Missiles/MatraMicaIR/MicaIR.xml";
        Explosion = "/Aircraft/Mirage-2000/Missiles/MatraMica/explosion.xml";
        maxdetectionrngnm = 45;                      #  Not real Impact yet
        fovdeg = 30;                                 # seeker optical FOV
        detectionfovdeg = 180;                       # Search pattern diameter (rosette scan)
        trackmaxdeg = 135;                           # Seeker max total angular rotation
        maxg = 50;                                   # In turn
        thrustlbs1 = 2800;
        thrustlbs2 = 300;
        thrust1durationsec = 10;
        thrust2durationsec = 20;
        weightlaunchlbs = 216;
        weightwarheadlbs = 30;
        seeker_angular_speed_dps = 60;
        dragcoeff = 0.19;                           # guess; original 0.05
        dragarea = 0.30;                            # sq ft
        maxExplosionRange = 65;                      # in meter ! Due to the code, more the speed is important, more we need to have this figure high
        maxspeed = 4;                                # In Mach
        life = 110;
        fox = "Fox 2";
        rail = "true";
        cruisealt = 55000;
        fuel_lbm = 140;
        min_guiding_speed_mach = 0.7;
    }
    elsif(name == "aim-9")
    {
        # aim-9 max range 18 km for actual version. ->9 nm.. at mach 2.5 it's about 21 sec. I put a life of 40, and thurst duration to 3/4 the travel time.
        address = "/Aircraft/Mirage-2000/Missiles/aim-9/aim-9_smoke.xml";
        NoSmoke = "/Aircraft/Mirage-2000/Missiles/aim-9/aim-9.xml";
        maxdetectionrngnm = 9.7;                      # Not real Impact yet
        fovdeg = 27;                                  # seeker optical FOV
        detectionfovdeg = 180;                        # Search pattern diameter (rosette scan)
        trackmaxdeg = 82;                             # Seeker max total angular rotation
        weightlaunchlbs = 191;
        weightwarheadlbs = 20.8;
        maxExplosionRange = 65;                       # Due to the code, more the speed is important, more we need to have this figure high
        maxspeed = 2.5;                               # In Mach
        life = 50;
        fox = "Fox 2";
        rail = "true";
        cruisealt = 0;
        maxg = 32;
        min_guiding_speed_mach = 0.8;
        arming_time_sec = 1.4;
        seeker_angular_speed_dps = 30;
        thrustlbs1 = 2660;
        thrustlbs2 = 0;
        thrust1durationsec = 5.23;
        thrust2durationsec = 0;
        dragcoeff = 0.50;
        dragarea = 0.143;
        guidance = "heat";
        fuel_lbm = 60.4;
    }
    elsif(name == "GBU16")
    {
        address = "/Aircraft/Mirage-2000/Missiles/GBU16/gbu16.xml";
        NoSmoke = "/Aircraft/Mirage-2000/Missiles/GBU16/gbu16.xml";
        maxdetectionrngnm = 14;                       # Not real Impact yet
        fovdeg = 25;                                  # seeker optical FOV
        detectionfovdeg = 180;                        # Search pattern diameter (rosette scan)
        trackmaxdeg = 110;                            # Seeker max total angular rotation
        maxg = 15;
        thrustlbs1 = 1;
        thrustlbs2 = 0;
        thrust1durationsec =  0;
        thrust2durationsec =  0;
        weightlaunchlbs = 550;
        weightwarheadlbs = 450;
        dragcoeff = 0.10;                             # guess; original 0.05
        dragarea = 0.195;                             # sq ft
        maxExplosionRange = 40;                       # Due to the code, more the speed is important, more we need to have this figure high
        maxspeed = 1.5;                               # In Mach
        life = 120;
        fox = "A/G";
        rail = "false";
        cruisealt = 0;
    }
    elsif(name == "GBU12")
    {
        address = "/Aircraft/Mirage-2000/Missiles/GBU12/GBU12.xml";
        NoSmoke = "/Aircraft/Mirage-2000/Missiles/GBU12/GBU12.xml";
        maxdetectionrngnm = 14;                       # Not real Impact yet
        fovdeg = 25;                                  # seeker optical FOV
        detectionfovdeg = 180;                        # Search pattern diameter (rosette scan)
        trackmaxdeg = 110;                            # Seeker max total angular rotation
        maxg = 15;                                    # In turn
        thrustlbs1 = 1;
        thrustlbs2 = 0;
        thrust1durationsec =  0;
        thrust2durationsec =  0;
        weightlaunchlbs = 610;
        weightwarheadlbs = 190;
        dragcoeff = 0.10;                             # guess; original 0.05
        dragarea = 0.19;                              # sq ft
        maxExplosionRange = 40;                       # Due to the code, more the speed is important, more we need to have this figure high
        maxspeed = 1.5;                               # In Mach
        life = 120;
        fox = "A/G";
        rail = "false";
        cruisealt = 0;
    }
    elsif(name == "AGM65")
    {
        address = "/Aircraft/Mirage-2000/Missiles/AGM65/AGM65_smoke.xml";
        NoSmoke = "/Aircraft/Mirage-2000/Missiles/AGM65/AGM65.xml";
        maxdetectionrngnm = 14;                       # Not real Impact yet
        fovdeg = 25;                                  # seeker optical FOV
        detectionfovdeg = 180;                        # Search pattern diameter (rosette scan)
        trackmaxdeg = 110;                            # Seeker max total angular rotation
        maxg = 15;
        thrustlbs1 = 785;
        thrustlbs2 = 0;
        thrust1durationsec =  60;
        thrust2durationsec =  0;
        weightlaunchlbs = 400;
        weightwarheadlbs = 200;
        dragcoeff = 0.157;                            # guess; original 0.05
        dragarea = 0.135;                             # sq ft
        maxExplosionRange = 50;                       # Due to the code, more the speed is important, more we need to have this figure high
        maxspeed = 1;                                 # In Mach
        life = 90;
        fox = "A/G";
        rail = "false";
        cruisealt = 0;
    }
    elsif(name == "SCALP")
    {
        address = "/Aircraft/Mirage-2000/Missiles/SCALP/SCALP_smoke.xml";
        NoSmoke = "/Aircraft/Mirage-2000/Missiles/SCALP/SCALP.xml";
        maxdetectionrngnm = 135;                      # Not real Impact yet
        fovdeg = 25;                                  # seeker optical FOV
        detectionfovdeg = 180;                        # Search pattern diameter (rosette scan)
        trackmaxdeg = 180;                            # Seeker max total angular rotation
        maxg = 20;                                    # In turn
        thrustlbs1 = 2750;                            # guess
        thrust1durationsec = 1000;                    # Mk.36 Mod.7,8
        thrustlbs2 = 0;
        thrust2durationsec =  0;
        weightlaunchlbs = 1870;
        weightwarheadlbs = 992;
        dragcoeff = 0.50;                             # guess; original 0.05
        dragarea = 7.00;                              # sq ft
        maxExplosionRange = 90;                       # Due to the code, more the speed is important, more we need to have this figure high
        maxspeed = 0.8;                               # In Mach
        life = 1000;
        fox = "A/G";
        rail = "false";
        cruisealt = 300;
        min_guiding_speed_mach = 0.25;
        seeker_angular_speed_dps = 45;
    }
    elsif(name == "Sea Eagle")
    {
        address = "/Aircraft/Mirage-2000/Missiles/SeaEagle/seaeagle_smoke.xml";
        NoSmoke = "/Aircraft/Mirage-2000/Missiles/SeaEagle/seaeagle.xml";
        maxdetectionrngnm = 134;                      # Not real Impact yet
        fovdeg = 25;                                  # seeker optical FOV
        detectionfovdeg = 180;                        # Search pattern diameter (rosette scan)
        trackmaxdeg = 180;                            # Seeker max total angular rotation
        maxg = 15;                                    # In turn
        thrustlbs1 = 2000;                            # guess
        thrust1durationsec = 1000;                    # Mk.36 Mod.7,8
        thrustlbs2 = 0;
        thrust2durationsec =  0;
        weightlaunchlbs = 1320;
        weightwarheadlbs = 505;
        dragcoeff = 0.478;                            # guess; original 0.05
        dragarea = 0.411;                             # sq ft
        maxExplosionRange = 80;                       # Due to the code, more the speed is important, more we need to have this figure high
        maxspeed = 0.8;                               # In Mach
        life = 1000;
        fox = "A/M";
        rail = "false";
        cruisealt = 40;
        min_guiding_speed_mach = 0.25;
        seeker_angular_speed_dps = 45;
    }
    elsif(name == "Exocet")
    {
        address = "/Aircraft/Mirage-2000/Missiles/Exocet/exocet_smoke.xml";
        NoSmoke = "/Aircraft/Mirage-2000/Missiles/Exocet/exocet.xml";
        maxdetectionrngnm = 134;                      # Not real Impact yet
        fovdeg = 25;                                  # seeker optical FOV
        detectionfovdeg = 180;                        # Search pattern diameter (rosette scan)
        trackmaxdeg = 180;                            # Seeker max total angular rotation
        maxg = 15;                                    # In turn
        thrustlbs1 = 2000;                            # guess
        thrust1durationsec = 1000;                    # Mk.36 Mod.7,8
        thrustlbs2 = 0;
        thrust2durationsec =  0;
        weightlaunchlbs = 1480;
        weightwarheadlbs = 364;
        dragcoeff = 0.478;                            # guess; original 0.05
        dragarea = 0.411;                             # sq ft
        maxExplosionRange = 80;                       # Due to the code, more the speed is important, more we need to have this figure high
        maxspeed = 0.92;                               # In Mach
        life = 1000;
        fox = "A/M";
        rail = "false";
        cruisealt = 40;
        min_guiding_speed_mach = 0.25;
        seeker_angular_speed_dps = 45;
    }
    elsif(name == "AIM-54")
    {
        # aim-54 max range 1884 km for actual version. ->100 nm.. at mach 5 it's about 108 sec. I put a life of 1120, and thurst duration to 3/4 the travel time.
        address = "/Aircraft/Mirage-2000/Missiles/AIM-54/AIM-54_smoke.xml";
        NoSmoke = "/Aircraft/Mirage-2000/Missiles/AIM-54/AIM-54.xml";
        maxdetectionrngnm = 100;                      # Not real Impact yet
        fovdeg = 25;                                  # seeker optical FOV
        detectionfovdeg = 180;                        # Search pattern diameter (rosette scan)
        trackmaxdeg = 110;                            # Seeker max total angular rotation
        maxg = 25;                                    # In turn
        thrustlbs1 = 3250;                            # guess
        thrust1durationsec = 50;                      # Mk.36 Mod.7,8
        thrustlbs2 = 0;
        thrust2durationsec =  0;
        weightlaunchlbs = 905;
        weightwarheadlbs = 135;
        dragcoeff = 0.25;                             # guess; original 0.05
        dragarea = 1.234;                             # sq ft
        maxExplosionRange = 100;                      # Due to the code, more the speed is important, more we need to have this figure high
        maxspeed = 5;                                  # In Mach
        life = 180;
        fox = "Fox 3";
        rail = "false";
        cruisealt = 100000;
        fuel_lbm = 364;
        min_guiding_speed_mach = 0.7;
    }
    elsif(name == "Meteor")
    {
        # Meteor max range 180 km for actual version. ->100 nm.. at mach 5.8 it's about 95 sec. I put a life of 140, and thurst duration to 100% the travel time, and have vectorial thurst (So 35 G more than a similar missile wich have not vectorial thurst)
        address = "/Aircraft/Mirage-2000/Missiles/Meteor/Meteor_smoke.xml";
        NoSmoke = "/Aircraft/Mirage-2000/Missiles/Meteor/Meteor.xml";
        maxdetectionrngnm = 100;                      # Not real Impact yet
        fovdeg = 25;                                  # seeker optical FOV
        detectionfovdeg = 180;                        # Search pattern diameter (rosette scan)
        trackmaxdeg = 110;                            # Seeker max total angular rotation
        maxg = 35;                                    # In turn
        thrustlbs1 = 18344;                             # guess
        thrust1durationsec = 95;                       # Mk.36 Mod.7,8
        thrustlbs2 = 0;
        thrust2durationsec =  0;
        weightlaunchlbs = 357;
        weightwarheadlbs = 55;
        dragcoeff = 0.065;                            # guess; original 0.05
        dragarea = 0.056;                             # sq ft
        maxExplosionRange = 50;                       # in meter ! Due to the code, more the speed is important, more we need to have this figure high
        maxspeed = 5.8;                               # In Mach
        life = 140;
        fox = "Fox 3";
        rail = "true";
        cruisealt = 50000;
        min_guiding_speed_mach = 0.7;
    }
    elsif(name == "MATRA-R530")
    {
        # MATRA-R530 max range 20 km for actual version. ->10 nm.. at mach 2.7 it's about 20 sec. I put a life of 30, and thurst duration to 3/4 the travel time.
        address = "/Aircraft/Mirage-2000/Missiles/MATRA-R530/MATRA-R530_smoke.xml";
        NoSmoke = "/Aircraft/Mirage-2000/Missiles/MATRA-R530/MATRA-R530.xml";
        maxdetectionrngnm = 10.8;                     # Not real Impact yet
        fovdeg = 25;                                  # seeker optical FOV
        detectionfovdeg = 180;                        # Search pattern diameter (rosette scan)
        trackmaxdeg = 110;                            # Seeker max total angular rotation
        maxg = 30;                                    # In turn
        thrustlbs1 = 2700;                            # guess  the doc says 17 000 = 83 lbs of thrust...need to readapt all the values.
        thrust1durationsec = 6;                       # Mk.36 Mod.7,8
        thrustlbs2 = 0;
        thrust2durationsec =  0;
        weightlaunchlbs = 357;
        weightwarheadlbs = 55;
        dragcoeff = 0.30;                             # guess; original 0.05
        dragarea = 0.234;                             # sq ft
        maxExplosionRange =  65;                      # Due to the code, more the speed is important, more we need to have this figure high
        maxspeed = 2.7;                               # In Mach
        life = 50;
        fox = "Fox 2";
        rail = "false";
        cruisealt = 0;
        guidance = "heat";
        fuel_lbm = 60;
        min_guiding_speed_mach = 0.8;
    }
    elsif(name == "R74")
    {
        # R74 max range 40 km for actual version. ->21 nm.. at mach 2.5 it's about 47 sec. I put a life of 55, and thurst duration to 3/4 the travel time.
        address = "/Aircraft/Mirage-2000/Missiles/R74/R-74Smoke.xml";
        NoSmoke = "/Aircraft/Mirage-2000/Missiles/R74/R-74.xml";
        maxdetectionrngnm = 25;                       # Not real Impact yet
        fovdeg = 25;                                  # seeker optical FOV
        detectionfovdeg = 180;                        # Search pattern diameter (rosette scan)
        trackmaxdeg = 110;                            # Seeker max total angular rotation
        maxg = 25;                                    # In turn
        thrustlbs1 = 11495;                              # guess  the doc says 17 000 = 83 lbs of thrust...need to readapt all the values.
        thrust1durationsec = 35;                       # Mk.36 Mod.7,8
        thrustlbs2 = 0;
        thrust2durationsec =  0;
        weightlaunchlbs = 214;
        weightwarheadlbs = 16;
        dragcoeff = 0.06;                             # guess; original 0.05
        dragarea = 0.0552;                            # sq ft
        maxExplosionRange =  65;                      # Due to the code, more the speed is important, more we need to have this figure high
        maxspeed = 2.7;                               # In Mach
        life = 55;
        fox = "Fox 2";
        rail = "false";
        cruisealt = 0;
        min_guiding_speed_mach = 0.8;
    }
    else
    {
        return 0;
    }
    # SetProp
    setprop("controls/armament/missile/address", address);
    setprop("controls/armament/missile/addressNoSmoke", NoSmoke);
    setprop("controls/armament/missile/addressExplosion", Explosion);
    setprop("controls/armament/missile/max-detectionrngnm", maxdetectionrngnm);
    setprop("controls/armament/missile/fov-deg", fovdeg);
    setprop("controls/armament/missile/detection-fov-deg", detectionfovdeg);
    setprop("controls/armament/missile/track-max-deg", trackmaxdeg);
    setprop("controls/armament/missile/thrust-lbs-1", thrustlbs1);
    setprop("controls/armament/missile/thrust-lbs-2", thrustlbs2);
    setprop("controls/armament/missile/max-g", maxg);
    setprop("controls/armament/missile/weight-launch-lbs", weightlaunchlbs);
    setprop("controls/armament/missile/thrust-1-duration-sec", thrust1durationsec);
    setprop("controls/armament/missile/thrust-2-duration-sec", thrust2durationsec);
    setprop("controls/armament/missile/weight-warhead-lbs", weightwarheadlbs);
    setprop("controls/armament/missile/drag-coeff", dragcoeff);
    setprop("controls/armament/missile/drag-area", dragarea);
    setprop("controls/armament/missile/maxExplosionRange", maxExplosionRange);
    setprop("controls/armament/missile/maxspeed", maxspeed);
    setprop("controls/armament/missile/life", life);
    setprop("controls/armament/missile/fox", fox);
    setprop("controls/armament/missile/rail", rail);
    setprop("controls/armament/missile/cruise_alt", cruisealt);
    setprop("controls/armament/missile/min-guiding-speed-mach", min_guiding_speed_mach);
    setprop("controls/armament/missile/seeker-angular-speed-dps", seeker_angular_speed_dps);
    setprop("controls/armament/missile/arming-time-sec", arming_time_sec);
    setprop("controls/armament/missile/guidance", guidance);
    setprop("controls/armament/missile/rail-length-m", railLength);
    setprop("controls/armament/missile/rail-point-forward", railForward);
    setprop("controls/armament/missile/weight-fuel-lbm", fuel_lbm);
    setprop("controls/armament/missile/lock-on-sun-deg", lock_on_sun_deg);
    return 1;
}
