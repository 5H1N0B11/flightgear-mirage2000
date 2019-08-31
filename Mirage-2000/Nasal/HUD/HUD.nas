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


var roundabout = func(x) {
  var y = x - int(x);
  return y < 0.5 ? int(x) : 1 + int(x) ;
};

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


#X = 420 * 2
#Y = 1024 => 512 * 2
var HUD = {
  canvas_settings: {
    "name": "HUD",
    "size": [1024,1024],#<-- size of the texture
    "view": [1024,1024], #<- Size of the coordinate systems (the bigger the sharpener)
    "mipmapping": 0
  },
  new: func(placement)
  {
    var m = {
      parents: [HUD],
      canvas: canvas.new(HUD.canvas_settings)
    };
     
    HudMath.init([-3.26163,-0.067,0.099216], [-3.26163,0.067,-0.062785], [1024,1024], [0,1.0], [0.8265,0.0], 0);
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
        .set("stroke", "rgba(0,255,0,0.9)");
        #.set("stroke", "rgba(0,180,0,0.9)");
        
   #Chevrons Acceleration Vector (AV)
   m.chevronFactor = 25;
   m.chevronGroup = m.root.createChild("group");
   
  m.LeftChevron = m.chevronGroup.createChild("text")
  .setTranslation(-150,0)
  .setDouble("character-size", 35)
  .setAlignment("center-center")
  #.setFontSize((65/1024)*canvasWidth*fs, ar);
  .setText(">");    
  
  m.RightChevron = m.chevronGroup.createChild("text")
    .setTranslation(150,0)
    .setDouble("character-size", 35)
    .setAlignment("center-center")
    #.setFontSize((65/1024)*canvasWidth*fs, ar);
    .setText("<");   
   
    
    
  #Take off Acceleration
  m.accBoxGroup = m.root.createChild("group");  
    
  m.acceleration_Box = m.accBoxGroup.createChild("text")
  .setTranslation(0,0)
  .setDouble("character-size", 35)
  .setAlignment("center-center")
  #.setFontSize((65/1024)*canvasWidth*fs, ar);
  .setText("0.00"); 
        
        
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

    m.ladderScale = 7.5;#7.5
    m.maxladderspan =  200;
                   
   for (var myladder = 5;myladder <= 90;myladder+=5)
   {
     if (myladder/10 == int(myladder/10)){
        #Text bellow 0 left
        m.horizon_sub_group.createChild("text")
          .setAlignment("right-center")
          .setTranslation(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
          .setDouble("character-size", 30)
          .setText(myladder);
        #Text bellow 0 left
        m.horizon_sub_group.createChild("text")
          .setAlignment("left-center")
          .setTranslation(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
          .setDouble("character-size", 30)
          .setText(myladder);

        #Text above 0 left         
        m.horizon_sub_group.createChild("text")
          .setAlignment("right-center")
          .setTranslation(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
          .setDouble("character-size", 30)
          .setText(myladder); 
        #Text above 0 right   
        m.horizon_sub_group.createChild("text")
          .setAlignment("left-center")
          .setTranslation(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
          .setDouble("character-size", 30)
          .setText(myladder);
      }
      
  # =============  BELLOW 0 ===================           
    #half line bellow 0 (left part)       ------------------ 
    m.horizon_sub_group.createChild("path")
                   .moveTo(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
                   .vert(-m.maxladderspan/15)
                   .setStrokeLineWidth(4); 
                   
    m.horizon_sub_group.createChild("path")
                   .moveTo(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
                   .horiz(m.maxladderspan*2/15)
                  .setStrokeLineWidth(4);             
    m.horizon_sub_group.createChild("path")
                   .moveTo(-abs(m.maxladderspan - m.maxladderspan*2/15*2), HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
                   .horiz(m.maxladderspan*2/15)
                  .setStrokeLineWidth(4);    
    m.horizon_sub_group.createChild("path")
                   .moveTo(-abs(m.maxladderspan - m.maxladderspan*2/15*4), HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
                   .horiz(m.maxladderspan*2/15)
                  .setStrokeLineWidth(4);
                  
    #half line (rigt part)       ------------------   
    m.horizon_sub_group.createChild("path")
                   .moveTo(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
                   .vert(-m.maxladderspan/15)
                   .setStrokeLineWidth(4); 
                   
    m.horizon_sub_group.createChild("path")
                   .moveTo(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
                   .horiz(-m.maxladderspan*2/15)
                  .setStrokeLineWidth(4);             
    m.horizon_sub_group.createChild("path")
                   .moveTo(abs(m.maxladderspan - m.maxladderspan*2/15*2), HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
                   .horiz(-m.maxladderspan*2/15)
                  .setStrokeLineWidth(4);    
    m.horizon_sub_group.createChild("path")
                   .moveTo(abs(m.maxladderspan - m.maxladderspan*2/15*4), HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
                   .horiz(-m.maxladderspan*2/15)
                  .setStrokeLineWidth(4);              
                  
                  
  
                   
# =============  ABOVE 0 ===================               
    m.horizon_sub_group.createChild("path")
                   .moveTo(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
                   .vert(m.maxladderspan/15)
                   .setStrokeLineWidth(4); 
                   
    m.horizon_sub_group.createChild("path")
                   .moveTo(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
                   .horiz(m.maxladderspan/3*2)
                  .setStrokeLineWidth(4);             
          
    #half line (rigt part)       ------------------           
    m.horizon_sub_group.createChild("path")
                   .moveTo(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
                   .horiz(-m.maxladderspan/3*2)
                  .setStrokeLineWidth(4);            
    m.horizon_sub_group.createChild("path")
                   .moveTo(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
                   .vert(m.maxladderspan/15)
                   .setStrokeLineWidth(4); 
                   

   }           
                   
                   
    #m.horizon_sub_group.createChild("path")
                   #.moveTo(-100, HudMath.getPixelPerDegreeAvg(5)*-5)
                   #.horiz(200)
                   #.setStrokeLineWidth(4);               
 #   m.horizon_sub_group.createChild("path")
#                   .moveTo(-100, HudMath.getPixelPerDegreeAvg(10)*10)
#                   .horiz(200)
#                   .setStrokeLineWidth(4);
#    m.horizon_sub_group.createChild("path")
#                   .moveTo(-100, HudMath.getPixelPerDegreeAvg(10)*-10)
#                   .horiz(200)
#                   .setStrokeLineWidth(4);
#    m.horizon_sub_group.createChild("path")
#                   .moveTo(-100, HudMath.getPixelPerDegreeAvg(15)*15)
#                   .horiz(200)
#                   .setStrokeLineWidth(4);
#    m.horizon_sub_group.createChild("path")
#                   .moveTo(-100, HudMath.getPixelPerDegreeAvg(15)*-15)
#                   .horiz(200)
#                   .setStrokeLineWidth(4);
              
    m.headScaleTickSpacing = 45;           
    m.headScaleVerticalPlace = -450;
    m.headingStuff = m.root.createChild("group");
    m.headingScaleGroup = m.headingStuff.createChild("group");

    
     m.headingStuff.set("clip-frame", canvas.Element.LOCAL);
     m.headingStuff.set("clip", "rect(-500px, 150px, -400px, -150px)");# top,right,bottom,left
    
    
    m.head_scale = m.headingScaleGroup.createChild("path")
    .moveTo(-m.headScaleTickSpacing*2, m.headScaleVerticalPlace)
    .vert(-10)
    .moveTo(0, m.headScaleVerticalPlace)
    .vert(-10)
    .moveTo(m.headScaleTickSpacing*2, m.headScaleVerticalPlace)
    .vert(-10)
    .moveTo(m.headScaleTickSpacing*4, m.headScaleVerticalPlace)
    .vert(-10)
    .moveTo(-m.headScaleTickSpacing, m.headScaleVerticalPlace)
    .vert(-3)
    .moveTo(m.headScaleTickSpacing, m.headScaleVerticalPlace)
    .vert(-3)
    .moveTo(-m.headScaleTickSpacing*3, m.headScaleVerticalPlace)
    .vert(-3)
    .moveTo(m.headScaleTickSpacing*3, m.headScaleVerticalPlace)
    .vert(-3)
    .setStrokeLineWidth(2)
    .show();
    
    #Heading middle number on horizon line
    me.hdgMH = m.headingScaleGroup.createChild("text")
          .setTranslation(0,m.headScaleVerticalPlace -15)
          .setDouble("character-size", 30)
          .setAlignment("center-bottom")
          #.setFontSize((65/1024)*canvasWidth*fs, ar);
          .setText("0"); 
                   
#     # Heading left number on horizon line
      me.hdgLH = m.headingScaleGroup.createChild("text")
          .setTranslation(-m.headScaleTickSpacing*2,m.headScaleVerticalPlace -15)
          .setDouble("character-size", 30)
          .setAlignment("center-bottom")
          #.setFontSize((65/1024)*canvasWidth*fs, ar);
          .setText("350");           

#     # Heading right number on horizon line
      me.hdgRH = m.headingScaleGroup.createChild("text")
          .setTranslation(m.headScaleTickSpacing*2,m.headScaleVerticalPlace -15)
          .setDouble("character-size", 30)
          .setAlignment("center-bottom")
          #.setFontSize((65/1024)*canvasWidth*fs, ar);
          .setText("10");    
          
      # Heading right right number on horizon line
      me.hdgRRH = m.headingScaleGroup.createChild("text")
          .setTranslation(m.headScaleTickSpacing*4,m.headScaleVerticalPlace -15)
          .setDouble("character-size", 30)
          .setAlignment("center-bottom")
          #.setFontSize((65/1024)*canvasWidth*fs, ar);
          .setText("20");          

    
      
    #Point the The Selected Route. it's at the middle of the HUD
    m.TriangleSize = 4;
    m.head_scale_route_pointer = m.headingStuff.createChild("path")
    .setStrokeLineWidth(3)
    #.set("stroke", "rgba(0,180,0,0.9)")
    .moveTo(0, m.headScaleVerticalPlace)
    .lineTo(m.TriangleSize*-5/2, (m.headScaleVerticalPlace)+(m.TriangleSize*5))
    .lineTo(m.TriangleSize*5/2,(m.headScaleVerticalPlace)+(m.TriangleSize*5))
    .lineTo(0, m.headScaleVerticalPlace);
    
    

    #a line representthe middle and the actual heading
    m.heading_pointer_line = m.headingStuff.createChild("path")
    .setStrokeLineWidth(4)
    .moveTo(0, m.headScaleVerticalPlace + 2)
    .vert(20);
    

     m.speedAltGroup = m.root.createChild("group");
     # Heading right right number on horizon line
    me.Speed = m.speedAltGroup.createChild("text")
          .setTranslation(- m.maxladderspan,m.headScaleVerticalPlace)
          .setDouble("character-size", 50)
          .setAlignment("right-bottom")
          #.setFontSize((65/1024)*canvasWidth*fs, ar);
          .setText("0"); 
          

     # Heading right right number on horizon line
     me.hundred_feet_Alt = m.speedAltGroup.createChild("text")
          .setTranslation(m.maxladderspan + 60 ,m.headScaleVerticalPlace)
          .setDouble("character-size", 50)
          .setAlignment("right-bottom")
          #.setFontSize((65/1024)*canvasWidth*fs, ar);
          .setText("0");   
      

     # Heading right right number on horizon line
     me.feet_Alt = m.speedAltGroup.createChild("text")
          .setTranslation(m.maxladderspan + 60,m.headScaleVerticalPlace)
          .setDouble("character-size", 30)
          .setAlignment("left-bottom")
          #.setFontSize((65/1024)*canvasWidth*fs, ar);
          .setText("00");  
          
    
    
    
                   
    m.radarStuffGroup = m.root.createChild("group");
    
    
    #eegs funnel:
    #time * vectorSize >= 1.5
    
    m.eegsGroup = m.root.createChild("group");
    #m.averageDt = 0.050;
    m.averageDt = 0.10;
    #m.funnelParts = 10;
    m.funnelParts = 1.5 / m.averageDt;
    m.eegsRightX = [0];
    m.eegsRightY = [0];
    m.eegsLeftX  = [0];
    m.eegsLeftY  = [0]; 
    m.gunPos  = [[nil,nil]];
    m.shellPosXInit = [0];
    m.shellPosYInit =  [0];
    m.shellPosDistInit = [0];
    m.wingspanFT = 35;# 7- to 40 meter
    
    #m.gunTemp = [nil,nil];
    
    for(i = 0;i < m.funnelParts;i+=1){
      append(m.eegsRightX,0);
      append(m.eegsRightY,0);
      append(m.eegsLeftX,0);
      append(m.eegsLeftY,0);

      #print ("i:"~i);
      #print("size:"~size(m.gunPos));
      #print("size[i]:"~size(m.gunPos[i]));
      
      var tmp = [];
      for( myloopy = 0;myloopy <= i+2;myloopy+=1){
        append(tmp,nil);
      }
      append(m.gunPos, tmp);
      
      #print("After append size:"~size(m.gunPos));
      #print("After append size[i]:"~size(m.gunPos[i]));
      #print("After append size[i+1]:"~size(m.gunPos[i+1]));
      #append(m.gunPos,append(m.gunPos[i],[nil]));
      
      append(m.shellPosXInit,0);
      append(m.shellPosYInit,0);
      append(m.shellPosDistInit,0);
    }
    #print(size(m.eegsRightX));
    #print(size(m.gunPos[size(m.gunPos)-1]));
    
    #m.eegsRightX = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    #m.eegsRightY = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    #m.eegsLeftX = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    #m.eegsLeftY = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    #m.gunPos   = [[nil,nil],[nil,nil,nil],[nil,nil,nil,nil],[nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]];
    m.eegsMe = {ac: geo.Coord.new(), eegsPos: geo.Coord.new(),
        shellPosX:     m.shellPosXInit,
        shellPosY:     m.shellPosYInit,
        shellPosDist:  m.shellPosDistInit};
    m.lastTime = systime();
    m.eegsLoop = maketimer(m.averageDt, m, m.displayEEGS);
    m.eegsLoop.simulatedTime = 1;
                     
    
    
    
    
   ################################### Runways #######################################   
   m.myRunwayGroup = m.root.createChild("group");
   m.selectedRunway = 0;
   
   
#    m.myRunway = m.myRunwayGroup.createChild("path")
#         .moveTo(15, 0)
#         .arcSmallCW(15,15, 0, -30, 0)
#         .arcSmallCW(15,15, 0, 30, 0)
#         .setStrokeLineWidth(4)
#         .set("stroke", "rgba(0,180,0,0.9)");
#   
#     m.myRunwayBeginLeft = m.myRunwayGroup.createChild("path")
#         .moveTo(15, 0)
#         .arcSmallCW(15,15, 0, -30, 0)
#         .arcSmallCW(15,15, 0, 30, 0)
#         .setStrokeLineWidth(4)
#         .set("stroke", "rgba(0,180,0,0.9)");
#         
#     m.myRunwayBeginRight = m.myRunwayGroup.createChild("path")
#         .moveTo(15, 0)
#         .arcSmallCW(15,15, 0, -30, 0)
#         .arcSmallCW(15,15, 0, 30, 0)
#         .setStrokeLineWidth(4)
#         .set("stroke", "rgba(0,180,0,0.9)");
#     
#      m.myRunwayEndRight = m.myRunwayGroup.createChild("path")
#         .moveTo(15, 0)
#         .arcSmallCW(15,15, 0, -30, 0)
#         .arcSmallCW(15,15, 0, 30, 0)
#         .setStrokeLineWidth(4)
#         .set("stroke", "rgba(0,180,0,0.9)");
# 
#      m.myRunwayEndLeft = m.myRunwayGroup.createChild("path")
#         .moveTo(15, 0)
#         .arcSmallCW(15,15, 0, -30, 0)
#         .arcSmallCW(15,15, 0, 30, 0)
#         .setStrokeLineWidth(4)
#         .set("stroke", "rgba(0,180,0,0.9)");    
#       
   ##################################### Target Circle ####################################
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
      hdg:        "/orientation/heading-magnetic-deg",
      hdgReal:    "/orientation/heading-deg",
      hdgBug:     "/autopilot/settings/heading-bug-deg",
      hdgDisplay: "/instrumentation/efis/mfd/true-north",
      speed_n:    "velocities/speed-north-fps",
      speed_e:    "velocities/speed-east-fps",
      speed_d:    "velocities/speed-down-fps",
      alpha:      "/orientation/alpha-deg",
      beta:       "/orientation/side-slip-deg",
      ias:        "/velocities/airspeed-kt",
      gs:         "/velocities/groundspeed-kt",
      vs:         "/velocities/vertical-speed-fps",
      alt:        "/position/altitude-ft",
      alt_instru: "/instrumentation/altimeter/indicated-altitude-ft",
      rad_alt:    "/instrumentation/radar-altimeter/radar-altitude-ft",
      wow_nlg:    "/gear/gear[1]/wow",
      airspeed:   "/velocities/airspeed-kt",
      target_spd: "/autopilot/settings/target-speed-kt",
      acc:        "/fdm/jsbsim/accelerations/udot-ft_sec2",
      acc_yas:    "/fdm/yasim/accelerations/a-x",
      NavFreq:    "/instrumentation/nav/frequencies/selected-mhz",
      destRunway: "/autopilot/route-manager/destination/runway",
      destAirport:"/autopilot/route-manager/destination/airport",

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
    #me.Textrot.setRotation(rot);
    
    
    
    
    # flight path vector (FPV)
    me.display_Fpv();
    
    #chevronGroup
    me.display_Chevron();

    var speed_error = 0;
    if( me.input.target_spd.getValue() != nil )
      speed_error = 4 * clamp(
        me.input.target_spd.getValue() - me.input.airspeed.getValue(),
        -15, 15
      );
      
    #Acc accBoxGroup in G(so I guess /9,8)
    me.display_Acceleration_Box();
      
    #Display speedAltGroup
    me.display_speedAltGroup();

    
    
    
    #me.hdg.hide();
    #me.groundspeed.hide();  
    me.rad_alt.hide();
    #me.airspeed.hide();
    #me.energy_cue.hide();
    #me.acc.hide();
    #me.vertical_speed.hide();
    
  
    
    #To put a triangle on the selected target
    #This should be changed by calling directly the radar object (in case of multi targeting)
    
    var closestCallsign = getprop("ai/closest/callsign");
    var closestRange = getprop("ai/closest/range");
    var Token = 0;
    

    raw_list = mirage2000.myRadar3.ContactsList;
    #print("Size:" ~ size(raw_list));
    
    i = 0;
    
    me.designatedDistanceFT = nil;
    
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
          
          var triPos = HudMath.getPosFromCoord(c.get_Coord());
          
          #If we have a selected target we display a triangle
          if(target_callsign == closestCallsign and closestRange > 0){
            Token = 1;
            me.TriangleGroupe.show();
            me.triangle.setTranslation(triPos);
            me.triangle2.setTranslation(triPos);
            #And we hide the circle
            me.targetArray[i].hide();
            if (math.abs(triPos[0])<2000 and math.abs(triPos[1])<2000) {#only show it when target is in front
              me.designatedDistanceFT = c.get_Coord().direct_distance_to(geo.aircraft_position())*M2FT;
            }
          }else{
            #Else  the circle
            me.targetArray[i].show();
            me.targetArray[i].setTranslation(triPos);
          }
          #here is the text display
          me.TextInfoArray[i].show();
          me.TextInfoArray[i].setTranslation(triPos[0]+19,triPos[1]);
          
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
    
    #--------------------- Selecting the Airport and the runway -------------
    #------------------------------------------------------------------------
    #Need to select the runways and write the conditions
    #2. SYNTHETIC RUNWAY. The synthetic runway symbol is an aid for locating the real runway, especially during low visibility conditions. 
    #It is only visible when: 
    #a. The INS is on.
    #b. The airport is the current fly-to waypoint. 
    #c. The runway data (heading and glideslope) were entered.
    #d. Both localizer and glideslope have been captured 
    #e. The runway is less than 10 nautical miles away. 
    #f. Lateral deviation is less than 7º.
    # The synthetic runway is removed from the HUD as soon as there is weight on the landing gear’s wheels. 
       
    
    #First trying with ILS
    #var NavFrequency = getprop("/instrumentation/nav/frequencies/selected-mhz");
    me.selectedRunway  = "0";
    #print("-- Lengths of the runways at ", info.name, " (", info.id, ") --");
    var info = airportinfo();
    foreach(var rwy; keys(info.runways)){
        if(sprintf("%.2f",info.runways[rwy].ils_frequency_mhz) == sprintf("%.2f",me.input.NavFreq.getValue())){
          me.selectedRunway = rwy;
        }  
    }
    #Then, trying with route manager
    if(me.selectedRunway == "0"){
      if(me.input.destRunway.getValue() != ""){
        
        var fp = flightplan();
        if(fp.getPlanSize() == fp.indexOfWP(fp.currentWP())+1){
          
          info = airportinfo(me.input.destAirport.getValue());
          me.selectedRunway = me.input.destRunway.getValue() ;
        }
      }
    }
    #print("Test : ",me.selectedRunway != "0");
    if(me.selectedRunway != "0"){
      var (courseToAiport, distToAirport) = courseAndDistance(info);
      if(  distToAirport < 10 and me.input.wow_nlg.getValue() == 0){
        me.displayRunway(info,me.selectedRunway);
      }else{
        me.myRunwayGroup.removeAllChildren();
      }
    }else{
      me.myRunwayGroup.removeAllChildren();
    }
    
    # -------------------- displayHeadingHorizonScale ---------------
    me.displayHeadingHorizonScale();
    
    
    # -------------------- display_heading_bug ---------------
    me.display_heading_bug();
    
    
    #---------------------- EEFS --------------------
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
  
  
  
  displayHeadingHorizonScale:func(){
      #Depend of which heading we want to display
      if(me.input.hdgDisplay.getValue()){
        me.heading = me.input.hdgReal.getValue();
      }else{
        me.heading = me.input.hdg.getValue();
      }
    
      me.headOffset = me.heading/10 - int (me.heading/10);
      me.headScaleOffset = me.headOffset;
      me.middleText = roundabout(me.heading/10);

      me.middleText = me.middleText == 36?0:me.middleText;
      me.leftText = me.middleText == 0?35:me.middleText-1;
      me.rightText = me.middleText == 35?0:me.middleText+1;
      me.rightRightText = me.rightText == 35?0:me.rightText+1;
      
      if (me.headOffset > 0.5) {
        me.middleOffset = -(me.headScaleOffset-1)*me.headScaleTickSpacing*2;
        #me.hdgLineL.show();
        #me.hdgLineR.hide();
      } else {
        me.middleOffset = -me.headScaleOffset*me.headScaleTickSpacing*2;
        #me.hdgLineR.show();
        #me.hdgLineL.hide();
      }
      #print(" me.heading:", me.heading,", me.headOffset:",me.headOffset, ", me.middleOffset:",me.middleOffset);
      me.headingScaleGroup.setTranslation(me.middleOffset , 0);
      me.hdgRH.setText(sprintf("%02d", me.rightText));
      me.hdgMH.setText(sprintf("%02d", me.middleText));
      me.hdgLH.setText(sprintf("%02d", me.leftText));
      me.hdgRRH.setText(sprintf("%02d", me.rightRightText));
      
      #me.hdgMH.setTranslation(me.middleOffset , 0);
      me.headingScaleGroup.update();
    
  },
  
  # flight path vector (FPV)
  display_Fpv:func(){
    me.fpvCalc = HudMath.getFlightPathIndicatorPosWind();
    me.fpv.setTranslation(me.fpvCalc);
  },
  
  display_Chevron : func(){
     #print(me.input.acc_yas.getValue());
    me.chevronGroup.setTranslation(me.fpvCalc[0],me.fpvCalc[1]-me.input.acc_yas.getValue()*me.chevronFactor);
  },
  
  display_heading_bug : func(){
      #Depend of which heading we want to display
      if(me.input.hdgDisplay.getValue()){
        me.heading = me.input.hdgReal.getValue();
      }else{
        me.heading = me.input.hdg.getValue();
      }
      var headOffset = -(geo.normdeg180(me.heading - me.input.hdgBug.getValue() ))*me.headScaleTickSpacing/5;
      me.head_scale_route_pointer.setTranslation(headOffset,0);
  },
  
  display_Acceleration_Box:func(){
    #Acc accBoxGroup in G(so I guess /9,8)
    if(me.input.wow_nlg.getValue()){
      me.acceleration_Box.setText(sprintf("%.2f", me.input.acc_yas.getValue()/9.8));
      me.accBoxGroup.show();
    }else{
      me.accBoxGroup.hide();
    } 
    
  },
  display_speedAltGroup:func(){
      me.Speed.setText(sprintf("%d",int(me.input.ias.getValue())));
    #print("Alt:",me.input.alt.getValue()," Calcul:" ,int(((me.input.alt.getValue()/100) - int(me.input.alt.getValue()/100))*100));
    me.feet_Alt.setText(sprintf("%d",int(((me.input.alt_instru.getValue()/100) - int(me.input.alt_instru.getValue()/100))*100)));
    me.hundred_feet_Alt.setText(sprintf("%d",int((me.input.alt_instru.getValue()/100))));
  },
  
  displayRunway:func( info, rwy){
    
    #Coord of the runways gps coord
    var RunwayCoord =  geo.Coord.new();
    var RunwaysCoordCornerLeft = geo.Coord.new();
    var RunwaysCoordCornerRight = geo.Coord.new();
    var RunwaysCoordEndCornerLeft = geo.Coord.new();
    var RunwaysCoordEndCornerRight = geo.Coord.new();
    
    #var info = airportinfo(icao;
    #Need to select the runways and write the conditions
    #2. SYNTHETIC RUNWAY. The synthetic runway symbol is an aid for locating the real runway, especially during low visibility conditions. 
    #It is only visible when: 
    #a. The INS is on.
    #b. The airport is the current fly-to waypoint. 
    #c. The runway data (heading and glideslope) were entered.
    #d. Both localizer and glideslope have been captured 
    #e. The runway is less than 10 nautical miles away. 
    #f. Lateral deviation is less than 7º.
    # The synthetic runway is removed from the HUD as soon as there is weight on the landing gear’s wheels. 
    
    
    #print("reciprocal:" , info.runways[rwy].reciprocal, " ICAO:", info.id, " runway:",info.runways[rwy].id);
    
    #Calculating GPS coord of the runway's corners
    RunwayCoord.set_latlon(info.runways[rwy].lat, info.runways[rwy].lon, info.elevation);
    
    RunwaysCoordCornerLeft.set_latlon(info.runways[rwy].lat, info.runways[rwy].lon, info.elevation);
    RunwaysCoordCornerLeft.apply_course_distance((info.runways[rwy].heading)-90,(info.runways[rwy].width)/2);
    
    RunwaysCoordCornerRight.set_latlon(info.runways[rwy].lat, info.runways[rwy].lon, info.elevation);
    RunwaysCoordCornerRight.apply_course_distance((info.runways[rwy].heading)+90,(info.runways[rwy].width)/2);
    
    RunwaysCoordEndCornerLeft.set_latlon(info.runways[rwy].lat, info.runways[rwy].lon, info.elevation);
    RunwaysCoordEndCornerLeft.apply_course_distance((info.runways[rwy].heading)-90,(info.runways[rwy].width)/2);
    RunwaysCoordEndCornerLeft.apply_course_distance((info.runways[rwy].heading),info.runways[rwy].length);
    
    RunwaysCoordEndCornerRight.set_latlon(info.runways[rwy].lat, info.runways[rwy].lon, info.elevation);
    RunwaysCoordEndCornerRight.apply_course_distance((info.runways[rwy].heading)+90,(info.runways[rwy].width)/2);
    RunwaysCoordEndCornerRight.apply_course_distance((info.runways[rwy].heading),info.runways[rwy].length);
    
    
    #Calculating the HUD coord of the runways coord
    var MyRunwayTripos                     = HudMath.getPosFromCoord(RunwayCoord);
    var MyRunwayCoordCornerLeftTripos      = HudMath.getPosFromCoord(RunwaysCoordCornerLeft);
    var MyRunwayCoordCornerRightTripos     = HudMath.getPosFromCoord(RunwaysCoordCornerRight);
    var MyRunwayCoordCornerEndLeftTripos   = HudMath.getPosFromCoord(RunwaysCoordEndCornerLeft);
    var MyRunwayCoordCornerEndRightTripos  = HudMath.getPosFromCoord(RunwaysCoordEndCornerRight);
    
    
    

    #Updating : clear all previous stuff
    me.myRunwayGroup.removeAllChildren();
    #drawing the runway
    me.RunwaysDrawing = me.myRunwayGroup.createChild("path")
    .moveTo(MyRunwayCoordCornerLeftTripos)
    .lineTo(MyRunwayCoordCornerRightTripos)
    .lineTo(MyRunwayCoordCornerEndRightTripos)
    .lineTo(MyRunwayCoordCornerEndLeftTripos)
    .lineTo(MyRunwayCoordCornerLeftTripos)
    .setStrokeLineWidth(4);
    
    me.myRunwayGroup.update();
    
    #tranlating the circle ...
    #old stuff : not used anymore
    #me.myRunway.setTranslation(MyRunwayTripos);
    #me.myRunwayBeginLeft.setTranslation(MyRunwayCoordCornerLeftTripos);
    #me.myRunwayBeginRight.setTranslation(MyRunwayCoordCornerRightTripos);
    #me.myRunwayEndRight.setTranslation(MyRunwayCoordCornerEndLeftTripos);
    #me.myRunwayEndLeft.setTranslation(MyRunwayCoordCornerEndRightTripos);
    
    
    #myRunwayBeginLeft
    #me.myRunway.hide();
  },
  
  
  
  displayEEGS: func() {
        #note: this stuff is expensive like hell to compute, but..lets do it anyway.
        
        #var me.funnelParts = 40;#max 10
        var st = systime();
        me.eegsMe.dt = st-me.lastTime;
        if (me.eegsMe.dt > me.averageDt*3) {
            me.lastTime = st;
            me.gunPos   = [[nil,nil]];
            for(i = 1;i < me.funnelParts;i+=1){
              var tmp = [];
              for(var myloopy = 0;myloopy <= i+2;myloopy+=1){
                append(tmp,nil);
              }
              append(me.gunPos, tmp);
            }
  
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
            me.drawEEGSPipper = 0;
            me.drawEEGS300 = 0;
            me.drawEEGS600 = 0;
            for (var l = 0;l < me.funnelParts;l+=1) {
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
                    if (me.designatedDistanceFT != nil and !me.drawEEGSPipper) {
                      if (l != 0 and me.eegsMe.shellPosDist[l] >= me.designatedDistanceFT and me.eegsMe.shellPosDist[l]>me.eegsMe.shellPosDist[l-1]) {
                        var highdist = me.eegsMe.shellPosDist[l];
                        var lowdist = me.eegsMe.shellPosDist[l-1];
                        var fractionX = HudMath.extrapolate(me.designatedDistanceFT,lowdist,highdist,me.eegsMe.shellPosX[l-1],me.eegsMe.shellPosX[l]);
                        var fractionY = HudMath.extrapolate(me.designatedDistanceFT,lowdist,highdist,me.eegsMe.shellPosY[l-1],me.eegsMe.shellPosY[l]);
                        me.eegsRightX[0] = fractionX;
                        me.eegsRightY[0] = fractionY;
                        me.drawEEGSPipper = 1;
                      }
                    }
                    if (!me.drawEEGS300) {
                      if (l != 0 and me.eegsMe.shellPosDist[l] >= 300*M2FT and me.eegsMe.shellPosDist[l]>me.eegsMe.shellPosDist[l-1]) {
                        var highdist = me.eegsMe.shellPosDist[l];
                        var lowdist = me.eegsMe.shellPosDist[l-1];
                        var fractionX = HudMath.extrapolate(300*M2FT,lowdist,highdist,me.eegsMe.shellPosX[l-1],me.eegsMe.shellPosX[l]);
                        var fractionY = HudMath.extrapolate(300*M2FT,lowdist,highdist,me.eegsMe.shellPosY[l-1],me.eegsMe.shellPosY[l]);
                        me.eegsRightX[1] = fractionX;
                        me.eegsRightY[1] = fractionY;
                        me.drawEEGS300 = 1;
                      }
                    }
                    if (!me.drawEEGS600) {
                      if (l != 0 and me.eegsMe.shellPosDist[l] >= 600*M2FT and me.eegsMe.shellPosDist[l]>me.eegsMe.shellPosDist[l-1]) {
                        var highdist = me.eegsMe.shellPosDist[l];
                        var lowdist = me.eegsMe.shellPosDist[l-1];
                        var fractionX = HudMath.extrapolate(600*M2FT,lowdist,highdist,me.eegsMe.shellPosX[l-1],me.eegsMe.shellPosX[l]);
                        var fractionY = HudMath.extrapolate(600*M2FT,lowdist,highdist,me.eegsMe.shellPosY[l-1],me.eegsMe.shellPosY[l]);
                        me.eegsRightX[2] = fractionX;
                        me.eegsRightY[2] = fractionY;
                        me.drawEEGS600 = 1;
                      }
                    }
                }
            }
            if (me.eegsMe.allow) {
                # draw the funnel
                for (var k = 0;k<me.funnelParts;k+=1) {
                    
                    me.eegsLeftX[k]  = me.eegsMe.shellPosX[k];
                    me.eegsLeftY[k]  = me.eegsMe.shellPosY[k];
                }
                me.eegsGroup.removeAllChildren();
                for (var i = 0; i < me.funnelParts-1; i+=1) {
                    me.fnnl = me.eegsGroup.createChild("path")
                        .moveTo(me.eegsLeftX[i], me.eegsLeftY[i])
                        .lineTo(me.eegsLeftX[i+1], me.eegsLeftY[i+1])
                        .setStrokeLineWidth(4);
                    if (i==0) {
                      me.fnnl.setStrokeDashArray([5,5]);
                    }
                }
                if (me.drawEEGSPipper) {
                    me.EEGSdeg = math.max(0,HudMath.extrapolate(me.designatedDistanceFT*FT2M,1200,300,360,0))*D2R;
                    me.EEGSdegPos = [math.sin(me.EEGSdeg)*40,40-math.cos(me.EEGSdeg)*40];
                    if (me.EEGSdeg<180*D2R) {
                      me.eegsGroup.createChild("path")
                          .moveTo(me.eegsRightX[0], me.eegsRightY[0]-40)
                          .arcSmallCW(40,40,0,me.EEGSdegPos[0],me.EEGSdegPos[1])
                          .setStrokeLineWidth(4);
                    } elsif (me.EEGSdeg>=360*D2R) {
                      me.eegsGroup.createChild("path")
                          .moveTo(me.eegsRightX[0], me.eegsRightY[0]-40)
                          .arcSmallCW(40,40,0,0,80)
                          .arcSmallCW(40,40,0,0,-80)
                          .setStrokeLineWidth(4);
                    } else {
                      me.eegsGroup.createChild("path")
                          .moveTo(me.eegsRightX[0], me.eegsRightY[0]-40)
                          .arcLargeCW(40,40,0,me.EEGSdegPos[0],me.EEGSdegPos[1])
                          .setStrokeLineWidth(4);
                    }
                }
                if (me.drawEEGS300 and !me.drawEEGSPipper) {
                    var halfspan = math.atan2(me.wingspanFT*0.5,300*M2FT)*R2D*HudMath.getPixelPerDegreeAvg(2.0);#35ft average fighter wingspan
                    me.eegsGroup.createChild("path")
                        .moveTo(me.eegsRightX[1]-halfspan, me.eegsRightY[1])
                        .horiz(halfspan*2)
                        .setStrokeLineWidth(4);
                }
                if (me.drawEEGS600 and !me.drawEEGSPipper) {
                    var halfspan = math.atan2(me.wingspanFT*0.5,600*M2FT)*R2D*HudMath.getPixelPerDegreeAvg(2.0);#35ft average fighter wingspan
                    me.eegsGroup.createChild("path")
                        .moveTo(me.eegsRightX[2]-halfspan, me.eegsRightY[2])
                        .horiz(halfspan*2)
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
            
            for (var j = 0;j < me.funnelParts;j+=1) {
                
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
    
    interpolate: func (start, end, fraction) {
        me.xx = (start.x()*(1-fraction)
          +end.x()*fraction);
        me.yy = (start.y()*(1-fraction)+end.y()*fraction);
        me.zz = (start.z()*(1-fraction)+end.z()*fraction);

        me.cc = geo.Coord.new();
        me.cc.set_xyz(me.xx,me.yy,me.zz);

        return me.cc;
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
