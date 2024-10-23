
<!-- ========================================================================================= -->
# Cursor #



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

## HUD ##
* /Models/Instruments/hud:
  * hud.ac
  * hud.png
  * hud.xml
* /Models/Instruments/revi
  * revi.ac
  * revi.png
  * revi.xml
* /Nasal/HUD/HUD.nas
  * var hud_pilot = hud.HUD.new("node": "revi.canvasHUD") -> revi.canvasHUD in revi.ac
  * _mainInitLoop = func() -> hud_pilot.update();
  * _updateFunction = func() -> hud_pilot.update();


<!-- ========================================================================================= -->
# Radar #

## Knowledge: Radar core system which is used in displays ##
* Systems/cnf-instrumentation.xml -> <radar> properties inkl. e.g. <radar-standby> ->/instrumentation/radar/radar-standby
* /Nasal/Radar/radar2.nas
  * radar_mode_toggle: between rws (az=120) and tws-auto (az=60)


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
* Use French symbology from DCS or elsewhere (maybe look back at how Shinobi did it)
* Check whether datalink works

<!-- ========================================================================================= -->
# VTM #

## Todo VTM better ##
* Radar scanning/disc movement indication
* Weapons available
* Scale on the right side (maybe radar forced elevation - tilt)
* Scale at bottom (maybe radar forced sideways - or degrees)
* Make sure DLINK stuff is understood and IFF is implemented.
* Remove not original stuff:
  * Radar range
* Work with settimer, setlistener for stuff which does not change often - e.g. radar-standby
* toggle screen on/off depending on /instrumentation/radar/radar-standby (1 means radar is working, 0 it is off - the property should be renamed of true/false switched). Maybe show a text on the HUD and the VTM that it is stand-by
* Test whether 2000-D still works
* Add a shader to simulate a bit of glass reflections

## Reference ##
* https://forum.dcs.world/topic/209641-mirage-radar-under-rework/: has picture of 2000C VTB, which show that depending on situation different colors are used (not only green or orange)


<!-- ========================================================================================= -->
# Copied files #
## OPRF Files ##

https://github.com/NikolaiVChr/OpRedFlag/tree/master

| Area                  | Commit               | Files not yet converted | Deviations |
| ----------------------| -------------------- | ------------------------| ---------- |
| emesary-damage-system | 200cd50 (2024-10-16) | n/a | /payload.xml/armament/models points to Aircraft/Mirage-2000/Missiles/ instead of ./Models/emesary/ |
| libraries             | 200cd50 (2024-10-16) | n/a | There is an additional custom file for m2000: iff_m2000.nas. The last ca. 10 lines of fire-control.nas is adapted for M2000 |
| radar                 | 200cd50 (2024-10-16) | n/a | rcs.nas is missing in the OPRF library -> copied from F-16 |


## F16 files ##
If changes have been made to the file, then they are marked with ADAPT_TO_M2000
* Nasal/radar/apg-68.nas
* Nasal/rwr.nas
* Nasal/M_frame_notification.nas

<!-- ========================================================================================= -->
# Smaller features / issues #
* Reload Guns etc. button from config menu should either be included in Payload stuff or make sure that guns are only loaded if there is a cannon in e.g. the 2000-D
* Cockpit lights (/controls/lighting/cockpit-lights-side/-top) do not work / illuminate
* Fly-by-wire configuration /fdm/jsbsim/fbw/mode should trigger warning light, if heavy armament loaded but not in CHARGES mode
* ALS rocket like the Viggen guide on stick: in JA37 look for <pure_gain name="names/cursor/rb05-control-yaw">
* Should the VTM display different cursors like the Viggen MI: if (radar.ps46.getMode() == "TWS") {me.cursor_mode = CURSOR_TWS;} else {me.cursor_mode = CURSOR_STT;}
* In VTM._updateTargets: can we use blep info instead of calulation like in viggen: var info = contact.getLastBlep(); var pos = ..(info.getAZDeviation(), info.getRangeNow(),..);
* Make sure headings true vs. magnetic are handled correct in HUD and VTM
* Alidade cartouche in top right corner: what is "N"?


## Tidy up ##
* Add Rick to contributers
* Ask to get m2000 promoted to maintained again in OPRF fleet Discord
* remove gui/dialogs/options.xml:
  * move the performance thing to another place, rest goes away
  * /controls/assistance and assistance.nas go away
* remove hud.xml etc. once we are sure that it revi has replaced it
* remove radar.xml once we have a canvas VTM
* lots of warnings in the log when the Mirage starts up in FGFS
* Remove references to myRadar3 - even if commented out
* Remove MP.nas and dynamic links from e.g. m2000-5.xml
* Nasal:
  * why do we need math_ext and logger namespaces (from C172)?
  * remove commented out namespaces and delete related files
  * Merge exec.nas with M_frame_notification.nas
  * Move HUD/*nas and MFD/*nas into displays folder
* Update key bindings in help and announce changes
* Use the display poweron/off logic in JA37 displays/common.nas

<!-- ========================================================================================= -->
# Reference stuff #
* https://codex.uoaf.net/index.php/Air-to-air_radar
  * https://codex.uoaf.net/index.php/M2k
  * https://codex.uoaf.net/index.php/Special:WhatLinksHere/Air-to-air_radar
* https://www.sto.nato.int/publications/STO%2520Educational%2520Notes/RTO-EN-SET-063/EN-SET-063-%24%24ALL.pdf
* https://forum.dcs.world/topic/311044-a-mirage-2000-5f-for-dcs/: picture of 2000-5F variant as well as backseat of 2000D-5
* https://www.avionslegendaires.net/2024/07/actu/ejection-dun-pilote-de-dassault-aviation-mirage-2000-5/ 2000-5 cockpit
* https://forum.air-defense.net/topic/18257-mirage-2000/page/168/ 2000-5F cockpit
* https://thaimilitaryandasianregion.wordpress.com/2016/07/24/mirage-2000-multirole-combat-fighter-france/
* https://www.estrepublicain.fr/defense-guerre-conflit/2023/04/10/vols-de-nuit-a-luxeuil-delicates-missions-pour-les-pilotes-de-mirage-de-la-ba-116 - picture 13 is 2000-5F cockpit
* https://www.modellingnews.gr/el/%CE%BD%CE%AD%CE%B1-%CE%BC%CE%BF%CE%BD%CF%84%CE%B5%CE%BB%CE%B9%CF%83%CE%BC%CE%BF%CF%8D/mirage-2000-under-skin-ioannis-lekkas-ilias-gkonis-eagle-aviation


