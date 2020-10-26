#print("Test Canvas");

var showLoadDialog = func{
var (width,height) = (805,420);
var title = 'Mirage 2000 fuel selector :';
 
# create a new window, dimensions are WIDTH x HEIGHT, using the dialog decoration (i.e. titlebar)
var window = canvas.Window.new([width,height],"dialog").set('title',title);
 
# adding a canvas to the new window and setting up background colors/transparency
var myCanvas = window.createCanvas().set("background", canvas.style.getColor("bg_color"));
 
# creating the top-level/root group which will contain all other elements/group
var root = myCanvas.createGroup();
 
# create a new layout for the dialog:
var mainVBox = canvas.VBoxLayout.new();
# assign the layout to the Canvas

myCanvas.setLayout(mainVBox);

var pylonsMap = canvas.gui.widgets.Label.new(root, canvas.style, {} )
	.setImage("Aircraft/Mirage-2000/Dialogs/tanks_base.png")
	.setFixedSize(600,400); # image dimensions
mainVBox.addItem(pylonsMap);



var statusbar =canvas.HBoxLayout.new();
mainVBox.addItem(statusbar);

var version=canvas.gui.widgets.Label.new(root, canvas.style, {wordWrap: 0});
version.setText("FlightGear v" ~ getprop("/sim/version/flightgear"));
statusbar.addItem(version);


}

# canvas.showLoadDialog();
