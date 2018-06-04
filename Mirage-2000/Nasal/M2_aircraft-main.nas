 #---------------------------------------------------------------------------
 #
 #	Title                : Mirage 2000-5 main aircraft module.
 #
 #	File Type            : Implementation File
 #
 #	Description          : Top level nasal module that controls overall aircraft function
 #
 #	Author               : Richard Harrison (richard@zaretto.com)
 #
 #	Creation Date        : 4 June 2018
 #
 #	Version              : 1.0
 #
 #  Copyright (C) 2018 Richard Harrison           Released under GPL V2
 #
 #---------------------------------------------------------------------------*/

# set reasonable values for sound volumes
setprop("fdm/jsbsim/systems/sound/engine-efflux-l-volume",0.3);
setprop("fdm/jsbsim/systems/sound/engine-efflux-r-volume",0.3);
setprop("fdm/jsbsim/systems/sound/engine-jet-augmentation-l-volume",0);
setprop("fdm/jsbsim/systems/sound/engine-jet-augmentation-r-volume",0);
setprop("fdm/jsbsim/systems/sound/engine-jet-exhaust-l-volume",0.3);
setprop("fdm/jsbsim/systems/sound/engine-jet-exhaust-r-volume",0.3);
setprop("fdm/jsbsim/systems/sound/engine-jet-intake-l-volume",0.8);
setprop("fdm/jsbsim/systems/sound/engine-jet-intake-r-volume",0.8);
setprop("fdm/jsbsim/systems/sound/engine-n2-l-volume",0.4);
setprop("fdm/jsbsim/systems/sound/engine-n2-r-volume",0.4);
#
# Mirage 2000-5 aircraft interface
# based on my new way of doing things that mainly uses Emesary and frame notifications.
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2017-01-17
#


#
# add dialogs
var wow = 0;
var two_seater=1;
var dlg_ext_loads = gui.Dialog.new("dialog","Aircraft/Mirage-2000/Dialogs/external-loads.xml");
var dlg_ground_services  = gui.Dialog.new("dialog[2]","Aircraft/Mirage-2000/Dialogs/ground-services.xml");
var dlg_lighting  = gui.Dialog.new("dialog[3]","Aircraft/Mirage-2000/Dialogs/lighting.xml");
var dlg_debug = gui.Dialog.new("dialog[4]","Aircraft/Mirage-2000/Dialogs/debug.xml");

# Init ####################
var init = func(v) {

	print("Initializing Mirage 2000");
    
    setprop("/autopilot/locks/altitude","");
    setprop("/autopilot/locks/heading","");
    setprop("/autopilot/locks/passive-mode","");
    setprop("/autopilot/locks/speed","");

    # now allow the subsystems to intialize
    emesary.GlobalTransmitter.NotifyAll(notifications.InitNotification.new(v));
#	ext_loads_init();
#	init_fuel_system();
#	aircraft.data.load();
#	_net.mp_network_init(1);
#	weapons_init();
}

setlistener("/sim/initialized", init);
setlistener("sim/signals/reinit", init);

#
# sets property with clipping to remain in the specified range
var  setprop_inrange = func(p,v,mn,mx)
{
    if (mn != nil and v < mn)
        v = mn;
    if (mx != nil and  v > mx)
        v = mx;
    setprop(p,v);
};

var AircraftMain_System = 
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident~".RtExec");

        # request framenotification to monitor new properties that we use
        emesary.GlobalTransmitter.NotifyAll(notifications.FrameNotificationAddProperty.new("engine_n2", "engines/engine[0]/n2"));
        emesary.GlobalTransmitter.NotifyAll(notifications.FrameNotificationAddProperty.new("wow", "fdm/jsbsim/gear/wow"));
        emesary.GlobalTransmitter.NotifyAll(notifications.FrameNotificationAddProperty.new("view_internal", "sim/current-view/internal"));

        new_class.Receive = func(notification)
        {
            if (notification == nil)
            {
                print("bad notification nil");
                return emesary.Transmitter.ReceiptStatus_NotProcessed;
            }

            if (notification.NotificationType == "FrameNotification")
            {
                me.updateVolume(notification);
                wow = notification.wow;
                notification.ContactsList = []; #mirage2000.myRadar3
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        new_class.updateVolume = func(notification)
        {
            var n2_l = notification.engine_n2;

            if (notification.view_internal)
                setprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume",
                        0.2
                        + getprop("canopy/position-norm")-getprop("/controls/seat/pilot-helmet-volume-attenuation"));
            else
                setprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume",1);


            setprop_inrange("fdm/jsbsim/systems/sound/cockpit-effects-volume", 
                            0.3
                            - getprop("/controls/seat/pilot-helmet-volume-attenuation"),0,1);

            if (n2_l != nil)
            {
                setprop_inrange("fdm/jsbsim/systems/sound/engine-jet-intake-l-volume",
                                0.0133
                                * n2_l
                                * getprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume"),nil,1);

                setprop_inrange("fdm/jsbsim/systems/sound/engine-n2-l-volume",
                                0.015
                                * n2_l
                                * getprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume"),nil,0.4);

                setprop_inrange("fdm/jsbsim/systems/sound/engine-jet-exhaust-l-volume",
                                (n2_l-30)/70
                                * getprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume"), 0, 1.0);

                setprop_inrange("fdm/jsbsim/systems/sound/engine-efflux-l-volume",
                                (n2_l-30)/70
                                * getprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume"), 0, 1.0);
            }
        };
        return new_class;
    },
};

#
# set the splash vector for the new canopy rain.
var splash_vec_loop = func
{
    var v_x = getprop("fdm/jsbsim/velocities/u-aero-fps");
    var v_y = getprop("fdm/jsbsim/velocities/v-aero-fps");
    var v_z = getprop("fdm/jsbsim/velocities/w-aero-fps");
    var v_x_max =400;
 
    if (v_x > v_x_max) 
        v_x = v_x_max;
 
    if (v_x > 1)
        v_x = math.sqrt(v_x/v_x_max);

    var splash_x = -0.1 - 4   * v_x;
    var splash_y =  0   - 0.1 * v_y;
    var splash_z =  1   - 0.1 * v_z;

    setprop("/environment/aircraft-effects/splash-vector-x", splash_x);
    setprop("/environment/aircraft-effects/splash-vector-y", splash_y);
    setprop("/environment/aircraft-effects/splash-vector-z", splash_z);
 
    if (wow and getprop("gear/gear[0]/rollspeed-ms") < 30)
      settimer( func {splash_vec_loop() },2.5);
    else
      settimer( func {splash_vec_loop() },1.2);
}

#
# this is an exception to the new way of calling systems using the my exec module
# simply because the rate is much slower and varies
splash_vec_loop();

var r1= AircraftMain_System.new("Mirage2000-5");
#emesary.GlobalTransmitter.PrintRecipients();
emesary.GlobalTransmitter.Register(r1);

