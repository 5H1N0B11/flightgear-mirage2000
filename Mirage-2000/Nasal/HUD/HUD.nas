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
# var target_callsign = "";
# var target_altitude = 0;
# var target_closureRate = 0;
# var target_heading_deg = 0;
# var target_Distance = 0;
# var raw_list = [];


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
# var MaxTarget = 30;


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
     
    HudMath.init([-3.3935,-0.067,0.12032], [-3.3935,0.067,-0.041679], [1024,1024], [0,1.0], [0.8265,0.0], 0);
    #HudMath.init([-3.26163,-0.067,0.099216], [-3.26163,0.067,-0.062785], [1024,1024], [0,1.0], [0.8265,0.0], 0);
    #HudMath.init([-3.22012,-0.07327,0.101839], [-3.32073,0.07327,-0.093358], [1024,1024], [0.166803,1.0], [0.834003,0.0], 0); wrong HUD
        
    m.sy = 1024/2;                        
    m.sx = 1024/2;
    
    m.viewPlacement = 480;
    m.min = -m.viewPlacement * 0.846;
    m.max = m.viewPlacement * 0.846;

    m.MaxX = 420; #the canvas is 420 *2;
    m.MaxY = 512; #the canvas is 420 *2;
    
    m.red = 0.3;
    m.green = 1.0;
    m.blue = 0.3;
    
    m.MaxTarget = 30;
    
    #m.myGreen = [0.3,1.0,0.3,1];
    m.myGreen = [0,1,0,1];
    
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
   m.chevronFactor = 50;
   m.chevronGroup = m.root.createChild("group");
   m.chevronGroupAB = m.chevronGroup.createChild("group");
   
  m.LeftChevron = m.chevronGroup.createChild("text")
  .setColor(m.myGreen)
  .setTranslation(-150,0)
  .setDouble("character-size", 60)
  .setAlignment("center-center")
  .setText(">"); 
  m.LeftChevronAB = m.chevronGroupAB.createChild("text")
  .setColor(m.myGreen)
  .setTranslation(-180,0)
  .setDouble("character-size", 60)
  .setAlignment("center-center")
  .setText(">");  
  
  m.RightChevron = m.chevronGroup.createChild("text")
    .setColor(m.myGreen)
    .setTranslation(150,0)
    .setDouble("character-size", 60)
    .setAlignment("center-center")
    .setText("<");
  m.RightChevronAB = m.chevronGroupAB.createChild("text")
    .setColor(m.myGreen)
    .setTranslation(180,0)
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
      .moveTo(-700, 0)
      .horiz(1400)
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
    m.LadderGroup = m.horizon_sub_group.createChild("group");
                   
   for (var myladder = 5;myladder <= 90;myladder+=5)
   {
     
     if (myladder/10 == int(myladder/10)){
        #Text bellow 0 left
        m.LadderGroup.createChild("text")
          .setColor(m.myGreen)
          .setAlignment("right-center")
          .setTranslation(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
          .setDouble("character-size", 30)
          .setText(myladder);
        #Text bellow 0 left
        m.LadderGroup.createChild("text")
          .setColor(m.myGreen)
          .setAlignment("left-center")
          .setTranslation(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
          .setDouble("character-size", 30)
          .setText(myladder);

        #Text above 0 left         
        m.LadderGroup.createChild("text")
          .setColor(m.myGreen)
          .setAlignment("right-center")
          .setTranslation(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
          .setDouble("character-size", 30)
          .setText(myladder); 
        #Text above 0 right   
        m.LadderGroup.createChild("text")
          .setColor(m.myGreen)
          .setAlignment("left-center")
          .setTranslation(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
          .setDouble("character-size", 30)
          .setText(myladder);
      }
      
  # =============  BELLOW 0 ===================           
    #half line bellow 0 (left part)       ------------------ 
    m.LadderGroup.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .vert(-m.maxladderspan/15)
      .setStrokeLineWidth(4); 
                   
    m.LadderGroup.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .horiz(m.maxladderspan*2/15)
      .setStrokeLineWidth(4);             
    m.LadderGroup.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-abs(m.maxladderspan - m.maxladderspan*2/15*2), HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .horiz(m.maxladderspan*2/15)
      .setStrokeLineWidth(4);    
    m.LadderGroup.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-abs(m.maxladderspan - m.maxladderspan*2/15*4), HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .horiz(m.maxladderspan*2/15)
      .setStrokeLineWidth(4);
                  
    #half line (rigt part)       ------------------   
    m.LadderGroup.createChild("path")
      .setColor(m.myGreen)
      .moveTo(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .vert(-m.maxladderspan/15)
      .setStrokeLineWidth(4); 
                   
    m.LadderGroup.createChild("path")
      .setColor(m.myGreen)
      .moveTo(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .horiz(-m.maxladderspan*2/15)
      .setStrokeLineWidth(4);             
    m.LadderGroup.createChild("path")
      .setColor(m.myGreen)
      .moveTo(abs(m.maxladderspan - m.maxladderspan*2/15*2), HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .horiz(-m.maxladderspan*2/15)
      .setStrokeLineWidth(4);    
    m.LadderGroup.createChild("path")
      .setColor(m.myGreen)
      .moveTo(abs(m.maxladderspan - m.maxladderspan*2/15*4), HudMath.getPixelPerDegreeAvg(m.ladderScale)*myladder)
      .horiz(-m.maxladderspan*2/15)
      .setStrokeLineWidth(4);              
                  
                  
  
                   
# =============  ABOVE 0 ===================               
    m.LadderGroup.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
      .vert(m.maxladderspan/15)
      .setStrokeLineWidth(4); 
                   
    m.LadderGroup.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
      .horiz(m.maxladderspan/3*2)
      .setStrokeLineWidth(4);             
          
    #half line (rigt part)       ------------------           
    m.LadderGroup.createChild("path")
      .setColor(m.myGreen)
      .moveTo(m.maxladderspan, HudMath.getPixelPerDegreeAvg(m.ladderScale)*-myladder)
      .horiz(-m.maxladderspan/3*2)
      .setStrokeLineWidth(4);            
    m.LadderGroup.createChild("path")
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
    
      
    m.alphaGloadGroup = m.root.createChild("group");  
    m.gload_Text = m.alphaGloadGroup.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(- m.maxladderspan-50,-120)
      .setDouble("character-size", 35)
      .setAlignment("right-center")
      .setText("0.0");
      
    m.alpha_Text = m.alphaGloadGroup.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(- m.maxladderspan-50,-90)
      .setDouble("character-size", 35)
      .setAlignment("right-center")
      .setText("0.0");  
      
      m.alphaGloadGroup.hide();
      
    m.loads_Type_text = m.root.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(- m.maxladderspan-90,-150)
      .setDouble("character-size", 35)
      .setAlignment("right-center")
      .setText("0.0");  
    m.loads_Type_text.hide();
    
    
    # Bullet count when CAN is selected
    m.bullet_CountGroup = m.root.createChild("group");  
    m.Left_bullet_Count = m.bullet_CountGroup.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(-m.maxladderspan+60,100)
      .setDouble("character-size", 35)
      .setFont("LiberationFonts/LiberationMono-Bold.ttf")
      .setAlignment("center-center")
      .setText("0.0");  
    m.Right_bullet_Count = m.bullet_CountGroup.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(m.maxladderspan-60,100)
      .setDouble("character-size", 35)
      .setFont("LiberationFonts/LiberationMono-Bold.ttf")
      .setAlignment("center-center")
      .setText("0.0");  
    m.bullet_CountGroup.hide();
    
    # Pylon selection letters
    m.pylons_Group = m.root.createChild("group");  
    m.Left_pylons = m.pylons_Group.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(-m.maxladderspan+60,100)
      .setDouble("character-size", 35)
      .setFont("LiberationFonts/LiberationMono-Bold.ttf")
      .setAlignment("center-center")
      .setText("L");  
    m.Right_pylons = m.pylons_Group.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(m.maxladderspan-60,100)
      .setDouble("character-size", 35)
      .setFont("LiberationFonts/LiberationMono-Bold.ttf")
      .setAlignment("center-center")
      .setText("D");
    m.Center_pylons = m.pylons_Group.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(0,100)
      .setDouble("character-size", 35)
      .setFont("LiberationFonts/LiberationMono-Bold.ttf")
      .setAlignment("center-center")
      .setText("C");  
    m.pylons_Group.hide();
    
    # Pylon selection letters
    m.pylons_Circle_Group = m.root.createChild("group");  
    m.LeftCircle = m.pylons_Circle_Group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(-m.maxladderspan+60+25, 100)
      .arcSmallCW(25,25, 0, -50, 0)
      .arcSmallCW(25,25, 0, 50, 0)
      .setStrokeLineWidth(5);
    m.RightCircle = m.pylons_Circle_Group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(m.maxladderspan-60+25, 100)
      .arcSmallCW(25,25, 0, -50, 0)
      .arcSmallCW(25,25, 0, 50, 0)
      .setStrokeLineWidth(5);
    m.CenterCircle = m.pylons_Circle_Group.createChild("path")
      .setColor(m.myGreen)
      .moveTo(25, 100)
      .arcSmallCW(25,25, 0, -50, 0)
      .arcSmallCW(25,25, 0, 50, 0)
      .setStrokeLineWidth(5);
    m.pylons_Circle_Group.hide();
    
    
      
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
    m.gunPos  = nil;
    m.shellPosXInit = [0];
    m.shellPosYInit =  [0];
    m.shellPosDistInit = [0];
    m.wingspanFT = 35;# 7- to 40 meter
    m.resetGunPos();
    
    m.eegsRightX = m.makeVector(m.funnelParts,0);
    m.eegsRightY = m.makeVector(m.funnelParts,0);
    m.eegsLeftX  = m.makeVector(m.funnelParts,0);
    m.eegsLeftY  = m.makeVector(m.funnelParts,0);
    
    m.eegsMe = {ac: geo.Coord.new(), eegsPos: geo.Coord.new(),shellPosX: m.makeVector(m.funnelParts,0),shellPosY: m.makeVector(m.funnelParts,0),shellPosDist: m.makeVector(m.funnelParts,0)};
    
    m.lastTime = systime();
    m.eegsLoop = maketimer(m.averageDt, m, m.displayEEGS);
    m.eegsLoop.simulatedTime = 1;
    
    #m.gunTemp = [nil,nil];
    
#     for(i = 0;i < m.funnelParts;i+=1){
#       append(m.eegsRightX,0);
#       append(m.eegsRightY,0);
#       append(m.eegsLeftX,0);
#       append(m.eegsLeftY,0);

      #print ("i:"~i);
      #print("size:"~size(m.gunPos));
      #print("size[i]:"~size(m.gunPos[i]));
   
      #print("After append size:"~size(m.gunPos));
      #print("After append size[i]:"~size(m.gunPos[i]));
      #print("After append size[i+1]:"~size(m.gunPos[i+1]));
      #append(m.gunPos,append(m.gunPos[i],[nil]));
      
#       append(m.shellPosXInit,0);
#       append(m.shellPosYInit,0);
#       append(m.shellPosDistInit,0);
#     }
#     

    #print(size(m.eegsRightX));
    #print(size(m.gunPos[size(m.gunPos)-1]));
    
    #m.eegsRightX = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    #m.eegsRightY = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    #m.eegsLeftX = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    #m.eegsLeftY = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    #m.gunPos   = [[nil,nil],[nil,nil,nil],[nil,nil,nil,nil],[nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]];
#     m.eegsMe = {ac: geo.Coord.new(), eegsPos: geo.Coord.new(),
#         shellPosX:     m.shellPosXInit,
#         shellPosY:     m.shellPosYInit,
#         shellPosDist:  m.shellPosDistInit};

                     
    
    
    
    
   ################################### Runways #######################################   
   m.myRunwayGroup = m.root.createChild("group");
   m.selectedRunway = 0;
   
   #################################### CCIP #########################################

    m.CCIP = m.root.createChild("group");
    # Bomb Fall Line (BFL)
    m.CCIP_BFL = m.CCIP.createChild("group");
    
    m.CCIP_BFL_line = m.CCIP_BFL.createChild("path");
    
    #Bomb impact    
    m.CCIP_piper = m.CCIP.createChild("path")
        .setColor(m.myGreen)
        .moveTo(15, 0)
        .horiz(40)
        .moveTo(15, 0)
        .lineTo(7.5,13)
        .lineTo(-7.5,13)
        .lineTo(-15,0)
        .lineTo(-7.5,-13)
        .lineTo(7.5,-13)
        .lineTo(15,0)
        .moveTo(-15, 0)
        .horiz(-40)
        .setStrokeLineWidth(4);
    
    m.CCIP_safe_alt = m.CCIP.createChild("path")
        .setColor(m.myGreen)
        .moveTo(15, 0)
        .horiz(40)
        .vert(-15)

        .moveTo(-15, 0)
        .horiz(-40)
        .vert(-15)
        .setStrokeLineWidth(4);
        
     # Distance to impact
     m.CCIP_impact_dist = m.CCIP.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(m.maxladderspan,-120)
      .setDouble("character-size", 35)
      .setAlignment("left-center")
      .setText("0.0");
      
     m.CCIP_no_go_cross = m.CCIP.createChild("path")
        .setColor(m.myGreen)
        .moveTo(80, 80)
        .lineTo(-80,-80)
        .moveTo(-80, 80)
        .lineTo(80,-80)
        .setStrokeLineWidth(4);
        
     #################################### CCRP #########################################

    m.CCRP = m.root.createChild("group");
    
    m.CCRP_Piper_group = m.CCRP.createChild("group");   
    
    m.CCRP_piper = m.CCRP_Piper_group.createChild("path")
        .setColor(m.myGreen)
        .moveTo(24, 0)
        .lineTo(0,32)
        .lineTo(-24,0)
        .lineTo(0,-32)
        .lineTo(24,0)
        .moveTo(1,1)
        .lineTo(1,-1)
        .lineTo(-1,-1)
        .lineTo(-1,1)
        .moveTo(24, 0)
        .lineTo(44,0)
        .moveTo(-24, 0)
        .lineTo(-44,0)
        .setStrokeLineWidth(4);
        
    m.CCRP_Deviation = m.CCRP_Piper_group.createChild("path")
        .setColor(m.myGreen)
        .moveTo(34, 0)
        .lineTo(80,0)
        .moveTo(-34, 0)
        .lineTo(-80,0)
        .setStrokeLineWidth(4);
        
    #m.CCRP_Piper_group.setTranslation(0,-250);
    
        
    m.CCRP_release_cue = m.CCRP.createChild("path")
        .setColor(m.myGreen)
        .moveTo(55, 0)
        .horiz(-110)
        .setStrokeLineWidth(4);
        
        
     # Distance to target
     m.CCRP_impact_dist = m.CCRP.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(m.maxladderspan,-120)
      .setDouble("character-size", 35)
      .setAlignment("left-center")
      .setText("0.0");
      
     m.CCRP_no_go_cross = m.CCRP.createChild("path")
        .setColor(m.myGreen)
        .moveTo(80, 80)
        .lineTo(-80,-80)
        .moveTo(-80, 80)
        .lineTo(80,-80)
        .setStrokeLineWidth(4);
   
   
       
   ##################################### Target Circle ####################################
    m.targetArray = [];
    m.circle_group2 = m.radarStuffGroup.createChild("group");
    for(var i = 1; i <= m.MaxTarget; i += 1){
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
    
    for(var i = 1; i <= m.MaxTarget; i += 1){
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
      
    
    
    m.missileFireRange = m.root.createChild("group");
    m.MaxFireRange = m.missileFireRange.createChild("path")
      .setColor(m.myGreen)
      .moveTo(210,0)
      .horiz(-30)
      .setStrokeLineWidth(6); 
    m.MinFireRange = m.missileFireRange.createChild("path")
      .setColor(m.myGreen)
      .moveTo(210,0)
      .horiz(-30)
      .setStrokeLineWidth(6); 
    m.NEZFireRange = m.missileFireRange.createChild("path")
      .setColor(m.myGreen)
      .moveTo(215,0)
      .horiz(-40)
      .setStrokeLineWidth(4);   
    m.missileFireRange.hide();
      
    
    m.distanceToTargetLineGroup = m.root.createChild("group");
    m.distanceToTargetLineMin = -100;
    m.distanceToTargetLineMax = 100;
    m.distanceToTargetLine = m.distanceToTargetLineGroup.createChild("path")
      .setColor(m.myGreen)
      .moveTo(200,m.distanceToTargetLineMin)
      .horiz(30)
      .moveTo(200,m.distanceToTargetLineMin)
      .vert(m.distanceToTargetLineMax-m.distanceToTargetLineMin)
      .horiz(30)
      .setStrokeLineWidth(5); 
    
    m.distanceToTargetLineTextGroup = m.distanceToTargetLineGroup.createChild("group");
      
    m.distanceToTargetLineChevron = m.distanceToTargetLineTextGroup.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(200,0)
      .setDouble("character-size", 60)
      .setAlignment("left-center")
      .setText("<"); 
      
    m.distanceToTargetLineChevronText = m.distanceToTargetLineTextGroup.createChild("text")
      .setColor(m.myGreen)
      .setTranslation(230,0)
      .setDouble("character-size", 40)
      .setAlignment("left-center")
      .setText("x");
    
    m.distanceToTargetLineGroup.hide(); 

    
      
#       obj.ASC = obj.svg.createChild("path")# (Attack Steering Cue (ASC))
#       .moveTo(-8*mr,0)
#       .arcSmallCW(8*mr,8*mr, 0, 8*mr*2, 0)
#       .arcSmallCW(8*mr,8*mr, 0, -8*mr*2, 0)
#       .setStrokeLineWidth(1)
#       .setColor(0,1,0).hide();
#       append(obj.total, obj.ASC);  
      
   
    
    m.root.setColor(m.red,m.green,m.blue,1);
    
    m.loads_hash =  {
     "30mm Cannon":"CAN",
     "Magic-2": "MAG",
     "S530D":"530",
     "MICA-IR":"MIC-I",
     "MICA-EM":"MIC-E",
     "GBU-12": "GBU12",
     "SCALP": "SCALP",
     "APACHE": "APACHE",
     "AM39-Exocet":"AM39",
     "AS-37-Martel":"AS37",
     "AS-37-Armat":"AS37A",
     "AS30L" :"AS30",
     "Mk-82" : "Mk82",
     "Mk-82SE":"Mk82S",
     "GBU-24":"GBU24"
    };
    
    m.pylonsSide_hash = {
      0 : "L",
      1 : "L",
      2 : "L",
      7 : "L",
      3 : "C",
      4 : "R",
      5 : "R",
      6 : "R",
      8 : "R",
    };
    
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
      uBody_fps:  "velocities/uBody-fps",
      alpha:      "/orientation/alpha-deg",
      beta:       "/orientation/side-slip-deg",
      gload:      "/accelerations/pilot-g",
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
      afterburner: "/engines/engine[0]/afterburner",
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
      x_offset_m:    "/sim/current-view/x-offset-m",
      y_offset_m:    "/sim/current-view/y-offset-m",
      z_offset_m:    "/sim/current-view/z-offset-m",
      MasterArm      :"/controls/armament/master-arm",
      TimeToTarget   :"/sim/dialog/groundtTargeting/time-to-target",
      IsRadarWorking : "/systems/electrical/outputs/radar",
      gun_rate       : "/ai/submodels/submodel[1]/delay",
      bullseye_lat   : "/instrumentation/bullseye/bulls-eye-lat",
      bullseye_lon   : "instrumentation/bullseye/bulls-eye-lon",
      bullseye_def   : "instrumentation/bullseye/bulls-eye-defined",
      HUD_POWER_VOLT : "/systems/electrical/outputs/HUD"
    };
    
    foreach(var name; keys(m.input)){
      m.input[name] = props.globals.getNode(m.input[name], 1);
  }
    
    m.lastWP = m.input.currentWp.getValue();
    m.RunwayCoord =  geo.Coord.new();
    m.RunwaysCoordCornerLeft = geo.Coord.new();
    m.RunwaysCoordCornerRight = geo.Coord.new();
    m.RunwaysCoordEndCornerLeft = geo.Coord.new();
    m.RunwaysCoordEndCornerRight = geo.Coord.new();
    m.bullseyeGeo = geo.Coord.new();
    m.NXTWP = geo.Coord.new();
    
        
    return m;
  },
  update: func()
  {
    #if electrical < 23 volts then hud should hide
    
    if(me.input.HUD_POWER_VOLT.getValue()<23){
      me.root.setVisible(0);
    }else{
      me.root.setVisible(1);
    }
    
    me.aircraft_position = geo.aircraft_position();
    me.hydra = 0; #for rocket
    me.strf = me.input.gun_rate.getValue()==0.06?1:0; #Air to ground fire : based on the gun rate
    #me.airspeed.setText(sprintf("%d", me.input.ias.getValue()));
    #me.groundspeed.setText(sprintf("G %3d", me.input.gs.getValue()));
    #me.vertical_speed.setText(sprintf("%.1f", me.input.vs.getValue() * 60.0 / 1000));
    HudMath.reCalc();
    
    #loading Flightplan
    me.fp = flightplan();
    
    #Choose the heading to display
    me.getHeadingToDisplay();
    
    #-----------------Test of paralax
    me.Vy   =    me.input.x_offset_m.getValue();
    me.pixelPerMeterX = HudMath.pixelPerMeterX;#(340*0.695633)/0.15848;
    #me.pixelPerMeterY = 260/(me.Hz_t-me.Hz_b);
    me.pixelside = me.pixelPerMeterX*me.Vy;
    #me.svg.setTranslation(me.pixelside, 0);
    #me.custom.setTranslation(me.pixelside, 0);
    me.root.setTranslation(HudMath.getCenterOrigin()[0]+me.pixelside, HudMath.getCenterOrigin()[1]);
    #me.custom.update();
    me.root.update();
    #me.svg.update();
    
 

    
    #Think this code sucks. If everyone have better, please, proceed :)
    #Weapons management should be in a function.
    #Taking radar should be done once for all
    #missile management aren't made : it should be
    
    me.eegsShow=0;
    me.selectedWeap = pylons.fcs.getSelectedWeapon();
    
    
    me.Fire_GBU.setText("Fire");
    me.showFire_GBU = 0;
    me.show_CCIP = 0;
    me.show_CCRP = 0;
    me.CCRP_Piper_group_visibilty = 1;
    me.CCRP_cue_visbility = 0;
    me.CCRP_no_go_cross_visibility = 0;
    
    if(me.selectedWeap != nil and me.input.MasterArm.getValue()){
      if(me.selectedWeap.type != "30mm Cannon"){
        #Doing the math only for bombs
        if(me.selectedWeap.stage_1_duration+me.selectedWeap.stage_2_duration == 0){
          if(mirage2000.myRadar3.tgts_list != nil and size(mirage2000.myRadar3.tgts_list) > 0){
            #if target selected : CCRP
            #print("Should CCRP : size target list" ~ size(mirage2000.myRadar3.tgts_list));
            me.show_CCRP = me.display_CCRP_mode();
          }else{
            #Else CCIP
            #print("Should CCIP");
            me.show_CCIP = me.display_CCIP_mode();
            #print("Distance to shoot : nil");
          }
        }
      }else{
        #Else showing the gun
        me.eegsShow=me.input.MasterArm.getValue();
      }
    }
    
    #CCRP visibility : 
    #piper when we have a target
    #Cue line when time to target < 15
    #Cross when speed <350
    #target and house (to be defined)
    me.CCRP.setVisible(me.show_CCRP);
    me.CCRP_Piper_group.setVisible(me.CCRP_Piper_group_visibilty);
    me.CCRP_release_cue.setVisible( me.CCRP_cue_visbility);
    me.CCRP_no_go_cross.setVisible(me.CCRP_no_go_cross_visibility);
    
    me.Fire_GBU.setVisible(me.showFire_GBU);
    
    #CCIP Visibility
    me.CCIP.setVisible(me.show_CCIP);
  

    #me.hdg.setText(sprintf("%03d", me.input.hdg.getValue()));
    me.horizStuff = HudMath.getStaticHorizon();
    me.horizon_group.setTranslation(me.horizStuff[0]);
    me.h_rot.setRotation(me.horizStuff[1]);
    me.horizon_sub_group.setTranslation(me.horizStuff[2]);
    
#     var rot = -me.input.roll.getValue() * math.pi / 180.0;
    #me.Textrot.setRotation(rot);

    #Displaying ILS STUFF (but only show after LOCALIZER capture)
    me.display_ILS_STUFF();
    
    #ILS not dependent of the Scale (but only show after GS capture)
    me.display_ILS_Square();
    #me.RunwayOnTheHorizonLine.hide();
    
    
    # Bore Cross. In navigation, the cross should only appear on NextWaypoint gps cooord, when dist to this waypoint is bellow 10 nm
    #me.NXTWP = geo.Coord.new();
    
    #Calculate the GPS coord of the next WP
    me.NextWaypointCoordinate();
      
    if(me.input.bullseye_def.getValue()){
      if(me.input.bullseye_lat.getValue() != nil and me.input.bullseye_lon.getValue() != nil){
        me.bullseyeGeo.set_latlon(me.input.bullseye_lat.getValue(),me.input.bullseye_lon.getValue());
      }
    }
    
    
    
    #Display the Next WP ##################################################
    #Should be displayed for : 
    #1-Next waypoint
    #2-bulleseye
    #3-ground target
    me.displayWaypointCrossShow = 0;
    me.display_houseShow = 0;
    me.waypointGroupshow = 0;
    me.waypointSimpleGroupShow = 0;
    
    
    
    if(me.input.gearPos.getValue() == 0){# if masterArm is not selected
      #if there is a route selected and Bulleye isn't selected
      if( me.NXTWP.is_defined() and !me.input.MasterArm.getValue()){#if waypoint is active
        me.displayWaypointCross(me.NXTWP);  # displaying the ground cross
        me.display_house(me.NXTWP);         # displaying the little house
        me.display_Waypoint(me.NXTWP,"DEST",me.input.NextWayNum.getValue());
      }
      
      if(me.input.bullseye_def.getValue()){
        me.displayWaypointCross(me.bullseyeGeo);  # displaying the ground cross
        me.display_house(me.bullseyeGeo);         # displaying the little house
        me.display_Waypoint(me.bullseyeGeo,"BE ",nil);
      }
    }
    
    
    
    
    
    
    me.WaypointCross.setVisible(me.displayWaypointCrossShow);
    me.HeadingHouse.setVisible(me.display_houseShow);
    me.waypointGroup.setVisible(me.waypointGroupshow);
    me.waypointSimpleGroup.setVisible(0);
     
###################################################
    
    
    
    #Gun Cross (bore)
    me.displayBoreCross();
    

    
    # flight path vector (FPV)
    me.display_Fpv();
    

    
    #chevronGroup
    me.display_Chevron();

    #Don't know what that does ...
#     var speed_error = 0;
#     if( me.input.target_spd.getValue() != nil )
#       speed_error = 4 * clamp(
#         me.input.target_spd.getValue() - me.input.airspeed.getValue(),
#         -15, 15
#       );
      
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
    
    #Display gload
    me.display_gload();
    
    #Diplay Load type
    me.display_loadsType();
    
    #Display bullet Count
    me.display_BulletCount();
    
    #Display selected
    me.displaySelectedPylons();
    
    #Display Route dist and waypoint number
    #me.display_Waypoint();
    
    #me.hdg.hide();
    #me.groundspeed.hide();  
    #me.rad_alt.hide();
    #me.airspeed.hide();
    #me.energy_cue.hide();
    #me.acc.hide();
    #me.vertical_speed.hide();
    
    #Displaying the circles, the squares or even the triangles (triangles will be for a IR lock without radar)
    me.displayTarget();
    me.displayHeattarget();
    
   
    
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
    me.info = airportinfo();
    foreach(var rwy; keys(me.info.runways)){
        if(sprintf("%.2f",me.info.runways[rwy].ils_frequency_mhz) == sprintf("%.2f",me.input.NavFreq.getValue())){
          me.selectedRunway = rwy;
        }  
    }
    #Then, trying with route manager
    if(me.selectedRunway == "0" and !me.input.MasterArm.getValue()){
      if(me.input.destRunway.getValue() != ""){
         
        if(me.fp.getPlanSize() == me.fp.indexOfWP(me.fp.currentWP())+1){
          
          me.info = airportinfo(me.input.destAirport.getValue());
          me.selectedRunway = me.input.destRunway.getValue() ;
        }
      }
    }
    #print("Test : ",me.selectedRunway != "0");
    if(me.selectedRunway != "0" and !me.input.MasterArm.getValue()){
      var (courseToAiport, distToAirport) = courseAndDistance(me.info);
      if(  distToAirport < 10 and me.input.wow_nlg.getValue() == 0){
        me.displayRunway();
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
    me.lastWP = me.input.currentWp.getValue();
    #------------------------End of the Update------------------------------------------------------------------------
  },
  display_ILS_STUFF:func(){
    if(me.input.ILS_valid.getValue() and !me.input.MasterArm.getValue()){
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
  display_CCIP_mode:func(){
    #CCIP : for bomb dropping. 
    #Source : DCS manual / tutorials
    me.ccipPos = me.selectedWeap.getCCIPadv(me.input.TimeToTarget.getValue(), 0.20);
    if(me.ccipPos != nil){
      me.hud_pos = HudMath.getPosFromCoord(me.ccipPos[0]);
      if(me.hud_pos != nil) {
          me.pos_x = me.hud_pos[0];
          me.pos_y = me.hud_pos[1];
          me.CCIP_piper.setTranslation(me.pos_x,me.pos_y);
          
          #Updating : clear all previous stuff
          me.CCIP_BFL.removeAllChildren();
          
          #Drawing the line
          me.CCIP_BFL_line = me.CCIP_BFL.createChild("path")
            .setColor(me.myGreen)
            .moveTo(me.fpvCalc)
            .lineTo(me.pos_x,me.pos_y)
            .setStrokeLineWidth(4);
            
          #Calculate safe alt :
          #me.selectedWeap.reportDist*2) is an arbitrary choice
          me.safe_alt = int(me.ccipPos[0].alt()+me.selectedWeap.reportDist*2);
          #print("me.safe_alt:" ~me.safe_alt);
          #print("diff elevation vs target_alt:" ~ int(me.input.alt.getValue()*FT2M));
          #print("%off line : " ~ me.safe_alt/(me.input.alt.getValue()*FT2M));
          me.safe_alt_pourcent = me.safe_alt/(me.input.alt.getValue()); 
          me.CCIP_safe_alt.setTranslation(me.fpvCalc[0],me.fpvCalc[1]-(me.fpvCalc[1]-me.pos_y)*(1-clamp(me.safe_alt_pourcent,0,1)));
          
          #Distance to ground impact : only working if radar is on
          if(me.input.IsRadarWorking.getValue()>24){
            me.CCIP_impact_dist.setText(sprintf("%.1f KM", me.ccipPos[0].direct_distance_to(geo.aircraft_position())/1000));
          }else{
            me.CCIP_impact_dist.setText(sprintf("%.1f KM", 0));
          }
          
          #No go : too dangerous to drop the bomb
          me.CCIP_no_go_cross.setVisible(me.safe_alt_pourcent>0.85);
            
          return 1;
      }
    }
    return 0;
  },
  
  display_CCRP_mode:func(){
    #print("Class of Load:" ~ me.selectedWeap.class);     
    me.DistanceToShoot = nil;
    me.DistanceToShoot = me.selectedWeap.getCCRP(me.input.TimeToTarget.getValue(), 0.05);

    if(me.DistanceToShoot != nil ){
      # This should be the CCRP function
      # The no go CCRP is when speed < 350 kts.
      # We need the house and the nav point display to display the target.
      # the CCRP piper is a fixed pointand replace the FPV

      # CCRP steering cues:
      # They appear only after a target point has been selected. They are centered on the
      # CCRP piper and rotate to show deviation from the course to target. The aircraft is
      # flying directly to the target when they are level.

      #if(me.DistanceToShoot/ (me.input.gs.getValue() * KT2MPS) < 30){
        #me.showFire_GBU = 1;
        #me.Fire_GBU.setText(sprintf("TTR: %d ", int(me.DistanceToShoot/ (me.input.gs.getValue() * KT2MPS))));
        if(me.DistanceToShoot/ (me.input.gs.getValue() * KT2MPS) < 15){
          #me.Fire_GBU.setText(sprintf("Fire : %d ", int(me.DistanceToShoot/ (me.input.gs.getValue() * KT2MPS))));
          me.BorePos =  HudMath.getBorePos();
          me.hud_pos = HudMath.getPosFromCoord(me.selectedWeap.Tgt.get_Coord());
          if(me.hud_pos != nil) {
            #print('CCRP_release_cue should move');
            me.pos_x = me.hud_pos[0];
            me.pos_y = me.hud_pos[1];          
            me.CCRP_release_percent = (me.DistanceToShoot/ (me.input.gs.getValue() * KT2MPS))/30; 
            me.CCRP_release_cue.setTranslation(me.BorePos[0],me.BorePos[1]-(me.BorePos[1]-me.pos_y)*(clamp(me.CCRP_release_percent,0,1)));
            me.CCRP_cue_visbility = 1;
          }
            
        }
      #}
      printf("me.DistanceToShoot: %.2f ; Time to shoot : %.2f",me.DistanceToShoot,me.DistanceToShoot/ (me.input.gs.getValue() * KT2MPS));
      print("Deviation:"~me.selectedWeap.Tgt.get_deviation(me.input.hdgReal.getValue(), geo.aircraft_position()));
    }
    
    # The no go CCRP is when speed < 350 kts.
    if(me.input.airspeed.getValue()<350){
      me.CCRP_no_go_cross_visibility = 1;
    }      
    
    #There is a target so the piper and the deviation should get displayed.
    me.CCRP_Piper_group.setTranslation(HudMath.getBorePos());
    if(me.selectedWeap.Tgt != nil){
      # * 10 to see if that can improves precisions
      me.CCRP_Deviation.setRotation(me.selectedWeap.Tgt.get_deviation(me.input.hdgReal.getValue(), geo.aircraft_position())*D2R*2);
    }
    return 1;
  },
      
  display_ILS_Square:func(){
    if(me.input.ILS_gs_in_range.getValue()and !me.input.MasterArm.getValue()){
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
    #we only need those digit : this tricks avoid too much drawing
      me.headOffset = me.heading/10 - int (me.heading/10);
      me.headScaleOffset = me.headOffset;
      me.middleText = roundabout(me.heading/10);
      me.middleText = me.middleText == 36?0:me.middleText;
      me.leftText = me.middleText == 0?35:me.middleText-1;
      me.rightText = me.middleText == 35?0:me.middleText+1;
      me.rightRightText = me.rightText == 35?0:me.rightText+1;
      
      if (me.headOffset > 0.5) {
        me.middleOffset = -(me.headScaleOffset-1)*me.headScaleTickSpacing*2;
      } else {
        me.middleOffset = -me.headScaleOffset*me.headScaleTickSpacing*2;
      }
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
  
  #This should be called with a geo.coord object.
  #Doing that way it could be used for waypoint, bullseye and ground target
  display_house:func(coord){
    if(coord != nil){
      if(!me.isInCanvas(HudMath.getPosFromCoord(coord)[0],HudMath.getPosFromCoord(coord)[1]) or me.aircraft_position.direct_distance_to(coord)*M2NM >=10 ){
        #Depend of which heading we want to display
          if(me.input.hdgDisplay.getValue()){
            me.houseTranslation = -(geo.normdeg180(me.heading - me.aircraft_position.course_to(coord)))*me.headScaleTickSpacing/5;
          }else{
            me.houseTranslation = -(geo.normdeg180(me.heading - me.aircraft_position.course_to(coord)))*me.headScaleTickSpacing/5;
          }
 
        me.HeadingHouse.setTranslation(clamp(me.houseTranslation,-me.maxladderspan,me.maxladderspan),me.fpvCalc[1]);
        if(abs(me.houseTranslation/(me.headScaleTickSpacing/5))>90){
          me.HeadingHouse.setRotation(me.horizStuff[1]+(180* D2R));
        }else{
          me.HeadingHouse.setRotation(me.horizStuff[1]);
        }
        me.display_houseShow = 1;
        return;
      }
    }
    #me.HeadingHouse.hide();
  },
  
  display_Chevron : func(){
    if(me.input.afterburner.getValue()){me.chevronGroupAB.show();}else{me.chevronGroupAB.hide();}
    me.chevronGroup.setTranslation(me.fpvCalc[0],me.fpvCalc[1]-me.input.acc.getValue()*FT2M*me.chevronFactor);
    
    me.chevronGroup.update();
  },
  
  display_heading_bug : func(){
      headOffset = -(geo.normdeg180(me.heading - me.input.hdgBug.getValue() ))*me.headScaleTickSpacing/5;
      me.head_scale_route_pointer.setTranslation(headOffset,0);
      me.headingScaleGroup.update();
  },
  
  display_Acceleration_Box:func(){
    #Acc accBoxGroup in G(so I guess /9,8)
    if(me.input.wow_nlg.getValue()){
      me.acceleration_Box.setText(sprintf("%.2f", int(me.input.acc.getValue()*FT2M/9.8*1000+1)/1000));
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
    if(me.input.gearPos.getValue() < 1 and abs(me.input.alpha.getValue())>2 and me.input.MasterArm.getValue() == 0){
      me.aoa.setText(sprintf("%0.1f",me.input.alpha.getValue()));
      me.alphaGroup.show();
    }else{
      me.alphaGroup.hide();
    }
  },
  
  display_gload:func(){
    if(me.input.MasterArm.getValue()){
      me.gload_Text.setText(sprintf("%0.1fG",me.input.gload.getValue()));
      me.alpha_Text.setText(sprintf("%0.1fα",me.input.alpha.getValue()));
      me.alphaGloadGroup.show();
    }else{
      me.alphaGloadGroup.hide();
    }
  },
  
  display_loadsType:func{
    if(me.input.MasterArm.getValue() and me.selectedWeap != nil){
#       print(me.loads_hash[me.selectedWeap.type]);
      me.loads_Type_text.setText(me.loads_hash[me.selectedWeap.type]);
      me.loads_Type_text.show();
    }else{
      me.loads_Type_text.hide();
    }
  },
  
  display_BulletCount:func{
    if(me.input.MasterArm.getValue() and me.selectedWeap != nil){
#       print("Test");
#       print("Test:" ~ me.loads_hash[me.selectedWeap.type] ~ " : " ~ pylons.fcs.getAmmo());
#       print("Test:" ~ me.selectedWeap.type ~ " : " ~ pylons.fcs.getAmmo());
      if(me.selectedWeap.type == "30mm Cannon"){
#         print(me.loads_hash[me.selectedWeap.type] ~ " : " ~ pylons.fcs.getAmmo());
        me.Left_bullet_Count.setText(sprintf("%3d", pylons.fcs.getAmmo()/2));
        me.Right_bullet_Count.setText(sprintf("%3d", pylons.fcs.getAmmo()/2));
        me.bullet_CountGroup.show();
      }else{
        me.bullet_CountGroup.hide();
      }
    }else{
      me.bullet_CountGroup.hide();
    }
    
  },
  
  displaySelectedPylons:func{
    #Init the vector
    me.pylonRemainAmmo_hash = {
      "L":0,
      "C":0,
      "R":0,
    };
    
    #Showing the circle around the L or R if the weapons is under the wings.
    #A circle around a C is also done for center loads, but I couldn't find any docs on that, so it is conjecture
    if(me.input.MasterArm.getValue() and me.selectedWeap != nil){
      if(me.selectedWeap.type != "30mm Cannon"){
        me.pylons_Group.show();
        me.pylons_Circle_Group.show();
#          print("Type:"~me.loads_hash[me.selectedWeap.type]);
#          print("Pylons:"~pylons.fcs.getSelectedPylonNumber());
#          print("Side:"~me.pylonsSide_hash[pylons.fcs.getSelectedPylonNumber()]);
         #create the remainingAmmo vector and starting to count L and R
         me.RemainingAmmoVector = pylons.fcs.getAllAmmo(pylons.fcs.getSelectedType());
         for(i = 0 ; i < size(me.RemainingAmmoVector)-1 ; i += 1){
#               print("NumPylons="~ i ~ " :"~me.RemainingAmmoVector[i]);
              me.pylonRemainAmmo_hash[me.pylonsSide_hash[i]] += me.RemainingAmmoVector[i];
         }
#          print("Number Left Side :"~me.pylonRemainAmmo_hash["L"]);
#          print("Number Right Side :"~me.pylonRemainAmmo_hash["R"]);
        #Showing the pylon
        if(me.pylonRemainAmmo_hash["L"]>0){me.Left_pylons.show();}else{me.Left_pylons.hide();}
        if(me.pylonRemainAmmo_hash["C"]>0){me.Center_pylons.show();}else{me.Center_pylons.hide();}
        if(me.pylonRemainAmmo_hash["R"]>0){me.Right_pylons.show();}else{me.Right_pylons.hide();}
        
        #Showing the Circle for the selected pylon
        if(me.pylonsSide_hash[pylons.fcs.getSelectedPylonNumber()] == "L"){me.LeftCircle.show();}else{me.LeftCircle.hide();}
        if(me.pylonsSide_hash[pylons.fcs.getSelectedPylonNumber()] == "C"){me.CenterCircle.show();}else{me.CenterCircle.hide();}
        if(me.pylonsSide_hash[pylons.fcs.getSelectedPylonNumber()] == "R"){me.RightCircle.show();}else{me.RightCircle.hide();}
        
      }else{
        me.pylons_Group.hide();
        me.pylons_Circle_Group.hide();
      } 
    }else{
      me.pylons_Group.hide();
      me.pylons_Circle_Group.hide();
    }
  },
  
  
  display_Waypoint:func(coord,TEXT,NextNUM){
    #coord is a geo object of the current destination
    #TEXT is what will be written to describe our target : BE (Bullseye) ou DEST (route)
    #NextNUM is the next waypoint/bullseye number (most of the time it's the waypoint number)
    
    if(coord != nil){
      if(me.aircraft_position.direct_distance_to(coord)*M2NM>10){
        me.waypointDist.setText(sprintf("%d N",int(me.aircraft_position.direct_distance_to(coord)*M2NM)));
        me.waypointDistSimple.setText(sprintf("%d N",int(me.aircraft_position.direct_distance_to(coord)*M2NM)));
      }else{
        me.waypointDist.setText(sprintf("%0.1f N",me.aircraft_position.direct_distance_to(coord)*M2NM));
        me.waypointDistSimple.setText(sprintf("%0.1f N",me.aircraft_position.direct_distance_to(coord)*M2NM));
      }
      
      
      if(NextNUM != nil){
        me.waypointNumber.setText(sprintf("%02d",NextNUM));
        me.waypointNumberSimple.setText(sprintf("%02d",NextNUM));
      }
      me.DEST.setText(TEXT);
      
      if(me.input.hdgDisplay.getValue()){
        me.waypointHeading.setText(sprintf("%03d/",me.aircraft_position.course_to(coord)));
      }else{
        me.waypointHeading.setText(sprintf("%03d/",me.aircraft_position.course_to(coord)));
      }
      me.waypointGroupshow = 1;
    }
  },
  
  displayHeattarget:func(){
    if(me.selectedWeap == nil or !me.input.MasterArm.getValue()){me.TriangleGroupe.hide();return;}
    if(me.selectedWeap.type == "30mm Cannon"){me.TriangleGroupe.hide();return;}
    if(me.selectedWeap.guidance != "heat"){me.TriangleGroupe.hide();return;}
    
    #Starting to search (Shouldn't be there but in the controls)
    me.selectedWeap.start();
    #me.selectedWeap.contacts = radar.completeList;#This shoiuldn't be here.
    #screen.log.write("starting IR sweep", 1.0, 1.0, 0.0);
    #veryTempo = me.selectedWeap.getSeekerInfo();
    #print("veryTempo.seeker_head:"~veryTempo.seeker_head);
    #screen.log.write("getSeekerInfo:"~me.selectedWeap.getSeekerInfo[0],1.0, 1.0, 0.0);
    #if (me.selectedWeap != nil and me.selectedWeap.isCaged()) {
    if (me.selectedWeap != nil) {
      var coords = me.selectedWeap.getSeekerInfo();
      if (coords != nil) {
         var seekerTripos = HudMath.getCenterPosFromDegs(coords[0],coords[1]);
#         if(seekerTripos == triPos)
          #print("Perlinpipin. Status :"~me.selectedWeap.status~ "; missile contacts size : "~ size(me.selectedWeap.contacts));
            me.TriangleGroupe.show();
            me.triangle.setTranslation(seekerTripos);
            me.triangle2.setTranslation(seekerTripos);
      } else {me.TriangleGroupe.hide();}      
    }else{me.TriangleGroupe.hide();}
    
#     if(me.selectedWeap.status == armament.MISSILE_LOCK){
      
        #show triangle if IR missile have a lock (but don't show if it's a radar lock)
        #screen.log.write("me.selectedWeap.class:"~ me.selectedWeap.class, 1.0, 1.0, 0.0);
        #screen.log.write("me.selectedWeap.guidance:"~ me.selectedWeap.guidance, 1.0, 1.0, 0.0);
      

#         
#         if(me.selectedWeap.Tgt == nil){return 0;}
#         
#         if(c.get_Callsign() != me.selectedWeap.Tgt.get_Callsign()){return 0;}
#         screen.log.write("me.selectedWeap.Tgt.get_Callsign():"~ me.selectedWeap.Tgt.get_Callsign(), 1.0, 1.0, 0.0);
#         return 1;
        #Should now display the triangle group
        
        #             me.TriangleGroupe.show();
        #             me.triangle.setTranslation(triPos);
        #             me.triangle2.setTranslation(triPos);
  },
  
  displayRectangletarget:func(c,i){
    #if(me.selectedWeap == nil or !me.input.MasterArm.getValue()){return 0;}
    #if(me.selectedWeap.type == "30mm Cannon"){return 0;}
    #if(me.selectedWeap.guidance == "heat" and me.selectedWeap.status == armament.MISSILE_LOCK){
      if(i<size(me.targetArray) and size(me.raw_list)>0 and c.objectDisplay ==1 ){
         if(c.get_Callsign() == me.closestCallsign and me.closestRange > 0){
           #screen.log.write("me.selectedWeap.Tgt.get_Callsign():"~ me.selectedWeap.Tgt.get_Callsign(), 1.0, 1.0, 0.0);
           return 1;
         }
      }
      return 0;
  },
  
  
  displayTarget:func(){
    #To put a triangle on the selected target
    #This should be changed by calling directly the radar object (in case of multi targeting)


    #Getting the radar target from radar tgts_list
    if(mirage2000.myRadar3.tgts_list != nil and size(mirage2000.myRadar3.tgts_list)>mirage2000.myRadar3.Target_Index){
      me.MytargetIndex = mirage2000.myRadar3.Target_Index;
      me.closestCallsign = me.MytargetIndex != -1 ? mirage2000.myRadar3.tgts_list[me.MytargetIndex].get_Callsign():"";
      me.is_Painted = me.MytargetIndex != -1 ? mirage2000.myRadar3.tgts_list[me.MytargetIndex].isPainted():0;
      me.closestRange = me.MytargetIndex != -1 ? mirage2000.myRadar3.targetRange(mirage2000.myRadar3.tgts_list[me.MytargetIndex]):0;
    }else{
      me.closestCallsign = "";
      me.closestRange = -1;
    }
    me.showdistanceToken = 0;
    

    me.raw_list = mirage2000.myRadar3.ContactsList; 
    i = 0;
    
    me.designatedDistanceFT = nil;
    
    foreach(var c; me.raw_list){
      #This is too complicated :
      #I need to change  the way those things are displayed:
      #list what should be displayed and make a fonction if it needs to be displayed
      #me.ShouldDisplayheat = me.displayHeattarget(c);
      
      me.target_callsign = c.get_Callsign();
      #print("Paint : " ~ me.target_callsign ~ " : "~ myTest);
      
      #Position of the "target"
      target_altitude = c.get_altitude();
      target_heading_deg = c.get_heading();  
      target_Distance = c.get_range_from_Coord(me.aircraft_position);  
      var triPos = HudMath.getPosFromCoord(c.get_Coord());
      #1- Show Rectangle : habe been painted (or selected ?)
      #2- Show double triangle : IR missile LOCK without radar
      #3- Show circle : the radar see it, without focusing
      #4- Do not show anything : nothing see it
      
      #Should this be displayed by a radar
      #displayIt = c.objectDisplay;
      
      #1 Rectangle :  
      if(me.displayRectangletarget(c,i)){
    
          #Here for displaying the square (painting)
            me.showdistanceToken = 1;
            #Show square group            
            me.Square_Group.show();
            me.Locked_Square.setTranslation(triPos);
            me.Locked_Square_Dash.setTranslation(clamp(triPos[0],-me.MaxX*0.8,me.MaxX*0.8), clamp(triPos[1],-me.MaxY*0.8,me.MaxY*0.8));
            #hide triangle and circle
            #me.TriangleGroupe.hide();
            me.targetArray[i].hide();
            
            me.distanceToTargetLineGroup.show(); 
            me.displayDistanceToTargetLine(c);
            
            if (math.abs(triPos[0])<2000 and math.abs(triPos[1])<2000) {#only show it when target is in front
             me.designatedDistanceFT = c.get_Coord().direct_distance_to(geo.aircraft_position())*M2FT;
            }        
#       }elsif(me.displayHeattarget(triPos)) {
#             me.showdistanceToken = 1;
#             me.TriangleGroupe.show();
# #             me.triangle.setTranslation(triPos);
# #             me.triangle2.setTranslation(triPos);
#             
#             #hide rectangle and circle
#             me.Square_Group.hide();
#             me.targetArray[i].hide();         
#             if (math.abs(triPos[0])<2000 and math.abs(triPos[1])<2000) {#only show it when target is in front
#               me.designatedDistanceFT = c.get_Coord().direct_distance_to(geo.aircraft_position())*M2FT;
#             }
      }elsif(c.objectDisplay == 1){
        #show circle
          me.targetArray[i].show();
          me.targetArray[i].setTranslation(triPos);

      }else{
        #dont show anything
        me.targetArray[i].hide();
      }
        
        
      #here is the text display : Normally not in the real HUD
      if(c.objectDisplay == 1){
        #here is the text display
        me.TextInfoArray[i].show();
        me.TextInfoArray[i].setTranslation(triPos[0]+19,triPos[1]);

        me.TextInfoArray[i].setText(sprintf("  %s \n   %.0f nm \n   %d ft / %d", me.target_callsign, target_Distance, target_altitude, target_heading_deg));
      }else{
        me.targetArray[i].hide();
        me.TextInfoArray[i].hide();
      }
      i+=1;
    }

    #The token has 1 when we have a selected target
    #if we don't have target : 
      if(me.showdistanceToken == 0){
#         me.TriangleGroupe.hide();
        me.Square_Group.hide();
        me.distanceToTargetLineGroup.hide(); 
        me.missileFireRange.hide();
      }
  
    for(var y=i;y<size(me.targetArray);y+=1){
      me.targetArray[y].hide();
      me.TextInfoArray[y].hide();
    } 
  },
  
  displayDistanceToTargetLine : func(contact){
    me.MaxRadarRange = mirage2000.myRadar3.rangeTab[mirage2000.myRadar3.rangeIndex];
    var myString ="";
    #< 10 nm should be a float
    #< 1000 m should be in meters 
    if(contact.get_range_from_Coord(me.aircraft_position)<= me.MaxRadarRange){
      #Text for distance to target
      if(contact.get_range_from_Coord(me.aircraft_position)*NM2M<1200){
        myString = sprintf("%dm",contact.get_range_from_Coord(me.aircraft_position)*NM2M);
      }elsif(contact.get_range_from_Coord(me.aircraft_position)<10){
        myString = sprintf("%.1fnm",contact.get_range_from_Coord(me.aircraft_position));
      }else{
        myString = sprintf("%dnm",contact.get_range_from_Coord(me.aircraft_position));
      }

      if (me.displayDLZ(me.MaxRadarRange)){
        me.missileFireRange.show();
      }else{
        me.missileFireRange.hide();
      }   
      me.distanceToTargetLineChevronText.setText(myString);
      me.distanceToTargetLineTextGroup.setTranslation(0,(me.distanceToTargetLineMax-me.distanceToTargetLineMin)-(contact.get_range_from_Coord(me.aircraft_position)*(me.distanceToTargetLineMax-me.distanceToTargetLineMin)/ me.MaxRadarRange)-100); 
    }
  },
  
  displayDLZ:func(){
    if(me.selectedWeap != nil and me.input.MasterArm.getValue()){
        
        #Testings
        if(me.selectedWeap.type != "30mm Cannon"){ 
            if(me.selectedWeap.class == "A" and me.selectedWeap.parents[0] == armament.AIM){
            #Taking back the DLZ
            
            me.myDLZ = pylons.getDLZ();

            if(me.myDLZ != nil and size(me.myDLZ) == 5 and me.myDLZ[4]<me.myDLZ[0]*2){
              #Max
              me.MaxFireRange.setTranslation(0,clamp((me.distanceToTargetLineMax-me.distanceToTargetLineMin)-(me.myDLZ[0]*(me.distanceToTargetLineMax-me.distanceToTargetLineMin)/ me.MaxRadarRange)-100,me.distanceToTargetLineMin,me.distanceToTargetLineMax));

              #MmiFireRange
              me.MinFireRange.setTranslation(0,clamp((me.distanceToTargetLineMax-me.distanceToTargetLineMin)-(me.myDLZ[3]*(me.distanceToTargetLineMax-me.distanceToTargetLineMin)/ me.MaxRadarRange)-100,me.distanceToTargetLineMin,me.distanceToTargetLineMax));

              #NEZFireRange           
              me.NEZFireRange.setTranslation(0,clamp((me.distanceToTargetLineMax-me.distanceToTargetLineMin)-(me.myDLZ[2]*(me.distanceToTargetLineMax-me.distanceToTargetLineMin)/ me.MaxRadarRange)-100,me.distanceToTargetLineMin,me.distanceToTargetLineMax));

              me.missileFireRange.show();
              return 1;
            }
          }elsif(me.selectedWeap.class == "GM" or me.selectedWeap.class == "M"){
              me.MaxFireRange.setTranslation(0,clamp((me.distanceToTargetLineMax-me.distanceToTargetLineMin)-(me.selectedWeap.max_fire_range_nm*(me.distanceToTargetLineMax-me.distanceToTargetLineMin)/ me.MaxRadarRange)-100,me.distanceToTargetLineMin,me.distanceToTargetLineMax));
              
              #MmiFireRange
              me.MinFireRange.setTranslation(0,clamp((me.distanceToTargetLineMax-me.distanceToTargetLineMin)-(me.selectedWeap.min_fire_range_nm*(me.distanceToTargetLineMax-me.distanceToTargetLineMin)/ me.MaxRadarRange)-100,me.distanceToTargetLineMin,me.distanceToTargetLineMax));
              
              me.NEZFireRange.hide();
              me.MaxFireRange.show();
              me.MinFireRange.show();
              
              return 1;   
          }
        } 
      }
      return 0;
  },
  
  
  displayRunway:func(){

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
    #No need to recalculate GPS position everytime, only when the destination airport is changed
    if(me.RunwayCoord.lat != me.info.runways[me.selectedRunway].lat or me.RunwayCoord.lpn != me.info.runways[me.selectedRunway].lon){
      me.RunwayCoord.set_latlon(me.info.runways[me.selectedRunway].lat, me.info.runways[me.selectedRunway].lon, me.info.elevation);
      
      me.RunwaysCoordCornerLeft.set_latlon(me.info.runways[me.selectedRunway].lat, me.info.runways[me.selectedRunway].lon, me.info.elevation);
      me.RunwaysCoordCornerLeft.apply_course_distance((me.info.runways[me.selectedRunway].heading)-90,(me.info.runways[me.selectedRunway].width)/2);
      
      me.RunwaysCoordCornerRight.set_latlon(me.info.runways[me.selectedRunway].lat, me.info.runways[me.selectedRunway].lon, me.info.elevation);
      me.RunwaysCoordCornerRight.apply_course_distance((me.info.runways[me.selectedRunway].heading)+90,(me.info.runways[me.selectedRunway].width)/2);
      
      me.RunwaysCoordEndCornerLeft.set_latlon(me.info.runways[me.selectedRunway].lat, me.info.runways[me.selectedRunway].lon, me.info.elevation);
      me.RunwaysCoordEndCornerLeft.apply_course_distance((me.info.runways[me.selectedRunway].heading)-90,(me.info.runways[me.selectedRunway].width)/2);
      me.RunwaysCoordEndCornerLeft.apply_course_distance((me.info.runways[me.selectedRunway].heading),me.info.runways[me.selectedRunway].length);
      
      me.RunwaysCoordEndCornerRight.set_latlon(me.info.runways[me.selectedRunway].lat, me.info.runways[me.selectedRunway].lon, me.info.elevation);
      me.RunwaysCoordEndCornerRight.apply_course_distance((me.info.runways[me.selectedRunway].heading)+90,(me.info.runways[me.selectedRunway].width)/2);
      me.RunwaysCoordEndCornerRight.apply_course_distance((me.info.runways[me.selectedRunway].heading),me.info.runways[me.selectedRunway].length);
    }
     
    #Calculating the HUD coord of the runways coord
    me.MyRunwayTripos                     = HudMath.getPosFromCoord(me.RunwayCoord);
    me.MyRunwayCoordCornerLeftTripos      = HudMath.getPosFromCoord(me.RunwaysCoordCornerLeft);
    me.MyRunwayCoordCornerRightTripos     = HudMath.getPosFromCoord(me.RunwaysCoordCornerRight);
    me.MyRunwayCoordCornerEndLeftTripos   = HudMath.getPosFromCoord(me.RunwaysCoordEndCornerLeft);
    me.MyRunwayCoordCornerEndRightTripos  = HudMath.getPosFromCoord(me.RunwaysCoordEndCornerRight);

    #Updating : clear all previous stuff
    me.myRunwayGroup.removeAllChildren();
    #drawing the runway
    me.RunwaysDrawing = me.myRunwayGroup.createChild("path")
    .setColor(me.myGreen)
    .moveTo(me.MyRunwayCoordCornerLeftTripos[0],me.MyRunwayCoordCornerLeftTripos[1])
    .lineTo(me.MyRunwayCoordCornerRightTripos[0],me.MyRunwayCoordCornerRightTripos[1])
    .lineTo(me.MyRunwayCoordCornerEndRightTripos[0],me.MyRunwayCoordCornerEndRightTripos[1])
    .lineTo(me.MyRunwayCoordCornerEndLeftTripos[0],me.MyRunwayCoordCornerEndLeftTripos[1])
    .lineTo(me.MyRunwayCoordCornerLeftTripos[0],me.MyRunwayCoordCornerLeftTripos[1])
    .setStrokeLineWidth(4);
    
    me.myRunwayGroup.update();
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
  #This should be called with a geo.coord object.
  #Doing that way it could be used for waypoint, bullseye and ground target
#       if(me.input.distNextWay.getValue()!= nil and me.input.distNextWay.getValue()<10 and me.input.gearPos.getValue() == 0 
#                        and me.input.NextWayNum.getValue()!=-1 and me.NXTWP != nil and me.fp.currentWP() != nil){#if waypoint is active
  
  
  displayWaypointCross:func(coord){
    #print("runing displayWaypointCross"); 
    if(coord != nil){ #The aircraft should be flying ... This need to be done before in hud mode selection
      #print("coord is not nil");
      if(me.aircraft_position.direct_distance_to(coord)*M2NM<10){
        #print("Shoud display the waypoint");
        me.WaypointCross.setTranslation(HudMath.getPosFromCoord(coord));
        me.displayWaypointCrossShow = 1;
        return;
      }
    }
    #me.WaypointCross.hide();
  },
  
  #This should be called at every iteration
  NextWaypointCoordinate:func(){ 
      if(me.fp.currentWP() != nil){
          #Sometime you can set up an altitude to your waypoint. if it's the case we take it.
          me.NxtElevation = getprop("/autopilot/route-manager/route/wp[" ~ me.input.currentWp.getValue() ~ "]/altitude-m");
          
          #print("me.NxtWP_latDeg:",me.NxtWP_latDeg, " me.NxtWP_lonDeg:",me.NxtWP_lonDeg);
          #if the altitude isn't set, just take the ground alt.
          var Geo_Elevation = geo.elevation(me.fp.currentWP().lat , me.fp.currentWP().lon);    
          Geo_Elevation = Geo_Elevation == nil ? 0: Geo_Elevation; 
          #print("Geo_Elevation:",Geo_Elevation," me.NxtElevation:",me.NxtElevation);
          
          #if no altitude, then take ground alt
          if( me.NxtElevation  != nil){
            Geo_Elevation = me.NxtElevation  > Geo_Elevation ? me.NxtElevation : Geo_Elevation ;     
            me.NXTWP.set_latlon(me.fp.currentWP().lat , me.fp.currentWP().lon ,  Geo_Elevation + 2);
          }
          
      }
  },
  
  resetGunPos: func {
      me.gunPos   = [];
      for(i = 0;i < me.funnelParts*4;i+=1){
        var tmp = [];
        for(var myloopy = 0;myloopy <= i+1;myloopy+=1){
          append(tmp,nil);
        }
        append(me.gunPos, tmp);
      }
  },
  makeVector: func (siz,content) {
        var vec = setsize([],siz*4);
        var k = 0;
        while(k<siz*4) {
            vec[k] = content;
            k += 1;
        }
        return vec;
  },
  displayEEGS: func() {
        #note: this stuff is expensive like hell to compute, but..lets do it anyway.
        #var me.funnelParts = 40;#max 10
        var st = systime();
        me.eegsMe.dt = st-me.lastTime;
        if (me.eegsMe.dt > me.averageDt*3) {
            me.lastTime = st;
            me.resetGunPos();  
            me.eegsGroup.removeAllChildren();
        } else {
            #printf("dt %05.3f",me.eegsMe.dt);
            me.lastTime = st;
            
            me.eegsMe.hdg   = me.input.hdgReal.getValue();
            me.eegsMe.pitch = me.input.pitch.getValue();
            me.eegsMe.roll  = me.input.roll.getValue();
                   
            var hdp = {roll:me.eegsMe.roll,current_view_z_offset_m: me.input.z_offset_m.getValue()};
            
            
            me.eegsMe.ac = geo.aircraft_position();
            me.eegsMe.allow = 1;
            me.drawEEGSPipper = 0;
            me.drawEEGS300 = 0;
            me.drawEEGS600 = 0;
            me.strfRange = 4500 * M2FT;  
            if(me.strf or me.hydra) {
                me.groundDistanceFT = nil;
                var l = 0;
                for (l = 0;l < me.funnelParts*4;l+=1) {
                    # compute display positions of funnel on hud
                    var pos = me.gunPos[l][0];
                    if (pos == nil) {
                        me.eegsMe.allow = 0;
                    } else {
                        var ac  = me.gunPos[l][0][1];
                        pos     = me.gunPos[l][0][0];
                        var el = geo.elevation(pos.lat(),pos.lon());
                        if (el == nil) {
                            el = 0;
                        }

                        if (l != 0 and el > pos.alt()) {
                            var hitPos = geo.Coord.new(pos);
                            hitPos.set_alt(el);
                            me.groundDistanceFT = (el-pos.alt())*M2FT;#ac.direct_distance_to(hitPos)*M2FT;
                            me.strfRange = hitPos.direct_distance_to(me.eegsMe.ac)*M2FT;
                            l = l;
                            break;
                        }
                    }
                }
                #print("me.eegsMe.allow:" ~ me.eegsMe.allow);
                #print(" me.groundDistanceFT:"~ (me.groundDistanceFT==nil?"nil":me.groundDistanceFT));
                # compute display positions of pipper on hud                
                if (me.eegsMe.allow and me.groundDistanceFT != nil) {
                    #print("test");
                    for (var ll = l-1;ll <= l;ll+=1) {
                        var ac    = me.gunPos[ll][0][1];
                        var pos   = me.gunPos[ll][0][0];
                        var pitch = me.gunPos[ll][0][2];

                        me.eegsMe.posTemp = HudMath.getPosFromCoord(pos,ac);
                        me.eegsMe.shellPosDist[ll] = ac.direct_distance_to(pos)*M2FT;
                        me.eegsMe.shellPosX[ll] = me.eegsMe.posTemp[0];#me.eegsMe.xcS;
                        me.eegsMe.shellPosY[ll] = me.eegsMe.posTemp[1];#me.eegsMe.ycS;
                        
                        if (l == ll and me.strfRange*FT2M < 4500) {
                            var highdist = me.eegsMe.shellPosDist[ll];
                            var lowdist = me.eegsMe.shellPosDist[ll-1];
                            me.groundDistanceFT = me.groundDistanceFT/math.cos(90-pitch*D2R);
                            #me.groundDistanceFT = math.sqrt(me.groundDistanceFT*me.groundDistanceFT+me.groundDistanceFT*me.groundDistanceFT);#we just assume impact angle of 45 degs
                            me.eegsPipperX = HudMath.extrapolate(highdist-me.groundDistanceFT,lowdist,highdist,me.eegsMe.shellPosX[ll-1],me.eegsMe.shellPosX[ll]);
                            me.eegsPipperY = HudMath.extrapolate(highdist-me.groundDistanceFT,lowdist,highdist,me.eegsMe.shellPosY[ll-1],me.eegsMe.shellPosY[ll]);
                            me.drawEEGSPipper = 1;
                            #print("Should draw Piper");
                        }
                    }
                }
            }else{       
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
            }
            if (me.eegsMe.allow and !(me.strf or me.hydra)) {
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
            #print("me.strfRange in meters:" ~me.strfRange*FT2M);
            #Same Piper asthe A/A it should be done in a function
            if (me.eegsMe.allow and (me.strf or me.hydra)) {
                me.eegsGroup.removeAllChildren();
                if (me.drawEEGSPipper and me.strfRange*FT2M <= 4000) {

                    #print("me.strfRange in meters:" ~me.strfRange*FT2M);
                    me.EEGSdeg = math.max(0,HudMath.extrapolate(me.strfRange*FT2M,2400,600,360,0))*D2R;
                    me.EEGSdegPos = [math.sin(me.EEGSdeg)*40,40-math.cos(me.EEGSdeg)*40];
                  
                    
                    #drawing mini line and centra point 
                    me.eegsGroup.createChild("path")
                          .moveTo(me.eegsPipperX,me.eegsPipperY)
                          .lineTo(me.eegsPipperX,me.eegsPipperY)
                          .arcSmallCW(3, 3, 0, 3*2, 0)
                          .arcSmallCW(3, 3, 0, -3*2, 0)
                          .moveTo(me.eegsPipperX, me.eegsPipperY-40)  
                          .lineTo(me.eegsPipperX, me.eegsPipperY-55)
                          .moveTo(me.eegsPipperX, me.eegsPipperY+40)  
                          .lineTo(me.eegsPipperX, me.eegsPipperY+55)
                          .moveTo(me.eegsPipperX-40, me.eegsPipperY)  
                          .lineTo(me.eegsPipperX-55, me.eegsPipperY)
                          .moveTo(me.eegsPipperX+40, me.eegsPipperY)  
                          .lineTo(me.eegsPipperX+55, me.eegsPipperY)
                          .setColor(me.myGreen)
                          .setStrokeLineWidth(4);
                          
                          # Distance to target
                    me.eegsGroup.createChild("text")
                    .setColor(me.myGreen)
                    .setTranslation(me.maxladderspan,-120)
                    .setDouble("character-size", 35)
                    .setAlignment("left-center")
                    .setText(sprintf("%.1f KM", me.strfRange*FT2M/1000));     
                          
                    
                     #drawing piper
                    if(me.strfRange*FT2M <4000){
                    me.eegsGroup.createChild("path")
                          .moveTo(me.eegsPipperX,me.eegsPipperY-40)
                          .lineTo(me.eegsPipperX, me.eegsPipperY-55)
                          .setCenter(me.eegsPipperX,me.eegsPipperY)
                          .setColor(me.myGreen)
                          .setStrokeLineWidth(4)
                          .setRotation(me.EEGSdeg);
                    }
                    
                    if (me.EEGSdeg<180*D2R) {
                      me.eegsGroup.createChild("path")
                          .setColor(me.myGreen)
                          .moveTo(me.eegsPipperX, me.eegsPipperY-40)
                          .arcSmallCW(40,40,0,me.EEGSdegPos[0],me.EEGSdegPos[1])
                          .setStrokeLineWidth(4);
                    } elsif (me.EEGSdeg>=360*D2R) {
                      me.eegsGroup.createChild("path")
                          .setColor(me.myGreen)
                          .moveTo(me.eegsPipperX, me.eegsPipperY-40)
                          .arcSmallCW(40,40,0,0,80)
                          .arcSmallCW(40,40,0,0,-80)
                          .setStrokeLineWidth(4);
                    } else {
                      me.eegsGroup.createChild("path")
                          .setColor(me.myGreen)
                          .moveTo(me.eegsPipperX, me.eegsPipperY-40)
                          .arcLargeCW(40,40,0,me.EEGSdegPos[0],me.EEGSdegPos[1])
                          .setStrokeLineWidth(4);
                    }
                  
                  
                  
                    #var mr = 0.4 * 1.5;
#                     var mr = 1.8;
#                     var pipperRadius = 15 * mr;
#                     if (me.strfRange <= 4000) {
#                         me.eegsGroup.createChild("path")
#                             .moveTo(me.eegsPipperX-pipperRadius, me.eegsPipperY-pipperRadius-2)
#                             .horiz(pipperRadius*2)
#                             .moveTo(me.eegsPipperX-pipperRadius, me.eegsPipperY)
#                             .arcSmallCW(pipperRadius, pipperRadius, 0, pipperRadius*2, 0)
#                             .arcSmallCW(pipperRadius, pipperRadius, 0, -pipperRadius*2, 0)
#                             .moveTo(me.eegsPipperX-2*mr,me.eegsPipperY)
#                             .arcSmallCW(2*mr,2*mr, 0, 2*mr*2, 0)
#                             .arcSmallCW(2*mr,2*mr, 0, -2*mr*2, 0)
#                             .setStrokeLineWidth(4)
#                             .setColor(me.myGreen);
#                     } else {
#                         me.eegsGroup.createChild("path")
#                             .moveTo(me.eegsPipperX-pipperRadius, me.eegsPipperY)
#                             .arcSmallCW(pipperRadius, pipperRadius, 0, pipperRadius*2, 0)
#                             .arcSmallCW(pipperRadius, pipperRadius, 0, -pipperRadius*2, 0)
#                             .moveTo(me.eegsPipperX-2*mr,me.eegsPipperY)
#                             .arcSmallCW(2*mr,2*mr, 0, 2*mr*2, 0)
#                             .arcSmallCW(2*mr,2*mr, 0, -2*mr*2, 0)
#                             .setStrokeLineWidth(4)
#                             .setColor(me.myGreen);
#                     }
                }
                me.eegsGroup.update();
            }
            
            
            
            
            #calc shell positions
            
            me.eegsMe.vel = me.input.uBody_fps.getValue() +3363.0 ; #3363.0 = speed
            
            me.eegsMe.geodPos = aircraftToCart({x:-0, y:0, z: me.input.y_offset_m.getValue()});#position (meters) of gun in aircraft (x and z inverted)
            me.eegsMe.eegsPos.set_xyz(me.eegsMe.geodPos.x, me.eegsMe.geodPos.y, me.eegsMe.geodPos.z);
            me.eegsMe.altC = me.eegsMe.eegsPos.alt();
            
            me.eegsMe.rs = armament.AIM.rho_sndspeed(me.eegsMe.altC*M2FT);#simplified
            me.eegsMe.rho = me.eegsMe.rs[0];
            me.eegsMe.mass =  0.9369635/ armament.slugs_to_lbm;#0.9369635=lbs
            
            #print("x,y");
            #printf("%d,%d",0,0);
            #print("-----");
            var multi = (me.strf or me.hydra)?4:1;
            for (var j = 0;j < me.funnelParts*multi;j+=1) {
                
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
                
                me.old = me.gunPos[j];
                me.gunPos[j] = [[geo.Coord.new(me.eegsMe.eegsPos),me.eegsMe.ac, me.eegsMe.pitch]];
                for (var m = 0;m<j+1;m+=1) {
                    append(me.gunPos[j], me.old[m]);
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
############## When pilot view is changed the whole scale need to be redrawn ##########################
    recalculateLadder:func(){
      
        me.LadderGroup.removeAllChildren();
        for (var myladder = 5;myladder <= 90;myladder+=5)
        {
          
          if (myladder/10 == int(myladder/10)){
              #Text bellow 0 left
              me.LadderGroup.createChild("text")
                .setColor(me.myGreen)
                .setAlignment("right-center")
                .setTranslation(-me.maxladderspan, HudMath.getPixelPerDegreeAvg(me.ladderScale)*myladder)
                .setDouble("character-size", 30)
                .setText(myladder);
              #Text bellow 0 left
              me.LadderGroup.createChild("text")
                .setColor(me.myGreen)
                .setAlignment("left-center")
                .setTranslation(me.maxladderspan, HudMath.getPixelPerDegreeAvg(me.ladderScale)*myladder)
                .setDouble("character-size", 30)
                .setText(myladder);

              #Text above 0 left         
              me.LadderGroup.createChild("text")
                .setColor(me.myGreen)
                .setAlignment("right-center")
                .setTranslation(-me.maxladderspan, HudMath.getPixelPerDegreeAvg(me.ladderScale)*-myladder)
                .setDouble("character-size", 30)
                .setText(myladder); 
              #Text above 0 right   
              me.LadderGroup.createChild("text")
                .setColor(me.myGreen)
                .setAlignment("left-center")
                .setTranslation(me.maxladderspan, HudMath.getPixelPerDegreeAvg(me.ladderScale)*-myladder)
                .setDouble("character-size", 30)
                .setText(myladder);
            }
            
        # =============  BELLOW 0 ===================           
          #half line bellow 0 (left part)       ------------------ 
          me.LadderGroup.createChild("path")
            .setColor(me.myGreen)
            .moveTo(-me.maxladderspan, HudMath.getPixelPerDegreeAvg(me.ladderScale)*myladder)
            .vert(-me.maxladderspan/15)
            .setStrokeLineWidth(4); 
                        
          me.LadderGroup.createChild("path")
            .setColor(me.myGreen)
            .moveTo(-me.maxladderspan, HudMath.getPixelPerDegreeAvg(me.ladderScale)*myladder)
            .horiz(me.maxladderspan*2/15)
            .setStrokeLineWidth(4);             
          me.LadderGroup.createChild("path")
            .setColor(me.myGreen)
            .moveTo(-abs(me.maxladderspan - me.maxladderspan*2/15*2), HudMath.getPixelPerDegreeAvg(me.ladderScale)*myladder)
            .horiz(me.maxladderspan*2/15)
            .setStrokeLineWidth(4);    
          me.LadderGroup.createChild("path")
            .setColor(me.myGreen)
            .moveTo(-abs(me.maxladderspan - me.maxladderspan*2/15*4), HudMath.getPixelPerDegreeAvg(me.ladderScale)*myladder)
            .horiz(me.maxladderspan*2/15)
            .setStrokeLineWidth(4);
                        
          #half line (rigt part)       ------------------   
          me.LadderGroup.createChild("path")
            .setColor(me.myGreen)
            .moveTo(me.maxladderspan, HudMath.getPixelPerDegreeAvg(me.ladderScale)*myladder)
            .vert(-me.maxladderspan/15)
            .setStrokeLineWidth(4); 
                        
          me.LadderGroup.createChild("path")
            .setColor(me.myGreen)
            .moveTo(me.maxladderspan, HudMath.getPixelPerDegreeAvg(me.ladderScale)*myladder)
            .horiz(-me.maxladderspan*2/15)
            .setStrokeLineWidth(4);             
          me.LadderGroup.createChild("path")
            .setColor(me.myGreen)
            .moveTo(abs(me.maxladderspan - me.maxladderspan*2/15*2), HudMath.getPixelPerDegreeAvg(me.ladderScale)*myladder)
            .horiz(-me.maxladderspan*2/15)
            .setStrokeLineWidth(4);    
          me.LadderGroup.createChild("path")
            .setColor(me.myGreen)
            .moveTo(abs(me.maxladderspan - me.maxladderspan*2/15*4), HudMath.getPixelPerDegreeAvg(me.ladderScale)*myladder)
            .horiz(-me.maxladderspan*2/15)
            .setStrokeLineWidth(4);              
                        
      # =============  ABOVE 0 ===================               
          me.LadderGroup.createChild("path")
            .setColor(me.myGreen)
            .moveTo(-me.maxladderspan, HudMath.getPixelPerDegreeAvg(me.ladderScale)*-myladder)
            .vert(me.maxladderspan/15)
            .setStrokeLineWidth(4); 
                        
          me.LadderGroup.createChild("path")
            .setColor(me.myGreen)
            .moveTo(-me.maxladderspan, HudMath.getPixelPerDegreeAvg(me.ladderScale)*-myladder)
            .horiz(me.maxladderspan/3*2)
            .setStrokeLineWidth(4);             
                
          #half line (rigt part)       ------------------           
          me.LadderGroup.createChild("path")
            .setColor(me.myGreen)
            .moveTo(me.maxladderspan, HudMath.getPixelPerDegreeAvg(me.ladderScale)*-myladder)
            .horiz(-me.maxladderspan/3*2)
            .setStrokeLineWidth(4);            
          me.LadderGroup.createChild("path")
            .setColor(me.myGreen)
            .moveTo(me.maxladderspan, HudMath.getPixelPerDegreeAvg(me.ladderScale)*-myladder)
            .vert(me.maxladderspan/15)
            .setStrokeLineWidth(4); 
                        

        }           
      
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
