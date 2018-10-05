print("*** LOADING pylons.nas ... ***");

var TRUE=1;
var FALSE=0;

var fcs = nil;
var pylon1 = nil;
var pylon2 = nil;
var pylon3 = nil;
var pylon4 = nil;
var pylon5 = nil;
var pylon6 = nil;
var pylon7 = nil;
var pylon8 = nil;
var pylon9 = nil;
var pylonI = nil;

var cannon = stations.SubModelWeapon.new("30mm Cannon", 0.9369635, 120, 2, [1,2], props.globals.getNode("controls/armament/Gun_trigger",1), 0, func{return 1;});

#5H1NB1's notes : To check : It seems that the weight of the tank itself isn't taking in account
#Not because of the fc code, but because I didn't find where to put it
var RP522 = stations.FuelTank.new("1300 l Droptank", "RP522", 3, 343, "mirage/center1300TankMounted");

var RP542 = stations.FuelTank.new("2000 l Droptank", "RP542", 2, 528, "mirage/center2000TankMountedR");
var RP541 = stations.FuelTank.new("2000 l Droptank", "RP541", 4, 528, "mirage/center2000TankMountedL");

var RP502 = stations.FuelTank.new("1700 l Droptank", "RP502", 2, 448, "mirage/center1700TankMountedR");
var RP501 = stations.FuelTank.new("1700 l Droptank", "RP501", 4, 448, "mirage/center1700TankMountedL");

var dummy1 = stations.Dummy.new("PDLCT", "PDLCT");
var dummy2 = stations.Dummy.new("ASMP", "ASMP");

# content = folder name with upper and lower case
#name = what will be in the -set, the 3D displaying underwings

#Lowercase: flags, xml, payload.xml(<tag>)
#Normal: folder, content, firecontrol, damage

var pylonSets = {
	empty: {name: "none", content: [], fireOrder: [], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
	e: {name: "30mm Cannon", content: [cannon], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	t: {name: "1300 l Droptank", content: [RP522], fireOrder: [0], launcherDragArea: 0.18, launcherMass: 392, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 1},
  t2: {name: "2000 l Droptank", content: [RP542], fireOrder: [0], launcherDragArea: 0.18, launcherMass: 392, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 1},
  tb2: {name: "1700 l Droptank", content: [RP502], fireOrder: [0], launcherDragArea: 0.18, launcherMass: 392, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 1},
  t4: {name: "2000 l Droptank", content: [RP541], fireOrder: [0], launcherDragArea: 0.18, launcherMass: 392, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 1},
  tb4: {name: "1700 l Droptank", content: [RP501], fireOrder: [0], launcherDragArea: 0.18, launcherMass: 392, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 1},
	g: {name: "Matra R550 Magic 2", content: ["Magic-2"], fireOrder: [0], launcherDragArea: -0.0785, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},#wingtip
	g2: {name: "MICA IR", content: ["MICA-IR"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	
	h: {name: "Matra Super 530D", content: ["S530D"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},#non wingtip
	
  i: {name: "MICA EM", content: ["MICA-EM"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
  
  s: {name: "PDLCT", content: [dummy1], fireOrder: [0], launcherDragArea: 0.18, launcherMass: 410, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 1},
	b2: {name: "2 x GBU-12", content: ["GBU-12", "GBU-12"], fireOrder: [0,1], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 2},
  b3: {name: "SCALP", content: ["SCALP"], fireOrder: [0], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 2},
  b4: {name: "AM39-Exocet", content: ["AM39-Exocet"], fireOrder: [0], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 2},
  b5: {name: "AS-37-Martel", content: ["AS-37-Martel"], fireOrder: [0], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 2},
  b6: {name: "AS30L", content: ["AS30L"], fireOrder: [0], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 2},
  b10: {name: "ASMP", content: [dummy2], fireOrder: [0], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 2},
};
#if the total actual sweight is > (total fuel weight + total empty weight) then 
#if (num(getprop("/yasim/gross-weight-lbs")) - num(getprop("/consumables/fuel/total-fuel-lbs")) - 16350 > 10){
#if (getprop("sim/model/f16/wingmounts") != 0) {
if(1){
	# all variants except YF-16 gets store options:

	# source for fuel tanks content, fuel type, jettisonable and drag: TO. GR1F-16CJ-1-1

	# sets
	var InteriorWingSetR = [pylonSets.empty,pylonSets.h,pylonSets.t2,pylonSets.tb2,pylonSets.b4,pylonSets.b5,pylonSets.b6];
  var InteriorWingSetL = [pylonSets.empty,pylonSets.h,pylonSets.t4,pylonSets.tb4,pylonSets.b4,pylonSets.b5,pylonSets.b6];
	var ExteriorWingSet  = [pylonSets.empty,pylonSets.g,pylonSets.g2];
	var CenterSet   = [pylonSets.empty, pylonSets.t,pylonSets.b2,pylonSets.b3,pylonSets.b10];
    
	var ForwardfuselagepylonsR = [pylonSets.empty,pylonSets.i,pylonSets.s];
  var ForwardfuselagepylonsL = [pylonSets.empty,pylonSets.i,];
  
  
	var Rearfuselagepylons = [pylonSets.empty,pylonSets.i];


#### note :
# pylon options
#
# BOTTOM VIEW
#  _________________|___|_________________
#  \                |   |                /
#   \               |   |               /
#    \2.L        4.L|   |4.R        2.R/
#     (1)        (7)|   |(8)        (5)
#      \   3.L      |   |      3.R   /
#       \  (2)      |   |      (4)  /
#        \          |   |          /
#         \         |   |         /
#          \        |   |        /
#           \       |.C |       /
#            \      |(3)|      /
#             \     |   |     /
#              \ 1.L|   |1.R /
#               \(0)|   |(6)/
#                \  |   |  /
#                 \ |   | /
#                  \|___|/
#
# station left 1 (Index 0)    
    
    #new(name of pylon (for dialog), id number, position of pylon in meters, all possible allowed sets, id number for fuel dialog, property for mass of pylon, property for drag of pylon, 
    #opFunction for test if pylon is working)

	# pylons

#   		me.x = me.pylon_prop.getNode("offsets/x-m").getValue();
# 		me.y = me.pylon_prop.getNode("offsets/y-m").getValue();
# 		me.z = me.pylon_prop.getNode("offsets/z-m").getValue();
  
  
#Pylon2.L (2.373;-3.278 ;-1.494)
#Pylon2.R (2.373; 3.278 ;-1.494)

#Pylon3.L (1.047;-2.359;-1.556)
#Pylon3.R (1.047; 2.359;-1.556) 
 
#pylon.C (1.082;0.000;-1.656)
  
#pylon1.L (-1.265;-0.824;-1.370)
#pylon1.L (-1.265; 0.824;-1.370)
  
#pylonB.L (3.360;-0.920;-1.380)
#pylonB.L (3.360; 0.920;-1.380)
  
  
  #Exterior wing Load
	pylon2 = stations.Pylon.new("pylon2.L", 1, [2.373,-3.278,-1.494], ExteriorWingSet, 1, props.globals.getNode("yasim/weight[1]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[2]",1),func{return getprop("payload/armament/fire-control/serviceable")});
  pylon6 = stations.Pylon.new("pylon2.R", 5, [2.373,3.278,-1.494], ExteriorWingSet,5, props.globals.getNode("yasim/weight[5]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[5]",1),func{return getprop("payload/armament/fire-control/serviceable")});
    
  #Interior Wing load
  pylon3 = stations.Pylon.new("pylon3.L", 2, [1.047,-2.359,-1.556], InteriorWingSetR, 2, props.globals.getNode("yasim/weight[2]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[2]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon5 = stations.Pylon.new("pylon3.R", 4, [1.047,2.359,-1.556], InteriorWingSetL, 4, props.globals.getNode("yasim/weight[4]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[4]",1),func{return getprop("payload/armament/fire-control/serviceable")});
        
  #Center Fuselage pylon
	pylon4 = stations.Pylon.new("pylon.C", 3, [1.082,0,-1.656], CenterSet,3, props.globals.getNode("yasim/weight[3]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[3]",1),func{return getprop("payload/armament/fire-control/serviceable")});
    

  #Forward fuselage pylons
  pylon1 = stations.Pylon.new("pylon1.L", 0, [-1.265,-0.824,-1.370], ForwardfuselagepylonsL, 0, props.globals.getNode("yasim/weight[1]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[1]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon7 = stations.Pylon.new("pylon1.R", 6, [-1.265,0.824,-1.370], ForwardfuselagepylonsR, 6, props.globals.getNode("yasim/weight[6]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[6]",1),func{return getprop("payload/armament/fire-control/serviceable")});
    
  #Rear fuselage pylons
	pylon8 = stations.Pylon.new("pylonB.L", 7, [3.360,-0.920,-1.380], Rearfuselagepylons, 7, props.globals.getNode("yasim/weight[7]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[7]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon9 = stations.Pylon.new("pylonB.R", 8, [3.360,0.920,-1.380], Rearfuselagepylons, 8, props.globals.getNode("yasim/weight[8]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[8]",1),func{return getprop("payload/armament/fire-control/serviceable")});
    

    
	pylonI = stations.InternalStation.new("Internal gun mount", 9, [pylonSets.e], props.globals.getNode("yasim/weight[10]",1));

	var pylons = [pylon1,pylon2,pylon3,pylon4,pylon5,pylon6,pylon7,pylon8,pylon9,pylonI];

	fcs = fc.FireControl.new(pylons, [9,0,8,1,7,2,6,3,5,4], ["30mm Cannon","Magic-2","S530D","MICA-IR","MICA-EM","GBU-12","SCALP","AM39-Exocet","AS-37-Martel","AS30L"]);
  
  

	var aimListener = func (obj) {
		#If auto focus on missile is activated the we call the function
        if(getprop("/controls/armament/automissileview"))# and !getprop("payload/armament/msg")
        {
          view.view_firing_missile(obj);
        } 
    };
    pylon1.setAIMListener(aimListener);
    pylon2.setAIMListener(aimListener);
    pylon3.setAIMListener(aimListener);
    pylon4.setAIMListener(aimListener);
    pylon5.setAIMListener(aimListener);
    pylon6.setAIMListener(aimListener);
    pylon7.setAIMListener(aimListener);
    pylon8.setAIMListener(aimListener);
    pylon9.setAIMListener(aimListener);

}

#print("** Pylon & fire control system started. **");
var getDLZ = func {
    if (fcs != nil and getprop("controls/armament/master-arm") == 1) {
        var w = fcs.getSelectedWeapon();
        if (w!=nil and w.parents[0] == armament.AIM) {
            var result = w.getDLZ(1);
            if (result != nil and size(result) == 5 and result[4]<result[0]*1.5 and armament.contact != nil and armament.contact.get_display()) {
                #target is within 150% of max weapon fire range.
        	    return result;
            }
        }
    }
    return nil;
}



# Lisse : means literrally "slick" or "bald"  : no load at all : "empty"
var lisse = func { 
  if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("/gear/gear[2]/wow")) {
        #External wings
        pylon2.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        
        #Internal wing
        pylon3.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        
        #Center Fuselage
        pylon4.loadSet(pylonSets.empty);
        
        #Side fuselage forward
        pylon1.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        
        #Side fuselage backward
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.empty);
    } else {
      screen.log.write(mirage2000.msgB);
    }
  }




# PO : permanence opérationnelle : Scramble
var a2a_po_old = func { 
  if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("/gear/gear[2]/wow")) {
        #External wings
        pylon2.loadSet(pylonSets.g);
        pylon6.loadSet(pylonSets.g);
        
        #Internal wing
        pylon3.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        
        #Center Fuselage
        pylon4.loadSet(pylonSets.t);
        
        #Side fuselage forward
        pylon1.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        
        #Side fuselage backward
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.empty);
    } else {
      screen.log.write(mirage2000.msgB);
    }
  }


# Fox configuration : 1 center tank
var a2a_fox_old = func { 
  if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("/gear/gear[2]/wow")) {
        #External wings
        pylon2.loadSet(pylonSets.g);
        pylon6.loadSet(pylonSets.g);
        
        #Internal wing
        pylon3.loadSet(pylonSets.h);
        pylon5.loadSet(pylonSets.h);
        
        #Center Fuselage
        pylon4.loadSet(pylonSets.t);
        
        #Side fuselage forward
        pylon1.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        
        #Side fuselage backward
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.empty);
    } else {
      screen.log.write(mirage2000.msgB);
    }
  }
  
# Fox Mix configuration : 1 center tank
var a2a_fox_mix = func { 
  if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("/gear/gear[2]/wow")) {
        #External wings
        pylon2.loadSet(pylonSets.g);
        pylon6.loadSet(pylonSets.g);
        
        #Internal wing
        pylon3.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        
        #Center Fuselage
        pylon4.loadSet(pylonSets.t);
        
        #Side fuselage forward
        pylon1.loadSet(pylonSets.i);
        pylon7.loadSet(pylonSets.i);
        
        #Side fuselage backward
        pylon8.loadSet(pylonSets.i);
        pylon9.loadSet(pylonSets.i);
    } else {
      screen.log.write(mirage2000.msgB);
    }
  }

  

# Fox configuration : 1 center tank. Most recent configuration
var a2a_fox_mica = func { 
  if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("/gear/gear[2]/wow")) {
        #External wings
        pylon2.loadSet(pylonSets.g2);
        pylon6.loadSet(pylonSets.g2);
        
        #Internal wing
        pylon3.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        
        #Center Fuselage
        pylon4.loadSet(pylonSets.t);
        
        #Side fuselage forward
        pylon1.loadSet(pylonSets.i);
        pylon7.loadSet(pylonSets.i);
        
        #Side fuselage backward
        pylon8.loadSet(pylonSets.i);
        pylon9.loadSet(pylonSets.i);
    } else {
      screen.log.write(mirage2000.msgB);
    }
  }

  # Bravo Mix configuration : 2 wing tanks
  var a2a_bravo_mix = func { 
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("/gear/gear[2]/wow")) {
          #External wings
          pylon2.loadSet(pylonSets.g);
          pylon6.loadSet(pylonSets.g);
          
          #Internal wing
          pylon3.loadSet(pylonSets.t2);
          pylon5.loadSet(pylonSets.t4);
          
          #Center Fuselage
          pylon4.loadSet(pylonSets.empty);
          
          #Side fuselage forward
          pylon1.loadSet(pylonSets.i);
          pylon7.loadSet(pylonSets.i);
          
          #Side fuselage backward
          pylon8.loadSet(pylonSets.i);
          pylon9.loadSet(pylonSets.i);
      } else {
        screen.log.write(mirage2000.msgB);
      }
  }
  
  # Kilo configuration : 1 center tank, 2 wing tanks +  Most recent missile configuration
var a2a_kilo_mica = func { 
  if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("/gear/gear[2]/wow")) {
        #External wings
        pylon2.loadSet(pylonSets.g2);
        pylon6.loadSet(pylonSets.g2);
        
        #Internal wing
        pylon3.loadSet(pylonSets.t2);
        pylon5.loadSet(pylonSets.t4);
        
        #Center Fuselage
        pylon4.loadSet(pylonSets.t);
        
        #Side fuselage forward
        pylon1.loadSet(pylonSets.i);
        pylon7.loadSet(pylonSets.i);
        
        #Side fuselage backward
        pylon8.loadSet(pylonSets.i);
        pylon9.loadSet(pylonSets.i);
    } else {
      screen.log.write(mirage2000.msgB);
    }
  }

  
  # Ground Attack configuration : 2 wing tanks, 2 x GBU-12, 2 magic2
  var a2g_bravo_mix = func { 
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("/gear/gear[2]/wow")) {
          #External wings
          pylon2.loadSet(pylonSets.g);
          pylon6.loadSet(pylonSets.g);
          
          #Internal wing
          pylon3.loadSet(pylonSets.t2);
          pylon5.loadSet(pylonSets.t4);
          
          #Center Fuselage
          pylon4.loadSet(pylonSets.b2);
          
          #Side fuselage forward
          pylon1.loadSet(pylonSets.empty);
          pylon7.loadSet(pylonSets.s);
          
          #Side fuselage backward
          pylon8.loadSet(pylonSets.empty);
          pylon9.loadSet(pylonSets.empty);
      } else {
        screen.log.write(mirage2000.msgB);
      }
  }
  
  # Anti radar configation : double martel, center tank double magix2
  var a2ouadi_fox = func { 
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("/gear/gear[2]/wow")) {
          #External wings
          pylon2.loadSet(pylonSets.g);
          pylon6.loadSet(pylonSets.g);
          
          #Internal wing
          pylon3.loadSet(pylonSets.b5);
          pylon5.loadSet(pylonSets.b5);
          
          #Center Fuselage
          pylon4.loadSet(pylonSets.t);
          
          #Side fuselage forward
          pylon1.loadSet(pylonSets.empty);
          pylon7.loadSet(pylonSets.empty);
          
          #Side fuselage backward
          pylon8.loadSet(pylonSets.empty);
          pylon9.loadSet(pylonSets.empty);
      } else {
        screen.log.write(mirage2000.msgB);
      }
    }
  
  # Air to Sea configuration : double exocet, center tank double magix2
  var a2s_fox = func { 
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("/gear/gear[2]/wow")) {
          #External wings
          pylon2.loadSet(pylonSets.g);
          pylon6.loadSet(pylonSets.g);
          
          #Internal wing
          pylon3.loadSet(pylonSets.b4);
          pylon5.loadSet(pylonSets.b4);
          
          #Center Fuselage
          pylon4.loadSet(pylonSets.t);
          
          #Side fuselage forward
          pylon1.loadSet(pylonSets.empty);
          pylon7.loadSet(pylonSets.empty);
          
          #Side fuselage backward
          pylon8.loadSet(pylonSets.empty);
          pylon9.loadSet(pylonSets.empty);
      } else {
        screen.log.write(mirage2000.msgB);
      }
    }
  
    # Ground Attack configuration : 2 wing tanks, 2 x GBU-12, 2 magic2
  var nuke = func { 
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("/gear/gear[2]/wow")) {
          #External wings
          pylon2.loadSet(pylonSets.g);
          pylon6.loadSet(pylonSets.g);
          
          #Internal wing
          pylon3.loadSet(pylonSets.t2);
          pylon5.loadSet(pylonSets.t4);
          
          #Center Fuselage
          pylon4.loadSet(pylonSets.b10);
          
          #Side fuselage forward
          pylon1.loadSet(pylonSets.empty);
          pylon7.loadSet(pylonSets.empty);
          
          #Side fuselage backward
          pylon8.loadSet(pylonSets.empty);
          pylon9.loadSet(pylonSets.empty);
      } else {
        screen.log.write(mirage2000.msgB);
      }
  }
  
  
  
  
  
  #Variable declaration
  var pylonSetListener = [];
  var pylonCountListener = [];
  var maxPylons = 9;
  var AllPossibleLoads = std.Vector.new();
  
  #Loading a vector with the Set names
  foreach(key;keys(pylonSets)) {
    #print(pylonSets[key].name);   <--- Uncomment this line to have the list displayed in the console
    AllPossibleLoads.append(pylonSets[key].name);
  }
  
  #This is the array that allow us to decode it it has to be the same as  "AllPossibleLoads"
  #To know what in it uncomment : "print(pylonSets[key].name);"
  #ACtually, here this list is useless : but it need to be the exact same in MP.nas
  loadList = [
    "2000 l Droptank",
    "SCALP",
    "1700 l Droptank",
    "AM39-Exocet",
    "2 x GBU-12",
    "1700 l Droptank",
    "AS-37-Martel",
    "PDLCT",
    "Matra Super 530D",
    "AS30L",
    "30mm Cannon",
    "none",
    "MICA IR",
    "1300 l Droptank",
    "Matra R550 Magic 2",
    "2000 l Droptank",
    "MICA EM",
    "ASMP"
  ];

  
  #Decoding String => Not needed anymore. Just for information
  var decodeStations = func(){
    
    String = getprop("sim/multiplay/generic/string[1]");    
    #Index of the beguining of each set string
    var mySetIndexArray = [];
    #Index of the beguining of each count string
    var myCountIndexArray = [];
    
    for(i = 0 ; i < size(String) ; i += 1)
    {
        if(chr(String[i]) == '#'){append(mySetIndexArray, i);}
        if(chr(String[i]) == 'C'){append(myCountIndexArray, i);}
    }
    
    var i = 0;
    forindex(i; mySetIndexArray){
      var mySet = substr(String, mySetIndexArray[i] + 1, myCountIndexArray[i]-mySetIndexArray[i]-1);
      #print("myCountIndexArray[i]:"~myCountIndexArray[i]~ " size(String):"~ size(String));
      if(i+1<size(mySetIndexArray)){
        var myCount = substr(String, myCountIndexArray[i] + 1, mySetIndexArray[i+1] - myCountIndexArray[i]-1);
      }else{
        var myCount = substr(String, myCountIndexArray[i] + 1, size(String) - myCountIndexArray[i]-1);
      }
      #print(mySet);
      #print(myCount);
      #print(AllPossibleLoads.vector[mySet]);
      #setprop("payload/armament/station/id-" ~ i ~ "-set",loadList[mySet]);
      #setprop("payload/armament/station/id-" ~ i ~ "-count",myCount);
    }
  
    
  }
  

  #Encoding string String
  var codeStations = func(){
    var compiled = "";
    for(var i = 0 ; i <= maxPylons ; i += 1){
        # Load name
        var myTempoSet = getprop("/payload/armament/station/id-" ~ i ~ "-set");
        var myTempoCount = getprop("/payload/armament/station/id-" ~ i ~ "-count");
        
        compiled = compiled  ~ "#" ~ AllPossibleLoads.index(myTempoSet) ~ "C" ~ myTempoCount;
        #print("myTempoSet" ~ myTempoSet ~ " and Vector index :" ~ AllPossibleLoads.index(myTempoSet) ~ ":"~ AllPossibleLoads.vector[AllPossibleLoads.index(myTempoSet)]);
    }
    #print(compiled);
    setprop("sim/multiplay/generic/string[1]", compiled);
  }
  
  
  #Set up Listener for pylons properties
  #i is the pylon number
  var setEncodeMPListener = func(i){
    var tempSet = setlistener("/payload/armament/station/id-" ~ i ~ "-set",func {
                    #print(i);
                    codeStations();
                  }, 1, 0);
    var tempCount = setlistener("/payload/armament/station/id-" ~ i ~ "-count",func {
                      codeStations();
                    }, 1, 0);
    
    append( pylonSetListener, tempSet);
    append( pylonCountListener, tempCount);
  }
  
  #loop for all listener (20 => because I'm lazy)
  for(var i = 0 ; i <= maxPylons ; i += 1){
    setEncodeMPListener(i);
  }
  

