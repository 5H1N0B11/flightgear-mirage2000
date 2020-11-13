
Prototype to test Richard and radar-mafia's radar designs.

In Richards design, the class called RadarSystem is being represented as AIToNasal, NoseRadar, OmniRadar & TerrainChecker classes.
                    the class called AircraftRadar is represented as ActiveDiscRadar & RWR.
                    the class called AIContact does allow for direct reading of properties, but this is forbidden outside RadarSystem. Except for Missile-code.

 * v1.0: 7 Nov. 2017 - Modular
 * v2.0: 8 Nov 2017 - Decoupled via emesary
 * v3.0: 10 Nov 2017 - NoseRadar now finds everything inside an elevation bar on demand,
                     and stuff is stored in Nasal.
                     Most methods are reused from v2, and therefore the code is a bit messy now, especially method/variable names and AIContact.
                     Weakness:
                       1) Asking NoseRadar for a slice when locked, is very inefficient.
                       2) If RWR should be feed almost realtime data, at least some properties needs to be read all the time for all aircraft. (damn it!)
 * v4.0: 10 Nov 2017 - Fixed weakness 1 in v3.
 * v5.0: 11 Nov 2017 - Fixed weakness 2 in v3. And added terrain checker.
 * v5.1 test for shinobi
 * v6.0: 13 Nov 2020 - Complete refactor into a new prototype (decoupling generic radar modules).
--------
Dependencies:
  - FGUM_LA
  - FGUM_RCSDatabase
  - FGUM_Contact
  - FGUM_Radar
  
GPL 2.0