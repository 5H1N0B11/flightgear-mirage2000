print("*** LOADING mini-hud.nas ... ***");
################################################################################
#
#                          m2005-5's HUD SETTINGS
#
################################################################################

# this function will display hud #1 (standard) or hud #4 (minihud).
var minihud = func()
{
    var hud_number     = getprop("/sim/hud/current-path");
    var view_number    = getprop("/sim/current-view/view-number");
    var is_internal    = getprop("/sim/current-view/internal");
    var heading_offset = getprop("/sim/current-view/heading-offset-deg");
    var pitch_offset   = getprop("/sim/current-view/pitch-offset-deg");
    var internalHUD_selected = getprop("/controls/hud");
    
    var x = math.sin(heading_offset * math.pi / 180);
    var y = math.sin(pitch_offset * math.pi / 180);
    var distance_from_center = (x * x) + (y * y);
    
    # we check if internal or not and if pilot view :
    if((is_internal == 1) and (view_number != 11))
    {
        if(distance_from_center > 0.6)
        {
            if(hud_number != 4)
            {
                # head turned, mini hud is displayed
                setprop("/sim/hud/current-path",        4);
                setprop("/sim/hud/clipping/left",   -2000);
                setprop("/sim/hud/clipping/right",   2000);
                setprop("/sim/hud/clipping/top",     2000);
                setprop("/sim/hud/clipping/bottom", -2000);
            }
        }
        else
        {
            # if too much G, the bottom of the hud is hidden
            var is_dynamic_view = getprop("/sim/current-view/dynamic-view");
            if(is_dynamic_view)
            {
                var dynamic_clipping_bottom = -(95 - (getprop("/accelerations/pilot-gdamped") * 7));
                setprop("/sim/hud/clipping/bottom", dynamic_clipping_bottom);
            }
            
            if(hud_number != 1 and internalHUD_selected)
            {
                # head centered, normal hud is displayed
                setprop("/sim/hud/current-path",                          1);
                setprop("/sim/hud/clipping/left",                       -65);
                setprop("/sim/hud/clipping/right",                       65);
                setprop("/sim/hud/clipping/top",                         60);
            }
        }
    }
    else
    {
        if(hud_number != 4)
        {
            setprop("/sim/hud/current-path",        4);
            setprop("/sim/hud/clipping/left",   -2000);
            setprop("/sim/hud/clipping/right",   2000);
            setprop("/sim/hud/clipping/top",     2000);
            setprop("/sim/hud/clipping/bottom", -2000);
        }
    }
    settimer(minihud, 0.5);
}
