var (width,height) = (512,512);
var ELEMENT_NAME = "viewcam";

var display_view = func(view=0) {
var title = 'Canvas test:' ~ ELEMENT_NAME;
var window = canvas.Window.new([width,height],"dialog").set('title',title);
var myCanvas = window.createCanvas().set("background", canvas.style.getColor("bg_color"));
var root = myCanvas.createGroup();

var child = root.createChild( ELEMENT_NAME );
# child.set("view-number", view);
} # display_view()


var totalViews = props.getNode("sim").getChildren("view");
var mydisplay = func () {
  forindex(var v;totalViews) { 
display_view(view: v);
}
}
