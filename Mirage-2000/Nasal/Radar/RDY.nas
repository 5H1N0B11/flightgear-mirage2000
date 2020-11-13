#
# Authors: Axel Paccalin.
#
# Version 0.1
#

var RDY = {
    #! \brief  RDY constructor. 
    #! \detail Instantiate a new FGUM_Radar with modules and parameters to match the behavior of the RDY radar made from Tales.
    new: func(){
        var me = {parents: [RDY]};
        
        # The RDY radar antenna.
        me.antenna = FGUM_Radar.Antenna.fromArbitraryGEA(4000,    # 4KW peak power.
                                                         111120,  # Can detect targets @60nm (111,12 km).
                                                         3.2);    # If the target has a RCS of 3.2m².
        
        # Filter for the target echo signal.
        me.signalFilter = FGUM_Radar.SignalFilter.new(me.antenna);
        
        # Filter for the pilot to filter out contacts further than a certain range.
        me.rangeFilter = FGUM_Radar.RangeFilter.new(111120);  # Initialized to filter out anything that's further than 60nm (111,12 km).
        
        # Filter for the scan shape of an Active Mechanically Steered Array.
        me.scanShapeFilter = FGUM_Radar.AMSAScanShapeFilter.new( 8,       #  8  Strips.
                                                                 3*D2R,   #  3° Height each (8*3=24° vertical FOV).
                                                                30*D2R,   # 30° Wide (horizontal FOV).
                                                                15*D2R,   # 15° Per second pan rate.
                                                                15*D2R,   # 15° Soft-lock radius.
                                                                 1*D2R);  #  1° Hard-lock radius.
        # Filter for the Line Of Sight (terrain).
        me.losFilter = FGUM_Radar.TerrainLOSFilter.new();  
        
        # Filter fot the contact-terrain differentiation.
        me.dopplerFilter = FGUM_Radar.DopplerFilter.new(10);  # 10m/s minimum observed speed to differentiate with the terrain.
        
        # Expression defining the echo of a contact. 
        me.echoExpr = FGUM_Radar_MOLG.BAnd.new(FGUM_Radar_MOLG.BAnd.new(me.signalFilter, 
                                                                        me.scanShapeFilter), 
                                               FGUM_Radar_MOLG.BAnd.new(me.losFilter, 
                                                                        me.dopplerFilter));
        
        # Expression for the post-processing of the contacts in radar memory.                  
        me.postProcessExpr = FGUM_Radar_MOLG.BAnd.new(FGUM_Radar_MOLG.NodeEvalExpr.new("echoMemory"),
                                                      me.rangeFilter);
        
        var modules = [
            FGUM_Radar_MOLG.ExprModule.new("echo", me.echoExpr),             # Store the echoes in "echo".
            FGUM_Radar.MemoryModule.new("echo", "echoMemory", 8),            # Keep the echoes in "echoMemory" for 8 seconds.
            FGUM_Radar_MOLG.ExprModule.new("contacts", me.postProcessExpr),  # Apply post-processing and store the result in "contacts".
        ];
        
        append(me.parents, FGUM_Radar.Radar.new(modules));
        
        return me;
    },
    
    # TODO: Implement pilot radar controls here. 
};

#TODO Move the pipeline to the FGUM_Radar module.
RadarPipeline = {
    new: func(){
        var me = {parents: [RadarPipeline]};
        
        me.contactManager = FGUM_Contact.ContactManager.new(FGUM_Radar.RadarContact.new);
        me.radar = RDY.new();
        
        # Timer for the radar clock.
        me.timer = maketimer(1/10, me, me.loop);
        # Make the timer follow the time of the simulation (time acceleration, pause ...).
        me.timer.simulatedTime = 1;
                
        # TODO: Enable again, ideally through an event listener.
        # me.start();
        
        setlistener("sim/signals/fdm-initialized", func {
            me.timer.start();
        });
        
        return me;
    },
    
    loop: func(){
        #TODO: Move the contact manager update to either a second (lower frequency) loop, or (ideally) update it through flightgear events.
        me.contactManager.update();
        me.radar.frame(me.contactManager.contacts);
    },
};

pipeline = RadarPipeline.new();