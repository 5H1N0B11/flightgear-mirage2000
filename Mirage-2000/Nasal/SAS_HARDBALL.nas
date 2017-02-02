print("*** LOADING SAS.nas ... ***");
################################################################################
#
#                   m2005-5's STABILITY AUGMENTATION SYSTEM
#
################################################################################


#===============================================================================
#                                                                      CONSTANTS

var reduction_of_efficiency_for_speed     = 2.5;
var reduction_of_efficiency_for_altitude  = 3.5;
var reduction_of_efficiency_for_gear_down = 0.8;
var reduction_of_efficiency_for_airbrakes = 2.8;

var optimal_speed                 = 400;   # kts
var range_speed                   = 150;   # kts
var optimal_altitude              = 0;     # ft
var range_altitude                = 30000; # ft

var max_autorized_gload           = 9;    # G
var min_autorized_gload           = -3.5;    # G
var max_autorized_aoa             = 20;    # deg
var min_autorized_aoa             = -5;    # deg
var max_roll_rate                 = 190;   # deg/sec

#===============================================================================
#                                                                 INITIALISATION

# Inputs
var RawPitch    = props.globals.getNode("controls/flight/elevator");
var RawRoll     = props.globals.getNode("controls/flight/aileron");
var RawYaw      = props.globals.getNode("controls/flight/rudder");

# Outputs
var SasRoll      = props.globals.getNode("controls/flight/SAS-roll", 1);
var SasPitch     = props.globals.getNode("controls/flight/SAS-pitch", 1);
var SasYaw       = props.globals.getNode("controls/flight/SAS-yaw", 1);
var SasGear      = props.globals.getNode("controls/flight/SAS-gear", 1);

# Orientation and velocities
#var GroundSpeed  = props.globals.getNode("velocities/groundspeed-kt");
#var mach         = props.globals.getNode("velocities/mach");
#var slideDeg     = props.globals.getNode("orientation/side-slip-deg");

var AirSpeed     = props.globals.getNode("velocities/airspeed-kt");
var Altitude     = props.globals.getNode("instrumentation/altimeter/indicated-altitude-ft");
var RollRate     = props.globals.getNode("orientation/roll-rate-degps");
var PitchRate    = props.globals.getNode("orientation/pitch-rate-degps", 1);
var YawRate      = props.globals.getNode("orientation/yaw-rate-degps", 1);

var Brakes       = props.globals.getNode("surface-positions/spoiler-pos-norm", 1);
var Gears        = props.globals.getNode("gear/gear/position-norm", 1);

var buffer_input_pitch  = 0;
var buffer_pitch = 1;
var buffer_input_roll   = 0;

#===============================================================================
#                                                                      FUNCTIONS

#-------------------------------------------------------------------------------
#                                                        keep_in_flight_envelope
# this function keeps input values in flight envelope
# if some values (gload, aoa, roll rate) are exceded, buffered input values are
# returned
var keep_in_flight_envelope = func(input_pitch, input_roll) {

    var keep_pitch = keep_in_flight_envelope_pitch();
    
    if(keep_pitch != 0)
    {
        input_pitch = (abs(input_pitch) < abs(buffer_input_pitch)) ? input_pitch : buffer_input_pitch;
        printf("KEEP PITCH input:%.4f - buffer_input:%.4f", input_pitch, buffer_input_pitch);
    }
    else
    {
        buffer_input_pitch = input_pitch;
        #printf("OK   PITCH input:%.4f - buffer_input:%.4f", input_pitch, buffer_input_pitch);
    }

    var keep_roll = keep_in_flight_envelope_roll(input_roll);
    if(keep_roll != 0)
    {
        input_roll = (abs(input_roll) < abs(buffer_input_roll)) ? input_roll : buffer_input_roll;
        printf("KEEP ROLL input:%.4f - buffer_input:%.4f", input_roll, buffer_input_roll);
    }
    else
    {
        buffer_input_roll = input_roll;
        #printf("OK   ROLL input:%.4f - buffer_input:%.4f", input_roll, buffer_input_roll);
    }
    var out = [input_pitch, input_roll];
    return out;
}

#-------------------------------------------------------------------------------
#                                                  keep_in_flight_envelope_pitch
# this function tests gload and aoa and decides if the pitch should be
# restricted
var keep_in_flight_envelope_pitch = func() {
    var out = 0;
    var current_aoa   = getprop("/orientation/alpha-deg");
    var current_gload = getprop("/accelerations/pilot-g");
    if((current_aoa > max_autorized_aoa) or (current_gload > max_autorized_gload))
    {
        out = 1;
    }
    elsif((current_aoa < min_autorized_aoa) or (current_gload < min_autorized_gload))
    {
        out = -1;
    }
    return out;
}
#-------------------------------------------------------------------------------
#                                                   keep_in_flight_envelope_roll
# this function tests roll rate and decides if the roll should be restricted
var keep_in_flight_envelope_roll = func(input_roll) {
    var out = 0;
    var RollRate          = props.globals.getNode("orientation/roll-rate-degps");
    var current_roll_rate = RollRate.getValue();
    if(abs(current_roll_rate) > max_roll_rate)
    {
        out = (input_roll < 0) ? -1 : 1;
    }
    return out;
}

#-------------------------------------------------------------------------------
#                                         reduce_efficiency_due_to_configuration
# this function returns a factor depending of current configuration (gear down
# or airbrakes deployed)
var reduce_efficiency_due_to_configuration = func() {
# todo : missiles, etc
# todo object gear
    var is_gear_down      = Gears.getValue();
    var is_airbrakes_open = Brakes.getValue();

    var factor = 0;
    factor += (is_gear_down) ? reduction_of_efficiency_for_gear_down : 0;
    factor += (is_airbrakes_open) ? reduction_of_efficiency_for_airbrakes : 0;

    #printf("--- FACTOR CONFIG:%.6f", factor);
    return factor
}

#-------------------------------------------------------------------------------
#                                                 reduce_efficiency_due_to_speed
# this function returns a factor depending of current speed
var reduce_efficiency_due_to_speed = func() {
    var current_speed = AirSpeed.getValue();

    var min = (range_speed > optimal_speed) ? 0 : optimal_speed - range_speed;
    var max = optimal_speed + range_speed;

    var factor = reduction_of_efficiency_for_speed;
    if((current_speed >= optimal_speed and current_speed < max)
        or(current_speed < optimal_speed and current_speed > min))
    {
        factor = abs(((reduction_of_efficiency_for_speed * current_speed) / range_speed) - (reduction_of_efficiency_for_speed * (optimal_speed / range_speed)));
    }

    #printf("--- FACTOR SPEED:%.6f - CURRENT SPEED:%.6f", factor, current_speed);
    return factor
}

#-------------------------------------------------------------------------------
#                                              reduce_efficiency_due_to_altitude
# this function returns a factor depending of current altitude
var reduce_efficiency_due_to_altitude = func() {
    var current_altitude  = Altitude.getValue();
    var min = (range_altitude > optimal_altitude) ? 0 : optimal_altitude - range_altitude;
    var max = optimal_altitude + range_altitude;

    var factor = reduction_of_efficiency_for_altitude;
    if((current_altitude >= optimal_altitude and current_altitude < max)
        or(current_altitude < optimal_altitude and current_altitude > min))
    {
        factor = abs(((reduction_of_efficiency_for_altitude * current_altitude) / range_altitude) - (reduction_of_efficiency_for_altitude * (optimal_altitude / range_altitude)));
    }

    #printf("--- FACTOR ALTITUDE:%.6f - CURRENT ALTITUDE:%.6f", factor, current_altitude);
    return factor
}

#-------------------------------------------------------------------------------
#                                                               modify_stability
# this function modifies command effect 
var modify_stability = func(input) {

    var factor = 3;

    factor += reduce_efficiency_due_to_speed();
    factor += reduce_efficiency_due_to_altitude();
    factor += reduce_efficiency_due_to_configuration();

    var output = ((input * 2) * (input * 2)) / factor; # f(x) = ((x * 2) ^ 2) / 3
    output = (input < 0) ? -output : output;

    output = (output < -1) ? -1 : (output > 1) ? 1 : output;
    return output;
}

#-------------------------------------------------------------------------------
#                                                                enable_commands
# this function is used when the engine is started
var enable_commands = func(pitch, roll, yaw) {
    var oilpress = getprop("/systems/hydraulical/circuit1_press");
    if(oilpress <= 100)
    {
        pitch = buffer_pitch;
        roll = 0;
        yaw = 0;
    }
    elsif(oilpress > 100 and oilpress <= 200)
    {
        buffer_pitch -= (buffer_pitch > 0) ? 0.01 : 0;
        pitch = buffer_pitch;
    }
    var out = [pitch, roll, yaw];
    return out;
}

#-------------------------------------------------------------------------------
#                                                                 stall_detector
#
# @TODO : Stall warning ! should be in instruments
var stall_detector = func() {
    var stallwarning = "0";
    var current_aoa = getprop("/orientation/alpha-deg");
    if(getprop("/gear/gear[2]/wow") == 0)
    {
        # STALL ALERT !
        if((current_aoa >= 29) or (AirSpeed.getValue() < 100))
        {
            stallwarning = "2";
        }
        # STALL WARNING
        elsif((current_aoa >= 20) or (AirSpeed.getValue() < 130))
        {
            stallwarning = "1";
        }
    }
    setprop("/sim/alarms/stall-warning", stallwarning);
}

#-------------------------------------------------------------------------------
#                                                                 thrust_manager
#
# Should be on the engine part !
# finally nope : The engine have a computer driven throttle
# Could be changed here without touching yasim props
var thrust_manager = func() {
    var reheatlimit = 85;
    var reheat = (getprop("/controls/engines/engine[0]/n1") >= reheatlimit)
        ? (getprop("/controls/engines/engine[0]/n1") - reheatlimit) / (100 - reheatlimit)
        : 0;
    setprop("/controls/engines/engine[0]/reheat", reheat);
}

#-------------------------------------------------------------------------------
#                                                                  slats_manager
#
# To calculate the best slats position
var slats_manager = func() {
    var current_aoa = getprop("/orientation/alpha-deg");
    if(getprop("/controls/gear/gear-down") == 0)
    {
        var slats = 0;
        if(current_aoa >= 2)
        {
            var current_gload = getprop("/accelerations/pilot-g");
            if(current_gload < 9)
            {
                var slats = (current_aoa - 3) / 6;
            }
        }
        setprop("/controls/flight/flaps", slats);
    }
}

#-------------------------------------------------------------------------------
#                                                                     computeSAS
#
var computeSAS = func() {

    # we are getting the input values (pilot's controls)
    var input_pitch  = RawPitch.getValue();
    var input_roll   = RawRoll.getValue();
    var input_yaw    = RawYaw.getValue();

    # we are correcting theese values to keep the aircraft in flight envelope
    var inputs = keep_in_flight_envelope(input_pitch, input_roll);
    input_pitch = inputs[0];
    input_roll = inputs[1];

    # the ouput (aircraft's gouverns) equals the input (pilot's controls)
    var output_pitch = input_pitch;
    var output_roll  = input_roll;
    var output_yaw   = input_yaw;

    # in manual mode, the stability is improved (more precise on the center
    # of the controls and depends on speed, altitude, configuration)
    if(getprop("/autopilot/locks/AP-status") != "AP1")
    {
        output_pitch = modify_stability(output_pitch);
        output_roll  = modify_stability(output_roll);
        output_yaw   = modify_stability(output_yaw);
    }

    # other controls managers
    thrust_manager();
    stall_detector();
    slats_manager();

    # starting
    var outputs = enable_commands(output_pitch, output_roll, output_yaw);
    output_pitch = outputs[0];
    output_roll = outputs[1];
    output_yaw = outputs[2];

    SasPitch.setValue(output_pitch);
    SasRoll.setValue(output_roll);
    SasYaw.setValue(output_yaw);
    SasGear.setValue(output_yaw);

    SAS_Loop_running = 0;

    #printf("PITCH %.4f:%.4f - ROLL %.4f:%.4f - YAW %.4f:%.4f", input_pitch, output_pitch, input_roll, output_roll, input_yaw, output_yaw);

}


#-------------------------------------------------------------------------------
#                                                                           trim
#
# elevator Trim
#var ElevatorTrim = props.globals.getNode("controls/flight/elevator-trim", 1);
#var t_increment  = 0.0075;
#if(ElevatorTrim.getValue() != nil)
#{
#    e_trim = ElevatorTrim.getValue();
#}
#var trimUp = func() {
#    e_trim += (airspeed < 120.0) ? t_increment : t_increment * 14400 / airspeed_sqr;
#    if(e_trim > 1)
#    {
#        e_trim = 1;
#    }
#    ElevatorTrim.setValue(e_trim);
#}
#var trimDown = func() {
#    e_trim -= (airspeed < 120.0) ? t_increment : t_increment * 14400 / airspeed_sqr;
#    if(e_trim < -1)
#    {
#        e_trim = -1;
#    }
#    ElevatorTrim.setValue(e_trim);
#}

#-------------------------------------------------------------------------------
#                                                                       init_SAS
#
# SAS initialisation
var init_SAS = func() {
}

#-------------------------------------------------------------------------------
#                                                                     Update_SAS
#
# SAS double running avoidance
var Update_SAS = func() {
    if(SAS_Loop_running == 0)
    {
        SAS_Loop_running = 1;
        computeSAS();
    }
}
