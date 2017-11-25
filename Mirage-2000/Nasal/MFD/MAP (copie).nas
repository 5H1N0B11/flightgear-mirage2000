print("*** LOADING MAP.nas ... ***");
var zoom  = 10;
var width = 768;
var height = 576; 

var rightMFDcanvas = {
  canvas_settings: {
      "name": "PFD-Test",   # The name is optional but allow for easier identification
      "size": [1024, 1024], # Size of the underlying texture (should be a power of 2, required) [Resolution]
      "view": [width, height],  # Virtual resolution (Defines the coordinate system of the canvas [Dimensions]
                            # which will be stretched the size of the texture, required)
      "mipmapping": 1       # Enable mipmapping (optional)
    },
    new: func(placement)
    {
      var m = {
        parents: [HUD],
        canvas: canvas.new(HUD.canvas_settings)
      };
      ##
      m.canvas.addPlacement(placement);
      m.root = my_canvas.createGroup();
      
      #MAP stuff
      m.g_front = m.root.createChild("group");
      m.g_back = m.root.createChild("group");
      
      #Aircraft orientation/position stuff
      m.myHeadingProp = props.globals.getNode("orientation/heading-deg");
      m.myCoord = geo.aircraft_position();
      
      #Center of the canvas
      m.root.setCenter(384,256);
      
      ##MAP stuff : Set up of the tiles
      m.tile_size = 256;
      m.num_tiles = [4, 3];
      
      m.type = "map";
      m.home =  props.globals.getNode("/sim/fg-home");
      m.maps_base = m.home.getValue() ~ '/cache/maps';

      #----------------  Make the url where to take the tiles ------------
      #Some alternative can exist
      # http://otile1.mqcdn.com/tiles/1.0.0/map
      # http://otile1.mqcdn.com/tiles/1.0.0/sat
      # (also see http://wiki.openstreetmap.org/wiki/Tile_usage_policy)
      
      #var makeUrl  = string.compileTemplate('http://{server}.mqcdn.com/tiles/1.0.0/sat/{z}/{x}/{y}.jpg');
      #var servers = ["otile1", "otile2", "otile3", "otile4"];

      
      m.makeUrl  = string.compileTemplate('http://{server}.tile.osm.org/{z}/{x}/{y}.png');
      m.servers = ["a", "b", "c"];
      m. makePath = string.compileTemplate(m.maps_base ~ '/osm-{type}/{z}/{x}/{y}.png');

      
      #Setting up red little aircraft
      m.center_tile_offset = [
          (m.num_tiles[0] - 1) / 2,
          (m.num_tiles[1] - 1) / 2
      ];
      # simple aircraft icon at current position/center of the map
      m.filename = "Aircraft/Mirage-2000/Models/Interior/Panel/Instruments/Mfd/littleaircraftRed.svg";
      m.svg_symbol = g.createChild("group");
      canvas.parsesvg(m.svg_symbol, m.filename);
      m.svg_symbol.setScale(0.05);
      
      m.svg_symbol.setTranslation((width/2)-20,height/2-45);
      
      m.myVector = svg_symbol.getBoundingBox();
      #svg_symbol.setCenter(width/2,height/2);
      m.svg_symbol.updateCenter();
      m.svg_symbol.set("z-index", 1);
      
      
      
      #MAP Stuff
      m.tiles_front = m.make_tiles(g_front);
      m.tiles_back  = m.make_tiles(g_back);

      m.use_front = 1;

      m.last_tile = [-1,-1];
      m.last_type = type;
      
      ##ETC all needed for MAP and RWR canvas  
      m.zoom = 10;
      m.update_timer = maketimer(0, m.updateTiles);
      m.changeZoom(0);
      return m;
    },
    
    make_tiles ; func (canvas_group) {
        var tiles = setsize([], me.num_tiles[0]);
        for (var x = 0; x < me.num_tiles[0]; x += 1) {
            tiles[x] = setsize([], me.num_tiles[1]);
            for (var y = 0; y < me.num_tiles[1]; y += 1) {
                tiles[x][y] = canvas_group.createChild("image", "map-tile");
            }
        }
        return tiles;
    },
    
    changeZoomMap : func(d) {
      new_zoom = math.max(2, math.min(15, me.zoom + d));
      if (new_zoom != me.zoom) {
          me.zoom = new_zoom;
          #debug.dump(zoom);
          #updateTiles();
          }
    },

    updateTiles : func() {
          me.svg_symbol.setRotation(myHeadingProp.getValue()*D2R);
          #g.setRotation(myHeadingProp.getValue()*D2R);
          me.myCoord = geo.aircraft_position();
          lat = myCoord.lat();
          lon = myCoord.lon();
        
        
          var n = math.pow(2, me.zoom);
          var offset = [
              n * ((lon + 180) / 360) - me.center_tile_offset[0],
              (1 - math.ln(math.tan(lat * math.pi/180) + 1 / math.cos(lat * math.pi/180)) / math.pi) / 2 * n - me.center_tile_offset[1]
          ];
          var tile_index = [int(offset[0]), int(offset[1])];

          var ox = tile_index[0] - offset[0];
          var oy = tile_index[1] - offset[1];
          me.g_front.setVisible(me.use_front);
          me.g_back.setVisible(!me.use_front);

          me.use_front = math.mod(me.use_front + 1, 2);

          for (var x = 0; x < me.num_tiles[0]; x += 1) {
              for (var y = 0; y < me.num_tiles[1]; y += 1) {
                  if (me.use_front) {
                      me.tiles_back[x][y].setTranslation(int((ox + x) * me.tile_size + 0.5), int((oy + y) * me.tile_size + 0.5));
                      #debug.dump("updating back");
                  }
                  else {
                      me.tiles_front[x][y].setTranslation(int((ox + x) * me.tile_size + 0.5), int((oy + y) * me.tile_size + 0.5));
                      #debug.dump("updating front");
                  }
              }
          }

          if (tile_index[0] != last_tile[0] or tile_index[1] != last_tile[1] or type != last_type) {
              for (var x = 0; x < me.num_tiles[0]; x += 1) {
                  for (var y = 0; y < me.num_tiles[1]; y += 1) {
                      var server_index = math.round(rand() * (size(me.servers) - 1));
                      var server_name = servers[server_index];
                      var pos = {
                          z: me.zoom,
                          x: int(offset[0] + x),
                          y: int(offset[1] + y),
                          type: me.type,
                          server: server_name
                      };
                      
                      (func {
                          var img_path = makePath(pos);

                          if (io.stat(img_path) == nil) {
                              var img_url = makeUrl(pos);
                              var message = "Requesting %s...";
                              #printf(message, img_url);
                              http.save(img_url, img_path)
                                  .done(func {
                                      var message = "Received image %s";
                                      #printf(message, img_path);
      #                                if (pos.z == zoom) {
      #                                    tile.setFile(img_path);
      #                                }
                                  })
                                  .fail(func (r) {
                                      var message = "Failed to get image %s %s: %s";
                                      #printf(message, img_path, r.status, r.reason);
                                      me.tiles_back[x][y].setFile("");
                                      me.tiles_front[x][y].setFile("");
                                  });
                          }
                          else {
                              if (pos.z == me.zoom) {
                                  var message = "Loading %s";
                                  #printf(message, img_path);
                                  me.tiles_back[x][y].setFile(img_path);
                                  me.tiles_front[x][y].setFile(img_path);
                              }
                          }
                      })();
                  }
              }
              
              me.last_tile = tile_index;
              me.last_type = type;
          }
      },
    
    
    
    
    updade : func()
    {
      #Whatever need to be updated
      
      me.update_timer.start();
      
    },
    #Other function like zoom in/out changing tile index, etc
};
#var myRightMfd = mirage2000.rightMFDcanvas.new({"node": "canvasCadre", "texture": "canvasTex.png"});













#Very ugly canvas. We need an OOP one (being writted above)

var changeZoomMap = func(d) {
    new_zoom = math.max(2, math.min(15, zoom + d));
    if (new_zoom != zoom) {
        zoom = new_zoom;
        #debug.dump(zoom);
        #updateTiles();
    }
}


var createMap = func {
    
  
    var my_canvas = canvas.new({
      "name": "PFD-Test",   # The name is optional but allow for easier identification
      "size": [1024, 1024], # Size of the underlying texture (should be a power of 2, required) [Resolution]
      "view": [width, height],  # Virtual resolution (Defines the coordinate system of the canvas [Dimensions]
                            # which will be stretched the size of the texture, required)
      "mipmapping": 1       # Enable mipmapping (optional)
    });
    
    #var window = canvas.Window.new([768, 512], "dialog").set('title', "Map").set("mipmap", 1);
    
    #We put this like that but this shouldn't be the way to write it
    my_canvas.addPlacement({"node": "canvasCadre", "texture": "canvasTex.png"});
    
    var g = my_canvas.createGroup();    
    
    var g_front = g.createChild("group");
    var g_back = g.createChild("group");
    
    var myHeadingProp = props.globals.getNode("orientation/heading-deg");
    var myCoord = geo.aircraft_position();
    
    g.setCenter(384,256);
    #g.setRotation(180*D2R);
    

    var tile_size = 256;
    var num_tiles = [4, 3];

    # Simple user interface (Buttons for zoom and label for displaying it)
    #var zoom = 10;
    var type = "map";

    var lat = myCoord.lat();
    var lon = myCoord.lon();

    var ui_root = my_canvas.createGroup();
    var vbox = canvas.VBoxLayout.new();
    my_canvas.setLayout(vbox);

#     var button_in = canvas.gui.widgets.Button.new(ui_root, canvas.style, {})
#       .setText("+")
#       .listen("clicked", func changeZoom(1));
#     var button_out = canvas.gui.widgets.Button.new(ui_root, canvas.style, {})
#       .setText("-")
#       .listen("clicked", func changeZoom(-1));
#     var button_center = canvas.gui.widgets.Button.new(ui_root, canvas.style, {})
#       .setText("center")
#       .listen("clicked", func {
#         lat = getprop('/position/latitude-deg');
#         lon = getprop('/position/longitude-deg');
#         updateTiles();
#       });
# 
#     button_in.setSizeHint([32, 32]);
#     button_out.setSizeHint([32, 32]);
#     button_center.setSizeHint([80, 32]);
# 
#     var button_box = canvas.HBoxLayout.new();
#     button_box.setContentsMargin(6);
#     button_box.addItem(button_in);
#     button_box.addItem(button_out);
#     button_box.addItem(button_center);
#     button_box.addStretch(1);
# 
#     vbox.addItem(button_box);
#     vbox.addStretch(1);

    var changeZoom = func(d) {
        new_zoom = math.max(2, math.min(15, zoom + d));
        if (new_zoom != zoom) {
            zoom = new_zoom;
            #debug.dump(zoom);
            updateTiles();
        }
    }

    #Zoom/Unzoom on map : Do not work on 3D canvas
    g.addEventListener("wheel", func(e) {
        changeZoom(e.deltaY);
    });

    var drag_x = 0;
    var drag_y = 0;
    var orig_lon = lon;
    var orig_lat = lat;

    # on map : Do not work on 3D canvas
    g.addEventListener("mousedown", func(e) {
        if (e.button == 0) {
            drag_x = e.localX;
            drag_y = e.localY;
            orig_lon = lon;
            orig_lat = lat;
        }
    });
    #drag on map : Do not work on 3D canvas
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
    var filename = "Aircraft/Mirage-2000/Models/Interior/Panel/Instruments/Mfd/littleaircraftRed.svg";
    var svg_symbol = g.createChild("group");
    canvas.parsesvg(svg_symbol, filename);
    svg_symbol.setScale(0.05);
    
    svg_symbol.setTranslation((width/2)-20,height/2-45);
    
    var myVector = svg_symbol.getBoundingBox();
    #svg_symbol.setCenter(width/2,height/2);
    svg_symbol.updateCenter();
    svg_symbol.set("z-index", 1);
    
    
    
#     g.createChild("path")
#         .moveTo(tile_size * center_tile_offset[0] - 10,
#                 tile_size * center_tile_offset[1])
#         .horiz(20)
#         .move(-10,-10)
#         .vert(20)
#         .set("stroke", "red")
#         .set("stroke-width", 2)
#         .set("z-index", 1);

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
        svg_symbol.setRotation(myHeadingProp.getValue()*D2R);
        #g.setRotation(myHeadingProp.getValue()*D2R);
        myCoord = geo.aircraft_position();
        lat = myCoord.lat();
        lon = myCoord.lon();
      
      
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
        #debug.dump(use_front);

        for (var x = 0; x < num_tiles[0]; x += 1) {
            for (var y = 0; y < num_tiles[1]; y += 1) {
                if (use_front) {
                    tiles_back[x][y].setTranslation(int((ox + x) * tile_size + 0.5), int((oy + y) * tile_size + 0.5));
                    #debug.dump("updating back");
                }
                else {
                    tiles_front[x][y].setTranslation(int((ox + x) * tile_size + 0.5), int((oy + y) * tile_size + 0.5));
                    #debug.dump("updating front");
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
                            #printf(message, img_url);
                            http.save(img_url, img_path)
                                .done(func {
                                    var message = "Received image %s";
                                    #printf(message, img_path);
    #                                if (pos.z == zoom) {
    #                                    tile.setFile(img_path);
    #                                }
                                })
                                .fail(func (r) {
                                    var message = "Failed to get image %s %s: %s";
                                    #printf(message, img_path, r.status, r.reason);
                                    tiles_back[x][y].setFile("");
                                    tiles_front[x][y].setFile("");
                                });
                        }
                        else {
                            if (pos.z == zoom) {
                                var message = "Loading %s";
                                #printf(message, img_path);
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

    var update_timer = maketimer(0, updateTiles);
    update_timer.start();

    changeZoom(0);

    #window.del = func {
    #    debug.dump("cleaning up window");
    #    update_timer.stop();
        #call(canvas.Window.del, [], me);
    #};
}

#createMap();
