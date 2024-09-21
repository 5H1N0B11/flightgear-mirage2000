print("*** LOADING vtm.nas ... ***");

var colorBackground = [0,0.1,0];
var colorForeground = [0,1,0];

var VTM = {
  new: func() {
    print("*** VTM.new called");
    var vtm_obj = {parents: [VTM]};
    vtm_obj.vtm_canvas = canvas.new({
      "name": "vtm_canvas",
      "size": [1024, 768],
      "view": [1024, 768],
      "mipmapping": 1
    });

    vtm_obj.vtm_canvas.addPlacement({"node": "vtm_ac_object"});
    vtm_obj.vtm_canvas.setColorBackground(colorBackground);

    vtm_obj.group = vtm_obj.vtm_canvas.createGroup();
    vtm_obj.text = vtm_obj.group.createChild("text")
                    .setTranslation(300, 300)      # The origin is in the top left corner
                    .setAlignment("left-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
                    #.setFont("LiberationFonts/LiberationSans-Regular.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
                    .setFontSize(48, 1.2)        # Set fontsize and optionally character aspect ratio
                    .setColor(colorForeground)
                    .setText("This is a text element");

    var x_axis = vtm_obj.group.createChild("path", "x-axis")
                 .moveTo(10, 768/2)
                 .lineTo(1024-10, 768/2)
                 .setColor(1,0,0)
                 .setStrokeLineWidth(10);

    var y_axis = vtm_obj.group.createChild("path", "y-axis")
                  .moveTo(10, 10)
                  .lineTo(10, 768-10)
                  .setColor(0,0,1)
                  .setStrokeLineWidth(10);
    return vtm_obj;
  },

  update: func() {
  },
}
