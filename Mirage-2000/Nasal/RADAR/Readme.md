
Prototype to test Richard and radar-mafia's radar designs.

In Richards design, the class called RadarSystem is being represented as AIToNasal, NoseRadar, OmniRadar & TerrainChecker classes.
                    the class called AircraftRadar is represented as ActiveDiscRadar & RWR.
                    the class called AIContact does allow for direct reading of properties, but this is forbidden outside RadarSystem. Except for Missile-code.

 * v1: 7 Nov. 2017 - Modular
 * v2: 8 Nov 2017 - Decoupled via emesary
 * v3: 10 Nov 2017 - NoseRadar now finds everything inside an elevation bar on demand,
                     and stuff is stored in Nasal.
                     Most methods are reused from v2, and therefore the code is a bit messy now, especially method/variable names and AIContact.
                     Weakness:
                       1) Asking NoseRadar for a slice when locked, is very inefficient.
                       2) If RWR should be feed almost realtime data, at least some properties needs to be read all the time for all aircraft. (damn it!)
 * v4: 10 Nov 2017 - Fixed weakness 1 in v3.
 * v5: 11 Nov 2017 - Fixed weakness 2 in v3. And added terrain checker.
 * v5.1 test for shinobi


RCS check done in ActiveDiscRadar at detection time, so about every 5-10 seconds per contact.
     Faster for locks since its important to lose lock if it turns nose to us suddenly and can no longer be seen.
Terrain check done in TerrainChecker, 10 contacts per second. All contacts being evaluated due to rwr needs that.
Doppler is not being done.
Properties is only being read in the modules that represent RadarSystem.




Notice that everything below test code line, is not decoupled, nor optimized in any way.
Also notice that most comments at start of classes are old and not updated.

Needs rcs.nas and vector.nas. Nothing else. When run, it will display a couple of example canvas dialogs on screen.

GPL 2.0