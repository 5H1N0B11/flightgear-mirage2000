print("*** LOADING environment.nas ... ***");
################################################################################
#
#                     m2005-5's ENVIRONMENT SETTINGS
#
################################################################################
# From AIBase.cxx

var const_e = 2.71828183;

var rho_sndspeed = func(altitude)
{
    # Calculate density of air: rho
    # at altitude (ft), using standard atmosphere,
    # standard temperature T and pressure p.
    var T = 0;
    var p = 0;

    if(altitude < 36152)
    {
        # curve fits for the troposphere
        T = 59 - 0.00356 * altitude;
        p = 2116 * math.pow( ((T + 459.7) / 518.6), 5.256 );
    }
    elsif(altitude > 36152 and altitude < 82345)
    {
        # lower stratosphere
        T = -70;
        p = 473.1 * math.pow(const_e, 1.73 - (0.000048 * altitude) );
    }
    else
    {
        # upper stratosphere
        T = -205.05 + (0.00164 * altitude);
        p = 51.97 * math.pow( ((T + 459.7) / 389.98) , -11.388 );
    }
    var rho = p / (1718 * (T + 459.7));

    # calculate the speed of sound at altitude
    # a = sqrt ( g * R * (T + 459.7))
    # where:
    # snd_speed in feet/s,
    # g = specific heat ratio, which is usually equal to 1.4
    # R = specific gas constant, which equals 1716 ft-lb/slug/R
    var snd_speed = math.sqrt( 1.4 * 1716 * (T + 459.7) );
    return [rho, snd_speed];
}

var max_cloud_layer = func() {
  #Generate a property that give the max cloud layer  
  
  #Creating property in tree
  var maxCloudLayer = props.globals.getNode("/environment/maxCloudLayer",1);
  
  #Taking the tree for the loop
  var layerTree = props.globals.getNode("/environment/clouds/");
    
  #Variable for the max alt
  var cloudlayerAlt = 0 ; 
  var raw_list = layerTree.getChildren();
  
  #The loop
  foreach(var c ; raw_list)
  {
    if(c.getName()=="layer"){
      var elevation = c.getNode("elevation-ft").getValue();
      cloudlayerAlt = elevation > cloudlayerAlt?elevation:cloudlayerAlt;
    }
  }
  #Writing the max value
  maxCloudLayer.setValue(cloudlayerAlt);
}



input = {
  acInstrVolt:      "systems/electrical/outputs/ac-instr-voltage",
  acMainVolt:       "systems/electrical/outputs/ac-main-voltage",
  airspeed:         "velocities/airspeed-kt",
  alpha:            "orientation/alpha-deg",
  alt:              "position/altitude-ft",
  apLockAlt:        "autopilot/locks/altitude",
  apLockHead:       "autopilot/locks/heading",
  apLockSpeed:      "autopilot/locks/speed",
  augmentation:     "/controls/engines/engine[0]/augmentation",
  dcVolt:           "systems/electrical/volts",
  
  
  dme:              "instrumentation/dme/KDI572-574/nm",
  dmeDist:          "instrumentation/dme/indicated-distance-nm",
  downFps:          "/velocities/down-relground-fps",
  elapsed:          "sim/time/elapsed-sec",
  elapsedInit:      "sim/time/elapsed-at-init-sec",
  elecMain:         "controls/electric/main",
  engineRunning:    "engines/engine/running",
  flame:            "engines/engine/flame",
  fuelNeedleB:      "/instrumentation/fuel/needleB_rot",
  fuelNeedleF:      "/instrumentation/fuel/needleF_rot",
  fuelRatio:        "/instrumentation/fuel/ratio",
  fullInit:         "sim/time/full-init",
  g3d:              "/velocities/groundspeed-3D-kt",
  gearsPos:         "gear/gear/position-norm",
  headingMagn:      "/orientation/heading-magnetic-deg",
  impact:           "/ai/models/model-impact",
  indAlt:           "/instrumentation/altitude-indicator",
  indAltFt:         "instrumentation/altimeter/indicated-altitude-ft",
  indAltMeter:      "instrumentation/altimeter/indicated-altitude-meter",
  indAtt:           "/instrumentation/attitude-indicator",
  indJoy:           "/instrumentation/joystick-indicator",
  indRev:           "/instrumentation/reverse-indicator",
  indTrn:           "/instrumentation/transonic-indicator",
  landLightALS:     "sim/rendering/als-secondary-lights/use-landing-light",
  #landLightSupport: "ja37/supported/landing-light",
  landLightSwitch:  "controls/electric/lights-land-switch",
  lockPassive:      "/autopilot/locks/passive-mode",
  mach:             "velocities/mach",
  MPfloat2:         "sim/multiplay/generic/float[2]",
  MPfloat9:         "sim/multiplay/generic/float[9]",
  MPint17:          "sim/multiplay/generic/int[17]",
  MPint18:          "sim/multiplay/generic/int[18]",
  MPint19:          "sim/multiplay/generic/int[19]",
  MPint9:           "sim/multiplay/generic/int[9]",
  n1:               "/engines/engine/n1",
  n2:               "/engines/engine/n2",
  nearby:           "damage/sounds/nearby-explode-on",
  explode:          "damage/sounds/explode-on",
  rad_alt:          "position/altitude-agl-ft",
  rainNorm:         "environment/rain-norm",
  #rainVol:          "ja37/sound/rain-volume",
  replay:           "sim/replay/replay-state",
  reversed:         "/engines/engine/is-reversed",
  rmActive:         "/autopilot/route-manager/active",
  rmBearing:        "/autopilot/route-manager/wp/bearing-deg",
  rmBearingRel:     "autopilot/route-manager/wp/bearing-deg-rel",
  rmDist:           "autopilot/route-manager/wp/dist",
  rmDistKm:         "autopilot/route-manager/wp/dist-km",
  roll:             "/instrumentation/attitude-indicator/indicated-roll-deg",
  sceneRed:         "/rendering/scene/diffuse/red",
  servFire:         "engines/engine[0]/fire/serviceable",
  serviceElec:      "systems/electrical/serviceable",
  speedKt:          "/instrumentation/airspeed-indicator/indicated-speed-kt",
  speedMach:        "/instrumentation/airspeed-indicator/indicated-mach",
  srvHead:          "instrumentation/heading-indicator/serviceable",
  starter:          "controls/engines/engine[0]/starter-cmd",
  stationSelect:    "controls/armament/station-select",
  subAmmo2:         "ai/submodels/submodel[2]/count", 
  subAmmo3:         "ai/submodels/submodel[3]/count", 
  sunAngle:         "sim/time/sun-angle-rad",
  switchBeacon:     "controls/electric/lights-ext-beacon",
  switchFlash:      "controls/electric/lights-ext-flash",
  switchNav:        "controls/electric/lights-ext-nav",
  tempDegC:         "environment/temperature-degc",
  thrustLb:         "engines/engine/thrust_lb",
  thrustLbAbs:      "engines/engine/thrust_lb-absolute",
  trigger:          "controls/armament/trigger",
  viewInternal:     "sim/current-view/internal",
  viewName:         "sim/current-view/name",
  viewYOffset:      "sim/current-view/y-offset-m",
  zAccPilot:        "accelerations/pilot/z-accel-fps_sec",
  
  airconditioningtype:        "/controls/ventilation/airconditioning-type",
  airconditioningtemperature: "/controls/ventilation/airconditioning-temperature",
  airconditioningenabled:     "/controls/ventilation/airconditioning-enabled",
  windshieldhotairknob:       "/controls/ventilation/windshield-hot-air-knob",
  airConditionKnob:           "/controls/ventilation/knob",
  canopyPos:        "sim/model/door-positions/crew/position-norm",
  glasstempIndex:   "/environment/aircraft-effects/glass-temperature-index",
  fogNormInside:    "/environment/aircraft-effects/fog-inside",
  fogNormOutside:   "/environment/aircraft-effects/fog-outside",
  frostNormInside:  "/environment/aircraft-effects/frost-inside",
  frostNormOutside: "/environment/aircraft-effects/frost-outside",
  tempInside :      "/environment/aircraft-effects/temperature-inside-degC",
};

var FALSE = 0;
var TRUE = 1;
var LOOP_SLOW_RATE     = 1.50;

  foreach(var name; keys(input)) {
      input[name] = props.globals.getNode(input[name], 1);
  }
  
input.glasstempIndex.setValue(0.80); 
input.fogNormInside.setValue(0);
input.fogNormOutside.setValue(0);
input.frostNormInside.setValue(0);
input.frostNormOutside.setValue(0);
input.airConditionKnob.setValue(0);
input.airconditioningenabled.setValue(0);
input.windshieldhotairknob.setValue(0);
input.airconditioningtemperature.setValue(22);
input.airconditioningtype.setValue(0);



#airConditionKnob is middle at 0 in auto mode.180 middle in manual mode
#90 Max Hot.91 => going to manual d
# 
#    30 -------------   22 ------------- 15     Temp deg C
#                   Automatic
#    90  ------------   0  ------------- 270    Knob deg
#    |                                    | 
#    91  ------------- 180 ------------- 269    Knob deg
#                   Manual
#    30  ------------- 22 ---------------15     Temp deg C
                  

var acSetting = 0;
var acTimer = 0;
var acPrev = 0;
var tempAC = 0;
var airspeed =0;
var airspeed_max = 0;
var splash_x = 0;
var splash_y = 0;
var splash_z = 0;


var tempOutside = 0;
var ramRise     =  0;
var tempInside  = 0;
var tempOutsideDew = 0;
var tempInsideDew = 0;
var tempACDew = 0;
var ACRunning = 0;


var hotAir_deg_min = 0;
var AC_deg_min     = 0;
var pilot_deg_min  = 0;
var knob = 0;
var hotAirOnWindshield = 0;

var tempInsideDew = 0;
var fogNormOutside = 0;
var fogNormInside = 0;

var tempIndex=0;
var tempGlass=0;

var frostNormOutside = 0;
var frostNormInside = 0;
var rain = 0;

var frostSpeedInside = 0;
var frostSpeedOutside = 0;
var maxFrost = 0;
var maxFrostInside = 0;
var frostNormOutside = 0;
var frostNormInside = 0;
var frostNorm = 0;

var mask=0;

# controls/ventilation/airconditioning-type
# controls/ventilation/airconditioning-temperature
# controls/ventilation/airconditioning-enabled
# controls/ventilation/windshield-hot-air-knob
#/controls/ventilation/knob


#From the Viggen. Has to be converted
var environment =  func (){
    
    ###########################################################
    #               Aircondition, frost, fog and rain         #
    ###########################################################

    # If AC is set to warm or cold, then it will put warm/cold air into the cockpit for 12 seconds, and then revert to auto setting.

     acSetting = getprop("controls/ventilation/airconditioning-type");
#     if (acSetting != 0) {
      # 12 second of cold or hot air has been selected.
#       if (acPrev != acSetting) {
#         acTimer = input.elapsed.getValue();
#       } elsif (acTimer+12 < input.elapsed.getValue()) {
#         setprop("controls/ventilation/airconditioning-type", 0);
#         acSetting = 0;
#       }
#     }
#     acPrev = acSetting;
     tempAC = getprop("controls/ventilation/airconditioning-temperature");
#     if (acSetting == -1) {
#       tempAC = -200;
#     } elsif (acSetting == 1) {
#       tempAC = 200;
#     }

    # Here is calculated how raindrop move over the surface of the glass

    airspeed = getprop("/velocities/airspeed-kt");
    airspeed_max = 120;
    if (airspeed > airspeed_max) {
      airspeed = airspeed_max;
    }
    airspeed = math.sqrt(airspeed/airspeed_max);
    # Reverted the vector from what is used on the f-16
    splash_x = -(-0.1 - 2.0 * airspeed);
    splash_y = 0.0;
    splash_z = -(1.0 - 1.35 * airspeed);
    setprop("/environment/aircraft-effects/splash-vector-x", splash_x);
    setprop("/environment/aircraft-effects/splash-vector-y", splash_y);
    setprop("/environment/aircraft-effects/splash-vector-z", splash_z);

    # If the AC is turned on and on auto setting, it will slowly move the cockpit temperature toward its temperature setting.
    # The dewpoint inside the cockpit depends on the outside dewpoint and how the AC is working.
    tempOutside = getprop("environment/temperature-degc");
    ramRise     = (input.airspeed.getValue()*input.airspeed.getValue())/(87*87);#this is called the ram rise formula
    tempOutside    += ramRise;
    tempInside  = getprop("environment/aircraft-effects/temperature-inside-degC");
    tempOutsideDew = getprop("environment/dewpoint-degc");
    tempInsideDew = getprop("/environment/aircraft-effects/dewpoint-inside-degC");
    tempACDew = 5;# aircondition dew point target. 5 = dry
    ACRunning = input.dcVolt.getValue() > 23 and getprop("controls/ventilation/airconditioning-enabled") == TRUE;# and testing.ongoing == FALSE;

    # calc inside temp
    hotAir_deg_min = 2.0;# how fast does the sources heat up cockpit.
    AC_deg_min     = 6.0;
    pilot_deg_min  = 0.2;
    knob = getprop("controls/ventilation/windshield-hot-air-knob");
    hotAirOnWindshield = input.dcVolt.getValue() > 23?knob:0;
    
    
    if (input.canopyPos.getValue() > 0 ){ #or input.canopyHinge.getValue() == FALSE) {
      tempInside = tempOutside;
    } else {
        tempInside = tempInside + hotAirOnWindshield * (hotAir_deg_min/(60/LOOP_SLOW_RATE)); # having hot air on windshield will also heat cockpit (10 degs/5 mins).
      if (tempInside < 37) {
        tempInside = tempInside + (pilot_deg_min/(60/LOOP_SLOW_RATE)); # pilot will also heat cockpit with 1 deg per 5 mins
      }
      
      # outside temp will influence inside temp:
      coolingFactor = clamp(abs(tempInside - tempOutside)*0.005, 0, 0.10);# 20 degrees difference will cool/warm with 0.10 Deg C every 1.5 second
      if (tempInside < tempOutside) {
        tempInside = clamp(tempInside+coolingFactor, -1000, tempOutside);
      } elsif (tempInside > tempOutside) {
        tempInside = clamp(tempInside-coolingFactor, tempOutside, 1000);
      }
      if (ACRunning == TRUE) {
        # AC is running and will work to adjust to influence the inside temperature
        if (tempInside < tempAC) {
          tempInside = clamp(tempInside+(AC_deg_min/(60/LOOP_SLOW_RATE)), -1000, tempAC);
        } elsif (tempInside > tempAC) {
          tempInside = clamp(tempInside-(AC_deg_min/(60/LOOP_SLOW_RATE)), tempAC, 1000);
        }
      }
    }
    # print("tempInside:"~tempInside);
    # calc temp of glass itself
    tempIndex = getprop("/environment/aircraft-effects/glass-temperature-index"); # 0.80 = good window   0.45 = bad window
    tempGlass = tempIndex*(tempInside - tempOutside)+tempOutside;
    
    # calc dewpoint inside
    if (input.canopyPos.getValue() > 0){ # or input.canopyHinge.getValue() == FALSE) {
      # canopy is open, inside dewpoint aligns to outside dewpoint instead
      tempInsideDew = tempOutsideDew;
    } else {
      tempInsideDewTarget = 0;
      if (ACRunning == TRUE) {
        # calculate dew point for inside air. When full airconditioning is achieved at tempAC dewpoint will be tempACdew.
        # slope = (outsideDew - desiredInsideDew)/(outside-desiredInside)
        # insideDew = slope*(inside-desiredInside)+desiredInsideDew
        slope = (tempOutsideDew - tempACDew)/(tempOutside-tempAC);
        tempInsideDewTarget = slope*(tempInside-tempAC)+tempACDew;
      } else {
        tempInsideDewTarget = tempOutsideDew;
      }
      if (tempInsideDewTarget > tempInsideDew) {
        tempInsideDew = clamp(tempInsideDew + 0.15, -1000, tempInsideDewTarget);
      } else {
        tempInsideDew = clamp(tempInsideDew - 0.15, tempInsideDewTarget, 1000);
      }
    }

    # calc fogging outside and inside on glass
    fogNormOutside = clamp((tempOutsideDew-tempGlass)*0.05, 0, 1);
    fogNormInside = clamp((tempInsideDew-tempGlass)*0.05, 0, 1);
    
    # calc frost
    frostNormOutside = getprop("/environment/aircraft-effects/frost-outside");
    frostNormInside = getprop("/environment/aircraft-effects/frost-inside");
    rain = getprop("/environment/rain-norm");
    if (rain == nil) {
      rain = 0;
    }
    frostSpeedInside = clamp(-tempGlass, -60, 60)/600 + (tempGlass<0?fogNormInside/50:0);
    frostSpeedOutside = clamp(-tempGlass, -60, 60)/600 + (tempGlass<0?(fogNormOutside/50 + rain/50):0);
    maxFrost = clamp(1 + ((tempGlass + 5) / (0 + 5)) * (0 - 1), 0, 1);# -5 is full frost, 0 is no frost
    maxFrostInside = clamp(maxFrost - clamp(tempInside/30,0,1), 0, 1);# frost having harder time to form while being constantly thawed.
    frostNormOutside = clamp(frostNormOutside + frostSpeedOutside, 0, maxFrost);
    frostNormInside = clamp(frostNormInside + frostSpeedInside, 0, maxFrostInside);
    frostNorm = frostNormOutside>frostNormInside?frostNormOutside:frostNormInside;
    #var frostNorm = clamp((tempGlass-0)*-0.05, 0, 1);# will freeze below 0

    # recalc fogging from frost levels, frost will lower the fogging
    fogNormOutside = clamp(fogNormOutside - frostNormOutside / 4, 0, 1);
    fogNormInside = clamp(fogNormInside - frostNormInside / 4, 0, 1);
    fogNorm = fogNormOutside>fogNormInside?fogNormOutside:fogNormInside;

    # If the hot air on windshield is enabled and its setting is high enough, then apply the mask which will defog the windshield.
    mask = FALSE;
    if (frostNorm <= hotAirOnWindshield and hotAirOnWindshield != 0) {
      mask = TRUE;
    }

    # internal environment
    setprop("/environment/aircraft-effects/fog-inside", fogNormInside);
    setprop("/environment/aircraft-effects/fog-outside", fogNormOutside);
    setprop("/environment/aircraft-effects/frost-inside", frostNormInside);
    setprop("/environment/aircraft-effects/frost-outside", frostNormOutside);
    setprop("/environment/aircraft-effects/temperature-glass-degC", tempGlass);
    setprop("/environment/aircraft-effects/dewpoint-inside-degC", tempInsideDew);
    setprop("/environment/aircraft-effects/temperature-inside-degC", tempInside);
    # effects
    setprop("/environment/aircraft-effects/frost-level", frostNorm);
    setprop("/environment/aircraft-effects/fog-level", fogNorm);
    setprop("/environment/aircraft-effects/use-mask", mask);
    if (rand() > 0.95) {
      if (tempInside < 10) {
        if (tempInside < 5) {
          screen.log.write("You are freezing, the cabin is very cold", 1.0, 0.0, 0.0);
        } else {
          screen.log.write("You feel cold, the cockpit is cold", 1.0, 0.5, 0.0);
        }
      } elsif (tempInside > 23) {
        if (tempInside > 26) {
          screen.log.write("You are sweating, the cabin is way too hot", 1.0, 0.0, 0.0);
        } else {
          screen.log.write("You feel its too warm in the cabin", 1.0, 0.5, 0.0);
        }
      }
    }
  };
  var clamp = func(v, min, max) {
   v < min ? min : v > max ? max : v
  };
  
var TempInterpolation = func(){
  #airConditionKnob is middle at 0 in auto mode.180 middle in manual mode
#90 Max Hot.91 => going to manual d
# 
#    30 -------------   22 ------------- 15     Temp deg C
#                   Automatic
#    90  ------------   0  ------------- 270    Knob deg
#    |                                    | 
#    91  ------------- 180 ------------- 269    Knob deg
#                   Manual
#    30  ------------- 22 ---------------15     Temp deg C
  
# input.airConditionKnob.setValue(0);
# controls/ventilation/airconditioning-temperature
  input.airconditioningtemperature.setValue(8*math.sin(input.airConditionKnob.getValue()*D2R)+22);
  input.airconditioningtype.setValue(math.cos(input.airConditionKnob.getValue()*D2R)<0?1:0);
}
