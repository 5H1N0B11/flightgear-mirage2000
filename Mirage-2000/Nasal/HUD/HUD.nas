print("*** LOADING HUD.nas ... ***");
################################################################################
#
#                     m2005-5's HUD AI/MP SETTINGS
#
################################################################################

var target_marker = func()
{
    # draw hud markers on top of each AI/MP target
    #SGPropertyNode * models = globals->get_props()->getNode("/ai/models", true);
    #for(int i = 0 ; i < models->nChildren() ; i += 1)
    #{
        # @TODO: hardball : I don't understand this line :
       # SGPropertyNode * chld = models->getChild(i);
        #string name;
        #name = chld->getName();
        #if(name == "aircraft" || name == "multiplayer" || type == "tanker" || type == "carrier")
        #{
          #  string callsign = chld->getStringValue("callsign");
            #if(callsign != "")
            #{
             #   float h_deg = chld->getFloatValue("radar/h-offset");
             #   float v_deg = chld->getFloatValue("radar/v-offset");
              #  float pos_x = (h_deg * cos(roll_value) - v_deg * sin(roll_value)) * _compression;
                #float pos_y = (v_deg * cos(roll_value) + h_deg * sin(roll_value)) * _compression;
               # draw_circle(pos_x, pos_y, 8);
           # }
        #}
    #}
}

var x_view = props.globals.getNode("sim/current-view/x-offset-m");
var y_view = props.globals.getNode("sim/current-view/y-offset-m");
var z_view = props.globals.getNode("sim/current-view/z-offset-m");

var Hud_Position = [-0.0005,0.0298,-3.16320];
var PilotCurrentView = [x_view.getValue(),y_view.getValue(),z_view.getValue()];

var pow2 = func(x) { return x * x; };
var vec_length = func(x, y,z=0) { return math.sqrt(pow2(x) + pow2(y)+pow2(z)); };


#Nodes values variables
var mydeviation = 0;
var myelevation = 0;
var displayIt = 0;
var target_callsign = "";
var target_altitude = 0;
var target_closureRate = 0;
var target_heading_deg = 0;
var target_Distance = 0;
var raw_list = [];


#verre2

# ==============================================================================
# Head up display
# ==============================================================================

var pow2 = func(x) { return x * x; };
var vec_length = func(x, y) { return math.sqrt(pow2(x) + pow2(y)); };
var round0 = func(x) { return math.abs(x) > 0.01 ? x : 0; };
var clamp = func(x, min, max) { return x < min ? min : (x > max ? max : x); }

#canvas.
#the canvas is wider than the actual hud : so display start at 16,7% of the hud and end at 84,3% (100%-16.7%)
#vertical is 100%
#the HUD is slanted. Angle : 40%
#Canvs start upper right
#x is positive rightwards. y is positive downwards
#480,480 --> (140,-150) - (150,200)
#Canvas coordinates :
#X: 80 to 400
#Y: 27.36 to 456.89

 #HUD Position : x,y,z
#left lower corner (-0.07606, -0.07327, -0.03237) 
#right upper corner (0.05357, 0.07327, 0.11536)
#Center HUD : (-0.12963,0,0.08299)

#OFFSET1 panel.xml :<offsets><x-m> 0.456 </x-m> <y-m> 0.000 </y-m><z-m> 0.159 </z-m></offsets>
#OFFSET2  interior.xml <offsets><x-m> -3.653 </x-m> <y-m>  0.000 </y-m>  <z-m> -0.297 </z-m>      <pitch-deg> -14 </pitch-deg>    </offsets>

#TO do = update distance to HUD in fonction of the position on it : if vertical on 2D HUD is high, distance should be lower.
#find a trigonometric way to calculate the y position (2D HUD) as the real hud have around 45° of inclinaison.
#Make it happen for all non null radar properies
#Make null properties hidded



#var centerHUDx = (-0.07606 + 0.05357)/2;
#var centerHUDy = (-0.07327 +0.07327)/2;
#var centerHUDz = (-0.03237 +0.11536)/2;


#centerHUDx = centerHUDx+0.456-3.653;
#centerHUDy = centerHUDy;
#centerHUDz = centerHUDz+0.159-0.297;
#centerHUDz = 0.040;

#leftbottom: -3.20962,-0.067,-0.15438
#righttop: -3.20962, 0.067,-0.02038

centerHUDx = -3.20962;
centerHUDy = 0;
centerHUDz = (-0.15438 + -0.02038)/2;
var heightMeters = 0.067-(-0.067);
var wideMeters = math.abs(-0.02038 - (-0.15438));


#Pilot position: 
#Pilotz = getprop("sim/view[0]/config/y-offset-m"); 
#Pilotx = getprop("sim/view[0]/config/z-offset-m");
#Piloty = getprop("sim/view[0]/config/x-offset-m");

#var raw_list = props.globals.getNode("instrumentation/radar2/targets").getChildren();
#print("Size:" ~ size(raw_list));
var MaxTarget = 15;


#center of the hud



var HUD = {
  canvas_settings: {
    "name": "HUD",
    "size": [1024,1024],#<-- size of the texture
    "view": [480, 480], #<- Size of the coordinate systems (the bigger the sharpener)
    "mipmapping": 0
  },
  new: func(placement)
  {
    var m = {
      parents: [HUD],
      canvas: canvas.new(HUD.canvas_settings)
    };
    m.viewPlacement = 480;
    m.min = -m.viewPlacement * 0.846;
    m.max = m.viewPlacement * 0.846;

    m.canvas.addPlacement(placement);
    #m.canvas.setColorBackground(red, green, blue, 0.0);
    m.canvas.setColorBackground(0.36, 1, 0.3, 0.02);
    
    m.root =
      m.canvas.createGroup()
              #.setScale(1, 1/math.cos(45 * D2R))
              .setTranslation(240, 240)
              .set("font", "LiberationFonts/LiberationMono-Regular.ttf")
              .setDouble("character-size", 18)
              .setDouble("character-aspect-ration", 0.9)
              .set("stroke", "rgba(0,255,0,0.9)");
    m.text =
      m.root.createChild("group")
            .set("fill", "rgba(0,255,0,0.9)");
            
            
    m.Fire_GBU =
      m.text.createChild("text")
            .setAlignment("right-center")
            .setTranslation(220, 70)
            .setDouble("character-size", 42);
            
   
    # Radar altidude
    m.rad_alt =
      m.text.createChild("text")
            .setAlignment("right-center")
            .setTranslation(220, 70);


    # Horizon
    m.horizon_group = m.root.createChild("group");
    m.h_trans = m.horizon_group.createTransform();
    m.h_rot   = m.horizon_group.createTransform();
    
  
    # Horizon line
    m.horizon_group.createChild("path")
                   .moveTo(-500, 0)
                   .horizTo(500)
                   .setStrokeLineWidth(1.5);
    m.radarStuffGroup = m.root.createChild("group");
                     
      
   ##################################### Circle ####################################
    m.targetArray = [];
    m.circle_group2 = m.radarStuffGroup.createChild("group");
    for(var i = 1; i <= MaxTarget; i += 1){
      myCircle = m.circle_group2.createChild("path")
        .moveTo( 10, 0)
        .arcSmallCW(15,15, 0, -30, 0)
        .arcSmallCW(15,15, 0, 30, 0)
        .setStrokeLineWidth(4)
        .set("stroke", "rgba(0,180,0,0.9)");
      append(m.targetArray, myCircle);
    }
    m.targetrot   = m.circle_group2.createTransform();
  
    ####################### Info Text ########################################
    m.TextInfoArray = [];
    m.TextInfoGroup = m.radarStuffGroup.createChild("group");
    
    for(var i = 1; i <= MaxTarget; i += 1){
        # on affiche des infos de la cible a cote du cercle
        text_info = m.TextInfoGroup.createChild("text", "infos")
                .setTranslation(15, -10)
                .setAlignment("left-center")
                .setFont("LiberationFonts/LiberationSansNarrow-Bold.ttf")
                .setFontSize(26)
                .setColor(0,180,0,0.9)
                .setText("VOID");
        append(m.TextInfoArray, text_info);
    }
    m.Textrot   = m.TextInfoGroup.createTransform();
    
  
    
    #######################  Triangles ##########################################
    
    var TriangleSize = 30;
    m.TriangleGroupe = m.radarStuffGroup.createChild("group");
    

    # le triangle donne le cap relatif
        m.triangle = m.TriangleGroupe.createChild("path")
            .setStrokeLineWidth(3)
            .set("stroke", "rgba(0,180,0,0.9)")
            .moveTo(0, TriangleSize*-1)
            .lineTo(TriangleSize*0.866, TriangleSize*0.5)
            .lineTo(TriangleSize*-0.866, TriangleSize*0.5)
            .lineTo(0, TriangleSize*-1);
    TriangleSize = TriangleSize*0.7;
    
        m.triangle2 = m.TriangleGroupe.createChild("path")
            .setStrokeLineWidth(3)
            .set("stroke", "rgba(0,180,0,0.9)")
            .moveTo(0, TriangleSize*-1)
            .lineTo(TriangleSize*0.866, TriangleSize*0.5)
            .lineTo(TriangleSize*-0.866, TriangleSize*0.5)
            .lineTo(0, TriangleSize*-1.1);
         m.triangleRot =  m.TriangleGroupe.createTransform();
         
    m.TriangleGroupe.hide();

    m.input = {
      pitch:      "/orientation/pitch-deg",
      roll:       "/orientation/roll-deg",
      hdg:        "/orientation/heading-deg",
      speed_n:    "velocities/speed-north-fps",
      speed_e:    "velocities/speed-east-fps",
      speed_d:    "velocities/speed-down-fps",
      alpha:      "/orientation/alpha-deg",
      beta:       "/orientation/side-slip-deg",
      ias:        "/velocities/airspeed-kt",
      gs:         "/velocities/groundspeed-kt",
      vs:         "/velocities/vertical-speed-fps",
      rad_alt:    "/instrumentation/radar-altimeter/radar-altitude-ft",
      wow_nlg:    "/gear/gear[4]/wow",
      airspeed:   "/velocities/airspeed-kt",
      target_spd: "/autopilot/settings/target-speed-kt",
      acc:        "/fdm/jsbsim/accelerations/udot-ft_sec2"
    };
    
    foreach(var name; keys(m.input))
      m.input[name] = props.globals.getNode(m.input[name], 1);
    
    return m;
  },
  update: func()
  {
    #me.airspeed.setText(sprintf("%d", me.input.ias.getValue()));
    #me.groundspeed.setText(sprintf("G %3d", me.input.gs.getValue()));
    #me.vertical_speed.setText(sprintf("%.1f", me.input.vs.getValue() * 60.0 / 1000));
    
    var rad_alt = me.input.rad_alt.getValue();
    if( rad_alt and rad_alt < 5000 ) # Only show below 5000AGL
      rad_alt = sprintf("R %4d", rad_alt);
    else
      rad_alt = nil;
    me.rad_alt.setText(rad_alt);
    
    
    
    me.Fire_GBU.setText("Fire");
    var aGL = props.globals.getNode("/position/altitude-agl-ft").getValue();
    
    #Think this code sucks. If everyone have better, please, proceed :)
    if(pylons.fcs.getSelectedWeapon() != nil){
      #print(pylons.fcs.getSelectedWeapon().type);
      if(pylons.fcs.getSelectedWeapon().type != "30mm Cannon"){
        #print(pylons.fcs.getSelectedWeapon().getCCRP(20, 0.1));
        if(pylons.fcs.getSelectedWeapon().class =="GM" or pylons.fcs.getSelectedWeapon().class == "G"){
          #print("Class of Load:" ~ pylons.fcs.getSelectedWeapon().class);
          if(aGL<8000){
            var DistanceToShoot = pylons.fcs.getSelectedWeapon().getCCRP(20, 0.1);
          }elsif(aGL<15000){
            var DistanceToShoot = pylons.fcs.getSelectedWeapon().getCCRP(30, 0.2);
          }else{
            var DistanceToShoot = pylons.fcs.getSelectedWeapon().getCCRP(45, 0.2);
          }
          
          if(DistanceToShoot != nil ){
            if(DistanceToShoot < 3000){
              me.Fire_GBU.show();
              me.Fire_GBU.setText(sprintf("Hold Fire: %d ", int(DistanceToShoot)));
              if(DistanceToShoot < 600){
                #print(DistanceToShoot);
                me.Fire_GBU.setText(sprintf("Fire: %d ", int(DistanceToShoot)));
                me.Fire_GBU.show();
              }
            }else{me.Fire_GBU.hide();}
          }else{me.Fire_GBU.hide();}
        }else{me.Fire_GBU.hide();}
      }else{me.Fire_GBU.hide();}
    }else{me.Fire_GBU.hide();}
    
    
    
    #me.hdg.setText(sprintf("%03d", me.input.hdg.getValue()));
    me.h_trans.setTranslation(0, 18 * me.input.pitch.getValue());
    
    var rot = -me.input.roll.getValue() * math.pi / 180.0;
    me.h_rot.setRotation(rot);
    me.targetrot.setRotation(rot);
    me.Textrot.setRotation(rot);
    me.triangleRot.setRotation(rot);
    
    
    
    # flight path vector (FPV)
    var vel_gx = me.input.speed_n.getValue();
    var vel_gy = me.input.speed_e.getValue();
    var vel_gz = me.input.speed_d.getValue();
    
    var yaw = me.input.hdg.getValue() * math.pi / 180.0;
    var roll = me.input.roll.getValue() * math.pi / 180.0;
    var pitch = me.input.pitch.getValue() * math.pi / 180.0;
    
    var sy = math.sin(yaw);   var cy = math.cos(yaw);
    var sr = math.sin(roll);  var cr = math.cos(roll);
    var sp = math.sin(pitch); var cp = math.cos(pitch);

    var vel_bx = vel_gx * cy * cp
               + vel_gy * sy * cp
               + vel_gz * -sp;
    var vel_by = vel_gx * (cy * sp * sr - sy * cr)
               + vel_gy * (sy * sp * sr + cy * cr)
               + vel_gz * cp * sr;
    var vel_bz = vel_gx * (cy * sp * cr + sy * sr)
               + vel_gy * (sy * sp * cr - cy * sr)
               + vel_gz * cp * cr;

    var dir_y = math.atan2(round0(vel_bz), math.max(vel_bx, 0.01)) * 180.0 / math.pi;
    var dir_x  = math.atan2(round0(vel_by), math.max(vel_bx, 0.01)) * 180.0 / math.pi;

    #me.fpv.setTranslation(dir_x * 18, dir_y * 18);

    var speed_error = 0;
    if( me.input.target_spd.getValue() != nil )
      speed_error = 4 * clamp(
        me.input.target_spd.getValue() - me.input.airspeed.getValue(),
        -15, 15
      );
      
    me.horizon_group.hide();
    #me.hdg.hide();
    #me.groundspeed.hide();  
    me.rad_alt.hide();
    #me.airspeed.hide();
    #me.energy_cue.hide();
    #me.acc.hide();
    #me.vertical_speed.hide();
    
    
    #Pilot position:    
    var Piloty = getprop("sim/current-view/x-offset-m"); 
    var Pilotz = getprop("sim/current-view/y-offset-m");
    var Pilotx = getprop("sim/current-view/z-offset-m");
     var xCube = (centerHUDx - Pilotx)*(centerHUDx - Pilotx);
     var yCube = (centerHUDy - Piloty)*(centerHUDy - Piloty);
     var zCube = (centerHUDz - Pilotz)*(centerHUDz - Pilotz);
     
     var offsetZ = centerHUDz-Pilotz;
     
     #print("centerHUDx=" ~ centerHUDx ~ "centerHUDy=" ~ centerHUDy ~ "centerHUDz=" ~centerHUDz);
     #print("Pilotx = " ~ Pilotx ~ ";Piloty = " ~ Piloty ~ ";Pilotz = " ~ Pilotz);
     #print("xCube = " ~ xCube ~ ";yCube = " ~ yCube ~ ";zCube = " ~ zCube);
    
    mydistanceTohud = math.sqrt(xCube+yCube+zCube);
    
    #print(mydistanceTohud)


    
    #To put a triangle on the selected target
    #This should be changed by calling directly the radar object (in case of multi targeting)
    
    var closestCallsign = getprop("ai/closest/callsign");
    var closestRange = getprop("ai/closest/range");
    var Token = 0;
    

    #myarrayofTarget = mirage2000.myRadar3.update();
    raw_list = mirage2000.myRadar3.ContactsList;
    #print("Size:" ~ size(raw_list));
    
    i = 0;

    foreach(var c; raw_list){
      
      if(i<size(me.targetArray)){


        displayIt = c.objectDisplay;
        #var myTest = c.isPainted();
        
        #print("Display it : %d",displayIt);
        
        if(displayIt==1){


          target_callsign = c.get_Callsign();
          #print("Paint : " ~ target_callsign ~ " : "~ myTest);
          
          target_altitude = c.get_altitude();
          target_heading_deg = c.get_heading();
          target_Distance = c.get_range();
          
          #Data for position calculation
          mydeviation = c.objectDeviationDeg;
          myelevation = c.objectElevationDeg;
          
          myelevation = radar.deviation_normdeg(me.input.pitch.getValue(), myelevation);
      
          myhorizontaldeviation = mydeviation!=nil ?mydistanceTohud * math.tan(mydeviation*D2R):0;
          myverticalelevation = myelevation!=nil ?  mydistanceTohud * math.tan(myelevation*D2R):0;
          
          
          #If we have a selected target we display a triangle
          if(target_callsign == closestCallsign and closestRange > 0){
            Token = 1;
            me.TriangleGroupe.show();
            me.triangle.setTranslation((480/wideMeters)*myhorizontaldeviation,(480/heightMeters)*(myverticalelevation)-55);
            me.triangle2.setTranslation((480/wideMeters)*myhorizontaldeviation,(480/heightMeters)*(myverticalelevation)-55);
            #And we hide the circle
            me.targetArray[i].hide();
          }else{
            #Else  the circle
            me.targetArray[i].show();
            me.targetArray[i].setTranslation((480/wideMeters)*myhorizontaldeviation,(480/heightMeters)*(myverticalelevation)-55);
          }
          #here is the text display
          me.TextInfoArray[i].show();
          me.TextInfoArray[i].setTranslation((480/wideMeters)*myhorizontaldeviation,(480/heightMeters)*(myverticalelevation)-55);
          
          me.TextInfoArray[i].setText(sprintf("  %s \n   %d nm \n   %d ft / %d", target_callsign, target_Distance, target_altitude, target_heading_deg));

        }else{
          me.targetArray[i].hide();
          me.TextInfoArray[i].hide();
        }
        #The token has 1 when we have a selected target
        if(Token == 0){
            me.TriangleGroupe.hide();
        }
      }
      
      i+=1;
    }
    for(var y=i;y<size(me.targetArray);y+=1){
      me.targetArray[y].hide();
      me.TextInfoArray[y].hide();
    }
    


    #settimer(func me.update(), 0.1);
  }
};



#var init = setlistener("/sim/signals/fdm-initialized", func() {
#  removelistener(init); # only call once
#  var hud_pilot = HUD.new({"node": "canvasHUD", "texture": "hud.png"});
#  hud_pilot.update();
#  var hud_copilot = HUD.new({"node": "verre2"});
#  hud_copilot.update();
#});

#var initcanvas = func() {
#  var hud_pilot = HUD.new({"node": "canvasHUD", "texture": "hud.png"});
#  hud_pilot.update();
  #var hud_copilot = HUD.new({"node": "verre2"});
  #hud_copilot.update()
#};

