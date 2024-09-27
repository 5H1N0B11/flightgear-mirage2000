# VTM - Visualisation Tête Moyenne
# aka. écran radar
# The display just below the HUD and the Visualisation Tête Bas (VTB): head level display.
# Basically it is a bit like the Fire Control Radar in the F-16: https://github.com/NikolaiVChr/f16/wiki/FCR
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
# The main visual source for the VTM is the picture on page 71 in the following book:
# Alexandre Paringaux, Mirage 2000-5; Groupe de chasse 1/2 Cigognes. Zéphyr.
# 


print("*** LOADING vtm.nas ... ***");

# It is basically a black and green screen.
var COLOR_BACKGROUND = [0,0.02,0]; # almost black with a bit of green
var COLOR_FOREGROUND = [0.75,1,0]; # between yellow and green
var COLOR_RADAR = [0,1,0]; # green

var SCREEN_WIDTH = 1024;
var SCREEN_HEIGHT = 768;

# The main dimensions and corners of the screen. 
# x=0, y=0 is in the top left corner; x increases towards right; y increases downwards
# There is a small padding around the drawable screen area, because the pilot moves the head etc.
var PADDING_TOP = 34; # 768 - 2*34 = 700 left
var PADDING_BOTTOM = 54; 
var PADDING_HORIZONTAL = 47; # 1024 - 2*47 = 930 left

# The radar view is where radar stuff gets displayed - between the 4 corners
var RADAR_VIEW_VERTICAL = SCREEN_HEIGHT - PADDING_TOP - PADDING_BOTTOM;
var RADAR_VIEW_HORIZONTAL = SCREEN_WIDTH - 2 * PADDING_HORIZONTAL;

var CORNER_LINE_LENGTH = 75;
var LINE_WIDTH = 2;
var GRID_TICK_LENGTH = 10;

var FONT_SIZE = 18;
var FONT_ASPECT_RATIO = 1;

var MAX_TARGETS = 28;
var TARGET_WIDTH = 30;

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

    vtm_obj._create_visible_corners();
    vtm_obj._create_screen_mode_group();
    vtm_obj._create_rectangular_field_of_view_grid();
    vtm_obj._create_targets();

    return vtm_obj;
  },

  # The 4 visible corners at the edges of the main screen estate
  _create_visible_corners: func() {
    me.corners_group = me.vtm_canvas.createGroup("corners_group");
    me.left_upper_corner      = me.corners_group.createChild("path", "left_upper_corner")
                                .setColor(COLOR_FOREGROUND)
                                .moveTo(PADDING_HORIZONTAL + CORNER_LINE_LENGTH,
                                        PADDING_TOP)
                                .horizTo(PADDING_HORIZONTAL)
                                .vertTo(PADDING_TOP + CORNER_LINE_LENGTH)
                                .setStrokeLineWidth(LINE_WIDTH);
    me.right_upper_corner      = me.corners_group.createChild("path", "right_upper_corner")
                                 .setColor(COLOR_FOREGROUND)
                                 .moveTo(SCREEN_WIDTH - PADDING_HORIZONTAL - CORNER_LINE_LENGTH,
                                         PADDING_TOP)
                                 .horizTo(SCREEN_WIDTH - PADDING_HORIZONTAL)
                                 .vertTo(PADDING_TOP + CORNER_LINE_LENGTH)
                                 .setStrokeLineWidth(LINE_WIDTH);
    me.left_lower_corner       = me.corners_group.createChild("path", "left_lower_corner")
                                 .setColor(COLOR_FOREGROUND)
                                 .moveTo(PADDING_HORIZONTAL + CORNER_LINE_LENGTH,
                                         SCREEN_HEIGHT - PADDING_BOTTOM)
                                 .horizTo(PADDING_HORIZONTAL)
                                 .vertTo(SCREEN_HEIGHT - PADDING_BOTTOM - CORNER_LINE_LENGTH)
                                 .setStrokeLineWidth(LINE_WIDTH);
    me.right_lower_corner      = me.corners_group.createChild("path", "right_lower_corner")
                                  .setColor(COLOR_FOREGROUND)
                                  .moveTo(SCREEN_WIDTH - PADDING_HORIZONTAL - CORNER_LINE_LENGTH,
                                          SCREEN_HEIGHT - PADDING_BOTTOM)
                                  .horizTo(SCREEN_WIDTH - PADDING_HORIZONTAL)
                                  .vertTo(SCREEN_HEIGHT - PADDING_BOTTOM - CORNER_LINE_LENGTH)
                                  .setStrokeLineWidth(LINE_WIDTH);
  },

  # The text for the screen main modes: RDR (radar) and LDP (laser designation point)
  # appears at the bottom of the screen
  _create_screen_mode_group: func() {
    me.screen_mode_group = me.vtm_canvas.createGroup("screen_mode_group");
    me.screen_mode_rdr      = me.screen_mode_group.createChild("text", "screen_mode_rdr")
                              .setFontSize(FONT_SIZE, FONT_ASPECT_RATIO)
                              .setColor(COLOR_FOREGROUND)
                              .setAlignment("left-top")
                              .setText("RDR")
                              .setTranslation(PADDING_HORIZONTAL + 0.5*0.25*RADAR_VIEW_HORIZONTAL,
                                              SCREEN_HEIGHT - PADDING_BOTTOM + 5);
    me.screen_mode_ldp      = me.screen_mode_group.createChild("text", "screen_mode_ldp")
                              .setFontSize(FONT_SIZE, FONT_ASPECT_RATIO)
                              .setColor(COLOR_FOREGROUND)
                              .setAlignment("left-top")
                              .setText("LDP")
                              .setTranslation(PADDING_HORIZONTAL + 1.5*0.25*RADAR_VIEW_HORIZONTAL,
                                              SCREEN_HEIGHT - PADDING_BOTTOM + 5);
    me.screen_mode_rdr_box  = me.screen_mode_group.createChild("path", "screen_mode_rdr_box")
                              .setColor(COLOR_FOREGROUND)
                              .rect(PADDING_HORIZONTAL + 0.4*0.25*RADAR_VIEW_HORIZONTAL,
                                    SCREEN_HEIGHT - PADDING_BOTTOM + 1,
                                    0.5*0.25*RADAR_VIEW_HORIZONTAL, 25)
                              .setStrokeLineWidth(LINE_WIDTH);
    me.screen_mode_ldp_box  = me.screen_mode_group.createChild("path", "screen_mode_ldp_box")
                              .setColor(COLOR_FOREGROUND)
                              .rect(PADDING_HORIZONTAL + 1.4*0.25*RADAR_VIEW_HORIZONTAL,
                                    SCREEN_HEIGHT - PADDING_BOTTOM + 1,
                                    0.5*0.25*RADAR_VIEW_HORIZONTAL, 25)
                              .setStrokeLineWidth(LINE_WIDTH);
    me.screen_mode_ldp_box.hide();
  },

  # Create the stippled grid for B-scope
  _create_rectangular_field_of_view_grid: func() {
    me.rectangular_fov_grid_group = me.vtm_canvas.createGroup("rectangular_fov_grid");
    me.top_grid_line = me.rectangular_fov_grid_group.createChild("path", "top_grid_line")
                            .setColor(COLOR_RADAR)
                            .moveTo(PADDING_HORIZONTAL + GRID_TICK_LENGTH, PADDING_TOP - GRID_TICK_LENGTH)
                            .horizTo(SCREEN_WIDTH - PADDING_HORIZONTAL - GRID_TICK_LENGTH)
                            .setStrokeLineWidth(LINE_WIDTH);
    me.top_ticks     = me.rectangular_fov_grid_group.createChild("path", "top_ticks")
                            .setColor(COLOR_RADAR)
                            .moveTo(PADDING_HORIZONTAL + 0.25*RADAR_VIEW_HORIZONTAL, 
                                    PADDING_TOP - GRID_TICK_LENGTH)
                            .vertTo(PADDING_TOP)
                            .moveTo(PADDING_HORIZONTAL + 0.5*RADAR_VIEW_HORIZONTAL, 
                                    PADDING_TOP - GRID_TICK_LENGTH)
                            .vertTo(PADDING_TOP)
                            .moveTo(PADDING_HORIZONTAL + 0.75*RADAR_VIEW_HORIZONTAL, 
                                    PADDING_TOP - GRID_TICK_LENGTH)
                            .vertTo(PADDING_TOP)
                            .setStrokeLineWidth(LINE_WIDTH);
    var spacing = (RADAR_VIEW_VERTICAL - 4 * 2 * GRID_TICK_LENGTH) / 4;
    me.line_ticks    = me.rectangular_fov_grid_group.createChild("path", "line_ticks")
                            .setColor(COLOR_FOREGROUND)
                            .moveTo(PADDING_HORIZONTAL + 0.25*RADAR_VIEW_HORIZONTAL, 
                                    PADDING_TOP + spacing)
                            .vert(2*GRID_TICK_LENGTH)
                            .moveTo(PADDING_HORIZONTAL + 0.25*RADAR_VIEW_HORIZONTAL, 
                                    PADDING_TOP + 2*spacing + 2*GRID_TICK_LENGTH)
                            .vert(2*GRID_TICK_LENGTH)
                            .moveTo(PADDING_HORIZONTAL + 0.25*RADAR_VIEW_HORIZONTAL, 
                                    PADDING_TOP + 3*spacing + 2*2*GRID_TICK_LENGTH)
                            .vert(2*GRID_TICK_LENGTH)
                            .moveTo(PADDING_HORIZONTAL + 0.25*RADAR_VIEW_HORIZONTAL, 
                                    PADDING_TOP + 4*spacing + 3*2*GRID_TICK_LENGTH)
                            .vert(2*GRID_TICK_LENGTH)
                            # 
                            .moveTo(PADDING_HORIZONTAL + 0.5*RADAR_VIEW_HORIZONTAL, 
                                    PADDING_TOP + spacing)
                            .vert(2*GRID_TICK_LENGTH)
                            .moveTo(PADDING_HORIZONTAL + 0.5*RADAR_VIEW_HORIZONTAL, 
                                    PADDING_TOP + 2*spacing + 2*GRID_TICK_LENGTH)
                            .vert(2*GRID_TICK_LENGTH)
                            .moveTo(PADDING_HORIZONTAL + 0.5*RADAR_VIEW_HORIZONTAL, 
                                    PADDING_TOP + 3*spacing + 2*2*GRID_TICK_LENGTH)
                            .vert(2*GRID_TICK_LENGTH)
                            .moveTo(PADDING_HORIZONTAL + 0.5*RADAR_VIEW_HORIZONTAL, 
                                    PADDING_TOP + 4*spacing + 3*2*GRID_TICK_LENGTH)
                            .vert(2*GRID_TICK_LENGTH)
                            # 
                            .moveTo(PADDING_HORIZONTAL + 0.75*RADAR_VIEW_HORIZONTAL, 
                                    PADDING_TOP + spacing)
                            .vert(2*GRID_TICK_LENGTH)
                            .moveTo(PADDING_HORIZONTAL + 0.75*RADAR_VIEW_HORIZONTAL, 
                                    PADDING_TOP + 2*spacing + 2*GRID_TICK_LENGTH)
                            .vert(2*GRID_TICK_LENGTH)
                            .moveTo(PADDING_HORIZONTAL + 0.75*RADAR_VIEW_HORIZONTAL, 
                                    PADDING_TOP + 3*spacing + 2*2*GRID_TICK_LENGTH)
                            .vert(2*GRID_TICK_LENGTH)
                            .moveTo(PADDING_HORIZONTAL + 0.75*RADAR_VIEW_HORIZONTAL, 
                                    PADDING_TOP + 4*spacing + 3*2*GRID_TICK_LENGTH)
                            .vert(2*GRID_TICK_LENGTH)
                            .setStrokeLineWidth(LINE_WIDTH);
  },

  # 3 types of targets: selected target, friend targets, foe targets.
  # The selected target (max 1) is a cross.
  # The friendly targets (given the IFF) are drawn as a filled circle.
  # Foe targets are drawn as open squares - with the opening being on the back side of the target
  _create_targets: func() {
    var x_pos = 0;
    var y_pos = 0;
    me.targets_group = me.vtm_canvas.createGroup("targets_group");
    me.selected_target = me.targets_group.createChild("path", "selected_target")
                         .setColor(COLOR_RADAR)
                         .moveTo(PADDING_HORIZONTAL + 0.8*RADAR_VIEW_HORIZONTAL, 
                                 PADDING_TOP + 0.9*RADAR_VIEW_VERTICAL + TARGET_WIDTH/2)
                         .horiz(TARGET_WIDTH)
                         .moveTo(PADDING_HORIZONTAL + 0.8*RADAR_VIEW_HORIZONTAL + TARGET_WIDTH/2, 
                                 PADDING_TOP + 0.9*RADAR_VIEW_VERTICAL)
                         .vert(TARGET_WIDTH)
                         .setStrokeLineWidth(2*LINE_WIDTH);

    me.friend_targets = setsize([],MAX_TARGETS);
    y_pos = PADDING_TOP + 100;
    for (var i = 0; i<MAX_TARGETS; i += 1) {
      x_pos = PADDING_HORIZONTAL + (i + 2)*TARGET_WIDTH;
      me.friend_targets[i] = me.targets_group.createChild("path")
                             .setColor(COLOR_RADAR)
                             .circle(TARGET_WIDTH/2, x_pos, y_pos)
                             .setStrokeLineWidth(2*LINE_WIDTH);
    }

    me.foe_targets = setsize([],MAX_TARGETS);
    y_pos = PADDING_TOP + 300;
    for (var i = 0; i<MAX_TARGETS; i += 1) {
      x_pos = PADDING_HORIZONTAL + (i + 2)*TARGET_WIDTH;
      me.foe_targets[i]    = me.targets_group.createChild("path")
                             .setColor(COLOR_RADAR)
                             .moveTo(x_pos, y_pos)
                             .vert(TARGET_WIDTH)
                             .moveTo(x_pos, y_pos)
                             .horiz(TARGET_WIDTH)
                             .moveTo(x_pos + TARGET_WIDTH, y_pos)
                             .vert(TARGET_WIDTH)
                             .setStrokeLineWidth(LINE_WIDTH);
    }
  },

  update: func() {
  },
}
