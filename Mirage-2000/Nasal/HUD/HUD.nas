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

    m.MaxX = 420; #the canvas is 420 *2;
    m.MaxY = 512; #the canvas is 420 *2;
    
    m.red = 0.3;
    m.green = 1.0;
    m.blue = 0.3;
    
    m.myGreen = [0.3,1.0,0.3,1];
    
#     .setColor(m.myGreen)
    
    m.canvas.addPlacement(placement);
    #m.canvas.setColorBackground(red, green, blue, 0.0);
    #m.canvas.setColorBackground(0.36, 1, 0.3, 0.02);
    m.canvas.setColorBackground(m.red, m.green, m.blue, 0.00);
    
    #.set("stroke", "rgba(0,255,0,0.9)");
    #.setColor(0.3,1,0.3)
    
    m.root =
        m.canvas.createGroup()
                .setTranslation(HudMath.getCenterOrigin())
                .set("font", "LiberationFonts/LiberationMono-Regular.ttf")
                .setDouble("character-size", 18)
                .setDouble("character-aspect-ration", 0.9);
#     m.root.setColor(m.red,m.green,m.blue,1);

    m.text =
      m.root.createChild("group");
            
            
    m.Fire_GBU =
      m.text.createChild("text")
            .setAlignment("center-center")
            .setTranslation(0, 70)
            .setColor(m.myGreen)
            .setDouble("character-size", 42);
            
            
    #fpv
    m.fpv = m.root.createChild("path")
        .setColor(m.myGreen)
        .moveTo(15, 0)
        .horiz(40)
        .moveTo(15, 0)
        .arcSmallCW(15,15, 0, -30, 0)
        .arcSmallCW(15,15, 0, 30, 0)
        .moveTo(-15, 0)
        .horiz(-40)
        .moveTo(0, -15)
        .vert(-15)
        .setStrokeLineWidth(4);
        
  m.AutopilotStar = m.root.createChild("text")
    .setColor(m.myGreen)
    .setTranslation(150,0)
    .setDouble("character-size", 50)
    .setAlignment("center-center")
    .setText("*"); 
        
        
         
      #Little House pointing  Waypoint
      m.HouseSize = 4;
      m.HeadingHouse = m.root.createChild("path")
      .setColor(m.myGreen)
      .setStrokeLineWidth(5)
      .moveTo(-20,0)
      .vert(-30)
      .lineTo(0,-50)
      .lineTo(20,-30)
      .vert(30);
 
        
   #Chevrons Acceleration Vector (AV)
   m.chevronFactor = 40;
   m.chevronGroup = m.root.createChild("group");
   
  m.LeftChevron = m.chevronGroup.createChild("text")
  .setColor(m.myGreen)
  .setTranslation(-150,0)
  .setDouble("character-size", 60)
  .setAlignment("center-center")
  .setText(">");    
  
  m.RightChevron = m.chevronGroup.createChild("text")
    .setColor(m.myGreen)
    .setTranslation(150,0)
    .setDouble("character-size", 60)
    .setAlignment("center-center")
    .setText("<");   
   
        
    #bore cross
    m.boreCross = m.root.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-20, 0)
      .horiz(40)
      .moveTo(0, -20)
      .vert(40)
      .setStrokeLineWidth(4);
                   
                   
    #WP cross
    m.WaypointCross = m.root.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-20, 0)
      .horiz(12)
      .moveTo(8, 0)
      .horiz(12)
      .moveTo(0, -20)
      .vert(12)
      .moveTo(0, 8)
      .vert(12)
      .setStrokeLineWidth(4);
                   

                   

    # Horizon groups
    m.horizon_group = m.root.createChild("group");
    m.h_rot   = m.horizon_group.createTransform();
    m.horizon_sub_group = m.horizon_group.createChild("group");
  
    # Horizon and pitch lines
    m.horizon_sub_group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-1000, 0)
      .horiz(2000)
      .setStrokeLineWidth(4);
                   
    #ILS stuff
    m.ILS_Scale_dependant = m.horizon_sub_group.createChild("group");
                    
    #Runway on the HorizonLine
    m.RunwayOnTheHorizonLine = m.ILS_Scale_dependant.createChild("path")
      .setColor(m.myGreen)
      .move(0,0)
      .vert(-30)
      .setStrokeLineWidth(6);   
                    
    m.ILS_localizer_deviation = m.ILS_Scale_dependant.createChild("path")
      .setColor(m.myGreen)
      .move(0,0)
      .vert(1500)
      .setStrokeDashArray([30, 30, 30, 30, 30]) 
      #.setCenter(0.0)
      .setStrokeLineWidth(5);                  
    m.ILS_localizer_deviation.setCenter(0,0);
    
    #Part of the ILS not dependant of the SCALE
    m.ILS_Scale_Independant = m.root.createChild("group");
    m.ILS_Square  = m.ILS_Scale_Independant.createChild("path")
      .setColor(m.myGreen)
      .move(-25,-25)
      .vert(50)
      .horiz(50)
      .vert(-50)
      .horiz(-50)
      .setStrokeLineWidth(6);
    #Landing Brackets
    m.brackets = m.ILS_Scale_Independant.createChild("group");
    m.LeftBracket = m.brackets.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(-140,0)
      .setDouble("character-size", 60)
      .setAlignment("center-center")
      .setText("]");    
  
    m.RightBracket = m.brackets.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(140,0)
      .setDouble("character-size", 60)
      .setAlignment("center-center")
      .setText("["); 
    
    
                  
    m.ladderScale = 7.5;#7.5
    m.maxladderspan =  200;
                   
   for (var myladder = 5;myladder <= 90;myladder+=5)
   {
     if (myladder/10 == int(myladder/10)){
        #Text bellow 0 left
        m.horizon_sub_group.createChild("text")
          .setColor(m.myGreen)
          .setAlignment("right-center")
          .setTranslation(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
          .setDouble("character-size", 30)
          .setText(myladder);
        #Text bellow 0 left
        m.horizon_sub_group.createChild("text")
          .setColor(m.myGreen)
          .setAlignment("left-center")
          .setTranslation(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
          .setDouble("character-size", 30)
          .setText(myladder);

        #Text above 0 left         
        m.horizon_sub_group.createChild("text")
          .setColor(m.myGreen)
          .setAlignment("right-center")
          .setTranslation(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
          .setDouble("character-size", 30)
          .setText(myladder); 
        #Text above 0 right   
        m.horizon_sub_group.createChild("text")
          .setColor(m.myGreen)
          .setAlignment("left-center")
          .setTranslation(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
          .setDouble("character-size", 30)
          .setText(myladder);
      }
      
  # =============  BELLOW 0 ===================           
    #half line bellow 0 (left part)       ------------------ 
    m.horizon_sub_group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .vert(-m.maxladderspan/15)
      .setStrokeLineWidth(4); 
                   
    m.horizon_sub_group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .horiz(m.maxladderspan*2/15)
      .setStrokeLineWidth(4);             
    m.horizon_sub_group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-abs(m.maxladderspan - m.maxladderspan*2/15*2), HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .horiz(m.maxladderspan*2/15)
      .setStrokeLineWidth(4);    
    m.horizon_sub_group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-abs(m.maxladderspan - m.maxladderspan*2/15*4), HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .horiz(m.maxladderspan*2/15)
      .setStrokeLineWidth(4);
                  
    #half line (rigt part)       ------------------   
    m.horizon_sub_group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .vert(-m.maxladderspan/15)
      .setStrokeLineWidth(4); 
                   
    m.horizon_sub_group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .horiz(-m.maxladderspan*2/15)
      .setStrokeLineWidth(4);             
    m.horizon_sub_group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(abs(m.maxladderspan - m.maxladderspan*2/15*2), HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .horiz(-m.maxladderspan*2/15)
      .setStrokeLineWidth(4);    
    m.horizon_sub_group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(abs(m.maxladderspan - m.maxladderspan*2/15*4), HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .horiz(-m.maxladderspan*2/15)
      .setStrokeLineWidth(4);              
                  
                  
  
                   
# =============  ABOVE 0 ===================               
    m.horizon_sub_group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
      .vert(m.maxladderspan/15)
      .setStrokeLineWidth(4); 
                   
    m.horizon_sub_group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
      .horiz(m.maxladderspan/3*2)
      .setStrokeLineWidth(4);             
          
    #half line (rigt part)       ------------------           
    m.horizon_sub_group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
      .horiz(-m.maxladderspan/3*2)
      .setStrokeLineWidth(4);            
    m.horizon_sub_group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
      .vert(m.maxladderspan/15)
      .setStrokeLineWidth(4); 
                   

   }           
                   
       
    #This is the inverted T that is present in at -13 and putting this line on the horizon will keep the aircraft at 13 which is the perfect angle to take off and to land
    m.InvertedT = m.root.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-m.maxladderspan/2, 0)
      .horiz(m.maxladderspan)
      .moveTo(0, 0)
      .vert(-m.maxladderspan/15*2)
      .setStrokeLineWidth(6);
    
#     m.InvertedT = m.root.createChild("path")
#                       .moveTo(-m.maxladderspan/2, HudMath.getCenterPosFromDegs(0,-13)[1])
#                       .horiz(m.maxladderspan)
#                       .moveTo(0, HudMath.getCenterPosFromDegs(0,-13)[1])
#                       .vert(-m.maxladderspan/15*2)
#                       .setStrokeLineWidth(4);  
                   
                   
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
    .setColor(m.myGreen)
    .moveTo(-m.headScaleTickSpacing*2, m.headScaleVerticalPlace)
    .vert(-15)
    .moveTo(0, m.headScaleVerticalPlace)
    .vert(-15)
    .moveTo(m.headScaleTickSpacing*2, m.headScaleVerticalPlace)
    .vert(-15)
    .moveTo(m.headScaleTickSpacing*4, m.headScaleVerticalPlace)
    .vert(-15)
    .moveTo(-m.headScaleTickSpacing, m.headScaleVerticalPlace)
    .vert(-5)
    .moveTo(m.headScaleTickSpacing, m.headScaleVerticalPlace)
    .vert(-5)
    .moveTo(-m.headScaleTickSpacing*3, m.headScaleVerticalPlace)
    .vert(-5)
    .moveTo(m.headScaleTickSpacing*3, m.headScaleVerticalPlace)
    .vert(-5)
    .setStrokeLineWidth(5)
    .show();
    
    #Heading middle number on horizon line
    me.hdgMH = m.headingScaleGroup.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(0,m.headScaleVerticalPlace -15)
      .setDouble("character-size", 30)
      .setAlignment("center-bottom")
      .setText("0"); 
                   
#     # Heading left number on horizon line
      me.hdgLH = m.headingScaleGroup.createChild("text")
        .setColor(m.myGreen)
        .setTranslation(-m.headScaleTickSpacing*2,m.headScaleVerticalPlace -15)
        .setDouble("character-size", 30)
        .setAlignment("center-bottom")
        .setText("350");           

#     # Heading right number on horizon line
      me.hdgRH = m.headingScaleGroup.createChild("text")
        .setColor(m.myGreen)
        .setTranslation(m.headScaleTickSpacing*2,m.headScaleVerticalPlace -15)
        .setDouble("character-size", 30)
        .setAlignment("center-bottom")
        .setText("10");    
          
      # Heading right right number on horizon line
      me.hdgRRH = m.headingScaleGroup.createChild("text")
        .setColor(m.myGreen)
        .setTranslation(m.headScaleTickSpacing*4,m.headScaleVerticalPlace -15)
        .setDouble("character-size", 30)
        .setAlignment("center-bottom")
        .setText("20");          

    
      
    #Point the The Selected Route. it's at the middle of the HUD
    m.TriangleSize = 4;
    m.head_scale_route_pointer = m.headingStuff.createChild("path")
      .setColor(m.myGreen)
      .setStrokeLineWidth(3)
      .moveTo(0, m.headScaleVerticalPlace)
      .lineTo(m.TriangleSize*-5/2, (m.headScaleVerticalPlace)+(m.TriangleSize*5))
      .lineTo(m.TriangleSize*5/2,(m.headScaleVerticalPlace)+(m.TriangleSize*5))
      .lineTo(0, m.headScaleVerticalPlace);
    
    

    #a line representthe middle and the actual heading
    m.heading_pointer_line = m.headingStuff.createChild("path")
      .setColor(m.myGreen)
      .setStrokeLineWidth(4)
      .moveTo(0, m.headScaleVerticalPlace + 2)
      .vert(20);
    

     m.speedAltGroup = m.root.createChild("group");
     # Heading right right number on horizon line
    me.Speed = m.speedAltGroup.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(- m.maxladderspan,m.headScaleVerticalPlace)
      .setDouble("character-size", 50)
      .setAlignment("right-bottom")
      .setText("0"); 
          
    me.Speed_Mach = m.speedAltGroup.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(- m.maxladderspan,m.headScaleVerticalPlace+25)
      .setDouble("character-size", 30)
      .setAlignment("right-bottom")
      .setText("0"); 
          

     # Heading right right number on horizon line
     me.hundred_feet_Alt = m.speedAltGroup.createChild("text")
          .setTranslation(m.maxladderspan + 60 ,m.headScaleVerticalPlace)
          .setDouble("character-size", 50)
          .setAlignment("right-bottom")
          .setText("0");   
      

     # Heading right right number on horizon line
     me.feet_Alt = m.speedAltGroup.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(m.maxladderspan + 60,m.headScaleVerticalPlace)
      .setDouble("character-size", 30)
      .setAlignment("left-bottom")
      .setText("00");  
          
          
     # Heading right right number on horizon line
     me.groundAlt = m.speedAltGroup.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(m.maxladderspan + 95,m.headScaleVerticalPlace+25)
      .setDouble("character-size", 30)
      .setAlignment("right-bottom")
      .setText("*****"); 
      
         # Heading right right number on horizon line
     me.theH = m.speedAltGroup.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(m.maxladderspan + 100,m.headScaleVerticalPlace+25)
      .setDouble("character-size", 30)
      .setAlignment("left-bottom")
      .setText("H");  
          
    m.alphaGroup = m.root.createChild("group");      
  
    #alpha
    m.alpha = m.alphaGroup.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(- m.maxladderspan-70,m.headScaleVerticalPlace+50)
      .setDouble("character-size", 40)
      .setAlignment("right-center")
      .setText("α");
          
    #aoa 
    m.aoa = m.alphaGroup.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(- m.maxladderspan-50,m.headScaleVerticalPlace+50)
      .setDouble("character-size", 30)
      .setAlignment("left-center")
      .setText("0.0");
    
      
      #Take off Acceleration
      m.accBoxGroup = m.root.createChild("group");  
        
      m.acceleration_Box = m.accBoxGroup.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(0,0)
      .setDouble("character-size", 35)
      .setAlignment("center-center")
      .setText("0.00"); 
      
      m.accBoxLine = m.accBoxGroup.createChild("path")
        .setColor(m.myGreen)
        .moveTo(-70, -25)
        .horiz(140)
        .vert(50)
        .horiz(-140)
        .vert(-50)
        .setStrokeLineWidth(4);         
      m.accBoxGroup.setTranslation(0,m.headScaleVerticalPlace*2/5);
      
      #Waypoint Group
      m.waypointGroup = m.root.createChild("group");

      
      m.waypointSimpleGroup = m.root.createChild("group");
      #Distance to next Waypoint
      m.waypointDistSimple = m.waypointSimpleGroup.createChild("text")
        .setColor(m.myGreen)
        .setTranslation( m.maxladderspan + 45 ,m.headScaleVerticalPlace*2/5)
        .setDouble("character-size", 30)
        .setAlignment("right-center")
        .setText("0");    
      # N
#       m.waypointNSimple = m.waypointSimpleGroup.createChild("text")
#         .setTranslation( m.maxladderspan + 65 ,m.headScaleVerticalPlace*2/5)
#         .setDouble("character-size", 30)
#         .setAlignment("center-center")
#         .setText("N");     
      #next Waypoint NUMBER
      m.waypointNumberSimple = m.waypointSimpleGroup.createChild("text")
        .setColor(m.myGreen)
        .setTranslation( m.maxladderspan + 85 ,m.headScaleVerticalPlace*2/5)
        .setDouble("character-size", 30)
        .setAlignment("left-center")
        .setText("00"); 
      
      #Distance to next Waypoint
      m.waypointDist = m.waypointGroup.createChild("text")
        .setColor(m.myGreen)
        .setTranslation( m.maxladderspan + 80 ,m.headScaleVerticalPlace*2/5)
        .setDouble("character-size", 30)
        .setAlignment("left-center")
        .setText("0");    
      # N
#       m.waypointN = m.waypointGroup.createChild("text")
#         .setTranslation( m.maxladderspan + 120 ,m.headScaleVerticalPlace*2/5)
#         .setDouble("character-size", 30)
#         .setAlignment("left-center")
#         .setText("N");   
        
      #next Waypoint NUMBER
      m.waypointNumber = m.waypointGroup.createChild("text")
        .setColor(m.myGreen)
        .setTranslation( m.maxladderspan + 80 ,m.headScaleVerticalPlace*2/5-25)
        .setDouble("character-size", 30)
        .setAlignment("left-center")
        .setText("00");     
      #bull eye
#       m.BE = m.waypointGroup.createChild("text")
#         .setTranslation( m.maxladderspan + 55 ,m.headScaleVerticalPlace*2/5-25)
#         .setDouble("character-size", 30)
#         .setAlignment("right-center")
#         .setText("BE");
        
      m.DEST = m.waypointGroup.createChild("text")
        .setColor(m.myGreen)
        .setTranslation( m.maxladderspan + 55 ,m.headScaleVerticalPlace*2/5-25)
        .setDouble("character-size", 30)
        .setAlignment("right-center")
        .setText("DEST");
        
      #heading to the next Waypoint
      m.waypointHeading = m.waypointGroup.createChild("text")
        .setColor(m.myGreen)
        .setTranslation( m.maxladderspan + 65 ,m.headScaleVerticalPlace*2/5)
        .setDouble("character-size", 30)
        .setAlignment("right-center")
        .setText("000/"); 

      
      
                   
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
#         ;
#   
#     m.myRunwayBeginLeft = m.myRunwayGroup.createChild("path")
#         .moveTo(15, 0)
#         .arcSmallCW(15,15, 0, -30, 0)
#         .arcSmallCW(15,15, 0, 30, 0)
#         .setStrokeLineWidth(4)
#         ;
#         
#     m.myRunwayBeginRight = m.myRunwayGroup.createChild("path")
#         .moveTo(15, 0)
#         .arcSmallCW(15,15, 0, -30, 0)
#         .arcSmallCW(15,15, 0, 30, 0)
#         .setStrokeLineWidth(4)
#         ;
#     
#      m.myRunwayEndRight = m.myRunwayGroup.createChild("path")
#         .moveTo(15, 0)
#         .arcSmallCW(15,15, 0, -30, 0)
#         .arcSmallCW(15,15, 0, 30, 0)
#         .setStrokeLineWidth(4)
#         ;
# 
#      m.myRunwayEndLeft = m.myRunwayGroup.createChild("path")
#         .moveTo(15, 0)
#         .arcSmallCW(15,15, 0, -30, 0)
#         .arcSmallCW(15,15, 0, 30, 0)
#         .setStrokeLineWidth(4)
#         ;    
#       
   ##################################### Target Circle ####################################
    m.targetArray = [];
    m.circle_group2 = m.radarStuffGroup.createChild("group");
    for(var i = 1; i <= MaxTarget; i += 1){
      myCircle = m.circle_group2.createChild("path")
        .setColor(m.myGreen)
        .moveTo(25, 0)
        .arcSmallCW(25,25, 0, -50, 0)
        .arcSmallCW(25,25, 0, 50, 0)
        .setStrokeLineWidth(5)
        ;
      append(m.targetArray, myCircle);
    }
    m.targetrot   = m.circle_group2.createTransform();
  
    ####################### Info Text ########################################
    m.TextInfoArray = [];
    m.TextInfoGroup = m.radarStuffGroup.createChild("group");
    
    for(var i = 1; i <= MaxTarget; i += 1){
        # on affiche des infos de la cible a cote du cercle
        text_info = m.TextInfoGroup.createChild("text", "infos")
          .setColor(m.myGreen)
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
          .setColor(m.myGreen)
          .setStrokeLineWidth(3)
          .moveTo(0, TriangleSize*-1)
          .lineTo(TriangleSize*0.866, TriangleSize*0.5)
          .lineTo(TriangleSize*-0.866, TriangleSize*0.5)
          .lineTo(0, TriangleSize*-1);
    TriangleSize = TriangleSize*0.7;
    
        m.triangle2 = m.TriangleGroupe.createChild("path")
          .setColor(m.myGreen)
          .setStrokeLineWidth(3)
          .moveTo(0, TriangleSize*-1)
          .lineTo(TriangleSize*0.866, TriangleSize*0.5)
          .lineTo(TriangleSize*-0.866, TriangleSize*0.5)
          .lineTo(0, TriangleSize*-1.1);
         m.triangleRot =  m.TriangleGroupe.createTransform();
         
    m.TriangleGroupe.hide();
    
    
    m.Square_Group = m.radarStuffGroup.createChild("group");
     
    m.Locked_Square  = m.Square_Group.createChild("path")
      .setColor(m.myGreen)
      .move(-25,-25)
      .vert(50)
      .horiz(50)
      .vert(-50)
      .horiz(-50)
      .setStrokeLineWidth(6);
      
    m.Locked_Square_Dash  = m.Square_Group.createChild("path")
      .setColor(m.myGreen)
      .move(-25,-25)
      .vert(50)
      .horiz(50)
      .vert(-50)
      .horiz(-50)
      .setStrokeDashArray([10,10])
      .setStrokeLineWidth(5);
      
    m.Square_Group.hide();  
      
    
    
    m.root.setColor(m.red,m.green,m.blue,1);
    

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
      mach:       "/velocities/mach",
      gs:         "/velocities/groundspeed-kt",
      vs:         "/velocities/vertical-speed-fps",
      alt:        "/position/altitude-ft",
      alt_instru: "/instrumentation/altimeter/indicated-altitude-ft",
      rad_alt:    "position/altitude-agl-ft", #"/instrumentation/radar-altimeter/radar-altitude-ft",
      wow_nlg:    "/gear/gear[1]/wow",
      gearPos:    "/gear/gear[1]/position-norm",
      airspeed:   "/velocities/airspeed-kt",
      target_spd: "/autopilot/settings/target-speed-kt",
      acc:        "/fdm/jsbsim/accelerations/udot-ft_sec2",
      acc_yas:    "/fdm/yasim/accelerations/a-x",
      NavFreq:    "/instrumentation/nav/frequencies/selected-mhz",
      destRunway: "/autopilot/route-manager/destination/runway",
      destAirport:"/autopilot/route-manager/destination/airport",
      distNextWay:"/autopilot/route-manager/wp/dist",
      NextWayNum :"/autopilot/route-manager/current-wp",
      NextWayTrueBearing:"/autopilot/route-manager/wp/true-bearing-deg",
      NextWayBearing:"/autopilot/route-manager/wp/bearing-deg",
      AutopilotStatus:"/autopilot/locks/AP-status",
      currentWp     : "/autopilot/route-manager/current-wp",
      ILS_valid     :"/instrumentation/nav/data-is-valid",
      NavHeadingRunwayILS:"/instrumentation/nav/heading-deg",
      ILS_gs_in_range :"/instrumentation/nav/gs-in-range",
      ILS_gs_deg:  "/instrumentation/nav/gs-direct-deg",
      NavHeadingNeedleDeflectionILS:"/instrumentation/nav/heading-needle-deflection-norm",
      
      MasterArm      :"/controls/armament/master-arm",
      TimeToTarget   :"/sim/dialog/groundtTargeting/time-to-target",
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
    
    #loading Flightplan
    me.fp = flightplan();
    
    #Choose the heading to display
    me.getHeadingToDisplay();


    
 
    
 

    
    #Think this code sucks. If everyone have better, please, proceed :)
    me.eegsShow=0;
    me.selectedWeap = pylons.fcs.getSelectedWeapon();
    
    
    me.Fire_GBU.setText("Fire");
    me.showFire_GBU = 0;
    
    
    if(me.selectedWeap != nil and me.input.MasterArm.getValue()){
      if(me.selectedWeap.type != "30mm Cannon"){
        #Doing the math only for bombs
        if(me.selectedWeap.stage_1_duration+me.selectedWeap.stage_2_duration == 0){
          
          #print("Class of Load:" ~ me.selectedWeap.class);     
          me.DistanceToShoot = nil;
          me.DistanceToShoot = me.selectedWeap.getCCRP(me.input.TimeToTarget.getValue(), 0.05);
        
          if(me.DistanceToShoot != nil ){
            if(me.DistanceToShoot/ (me.input.gs.getValue() * KT2MPS) < 30){
              me.showFire_GBU = 1;
                me.Fire_GBU.setText(sprintf("TTR: %d ", int(me.DistanceToShoot/ (me.input.gs.getValue() * KT2MPS))));
              if(me.DistanceToShoot/ (me.input.gs.getValue() * KT2MPS) < 15){
                me.Fire_GBU.setText(sprintf("Fire : %d ", int(me.DistanceToShoot/ (me.input.gs.getValue() * KT2MPS))));
              }
            }
          }else{
             #print("Distance to shoot : nil");
          }
        }
      }else{me.eegsShow=me.input.MasterArm.getValue();}
    }
    
    me.Fire_GBU.setVisible(me.showFire_GBU);
    
    

    #me.hdg.setText(sprintf("%03d", me.input.hdg.getValue()));
    me.horizStuff = HudMath.getStaticHorizon();
    me.horizon_group.setTranslation(me.horizStuff[0]);
    me.h_rot.setRotation(me.horizStuff[1]);
    me.horizon_sub_group.setTranslation(me.horizStuff[2]);
    
    var rot = -me.input.roll.getValue() * math.pi / 180.0;
    #me.Textrot.setRotation(rot);

    #Displaying ILS STUFF (but only show after LOCALIZER capture)
    me.display_ILS_STUFF();
    
    #ILS not dependent of the Scale (but only show after GS capture)
    me.display_ILS_Square();
    #me.RunwayOnTheHorizonLine.hide();
    
    
    # Bore Cross. In navigation, the cross should only appear on NextWaypoint gps cooord, when dist to this waypoint is bellow 10 nm
    me.NXTWP = geo.Coord.new();
    
    #Calculate the GPS coord of the next WP
    me.NextWaypointCoordinate();
      
    #Display the Next WP
    me.displayWaypointCross();
     
    #Gun Cross (bore)
    me.displayBoreCross();
    
    
    
    
    # flight path vector (FPV)
    me.display_Fpv();
    
    # displaying the little house
    me.display_house();
    
    #chevronGroup
    me.display_Chevron();

    #Don't know what that does ...
    var speed_error = 0;
    if( me.input.target_spd.getValue() != nil )
      speed_error = 4 * clamp(
        me.input.target_spd.getValue() - me.input.airspeed.getValue(),
        -15, 15
      );
      
    #Acc accBoxGroup in G(so I guess /9,8)
    me.display_Acceleration_Box();

    #display_radarAltimeter
    me.display_radarAltimeter();
            
    #Display speedAltGroup
    me.display_speedAltGroup();
    
    #Display diplay_inverted_T
    me.display_inverted_T();
    
    #Display aoa
    me.display_alpha();
    
    #Display Route dist and waypoint number
    me.display_Waypoint();
    
    #me.hdg.hide();
    #me.groundspeed.hide();  
    #me.rad_alt.hide();
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
            #me.TriangleGroupe.show();
            #me.triangle.setTranslation(triPos);
            #me.triangle2.setTranslation(triPos);
            me.Square_Group.show();
            me.Locked_Square.setTranslation(triPos);
            me.Locked_Square_Dash.setTranslation(clamp(triPos[0],-me.MaxX*0.8,me.MaxX*0.8), clamp(triPos[1],-me.MaxY*0.8,me.MaxY*0.8));
            
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
            #me.TriangleGroupe.hide();
            me.Square_Group.hide();
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
         
        if(me.fp.getPlanSize() == me.fp.indexOfWP(me.fp.currentWP())+1){
          
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
  display_ILS_STUFF:func(){
    if(me.input.ILS_valid.getValue()){
      me.runwayPosHrizonOnHUD = HudMath.getPixelPerDegreeXAvg(7.5)*-(geo.normdeg180(me.heading - me.input.NavHeadingRunwayILS.getValue() ));

      me.ILS_Scale_dependant.setTranslation(me.runwayPosHrizonOnHUD,0);
      #me.ILS_localizer_deviation.setCenter(me.runwayPosHrizonOnHUD,0);
      me.ILS_localizer_deviation.setRotation(-45*me.input.NavHeadingNeedleDeflectionILS.getValue()*D2R);
      
      me.ILS_Scale_dependant.update();
      me.ILS_Scale_dependant.show();
      
    }else{
      me.ILS_Scale_dependant.hide();
      
    }

  },
  display_ILS_Square:func(){
    if(me.input.ILS_gs_in_range.getValue()){
      me.ILS_Square.setTranslation(0,HudMath.getCenterPosFromDegs(0,-me.input.ILS_gs_deg.getValue()-me.input.pitch.getValue())[1]);
      #me.ILS_Square.update();
      me.brackets.setTranslation(0,HudMath.getCenterPosFromDegs(0,me.input.pitch.getValue()-14)[1]);
      me.ILS_Scale_Independant.update();
      me.ILS_Scale_Independant.show();
    }else{
      me.ILS_Scale_Independant.hide();
    }
  },
  getHeadingToDisplay:func(){
      if(me.input.hdgDisplay.getValue()){
        me.heading = me.input.hdgReal.getValue();
      }else{
        me.heading = me.input.hdg.getValue();
      }
  },
  
  displayHeadingHorizonScale:func(){
      #Depend of which heading we want to display
#       if(me.input.hdgDisplay.getValue()){
#         me.heading = me.input.hdgReal.getValue();
#       }else{
#         me.heading = me.input.hdg.getValue();
#       }
    
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
    if(me.input.AutopilotStatus.getValue()=="AP1"){
      me.AutopilotStar.setTranslation(me.fpvCalc);
      me.AutopilotStar.show();
    }else{
      me.AutopilotStar.hide();
    }
  },
  
  display_house:func(){
    if(me.input.NextWayNum.getValue()!=-1){
      if(me.input.distNextWay.getValue() != nil and me.input.gearPos.getValue() == 0 and
        (!me.isInCanvas(HudMath.getPosFromCoord(me.NXTWP)[0],HudMath.getPosFromCoord(me.NXTWP)[1]) or me.input.distNextWay.getValue()>10) ){
        #Depend of which heading we want to display
#           if(me.input.hdgDisplay.getValue()){
#             me.heading = me.input.hdgReal.getValue();
#           }else{
#             me.heading = me.input.hdg.getValue();
#           }
          if(me.input.hdgDisplay.getValue()){
            me.houseTranslation = -(geo.normdeg180(me.heading - me.input.NextWayTrueBearing.getValue() ))*me.headScaleTickSpacing/5;
            #me.waypointHeading.setText(sprintf("%03d/",me.input.NextWayTrueBearing.getValue()));
          }else{
            me.houseTranslation = -(geo.normdeg180(me.heading - me.input.NextWayBearing.getValue() ))*me.headScaleTickSpacing/5;
            #me.waypointHeading.setText(sprintf("%03d/",me.input.NextWayBearing.getValue()));
          }
          #headOffset = -(geo.normdeg180(me.heading - me.input.hdgBug.getValue() ))*me.headScaleTickSpacing/5;
          #me.head_scale_route_pointer.setTranslation(headOffset,0);
        
        
        #print(me.houseTranslation/(me.headScaleTickSpacing/5));
        
        me.HeadingHouse.setTranslation(clamp(me.houseTranslation,-me.maxladderspan,me.maxladderspan),me.fpvCalc[1]);
        if(abs(me.houseTranslation/(me.headScaleTickSpacing/5))>90){
          me.HeadingHouse.setRotation(me.horizStuff[1]+(180* D2R));
        }else{
          me.HeadingHouse.setRotation(me.horizStuff[1]);
        }
        me.HeadingHouse.show();
      }else{
        me.HeadingHouse.hide();
      }
    }else{
        me.HeadingHouse.hide();
    }
  },
  
  display_Chevron : func(){
     #print(me.input.acc_yas.getValue());
    me.chevronGroup.setTranslation(me.fpvCalc[0],me.fpvCalc[1]-me.input.acc_yas.getValue()*me.chevronFactor);
    
    me.chevronGroup.update();
  },
  
  display_heading_bug : func(){
      #Depend of which heading we want to display
#       if(me.input.hdgDisplay.getValue()){
#         me.heading = me.input.hdgReal.getValue();
#       }else{
#         me.heading = me.input.hdg.getValue();
#       }
      headOffset = -(geo.normdeg180(me.heading - me.input.hdgBug.getValue() ))*me.headScaleTickSpacing/5;
      me.head_scale_route_pointer.setTranslation(headOffset,0);
      
      me.headingScaleGroup.update();
  },
  
  display_Acceleration_Box:func(){
    #Acc accBoxGroup in G(so I guess /9,8)
    if(me.input.wow_nlg.getValue()){
      me.acceleration_Box.setText(sprintf("%.2f", me.input.acc_yas.getValue()/9.8));
      me.accBoxGroup.show();
    }else{
      me.accBoxGroup.hide();
    } 
    
    me.accBoxGroup.update();
    
  },
  display_speedAltGroup:func(){
      me.Speed.setText(sprintf("%d",int(me.input.ias.getValue())));
      if(me.input.mach.getValue()>= 0.6){
        me.Speed_Mach.setText(sprintf("%0.2f",me.input.mach.getValue()));
        me.Speed_Mach.show();
      }else{
        me.Speed_Mach.hide();
      } 
      
    #print("Alt:",me.input.alt.getValue()," Calcul:" ,int(((me.input.alt.getValue()/100) - int(me.input.alt.getValue()/100))*100));
    me.feet_Alt.setText(sprintf("%02d",abs(int(((me.input.alt_instru.getValue()/100) - int(me.input.alt_instru.getValue()/100))*100))));
    if(me.input.alt_instru.getValue()>0){
      me.hundred_feet_Alt.setText(sprintf("%d",abs(int((me.input.alt_instru.getValue()/100)))));
    }else{
      me.hundred_feet_Alt.setText(sprintf("-%d",abs(int((me.input.alt_instru.getValue()/100)))));
    }
    
    me.speedAltGroup.update();
    
  },
  
  display_radarAltimeter:func(){
    if( me.input.rad_alt.getValue() < 5000) { #Or be selected be a special swith not yet done # Only show below 5000AGL
      if(abs(me.input.pitch.getValue())<20 and abs(me.input.roll.getValue())<20){ #if the angle is above 20° the radar do not work
        me.groundAlt.setText(sprintf("%4d", me.input.rad_alt.getValue()-8));#The radar should show 0 when on Ground      
      }else{
        me.groundAlt.setText("*****");
      }
      me.groundAlt.show();
      me.theH.show();
    }else{
      me.groundAlt.hide();
      me.theH.hide();
    }
  },
  
  display_inverted_T:func(){
    if(me.input.gearPos.getValue()){
      me.InvertedT.setTranslation(0, HudMath.getCenterPosFromDegs(0,-13)[1]);
      me.InvertedT.show();
    }else{
      me.InvertedT.hide();
    }
  },
  display_alpha:func(){
    if(me.input.gearPos.getValue() < 1 and abs(me.input.alpha.getValue())>2){
      me.aoa.setText(sprintf("%0.1f",me.input.alpha.getValue()));
      me.alphaGroup.show();
    }else{
      me.alphaGroup.hide();
    }
  },
  
  display_Waypoint:func(){
    
    if(me.input.distNextWay.getValue() != nil and me.input.gearPos.getValue() == 0){
      if(me.input.distNextWay.getValue()>10){
        me.waypointDist.setText(sprintf("%d N",int(me.input.distNextWay.getValue())));
        me.waypointDistSimple.setText(sprintf("%d N",int(me.input.distNextWay.getValue())));
      }else{
        me.waypointDist.setText(sprintf("%0.1f N",me.input.distNextWay.getValue()));
        me.waypointDistSimple.setText(sprintf("%0.1f N",me.input.distNextWay.getValue()));
      }
      me.waypointNumber.setText(sprintf("%02d",me.input.NextWayNum.getValue()));
      me.waypointNumberSimple.setText(sprintf("%02d",me.input.NextWayNum.getValue()));
      
      if(me.input.hdgDisplay.getValue()){
        me.waypointHeading.setText(sprintf("%03d/",me.input.NextWayTrueBearing.getValue()));
      }else{
        me.waypointHeading.setText(sprintf("%03d/",me.input.NextWayBearing.getValue()));
      }
      
      if(me.input.AutopilotStatus.getValue()=="AP1"){
        me.waypointGroup.show();
        me.waypointSimpleGroup.hide();
      }else{
        me.waypointSimpleGroup.show();
        me.waypointGroup.hide();
      }
    }else{
      me.waypointGroup.hide();
      me.waypointSimpleGroup.hide();
    }
      
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
    .setColor(me.myGreen)
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
  
  displayBoreCross:func(){
    #maybe it should be a different cross.
    if(me.input.MasterArm.getValue() and pylons.fcs.getSelectedWeapon() !=nil){   
      if(me.selectedWeap.type == "30mm Cannon"){#if weapons selected
        me.boreCross.setTranslation(HudMath.getBorePos());
        me.boreCross.show();
      }else{
        me.boreCross.hide();
      }
    }else{
      me.boreCross.hide();
    }
    
  },
  
  displayWaypointCross:func(){
    if(me.input.distNextWay.getValue()!= nil and me.input.distNextWay.getValue()<10 and me.input.gearPos.getValue() == 0 
                       and me.input.NextWayNum.getValue()!=-1 and me.NXTWP != nil and me.fp.currentWP() != nil){#if waypoint is active
      me.WaypointCross.setTranslation(HudMath.getPosFromCoord(me.NXTWP));
      me.WaypointCross.show();
    }else{
      me.WaypointCross.hide();
    }
  },
  
  NextWaypointCoordinate:func(){ 
      if(me.fp.currentWP() != nil){
          me.NxtElevation = getprop("/autopilot/route-manager/route/wp[" ~ me.input.currentWp.getValue() ~ "]/altitude-m");
          #print("me.NxtWP_latDeg:",me.NxtWP_latDeg, " me.NxtWP_lonDeg:",me.NxtWP_lonDeg);
          var Geo_Elevation = geo.elevation(me.fp.currentWP().lat , me.fp.currentWP().lon);    
          Geo_Elevation = Geo_Elevation == nil ? 0: Geo_Elevation; 
          #print("Geo_Elevation:",Geo_Elevation," me.NxtElevation:",me.NxtElevation);
          if( me.NxtElevation  == nil or me.NxtElevation  < Geo_Elevation){
            me.NXTWP.set_latlon(me.fp.currentWP().lat , me.fp.currentWP().lon ,  Geo_Elevation + 2);
          }else{
            me.NXTWP.set_latlon(me.fp.currentWP().lat , me.fp.currentWP().lon , me.NxtElevation );
          }
          
      }
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
                        .setColor(me.myGreen)
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
                    
                    #drawing mini and centra point 
                    me.eegsGroup.createChild("path")
                          .moveTo(me.eegsRightX[0],me.eegsRightY[0])
                          .lineTo(me.eegsRightX[0],me.eegsRightY[0])
                          .moveTo(me.eegsRightX[0], me.eegsRightY[0]-40)  
                          .lineTo(me.eegsRightX[0], me.eegsRightY[0]-55)
                          .moveTo(me.eegsRightX[0], me.eegsRightY[0]+40)  
                          .lineTo(me.eegsRightX[0], me.eegsRightY[0]+55)
                          .moveTo(me.eegsRightX[0]-40, me.eegsRightY[0])  
                          .lineTo(me.eegsRightX[0]-55, me.eegsRightY[0])
                          .moveTo(me.eegsRightX[0]+40, me.eegsRightY[0])  
                          .lineTo(me.eegsRightX[0]+55, me.eegsRightY[0])
                          .setColor(me.myGreen)
                          .setStrokeLineWidth(4);
                          
                          
                    #drawing mini and centra point 
                    if(me.designatedDistanceFT*FT2M <1200){
                    me.eegsGroup.createChild("path")
                          .moveTo(me.eegsRightX[0],me.eegsRightY[0]-40)
                          .lineTo(me.eegsRightX[0], me.eegsRightY[0]-55)
                          .setCenter(me.eegsRightX[0],me.eegsRightY[0])
                          .setColor(me.myGreen)
                          .setStrokeLineWidth(4)
                          .setRotation(me.EEGSdeg);
                    }
                    
                    if (me.EEGSdeg<180*D2R) {
                      me.eegsGroup.createChild("path")
                          .setColor(me.myGreen)
                          .moveTo(me.eegsRightX[0], me.eegsRightY[0]-40)
                          .arcSmallCW(40,40,0,me.EEGSdegPos[0],me.EEGSdegPos[1])
                          .setStrokeLineWidth(4);
                    } elsif (me.EEGSdeg>=360*D2R) {
                      me.eegsGroup.createChild("path")
                          .setColor(me.myGreen)
                          .moveTo(me.eegsRightX[0], me.eegsRightY[0]-40)
                          .arcSmallCW(40,40,0,0,80)
                          .arcSmallCW(40,40,0,0,-80)
                          .setStrokeLineWidth(4);
                    } else {
                      me.eegsGroup.createChild("path")
                          .setColor(me.myGreen)
                          .moveTo(me.eegsRightX[0], me.eegsRightY[0]-40)
                          .arcLargeCW(40,40,0,me.EEGSdegPos[0],me.EEGSdegPos[1])
                          .setStrokeLineWidth(4);
                    }
                }
                if (me.drawEEGS300 and !me.drawEEGSPipper) {
                    var halfspan = math.atan2(me.wingspanFT*0.5,300*M2FT)*R2D*HudMath.getPixelPerDegreeAvg(2.0);#35ft average fighter wingspan
                    me.eegsGroup.createChild("path")
                        .setColor(me.myGreen)
                        .moveTo(me.eegsRightX[1]-halfspan, me.eegsRightY[1])
                        .horiz(halfspan*2)
                        .setStrokeLineWidth(4);
                }
                if (me.drawEEGS600 and !me.drawEEGSPipper) {
                    var halfspan = math.atan2(me.wingspanFT*0.5,600*M2FT)*R2D*HudMath.getPixelPerDegreeAvg(2.0);#35ft average fighter wingspan
                    me.eegsGroup.createChild("path")
                        .setColor(me.myGreen)
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
    
    isInCanvas:func(x,y){
        #print("x:",x," y:",y," me.MaxX:",me.MaxX," MaxY",me.MaxY, " Result:",abs(x)<me.MaxX and abs(y)<me.MaxY;
        return abs(x)<me.MaxX and abs(y)<me.MaxY;
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
