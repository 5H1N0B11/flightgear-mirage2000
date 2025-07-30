*******************
Cockpit instruments
*******************

Overview
========

.. image:: images/cockpit_instruments.png
   :alt: Overview of cockpit instruments
   :align: center

#. `Head-up display (HUD)⇗ <https://en.wikipedia.org/wiki/Head-up_display>`_ - French: `visualisation tête haute (VTH)⇗ <https://fr.wikipedia.org/wiki/Affichage_t%C3%AAte_haute>`_
#. Autopilot panel
#. Elevator trim
#. Head-level display - French: visualisation tête moyenne (VTM)
#. Physical flight instruments
#. Left `Multi-function display (MFD)⇗ <https://en.wikipedia.org/wiki/Multi-function_display>`_ - French: écran multifonction
#. Head-down display - French: visualisation tête basse (VTB)
#. Right MFD
#. Clock
#. Master Arm switch
#. Weapon command panel
#. Transponder
#. Fuel indicator panel
#. Engine indicator panel
#. External tank jettison button
#. Gear indicator
#. Gear lever
#. Light switches
#. Throttle stick
#. Elevon angle indicator
#. Cabin altimeter (non-functional)
#. Power switches
#. Alert panel
#. ILS & TACAN panel
#. Air conditioning panel
#. Interior lighting
#. Engine control panel
#. Canopy handle & lock

Please note that this cockpit model is not complete. Only instruments that have been implemented are highlighted.

1. HUD
======

Please refer to the HUD section of this guide.

2. Autopilot panel
==================

.. image:: images/autopilot_display.png
   :alt: Autopilot display
   :align: center

The autopilot allows the onboard computer to control the aircraft without constant input from the pilot. 

Clicking one of the switches equals to toggling the mode and eventually disabling other incompatible modes. An enabled mode will be lit up or blinking, but they will only be active if the ``AP`` switch is also lit up.

Only the ``Stby`` button being lit up by default (the autopilot is not enabled on startup).

While the autopilot panel allows the pilot to toggle its different modes, the details of each parameter have to be set either on the ILS/TACAN panel, on the left MFD, or in the ``Autopilot -> Route manager`` built-in FlightGear menu. 

Details about the autopilot's enabled modes, registered altitude, heading, next waypoint, and speed can all be found in the ``EADI`` tab of the left MFD. The active pitch and roll control modes will be shown in white near the top of the ``EADI``.

Note that the switches might not all be visible depending on your viewpoint. You can move your head by using ``Key: shift``, ``right mouse  button`` and dragging your mouse across the screen. To reset it, you can use one of the flight mode keys (see Flight Modes section).

AP (active autopilot)
---------------------

This switch acts as the main toggle for the autopilot.

If ``AP`` and ``Stby`` are the only two modes active, the onboard computer will attempt maintain the current pitch & roll angle of the aircraft once the stick is released to its central position, but will not override the pilot's input.

When other modes are enabled, having the ``AP`` switch enabled will make them actively guide the aircraft. When in active guidance modes (``Vs``, ``Alt`` - ASL, ``Hdg``, ``Nav``, ``App``).

If switched on, a white ``AP1`` sign will appear at the top of the ``EADI`` tab of the left MFD.

Stby (standby)
--------------

Default state. Clicking it immediately disables all enabled modes except pitch and roll stabilisation (see previous section).

Vs (vertical speed)
-------------------

Enabling this mode registers the current vertical speed (visible in both the physical variometer and the EADI tab of the left MFD) and attempts to keep it constant at this value. This value will be remembered but not displayed.

The vertical speed will only be registered once the mode is activated, i.e. once both the ``AP`` switch and the ``Vs`` switch are simultaneously active.

Note that the throttle is not controlled by this autopilot mode, and the aircraft might stall if you do not pay attention to your speed if this mode is active at high vertical speeds or low throttle input.

This mode is incompatible with ``Alt`` - ASL, ``Alt`` - AGL, ``Nav`` and ``App`` modes.

Alt (altitude)
--------------

This switch controls two modes: altitude above sea level (ASL) and altitude above ground level (AGL). The switch will be lit in ASL mode, and blink in AGL mode. Alternating between the two can be done by clicking the switch, with ASL being enabled first if the switch is off.

Double-clicking the ``Alt`` switch will register the current altitude (either ASL or AGL depending on the mode), which will be visible at the top right corner of the EADI. 

The ASL mode will attempt to maintain the aircraft at the altitude set, or climb/descend towards it at a low vertical speed (ca. 450ft/min). It is recommended to use the ``Vs`` mode for faster changes in altitude. This mode will lock the manual pitch and yaw input of the aircraft, but will only control the pitch.

The AGL mode will only function below 10,000ft and if aircraft is close to horizontal and will not override the pilot's input. It will also attempt to follow the terrain based on the feed of the radar. To adjust the smoothness of the aircraft's trajectory and the range of the terrain taken into account, you can move the ``AP TF smooth`` and ``Predictions`` sliders in the ``Mirage 2000 -> Configuration`` menu respecively.

These modes are incompatible with the ``Vs``, ``Nav`` and ``App`` modes.

Hdg (heading)
-------------

This mode will override the roll axis and lock the pitch axis of the aircraft. Once enabled, the aircraft will attempt to stabilise or turn itself towards the heading bug set in the ``EHSI`` tab of the left MFD (bottom left knob). This direction will be visible both on the ``EHSI`` in pink, and in the HUD as a downards triangle on the compass.

This mode is incompatible with ``Nav`` and ``App`` modes.

Nav (navigation source)
-----------------------

[Placeholder]

App (ILS approach)
------------------

Switches to instrumental landing system approach by overriding the pitch and roll axes of the aircraft. It will not, however, control its throttle. It will use the frequency set in the ``VOR.ILS`` panel or the ``RMU`` tab of the left MFD.

This mode is only applicable if the aircraft is decently well aligned with the runway to begin with. It will disengage at around 100ft AGL.

This mode is incompatible with the ``Vs``, ``Alt`` - ASL, ``Alt`` - AGL, ``Hdg`` and ``Nav`` modes.

Spd (speed)
-----------

This is an in-sim switch only, and does not exist on actual Mirage 2000s. It overrides the pilot's throttle input in order to maintain the airspeed set in the ``EADI`` tab of the left MFD. 

Note that once disabled, the pilot has to move the throttle in order to unlock it again.



Note: autopilot glitches
------------------------

Please note that when activating the ``Vs``, ``Alt`` - ASL, ``Nav`` or ``App`` modes with too much G-load or AoA, the nose might start bobbing up and down violently. This is an in-sim issue that has not been solved yet. Should this happen to you, disable the autopilot, stabilise the aircraft, then enable it again.

3. Elevator trim
================

This instrument allows for the angle of the elevons to be manually offset in order to adjust the rotational angle of the aircraft along the pitch axis. It can be controlled by scrolling while hovering one's mouse over the wheel.

Please note that the influence of this instrument is rather low, and high-G manoeuvres should rely on the stick input moreso than the trim.

4. VTM
======

Please refer to the VTM section of this guide.

5. Physical flight instruments
==============================

.. image:: images/phys_flight_instruments.png
   :alt: Physical fligth instruments
   :align: center

These instruments serve as backup for the digital one, as well as when the left MFD is not on the ``EADI`` tab. 

1: Angle of attack (AoA) indicator
----------------------------------

This gauge enables the pilot to see the angle of attack of the aircraft. One dot equals to 5° up until +15°, then 6.7° approx up until 35°. Negative AoA will not be shown. 

While the onboard computer always attempts to keep the Mirage out of a stall (>25° AoA) and pulling on the stick regardless of AoA is not an issue, avoiding a tailstrike (>14° AoA) on takeoff and landing is of utmost importance. As such, should the HUD not function, this indicator will have to be taken into account on these instances.

Note that this indicator might not be visible depending on your view position. Moving your head to the side will allow you to see it.

2: Compass
----------

This indicator will display the current heading in degrees. Depending on the setting of the VTB, it will use either the True North or the Magnetic North. 

3: Airspeed indicator
---------------------

This indicator will display the current airspeed in knots as well as the current mach below. 

4: Attitude indicator
---------------------

5: Variometer
-------------

This indicator will show the vertical speed of the aircraft at low values. Each horizontal bar corresponds to 500ft, with a shown range between -2,000ft/min and +2,000ft/min.

7: Altimeter
------------

This indicator will show the altitude above sea level, adjusted to the pressure set in the ``EADI`` tab of the left MFD.

6. Left MFD 
===========

Please refer to the left MFD section of this guide.

7. VTB
======

Please refer to the VTB section of this guide.

8. Right MFD
============

Please refer to the right MFD section of this guide.

9. Clock
========

This clock will display the time in UTC.

10. Master arm switch
=====================

This switch sets all weapon stations as well as the onboard cannon on live fire mode, and must be toggled on to fire any type of armament. It is off by default.

This switch should only be turned on in combat situations.

11. Weapon command panel
========================

[Not implemented]

12. Transponder
===============

The top knobs are used to input the transponder code. The bottom right switch controls the different IFF modes of the aircraft. It is on ``N`` (French: neutre, corresponds to it being switched on) by default.

In combat, the transponder's mode should always be on ``OFF``.

13. Fuel indicator panel
========================

.. image:: images/fuel_panel.png
   :alt: Fuel indicator panel
   :align: center

Displays the remaining fuel in kg (Note that the amounts in the ``Equipment -> Fuel and payload`` menu are displayed in lbs, with 1 lbs = 0.45 kg or 1 kg = 2.2 lbs approximately).

``GAUGE`` will be the total amount of fuel in the internal tanks (feeding system aside).

``REMAIN`` will also account for the feeding line and the external tanks. 

``BINGO`` is a value that can be manually set in the ``Mirage 2000 -> Configuration`` menu. It should be set as the minimum fuel required to return to base (RTB) - having less than this will cause the fuel indicator to flash red, signalling the pilot to urgently RTB. By default, it is set at 480kg, which is a rather low value.

The white Mirage-shaped indicator on the left displays in white sections of the fuel system that are not empty, and in black if they are devoid of any fuel. The upper two rectangles account for both the forward and backward fuselage tanks of each side, and the pentagons for the wing internal tanks. When taking external tanks, they will be displayed as white disks below the aforementioned shapes.

Note that the fuel system will first attempt to empty the external tanks before using the fuel contained in the internal system. If the tanks are jettissonned, the fuel flow will automatically switch to internal tank feed.

14. Engine indicator panel
==========================

This indicator will display informations about the engine's speed and fuel consumption. 

The top value ("N%") displays the ratio of the engine's speed to its maximum military power (i.e. without afterburners). In the idle state, it should be stable at around 47%, and at maximum military power at around 96%. Using afterburners will push this value above 100%. 

The bottom left value shows the estimated fuel consumption per minute in kg. Note that this is an instantaneous estimation, which means changes in altitude, speed, etc, will affect it.

The bottom right value displays the number of engine rotations per minute (RPM). 

15. External tank jettison button
=================================

Self-explanatory name. This does not jettison weapons attached to the pylons of the aircraft. 

Jettisonning the tanks should only be done in dogfight situations or in case of emergency - they come from taxpayers' money, after all.

16. Gear indicator
==================

Will display three green downward arrows when the gear is fully lowered. These indicators will disappear once the gear is moving or retracted. 

17. Gear lever
==============

Lowering the lever will lower the gear, and raising it will retract the gear. Using the ``g`` and ``G`` keys (retract and extend gear respectively) will do the same, but also switch to the ``NAV`` and ``APP`` modes respectively.

18. Light switches
==================

.. image:: images/lights_panel.png
   :alt: Light switch panel
   :align: center

#. Taxi/landing light. Off by default.
#. Dorsal flash lights. On by default. Should be manually turned off after startup.
#. Formation lights (stripes on the sides of the fuselage and tail). On by default.
#. Tail position lights. On by default.
#. Wing position lights. On by default.

19. Throttle lever
==================

Cannot be moved via the mouse, only with ``Key: PageUp`` and ``Key: PageDown``. Afterburners are enabled at 90% of the lever's maximum extention. 

Note: this value is different in a real Mirage 2000, where it lies at 75%.

20. Elevon hydraulic pressure indicators 
========================================

21. Cabin altitude indicator
============================

Not functional.

22. Power switches
==================

The red power switch toggles the battery on/off. The battery should be on at all times when the engine is running. Off by default.

The grey switches toggle all the alternators at once. They should be on at all times when the engine is running. Off by default.

23. Alert Panel
===============

.. image:: images/alert_panel.png
   :alt: Alert panel
   :align: center
   
[Default state of the alert panel when launching the simulation]

The warning lights should all be off in a normal situation (save for the parking brake when stopped on the ground). Depending on the severity of the warning, you might have to review the cockpit's switches, carry out an emergency landing, or eject. Their following codes are as follows:

======= ====================================================================
Abbrev  Alert
======= ====================================================================
BATT    Battery off
TR      Alternators off
ALT.1   Alternator 1 off
ALT.2   Alternator 2 off
OIL     Oil pressure too low
T7      N/A
CMPTR   Computer failure
RPM     RPM too high
VSD     N/A
LP      Fuel flow irregular
LLP     Left fuel pump off
RLP     Right fuel pump off
HYD.1   1st hydraulic system failure
HYD.2   2nd hydraulic system failure
EMG HYD Emergency hydraulic system failure
EP      
BINGO   Fuel lower than ``BINGO`` value set
CAB P   Cabin pressure too low
TEMP    Temperature too low
OX REG  Engine oxygen flow irregularity
5mn OX  Low oxygen (5min remaining) (not implemented)
HA OX   Cockpit oxygen system failure
PITOT   Pitot tube failure
DC      N/A
CONDIT  Air conditioning failure
CONF    N/A

GAIN    N/A
SCOOP   NACA scoop failure
FLT ENV Flight envelope failure (aircraft no longer flyable)
S CONES Supersonic cone failure
EL B UP N/A
AOA     Too high AoA
SLATS   Slats failure
MAN     N/A
T/O     N/A
PARK    Parking brake enabled
AP      Autopilot failure
======= ====================================================================

24. ILS / TACAN panel
=====================

The ``VOR.ILS`` value can be tuned to an airport's instrumental landing system frequency in order to help with the landing. When in ``APP`` flying mode and if the ILS is enabled, you will be able to visualise the corresponding airport's runway in the HUD. The left knob changes the frequency by 1 MHz and the right knob by 0.05 MHz.

The ``TACAN`` allows the pilot to change the numerical value of the TACAN channel. The left knob changes it by 10 and the right knob by 1. In order to switch between X and Y modes, use the ``RMU`` tab of the left MFD.

25. Air conditioning panel
==========================

The ``COND`` switch toggles the air conditioning inside the cabin. Off by default.

The knob to its right allows the pilot to set the desired air temperature of the air conditioning. Pointing the hand of the knob towards upper half will make use of the automatic temperature regulation system, while the lower half will switch to manual control of the temperature of the airflow (and is not advised). Each movement of the hand (in-sim) will offset the temperature by 1.33°C from the default temperature (22°C AUTO). Turning the knob to the right makes the temperature cooler, and to the left makes it warmer. It is advised to set the temperature to around 17-18°C AUTO.

The ``DESEMB`` switch toggles the windshield fog removal (French: désembuage). Off by default. It is highly advised to turn it on for medium-to-high-altitude flights.

26. Interior lighting panel
===========================

Controls the cockpit lights.

27. Engine control panel
========================

.. image:: images/engine_control_panel.png
   :alt: Engine control panel
   :align: center
   
[Default state of the engine control panel when launching the simulation]

Panel used for starting up the engine. 

In order of the startup sequence:

#. Engine cuttoff switch. Enabled by default.
#. Cover of the cutoff switch. Closing it disables the cutoff switch. Open by default.
#. Left fuel pump switch. Off by default.
#. Right fuel pump switch. Off by default.
#. Startup mode switch. Off by default.
#. Pump BP switch. Off by default.
#. Starter button cover. Closed by default.
#. Starter button. Pressing it for a few seconds gives the engine the necessary rotational speed to keep turning on its own.

28. Canopy handle & lock
========================

Clicking the canopy handle will switch between almost closed and fully opened states. When the canopy is almost closed, clicking the locking lever will fully close and secure the canopy. The canopy is fully opened by default.

Pressing ``d`` twice equates to clicking the canopy handle and the locking lever (and thus closes the canopy from the default state, or opens it completely if it is closed).









































