****************
The Radar System
****************

The Real Radar RDY
==================

The -5 version of the Mirage 2000 is equipped with the RDY (Radar Doppler Modèle Y - Radar Doppler Multitarget), which can be used in air-to-air and air-to-ground tasks. See descriptions in `English Wikipedia <https://en.wikipedia.org/wiki/Radar_Doppler_Multitarget>`_ and `radartutorial.eu <https://www.radartutorial.eu/19.kartei/08.airborne/karte042.en.html>`_.

The Modelled Radar
==================

The modelled radar is a copy of the `FlightGear F-16 Flight Control Radar <https://github.com/NikolaiVChr/f16/wiki/FCR>`_, because it is already nicely modelled and the F-16 radar most probably is quite similar to the RDY-versions.

.. note::
   In reality the different versions of the Mirage 2000 have different radars and different radar modes, but this is not modelled.

Radar Range
-----------

The radar range can be increased by using ``Key: R`` - and decreased by using ``Key: E``. Each key press is a factor 2 (e.g. from 20 nm to 40 nm)

For air-to-air combat the range is up to 160 nm (depending on the mode), for ground and sea modes it is up to 80 nm (for ground auto 40 nm).

When the radar mode changes (either by actively changing the radar mode or as a consequence of e.g. selecting a target), the range can change automatically.

Radar Modes
-----------

The radar has a set of modes and sub-modes (see the description in `FlightGear F-16 Fire-Control Radar <https://github.com/NikolaiVChr/f16/wiki/FCR>`_ - bearing in mind that the displays are different in the M2000 and not all functionality is the same):

* **CRM**: Combined Radar Mode

  * RWS: Range while Search
  * TWS: Track while Search
  * LRS: Long Range Search
  * VS: Velocity Search

* **ACM**: Air combat Mode

  * ACM-20: 30 by 20 degrees HUD field of view
  * ACM-60: 10 by 60 degrees HUD field of view
  * ACM-BORE: boresight

* **SEA**: Sea Navigation
* **GM**: Ground Mapping
* **GMT**: Ground Moving Target

To change between main modes use ``Key: Q`` - to change between sub-modes use ``Key: ctrl-q``.

Selecting Targets
-----------------

When in TWS mode the next target can be selected using ``Key: y`` (can be used several times to cycle between targets). To deselect the current target use ``Key: ctrl-y``.

In other modes use the arrows on your keyboard (``Key: ⇐, ⇒, ⇑, ⇓``) to move the cursor on the VTM. Use ``Key: l`` (small L) to designate a target. You can also bind the cursor movement to your joystick of throttle like the following example (for vertical you just use the ``cursor-slew-y property``)::

    <axis>
        <name>Hat Switch Front Horizontal</name>
        <desc>Slew cursor left/right</desc>
        <number>
            <windows>6</windows>
        </number>
        <binding>
            <command>property-scale</command>
            <property>controls/displays/cursor-slew-x</property>
            <power>1</power>
        </binding>
    </axis>

