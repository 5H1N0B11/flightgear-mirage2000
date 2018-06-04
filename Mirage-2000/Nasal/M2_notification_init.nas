 #---------------------------------------------------------------------------
 #
 #	Title                : Mirage 2000-5 init notification
 #
 #	File Type            : Implementation File
 #
 #	Description          : Sent out when fdm initialized. Alternative to explicit listener on 
 #                       : /sim/initialized, or /sim/signals/fdm-initialized or /sim/signals/reinit
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


var InitNotification = 
{
    new: func(type)
    {
        var new_class = emesary.Notification.new("InitNotification", type);
        return new_class;
    },
};
