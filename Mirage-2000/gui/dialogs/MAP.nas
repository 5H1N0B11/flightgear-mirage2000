print("*** LOADING MAP.nas ... ***");
var createMap = func {
    var window = canvas.Window.new([768, 512], "dialog").set('title', "Map").set("mipmap", 1);

    var g = window.getCanvas(1).createGroup();
    var g_front = g.createChild("group");
    var g_back = g.createChild("group");

    var tile_size = 256;
    var num_tiles = [4, 3];

    # Simple user interface (Buttons for zoom and label for displaying it)
    var zoom = 10;
    var type = "map";

    var lat = getprop('/position/latitude-deg');
    var lon = getprop('/position/longitude-deg');

    var ui_root = window.getCanvas().createGroup();
    var vbox = canvas.VBoxLayout.new();
    window.setLayout(vbox);

    var button_in = canvas.gui.widgets.Button.new(ui_root, canvas.style, {})
      .setText("+")
      .listen("clicked", func changeZoom(1));
    var button_out = canvas.gui.widgets.Button.new(ui_root, canvas.style, {})
      .setText("-")
      .listen("clicked", func changeZoom(-1));
    var button_center = canvas.gui.widgets.Button.new(ui_root, canvas.style, {})
      .setText("center")
      .listen("clicked", func {
        lat = getprop('/position/latitude-deg');
        lon = getprop('/position/longitude-deg');
        updateTiles();
      });

    button_in.setSizeHint([32, 32]);
    button_out.setSizeHint([32, 32]);
    button_center.setSizeHint([80, 32]);

    var button_box = canvas.HBoxLayout.new();
    button_box.setContentsMargin(6);
    button_box.addItem(button_in);
    button_box.addItem(button_out);
    button_box.addItem(button_center);
    button_box.addStretch(1);

    vbox.addItem(button_box);
    vbox.addStretch(1);

    var changeZoom = func(d) {
        new_zoom = math.max(2, math.min(15, zoom + d));
        if (new_zoom != zoom) {
            zoom = new_zoom;
            debug.dump(zoom);
            updateTiles();
        }
    }

    g.addEventListener("wheel", func(e) {
        changeZoom(e.deltaY);
    });

    var drag_x = 0;
    var drag_y = 0;
    var orig_lon = lon;
    var orig_lat = lat;

    g.addEventListener("mousedown", func(e) {
        if (e.button == 0) {
            drag_x = e.localX;
            drag_y = e.localY;
            orig_lon = lon;
            orig_lat = lat;
        }
    });

    g.addEventListener("drag", func(e) {
        var resolution = 360.0 / math.pow(2, zoom);
        lon = orig_lon - (e.localX - drag_x) / tile_size * resolution;
        lat = orig_lat + (e.localY - drag_y) / tile_size * resolution;
        updateTiles();
    });

    var maps_base = getprop("/sim/fg-home") ~ '/cache/maps';

    # http://otile1.mqcdn.com/tiles/1.0.0/map
    # http://otile1.mqcdn.com/tiles/1.0.0/sat
    # (also see http://wiki.openstreetmap.org/wiki/Tile_usage_policy)
    var makeUrl  = string.compileTemplate('http://{server}.tile.osm.org/{z}/{x}/{y}.png');
    var servers = ["a", "b", "c"];
    #var makeUrl  = string.compileTemplate('http://{server}.mqcdn.com/tiles/1.0.0/sat/{z}/{x}/{y}.jpg');
    #var servers = ["otile1", "otile2", "otile3", "otile4"];

    var makePath = string.compileTemplate(maps_base ~ '/osm-{type}/{z}/{x}/{y}.png');

    var center_tile_offset = [
        (num_tiles[0] - 1) / 2,
        (num_tiles[1] - 1) / 2
    ];

    # simple aircraft icon at current position/center of the map
    g.createChild("path")
        .moveTo(tile_size * center_tile_offset[0] - 10,
                tile_size * center_tile_offset[1])
        .horiz(20)
        .move(-10,-10)
        .vert(20)
        .set("stroke", "red")
        .set("stroke-width", 2)
        .set("z-index", 1);

    var make_tiles = func (canvas_group) {
        var tiles = setsize([], num_tiles[0]);
        for (var x = 0; x < num_tiles[0]; x += 1) {
            tiles[x] = setsize([], num_tiles[1]);
            for (var y = 0; y < num_tiles[1]; y += 1) {
                tiles[x][y] = canvas_group.createChild("image", "map-tile");
            }
        }
        return tiles;
    };

    var tiles_front = make_tiles(g_front);
    var tiles_back  = make_tiles(g_back);

    var use_front = 1;

    var last_tile = [-1,-1];
    var last_type = type;

    var updateTiles = func() {
        var n = math.pow(2, zoom);
        var offset = [
            n * ((lon + 180) / 360) - center_tile_offset[0],
            (1 - math.ln(math.tan(lat * math.pi/180) + 1 / math.cos(lat * math.pi/180)) / math.pi) / 2 * n - center_tile_offset[1]
        ];
        var tile_index = [int(offset[0]), int(offset[1])];

        var ox = tile_index[0] - offset[0];
        var oy = tile_index[1] - offset[1];
        g_front.setVisible(use_front);
        g_back.setVisible(!use_front);

        use_front = math.mod(use_front + 1, 2);
    #    var tiles = use_front ? tiles_front : tiles_back;
    #    g_front.set("z-index", use_front + 2);
    #    g_back.set("z-index", !use_front + 2);
        debug.dump(use_front);

        for (var x = 0; x < num_tiles[0]; x += 1) {
            for (var y = 0; y < num_tiles[1]; y += 1) {
                if (use_front) {
                    tiles_back[x][y].setTranslation(int((ox + x) * tile_size + 0.5), int((oy + y) * tile_size + 0.5));
                    debug.dump("updating back");
                }
                else {
                    tiles_front[x][y].setTranslation(int((ox + x) * tile_size + 0.5), int((oy + y) * tile_size + 0.5));
                    debug.dump("updating front");
                }
            }
        }

        if (tile_index[0] != last_tile[0] or tile_index[1] != last_tile[1] or type != last_type) {
            for (var x = 0; x < num_tiles[0]; x += 1) {
                for (var y = 0; y < num_tiles[1]; y += 1) {
                    var server_index = math.round(rand() * (size(servers) - 1));
                    var server_name = servers[server_index];
                    var pos = {
                        z: zoom,
                        x: int(offset[0] + x),
                        y: int(offset[1] + y),
                        type: type,
                        server: server_name
                    };
                    
                    (func {
                        var img_path = makePath(pos);

                        if (io.stat(img_path) == nil) {
                            var img_url = makeUrl(pos);
                            var message = "Requesting %s...";
                            printf(message, img_url);
                            http.save(img_url, img_path)
                                .done(func {
                                    var message = "Received image %s";
                                    printf(message, img_path);
    #                                if (pos.z == zoom) {
    #                                    tile.setFile(img_path);
    #                                }
                                })
                                .fail(func (r) {
                                    var message = "Failed to get image %s %s: %s";
                                    printf(message, img_path, r.status, r.reason);
                                    tiles_back[x][y].setFile("");
                                    tiles_front[x][y].setFile("");
                                });
                        }
                        else {
                            if (pos.z == zoom) {
                                var message = "Loading %s";
                                printf(message, img_path);
                                tiles_back[x][y].setFile(img_path);
                                tiles_front[x][y].setFile(img_path);
                            }
                        }
                    })();
                }
            }
            
            last_tile = tile_index;
            last_type = type;
        }
    };

    var update_timer = maketimer(2, updateTiles);
    update_timer.start();

    changeZoom(0);

    window.del = func {
        debug.dump("cleaning up window");
        update_timer.stop();
        call(canvas.Window.del, [], me);
    };
}

#createMap();
