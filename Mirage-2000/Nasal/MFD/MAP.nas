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
        parents: [rightMFDcanvas],
        canvas: canvas.new(rightMFDcanvas.canvas_settings)
      };
      ##
      m.canvas.addPlacement(placement);
      m.root = m.canvas.createGroup();
      
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
      m.makePath = string.compileTemplate(m.maps_base ~ '/osm-{type}/{z}/{x}/{y}.png');

      
      #Setting up red little aircraft
      m.center_tile_offset = [
          (m.num_tiles[0] - 1) / 2,
          (m.num_tiles[1] - 1) / 2
      ];
      # simple aircraft icon at current position/center of the map
      m.filename = "Aircraft/Mirage-2000/Models/Interior/Panel/Instruments/Mfd/littleaircraftRed.svg";
      m.svg_symbol = m.root.createChild("group");
      canvas.parsesvg(m.svg_symbol, m.filename);
      m.svg_symbol.setScale(0.05);
      
      m.svg_symbol.setTranslation((width/2)-20,height/2-45);
      
      m.myVector = m.svg_symbol.getBoundingBox();
      #svg_symbol.setCenter(width/2,height/2);
      m.svg_symbol.updateCenter();
      m.svg_symbol.set("z-index", 1);
      
      
      var make_tiles = func (canvas_group) {
          var tiles = setsize([], m.num_tiles[0]);
          for (var x = 0; x < m.num_tiles[0]; x += 1) {
              tiles[x] = setsize([], m.num_tiles[1]);
              for (var y = 0; y < m.num_tiles[1]; y += 1) {
                  tiles[x][y] = canvas_group.createChild("image", "map-tile");
              }
          }
          return tiles;
      }
      
      
      
      #MAP Stuff
      m.tiles_front = make_tiles(m.g_front);
      m.tiles_back  = make_tiles(m.g_back);

      m.use_front = 1;

      m.last_tile = [-1,-1];
      m.last_type = m.type;
      
      ##ETC all needed for MAP and RWR canvas  
      m.zoom = 10;
      m.update_timer = nil;
      
      return m;
    },
        
    changeZoomMap: func(d) {
      new_zoom = math.max(2, math.min(15, me.zoom + d));
      if (new_zoom != me.zoom) {
          me.zoom = new_zoom;
          #debug.dump(zoom);
          #updateTiles();
          }
    },

    updateTiles: func() {
          #print("updateTiles is working");
          me.svg_symbol.setRotation(me.myHeadingProp.getValue()*D2R);
          #g.setRotation(myHeadingProp.getValue()*D2R);
          me.myCoord = geo.aircraft_position();
          lat = me.myCoord.lat();
          lon = me.myCoord.lon();
        
        
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

          if (tile_index[0] != me.last_tile[0] or tile_index[1] != me.last_tile[1] or me.type != me.last_type) {
              for (var x = 0; x < me.num_tiles[0]; x += 1) {
                  for (var y = 0; y < me.num_tiles[1]; y += 1) {
                      var server_index = math.round(rand() * (size(me.servers) - 1));
                      var server_name = me.servers[server_index];
                      var pos = {
                          z: me.zoom,
                          x: int(offset[0] + x),
                          y: int(offset[1] + y),
                          type: me.type,
                          server: server_name
                      };
                      
                      (func {
                          var img_path = me.makePath(pos);

                          if (io.stat(img_path) == nil) {
                              var img_url = me.makeUrl(pos);
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
                                      me.tiles_back[x-1][y-1].setFile("");
                                      me.tiles_front[x-1][y-1].setFile("");
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
              me.last_type = me.type;
          }
      },
    
    
    
    
    update: func()
    {
      #Whatever need to be updated
      var update_timer = maketimer(0, func(){
          #print("Hello World");
          me.updateTiles();});
      update_timer.start();
      
    },
    #Other function like zoom in/out changing tile index, etc
};

var myRightMfd = mirage2000.rightMFDcanvas.new({"node": "canvasCadre", "texture": "canvasTex.png"});
myRightMfd.update();



