print("*** LOADING vtm.nas ... ***");

var colorBackground = [30,235,30];
var colorForeground = [20,200,20];

var VTM = {
  new: func() {
    print("*** VTM.new called");
    var vtm_obj = {parents: [VTM]};
    #vtm_obj.vtm_canvas = canvas.new({
    #  "name": "vtm_canvas",
    #  "size": [768, 1024],
    #  "view": [768, 1024],
    #  "mipmapping": 1
    #});

    # vtm_obj.vtm_canvas.addPlacement({"node": "vtm_ac_object"});
    # vtm_obj.vtm_canvas.setColorBackground(colorBackground);

    print("*** VTM.new done");
    return vtm_obj;
  },

  update: func() {
  },
}
