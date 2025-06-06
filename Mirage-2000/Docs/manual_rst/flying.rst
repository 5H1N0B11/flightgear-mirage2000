******
Flying
******

Operations
==========

Start-up
--------

When your aircraft is cold and dark before start-up, the external generator and fuel truck are connected to your aircraft, and protections (in red) will be on your aircraft, as well as chocks. They will disappear automatically as you start up. With the ``}`` key, you can auto-start your aircraft.

Taxi
----

The Mirage can taxi at relatively high speeds, usually below 40kts, but you shouldn't go faster than 20kts when turning. Even if the track width is larger than usual, you should always stay at safe speeds.

The front gear can turn 90° to the left and to the right, so a turn radius of 3 meters is reachable. You might need to add thrust, as it is difficult to move with the front gear almost entirely turned. Do not push on the rudder pedals too much when braking, otherwise the aircraft may fall on one side or another if you turn too tight.

The taxi lights have an angle of about 30 degrees in front of the aircraft and are not attached to the moving part of the front gear, so they will always light in front.

Take-off
--------

Line up on the best runway for the current weather conditions and ask for clearance. Once the clearance is given and after releasing the parking brake, spool up while keeping the pedal brakes enabled. Then, throttle up to 99% RPM (military power) for long runways, 100%+ (with afterburners) for short runways or with heavy loadout. Rotate speed is at 120 knots when using a clean loadout, 140 knots if with payload. After this, bring the inverted "T" in the HUD under the line of horizon and you should be able to lift off at 170-190 knots, depending on your loadout. Do not exceed 14° nose angle or you will tail-strike. Even though the Mirage is airborne, you might feel that the plane with high nose angle "floats" over the runway until reaching well beyond 200 knots. Raise the gears with key ``g``.

The Mirage needs long runway distances to take off, as it hasn't got a separate horizontal tail stabilizer/elevator. Because of the elevons' position (trailing edge of the wing), they create a considerable loss of lift when they are moved up to rotate, so higher rotation speeds are needed. Also, the delta wing is often called "flying airbrake", as they generate lots of drag at high angles of attack, like at take-off. This is why high speeds and long runways are needed.

Initial Climb
-------------

After taking off, retract the landing gear before reaching 280kts (maximum gear extension speed). You are advised to follow the runway heading until you are at an acceptable speed (approximatively 200 knots), but if you used reheat and you are not heavy, you can turn as soon as you are at 200 knots. However, you have to watch your speed so you don't stall - at this altitude, a stall doesn't forgive.

After having chosen the correct heading and having attained 250 knots, you can commence your climb with full military power, at the beginning around 2,000 feet per minute to gain speed, and when you have reached your optimal climb speed you may pull the nose up to climb at a rate of 4,000 feet per minute. Remember that if you are faster, you will have an lower angle of attack and will thus drag less, and your elevons will not need to be pulled fully up (and thus will not create too much additional loss of lift), so it is advised to speed up before climbing too fast.

Climb
-----

The Mirage can climb exceedingly fast, with a maximum climb rate of 6,000 feet per minute. With full tanks and `air-policing <https://en.wikipedia.org/wiki/Air_sovereignty>`_ loadout, it is able to climb with full military power at a rate between 4,000 feet and 6,000 feet without bleeding speed (between 250 and 300 knots). With full afterburners and in the same conditions, the climb rate can go up to 12,000 feet, still in zero/zero conditions. If going vertical with full afterburners and a base speed of 400 knots, you can reach 20,000 feet before having to push the nose back down. This is the fastest way of climbing.

Cruise
------

The Mirage 2000 normally cruises between angels 35 and angels 40 (35,000 - 40,000 feet), and this is the best altitude for Mach 2+ flights. It can also go above 50,000 feet (the pilot would need special equipment - not simulated yet), and up to 80,000 feet, but with difficulties. The optimal cruise altitude is 36,000 feet.

While it has a bi-sonic flight possibility, it consumes lots of fuel. It is thus advised to stay sub-sonic during cruise flights, without using afterburners. With cargo loadout and without using afterburners, the Mirage can fly for more than two hours. For long cruises, it is advised to use the navigation, altitude and speed autopilots.

Visual Landing
--------------

Lower the gears when you are below 195 knots, then approach the runway at 175 knots (for 15% fuel left; add 5 knots every 20% additional fuel). If by night, put the landing lights on. On final approach, hold an angle of attack of between 6 and 9 degrees. When passing the runway threshold, flare and bring the aircraft to an angle of attack of 12 degrees. You should land at 145 knots (for 15% fuel left; add 5 knots every 20% additional fuel). When touching down, wait for the aircraft to slow down to 135 knots and apply pedal brakes. Use the brake parachute (key ``o`` to deploy) if necessary (heavy loadout or short runway) - and then release when not needed any more (same key ``o``).

The easiest way to get approach and touchdown right is placing the inverted "T" at the bottom of the HUD on the runway threshold and regulate speed with throttle, such that the flightpath marker is on top of the inverted T. When at speeds below 200 and high `angles of attack <https://en.wikipedia.org/wiki/Angle_of_attack>`_ you have to be ready to apply quite some throttle to keep a steady decent rate!

Navigation
----------

To switch between displaying heading in true North vs. magnetic North, use the second button from right on the lower button row of the VTB.

Miscellaneous
-------------

* When heavily loaded, the `fly-by-wire system (FBW) <https://en.wikipedia.org/wiki/Fly-by-wire>`_ should be set correctly to lower allowable flight limits in order to save the structure: ``Mirage2000=>Options=> Change A/A to CHARGES``.
* Afterburners engage when throttle moves past 85%.
* The 1700l dropable tanks are not supersonic.

Flight Modes
============

There are 4 flight modes:

* Take-off (``key: f``)
* Approach (``key: F``)
* Navigation (``key: h``)
* Attack (``key: H``)

The main difference between the flight modes for now is the view position and zoom. When you lower gear, then you get automatically into ``Approach`` mode - after gear up you end in mode ``Navigation``. Toggling the master arm switches between modes ``Attack`` and ``Navigation``.

In Cockpit Views
================

In order to see the MFDs and the VTB better as well as seeing better the gauges on each side of the VTM, you can use key bindings:

* ``Key: n``: view left MFD and VTB
* ``Key: N``: view right MDF and VTB
* ``Key: ctrl-n``: reset the view to the position of the current flight mode
