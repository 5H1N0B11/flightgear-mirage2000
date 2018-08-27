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
var fuelTankCenter = stations.FuelTank.new("Center 300 Gal Tank", "300Gal", 4, 300, "sim/model/f16/ventraltank");
var fuelTank370Left = stations.FuelTank.new("Left 370 Gal Tank", "370Gal", 3, 370, "sim/model/f16/wingtankL");
var fuelTank370Right = stations.FuelTank.new("Right 370 Gal Tank", "300Gal", 2, 370, "sim/model/f16/wingtankR");
var fuelTank600Left = stations.FuelTank.new("Left 600 Gal Tank", "600Gal", 3, 600, "sim/model/f16/wingtankL");
var fuelTank600Right = stations.FuelTank.new("Right 600 Gal Tank", "600Gal", 2, 600, "sim/model/f16/wingtankR");

var pylonSets = {
	empty: {name: "Empty", content: [], fireOrder: [], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
	e: {name: "20mm Cannon", content: [cannon], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	f: {name: "300 Gal Fuel tank", content: [fuelTankCenter], fireOrder: [0], launcherDragArea: 0.18, launcherMass: 392, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 1},
	g: {name: "1 x AIM-9", content: ["AIM-9"], fireOrder: [0], launcherDragArea: -0.0785, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#wingtip
	h: {name: "1 x AIM-120", content: ["AIM-120"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#non wingtip
};
#if the total actual sweight is > (total fuel weight + total empty weight) then 
#if (num(getprop("/yasim/gross-weight-lbs")) - num(getprop("/consumables/fuel/total-fuel-lbs")) - 16350 > 10){
#if (getprop("sim/model/f16/wingmounts") != 0) {
if(1){
	# all variants except YF-16 gets store options:

	# source for fuel tanks content, fuel type, jettisonable and drag: TO. GR1F-16CJ-1-1

	# sets
	var InteriorWingSet = [pylonSets.empty,pylonSets.h];
	var ExteriorWingSet  = [pylonSets.empty,pylonSets.g];
	var CenterSet   = [pylonSets.empty, pylonSets.f];
    
	var Forwardfuselagepylons = [pylonSets.empty];
	var Rearfuselagepylons = [pylonSets.empty];


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

    #Exterior wing Load
	pylon2 = stations.Pylon.new("Left Outer Wing Pylon", 1, [0,0,0], ExteriorWingSet, 1, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[2]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[2]",1),func{return getprop("payload/armament/fire-control/serviceable")});
    pylon6 = stations.Pylon.new("Right Wingtip Pylon", 5, [0,0,0], ExteriorWingSet,5, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[5]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[5]",1),func{return getprop("payload/armament/fire-control/serviceable")});
    
    #Interior Wing load
    pylon3 = stations.Pylon.new("Left Inner Wing Pylon", 2, [0,0,0], InteriorWingSet, 2, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[2]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[2]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon5 = stations.Pylon.new("Center Pylon", 4, [0,0,0], InteriorWingSet, 4, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[4]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[4]",1),func{return getprop("payload/armament/fire-control/serviceable")});
        
    #Center Fuselage pylon
	pylon4 = stations.Pylon.new("Left Wing Pylon", 3, [0,0,0], CenterSet,3, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[3]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[3]",1),func{return getprop("payload/armament/fire-control/serviceable")});
    

    #Forward fuselage pylons
    pylon1 = stations.Pylon.new("Left Wingtip Pylon", 0, [0,0,0], Forwardfuselagepylons, 0, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[1]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[1]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon7 = stations.Pylon.new("Right Inner Wing Pylon", 6, [0,0,0], Forwardfuselagepylons, 6, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[6]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[6]",1),func{return getprop("payload/armament/fire-control/serviceable")});
    
    #Rear fuselage pylons
	pylon8 = stations.Pylon.new("Right Wing Pylon", 7, [0,0,0], Rearfuselagepylons, 7, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[7]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[7]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon9 = stations.Pylon.new("Right Outer Wing Pylon", 8, [0,0,0], Rearfuselagepylons, 8, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[8]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[8]",1),func{return getprop("payload/armament/fire-control/serviceable")});
    

    
	pylonI = stations.InternalStation.new("Internal gun mount", 9, [pylonSets.e], props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[10]",1));

	var pylons = [pylon1,pylon2,pylon3,pylon4,pylon5,pylon6,pylon7,pylon8,pylon9,pylonI];

	fcs = fc.FireControl.new(pylons, [9,0,8,1,7,2,6,3,5,4], ["30mm Cannon","MAGIC-2","AIM-120","AIM-7","AGM-65","GBU-12","AGM-84","MK-82","AGM-88", "B61-12", "B61-7", "GBU-31"]);

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

} else {
	# YF-16 only get wingtip aim9 dummies:

	# sets
	var wingtipSet1yf  = [pylonSets.k,pylonSets.k2];# wingtips are normally not empty, so AN-T-17 dummy aim9 is loaded instead.
	var wingtipSet9yf  = [pylonSets.k,pylonSets.k2];# wingtips are normally not empty, so AN-T-17 dummy aim9 is loaded instead.

	# pylons
	pylon1 = stations.Pylon.new("Left Wingtip Pylon", 0, [0,0,0], wingtipSet1yf, 0, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[1]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[1]",1));
	pylon9 = stations.Pylon.new("Right Wingtip Pylon", 8, [0,0,0], wingtipSet9yf, 1, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[9]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[9]",1));
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

#Air patrol configuration
var a2a_patrol = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.q7);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.q7);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
    } else {
      screen.log.write(f16.msgB);
    }
}

# Air superiority configuration
var a2a_super = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
    	pylon1.loadSet(pylonSets.h);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.h);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.h);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.h);
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAP configuration
var a2a_cap = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.h);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.h);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAP extended loiter configuration
var a2a_capext = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.h);
        pylon4.loadSet(pylonSets.l);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.m);
        pylon7.loadSet(pylonSets.h);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
    } else {
      screen.log.write(f16.msgB);
    }
}
# CAS: 2 2XGBU and 2 AGM65
var a2g_cas = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.a);
        pylon4.loadSet(pylonSets.j);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.j);
        pylon7.loadSet(pylonSets.a);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAS extended loiter: 2 3XGBU
var a2g_casext = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.i);
        pylon4.loadSet(pylonSets.l);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.m);
        pylon7.loadSet(pylonSets.i);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
    } else {
      screen.log.write(f16.msgB);
    }
}

# Air Strike : 2 3XGBU and 2 2XMK82
var a2g_mix = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.i);
        pylon4.loadSet(pylonSets.c);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.c);
        pylon7.loadSet(pylonSets.i);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
    } else {
      screen.log.write(f16.msgB);
    }
}

# Guided Air to Ground 1 : 2 JDAM and 2 2XGBU
var a2g_guided1 = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.c3);
        pylon4.loadSet(pylonSets.j);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.j);
        pylon7.loadSet(pylonSets.c3);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
    } else {
      screen.log.write(f16.msgB);
    }
}

# Guided Air to Ground 2 : 2 JDAM and 2 3XGBU
var a2g_guided2 = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.i);
        pylon4.loadSet(pylonSets.c3);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.c3);
        pylon7.loadSet(pylonSets.i);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
    } else {
      screen.log.write(f16.msgB);
    }
}

# Anti-ship: 2 2XGBU and 2 AGM84
var a2s_antiship = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.b);
        pylon4.loadSet(pylonSets.c3);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.c3);
        pylon7.loadSet(pylonSets.b);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
    } else {
      screen.log.write(f16.msgB);
    }
}

# Ferry configuration: 3 droptanks
var a2a_ferry = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.l);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.m);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
    } else {
      screen.log.write(f16.msgB);
    }
}

# Ferry configuration w/ cargo: 2 droptanks, 2 cargopods
var a2a_ferrycargo = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.h);
        pylon2.loadSet(pylonSets.g);
        pylon3.loadSet(pylonSets.f3);
        pylon4.loadSet(pylonSets.l);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.m);
        pylon7.loadSet(pylonSets.f3);
        pylon8.loadSet(pylonSets.g);
        pylon9.loadSet(pylonSets.h);
    } else {
      screen.log.write(f16.msgB);
    }
}

# SEAD: 2 AGM88 and ECM pod
var a2g_sead = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.h);
        pylon2.loadSet(pylonSets.g);
        pylon3.loadSet(pylonSets.b2);
        pylon4.loadSet(pylonSets.l);
        pylon5.loadSet(pylonSets.f2);
        pylon6.loadSet(pylonSets.m);
        pylon7.loadSet(pylonSets.b2);
        pylon8.loadSet(pylonSets.g);
        pylon9.loadSet(pylonSets.h);
    } else {
      screen.log.write(f16.msgB);
    }
}

# OCA: 4 AA missiles and 2 AGM65
var a2g_oca = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.a);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.a);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
    } else {
      screen.log.write(f16.msgB);
    }
}

# Peacetime training configuration
var a2a_training = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.k2);
        pylon2.loadSet(pylonSets.k);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.k);
        pylon9.loadSet(pylonSets.k2);
    } else {
      screen.log.write(f16.msgB);
    }
}

# Clean configuration
var clean = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.empty);
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.empty);
    } else {
      screen.log.write(f16.msgB);
    }
}
