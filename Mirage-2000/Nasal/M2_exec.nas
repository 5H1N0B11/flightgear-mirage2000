 #---------------------------------------------------------------------------
 #
 #	Title                : Mirage 2000-5 real time executive
 #
 #	File Type            : Implementation File
 #
 #	Description          : Uses emesary notifications to permit nasal subsystems to
 #                       : be invoked in a controlled manner.
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



# to add properties to the FrameNotification simply send a FrameNotificationAddProperty
# to the global transmitter. This will be received by the frameNotifcation object and
# included in the update.
#emesary.GlobalTransmitter.NotifyAll(new FrameNotificationAddProperty("wow","gear/gear[0]/wow"));
#emesary.GlobalTransmitter.NotifyAll(new FrameNotificationAddProperty("engine_n2", "engines/engine[0]/n2"));
#    


#
# real time exec loop.
var rtExec_loop = func
{
    var frame_rate = getprop("/sim/frame-rate");
    var elapsed_seconds = getprop("/sim/time/elapsed-sec");
    #
    # you can put commonly accessed properties inside the message to improve performance.
    #
    notifications.frameNotification.FrameRate = frame_rate;
    notifications.frameNotification.ElapsedSeconds = elapsed_seconds;

    notifications.frameNotification.fetchvars();

    if (notifications.frameNotification.FrameCount >= 4) {
        notifications.frameNotification.FrameCount = 0;
    }

    emesary.GlobalTransmitter.NotifyAll(notifications.frameNotification);

    notifications.frameNotification.FrameCount = notifications.frameNotification.FrameCount + 1;

    execTimer.restart(0);
}

var execTimer = maketimer(1, rtExec_loop);
execTimer.start();
