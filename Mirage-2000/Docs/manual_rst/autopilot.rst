********************
The Autopilot system
********************

Autopilot Panel
===============

.. image:: images/autopilot_display.png
   :alt: Autopilot display
   :align: center

The autopilot allows the onboard computer to control the aircraft without constant input from the pilot. 

Clicking one of the switches equals to toggling the mode and eventually disabling other incompatible modes. An enabled mode will be lit up or blinking, but they will only be active if the ``AP`` switch is also lit up.

Only the ``Stby`` button being lit up by default (the autopilot is not enabled on startup).

While the autopilot panel allows the pilot to toggle its different modes, the details of each parameter have to be set either on the ILS/TACAN panel, on the left MFD, or in the ``Autopilot -> Route manager`` built-in FlightGear menu. 

Details about the autopilot's enabled modes, registered altitude, heading, next waypoint, and speed can all be found in the ``EADI`` tab of the left MFD. The active pitch and roll control modes will be shown in white near the top of the ``EADI``.

Note that the switches might not all be visible depending on your viewpoint. You can move your head by using ``Key: shift``, ``right mouse  button`` and dragging your mouse across the screen. To reset it, you can use one of the flight mode keys (see Flight Modes section).

Autopilot Switches and Modes
============================

AP (active autopilot)
---------------------

This switch acts as the main toggle for the autopilot.

If ``AP`` and ``Stby`` are the only two modes active, the onboard computer will attempt maintain the current pitch & roll angle of the aircraft once the stick is released to its central position, but will not override the pilot's input.

When other modes are enabled, having the ``AP`` switch enabled will make them actively guide the aircraft. When in active guidance modes (``VS``, ``ALT``, ``HDG``, ``LNAV``, ``[Placeholder]``).

If switched on, a white ``AP1`` sign will appear at the top of the ``EADI`` tab of the left MFD.

Stby (standby)
--------------

Default state. Clicking it immediately disables all enabled modes except pitch and roll stabilisation (see previous section).

These modes appear as ``PTCH`` and ``ROLL`` in the ``EADI``.

Vs (vertical speed)
-------------------

Enabling this mode registers the current vertical speed (visible in both the physical variometer and the EADI tab of the left MFD) and attempts to keep it constant at this value. This value will be remembered but not displayed.

The vertical speed will only be registered once the mode is activated, i.e. once both the ``AP`` switch and the ``Vs`` switch are simultaneously active.

Note that the throttle is not controlled by this autopilot mode, and the aircraft might stall if you do not pay attention to your speed if this mode is active at high vertical speeds or low throttle input.

This mode is incompatible with ``ALT``, ``TF`` and ``[Placeholder]`` modes.

This mode appears as ``VS`` in the ``EADI``.

Alt (altitude)
--------------

This switch controls two modes: altitude above sea level (ASL) and altitude above ground level (AGL), also called terrain following mode (TF). The switch will be lit in ASL mode, and blink in TF mode. Alternating between the two can be done by clicking the switch, with ASL being enabled first if the switch is off.

Double-clicking the ``Alt`` switch will register the current altitude (either ASL or AGL depending on the mode), which will be visible at the top right corner of the EADI. 

The ASL mode will attempt to maintain the aircraft at the altitude set, or climb/descend towards it at a low vertical speed (ca. 450ft/min). It is recommended to use the ``Vs`` mode for faster changes in altitude. This mode will lock the manual pitch and yaw input of the aircraft, but will only control the pitch.

The TF mode will only function below 10,000ft and if aircraft is close to horizontal and will not override the pilot's input. It will also attempt to follow the terrain based on the feed of the radar. To adjust the smoothness of the aircraft's trajectory and the range of the terrain taken into account, you can move the ``AP TF smooth`` and ``Predictions`` sliders in the ``Mirage 2000 -> Configuration`` menu respecively.

These modes are incompatible with the ``VS`` and ``[Placeholder]`` modes.

The ASL and AGL modes appear as ``ALT`` and ``TF`` in the ``EADI``.

Hdg (heading)
-------------

This mode will override the roll axis and lock the pitch axis of the aircraft. Once enabled, the aircraft will attempt to stabilise or turn itself towards the heading bug set in the ``EHSI`` tab of the left MFD (bottom left knob). This direction will be visible both on the ``EHSI`` in pink, and in the HUD as a downards triangle on the compass.

This mode is incompatible with ``LNAV`` and ``[Placeholder]`` modes.

This mode appears as ``HDG`` in the ``EADI``.

Nav (navigation source)
-----------------------

This mode will override the roll axis and lock the pitch axis of the aircraft. Once enabled, the aircraft will attempt to follow the navigation source (``NAV1``, ``NAV2``, ``TACAN`` or ``FMS``) set in the ``EHSI`` page of the left MFD. Depending on the NAVSRC mode, it can be configured on the ``RMU`` page or in the ``Autopilot -> Route manager`` menu). The selected direction will be shown by the blue arrow on the ``EHSI``, as well as the numerical value at the bottom right of the same page. For more details, please refer to the ``EHSI`` section of this guide.

This mode is incompatible with ``HDG`` and ``[Placeholder]`` modes.

This mode appears as ``LNAV`` in the ``EADI``.

App (ILS approach)
------------------

Switches to instrumental landing system approach by overriding the pitch and roll axes of the aircraft. It will not, however, control its throttle. It will use the frequency set in the ``VOR.ILS`` panel or the ``RMU`` tab of the left MFD.

This mode is only applicable if the aircraft is decently well aligned with the runway to begin with. It will disengage at around 100ft AGL.

This mode is incompatible with the ``VS``, ``ALT``, ``TF``, ``HDG`` and ``LNAV`` modes.

This mode appears as ``[Placeholder]`` in the ``EADI``.

Spd (speed)
-----------

This is an in-sim switch only, and does not exist on actual Mirage 2000s. It overrides the pilot's throttle input in order to maintain the airspeed set in the ``EADI`` tab of the left MFD. 

Note that once disabled, the pilot has to move the throttle in order to unlock it again.

This mode is not shown as enabled or otherwise in the ``EADI``.

Note: autopilot glitches
------------------------

Please note that when activating the ``VS``, ``ALT``, ``LNAV`` or ``[Placeholder]`` modes with too much G-load or AoA, the nose might start bobbing up and down violently. This is an in-sim issue that has not been solved yet. Should this happen to you, disable the autopilot, stabilise the aircraft, then enable it again.