# provides relative vectors from eye-point to aircraft lights
# in east/north/up coordinates the renderer uses
# Thanks to BAWV12 / Thorsten

# Put light stuff in a different object inorder to manage different kind of light
# This need to have work in order to initialize the differents lights with the new object
# Then we need to put a foreach loop in the update loop


var als_on = props.globals.getNode("/sim/rendering/shaders/skydome");
var alt_agl = props.globals.getNode("/position/gear-agl-ft");
var cur_alt = 0;

var light_manager = {

	run: 0,
	
	lat_to_m: 110952.0,
	lon_to_m: 0.0,
	
	flcpt: 0,
	prev_view : 1,
	
	
	init: func {
		# define your lights here

		# lights ########
		# offsets to aircraft center
#     light_xpos= 0.0,
#     light_ypos= 0.0,
#     light_zpos= 0.0,
#     light_dir=0,
#     light_size= 0.0,
#     light_stretch= 0.0,
#     light_r= 0.0,
#     light_g= 0.0,
#     light_b= 0.0,
#     light_is_on= 0,
#     number = 0
      me.data_light = [
        ALS_light_spot.new(70,-3,2,2,12,5,0.7,0.7,0.7,1,0),
        ALS_light_spot.new(70, 3,2,-2,12,5,0.7,0.7,0.7,1,1),
        ALS_light_spot.new(-4,5,2,0,3.5,0,0.4,0,0,1,2),
        ALS_light_spot.new(-4,-5,2,0,3.5,0,0,0.4,0,1,3)
      ];

     
#     me.light1 = ALS_light_spot.new(70,-3,2,2,12,5,0.7,0.7,0.7,1,0);
#     me.light2 = ALS_light_spot.new(70, 3,2,-2,12,5,0.7,0.7,0.7,1,1);
    
# 		me.light1_xpos =  -3.10000;
# 		me.light1_ypos =  -0.10927;
# 		me.light1_zpos =  -1.83217;
#     #dir = 0
#     me.light1_r = 0.7;
# 		me.light1_g = 0.7;
# 		me.light1_b = 0.7;
#     me.light1_size = 12;
# 		me.light1_stretch = 6;
		
# 		me.light2_xpos =  -3.10000;
# 		me.light2_ypos =  -0.10927;
# 		me.light2_zpos =  -1.83217;
#     		me.light2_r = 0.6;
# 		me.light2_g = 0.6;
# 		me.light2_b = 0.6;
#     me.light2_size = 6;
# 		me.light2_stretch = 6;
		
		
		setprop("sim/rendering/als-secondary-lights/flash-radius", 13);

		me.start();
	},

	start: func {
		setprop("/sim/rendering/als-secondary-lights/num-lightspots", size(me.data_light));
 
 
		me.run = 1;		
		me.update();
	},

	stop: func {
		me.run = 0;
	},

	update: func {
		if (me.run == 0) {
			return;
		}
		
		cur_alt = alt_agl.getValue();
    if(cur_alt != nil){
      if (als_on.getValue() == 1 and alt_agl.getValue() < 100.0) {
        ll1 = getprop("controls/lighting/landing-lights[1]");
        ll2 = getprop("controls/lighting/landing-lights[2]");
        ll3 = getprop("sim/model/lights/nose-lights");
        nav = getprop("/sim/model/lights/nav-lights");
        ll1_bis = getprop("sim/model/lights/landing/state");

        
  # 			if ((ll1 == 1 and getprop("/systems/electrical/bus/ac1") != 0) and (ll2 == 1 and getprop("/systems/electrical/bus/ac2") !=0)) {
  # 				me.light1_ypos =  0.0;
  # 				me.light1_setSize(16);
  # 				me.light1_on();
  # 			} else if (ll1 == 1 and getprop("/systems/electrical/bus/ac1") != 0) {
  # 				me.light1_ypos =  3.0;
  # 				me.light1_setSize(12);
  # 				me.light1_on();
  # 			} else if (ll2 == 1 and getprop("/systems/electrical/bus/ac2") !=0) {
  # 				me.light1_ypos =  -3.0;
  # 				me.light1_setSize(12);
  # 				me.light1_on();
  # 			} else {
  # 				me.light1_off();
  # 			}
  # 			
  # 			if (ll3 != 0) {
  # 				me.light2_on();
  # 			} else {
  # 				me.light2_off();
  # 			}
  # 			
  # 			if (ll3 == 1) {
  # 				me.light2_setSize(8);
  # 				me.light2_xpos =  65.0;
  # 			} else {
  # 				me.light2_setSize(6);
  # 				me.light2_xpos =  60.0;
  # 			}
  # 			
  # 			if (nav == 1) {
  # 				me.light3_on();
  # 				me.light4_on();
  # 				me.light5_on();
  # 			} else {
  # 				me.light3_off();
  # 				me.light4_off();
  # 				me.light5_off();
  # 			}
        
        for(var i = 0; i < size(me.data_light); i += 1)
        {
          me.data_light[i].position();
        }
        
        
#         me.light1.position();
        #call(me.light2.position,nil,nil,nil, myErr= []);
#         print("Toto:");
#         me.light2.position();

        # light 1 position
  # 			var proj_x = cur_alt;
  # 			var proj_z = cur_alt/10.0;
  # 	 
  # 			apos.set_lat(lat + ((me.light1_xpos + proj_x) * ch + me.light1_ypos * sh) / me.lat_to_m);
  # 			apos.set_lon(lon + ((me.light1_xpos + proj_x)* sh - me.light1_ypos * ch) / me.lon_to_m);
  # 	 
  # 			delta_x = (apos.lat() - vpos.lat()) * me.lat_to_m;
  # 			delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
  # 			var delta_z = apos.alt()- proj_z - vpos.alt();
  # 	 
  # 			me.nd_ref_light1_x.setValue(delta_x);
  # 			me.nd_ref_light1_y.setValue(delta_y);
  # 			me.nd_ref_light1_z.setValue(delta_z);
  # 			me.nd_ref_light1_dir.setValue(heading);			


      }
    }
		
		settimer ( func me.update(), 0.00);
	},
};


var ALS_light_spot = {
    new:func (
            light_xpos,
            light_ypos,
            light_zpos,
            light_dir,
            light_size,
            light_stretch,
            light_r,
            light_g,
            light_b,
            light_is_on,
            number
          ){
            var me = { parents : [ALS_light_spot] };
            if(number ==0){
              me.nd_ref_light_x=  props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m", 1);
              me.nd_ref_light_y=  props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m", 1);
              me.nd_ref_light_z= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m", 1);
              me.nd_ref_light_dir= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/dir", 1);
              me.nd_ref_light_size= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/size", 1);
              me.nd_ref_light_stretch= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/stretch", 1);
              me.nd_ref_light_r=props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-r",1);
              me.nd_ref_light_g=props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-g",1);
              me.nd_ref_light_b=props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-b",1);
            }else{
              me.nd_ref_light_x=  props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m["~number~"]", 1);
              me.nd_ref_light_y=  props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m["~number~"]", 1);
              me.nd_ref_light_z= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m["~number~"]", 1);
              me.nd_ref_light_dir= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/dir["~number~"]", 1);
              me.nd_ref_light_size= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/size["~number~"]", 1);
              me.nd_ref_light_stretch= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/stretch["~number~"]", 1);
              me.nd_ref_light_r=props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-r["~number~"]", 1);
              me.nd_ref_light_g=props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-g["~number~"]", 1);
              me.nd_ref_light_b=props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-b["~number~"]", 1);
            }
            
              me.light_xpos = light_xpos;
              me.light_ypos=light_ypos;
              me.light_zpos=light_zpos;
              me.light_dir=light_dir;
              me.light_size=light_size;
              me.light_stretch=light_stretch;
              me.light_r=light_r;
              me.light_g=light_g;
              me.light_b=light_b;
              me.light_is_on=light_is_on;
              me.number = number;
              
              print("light_stretch:"~light_stretch);
              
              me.lon_to_m  = 0;
              me.lat_to_m = 110952.0;
              me.nd_ref_light_x.setValue(me.light_xpos);
              me.nd_ref_light_y.setValue(me.light_ypos);
              me.nd_ref_light_z.setValue(me.light_zpos);
              me.nd_ref_light_r.setValue(me.light_r);
              me.nd_ref_light_g.setValue(me.light_g);
              me.nd_ref_light_b.setValue(me.light_b);
              me.nd_ref_light_dir.setValue(me.light_dir);
              me.nd_ref_light_size.setValue(me.light_size);
              me.nd_ref_light_stretch.setValue(me.light_stretch);
            
            return me;
    },
    
    position: func(){
      
      cur_alt = alt_agl.getValue();
      var apos = geo.aircraft_position();
			var vpos = geo.viewer_position();

			me.lon_to_m = math.cos(apos.lat()*math.pi/180.0) * me.lat_to_m;
			var heading = getprop("/orientation/heading-deg") * math.pi/180.0;

			var lat = apos.lat();
			var lon = apos.lon();
			var alt = apos.alt();

			var sh = math.sin(heading);
			var ch = math.cos(heading);
      
      var proj_x = cur_alt;
			var proj_z = cur_alt/10.0;
      
      #print("sh:"~sh ~" ch:"~ch~ " proj_x:"~proj_x~ " proj_z:"~proj_z ~" me.light_stretch:"~me.light_stretch);
      #print("me.nd_ref_light_x.getValue():"~me.nd_ref_light_x.getValue() ~ " me.nd_ref_light_y.getValue():"~ me.nd_ref_light_y.getValue());
	 
			apos.set_lat(lat + ((me.light_xpos + proj_x) * ch + me.light_ypos * sh) / me.lat_to_m);
			apos.set_lon(lon + ((me.light_xpos + proj_x)* sh - me.light_ypos * ch) / me.lon_to_m);
      

	 
			var delta_x = (apos.lat() - vpos.lat()) * me.lat_to_m;
			var delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
			var delta_z = apos.alt()- proj_z - vpos.alt();
      
#        print("delta_x:"~delta_x);
	 
			me.nd_ref_light_x.setValue(delta_x);
			me.nd_ref_light_y.setValue(delta_y);
			me.nd_ref_light_z.setValue(delta_z);
			me.nd_ref_light_dir.setValue(heading);	
      
    },
    light_on : func {
      if (me.light_is_on == 1) {return;}
        nd_ref_light_r.setValue(light_r);
        nd_ref_light_g.setValue(light_g);
        nd_ref_light_b.setValue(light_b);
      
      me.light_is_on = 1;
      },
  
    light_off : func {
        if (me.light_is_on == 0) {return;}
        nd_ref_light_r.setValue(0);
        nd_ref_light_g.setValue(0);
        nd_ref_light_b.setValue(0);
      
        me.light_is_on = 0;
      },
    
    light_setSize : func(size) {
      nd_ref_light_size.setValue(size);
    },
  
};

light_manager.init();



