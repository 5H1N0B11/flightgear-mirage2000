#
# Authors: Axel Paccalin.
#
# Version 0.2
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
            FGUM_Radar.MemoryModule.new("echoMemory","echo", 8),             # Keep the echoes in "echoMemory" for 8 seconds.
            FGUM_Radar_MOLG.ExprModule.new("contacts", me.postProcessExpr),  # Apply post-processing and store the result in "contacts".
        ];
        
        append(me.parents, FGUM_Radar.Radar.new(modules));
        
        return me;
    },
    
    # TODO: Implement pilot radar controls here. 
};

# Instantiate a new RDY radar.
radar = RDY.new();

# Instantiate a contact provider to keep a contact dictionary up to date.
provider = FGUM_Contact.ContactProvider.new(FGUM_Radar.RadarContact.new);

# Instantiate a new radar processing pipeline.
pipeline = FGUM_Radar.Pipeline.new(radar, provider, 10);

# Initialize the contact provider and start the processing pipeline when ready.
setlistener("sim/signals/fdm-initialized", func(){
    provider.init();
    pipeline.start();    
});
