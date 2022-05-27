RadarRDY = {
    new: func {
        var window = canvas.Window.new([256, 256],"dialog")
                .set('x', 825)#position on screen
                .set('title', "Radar Scope");
        var root = window.getCanvas(1).createGroup();
        window.getCanvas(1).setColorBackground(0,0,0);

# Here you define the canvas elements
        

        me.loop();
    },


    
    loop: func {

# Here you Move, rotate and show the canvas elements

        settimer(func me.loop(), 0.05);
    },
};

var rdy = RadarRDY.new();
