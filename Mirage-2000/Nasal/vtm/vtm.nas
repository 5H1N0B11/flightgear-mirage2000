# VTM - Visualisation Tête Moyenne
# aka. écran radar
# The display just below the HUD and the Visualisation Tête Bas (VTB): head level display.
#
# Measurements from ac-model 2000-5: 
#  * height (y) = top: -0.075 bottom: -0.159 = 84 mm, middle = -0.117
#  * width (z)  = left: 0.060 right: -0.060 = 120 mm, middle = 0.0
#  * depth (x) -3.305 (bottom of front), -3.268 (top of front)
# 
# From measurements of cockpit pictures it looks like the screen width/height is ca. 75% of an MFD.
#
# We go with height = 0.09, middle = -0.115; and width = 0.12 -> results in a 4:3 screen
# We go with a 768/1024 resolution -> 4:3
#
# The main visual source for the VTM is the picture on page 70 in the following book:
# Alexandre Paringaux, Mirage 2000-5; Groupe de chasse 1/2 Cigognes. Zéphyr.
# 


print("*** LOADING vtm.nas ... ***");

# It is basically a black and green screen.
var COLOR_BACKGROUND = [0,0.02,0];
var COLOR_FOREGROUND = [0,1,0];

var SCREEN_WIDTH = 1024;
var SCREEN_HEIGHT = 768;

# The main dimensions and corners of the screen. 
# x=0, y=0 is in the top left corner; x increases towards right; y increases downwards
# There is a small padding around the drawable screen area, because the pilot moves the head etc.
var PADDING_VERTICAL = 34; # 768 - 2*34 = 700 left
var PADDING_HORIZONTAL = 47; # 1024 - 2*47 = 930 left

var CORNER_LINE_LENGTH = 75;
var CORNER_LINE_WIDTH = 4;

var VTM = {
  new: func() {
    print("*** VTM.new called");
    var vtm_obj = {parents: [VTM]};
    vtm_obj.vtm_canvas = canvas.new({
      "name": "vtm_canvas",
      "size": [SCREEN_WIDTH, SCREEN_HEIGHT],
      "view": [SCREEN_WIDTH, SCREEN_HEIGHT],
      "mipmapping": 1
    });

    vtm_obj.vtm_canvas.addPlacement({"node": "vtm_ac_object"});
    vtm_obj.vtm_canvas.setColorBackground(COLOR_BACKGROUND);

    # draw the corners
    vtm_obj.corners_group = vtm_obj.vtm_canvas.createGroup("corners_group");
    vtm_obj.left_upper_corner = vtm_obj.corners_group.createChild("path", "left_upper_corner")
                                .setColor(COLOR_FOREGROUND)
                                .moveTo(PADDING_HORIZONTAL + CORNER_LINE_LENGTH,
                                        PADDING_VERTICAL)
                                .horizTo(PADDING_HORIZONTAL)
                                .vertTo(PADDING_VERTICAL + CORNER_LINE_LENGTH)
                                .setStrokeLineWidth(CORNER_LINE_WIDTH);
    vtm_obj.right_upper_corner = vtm_obj.corners_group.createChild("path", "right_upper_corner")
                                 .setColor(COLOR_FOREGROUND)
                                 .moveTo(SCREEN_WIDTH - PADDING_HORIZONTAL - CORNER_LINE_LENGTH,
                                         PADDING_VERTICAL)
                                 .horizTo(SCREEN_WIDTH - PADDING_HORIZONTAL)
                                 .vertTo(PADDING_VERTICAL + CORNER_LINE_LENGTH)
                                 .setStrokeLineWidth(CORNER_LINE_WIDTH);
    vtm_obj.left_lower_corner  = vtm_obj.corners_group.createChild("path", "left_lower_corner")
                                 .setColor(COLOR_FOREGROUND)
                                 .moveTo(PADDING_HORIZONTAL + CORNER_LINE_LENGTH,
                                         SCREEN_HEIGHT - PADDING_VERTICAL)
                                 .horizTo(PADDING_HORIZONTAL)
                                 .vertTo(SCREEN_HEIGHT - PADDING_VERTICAL - CORNER_LINE_LENGTH)
                                 .setStrokeLineWidth(CORNER_LINE_WIDTH);
    vtm_obj.right_lower_corner  = vtm_obj.corners_group.createChild("path", "right_lower_corner")
                                  .setColor(COLOR_FOREGROUND)
                                  .moveTo(SCREEN_WIDTH - PADDING_HORIZONTAL - CORNER_LINE_LENGTH,
                                          SCREEN_HEIGHT - PADDING_VERTICAL)
                                  .horizTo(SCREEN_WIDTH - PADDING_HORIZONTAL)
                                  .vertTo(SCREEN_HEIGHT - PADDING_VERTICAL - CORNER_LINE_LENGTH)
                                  .setStrokeLineWidth(CORNER_LINE_WIDTH);

    return vtm_obj;
  },

  update: func() {
  },
}
