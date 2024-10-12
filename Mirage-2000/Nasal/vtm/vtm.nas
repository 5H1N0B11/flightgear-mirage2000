# VTM - Visualisation Tête Moyenne
# aka. écran radar
# The display just below the HUD and the Visualisation Tête Bas (VTB): head level display.
# Basically it is a bit like the Fire Control Radar in the F-16: https://github.com/NikolaiVChr/f16/wiki/FCR
#
# Measurements from ac-model 2000-5:
#	* height (y) = top: -0.075 bottom: -0.159 = 84 mm, middle = -0.117
#	* width (z)	= left: 0.060 right: -0.060 = 120 mm, middle = 0.0
#	* depth (x) -3.305 (bottom of front), -3.268 (top of front)
#
# From measurements of cockpit pictures it looks like the screen width/height is ca. 75% of an MFD.
#
# Looking at photos it looks like a 4:3 screen ration - but given the total geometry of the box
# 16:10 is used - some of it covered by the round corners.
#
# The main visual source for the VTM is the picture on page 71 in the following book:
# Alexandre Paringaux, Mirage 2000-5; Groupe de chasse 1/2 Cigognes. Zéphyr.
#


print("*** LOADING vtm.nas ... ***");

# It is basically a black and green screen.
var COLOR_BACKGROUND = [0,0.02,0]; # almost black with a bit of green
var COLOR_FOREGROUND = [0.75,1,0.25]; # between yellow and green with some white
var COLOR_RADAR = [0,1,0]; # green

var SCREEN_WIDTH = 1228;
var SCREEN_HEIGHT = 768;

# The main dimensions and corners of the screen.
# x=0, y=0 is in the top left corner; x increases towards right; y increases downwards
# There is a small padding around the drawable screen area, because the pilot moves the head etc.
var PADDING_TOP = 38;
var PADDING_BOTTOM = 60;
var PADDING_HORIZONTAL = 144;

# The radar view is where radar stuff gets displayed - between the 4 corners
var RADAR_VIEW_VERTICAL = SCREEN_HEIGHT - PADDING_TOP - PADDING_BOTTOM; # 768 - 38 - 60 = 670 left
var RADAR_VIEW_HORIZONTAL = SCREEN_WIDTH - 2 * PADDING_HORIZONTAL; # 1228 - 2*144 = 940 left

var CORNER_LINE_LENGTH = 75;
var LINE_WIDTH = 4;
var GRID_TICK_LENGTH = 12;

var FONT_SIZE = 36;
var FONT_SIZE_BIG = 48;
var FONT_ASPECT_RATIO = 1;
var FONT_MONO_REGULAR = "LiberationFonts/LiberationMono-Regular.ttf";
var FONT_MONO_BOLD = "LiberationFonts/LiberationMono-Bold.ttf";
var TEXT_PADDING = 6; # when a text needs to be away from something else a bit

var MAX_TARGETS = 28;
var TARGET_WIDTH = 36;

var VTM = {
	new: func() {
		var vtm_obj = {parents: [VTM]};
		vtm_obj.vtm_canvas = canvas.new({
		                     "name": "vtm_canvas",
		                     "size": [SCREEN_WIDTH, SCREEN_HEIGHT],
		                     "view": [SCREEN_WIDTH, SCREEN_HEIGHT],
		                     "mipmapping": 0
		});

		vtm_obj.vtm_canvas.addPlacement({"node": "vtm_ac_object"});
		vtm_obj.vtm_canvas.setColorBackground(COLOR_BACKGROUND);

		vtm_obj.root = vtm_obj.vtm_canvas.createGroup("root");
		vtm_obj.root.setTranslation(_getCenterCoord());

		vtm_obj._createVisibleCorners();
		vtm_obj._createScreenModeGroup();
		vtm_obj._createRectangularFieldOfViewGrid();
		vtm_obj._createPPIView();
		vtm_obj._createTargets();
		vtm_obj._createStandbyText();
		vtm_obj._createRadarModesGroup();

		return vtm_obj;
	},

	# The 4 visible corners at the edges of the main screen estate
	_createVisibleCorners: func() {
		me.corners_group = me.root.createChild("group", "corners_group");
		me.corners_group.setTranslation(_getTopLeftTranslation());
		me.left_upper_corner  = me.corners_group.createChild("path", "left_upper_corner")
		                                        .setColor(COLOR_FOREGROUND)
		                                        .moveTo(PADDING_HORIZONTAL + CORNER_LINE_LENGTH,
		                                                PADDING_TOP)
		                                        .horizTo(PADDING_HORIZONTAL)
		                                        .vertTo(PADDING_TOP + CORNER_LINE_LENGTH)
		                                        .setStrokeLineWidth(LINE_WIDTH);
		me.right_upper_corner = me.corners_group.createChild("path", "right_upper_corner")
		                                        .setColor(COLOR_FOREGROUND)
		                                        .moveTo(SCREEN_WIDTH - PADDING_HORIZONTAL - CORNER_LINE_LENGTH,
		                                                PADDING_TOP)
		                                        .horizTo(SCREEN_WIDTH - PADDING_HORIZONTAL)
		                                        .vertTo(PADDING_TOP + CORNER_LINE_LENGTH)
		                                        .setStrokeLineWidth(LINE_WIDTH);
		me.left_lower_corner  = me.corners_group.createChild("path", "left_lower_corner")
		                                        .setColor(COLOR_FOREGROUND)
		                                        .moveTo(PADDING_HORIZONTAL + CORNER_LINE_LENGTH,
		                                                SCREEN_HEIGHT - PADDING_BOTTOM)
		                                        .horizTo(PADDING_HORIZONTAL)
		                                        .vertTo(SCREEN_HEIGHT - PADDING_BOTTOM - CORNER_LINE_LENGTH)
		                                        .setStrokeLineWidth(LINE_WIDTH);
		me.right_lower_corner = me.corners_group.createChild("path", "right_lower_corner")
		                                        .setColor(COLOR_FOREGROUND)
		                                        .moveTo(SCREEN_WIDTH - PADDING_HORIZONTAL - CORNER_LINE_LENGTH,
		                                                SCREEN_HEIGHT - PADDING_BOTTOM)
		                                        .horizTo(SCREEN_WIDTH - PADDING_HORIZONTAL)
		                                        .vertTo(SCREEN_HEIGHT - PADDING_BOTTOM - CORNER_LINE_LENGTH)
		                                        .setStrokeLineWidth(LINE_WIDTH);
		me.corners_group.hide();
	},

	# The text for the screen main modes: RDR (radar) and LDP (laser designation point)
	# appears at the bottom of the screen
	_createScreenModeGroup: func() {
		me.screen_mode_group = me.root.createChild("group", "screen_mode_group");
		me.screen_mode_group.setTranslation(_getTopLeftTranslation());
		me.screen_mode_rdr     = me.screen_mode_group.createChild("text", "screen_mode_rdr")
		                                             .setFontSize(FONT_SIZE, FONT_ASPECT_RATIO)
		                                             .setFont(FONT_MONO_BOLD)
		                                             .setColor(COLOR_FOREGROUND)
		                                             .setAlignment("left-top")
		                                             .setText("RDR")
		                                             .setTranslation(PADDING_HORIZONTAL + 0.5*0.25*RADAR_VIEW_HORIZONTAL,
		                                                             SCREEN_HEIGHT - PADDING_BOTTOM + TEXT_PADDING);
		me.screen_mode_ldp     = me.screen_mode_group.createChild("text", "screen_mode_ldp")
		                                             .setFontSize(FONT_SIZE, FONT_ASPECT_RATIO)
		                                             .setFont(FONT_MONO_BOLD)
		                                             .setColor(COLOR_FOREGROUND)
		                                             .setAlignment("left-top")
		                                             .setText("LDP")
		                                             .setTranslation(PADDING_HORIZONTAL + 1.5*0.25*RADAR_VIEW_HORIZONTAL,
		                                                             SCREEN_HEIGHT - PADDING_BOTTOM + TEXT_PADDING);
		me.screen_mode_rdr_box = me.screen_mode_group.createChild("path", "screen_mode_rdr_box")
		                                             .setColor(COLOR_FOREGROUND)
		                                             .rect(PADDING_HORIZONTAL + 0.4*0.25*RADAR_VIEW_HORIZONTAL,
		                                                   SCREEN_HEIGHT - PADDING_BOTTOM + 1,
		                                                   0.5*0.25*RADAR_VIEW_HORIZONTAL, 30)
		                                             .setStrokeLineWidth(LINE_WIDTH);
		me.screen_mode_ldp_box = me.screen_mode_group.createChild("path", "screen_mode_ldp_box")
		                                             .setColor(COLOR_FOREGROUND)
		                                             .rect(PADDING_HORIZONTAL + 1.4*0.25*RADAR_VIEW_HORIZONTAL,
		                                                   SCREEN_HEIGHT - PADDING_BOTTOM + 1,
		                                                   0.5*0.25*RADAR_VIEW_HORIZONTAL, 30)
		                                             .setStrokeLineWidth(LINE_WIDTH);
		me.screen_mode_ldp_box.hide();
		me.screen_mode_group.hide();
	},

	# Create the stippled grid for B-scope
	_createRectangularFieldOfViewGrid: func() {
		me.rectangular_fov_grid_group = me.root.createChild("group", "rectangular_fov_grid");
		me.rectangular_fov_grid_group.setTranslation(_getTopLeftTranslation());
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
		                                                # left
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
		                                                        PADDING_TOP + RADAR_VIEW_VERTICAL - GRID_TICK_LENGTH)
		                                                .vert(2*GRID_TICK_LENGTH)
		                                                # right
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
		                                                        PADDING_TOP + RADAR_VIEW_VERTICAL - GRID_TICK_LENGTH)
		                                                .vert(2*GRID_TICK_LENGTH)
		                                                # middle
		                                                .moveTo(PADDING_HORIZONTAL + 0.5*RADAR_VIEW_HORIZONTAL,
		                                                        PADDING_TOP + RADAR_VIEW_VERTICAL - CORNER_LINE_LENGTH - 2*GRID_TICK_LENGTH)
		                                                .vert(2*GRID_TICK_LENGTH)
		                                                .moveTo(PADDING_HORIZONTAL + 0.5*RADAR_VIEW_HORIZONTAL,
		                                                        PADDING_TOP + RADAR_VIEW_VERTICAL - GRID_TICK_LENGTH)
		                                                .vert(2*GRID_TICK_LENGTH)
		                                                .setStrokeLineWidth(LINE_WIDTH);
		me.rectangular_fov_grid_group.hide();
	},


	# Create circle sector grid for PPI view. We draw stippled lines at 30 and 60 degs to each side.
	# Because the sectors can have different angles, the circle at the top cannot be drawn fixed.
	_createPPIView: func() {
		me.ppi_fov_grid_group = me.root.createChild("group", "ppi_fov_grid");
		me.ppi_fov_grid_group.setTranslation(0, 0.5 * SCREEN_HEIGHT - PADDING_BOTTOM);

		me.ppi_circle_group = me.ppi_fov_grid_group.createChild("group", "ppi_circle_group");

		me.angle_markers = setsize([],5);
		var angle_rad = 30 * D2R;
		var circle_x = RADAR_VIEW_VERTICAL * math.sin(angle_rad);
		var circle_y = RADAR_VIEW_VERTICAL * math.cos(angle_rad);
		var dash_array = [1*GRID_TICK_LENGTH, 4*GRID_TICK_LENGTH];
		me.angle_markers[0] = me.ppi_fov_grid_group.createChild("path")
		                                           .moveTo(0, 0)
		                                           .lineTo(-circle_x, -circle_y)
		                                           .setStrokeLineWidth(LINE_WIDTH)
		                                           .setColor(COLOR_FOREGROUND)
		                                           .setStrokeDashArray(dash_array);
		me.angle_markers[1] = me.ppi_fov_grid_group.createChild("path")
		                                           .moveTo(0, 0)
		                                           .lineTo(circle_x, -circle_y)
		                                           .setStrokeLineWidth(LINE_WIDTH)
		                                           .setColor(COLOR_FOREGROUND)
		                                           .setStrokeDashArray(dash_array);
		angle_rad = 60 * D2R;
		circle_x = RADAR_VIEW_VERTICAL * math.sin(angle_rad);
		circle_y = RADAR_VIEW_VERTICAL * math.cos(angle_rad);
		me.angle_markers[2] = me.ppi_fov_grid_group.createChild("path")
		                                           .moveTo(0, 0)
		                                           .lineTo(-circle_x, -circle_y)
		                                           .setStrokeLineWidth(LINE_WIDTH)
		                                           .setColor(COLOR_FOREGROUND)
		                                           .setStrokeDashArray(dash_array);
		me.angle_markers[3] = me.ppi_fov_grid_group.createChild("path")
		                                           .moveTo(0, 0)
		                                           .lineTo(circle_x, -circle_y)
		                                           .setStrokeLineWidth(LINE_WIDTH)
		                                           .setColor(COLOR_FOREGROUND)
		                                           .setStrokeDashArray(dash_array);
		me.angle_markers[4] = me.ppi_fov_grid_group.createChild("path")
		                                           .moveTo(0, -RADAR_VIEW_VERTICAL)
		                                           .lineTo(0, -RADAR_VIEW_VERTICAL + 2*GRID_TICK_LENGTH)
		                                           .setStrokeLineWidth(LINE_WIDTH)
		                                           .setColor(COLOR_RADAR);
		me.ppi_fov_grid_group.hide();
	},


	# 3 types of targets: selected target, friend targets, foe targets.
	# The selected target (max 1) is a cross.
	# The friendly targets (given the IFF) are drawn as a filled circle.
	# Foe targets are drawn as open squares - with the opening being on the back side of the target
	_createTargets: func() {
		me.targets_group = me.root.createChild("group", "targets_group");
		me.selected_target          = me.targets_group.createChild("path", "selected_target")
		                                              .setColor(COLOR_RADAR)
		                                              .moveTo(-0.5 * TARGET_WIDTH, 0)
		                                              .horiz(TARGET_WIDTH)
		                                              .moveTo(0, -0.5 * TARGET_WIDTH)
		                                              .vert(TARGET_WIDTH)
		                                              .setStrokeLineWidth(2*LINE_WIDTH);

		me.selected_target_callsign = me.targets_group.createChild("text", "selected_target_callsign")
		                                              .setFontSize(FONT_SIZE, FONT_ASPECT_RATIO)
		                                              .setFont(FONT_MONO_BOLD)
		                                              .setColor(COLOR_RADAR)
		                                              .setAlignment("right-top")
		                                              .setText("")
		                                              .setTranslation(0.5 * RADAR_VIEW_HORIZONTAL - TEXT_PADDING,
		                                                              0.5 * RADAR_VIEW_VERTICAL + TEXT_PADDING);
		me.selected_target_callsign.enableUpdate();

		me.friend_targets = setsize([],MAX_TARGETS);
		for (var i = 0; i<MAX_TARGETS; i += 1) {
			me.friend_targets[i] = me.targets_group.createChild("path")
			                                       .setColor(COLOR_RADAR)
			                                       .circle(0.5 * TARGET_WIDTH, 0, 0)
			                                       .setStrokeLineWidth(2*LINE_WIDTH);
		}

		me.foe_targets = setsize([],MAX_TARGETS);
		for (var i = 0; i<MAX_TARGETS; i += 1) {
			me.foe_targets[i]    = me.targets_group.createChild("path")
			                                       .setColor(COLOR_RADAR)
			                                       .moveTo(-0.5 * TARGET_WIDTH, -0.5 * TARGET_WIDTH)
			                                       .vert(TARGET_WIDTH)
			                                       .moveTo(-0.5 * TARGET_WIDTH, -0.5 * TARGET_WIDTH)
			                                       .horiz(TARGET_WIDTH)
			                                       .vert(TARGET_WIDTH)
			                                       .setStrokeLineWidth(LINE_WIDTH);
		}
		me.targets_group.hide();

		# a special group for drawing a speed indicating line for targets with a minimum speed
		me.targets_speed_group = me.root.createChild("group", "targets_speed_group");
		me.targets_speeds = setsize([],MAX_TARGETS);
	},

	# When the radar goes into stand-by mode
	_createStandbyText: func () {
		me.standby_group = me.root.createChild("group", "standby_group");
		me.standby_group.setTranslation(_getTopLeftTranslation());
		me.standby_text = me.standby_group.createChild("text", "standby_text")
		                                  .setFontSize(FONT_SIZE_BIG, FONT_ASPECT_RATIO)
		                                  .setFont(FONT_MONO_BOLD)
		                                  .setColor(COLOR_RADAR)
		                                  .setAlignment("center-center")
		                                  .setText("SILENCE")
		                                  .setTranslation(PADDING_HORIZONTAL + 0.5*RADAR_VIEW_HORIZONTAL,
		                                                  PADDING_TOP + 200);
		me.standby_group.hide();
	},

	# When the radar goes into stand-by mode
	# The a-bars and the b-bars should be 0.25 to the left cf. the original in the book, but then there would not be space for the
	# root mode name plus the short name of the radar mode.
	_createRadarModesGroup: func () {
		var y_top_pos = PADDING_TOP + 10;
		me.radar_modes_group = me.root.createChild("group", "radar_range_group");
		me.radar_modes_group.setTranslation(_getTopLeftTranslation());
		me.radar_left_text  = me.radar_modes_group.createChild("text", "radar_left_text")
		                                          .setFontSize(FONT_SIZE, FONT_ASPECT_RATIO)
		                                          .setFont(FONT_MONO_BOLD)
		                                          .setColor(COLOR_RADAR)
		                                          .setAlignment("left-top")
		                                          .setText("MRF")
		                                          .setTranslation(PADDING_HORIZONTAL + 10, y_top_pos);
		me.radar_a_bars     = me.radar_modes_group.createChild("text", "radar_a_bars")
		                                          .setFontSize(FONT_SIZE, FONT_ASPECT_RATIO)
		                                          .setFont(FONT_MONO_BOLD)
		                                          .setColor(COLOR_RADAR)
		                                          .setAlignment("center-top")
		                                          .setText("A1")
		                                          .setTranslation(PADDING_HORIZONTAL + 0.375*RADAR_VIEW_HORIZONTAL, y_top_pos);
		me.radar_a_bars.enableUpdate();
		me.radar_b_bars     = me.radar_modes_group.createChild("text", "radar_b_bars")
		                                          .setFontSize(FONT_SIZE, FONT_ASPECT_RATIO)
		                                          .setFont(FONT_MONO_BOLD)
		                                          .setColor(COLOR_RADAR)
		                                          .setAlignment("right-top")
		                                          .setText("HI")
		                                          .setTranslation(PADDING_HORIZONTAL + 0.5*RADAR_VIEW_HORIZONTAL - 10, y_top_pos);
		me.radar_b_bars.enableUpdate();
		me.radar_range_text = me.radar_modes_group.createChild("text", "radar_range_text")
		                                          .setFontSize(FONT_SIZE, FONT_ASPECT_RATIO)
		                                          .setFont(FONT_MONO_BOLD)
		                                          .setColor(COLOR_RADAR)
		                                          .setAlignment("right-top")
		                                          .setText("")
		                                          .setTranslation(SCREEN_WIDTH - PADDING_HORIZONTAL - 10, y_top_pos);
		me.radar_range_text.enableUpdate();
		me.radar_modes_group.hide();
	},

	_updateTargets: func(heading_true, is_ppi) {
		var target_contacts_list = radar_system.apg68Radar.getActiveBleps();
		var i = 0;
		var has_priority = 0;
		var this_aircraft_position = geo.aircraft_position();
		var target_position = nil;
		var direct_distance_m = 0;
		var bearing_rad = 0; # from this aircraft to the target
		var relative_heading_rad = 0; # the heading of the target as seen by this aircraft with nose = North
		var screen_pos = nil;
		var max_distance_m = radar_system.apg68Radar.getRange() * NM2M;
		var max_azimuth_rad = radar_system.apg68Radar.getAzimuthRadius() * D2R;
		var target_speed_m_s = 0;

		me.targets_speed_group.removeAllChildren();
		var delta = nil;

		# walk through all existing targets as per available list
		foreach(var contact; target_contacts_list) {
			target_position = contact.getCoord();
			direct_distance_m = contact.getRangeDirect();
			bearing_rad = geo.normdeg180(this_aircraft_position.course_to(target_position) - heading_true) * D2R;
			relative_heading_rad = geo.normdeg(contact.getHeading() - heading_true) * D2R;
			if (is_ppi = 1) {
				screen_pos = _calcTargetScreenPositionPPIScope(direct_distance_m, max_distance_m, bearing_rad, max_azimuth_rad);
			} else {
				screen_pos = _calcTargetScreenPositionBScope(direct_distance_m, max_distance_m, bearing_rad, max_azimuth_rad);
			}

			me.friend_targets[i].hide(); # currently we do not know the friends
			if (contact.equalsFast(radar_system.apg68Radar.getPriorityTarget())) {
				has_priority = 1;
				me.selected_target.setTranslation(screen_pos[0], screen_pos[1]);
				me.selected_target_callsign.updateText(contact.getCallsign());
				me.foe_targets[i].hide();
			} else {
				me.foe_targets[i].setRotation(relative_heading_rad);
				me.foe_targets[i].setTranslation(screen_pos[0], screen_pos[1]);
				me.foe_targets[i].show();
			}

			# Draw a line from the target to indicate the speed - only if faster than 50 kt, ca 25 m/s
			# Based on the pict from the book the selected target does not get a line, here we do
			target_speed_m_s = contact.get_Speed() * KT2MPS;
			if (target_speed_m_s > 25) {
				delta = _calcTargetSpeedIndication(target_speed_m_s, relative_heading_rad);
				me.targets_speeds[i] = me.targets_speed_group.createChild("path")
				                                             .setColor(COLOR_RADAR)
				                                             .moveTo(screen_pos[0] + delta[0], screen_pos[1] - delta[1])
				                                             .lineTo(screen_pos[0] + delta[2], screen_pos[1] - delta[3])
				                                             .setStrokeLineWidth(LINE_WIDTH);
				me.targets_speeds[i].update(); # because targets_speed_group children get deleted in next frame
			}

			i += 1;
		}
		# handle the index positions if the target list was shorter than the reserved elements
		for (var j = i; j < MAX_TARGETS; j += 1) {
			me.friend_targets[j].hide();
			me.foe_targets[j].hide();
		}
		me.selected_target.setVisible(has_priority);
		me.selected_target_callsign.setVisible(has_priority);
	},

	_updateRadarTexts: func(radar_mode_root_name, radar_mode_name) {
		# this is fictional based on radar2.nas->radar_mode_toggle(). In the real screen it reads e.g. "MRF"
		me.radar_left_text.setText(radar_mode_root_name~"-"~radar_mode_name);

		# This is fictional based on interpretation of display_system.nas in the F16
		# The azimuth is only to one side - i.e. az=40 means plus/minus 40 -> 80 degrees
		var max_azimuth_deg = radar_system.apg68Radar.getAzimuthRadius();
		var az_text = "A0"; # does not exist
		if (max_azimuth_deg < 20) {
			az_text = "A1";
		} elsif (max_azimuth_deg < 30) {
			az_text = "A2";
		} elsif (max_azimuth_deg < 40) {
			az_text = "A3";
		} elsif (max_azimuth_deg < 50) {
			az_text = "A4";
		} elsif (max_azimuth_deg < 60) {
			az_text = "A5";
		} elsif (max_azimuth_deg < 70) {
			az_text = "A6";
		}
		me.radar_a_bars.setText(az_text);

		me.radar_b_bars.setText(radar_system.apg68Radar.getBars()~"B");

		me.radar_range_text.setText(radar_system.apg68Radar.getRange());
	},

	_updatePPICircle: func(max_azimuth_rad) {
		me.ppi_circle_group.removeAllChildren();
		var circle_x = RADAR_VIEW_VERTICAL * math.sin(max_azimuth_rad);
		var circle_y = RADAR_VIEW_VERTICAL * math.cos(max_azimuth_rad);

		var ppi_circle = me.ppi_circle_group.createChild("path")
		                                    .moveTo(-circle_x, -circle_y)
		                                    .arcSmallCW(RADAR_VIEW_VERTICAL, RADAR_VIEW_VERTICAL, 0, 2*circle_x, 0)
		                                    .setStrokeLineWidth(LINE_WIDTH)
		                                    .setColor(COLOR_RADAR);
		ppi_circle.update();
	},

	update: func() {
		var global_visible = 0;
		var radar_voltage = props.globals.getNode("/systems/electrical/outputs/radar").getValue();
		var heading_true = props.globals.getNode("/orientation/heading-deg").getValue();
		if (radar_voltage != nil and radar_voltage >= 23) {
			global_visible = 1;
		}
		me.corners_group.setVisible(global_visible);
		me.screen_mode_group.setVisible(global_visible);
		me.radar_modes_group.setVisible(global_visible);

		var is_ppi = 0;
		if (global_visible == 1) {
			var max_azimuth_rad = radar_system.apg68Radar.getAzimuthRadius() * D2R;
			var radar_mode_root_name = radar_system.apg68Radar.currentMode.rootName;
			var radar_mode_name = radar_system.apg68Radar.getMode();
			if (radar_mode_root_name == 'SEA' or radar_mode_root_name == 'GM' or radar_mode_root_name == 'GMT') {
				is_ppi = 1;
				me.ppi_fov_grid_group.setVisible(1);
				me._updatePPICircle(max_azimuth_rad);
				me.rectangular_fov_grid_group.setVisible(0);
			} else {
				me.ppi_fov_grid_group.setVisible(0);
				me.rectangular_fov_grid_group.setVisible(1);
			}
			me._updateRadarTexts(radar_mode_root_name, radar_mode_name);
		} else {
			me.ppi_fov_grid_group.setVisible(0);
			me.rectangular_fov_grid_group.setVisible(0);
		}

		if (global_visible == 0) {
			me.standby_group.setVisible(global_visible);
			me.targets_group.setVisible(global_visible);
		#} else if (props.globals.getNode("/instrumentation/radar/radar-standby").getBoolValue()) {
		#	me.standby_group.show();
		#	me.targets_group.hide();
		} else {
			me.standby_group.hide();
			me.targets_group.show();
			me.targets_speed_group.show();
			me._updateTargets(heading_true, is_ppi);
		}
	},
};


# Calculates the relative screen position of a target in PPI-scope
# Returns the x/y position on the Canvas
var _calcTargetScreenPositionPPIScope = func(distance_m, max_distance_m, angle_rad, max_azimuth_rad) {
	var x_pos = RADAR_VIEW_VERTICAL * math.sin(angle_rad);
	var y_pos = 0.5 * RADAR_VIEW_VERTICAL - RADAR_VIEW_VERTICAL * math.cos(angle_rad);
	return [x_pos, y_pos];
};

# Calculates the relative screen position of a target in B-scope
# Returns the x/y position on the Canvas
var _calcTargetScreenPositionBScope = func(distance_m, max_distance_m, angle_rad, max_azimuth_rad) {
	var x_pos = angle_rad / max_azimuth_rad * (0.5 * RADAR_VIEW_HORIZONTAL);
	var y_pos = 0.5 * RADAR_VIEW_VERTICAL - distance_m / max_distance_m * RADAR_VIEW_VERTICAL;
	return [x_pos, y_pos];
};

# Calculates an indication of the speed and direction of a target.
# For each 100 m/s (ca. 200 kt) extra the length increases
var _calcTargetSpeedIndication = func(target_speed_m_s, relative_heading_rad) {
	# the start point
	var dist_away = 0.5 * TARGET_WIDTH;
	var x_start_delta = dist_away * math.sin(relative_heading_rad);
	var y_start_delta = dist_away * math.cos(relative_heading_rad);

	# the end point
	dist_away = dist_away + TARGET_WIDTH + math.floor(target_speed_m_s/100) * 0.5 * TARGET_WIDTH;
	var x_end_delta = dist_away * math.sin(relative_heading_rad);
	var y_end_delta = dist_away * math.cos(relative_heading_rad);
	return [x_start_delta, y_start_delta, x_end_delta, y_end_delta];
};

# assuming a x/y coordinate system with x towards left and y towards up
# calculate a new direct_distance and bearing 1 minute away
# not suitable for B-scope
var _calcTargetOneMinute = func(speed_m_s, relative_heading_rad, direct_distance_m, bearing_rad) {
	var dist_away = speed_m_s * 60;
	var x_new = direct_distance_m * math.sin(bearing_rad) + dist_away * math.sin(relative_heading_rad);
	var y_new = direct_distance_m * math.cos(bearing_rad) + dist_away * math.cos(relative_heading_rad);
	if (y_new == 0) {
		y_new = 0.001;
	}
	var new_angle = 90 - math.atan2(x_new, y_new) * R2D;
	var new_dist = math.sqrt(x_new * x_new + y_new * y_new);
	return [new_dist, new_angle];
};

# the absolute coordinate from top left to screen middle
var _getCenterCoord = func() {
	return [0.5 * SCREEN_WIDTH, 0.5 * SCREEN_HEIGHT];
};

# get the translation from the center of screen coordinates to top left
var _getTopLeftTranslation = func() {
	return [-0.5 * SCREEN_WIDTH, -0.5 * SCREEN_HEIGHT];
};
