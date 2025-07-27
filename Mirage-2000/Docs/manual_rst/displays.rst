*********************************
The Mirage 2000-5 Display Systems
*********************************

The Mirage 2000-5 has its name from the fact that it has 5 main displays:

* Pink - `Head-up display (HUD)⇗ <https://en.wikipedia.org/wiki/Head-up_display>`_ - French: `visualisation tête haute (VTH)⇗ <https://fr.wikipedia.org/wiki/Affichage_t%C3%AAte_haute>`_
* Amber - Head-level display - French: visualisation tête moyenne (VTM)
* Red - Head-down display - French: visualisation tête basse (VTB)
* Blue - Left and right `Multi-function display (MFD)⇗ <https://en.wikipedia.org/wiki/Multi-function_display>`_ - French: écran multifonction

.. image:: images/5_screens.png
   :alt: 5 main screens of the M2000-5
   :align: center

VTM
===

This is a specialty of the Mirage 2000-5. Being positioned just below the HUD, this screen allows the pilot to see radar related information without moving the head. Like the HUD the VTM's focal point is perceived to be at infinity.

.. image:: images/vtm_intro.png
   :alt: VTM Default Display
   :align: center

Most radar pictures are displayed in a B-scope (see picture above), the sea and ground radar modes are displayed as Plan Position Indicator - cf. `Radar Displays⇗ <https://en.wikipedia.org/wiki/Radar_display>`_ on Wikipedia.

The top left corner shows the radar main mode (``Key: Q`` to cycle) and the radar sub-mode (``Key: ctrl-q`` to cycle). In the top middle the radar range in nm is displayed (``Key: R`` to increase, ``Key: E`` to decrease). The box in the top right corner shows data from the cursor: Θ shows the the heading of the cursor, Ρ shows the distance of the cursor on the radar.

The cursor can be moved with arrow keys on the keyboard or using a binding to a joystick. On the left side of the cursor the radar distance is shown, on the left side the top and bottom altitudes being scanned by the radar (in ft).

At the bottom of the screen there is a heading scale (showing true of magnetic North depending on the setting done on the VTB). At the bottom on the left the three main weapon guidance modes are displayed: radar (RDR), laser designation point (LDP), GPS. The currently used guidance mode is displayed inside a box and can be changed using ``Key: M``.

The scale on the left side shows the radar antenna elevation / radar pitch. The number shows the number of bars (vertical scanning of the radar). The antenna elevation can be changed (``Key: i`` for up, ``Key: I`` (capital i) for down, ``Key: Y`` for level).

Air-to-Air
----------

A flying target is shown as an open rectangle with a line showing the direction the target is flying at (the longer the line, the faster).

.. image:: images/vtm_crm_tws.png
   :alt: Air-to-Air Target Display
   :align: center

In TWS mode a target can be selected using ``Key: y`` (and deselected with ``Key: ctrl-y``). When the target is selected, then the display is changed to a small cross (still with a line indicating the direction) and the targets identifier is displayed in the lower right corner.

.. image:: images/vtm_crm_tws_selected.png
   :alt: Selected Air-to-Air Target
   :align: center

To select a target in another air-2-air or air-2-ground or air-2-see mode, the cursor must be moved over the middle of the target and then designated using ``Key: l`` (small L).

.. image:: images/vtm_crm_rws.png
   :alt: Target Designation
   :align: center

Air-to-Sea
----------

Like all ground modes the radar picture is displayed as PPI.

In air-2-sea mode the target is selected and designated using the cursor. A not designated target is shown as a diamond.

.. image:: images/vtm_sea.png
   :alt: Air-to-Sea Target (Undesignated)
   :align: center

When selected the target is shown as a cross. There is no information about direction / speed displayed.

.. image:: images/vtm_sea_selected.png
   :alt: Air-to-Sea Target (Selected)
   :align: center

Air-to-Ground
-------------

The following picture shows a few targets in ground mode (like for sea targets they are displayed as diamonds). Notice that the antenna elevation has been lowered a few degrees (radar pitch scale at left side) and one of the targets (boxed) has been designated using the laser - and therefore the LDP guidance mode is highlighted.

.. image:: images/vtm_ground.png
   :alt: Air-to-Ground Targets
   :align: center

VTB
===

The head-down display is currently basically a copy of a Navigation Display you would find in an Airbus - and thus not yet implemented as per the original.

..
   Actually it is using https://wiki.flightgear.org/Canvas_ND_framework

The buttons around the screen influence settings as follows:

.. image:: images/vtb_buttons.png
   :scale: 60%

#. Show/hide airports
#. Show/hide waypoint data
#. Show/hide waypoints
#. Show/hide position points
#. Show/hide weather data
#. On/off button
#. Set range in nautical miles (distances: 10; 20; 40; 80; 160; 320)
#. Cycle pages: PLAN, VOR, APP, MAP
#. Toggle liquid crystal display/cathode ray tube display (does not really do anything)
#. Toggle centre ND
#. Toggle true/magnetic heading


Right MFD
=========

To change the currently displayed page, use the middle button on the button row at the top of the screen. The text below the button shows the next screen.

Use the mouse wheel to push the toggles on the left and right side of the MFD up and down. Only those toggles work, which have a text associated on the screen.

You can also change the view with ``Key: N`` to better see the right MFD (and the VTB). Use ``Key: ctrl-n`` to go back to the default view.

NB: you cannot display pages from the right MFD on the left MFD or the VTB.


.. _link_subsection_sms:

Store Management system (SMS)
-----------------------------

The SMS page shows the currently loaded weapons incl. external tanks. A few things to note on the picture below:

* The red text on the left indicates that the load type for the Flight Control System should be changed given the heavy load of bombs. That can be done with the toggle at the bottom left.
* A gun is loaded (CC422 gun pod on a M2000D) and therefore at the top to the left you can see the remaining bullet count. If the page would be displayed in a M2000-5, then "CAN" would be displayed each of the 2 cannons.
* The currently selected store will have a yellow rectangle border. You can only select weapons (using ``Key: w``) and only the first available weapon of the same type.
* The red stripes in the middle indicate that there is weight on wheels.
* At the top of the page below the middle button you can read "PPA" - which will be the next page displayed.

The abbreviations used for the stores are available in the weapons overview table in :ref:`link_section_overview_weapons` (a number in front of the abbreviations means the number of this weapon at the station).

.. image:: images/sms_page.png


.. _link_subsection_ppa:

Poste de Préparation Armement (PPA)
-----------------------------------

The PPA is a weapons configuration panel. In the middle of the screen it shows the selected weapon plus the remaining number of this type.

At the top of the page a reminder for the pilot is displayed: "Damage: Off" means that the OPRF damage has not been enabled and therefore weapons will not generate damage when they hit something.

The displayed menus depend on the chosen weapon and sometimes on previously chosen menu items (e.g. the ripple distance is only shown, if ripple mode is set to more than 1).

.. image:: images/ppa_page.png


Radar Warning Receiver (RWR)
----------------------------

The radar warning receiver (`RWR⇗ <https://en.wikipedia.org/wiki/Radar_warning_receiver>`_) screen is actually a combination of a RWR display and a counter-measures dispenser display.

.. image:: images/rwr_intro.png
   :alt: RWR Display
   :align: center

On the left side of the screen there are 2 menu items for the RWR:

* Separation: whether the symbols should be dispersed a bit to make them more readable (but this changes the relative bearing).
* Unknown: whether to show radar sources, which cannot be interpreted.

RWR
^^^

.. image:: images/rwr_symbols.png

The RWR displays a maximum of 12 threats. High level threats (e.g. with an STT lock or actively guiding a missile) are within the blue centre ring, lower level threats are closer to the outer ring. I.e. the distance from centre is an interpretation of threat and not a real distance. The position is a top-down view around your aircraft (nose towards up/North).

Different types of threats are displayed with different symbols according to USA/NATO standards (i.e. not according to French symbology at the moment). ``U`` is for unknown threat, ``S`` is for surveillance aircraft (e.g. `AWACS⇗ <https://en.wikipedia.org/wiki/Airborne_early_warning_and_control>`_ - which typically cannot shoot), and ``AI`` is for aircraft which have not yet been classified in OPRF.

.. image:: images/rwr_locked.png
   :alt: RWR Threat Symbols
   :align: center

If there is a chevron below the symbol, then the threat has a radar lock on you. If there is a hat on top of the symbol, then the threat is either source to an active missile or guiding a semi-active missile. Only one missile in the air can be displayed - even though several might be in the air at the same time. The missile is shown with the symbol ``W`` close to the centre - again the distance is not the real distance and only the bearing relative to your aircraft is shown. If a missile is in the air, then the related threats are blinking once per second.

In addition to the visual indications there are sounds (refreshed every 0.5 seconds):

* A new threat has been detected: continuous 1 kHz tone for 0.5 seconds.
* A new radar lock (STT) has been detected: 1 kHz tone chopped at 25Hz for 0.5 seconds.
* A semi-active missile is being supported: 1 kHz tone chopped at 25Hz for 0.5 seconds repeating after 0.5 seconds of silence.
* An active radar missile is in the air: continuous 1 kHz tone chopped at 25Hz until the missile is not detected any more.

Counter-Measures Dispenser Display
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

At the right side of the RWR there are 4 indicators for dispensed counter-measures (flares and chaff). It is a "could-be" interpretation of the decoy dispenser lights on the right top of the M2000-C canopy.

.. image:: images/rwr_counter_measures.png
   :alt: Counter-Measures Dispenser Display
   :align: center

* ``LL`` = decoy dispenser (Lance-Leurres) - blue: blinks when counter-measures are being dispensed.
* ``EM`` = chaff (Électro-magnétique) - amber: blinks when remaining quantity is at or below 20. Steady light when remaining quantity is at 0 (empty).
* ``IR`` = flares (Infrarouges) - amber: blinks when remaining quantity is at or below 20. Steady light when remaining quantity is at 0 (empty).
* ``EO`` = electro-optical (Électro-optique) - amber: not simulated.

The total quantity of counter-measures simulated is 120. 2 are dispensed every second. No difference is made between flares and chaff in the simulation. Use ``Key: q`` to start dispensing and ``Key: q`` to stop dispensing.


Map
---

The map page is a temporary replacement for a real implementation in the VTB. Using the lower right toggle you can zoom and and out of the map.

The map is based `OpenStreetMap⇗ <https://osm.org>`_ and shows only the position of one's own aircraft in the middle.

Depending on the network connection it might take a while for parts of the map (tiles) to load. Once loaded the tiles get cached and should therefore be available further on.

.. image:: images/map_page.png
