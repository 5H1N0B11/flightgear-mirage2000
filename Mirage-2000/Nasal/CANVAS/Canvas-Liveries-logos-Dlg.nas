# Test prototype
#This needs to be done in OOP : The idea is to implement 3 scollArea in the same window
#more commented and be cleaned
#Need to add the multiplay variable in order to display it (not revelvant for liveries for it is for logos


#         #   #Scaning for livery
#         Livery_dir = "Aircraft/Mirage-2000/Models/Liveries"; # livery path
#         var Properties_tree_name =  "/sim/model/livery/name";
#         var Properties_tree_name_MP = "sim/multiplay/model/livery";


var OverlaySelector = {    
  new: func(title, dir, nameprop, sortprop = nil, mpprop = nil, callback = nil) {

    
    
        var m = { parents : [OverlaySelector] };

        # resolve the path in FG_ROOT, and --fg-aircraft dir, etc
        m.dir = resolvepath(dir) ~ "/";

        m.relpath = func(p) substr(p, p[0] == `/`);
        m.nameprop = m.relpath(nameprop);
        m.sortprop = m.relpath(sortprop or nameprop);
        m.mpprop = mpprop;
        m.callback = callback;
        m.title = title;
        m.dialog_name = title;
        
        #Saving current livery
        if (m.mpprop != nil)
            aircraft.data.add(m.nameprop);
        
        
                #read the property of the xml file above and put it into the props.globals
        #io.read_properties(me.data[me.current][3], props.globals); #index is 2 

        ###################### The example bellow is working ##############

        # Number of items to display
        m.num_items = size(m.scan(m.dir));
        # Define window width and height
        (m.winwidth,m.winheight) = (500,(30*0.5*m.num_items));
        # Initialize window variable
        m.CtrlListWin = nil;
        m.ListScroll = nil;
        m.SampleList = [];

 
        
        
        
        
        # need to reinit again, whenever the GUI is reloaded
        #m.reinit_listener = setlistener("/sim/signals/reinit-gui", func(n) m.reinit());
        return m;
    },
    
    InitList : func() {
      me.list = ["Test List"];
      for(var i = 1; i < (me.num_items+1); i +=1) {   
          append(me.list, [i, nil]);
      }   
      me.SampleList = me.list;
    },
    
    InitWindow : func() {
      #### Bellow : still under conversion
#####################################################       
      me.CtrlListWin = canvas.Window
          .new([me.winwidth,me.winheight],"dialog")
          .set('title','Controller Assignments');

      me.CtrlListWin.del = func() {
          call(canvas.Window.del, [], me);
          #Reset window variable
          CtrlListWin = nil;
      };
###########################################################
      me.CtrlListWinCanvas = me.CtrlListWin.createCanvas()
          .set("background", "#A9A9A9");
      me.WinRoot = me.CtrlListWinCanvas.createGroup();
        
      # Create a vbox as parent to the scroll area
      me.list_vbox = canvas.VBoxLayout.new();
      # Add vbox to the main window
      me.CtrlListWin.setLayout(me.list_vbox);
      # Create scroll area as a child of the root group
      me.scrollarea = canvas.gui.widgets.ScrollArea.new(me.WinRoot, canvas.style, {size: [me.winwidth, me.winheight]}).move(20, 100);
      # Add scroll area to the vbox
      me.list_vbox.addItem(me.scrollarea, 1);
      # Add content item to the scroll area, with style information
      me.scrollarea_content = me.scrollarea.getContent()
              .set("font", "LiberationFonts/LiberationSans-Bold.ttf")
              .set("character-size", 16)
              .set("alignment", "left-center");
      # Add vbox item as child to the scroll area
      me.list = canvas.VBoxLayout.new();
      me.scrollarea.setLayout(me.list);
      # Add title text
      me.label = canvas.gui.widgets.Label.new(me.scrollarea_content, canvas.style, {wordWrap: 0})
                      .setText(" "~me.SampleList[0]);
      me.list.addItem(me.label);
      #print(size(SampleList));
      
      me._makeListener_button = func(i) {
          return func {
              #debug testing property
              #print(SampleList[i][1]._checkable);
              #setting up the last livery button
              me.SampleList[me.selected_Item(me.data_liveries)][1]._down = 0 ;
              me.SampleList[me.selected_Item(me.data_liveries)][1]._onStateChange();
              
              #setting down the new livery button
              me.SampleList[i][1]._down = 1 ;
              #writing into the property tree
              io.read_properties(me.data_liveries[i][2], props.globals);
              #debug testing what has been choosen
              #print("Selected livery : n°" ~ i ~ " : " ~ data_liveries[i][0]);
          };
      }
      

      
      me.data_liveries = me.scan(me.dir); 
      
      # Add vector items to the scroll area content item
      for(var i=1; i < size(me.SampleList) - 1; i+=1) {
          
          #create a line that will contain all we need
          me.row = canvas.HBoxLayout.new();

            
          #adding the row to the scroll List
          me.list.addItem(me.row);
        
          # Add a simple label...
          me.SampleList[i][0] = canvas.gui.widgets.Label.new(me.scrollarea_content, canvas.style, {})
                      .setFixedSize(220,220)
                      .setImage("Aircraft/Mirage-2000/Models/"~me.data_liveries[i][3]);
          
                      
          #Adding image to the row
          me.row.addItem(me.SampleList[i][0]);
          
          # Add a simple button...
          me.SampleList[i][1] = canvas.gui.widgets.Button.new(me.scrollarea_content, canvas.style, {checkable:1})
                      .setText(me.data_liveries[i][0])
                      .setFixedSize(220,220)
                      .listen("clicked", me._makeListener_button(i));
          #Making it checkable
          me.SampleList[i][1]._checkable = 1;            
          me.row.addItem(me.SampleList[i][1]);
          me.row.addSpacing(5);
          
          #coloration of row
          if(me.selected_Item(me.data_liveries) == i){
              me.SampleList[i][1]._down = 1 ;
              me.SampleList[i][1]._onStateChange();
              me.SampleList[i][0]._down=1;
              me.SampleList[i][0]._onStateChange();
          #print("Selected livery : n°" ~ i ~ " : " ~ data_liveries[i][0]);
          }
          
      }
        
    },
    scan : func(dir){
        me.data = [];
        # put an array with files
        me.files = directory(dir);
        #If empty just return en empty []
        if (size(me.files)) {
            #Lokking for each files
            foreach (var file; me.files) {
                #print(file);
                if (substr(file, -4) != ".xml")
                    continue;
                #reading the file
                me.n = io.read_properties(dir ~ file);
                #props.dump(n);
                #print(file);
                #This need to be in variable.
                me.IOXML = io.readxml(dir ~ file);
                me.name = me.IOXML.getNode("/PropertyList/sim/model/livery/name",1).getValue();
                me.pathPng = me.IOXML.getNode("/PropertyList/sim/model/livery/texture",1).getValue();
                me.logoName = me.IOXML.getNode("/PropertyList/sim/model/logos/name",1).getValue();
                
                #print(name);
                #print(pathPng);
                #print(logoName);
                
                #props.dump(toto); # dump data
                #var name = nameNode.getValue(); # n.getNode(nameprop, 1).getValue();
                me.index = me.n.getNode("name", 1).getValue();
                #var pathPng = pathPngNode.getValue();
                #var logoName = logoNameNode.getValue();
                if (me.name == nil)# or index == nil)
                    continue;
                #adding what we want to the array
                append(me.data, [me.name, substr(file, 0, size(file) - 4), me.dir ~ file,me.pathPng,me.logoName]);
            }
            #sorting it by name
            data = sort(me.data, func(a, b) num(a[0]) == nil or num(b[0]) == nil
                   ? cmp(a[0], b[0]) : a[0] - b[0]);
        }
        return data
      },
      selected_Item : func(data_liveries){
        # finding the current selection
        for(var i=1; i < size(me.data_liveries) - 1; i+=1) {
          if(me.data_liveries[i][0] == getprop(me.nameprop)){
            return i;
          }
        }
      },
};      
      



# canvas.showLoadDialog();





# Window toggling function
var showLiveryDialog = func() {
   if(livery_dialog.CtrlListWin == nil) {
      # Initialize list
      livery_dialog.InitList();
      # Call window initialization function
      livery_dialog.InitWindow();
   }
   else {
      livery_dialog.CtrlListWin.del();
      # Reset window variable
      livery_dialog.CtrlListWin = nil;
   }
}

# 
#         Livery_dir = "Aircraft/Mirage-2000/Models/Liveries"; # livery path
#         var Properties_tree_name =  "/sim/model/livery/name";
#         var Properties_tree_name_MP = "sim/multiplay/model/livery";
        
        
var livery_dialog = OverlaySelector.new("Select Livery", "/Aircraft/Mirage-2000/Models/Liveries/", "/sim/model/livery/name", nil, "sim/multiplay/model/livery");
