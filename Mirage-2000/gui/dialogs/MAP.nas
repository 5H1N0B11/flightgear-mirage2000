print("*** LOADING MAP.nas ... ***");
#var mapType = ["osm", "map", "sat"];
var mapType = ["osm", "sat"];
var index = 0;

var changeindex = func() {
    index += 1;
    index = (index > size(mapType) - 1) ? 0 : index;
    print(index);
}

var initMAP = func() {
    var (width,height) = (768, 512);
    var tile_size = 256;

    # Simple user interface (Buttons for zoom and label for displaying it)
    var zoom = 10;
    var type = mapType[index];

    var window = canvas.Window.new([width, height],"dialog").set('title', "Tile map demo");
    var g = window.getCanvas(1).createGroup();

    var ui_root = window.getCanvas().createGroup();
    var vbox = canvas.VBoxLayout.new();
    window.setLayout(vbox);

    var button_in = canvas.gui.widgets.Button.new(ui_root, canvas.style, {})
        .setText("+")
        .listen("clicked", func() { changeZoom(1) });
    var button_out = canvas.gui.widgets.Button.new(ui_root, canvas.style, {})
        .setText("-")
        .listen("clicked", func() { changeZoom(-1) });
    button_in.setSizeHint([32, 32]);
    button_out.setSizeHint([32, 32]);

    var label_zoom = canvas.gui.widgets.Label.new(ui_root, canvas.style, {});

    var button_box = canvas.HBoxLayout.new();
    button_box.addItem(button_in);
    button_box.addItem(label_zoom);
    button_box.addItem(button_out);
    button_box.addStretch(1);

    vbox.addItem(button_box);
    vbox.addStretch(1);

    var changeZoom = func(d) {
        zoom = math.max(2, math.min(19, zoom + d));
        label_zoom.setText("Zoom " ~ zoom);
        updateTiles();
    }

    # http://polymaps.org/docs/
    # https://github.com/simplegeo/polymaps
    # https://github.com/Leaflet/Leaflet

    var maps_base = getprop("/sim/fg-home") ~ '/cache/maps';

    # http://otile1.mqcdn.com/tiles/1.0.0/map
    # http://otile1.mqcdn.com/tiles/1.0.0/sat
    # (also see http://wiki.openstreetmap.org/wiki/Tile_usage_policy)
    var makeUrl = string.compileTemplate('http://otile1.mqcdn.com/tiles/1.0.0/{type}/{z}/{x}/{y}.jpg');
    var makePath = string.compileTemplate(maps_base ~ '/osm-{type}/{z}/{x}/{y}.jpg');
    var num_tiles = [4, 3];

    var center_tile_offset = [
        (num_tiles[0] - 1) / 2,
        (num_tiles[1] - 1) / 2
    ];

    # simple aircraft icon at current position/center of the map
    g.createChild("path")
     .moveTo(tile_size * center_tile_offset[0] - 10, tile_size * center_tile_offset[1])
     .horiz(20)
     .move(-10,-10)
     .vert(20)
     .set("stroke", "red")
     .set("stroke-width", 2)
     .set("z-index", 1);

    ##
    # initialize the map by setting up
    # a grid of raster images  
    var tiles = setsize([], num_tiles[0]);
    for(var x = 0; x < num_tiles[0]; x += 1)
    {
        tiles[x] = setsize([], num_tiles[1]);
        for(var y = 0; y < num_tiles[1]; y += 1)
        {
            tiles[x][y] = g.createChild("image", "map-tile");
        }
    }

    var last_tile = [-1,-1];
    var last_type = type;

    ##
    # this is the callback that will be regularly called by the timer
    # to update the map
    var updateTiles = func() {
        # get current position
        var lat = getprop('/position/latitude-deg');
        var lon = getprop('/position/longitude-deg');

        var n = math.pow(2, zoom);
        var offset = [
            n * ((lon + 180) / 360) - center_tile_offset[0],
            (1 - math.ln(math.tan(lat * math.pi/180) + 1 / math.cos(lat * math.pi/180)) / math.pi) / 2 * n - center_tile_offset[1]
        ];
        var tile_index = [int(offset[0]), int(offset[1])];

        var ox = tile_index[0] - offset[0];
        var oy = tile_index[1] - offset[1];

        for(var x = 0; x < num_tiles[0]; x += 1)
        {
            for(var y = 0; y < num_tiles[1]; y += 1)
            {
                tiles[x][y].setTranslation(int((ox + x) * tile_size + 0.5), int((oy + y) * tile_size + 0.5));
            }
        }
        if(tile_index[0] != last_tile[0]
            or tile_index[1] != last_tile[1]
            or type != last_type)
        {
            for(var x = 0; x < num_tiles[0]; x += 1)
            {
                for(var y = 0; y < num_tiles[1]; y += 1)
                {
                    var pos = {
                        z: zoom,
                        x: int(offset[0] + x),
                        y: int(offset[1] + y),
                        type: type
                    };
                    (func() {
                        var img_path = makePath(pos);
                        var tile = tiles[x][y];
                        if(io.stat(img_path) == nil)
                        {
                            # image not found, save in $FG_HOME
                            var img_url = makeUrl(pos);
                            print('requesting ' ~ img_url);
                            http.save(img_url, img_path)
                                .done(func() { print('received image ' ~ img_path); tile.set("src", img_path);})
                                .fail(func(r) { print('Failed to get image ' ~ img_path ~ ' ' ~ r.status ~ ': ' ~ r.reason)});
                        }
                        else
                        {
                            # cached image found, reusing
                            print('loading ' ~ img_path);
                            tile.set("src", img_path)
                        }
                    })();
                }
                last_tile = tile_index;
                last_type = type;
            }
        }
    };

    ##
    # set up a timer that will invoke updateTiles at 2-second intervals
    var update_timer = maketimer(1, updateTiles);
    # actually start the timer
    update_timer.start();

    ##
    # set up default zoom level
    changeZoom(0);
}


