print("*** LOADING m2000-5-flightdirector.nas ... ***");
################################################################################
#
#                 m2005-5's FLIGHT DIRECTOR/AUTOPILOT SETTINGS
#
################################################################################
# Syd Adams
# Adapte pour Mirage2000 03/2013

var RMI1src         = "/instrumentation/mfd/rmi-1-src";
var RMI2src         = "/instrumentation/mfd/rmi-2-src";
var Lateral         = "/autopilot/locks/heading";
var Lateral_arm     = "/autopilot/locks/heading-arm";
var Vertical        = "/autopilot/locks/altitude";
var Vertical_arm    = "/autopilot/locks/altitude-arm";
var AP              = "/autopilot/locks/AP-status";
var SPD             = "autopilot/locks/speed";
var NAVprop         = "/autopilot/settings/nav-source";
var NAVSRC          = getprop(NAVprop);
var DMEprop         = "/instrumentation/dme/frequencies/source";
var pitch_trim      = "/controls/flight/elevator-trim";
var roll_trim       = "/controls/flight/aileron-trim";
var count           = 0;
var count_1         = 0;
var count_AP_SRC    = 0;
var cycle_AP_SRC    = ["NAV1", "NAV2", "TACAN", "FMS"];
# var minimums        = getprop("/autopilot/settings/minimums");
var wx_range        = [10, 25, 50, 100, 200, 300];
var wx_index        = 3;
var deadZ_pitch     = 0.05;
var deadZ_roll      = 0.05;
var stick_pos       = 0;
var flag            = 0;

var init_set = func()
{
    setprop("/autopilot/settings/target-altitude-ft", 4000);
    setprop(RMI1src, "");
    setprop(RMI2src, "");
    settimer(update_fd, 5);
	wpAdvance.start();
}

# AP /FD BUTTONS
var FD_set_mode = func(btn)
{
    var Lmode  = getprop(Lateral);
    var LAmode = getprop(Lateral_arm);
    var Vmode  = getprop(Vertical);
    var VAmode = getprop(Vertical_arm);
    var SPmode = getprop(SPD);
    
    if(btn == "ap")
    {
        if(getprop(AP) != "AP1")
        {
            setprop(Lateral_arm, "");
            setprop(Vertical_arm, "");
            if(Vmode == "PTCH")
            {
                set_pitch();
            }
            if(Lmode == "ROLL")
            {
                set_roll();
            }
            if(getprop("/position/altitude-agl-ft") > getprop("/autopilot/settings/minimums"))
            {
                setprop(AP, "AP1");
            }
        }
        else
        {
            kill_Ap("<MINIMUM");
        }
    }
    elsif(btn == "hdg")
    {
        if(Lmode != "HDG")
        {
            setprop(Lateral, "HDG");
        }
        else
        {
            set_roll();
        }
        setprop(Lateral_arm, "");
        setprop(Vertical_arm, "");
    }
    elsif(btn == "alt")
    {
        setprop(Lateral_arm, "");
        setprop(Vertical_arm, "");
        if ((Vmode == "ALT") and (!getprop ("/instrumentation/tfs/malfunction")))
        {
            setprop (Vertical, "TF");
            var target = getprop ("/position/altitude-agl-ft");
            target = 50 * int (target / 50 + 0.5);
            setprop ("/autopilot/settings/target-altitude-ft", target);
            setprop ("/autopilot/settings/minimums", 0);
        }
        else if (Vmode == "TF")
        {
            set_pitch();
            var target = getprop ("/instrumentation/altimeter/mode-c-alt-ft");
            target = 100 * int (target / 100 + 0.5);
            setprop ("/autopilot/settings/target-altitude-ft", target);
            setprop ("/autopilot/settings/minimums", 200);
        }
        else
        {
            setprop(Vertical, "ALT");
            #setprop("/autopilot/settings/target-altitude-ft", getprop("/instrumentation/altimeter/mode-c-alt-ft"));
        }
    }
    elsif(btn == "nav")
    {
        set_nav_mode();
    }
    elsif(btn == "vnav")
    {
        if(Vmode != "VALT")
        {
            if(NAVSRC == "FMS")
            {
                setprop(Vertical, "VALT");
                setprop(Lateral, "LNAV");
            }
        }
        else
        {
            set_pitch();
        }
    }
    elsif(btn == "app")
    {
        setprop(Lateral_arm, "");
        setprop(Vertical_arm, "");
        set_apr();
    }
    elsif(btn == "stby")
    {
        setprop(Lateral_arm, "");
        setprop(Vertical_arm, "");
        set_pitch();
        set_roll();
    }
    elsif(btn == "spd")
    {
        if(SPmode != "SPD")
        {
            setprop(SPD, "SPD");
        }
        else
        {
            setprop(SPD, "");
        }
    }
    elsif(btn == "vs")
    {      
        if(Vmode != "VS")
        {
            setprop("/autopilot/settings/vertical-speed-fpm", getprop("/autopilot/internal/vert-speed-fpm"));
            setprop(Vertical, "VS");
        }
        else
        {
            set_pitch();
        }
    }
}

# FMS/NAV BUTTONS
# Selection of the Autopilot source
var nav_src_set = func()
{
    setprop(Lateral_arm, "");
    setprop(Vertical_arm, "");

    count_AP_SRC += 1;
    setprop(NAVprop, cycle_AP_SRC[math.mod(count_AP_SRC, 4)]);
}

# ARM VALID NAV MODE
var set_nav_mode = func() {
    setprop(Lateral_arm, "");
    setprop(Vertical_arm, "");
    if(NAVSRC == "NAV1")
    {
        if(getprop("/instrumentation/nav/data-is-valid"))
        {
            if(getprop("/instrumentation/nav/nav-loc"))
            {
                setprop(Lateral_arm, "LOC");
            }
            else
            {
                setprop(Lateral_arm, "VOR");
            }
            setprop(Lateral, "HDG");
        }
    }
    elsif(NAVSRC == "NAV2")
    {
        if(getprop("/instrumentation/nav[1]/data-is-valid"))
        {
            if(getprop("/instrumentation/nav[1]/nav-loc"))
            {
                setprop(Lateral_arm, "LOC");
            }
            else
            {
                setprop(Lateral_arm, "VOR");
            }
            setprop(Lateral, "HDG");
        }
    }
    elsif(NAVSRC == "TACAN")
    {
        if(getprop("/instrumentation/tacan/in-range"))
        {
            setprop(Lateral, "LNAV");
        }
    }
    elsif(NAVSRC == "FMS")
    {
        if(getprop("autopilot/route-manager/active"))
        {
            setprop(Lateral, "LNAV");
        }
    }
}

# PITCH WHEEL ACTIONS
var pitch_wheel = func(dir) {
    var Vmode = getprop(Vertical);
    var amt = 0;
    if(Vmode == "PTCH")
    {
        amt = getprop("/autopilot/settings/target-pitch-deg") + (dir * 0.1);
        amt = (amt < -20) ? -20 : (amt > 20) ? 20 : amt;
        setprop("/autopilot/settings/target-pitch-deg", amt)
    }
}

# FD INTERNAL ACTIONS
var set_pitch = func() {
    setprop(Vertical, "PTCH");
    var p_inst = getprop("/orientation/pitch-deg");
    if(p_inst < 0.5 and p_inst > -0.5)
    {
        setprop("/autopilot/settings/target-pitch-deg", 0);
    }
    else
    {
        setprop("/autopilot/settings/target-pitch-deg", p_inst);
    }
}

var set_roll = func() {
    var r_inst = getprop("/orientation/roll-deg");
    setprop(Lateral, "ROLL");
    if(r_inst < 1 and r_inst > -1)
    {
        setprop("/autopilot/settings/target-roll-deg", 0.0);
    }
    else
    {
        setprop("/autopilot/settings/target-roll-deg", r_inst);
    }
}

var set_apr = func() {
    if(NAVSRC == "NAV1")
    {
        if(getprop("/instrumentation/nav/nav-loc") and getprop("/instrumentation/nav/has-gs"))
        {
            setprop(Lateral_arm, "LOC");
            setprop(Vertical_arm, "GS");
            setprop(Lateral, "HDG");
        }
    }
    elsif(NAVSRC == "NAV2")
    {
        if(getprop("/instrumentation/nav[1]/nav-loc") and getprop("/instrumentation/nav[1]/has-gs"))
        {
            setprop(Lateral_arm, "LOC");
            setprop(Vertical_arm, "GS");
            setprop(Lateral, "HDG");
        }
    }
}

# setlistener("autopilot/settings/minimums", func(mn) {
#     minimums = mn.getValue();
# }, 1, 0);

setlistener(NAVprop, func(Nv) {
    NAVSRC = Nv.getValue();
}, 1, 0);

var update_nav = func() {
    var sgnl = "- - -";
    var gs = 0;
    
    if(NAVSRC == "NAV1")
    {
        if(getprop("/instrumentation/nav/data-is-valid"))
        {
            sgnl = "VOR1";
        }
        setprop("/autopilot/internal/in-range", getprop("/instrumentation/nav/in-range"));
        setprop("/autopilot/internal/gs-in-range", getprop("/instrumentation/nav/gs-in-range"));
        var dst = getprop("/instrumentation/nav/nav-distance") or 0;
        dst *= 0.000539;
        setprop("/autopilot/internal/nav-distance", dst);
        if(getprop("/instrumentation/nav/nav-id") != nil)
        {
            setprop("/autopilot/internal/nav-id", getprop("/instrumentation/nav/nav-id"));
        }
        if(getprop("/instrumentation/nav/nav-loc"))
        {
            sgnl = "LOC1";
        }
        if(getprop("/instrumentation/nav/has-gs"))
        {
            sgnl = "ILS1";
        }
        if(sgnl == "ILS1")
        {
            gs = 1;
        }
        setprop("/autopilot/internal/gs-valid", gs);
        setprop("/autopilot/internal/nav-type", sgnl);
        course_offset("/instrumentation/nav[0]/radials/selected-deg");
        setprop("/autopilot/internal/radial-selected-deg", getprop("/instrumentation/nav[0]/radials/selected-deg"));
        if((getprop("/instrumentation/gps/mode") == "obs")
            and (getprop("/instrumentation/nav/slaved-to-gps") == 1))
        {
            setprop("autopilot/internal/heading-needle-deflection", 0);
            setprop("autopilot/internal/to-flag", getprop("instrumentation/gps/wp/wp[1]/to-flag"));
            setprop("autopilot/internal/from-flag", getprop("instrumentation/gps/wp/wp[1]/from-flag"));
        }
        else
        {
            setprop("/autopilot/internal/heading-needle-deflection", getprop("/instrumentation/nav/heading-needle-deflection"));
            setprop("/autopilot/internal/to-flag", getprop("/instrumentation/nav/to-flag"));
            setprop("/autopilot/internal/from-flag", getprop("/instrumentation/nav/from-flag"));
            setprop(DMEprop, "/instrumentation/nav[0]/frequencies/selected-mhz");
        }
    }
    elsif(NAVSRC == "NAV2")
    {
        if(getprop("/instrumentation/nav[1]/data-is-valid"))
        {
            sgnl = "VOR2";
        }
        setprop("/autopilot/internal/in-range", getprop("/instrumentation/nav[1]/in-range"));
        setprop("/autopilot/internal/gs-in-range", getprop("/instrumentation/nav[1]/gs-in-range"));
        var dst = getprop("/instrumentation/nav[1]/nav-distance") or 0;
        dst *= 0.000539;
        setprop("/autopilot/internal/nav-distance", dst);
        setprop("/autopilot/internal/nav-id", getprop("/instrumentation/nav[1]/nav-id"));
        if(getprop("/instrumentation/nav[1]/nav-loc"))
        {
            sgnl = "LOC2";
        }
        if(getprop("/instrumentation/nav[1]/has-gs"))
        {
            sgnl = "ILS2";
        }
        if(sgnl == "ILS2")
        {
            gs = 1;
        }
        setprop("/autopilot/internal/gs-valid", gs);
        setprop("/autopilot/internal/nav-type", sgnl);
        course_offset("/instrumentation/nav[1]/radials/selected-deg");
        setprop("/autopilot/internal/radial-selected-deg", getprop("/instrumentation/nav[1]/radials/selected-deg"));
        setprop("/autopilot/internal/heading-needle-deflection", getprop("/instrumentation/nav[1]/heading-needle-deflection"));
        setprop("/autopilot/internal/to-flag", getprop("/instrumentation/nav[1]/to-flag"));
        setprop("/autopilot/internal/from-flag", getprop("/instrumentation/nav[1]/from-flag"));
        setprop(DMEprop, "/instrumentation/nav[1]/frequencies/selected-mhz");
    }
    elsif(NAVSRC == "TACAN")
    {
        if(getprop("/instrumentation/tacan/indicated-bearing-true-deg") != nil)
        {
            setprop("/autopilot/internal/in-range", getprop("/instrumentation/tacan/in-range"));
            var dst = getprop("/instrumentation/tacan/indicated-distance-nm") or 0;
            dst *= 0.000539; # <- dont know why but Ok
            setprop("/autopilot/internal/nav-distance", dst);
            setprop("/autopilot/internal/nav-id", getprop("instrumentation/tacan/ident"));
            
            course_offset("/instrumentation/tacan/indicated-bearing-true-deg");
            setprop("/autopilot/internal/radial-selected-deg", getprop("/instrumentation/tacan/indicated-bearing-true-deg"));
        }
    }
    elsif(NAVSRC == "FMS")
    {
        if(getprop("/autopilot/route-manager/wp/bearing-deg") != nil)
        {
            setprop("/autopilot/internal/nav-type", "FMS1");
            setprop("/autopilot/internal/in-range", 1);
            setprop("/autopilot/internal/gs-in-range", 0);
            setprop("/autopilot/internal/nav-distance", getprop("/autopilot/route-manager/wp/dist"));
            setprop("/autopilot/internal/nav-id", getprop("/autopilot/route-manager/wp/id"));
            course_offset("/autopilot/route-manager/wp/bearing-deg");
            setprop("/autopilot/internal/radial-selected-deg", getprop("/autopilot/route-manager/wp/bearing-deg"));
        }
    }
}

var set_range = func(dir) {
    wx_index += dir;
    if(wx_index > 5)
    {
        wx_index=5;
    }
    if(wx_index < 0)
    {
        wx_index=0;
    }
    setprop("/instrumentation/nd/range", wx_range[wx_index]);
}

var course_offset = func(src) {
    var crs_set = getprop(src);
    var crs_offset = crs_set - getprop("/orientation/heading-magnetic-deg");
    if(crs_offset > 180)
    {
        crs_offset -= 360;
    }
    if(crs_offset < -180)
    {
        crs_offset += 360;
    }
    setprop("/autopilot/internal/course-offset", crs_offset);
    crs_offset += getprop("/autopilot/internal/cdi");
    if(crs_offset > 180)
    {
        crs_offset -= 360;
    }
    if(crs_offset < -180)
    {
        crs_offset += 360;
    }
    setprop("/autopilot/internal/ap_crs", crs_offset);
    setprop("/autopilot/internal/selected-crs", crs_set);
}

var monitor_L_armed = func() {
    if(getprop(Lateral_arm) != "")
    {
        if(getprop("/autopilot/internal/in-range"))
        {
            var cdi = getprop("/autopilot/internal/cdi");
            if(cdi < 40 and cdi > -40)
            {
                setprop(Lateral, getprop(Lateral_arm));
                setprop(Lateral_arm, "");
            }
        }
    }
}

var monitor_V_armed = func() {
    var Varm = getprop(Vertical_arm);
    var myalt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
    var asel = getprop("/autopilot/settings/target-altitude-ft");
    var alterr = myalt-asel;
    if(Varm == "ASEL")
    {
        if(alterr > -250 and alterr < 250)
        {
            setprop(Vertical, "ALT");
            setprop(Vertical_arm, "");
        }
    }
    elsif(Varm == "VASEL")
    {
        if(alterr > -250 and alterr < 250)
        {
            setprop(Vertical, "VALT");
            setprop("/instrumentation/gps/wp/wp[1]/altitude-ft", asel);
            setprop(Vertical_arm, "");
        }
    }
    elsif(Varm == "GS")
    {
        if(getprop(Lateral) == "LOC")
        {
            if(getprop("/autopilot/internal/gs-in-range"))
            {
                var gs_err = getprop("/autopilot/internal/gs-deflection");
                var gs_dst = getprop("/autopilot/internal/nav-distance");
                if(gs_dst <= 12.0)
                {
                    if(gs_err > -0.15 and gs_err < 0.15)
                    {
                        setprop(Vertical, "GS");
                        setprop(Vertical_arm, "");
                        # minimums = 100; # mini 100ft si GS
                        setprop ("/autopilot/settings/minimums", 100);
                    }
                }
            }
        }
    }
}

# Tests PA-Limits
var monitor_AP_errors = func() {
    var ralt = getprop("/position/altitude-agl-ft");
    if(ralt < getprop("/autopilot/settings/minimums"))
    {
        kill_Ap("AP-<MINI-ALTITUDE");
    }
    var rlimit = getprop("/orientation/roll-deg");
    if(rlimit > 65 or rlimit < -65)
    {
        kill_Ap("AP-BANKLIMIT-FAIL");
    }
    var plimit = getprop("/orientation/pitch-deg");
    if(plimit > 30 or plimit < -30)
    {
        kill_Ap("AP-PITCHLIMIT-FAIL");
    }
}

# PA OFF
var kill_Ap = func(msg) {
    setprop(AP, msg);
    setprop(SPD, "");
    set_pitch();
    set_roll();
    flag = 0;
    
    #Trim management is done on SAS so put it to 0 cause strange behaviour
    #setprop(pitch_trim, 0);
    #setprop(roll_trim, 0);
}

# Temporarly disengage Autopilot when control stick steering
var pa_stb_off = func() {
    if(stick_pos == 1 and flag == 0)
    {
        setprop(AP, "TEMP DISENGAGE");
        setprop(Lateral, "");
        setprop(Vertical, "");
        flag = 1;
    }
}

# Re-engage Autopilot
var pa_stb_on = func() {
    if(stick_pos == 0 and flag == 1)
    {
        setprop(AP, "AP1");
        set_pitch();
        set_roll();
        flag = 0;
    }
}

# Main loop
var update_fd = func() {
    var elev_ctrl = getprop("/controls/flight/elevator");
    var roll_ctrl = getprop("/controls/flight/aileron");

    # Control stick position
    stick_pos = (elev_ctrl > deadZ_pitch
        or -deadZ_pitch > elev_ctrl
        or roll_ctrl > deadZ_roll
        or -deadZ_roll > roll_ctrl) ? 1 : 0;
    
    var L_mode = getprop(Lateral);
    var V_mode = getprop(Vertical);
    var pa_stat = getprop(AP);
    if(pa_stat == "AP1"
        and L_mode == "ROLL"
        and V_mode == "PTCH"
        and stick_pos == 1)
    {
        pa_stb_off();
    }
    if(pa_stat == "TEMP DISENGAGE"
        and L_mode == ""
        and V_mode == ""
        and stick_pos == 0)
    {
        pa_stb_on();
    }
    if (V_mode == "TF" and stick_pos == 1)
    {
        setprop (Vertical, "TEMP DISENGAGE");
    }
    elsif (V_mode == "TEMP DISENGAGE" and stick_pos == 0)
    {
        setprop (Vertical, "TF");
    }
    update_nav();
    if(count == 0)
    {
        monitor_AP_errors();
    }
    elsif(count == 1)
    {
        monitor_L_armed();
    }
    elsif(count == 2)
    {
        monitor_V_armed();
    }
    count += 1;
    if(count > 2)
    {
        count = 0;
    }
}

# Automatically moves the waypoint ahead at the calculated distance.
# Every time the waypoint changes, update the stored time
setlistener("/autopilot/route-manager/current-wp", func {
	setprop("/autopilot/internal/wp-change-time", getprop("/sim/time/elapsed-sec"));
});

# Calculates the optimum distance from waypoint to begin turning to next waypoint
var wpAdvance = maketimer(1, func {
	if (getprop("/autopilot/route-manager/route/num") > 0 and getprop("/autopilot/route-manager/active") == 1) {
		if ((getprop("/autopilot/route-manager/current-wp") + 1) < getprop("/autopilot/route-manager/route/num")) {
			gnds_mps = getprop("/velocities/groundspeed-kt") * 0.5144444444444;
			wp_fly_from = getprop("/autopilot/route-manager/current-wp");
			if (wp_fly_from < 0) {
				wp_fly_from = 0;
			}
			current_course = getprop("/autopilot/route-manager/route/wp[" ~ wp_fly_from ~ "]/leg-bearing-true-deg");
			wp_fly_to = getprop("/autopilot/route-manager/current-wp") + 1;
			if (wp_fly_to < 0) {
				wp_fly_to = 0;
			}
			next_course = getprop("/autopilot/route-manager/route/wp[" ~ wp_fly_to ~ "]/leg-bearing-true-deg");

			delta_angle = math.abs(geo.normdeg180(current_course - next_course));
			max_bank = delta_angle * 1.5;
			max_bank_limit = getprop("/it-fbw/ap/max-roll");
			if (max_bank > max_bank_limit) {
				max_bank = max_bank_limit;
			}
			radius = (gnds_mps * gnds_mps) / (9.81 * math.tan(max_bank / 57.2957795131));
			time = 0.64 * gnds_mps * delta_angle * 0.7 / (360 * math.tan(max_bank / 57.2957795131));
			delta_angle_rad = (180 - delta_angle) / 114.5915590262;
			R = radius/math.sin(delta_angle_rad);
			dist_coeff = delta_angle * -0.011111 + 2;
			if (dist_coeff < 1) {
				dist_coeff = 1;
			}
			turn_dist = math.cos(delta_angle_rad) * R * dist_coeff / 1852;
			if (getprop("/gear/gear[0]/wow") == 1 and turn_dist < 1) {
				turn_dist = 1;
			}
			setprop("/autopilot/route-manager/advance", turn_dist);
			if (getprop("/sim/time/elapsed-sec")-getprop("/autopilot/internal/wp-change-time") > 60) {
				setprop("/autopilot/internal/wp-change-check-period", time);
			}
			
			if (getprop("/autopilot/route-manager/wp/dist") <= turn_dist) {
				setprop("/autopilot/route-manager/current-wp", getprop("/autopilot/route-manager/current-wp") + 1);
			}
		}
	}
});
