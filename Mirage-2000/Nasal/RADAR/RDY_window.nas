var RadarRDY_PPI = {
    new: func {
        var size_x = 330;
        var size_y = 256;
        me.myGreen = [0,1,0,1];
        
        var window = canvas.Window.new([size_x, size_y],"dialog")
                .set('x', size_x)#position on screen
                .set('y', size_y)
                .set('title', "Radar PPI");
        var root = window.getCanvas(1).createGroup();
        window.getCanvas(1).setColorBackground(0,0,0);
        
        
        
# Here you define the canvas elements
        me.rootCenter = root.createChild("group")
				.setTranslation(size_x/2,size_y);
        
        me.rayon = size_y-5;
        me.Circle = root.createChild("path");
        me.Circle.setStrokeLineWidth(2).set("stroke", "rgba(0,255,0,1)")
        .moveTo(size_x/2-me.rayon,size_y).arcSmallCW(me.rayon,me.rayon, 0, 2*me.rayon, 0);
        
        me.cross = root.createChild("path")
        .setColor(me.myGreen)
      .moveTo(-30, 0)
      .horiz(22)
      .moveTo(8, 0)
      .horiz(22)
      .moveTo(0, -30)
      .vert(22)
      .moveTo(0, 8)
      .vert(22)
      .setStrokeLineWidth(2);
        
        me.cross.setTranslation(150, 100);
        
        
        
#         me.test = root.createChild("path");
#         me.test.setStrokeLineWidth(4).set("stroke", "rgba(0,255,0,1)")
#           .moveTo(0,0).lineTo(100,100).lineTo(100,90);

        
          
          
          
          
#         me.rootCenterBleps = root.createChild("group")
# 				.setTranslation(size_x/2,256);
# 		me.sweepDistance = size_x/2/math.cos(30*D2R);
# 		me.sweep = me.rootCenter.createChild("path")
# 				.moveTo(0,0)
# 				.vert(-me.sweepDistance)
# 				.setStrokeLineWidth(2.5)
# 				.setColor(1,1,1);
# 		me.sweepA = me.rootCenter.createChild("path")
# 				.moveTo(0,0)
# 				.vert(-me.sweepDistance)
# 				.setStrokeLineWidth(1)
# 				.setColor(0.5,0.5,1);
# 		me.sweepB = me.rootCenter.createChild("path")
# 				.moveTo(0,0)
# 				.vert(-me.sweepDistance)
# 				.setStrokeLineWidth(1)
# 				.setColor(0.5,0.5,1);
# 		me.text = root.createChild("text")
# 	      .setAlignment("left-top")
#       	  .setFontSize(12, 1.0)
# 	      .setColor(1, 1, 1);
# 	    me.text2 = root.createChild("text")
# 	      .setAlignment("left-top")
#       	  .setFontSize(12, 1.0)
#       	  .setTranslation(0,15)
# 	      .setColor(1, 1, 1);
# 	    me.text3 = root.createChild("text")
# 	      .setAlignment("left-top")
#       	  .setFontSize(12, 1.0)
#       	  .setTranslation(0,30)
# 	      .setColor(1, 1, 1);
      root.show();
      
        me.loop();
    },


    
    loop: func {

# Here you Move, rotate and show the canvas elements
        me.rootCenter.show();
      
        settimer(func me.loop(), 0.05);
    },
};

var buttonWindow = func {
	# a test gui for radar modes
	window = canvas.Window.new([200,475],"dialog").set('title',"Radar modes");
	var myCanvas = window.createCanvas().set("background", canvas.style.getColor("bg_color"));
	var root = myCanvas.createGroup();
	var myLayout0 = canvas.HBoxLayout.new();
	var myLayout = canvas.VBoxLayout.new();
	var myLayout2 = canvas.VBoxLayout.new();
	myCanvas.setLayout(myLayout0);
	myLayout0.addItem(myLayout);
	myLayout0.addItem(myLayout2);
#	var button0 = canvas.gui.widgets.Button.new(root, canvas.style, {})
#		.setText("RWS high")
#		.setFixedSize(75, 25);
#	button0.listen("clicked", func {
#		exampleRadar.rwsHigh();
#	});
#	myLayout.addItem(button0);
	var button1 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("RWS")
		.setFixedSize(75, 25);
	button1.listen("clicked", func {
		exampleRadar.rws120();
	});
	myLayout.addItem(button1);
	var button2 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("TWS 15")
		.setFixedSize(75, 25);
	button2.listen("clicked", func {
		exampleRadar.tws15();
	});
	myLayout.addItem(button2);
	var button3 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("TWS 30")
		.setFixedSize(75, 25);
	button3.listen("clicked", func {
		exampleRadar.tws30();
	});
	myLayout.addItem(button3);
	var button4 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("TWS 60")
		.setFixedSize(75, 25);
	button4.listen("clicked", func {
		exampleRadar.tws60();
	});
	myLayout.addItem(button4);
	var button5 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Left")
		.setFixedSize(75, 25);
	button5.listen("clicked", func {
		exampleRadar.left();
	});
	myLayout.addItem(button5);
	var button6 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Right")
		.setFixedSize(75, 25);
	button6.listen("clicked", func {
		exampleRadar.right();
	});
	myLayout.addItem(button6);
	var button7 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Range+")
		.setFixedSize(75, 20);
	button7.listen("clicked", func {
		exampleRadar.more();
	});
	myLayout.addItem(button7);
	var button8 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Range-")
		.setFixedSize(75, 20);
	button8.listen("clicked", func {
		exampleRadar.less();
	});
	myLayout.addItem(button8);
	var button9 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Lock")
		.setFixedSize(75, 25);
	button9.listen("clicked", func {
		exampleRadar.lockRandom();
	});
	myLayout.addItem(button9);
	var button10 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Select|SAM")
		.setFixedSize(75, 25);
	button10.listen("clicked", func {
		exampleRadar.sam();
	});
	myLayout.addItem(button10);
	var button11 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Next")
		.setFixedSize(75, 25);
	button11.listen("clicked", func {
		exampleRadar.next();
	});
	myLayout.addItem(button11);
	var button12 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Up")
		.setFixedSize(75, 25);
	button12.listen("clicked", func {
		exampleRadar.up();
	});
	myLayout.addItem(button12);
	var button13 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Down")
		.setFixedSize(75, 25);
	button13.listen("clicked", func {
		exampleRadar.down();
	});
	myLayout.addItem(button13);
	var button14 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Level")
		.setFixedSize(75, 25);
	button14.listen("clicked", func {
		exampleRadar.level();
	});
	myLayout.addItem(button14);

	var button15b = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("1 Bar")
		.setFixedSize(75, 25);
	button15b.listen("clicked", func {
		exampleRadar.b1();
	});
	myLayout2.addItem(button15b);
	var button15 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("2 Bars")
		.setFixedSize(75, 25);
	button15.listen("clicked", func {
		exampleRadar.b2();
	});
	myLayout2.addItem(button15);
	var button16 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("4 Bars")
		.setFixedSize(75, 25);
	button16.listen("clicked", func {
		exampleRadar.b4();
	});
	myLayout2.addItem(button16);
	var button17 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("6 Bars")
		.setFixedSize(75, 25);
	button17.listen("clicked", func {
		exampleRadar.b6();
	});
	myLayout2.addItem(button17);
	var button18 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("8 Bars")
		.setFixedSize(75, 25);
	button18.listen("clicked", func {
		exampleRadar.b8();
	});
	myLayout2.addItem(button18);
	var button19 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("A1")
		.setFixedSize(75, 25);
	button19.listen("clicked", func {
		exampleRadar.a1();
	});
	myLayout2.addItem(button19);
	var button20 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("A2")
		.setFixedSize(75, 25);
	button20.listen("clicked", func {
		exampleRadar.a2();
	});
	myLayout2.addItem(button20);
	var button21 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("A3")
		.setFixedSize(75, 25);
	button21.listen("clicked", func {
		exampleRadar.a3();
	});
	myLayout2.addItem(button21);
	var button22 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("A4")
		.setFixedSize(75, 25);
	button22.listen("clicked", func {
		exampleRadar.a4();
	});
	button23 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Screens")
		.setFixedSize(75, 20);
	button23.listen("clicked", func {
		enable = !enable;
		if (enable == 0) button23.setText("Scr OFF");
		else button23.setText("Scr ON");
	});
	myLayout2.addItem(button23);
	button24 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("RWRScreen")
		.setFixedSize(75, 20);
	button24.listen("clicked", func {
		enableRWRs = !enableRWRs;
		if (enableRWRs == 0) button24.setText("RWRscr OFF");
		else button24.setText("RWRscr ON");
	});
	myLayout2.addItem(button24);
	button25 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("RWR ON")
		.setFixedSize(75, 20);
	button25.listen("clicked", func {
		enableRWR = !enableRWR;
		if (enableRWR == 0) button25.setText("RWR OFF");
		else button25.setText("RWR ON");
	});
	myLayout2.addItem(button25);
	button26 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Radar ON")
		.setFixedSize(75, 20);
	button26.listen("clicked", func {
		exampleRadar.enabled = !exampleRadar.enabled;
		if (exampleRadar.enabled == 0) button26.setText("RDR OFF");
		else button26.setText("RDR ON");
	});
	myLayout2.addItem(button26);
};

var button23 = nil;
var button24 = nil;
var button25 = nil;
var button26 = nil;




var Launch_Canvas = func (){

var my_rdy = RadarRDY_PPI.new();
var button = buttonWindow();
}

Launch_Canvas();


