print("*** LOADING transpondeur.nas ... ***");
################################################################################
#
#                     m2005-5's TRANSPONDER SETTINGS
#
################################################################################

var ALTITUDE = func()
{
    if(getprop("/instrumentation/transponder/switch/ALTITUDE") == 1)
    {
        # On enleve le mode IDENT
        setprop("/instrumentation/transponder/switch/IDENTIFICATION", 0);
        
        # Si la molette est bien en mode "N" alors on code le trans en ALT
        if(getprop("/instrumentation/transponder/switch/MoletteTrans") == 3)
        {
            setprop("/instrumentation/transponder/inputs/knob-mode", 5);
        }
    }
}

var IDENT = func()
{
    if(getprop("/instrumentation/transponder/switch/IDENTIFICATION") == 1)
    {
        # On enleve le mode ALTITUDE
        setprop("/instrumentation/transponder/switch/ALTITUDE", 0);
        
        # Si la molette est bien en mode "N" alors on code le trans en IDENTIFICATION
        if(getprop("/instrumentation/transponder/switch/MoletteTrans") == 3)
        {
            setprop("/instrumentation/transponder/inputs/knob-mode", 4);
        }
    }
}

var MOLETTE_haut = func()
{
    if(getprop("/instrumentation/transponder/switch/MoletteTrans") == 2)
    {
        setprop("/instrumentation/transponder/switch/MoletteTrans", 3);
    }
    MOLETTE();
}

var MOLETTE_bas = func()
{
    if(getprop("/instrumentation/transponder/switch/MoletteTrans") == 2)
    {
        setprop("/instrumentation/transponder/switch/MoletteTrans", 1);
    }
    MOLETTE();
}

var MOLETTE = func()
{
    # Mode OFF
    if(getprop("/instrumentation/transponder/switch/MoletteTrans") == 0)
    {
        setprop("/instrumentation/transponder/inputs/knob-mode", 0);
    }
    # Mode STBY
    if(getprop("/instrumentation/transponder/switch/MoletteTrans") == 1)
    {
        setprop("/instrumentation/transponder/inputs/knob-mode", 1);
    }
    # INDENT : Mode ON
    if(getprop("/instrumentation/transponder/switch/IDENTIFICATION") == 1)
    {
        # Si la molette est bien en mode "N" alors on code le trans en IDENTIFICATION
        if(getprop("/instrumentation/transponder/switch/MoletteTrans") == 3)
        {
            setprop("/instrumentation/transponder/inputs/knob-mode", 4);
        }
    }
    # INDENT : Mode ALT
    if(getprop("/instrumentation/transponder/switch/ALTITUDE") == 1)
    {
        # Si la molette est bien en mode "N" alors on code le trans en ALTITUDE
        if(getprop("/instrumentation/transponder/switch/MoletteTrans") == 3)
        {
            setprop("/instrumentation/transponder/inputs/knob-mode", 5);
        }
    }
}
