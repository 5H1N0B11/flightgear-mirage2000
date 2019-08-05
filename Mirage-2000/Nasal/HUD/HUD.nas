print("*** LOADING HUD.nas ... ***");
################################################################################
#
#                     m2005-5's HUD AI/MP SETTINGS
#
################################################################################
#panel with revi:
#      <x-m> -3.653 </x-m>
#      <y-m>  0.000 </y-m>
#      <z-m> -0.297 </z-m>
#      <pitch-deg> -14 </pitch-deg>
#revi:
#      <x-m> 0.456 </x-m>
#      <y-m> 0.000 </y-m>
#      <z-m> 0.159 </z-m>




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
    "view": [480,480], #<- Size of the coordinate systems (the bigger the sharpener)
    "mipmapping": 0
  },
  new: func(placement)
  {
    var m = {
      parents: [HUD],
      canvas: canvas.new(HUD.canvas_settings)
    };
    
    HudMath.init([-3.26163,-0.067,0.085216], [-3.26163,0.067,-0.048785], [480,480], [0,1.0], [1,0.0], 0);
    #HudMath.init([-3.22012,-0.07327,0.101839], [-3.32073,0.07327,-0.093358], [1024,1024], [0.166803,1.0], [0.834003,0.0], 0); wrong HUD
        
    m.viewPlacement = 480;
    m.min = -m.viewPlacement * 0.846;
    m.max = m.viewPlacement * 0.846;

    m.canvas.addPlacement(placement);
    #m.canvas.setColorBackground(red, green, blue, 0.0);
    m.canvas.setColorBackground(0.36, 1, 0.3, 0.02);
    
    m.root =
      m.canvas.createGroup()
              #.setScale(1, 1/math.cos(45 * D2R))
              .setTranslation(HudMath.getCenterOrigin())
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
            
    #fpv
    m.fpv = m.root.createChild("path")
        .moveTo(10, 0)
        .horiz(20)
        .moveTo(10, 0)
        .arcSmallCW(10,10, 0, -20, 0)
        .arcSmallCW(10,10, 0, 20, 0)
        .moveTo(-10, 0)
        .horiz(-20)
        .moveTo(0, -10)
        .vert(-10)
        .setStrokeLineWidth(4)
        .set("stroke", "rgba(0,180,0,0.9)");

    #bore cross
    m.boreCross = m.root.createChild("path")
                   .moveTo(-12.5, 0)
                   .horiz(25)
                   .moveTo(0, -12.5)
                   .vert(25)
                   .setStrokeLineWidth(4);

    # Horizon groups
    m.horizon_group = m.root.createChild("group");
    m.h_rot   = m.horizon_group.createTransform();
    m.horizon_sub_group = m.horizon_group.createChild("group");
  
    # Horizon and pitch lines
    m.horizon_sub_group.createChild("path")
                   .moveTo(-500, 0)
                   .horiz(1000)
                   .setStrokeLineWidth(4);
    m.horizon_sub_group.createChild("path")
                   .moveTo(-100, HudMath.getPixelPerDegreeAvg(5)*5)
                   .horiz(200)
                   .setStrokeLineWidth(4);
    m.horizon_sub_group.createChild("path")
                   .moveTo(-100, HudMath.getPixelPerDegreeAvg(5)*-5)
                   .horiz(200)
                   .setStrokeLineWidth(4);               
    m.horizon_sub_group.createChild("path")
                   .moveTo(-100, HudMath.getPixelPerDegreeAvg(10)*10)
                   .horiz(200)
                   .setStrokeLineWidth(4);
    m.horizon_sub_group.createChild("path")
                   .moveTo(-100, HudMath.getPixelPerDegreeAvg(10)*-10)
                   .horiz(200)
                   .setStrokeLineWidth(4);
    m.horizon_sub_group.createChild("path")
                   .moveTo(-100, HudMath.getPixelPerDegreeAvg(15)*15)
                   .horiz(200)
                   .setStrokeLineWidth(4);
    m.horizon_sub_group.createChild("path")
                   .moveTo(-100, HudMath.getPixelPerDegreeAvg(15)*-15)
                   .horiz(200)
                   .setStrokeLineWidth(4);
                   
    m.radarStuffGroup = m.root.createChild("group");
    
    
    #eegs funnel:
    m.eegsGroup = m.root.createChild("group");
    m.eegsRightX = [0,0,0,0,0,0,0,0,0,0];
    m.eegsRightY = [0,0,0,0,0,0,0,0,0,0];
    m.eegsLeftX = [0,0,0,0,0,0,0,0,0,0];
    m.eegsLeftY = [0,0,0,0,0,0,0,0,0,0];
    m.gunPos   = [[nil,nil],[nil,nil,nil],[nil,nil,nil,nil],[nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]];
    m.eegsMe = {ac: geo.Coord.new(), eegsPos: geo.Coord.new(),shellPosX: [0,0,0,0,0,0,0,0,0,0],shellPosY: [0,0,0,0,0,0,0,0,0,0],shellPosDist: [0,0,0,0,0,0,0,0,0,0]};
    m.lastTime = systime();
    m.averageDt = 0.150;
    m.eegsLoop = maketimer(m.averageDt, m, m.displayEEGS);
    m.eegsLoop.simulatedTime = 1;
                     
      
   ##################################### Circle ####################################
    m.targetArray = [];
    m.circle_group2 = m.radarStuffGroup.createChild("group");
    for(var i = 1; i <= MaxTarget; i += 1){
      myCircle = m.circle_group2.createChild("path")
        .moveTo(15, 0)
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
    HudMath.reCalc();
    me.boreCross.setTranslation(HudMath.getBorePos());
    
    var rad_alt = me.input.rad_alt.getValue();
    if( rad_alt and rad_alt < 5000 ) # Only show below 5000AGL
      rad_alt = sprintf("R %4d", rad_alt);
    else
      rad_alt = nil;
    me.rad_alt.setText(rad_alt);
    
    
    
    me.Fire_GBU.setText("Fire");
    var aGL = props.globals.getNode("/position/altitude-agl-ft").getValue();
    
    #Think this code sucks. If everyone have better, please, proceed :)
    me.eegsShow=0;
    me.selectedWeap = pylons.fcs.getSelectedWeapon();
    me.showFire_GBU = 0;
    if(me.selectedWeap != nil){
      #print(me.selectedWeap.type);
      if(me.selectedWeap.type != "30mm Cannon"){
        #print(me.selectedWeap.getCCRP(20, 0.1));
        if(find("M", me.selectedWeap.class) !=-1 or find("G", me.selectedWeap.class) !=-1){
          #print("Class of Load:" ~ me.selectedWeap.class);
          me.DistanceToShoot = nil;
          if(aGL<8000){
            me.DistanceToShoot = me.selectedWeap.getCCRP(20, 0.1);
          }elsif(aGL<15000){
            me.DistanceToShoot = me.selectedWeap.getCCRP(30, 0.2);
          }else{
            me.DistanceToShoot = me.selectedWeap.getCCRP(45, 0.2);
          }
          
          if(me.DistanceToShoot != nil ){
            if(me.DistanceToShoot < 3000){
              me.showFire_GBU = 1;
              me.Fire_GBU.setText(sprintf("Hold Fire: %d ", int(me.DistanceToShoot)));
              if(me.DistanceToShoot < 600){
                #print(me.DistanceToShoot);
                me.Fire_GBU.setText(sprintf("Fire: %d ", int(me.DistanceToShoot)));
              }
            }
          }
        }
      }else{me.eegsShow=getprop("controls/armament/master-arm");}
    }
    me.Fire_GBU.setVisible(me.showFire_GBU);
    
    
    #me.hdg.setText(sprintf("%03d", me.input.hdg.getValue()));
    me.horizStuff = HudMath.getStaticHorizon();
    me.horizon_group.setTranslation(me.horizStuff[0]);
    me.h_rot.setRotation(me.horizStuff[1]);
    me.horizon_sub_group.setTranslation(me.horizStuff[2]);
    
    var rot = -me.input.roll.getValue() * math.pi / 180.0;
    me.Textrot.setRotation(rot);
    
    
    
    
    # flight path vector (FPV)
    
    me.fpv.setTranslation(HudMath.getFlightPathIndicatorPosWind());

    var speed_error = 0;
    if( me.input.target_spd.getValue() != nil )
      speed_error = 4 * clamp(
        me.input.target_spd.getValue() - me.input.airspeed.getValue(),
        -15, 15
      );
      
    
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
     var yCube = (centerHUDy - Piloty)*(centerHUDy - Piloty); # 20190712 : testing by  x0
     var zCube = (centerHUDz - Pilotz)*(centerHUDz - Pilotz); # 20190712 : testing by  x0
     
     var offsetZ = centerHUDz-Pilotz;
     
     #print("centerHUDx=" ~ centerHUDx ~ "centerHUDy=" ~ centerHUDy ~ "centerHUDz=" ~centerHUDz);
     #print("Pilotx = " ~ Pilotx ~ ";Piloty = " ~ Piloty ~ ";Pilotz = " ~ Pilotz);
     #print("xCube = " ~ xCube ~ ";yCube = " ~ yCube ~ ";zCube = " ~ zCube);
    
    mydistanceTohud = math.sqrt(xCube+yCube+zCube);
    
    #print("mydistanceTohud:" ~ mydistanceTohud);


    
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
          
          #print("myelevation:" ~ myelevation ~ " from viewer:" ~ c.get_Elevation_from_Coord_HUD());
          myelevation = c.get_Elevation_from_Coord_HUD();
          
          myelevation = radar.deviation_normdeg(me.input.pitch.getValue(), myelevation);
      
          myhorizontaldeviation = mydeviation!=nil ?mydistanceTohud * math.tan(mydeviation*D2R):0;
          myverticalelevation = myelevation!=nil ?  mydistanceTohud * math.tan(myelevation*D2R):0;
          
          #print("myhorizontaldeviation:" ~ myhorizontaldeviation ~ " myverticalelevation:"~ myverticalelevation);
          
          var triPos = HudMath.getPosFromCoord(c.get_Coord());
          
          #If we have a selected target we display a triangle
          if(target_callsign == closestCallsign and closestRange > 0){
            Token = 1;
            me.TriangleGroupe.show();
            me.triangle.setTranslation(triPos);
            me.triangle2.setTranslation(triPos);
            #And we hide the circle
            me.targetArray[i].hide();
          }else{
            #Else  the circle
            me.targetArray[i].show();
            me.targetArray[i].setTranslation(triPos);
          }
          #here is the text display
          me.TextInfoArray[i].show();
          me.TextInfoArray[i].setTranslation(triPos);
          
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
    
    if (!me.eegsShow) {
      me.eegsGroup.setVisible(me.eegsShow);
    }
    if (me.eegsShow and !me.eegsLoop.isRunning) {
        me.eegsLoop.start();
    } elsif (!me.eegsShow and me.eegsLoop.isRunning) {
        me.eegsLoop.stop();
    }

    #settimer(func me.update(), 0.1);
  },
  
  displayEEGS: func() {
        #note: this stuff is expensive like hell to compute, but..lets do it anyway.
        
        var funnelParts = 10;#max 10
        var st = systime();
        me.eegsMe.dt = st-me.lastTime;
        if (me.eegsMe.dt > me.averageDt*3) {
            me.lastTime = st;
            me.gunPos   = [[nil,nil],[nil,nil,nil],[nil,nil,nil,nil],[nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]];
            me.eegsGroup.removeAllChildren();
        } else {
            #printf("dt %05.3f",me.eegsMe.dt);
            me.lastTime = st;
            
            me.eegsMe.hdg   = getprop("orientation/heading-deg");
            me.eegsMe.pitch = getprop("orientation/pitch-deg");
            me.eegsMe.roll  = getprop("orientation/roll-deg");
            
            var hdp = {roll:me.eegsMe.roll,current_view_z_offset_m: getprop("sim/current-view/z-offset-m")};
            
            me.eegsMe.ac = geo.aircraft_position();
            me.eegsMe.allow = 1;
            
            for (var l = 0;l < funnelParts;l+=1) {
                # compute display positions of funnel on hud
                var pos = me.gunPos[l][l+1];
                if (pos == nil) {
                    me.eegsMe.allow = 0;
                } else {
                    var ac  = me.gunPos[l][l][1];
                    pos     = me.gunPos[l][l][0];
                    
                    var ps = HudMath.getPosFromCoord(pos, ac);
                    me.eegsMe.xcS = ps[0];
                    me.eegsMe.ycS = ps[1];
                    me.eegsMe.shellPosDist[l] = ac.direct_distance_to(pos)*M2FT;
                    me.eegsMe.shellPosX[l] = me.eegsMe.xcS;
                    me.eegsMe.shellPosY[l] = me.eegsMe.ycS;
                }
            }
            if (me.eegsMe.allow) {
                # draw the funnel
                for (var k = 0;k<funnelParts;k+=1) {
                    var halfspan = math.atan2(35*0.5,me.eegsMe.shellPosDist[k])*R2D*HudMath.getPixelPerDegreeAvg(2.0);#35ft average fighter wingspan
                    me.eegsRightX[k] = me.eegsMe.shellPosX[k]-halfspan;
                    me.eegsRightY[k] = me.eegsMe.shellPosY[k];
                    me.eegsLeftX[k]  = me.eegsMe.shellPosX[k]+halfspan;
                    me.eegsLeftY[k]  = me.eegsMe.shellPosY[k];
                }
                me.eegsGroup.removeAllChildren();
                for (var i = 0; i < funnelParts-1; i+=1) {
                    me.eegsGroup.createChild("path")
                        .moveTo(me.eegsRightX[i], me.eegsRightY[i])
                        .lineTo(me.eegsRightX[i+1], me.eegsRightY[i+1])
                        .moveTo(me.eegsLeftX[i], me.eegsLeftY[i])
                        .lineTo(me.eegsLeftX[i+1], me.eegsLeftY[i+1])
                        .setStrokeLineWidth(4);
                }
                me.eegsGroup.update();
            }
            
            
            
            
            #calc shell positions
            
            me.eegsMe.vel = getprop("velocities/uBody-fps")+3363.0;#3363.0 = speed
            
            me.eegsMe.geodPos = aircraftToCart({x:-0, y:0, z: getprop("sim/current-view/y-offset-m")});#position (meters) of gun in aircraft (x and z inverted)
            me.eegsMe.eegsPos.set_xyz(me.eegsMe.geodPos.x, me.eegsMe.geodPos.y, me.eegsMe.geodPos.z);
            me.eegsMe.altC = me.eegsMe.eegsPos.alt();
            
            me.eegsMe.rs = armament.AIM.rho_sndspeed(me.eegsMe.altC*M2FT);#simplified
            me.eegsMe.rho = me.eegsMe.rs[0];
            me.eegsMe.mass =  0.9369635/ armament.slugs_to_lbm;#0.9369635=lbs
            
            #print("x,y");
            #printf("%d,%d",0,0);
            #print("-----");
            
            for (var j = 0;j < funnelParts;j+=1) {
                
                #calc new speed
                me.eegsMe.Cd = drag(me.eegsMe.vel/ me.eegsMe.rs[1],0.193);#0.193=cd
                me.eegsMe.q = 0.5 * me.eegsMe.rho * me.eegsMe.vel * me.eegsMe.vel;
                me.eegsMe.deacc = (me.eegsMe.Cd * me.eegsMe.q * 0.007609) / me.eegsMe.mass;#0.007609=eda
                me.eegsMe.vel -= me.eegsMe.deacc * me.averageDt;
                me.eegsMe.speed_down_fps       = -math.sin(me.eegsMe.pitch * D2R) * (me.eegsMe.vel);
                me.eegsMe.speed_horizontal_fps = math.cos(me.eegsMe.pitch * D2R) * (me.eegsMe.vel);
                
                me.eegsMe.speed_down_fps += 9.81 *M2FT *me.averageDt;
                
                
                 
                me.eegsMe.altC -= (me.eegsMe.speed_down_fps*me.averageDt)*FT2M;
                
                me.eegsMe.dist = (me.eegsMe.speed_horizontal_fps*me.averageDt)*FT2M;
                
                me.eegsMe.eegsPos.apply_course_distance(me.eegsMe.hdg, me.eegsMe.dist);
                me.eegsMe.eegsPos.set_alt(me.eegsMe.altC);
                
                var old = me.gunPos[j];
                me.gunPos[j] = [[geo.Coord.new(me.eegsMe.eegsPos),me.eegsMe.ac]];
                for (var m = 0;m<j+1;m+=1) {
                    append(me.gunPos[j], old[m]);
                } 
                
                me.eegsMe.vel = math.sqrt(me.eegsMe.speed_down_fps*me.eegsMe.speed_down_fps+me.eegsMe.speed_horizontal_fps*me.eegsMe.speed_horizontal_fps);
                me.eegsMe.pitch = math.atan2(-me.eegsMe.speed_down_fps,me.eegsMe.speed_horizontal_fps)*R2D;
            }                        
        }
        me.eegsGroup.show();
    },
    
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

var drag = func (Mach, _cd) {
    if (Mach < 0.7)
        return 0.0125 * Mach + _cd;
    elsif (Mach < 1.2)
        return 0.3742 * math.pow(Mach, 2) - 0.252 * Mach + 0.0021 + _cd;
    else
        return 0.2965 * math.pow(Mach, -1.1506) + _cd;
};

var deviation_normdeg = func(our_heading, target_bearing) {
  var dev_norm = target_bearing-our_heading;
    dev_norm=geo.normdeg180(dev_norm);
  return dev_norm;
};