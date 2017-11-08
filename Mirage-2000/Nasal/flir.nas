# Copyright (C) 2016  onox
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Position of the FLIR camera ([z (back), x (right), y (up)])
var coords_cam = [
    getprop("/sim/view[102]/config/z-offset-m"),
    getprop("/sim/view[102]/config/x-offset-m"),
    getprop("/sim/view[102]/config/y-offset-m")
];

var FLIRCameraUpdater = {

    new: func {
        var m = {
            parents: [FLIRCameraUpdater, updateloop.Updatable]
        };
        m.loop = updateloop.UpdateLoop.new(components: [m], update_period: 0.0);

        # Create a function to update the position of the FLIR camera
        m.update_cam = me._get_flir_auto_updater(180.0);

        # Create a function to update the position using an input device
        m.manual_update_cam = me._get_flir_updater(180.0, m.update_cam);

        m.click_coord_cam = nil;

        m.listeners = std.Vector.new();

        return m;
    },

    enable: func {
        me.loop.reset();
        me.loop.enable();
    },

    disable: func {
        me.remove_listeners();
        me.loop.disable();
    },

    enable_or_disable: func (enable) {
        if (enable) {
            me.enable();
        }
        else {
            me.disable();
        }
    },

    remove_listeners: func {
        foreach (var listener; me.listeners.vector) {
            removelistener(listener);
        }
        me.listeners.clear();
    },

    reset: func {
        me.remove_listeners();
        me.listeners.append(setlistener("/sim/signals/click", func {
            var lat = getprop("/sim/input/click/latitude-deg");
            var lon = getprop("/sim/input/click/longitude-deg");
            var elev = getprop("/sim/input/click/elevation-m");

            var click_position = geo.Coord.new().set_latlon(lat, lon, elev);

            var origin_position = geo.aircraft_position();
            var distance_m = origin_position.direct_distance_to(click_position);

            if (getprop("/aircraft/flir/locks/auto-track")) {
                me.click_coord_cam = click_position;
                setprop("/aircraft/flir/target/auto-track", 1);
                logger.screen.white(sprintf("New tracking position at %d meter distance", distance_m));
            }
            else {
                setprop("/aircraft/flir/target/auto-track", 0);
                me.click_coord_cam = nil;
                logger.screen.red("Press F6 to enable automatic tracking by FLIR camera");
            }
        }));

        me.listeners.append(setlistener("/aircraft/flir/locks/auto-track", func (n) {
            setprop("/aircraft/flir/target/auto-track", 0);
            me.click_coord_cam = nil;
            if (n.getBoolValue()) {
                logger.screen.green("Automatic tracking by FLIR camera enabled. Click on the terrain to start tracking.");
            }
            else {
                logger.screen.red("Automatic tracking by FLIR camera disabled");
            }
        }));
    },

    update: func (dt) {
        var roll_deg  = getprop("/orientation/roll-deg");
        var pitch_deg = getprop("/orientation/pitch-deg");
        var heading   = getprop("/orientation/heading-deg");

        var computer = me._get_flir_computer(roll_deg, pitch_deg, heading);

        if (getprop("/aircraft/flir/target/auto-track") and me.click_coord_cam != nil) {
            var (yaw, pitch, distance) = computer(coords_cam, me.click_coord_cam);
            me.update_cam(roll_deg, pitch_deg, yaw, pitch);
        }
#        else {
#            me.manual_update_cam(roll_deg, pitch_deg);
#        }
    },

    ######################################################################
    # Gyro stabilization                                                 #
    ######################################################################

    _get_flir_updater: func (offset, updater) {
        return func (roll_deg, pitch_deg) {
            var yaw   = getprop("/aircraft/flir/input/yaw-deg") + (180.0 - offset);
            var pitch = getprop("/aircraft/flir/input/pitch-deg");

            updater(roll_deg, pitch_deg, yaw, pitch);
        };
    },

    ######################################################################
    # Automatic tracking computation                                     #
    ######################################################################

    _get_flir_auto_updater: func (offset) {
        return func (roll_deg, pitch_deg, yaw, pitch) {
            (yaw, pitch) = math_ext.get_yaw_pitch_body(roll_deg, pitch_deg, yaw, pitch, offset);

            setprop("/aircraft/flir/target/yaw-deg", yaw);
            setprop("/aircraft/flir/target/pitch-deg", pitch);

            setprop("/sim/current-view/goal-heading-offset-deg", -yaw);
            setprop("/sim/current-view/goal-pitch-offset-deg", pitch);
        };
    },

    _get_flir_computer: func (roll_deg, pitch_deg, heading) {
        return func (coords, target) {
            var (position_2d, position) = math_ext.get_point(coords[0], coords[1], coords[2], roll_deg, pitch_deg, heading);
            return math_ext.get_yaw_pitch_distance_inert(position_2d, position, target, heading);
        }
    }

};

var flir_updater = FLIRCameraUpdater.new();

setlistener("/sim/signals/fdm-initialized", func {
    setlistener("/aircraft/flir/target/view-enabled", func (node) {
        flir_updater.enable_or_disable(node.getBoolValue());
    }, 1, 0);
});
