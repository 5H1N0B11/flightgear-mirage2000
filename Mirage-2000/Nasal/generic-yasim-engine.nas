print("*** LOADING generic-yasim-engine.nas ... ***");
################################################################################
#
#             m2005-5's NASAL BASED ENGINE CONTROL SYSTEM FOR YASIM
#
################################################################################
#
# generic-yasim-engine.nas -- a generic Nasal-based engine control system for YASim
# Version 1.0.0
#
# Copyright (C) 2011  Ryan Miller
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

var UPDATE_PERIOD = 0.01; # update interval for engine init() functions

# jet engine class
var Jet =
{
    # creates a new engine object
    new: func(n,
        running = 0,
        idle_throttle = 0.01,
        max_start_n1 = 5.21,
        start_threshold = 3,
        spool_time = 4,
        start_time = 30,
        shutdown_time = 4,
        idleRPM = 4700)
    {
        # copy the Jet object
        var m = { parents: [Jet] };
        # declare object variables
        m.number = n;
        m.autostart_status = 0;
        m.autostart_id = -1;
        m.loop_running = 0;
        m.started = 0;
        m.starting = 0;
        m.idle_throttle = idle_throttle;
        m.max_start_n1 = max_start_n1;
        m.start_threshold = start_threshold;
        m.spool_time = spool_time;
        m.start_time = start_time;
        m.shutdown_time = shutdown_time;
        # create references to properties and set default values
        m.cutoff = props.globals.getNode("controls/engines/engine[" ~ n ~ "]/cutoff", 1);
        m.cutoff.setBoolValue(!running);
        m.n1 = props.globals.getNode("engines/engine[" ~ n ~ "]/n1", 1);
        m.n1.setDoubleValue(0);
        m.n2 = props.globals.getNode("engines/engine[" ~ n ~ "]/n2", 1);
        
        m.out_of_fuel = props.globals.getNode("engines/engine[" ~ n ~ "]/out-of-fuel", 1);
        m.out_of_fuel.setBoolValue(0);
        m.reverser = props.globals.getNode("controls/engines/engine[" ~ n ~ "]/reverser", 1);
        m.reverser.setBoolValue(0);
        m.rpm = props.globals.getNode("engines/engine[" ~ n ~ "]/rpm", 1);
        m.rpm.setDoubleValue(running ? 100 : 0);
        m.running = props.globals.getNode("engines/engine[" ~ n ~ "]/running", 1);
        m.running.setBoolValue(running);
        
        m.serviceable = props.globals.getNode("engines/engine[" ~ n ~ "]/serviceable", 1);
        m.serviceable.setBoolValue(1);
        m.throttle = props.globals.getNode("controls/engines/engine[" ~ n ~ "]/throttle", 1);
        m.throttle.setDoubleValue(0);
        m.throttle_lever = props.globals.getNode("controls/engines/engine[" ~ n ~ "]/throttle-lever", 1);
        m.throttle_lever.setDoubleValue(0);
        
        # 5H1N0B1's code
        
        # Fuel pressure ! if bp off, don't start, if bpg & bpd off ... on sarting but not runing
        m.bpg = props.globals.getNode("/systems/fuel/suppliers/FUEL1_press", 1);
        m.bpd = props.globals.getNode("/systems/fuel/suppliers/FUEL2_press", 1);
        m.bp  = props.globals.getNode("/systems/fuel/suppliers/BP_press", 1);
        
        # Oil Pressure !! if off, engine not running
        m.oil1 = props.globals.getNode("/systems/hydraulical/circuit1_press", 1);
        m.oil2 = props.globals.getNode("/systems/hydraulical/circuit2_press", 1);
        
        # Alt. When Amp 115 : Engine is running
        m.ALT1_Amp = props.globals.getNode("/systems/electrical/suppliers/ALT_1", 1);
        m.ALT2_Amp = props.globals.getNode("/systems/electrical/suppliers/ALT_2", 1);
        
        # Switches
        # Allumage = for starting Not running
        # Starter/demarrage = for starting Not running
        m.allumage = props.globals.getNode("/controls/switches/vent-allumage", 1);
        m.starter = props.globals.getNode("controls/engines/engine[" ~ n ~ "]/starter", 1);
        
        # Used here for the loop
        m.starting = 0;
        m.ending   = 0;
        m.aborting = 0;
        
        # Time management
        m.lasTime = 0;
        m.Time    = 0;
        
        # RPM idle & engine part
        m.rpmIdle = idleRPM;
        m.n1_Control = props.globals.getNode("/controls/engines/engine[" ~ n ~ "]/n1", 1);
        m.n1_Control.setDoubleValue(0);
        m.IsRunning = 0;
        
        # return our new object
        return m;
    },
    # engine-specific autostart
    autostart: func
    {
        if(getprop("sim/time/elapsed-sec") < 10)
        {
            return;
        }
        if(me.autostart_status)
        {
            me.autostart_status = 0;
            # Cut Off
            setprop("/controls/switches/hide-cutoff", 1);
            setprop("/controls/engines/engine/cutoff", 1);
        }
        else
        {
            me.autostart_status = 1;
            me.starter.setBoolValue(1);
            
            # Place here all the switch 'on' needed for the autostart
            
            # First electrics switchs
            setprop("/controls/switches/battery-switch",       1);
            setprop("/controls/switches/transformator-switch", 1);
            setprop("/controls/switches/ALT1-switch",          1);
            setprop("/controls/switches/ALT2-switch",          1);
            
            # Launching process
            # Cut Off
            setprop("/controls/switches/hide-cutoff",  0);
            setprop("/controls/engines/engine/cutoff", 0);
            # Fuel Pumps
            setprop("/controls/switches/pump-BPG", 1);
            setprop("/controls/switches/pump-BPD", 1);
            # This isn't a pump, but it's here is the starting process.
            # Vent is to clear fuel of the engine, allumage is to burn it.
            # So 1 is allumage 0 vent.
            setprop("/controls/switches/vent-allumage", 1);
            setprop("/controls/switches/pump-BP",       1);
            
            # Starter
            setprop("/controls/switches/hide-starter",  1);
            setprop("/controls/engines/engine/starter", 1);
            
            # This init the variable to start the engine
            # Just in case, uncomment this and, no need to wait 30 seconds before it start
            #me.rpm.setValue(4700);
            #me.n1_Control.setValue(47);
            #me.n1.setValue(47);
        }
    },
    
    # creates an engine update loop
    init: func
    {
        if(me.loop_running)
        {
            return;
        }
        me.loop_running = 1;
        var loop = func
        {
            me.update();
            settimer(loop, UPDATE_PERIOD);
        };
        settimer(loop, 0);
    },
    # updates the engine
    update: func
    {
        # We need time and will set rpm
        var rpm = me.rpm.getValue();
        me.Time  = getprop("sim/time/elapsed-sec");
        
        # What we need to start
        # bp        =  true
        # cutoff    =  false
        # allumage  =  true (<-if false mean 'ventilation' to blow out fuel of the jet, without burning it (shut off process))
        # starter   =  true starter launch the fan
        if(! me.cutoff.getBoolValue()
            and me.bp.getValue() > 1
            and me.allumage.getBoolValue()
            and ! me.aborting)
        {
            # Detect the start button
            # STARTER pressed
            if(me.starter.getBoolValue())
            {
                me.starting = 1;
                me.aborting = 0;
            }
            # if start button have been pressed, then start fan
            # STARTING
            if(me.starting or (rpm > 1100 and ! me.IsRunning))
            {
                # This is to simulate rpm rate increase
                rpm += ((me.Time - me.lasTime) / me.start_time) * me.rpmIdle;
                me.rpm.setValue(rpm);
                me.n1_Control.setValue(rpm / 100);
                me.n1.setValue(rpm / 100);
            }
            # STARTED
            if(me.rpm.getValue() > 4500 and ! me.IsRunning)
            {
                me.starting = 0;
                # To be in Running mode :
                me.IsRunning= 1;
                me.started = 1;
                me.starting = 0;
                me.starter.setBoolValue(0); # just in case of AutoStart
                UPDATE_PERIOD = 0.05;
            }
            # RUNNING
            if(me.IsRunning)
            {
                me.rpm.setValue(me.n1.getValue() * 100);
                me.n1_Control.setValue(me.n1.getValue());
            }
            else
            {
                me.throttle.setDoubleValue(0);
                me.throttle_lever.setDoubleValue(0);
            }
            # Need here an "aborting" procedure. in case of all pumps haven't been started.
            if(me.IsRunning
                and (me.bpg.getValue() < 0.5
                    or me.bpd.getValue() < 0.5
                    or me.bp.getValue() < 0.5
                    or (me.oil1.getValue() + me.oil2.getValue() < 140)
                ))
            {
                print("Bpg:", me.bpg.getValue(), " Bpd:", me.bpd.getValue(), " Bp:", me.bp.getValue(), " Oil:", me.oil1.getValue() + me.oil2.getValue());
                # Aborting
                me.aborting = 1;
            }
        }
        else
        {
            # STARTER pressed : aborting = 0
            if(me.starter.getBoolValue())
            {
                me.aborting = 0;
            }
            # Shut down pressed
            if(me.IsRunning or me.starting)
            {
                me.ending = 1;
                me.started = 0;
                me.IsRunning =0;
                me.starting = 0;
                me.endingTime = me.Time;
                UPDATE_PERIOD = 0.01;
            }
            # Shuting down
            if(me.ending)
            {
                rpm -= ((me.Time - me.lasTime)/me.shutdown_time) * me.rpmIdle;
                me.rpm.setValue(rpm);
                me.n1_Control.setValue(rpm/100);
                me.n1.setValue(rpm/100);
            }
            if(me.rpm.getValue() < 1)
            {
                me.ending = 0;
                me.rpm.setValue(0);
                me.n1_Control.setValue(0);
                me.n1.setValue(0);
            }
            # NOTHING : ENGINE DOWN
            me.throttle.setDoubleValue(0);
            me.throttle_lever.setDoubleValue(0)
        }
        
        # UPDATE VARIABLE
        me.n1.setValue(me.n1_Control.getValue());
        me.lasTime = me.Time;
        
        if(me.n1_Control.getValue() > 100)
        {
            me.n1_Control.setValue(100);
        }
        elsif(me.n1_Control.getValue() < 0)
        {
            me.n1_Control.setValue(0);
        }
    }
};
