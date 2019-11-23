print("*** LOADING m2000-5-hydraulical.nas ... ***");
################################################################################
#
#                     m2005-5's HYDRAULICAL SYSTEM SETTINGS
#
################################################################################

var last_time       = 0.0;
var HYD1_deb        = props.globals.getNode("/systems/hydraulical/suppliers/HYD1_deb",   1);
var HYD1_press      = props.globals.getNode("/systems/hydraulical/suppliers/HYD1_press", 1);
var HYD2_deb        = props.globals.getNode("/systems/hydraulical/suppliers/HYD2_deb",   1);
var HYD2_press      = props.globals.getNode("/systems/hydraulical/suppliers/HYD2_press", 1);
var Circuit1_Press  = props.globals.getNode("/systems/hydraulical/circuit1_press",       1);
var Circuit2_Press  = props.globals.getNode("/systems/hydraulical/circuit2_press",       1);
var Volts           = props.globals.getNode("/systems/electrical/volts",                 1);
# Make it servicable
props.globals.getNode("/systems/hydraulical/serviceable", 1).setBoolValue(1);
var PWR             = props.globals.getNode("systems/hydraulical/serviceable", 1).getBoolValue();

# pump definition
# pressure in bars 1 bar =100 kPa = 100/6.89 PSI = 100kn/m^2
# deb in l/mn
HYDRPUMP = {
    new : func
    {
        m = { parents : [HYDRPUMP] };
        m.rpm_source =  props.globals.getNode(arg[0], 1);
        m.rpm_threshold = arg[1];
        m.ideal_bars = arg[2];
        m.ideal_deb = arg[3]; # l/mn
        m.volts_threshold = arg[4];
        return m;
    },
    get_output_bars_engine : func
    {
        var factor = me.rpm_source.getValue() / me.rpm_threshold;
        if(factor > 1.0)
        {
            factor = 1.0;
        }
        return me.ideal_bars * factor;
    },
    get_output_bars_electric : func
    {
#        var herevolts = (Volts.getValue() == "nil") ? 0 : Volts.getValue();
        var herevolts = (Volts.getValue() == nil) ? 0 : Volts.getValue();
        var factor = herevolts / me.volts_threshold;
        if(factor > 1.0)
        {
            factor = 1.0;
        }
        return me.ideal_bars * factor;
    },
    get_output_deb_engine : func
    {
        var factor = me.rpm_source.getValue() / me.rpm_threshold;
        if(factor > 1.0)
        {
            factor = 1.0;
        }
        return me.ideal_deb * factor;
    },
    get_output_deb_electric : func
    {
#        var herevolts = (Volts.getValue() == "nil") ? 0 : Volts.getValue();
        var herevolts = (Volts.getValue() == nil) ? 0 : Volts.getValue();
        var factor = herevolts / me.volts_threshold;
        if(factor > 1.0)
        {
            factor = 1.0;
        }
        return me.ideal_deb * factor;
    }
};

var hyd_1 = HYDRPUMP.new("/engines/engine[0]/rpm", 1500.0, 280.0, 110.0, 28);
var hyd_2 = HYDRPUMP.new("/engines/engine[0]/rpm", 1500.0, 280.0, 109.0, 28);

var update_virtual_circuits = func(dt)
{
#    var hydpress_1      = (hyd_1.get_output_bars_engine() == "nil") ? 0 : hyd_1.get_output_bars_engine();
    var hydpress_1      = (hyd_1.get_output_bars_engine() == nil) ? 0 : hyd_1.get_output_bars_engine();
#    var hydDeb_1        = (hyd_1.get_output_deb_engine()  == "nil") ? 0 : hyd_1.get_output_deb_engine();
    var hydDeb_1        = (hyd_1.get_output_deb_engine()  == nil) ? 0 : hyd_1.get_output_deb_engine();
#    var hydpress_2      = (hyd_2.get_output_bars_engine() == "nil") ? 0 : hyd_2.get_output_bars_engine();
    var hydpress_2      = (hyd_2.get_output_bars_engine() == nil) ? 0 : hyd_2.get_output_bars_engine();
#    var hydDeb_2        = (hyd_2.get_output_deb_engine()  == "nil") ? 0 : hyd_2.get_output_deb_engine();
    var hydDeb_2        = (hyd_2.get_output_deb_engine()  == nil) ? 0 : hyd_2.get_output_deb_engine();
    var circuit1_press  = hydpress_1;
    var circuit2_press  = hydpress_2;
    
    # in order to return what is working or not
    HYD1_press.setValue(hydpress_1);
    HYD2_press.setValue(hydpress_2);
    HYD1_deb.setValue(hydDeb_1 );
    HYD2_deb.setValue(hydDeb_2 );
    
    # if hydraulical system is not wrecked
    if(PWR)
    {
        Circuit1_Press.setValue(circuit1_press);
        Circuit2_Press.setValue(circuit2_press);
    }
}

var update_hydraulical = func
{
    var time = getprop("/sim/time/elapsed-sec");
    var dt = time - last_time;
    var last_time = time;
    update_virtual_circuits(dt);
    settimer(update_hydraulical, 1);
}

Hydraulical_init = func()
{
    settimer(update_hydraulical, 1);
    print("hydraulical System ... OK");
}
