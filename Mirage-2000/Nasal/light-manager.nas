# provides relative vectors from eye-point to aircraft lights
# in east/north/up coordinates the renderer uses
# Thanks to BAWV12 / Thorsten

# 5H1N0B1 201911 :
# Put light stuff in a different object inorder to manage different kind of light
# This need to have work in order to initialize the differents lights with the new object
# Then we need to put a foreach loop in the update loop


var als_on = props.globals.getNode("/sim/rendering/shaders/skydome");
var alt_agl = props.globals.getNode("/position/altitude-agl-ft");
var cur_alt = 0;

var landingLight = props.globals.getNode("systems/electrical/outputs/landing-lights", 1);
var positionLight = props.globals.getNode("systems/electrical/outputs/position", 1);
var gearPos = props.globals.getNode("gear/gear[0]/position-norm", 1);


var light_manager = {

	run: 0,
	
	lat_to_m: 110952.0,
	lon_to_m: 0.0,
	
	flcpt: 0,
	prev_view : 1,
	
	
	init: func {
		# define your lights here

		# lights ########
    #xpos,ypos,zpos,dir, size,stretch, r,g,b,is_on,number
      me.data_light = [
        ALS_light_spot.new(62,-3,2,2,12,5,0.7,0.7,0.7,1,0),
        ALS_light_spot.new(62, 3,2,-2,12,5,0.7,0.7,0.7,1,1),
        ALS_light_spot.new(-8.5,4.5,2,0,3.5,0,0.4,0,0,1,2),
        ALS_light_spot.new(-8.5,-4.5,2,0,3.5,0,0,0.4,0,1,3)
      ];

		
		
		setprop("sim/rendering/als-secondary-lights/flash-radius", 13);
    #print("Light init");

		me.start();
	},

	start: func {
    #print("Light start");
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
		#print("me.run != 0");
		cur_alt = alt_agl.getValue();
    if(cur_alt != nil){
      #print("cur_alt != nil");
      if (als_on.getValue() == 1 and alt_agl.getValue() < 100.0) {
          #print("als_on.getValue() == 1 and alt_agl.getValue() < 100.0");
          #Condition for lights
          if(gearPos.getValue() > 0.3 and landingLight.getValue()){
              #print("gearPos.getValue() > 0.3 and landingLight.getValue()");
              me.data_light[0].light_on();
              me.data_light[1].light_on();              
          }else{
              me.data_light[0].light_off();
              me.data_light[1].light_off(); 
          }
          
          if(positionLight.getValue()){
              me.data_light[2].light_on();
              me.data_light[3].light_on();              
          }else{
              me.data_light[2].light_off();
              me.data_light[3].light_off(); 
          }
          
          
         #Updating each light position 
        for(var i = 0; i < size(me.data_light); i += 1)
        {
          me.data_light[i].position();
        }
      }
    }
		
		settimer ( func me.update(), 0.00);
	},
};

#xpos,ypos,zpos,dir, size,stretch, r,g,b,is_on,number
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
              
              #print("light_stretch:"~light_stretch);
              
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
        me.nd_ref_light_r.setValue(me.light_r);
        me.nd_ref_light_g.setValue(me.light_g);
        me.nd_ref_light_b.setValue(me.light_b);
        me.light_is_on = 1;
      },
  
    light_off : func {
        if (me.light_is_on == 0) {return;}
        me.nd_ref_light_r.setValue(0);
        me.nd_ref_light_g.setValue(0);
        me.nd_ref_light_b.setValue(0);
        me.light_is_on = 0;
      },
    
    light_setSize : func(size) {
      me.nd_ref_light_size.setValue(size);
    },
  
};

light_manager.init();



