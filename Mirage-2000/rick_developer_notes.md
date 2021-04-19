
<!-- ========================================================================================= -->

## Notes ##
* Based on the JA37. The readme.ja37.txt has a good explanation for the pilot.

## Todo ##
* Enable the different ways the cursor works like in the JA37: <stick-controls-cursor type="bool"> and <arrows-controls-cursor ...
* Enable the cursor to work on the VTB instead of VTM by switch
* Copy the stuff which make the joystick config behave for cursor. In JA37 look for: button-axis-config, button-config


<!-- ========================================================================================= -->
# Various knowledge points #
## File structure ##

/m2000-5-set.xml:
* /Systems/m2000-common.xml:
  * /Systems/rotors.xml: declares MP props misused by OPRF for radar etc.
  * /Systems/payload.xml: all the weapons
  * /Systems/rendering.xml: red-out
  * /Systems/sim.xml:
    * multiplay props
    * submodels -> Aircraft/Mirage-2000/Models/Effects/guns/submodels.xml
    * help -> help.xml
    * menubar -> ../Dialogs/m2000-menu.xml"
    * weights per weapon per station
  * /Systems/systems.xml:
    * autopilot -> Aircraft/Mirage-2000/Systems/Mirage-2000-autopilot.xml
  * and a lot of other .xml
  * <nasal> tag: references all .nas files across directories and give them one name each

## Interesting properties ##

* payload/armament/msg: 0 = no damage, 1 = damage


<!-- ========================================================================================= -->
# Radar #

## Knowledge: Radar core system which is used in displays ##
* Systems/cnf-instrumentation.xml -> <radar> properties inkl. e.g. <radar-standby> ->/instrumentation/radar/radar-standby


## Radar stuff todo ##
* Constrain radar to only collect max 28 contacts
* me.debug = getprop("debug-radar/debug-main");
* Update tacview.nas ca. line 34 for - because it is F-16 specific
  * return radar_system.getCompleteList();
  * return radar_system.apg68Radar.getPriorityTarget();
* Radar enable should follow F-16 (return getprop("/f16/avionics/power-fcr-bit") == 2 and getprop("instrumentation/radar/radar-enable") and !getprop("instrumentation/radar/ovrd") and getprop("instrumentation/radar/serviceable") and !getprop("/fdm/jsbsim/gear/unit[0]/WOW");
  * Same in RWR scan method
* Implement radar power modes: Arrêt (Off), Préchauffage (WARM-UP), Silence (STANDBY), Émission (On - Emit) - see Chucks 2000C guide page 107. Currently radar-standby makes the screen to not getting power anymore, so effectively no STANDBY mode at all on the screen
* Check keybindings H (active target seeking) and Q (active ECM): do they still work? <key n="81"><name>Q</name><desc>Active ECM</desc><binding><command>nasal</command><script>instrumentation.activate_ECM()</script></binding></key>
* We need a steerpoints implementation
* check whether datalink works


<!-- ========================================================================================= -->
# RWR #

## Design ##
* Source:
  * DCS Mirage 2000C: https://forum.dcs.world/topic/244681-rwr-update/
  * Etendard SEM pictures:
* -> blue inner circle from DCS Mirage, outer white circles and white cross from SEM

## TODO ##
* Use French symbology from DCS or elsewhere

<!-- ========================================================================================= -->
# VTM #

## Todo VTM better ##
* Radar scanning/disc movement indication
* Weapons available
* Make sure DLINK stuff is understood and IFF is implemented.
* Work with settimer, setlistener for stuff which does not change often - e.g. radar-standby
* toggle screen on/off depending on /instrumentation/radar/radar-standby (1 means radar is working, 0 it is off - the property should be renamed of true/false switched). Maybe show a text on the HUD and the VTM that it is stand-by
* Add a shader to simulate a bit of glass reflections

## Reference ##
* https://forum.dcs.world/topic/209641-mirage-radar-under-rework/: has picture of 2000C VTB, which show that depending on situation different colors are used (not only green or orange)


<!-- ========================================================================================= -->
# Copied files #
## OPRF Files ##

Updated last time on 2025-09-28 from https://github.com/Op-RedFlag/OpRedFlag

| Area                  | Commit               | Files not yet converted | Deviations |
| ----------------------| -------------------- | ------------------------| ---------- |
| emesary-damage-system | 108ff45 (2024-10-28) | n/a | /payload.xml/armament/models points to Aircraft/Mirage-2000/Missiles/ instead of ./Models/emesary/. missile-code.nas has currently custom stuff for extra height |
| libraries             | 95f2ca5 (2025-02-07) | n/a | There is an additional custom file for m2000: iff_m2000.nas. The last ca. 10 lines of fire-control.nas is adapted for M2000 |
| radar                 | 7a7d871 (2025-09-25) | n/a | rcs.nas is missing in the OPRF library -> copied from F-16 |
| assets                | 95f2ca5 (2025-02-07) | n/a | not used - using fire-control.nas from libraries |


## F16 files ##
If changes have been made to the file, then they are marked with ADAPT_TO_M2000
* Nasal/radar/apg-68.nas
* Nasal/rwr.nas
* Nasal/M_frame_notification.nas

<!-- ========================================================================================= -->
# Smaller features / issues #
* Reload Guns etc. button from config menu should either be included in Payload stuff or make sure that guns are only loaded if there is a cannon in e.g. the 2000-D
* ALS rocket like the Viggen guide on stick: in JA37 look for <pure_gain name="names/cursor/rb05-control-yaw">
* In VTM._updateTargets: can we use blep info instead of calulation like in viggen: var info = contact.getLastBlep(); var pos = ..(info.getAZDeviation(), info.getRangeNow(),..);
* Alidade cartouche in top right corner: what is "N"?


<!-- ========================================================================================= -->
# Tidy up #
* remove Aircraft/Mirage-2000/Models/Interior/Instruments/hud/hud.xml etc. once we are sure that it revi has replaced it
* remove radar.xml once we have a canvas VTM
* Remove references to myRadar3 - even if commented out
* Remove MP.nas and dynamic links from e.g. m2000-5.xml
* Nasal:
  * why do we need math_ext and logger namespaces (from C172)?
  * remove commented out namespaces and delete related files
  * Merge exec.nas with M_frame_notification.nas
  * Move MFD/*nas into displays folder
* Use the display power on/off logic in JA37 displays/common.nas
* Exocet and Mica-EM deviate visually from what really happens (hits vs. miss)
* Why is there the following instead of fall time from weapon props? TimeToTarget   :"/sim/dialog/groundTargeting/time-to-target",
* In HUD.nas check use of input.IsRadarWorking.getValue()>24 and similar


<!-- ========================================================================================= -->
# Performance Stuff #
See also https://wiki.flightgear.org/Nasal_optimisation for general instructions

## FrameNotifications ##

* See Aircraft/Mirage-2000/Nasal/exec.nas (part of module mirage2000): defines a loop for sending out FrameNotificationAddProperty including e.g. /sim/time/elapsed-sec with a rate depending on current frame rate (the better the fps the more notifications). The rtExec_loop is called to start from m2000-5.nas._mainInitLoop()
* See Aircraft/Mirage-2000/Nasal/M_frame_notification.nas (part of module mirage2000) is the implementation of the FrameNotification and FrameNotificationAddProperty classes.

For explanation see the headers of the two Nasal files plus https://github.com/5H1N0B11/flightgear-mirage2000/issues/141.

notification.FrameCount (0, 1, 2, 3) can be used to limit the times a function is called - instead of each time the FrameNotificaiton is sent.

notification.frameNotification is a singleton added at the end of M_frame_notification.nas.


## m2000-5.nas - myFramerate ##
* The method _updateFunction() in m2000-5.nas checks time elapsed on only calls referenced methods after e.g. 0.05, 0.1, 0.5, 1, ... seconds. The variable myFramerate holds the last called time, so it can be compared with now. Based on time diff functions are called and last called time is reset.
