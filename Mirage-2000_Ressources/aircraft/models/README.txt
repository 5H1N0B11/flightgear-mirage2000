hardball 2020-01-03


blender layers
==============
A1 A2 A3 A4 A5 | A6 A7 A8 A9 A10
B1 B2 B3 B4 B5 | B6 B7 B8 B9 B10

content of the layers :
A1- common objects (wings, gears, windshield, etc)
A2- BIPLACE : fixed and mobile exterior parts (backbone, canopy pilot and navigator)
A3- BIPLACE : logos
A4- BIPLACE : fixed and mobile interior parts (cockpit, seats, canopy)
A5- common static panel
B1- common logos
B2- MONOPLACE : fixed and mobile exterior parts (backbone, canopy pilot)
B3- MONOPLACE : logos
B4- MONOPLACE : fixed and mobile interior parts (cockpit, seat, canopy)
B5- mobile monoplace interior parts (canopy)

A6- common dynamic panel and instruments
B6- radar

B10- ground equipments



export ac
=========

layers used to export ac models
-------------------------------
- m2000-5.ac = layers A1, A2, B2 (monoplace or biplace parts will be hidden by xml)
- logos.ac = layers B1, A3, B3
- interiorB.ac = layers A4
- interior.ac = layers B4
- panel.ac = layer A5

instruments
-----------
0- show layer A6
for each dynamic separated instrument (transparent, animated, illuminated) :
  1- hide recursively group panel (ctrl + eye logo)
  2- show recursively 1 instrument group
  3- export .ac

















