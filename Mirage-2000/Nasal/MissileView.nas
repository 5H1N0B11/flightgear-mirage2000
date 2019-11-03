print("*** LOADING MissileView.nas ... ***");
var missile_view_handler = {
  init: func(node) {
    me.viewN = node;
    me.current = nil;
    me.legendN = props.globals.initNode("/sim/current-view/missile-view", "");
    me.dialog = props.Node.new({ "dialog-name": "missile-view" });
    me.listener = nil;
  },
  start: func {
    me.listener = setlistener("/sim/signals/ai-updated", func me._update_(), 1);
    me.reset();
    fgcommand("dialog-show", me.dialog);
  },
  stop: func {
    fgcommand("dialog-close", me.dialog);
    if (me.listener!=nil)
    {
      removelistener(me.listener);
      me.listener=nil;
    }
  },
  reset: func {
    me.select(0);
  },
  find: func(callsign) {
    forindex (var i; me.list)
      if (me.list[i].callsign == callsign)
        return i;
    return nil;
  },
  select: func(which, by_callsign=0) {
    if (by_callsign or num(which) == nil)
      which = me.find(which) or 0;  # turn callsign into index

    me.setup(me.list[which]);
  },
  next: func(step) {
    #ai.model.update();
    me._update_();
    var i = me.find(me.current);
    i = i == nil ? 0 : math.mod(i + step, size(me.list));
    me.setup(me.list[i]);
  },
  _update_: func {
    var self = { callsign: getprop("/sim/multiplay/callsign"), model:,
        node: props.globals, root: '/' };
    #ai.myModel.update();
    me.list = [self] ~ myModel.get_list();
    if (!me.find(me.current))
      me.select(0);
  },
  setup: func(data) {
    var ident = '"' ~ data.callsign ~ '"';
#     var offset_heading= getprop("/sim/current-view/heading-offset-deg");
# print("Missile heading tree:" ~ data.root ~ "/orientation/true-heading-deg");
    #var load_heading = int(getprop(data.root ~ "/orientation/true-heading-deg"));
   # var myTest = load_heading>180? 540-load_heading :(180 - load_heading);
    #print("Missile heading : "~ load_heading ~" view heading offstet should be : "~ 360 - load_heading - 180 ~ " MyTest:" ~ myTest);
    
#     var offset_pitch= getprop("/sim/current-view/pitch-offset-deg");
    if (data.root == '/') {
      var zoffset = getprop("/sim/chase-distance-m");
    } else {
      var zoffset = 30;
      var load_heading = int(getprop(data.root ~ "/orientation/true-heading-deg"));
      var offset_heading = load_heading>180? 540-load_heading :(180 - load_heading);
      var offset_pitch = int(getprop(data.root ~ "/orientation/pitch-deg")) - 5;
#       print("Missile heading : "~ load_heading ~" view heading offstet should be : "~ (360 - load_heading - 180) ~ " MyTest:" ~ myTest);
      
      
      setprop("/sim/current-view/heading-offset-deg", offset_heading);
      setprop("/sim/current-view/pitch-offset-deg", offset_pitch);
      
      setprop("/sim/current-view/config/heading-offset-deg", offset_heading);
      setprop("/sim/current-view/config/pitch-offset-deg", offset_pitch);
    }

    me.current = data.callsign;
    me.legendN.setValue(ident);  

    setprop("/sim/current-view/z-offset-m", zoffset);

    
    #print("me.current:"~me.current);
    #print("data.root:"~data.root);

#      print("Missile heading treeV2:" ~ data.root ~ "/orientation/true-heading-deg");
     
    me.viewN.getNode("config").setValues({
      "root":data.root,
#       "eye-lat-deg-path": data.root ~ "/position/latitude-deg",
#       "eye-lon-deg-path": data.root ~ "/position/longitude-deg",
#       "eye-alt-ft-path": data.root ~ "/position/altitude-ft",
#       "eye-heading-deg-path": data.root ~ "/orientation/true-heading-deg",
#       "target-lat-deg-path": data.root ~ "/position/latitude-deg",
#       "target-lon-deg-path": data.root ~ "/position/longitude-deg",
#       "target-alt-ft-path": data.root ~ "/position/altitude-ft",
#       "target-heading-deg-path": data.root ~ "/orientation/true-heading-deg",
#       "target-pitch-deg-path": data.root ~ "/orientation/pitch-deg",
#       "target-roll-deg-path": data.root ~ "/orientation/roll-deg",
#       "heading-offset-deg":180
    });
  },
};

var myModel = ai.AImodel.new();
myModel.init();

view.manager.register("Missile view",missile_view_handler);

var view_firing_missile = func(myMissile)
{

    # We select the missile name
    var myMissileName = string.replace(myMissile.ai.getPath(), "/ai/models/", "");

    # We memorize the initial view number
    var actualView = getprop("/sim/current-view/view-number");
#     setprop("/sim/current-view/view-number",9);
#     setprop("/sim/current-view/view-number",actualView);

    # We recreate the data vector to feed the missile_view_handler  
    var data = { node: myMissile.ai, callsign: myMissileName, root: myMissile.ai.getPath()};

    # We activate the AI view (on this aircraft it is the number 9)
    setprop("/sim/current-view/view-number",9);
    # setprop("/sim/current-view/heading-offset-deg", 160);

    # We feed the handler
    view.missile_view_handler.setup(data);
}
var init_missile_view = func(){
  setprop("/sim/current-view/view-number",9);
  setprop("/sim/current-view/heading-offset-deg", 0);
  var timer = maketimer(3,func(){
    setprop("/sim/current-view/view-number", 0);
  });
  timer.singleShot = 1; # timer will only be run once
  timer.start();
}
