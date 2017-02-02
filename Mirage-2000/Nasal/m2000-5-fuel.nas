print("*** LOADING m2000-5-fuel.nas ... ***");
################################################################################
#
#                     m2005-5's FUEL SYSTEM SETTINGS
#
################################################################################

var last_time       = 0.0;
var FUEL1_deb       = props.globals.getNode("/systems/fuel/suppliers/FUEL1_deb", 1);
var FUEL1_press     = props.globals.getNode("/systems/fuel/suppliers/FUEL1_press", 1);
var FUEL2_deb       = props.globals.getNode("/systems/fuel/suppliers/FUEL2_deb", 1);
var FUEL2_press     = props.globals.getNode("/systems/fuel/suppliers/FUEL2_press", 1);
var BP_deb          = props.globals.getNode("/systems/fuel/suppliers/BP_deb", 1);
var BP_press        = props.globals.getNode("/systems/fuel/suppliers/BP_press", 1);
var Circuit1_Press  = props.globals.getNode("/systems/fuel/circuit1_press", 1);
var Volts           = props.globals.getNode("/systems/electrical/volts", 1);
# Make it servicable
props.globals.getNode("/systems/fuel/serviceable", 1).setBoolValue(1);
var PWR             = props.globals.getNode("/systems/fuel/serviceable", 1).getBoolValue();
var fuelTankTotal   = props.globals.getNode("/consumables/fuel/total-fuel-kg");

# Definition of the pump
# pressure in bars 1 bar =100 kPa = 100/6.89 PSI = 100kn/m^2
# deb in l/mn
# var alternator = Alternator.new("rpm-source", rpm_threshold, pressure, deb, volts_threshold);
FUELPUMP = {
    new: func()
    {
        m = { parents : [FUELPUMP] };
        m.rpm_source = props.globals.getNode(arg[0], 1);
        m.rpm_threshold = arg[1];
        m.ideal_bars = arg[2];
        m.ideal_deb = arg[3]; # l/mn
        m.volts_threshold = arg[4];
        return m;
    },
    get_output_bars_engine: func()
    {
        var factor = me.rpm_source.getValue() / me.rpm_threshold;
        if(factor > 1.0)
        {
            factor = 1.0;
        }
        return me.ideal_bars * factor;
    },
    get_output_bars_electric: func()
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
    get_output_deb_engine: func()
    {
        var factor = me.rpm_source.getValue() / me.rpm_threshold;
        if(factor > 1.0)
        {
            factor = 1.0;
        }
        return me.ideal_deb * factor;
    },
    get_output_deb_electric: func()
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

FUELTANK = {
    new: func()
    {
        m = { parents : [FUELTANK] };
        m.interal = arg[0];
        m.Tankid = arg[1];
        m.weightId = arg[2];
        return m;
    },
    get_Level: func()
    {
    }
};

# Definition of pumps caracteristics
var fuel_1 = FUELPUMP.new("/engines/engine[0]/rpm", 1500.0, 3, 110.0, 28);
var fuel_2 = FUELPUMP.new("/engines/engine[0]/rpm", 1500.0, 3, 109.0, 28);
var fuel_BP = FUELPUMP.new("/engines/engine[0]/rpm", 1500.0, 3, 108.0, 28);

Fuel_init = func()
{
    settimer(update_fuel, 1);
    print("fuel System ... OK");
}

var update_virtual_circuits = func(dt)
{
    var Tank = fuelTankTotal.getValue();
    var fuelpress_1 = fuel_1.get_output_bars_engine();
    var fuelpress_2 = fuel_2.get_output_bars_engine();
    var BPpress = fuel_BP.get_output_bars_electric();
#    fuelpress_1 = (fuelpress_1 == "nil") ? 0 : fuelpress_1;
    fuelpress_1 = (fuelpress_1 == nil) ? 0 : fuelpress_1;
#    fuelpress_2 = (fuelpress_2 == "nil") ? 0 : fuelpress_2;
    fuelpress_2 = (fuelpress_2 == nil) ? 0 : fuelpress_2;
#    BPpress = (BPpress == "nil") ? 0 : BPpress;
    BPpress = (BPpress == nil) ? 0 : BPpress;
    var circuit1_press = fuelpress_1;
    
    # in order to return what is working or not
    if(getprop("/controls/switches/pump-BPG") and (Tank > 100))
    {
        FUEL1_press.setValue(fuelpress_1);
    }
    else
    {
        FUEL1_press.setValue(0);
    }
    if(getprop("/controls/switches/pump-BPD") and (Tank > 100))
    {
        FUEL2_press.setValue(fuelpress_2);
    }
    else
    {
        FUEL2_press.setValue(0);
    }
    if(getprop("/controls/switches/pump-BP") and (Tank > 100))
    {
        BP_press.setValue(BPpress);
    }
    else
    {
        BP_press.setValue(0);
    }
    # if hydraulical system not wrecked
    if(PWR)
    {
        Circuit1_Press.setValue(circuit1_press);
    }
}

var update_fuel = func
{
    var time = getprop("/sim/time/elapsed-sec");
    var dt = time - last_time;
    var last_time = time;
    update_virtual_circuits(dt);
    settimer(update_fuel, 1);
}
