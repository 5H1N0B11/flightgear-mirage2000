# Test prototype
#This needs to be done in OOP : The idea is to implement 3 scollArea in the same window
#more commented and be cleaned
#Need to add the multiplay variable in order to display it (not revelvant for liveries for it is for logos
var scan = func(dir){
        data = [];
        # put an array with files
        var files = directory(dir);
        #If empty just return en empty []
        if (size(files)) {
            #Lokking for each files
            foreach (var file; files) {
                #print(file);
                if (substr(file, -4) != ".xml")
                    continue;
                #reading the file
                var n = io.read_properties(dir ~ file);
                #props.dump(n);
                #print(file);
                #This need to be in variable.
                var IOXML = io.readxml(dir ~ file);
                var name = IOXML.getNode("/PropertyList/sim/model/livery/name",1).getValue();
                var pathPng = IOXML.getNode("/PropertyList/sim/model/livery/texture",1).getValue();
                var logoName = IOXML.getNode("/PropertyList/sim/model/logos/name",1).getValue();
                
                #print(name);
                #print(pathPng);
                #print(logoName);
                
                #props.dump(toto); # dump data
                #var name = nameNode.getValue(); # n.getNode(nameprop, 1).getValue();
                var index = n.getNode("name", 1).getValue();
                #var pathPng = pathPngNode.getValue();
                #var logoName = logoNameNode.getValue();
                if (name == nil)# or index == nil)
                    continue;
                #adding what we want to the array
                append(data, [name, substr(file, 0, size(file) - 4), dir ~ file,pathPng,logoName]);
            }
            #sorting it by name
            data = sort(data, func(a, b) num(a[0]) == nil or num(b[0]) == nil
                   ? cmp(a[0], b[0]) : a[0] - b[0]);
        }
        return data
}



# canvas.showLoadDialog();


#read the property of the xml file above and put it into the props.globals
#io.read_properties(me.data[me.current][3], props.globals); #index is 2 

###################### The example bellow is working ##############

#   #Scaning for livery
Livery_dir = "Aircraft/Mirage-2000/Models/Liveries"; # livery path
var Properties_tree_name =  "/sim/model/livery/name";
var Properties_tree_name_MP = "sim/multiplay/model/livery";

var dir = resolvepath(Livery_dir) ~ "/";

# Number of items to display
var num_items = size(scan(dir));
# Define window width and height
var (winwidth,winheight) = (500,(30*0.5*num_items));
# Initialize window variable
var CtrlListWin = nil;

var ListScroll = nil;

var SampleList = [];

var InitList = func() {
   var list = ["Test List"];
   for(var i = 1; i < (num_items+1); i +=1) {   
         append(list, [i, nil]);
    }   
    return list;
}

var InitWindow = func() {
   CtrlListWin = canvas.Window
      .new([winwidth,winheight],"dialog")
      .set('title','Controller Assignments');

   CtrlListWin.del = func() {
       call(canvas.Window.del, [], me);
       #Reset window variable
       CtrlListWin = nil;
   };

   var CtrlListWinCanvas = CtrlListWin.createCanvas()
      .set("background", "#A9A9A9");
   var WinRoot = CtrlListWinCanvas.createGroup();
     
   # Create a vbox as parent to the scroll area
   var list_vbox = canvas.VBoxLayout.new();
   # Add vbox to the main window
   CtrlListWin.setLayout(list_vbox);
   # Create scroll area as a child of the root group
   var scrollarea = canvas.gui.widgets.ScrollArea.new(WinRoot, canvas.style, {size: [winwidth, winheight],focus_policy:2}).move(20, 100);
   # Add scroll area to the vbox
   list_vbox.addItem(scrollarea, 1);
   # Add content item to the scroll area, with style information
   var scrollarea_content = scrollarea.getContent()
          .set("font", "LiberationFonts/LiberationSans-Bold.ttf")
          .set("character-size", 16)
          .set("alignment", "left-center");
   # Add vbox item as child to the scroll area
   var list = canvas.VBoxLayout.new();
   scrollarea.setLayout(list);
   # Add title text
   var label = canvas.gui.widgets.Label.new(scrollarea_content, canvas.style, {wordWrap: 0})
                  .setText(" "~SampleList[0]);
   list.addItem(label);
   #print(size(SampleList));
   
   var _makeListener_button = func(i) {
       return func {
          #debug testing property
          #print(SampleList[i][1]._checkable);
          #setting up the last livery button
          SampleList[selected_Item(data_liveries)][1]._down = 0 ;
          SampleList[selected_Item(data_liveries)][1]._onStateChange();
          
          #setting down the new livery button
          SampleList[i][1]._down = 1 ;
          #writing into the property tree
          io.read_properties(data_liveries[i][2], props.globals);
          #debug testing what has been choosen
          #print("Selected livery : n°" ~ i ~ " : " ~ data_liveries[i][0]);

       };
   }
   

   
   var data_liveries = scan(dir); 
   
   # Add vector items to the scroll area content item
   for(var i=1; i < size(SampleList) - 1; i+=1) {
      
      #create a line that will contain all we need
      var row = canvas.HBoxLayout.new();

        
      #adding the row to the scroll List
      list.addItem(row);
     
      # Add a simple label...
      SampleList[i][0] = canvas.gui.widgets.Label.new(scrollarea_content, canvas.style, {})
                  .setFixedSize(220,220)
                  .setImage("Aircraft/Mirage-2000/Models/"~data_liveries[i][3]);
      
                  
      #Adding image to the row
      row.addItem(SampleList[i][0]);
      
      # Add a simple button...
      SampleList[i][1] = canvas.gui.widgets.Button.new(scrollarea_content, canvas.style, {checkable:1})
                   .setText(data_liveries[i][0])
                   .setFixedSize(220,220)
                   .listen("clicked", _makeListener_button(i));
      #Making it checkable
      SampleList[i][1]._checkable = 1;            
      row.addItem(SampleList[i][1]);
      row.addSpacing(5);
      
      #coloration of row
      if(selected_Item(data_liveries) == i){
          SampleList[i][1]._down = 1 ;
          SampleList[i][1]._onStateChange();
          SampleList[i][0]._focused=1;
          SampleList[i][0]._onStateChange();
       #print("Selected livery : n°" ~ i ~ " : " ~ data_liveries[i][0]);
      }
      
   }
     
}

var selected_Item = func(data_liveries){
  # finding the current selection
  for(var i=1; i < size(data_liveries) - 1; i+=1) {
    if(data_liveries[i][0] == getprop(Properties_tree_name)){
      return i;
    }
  }
}

# Window toggling function
var showLiveryDialog = func() {
   if(CtrlListWin == nil) {
      # Initialize list
      SampleList = InitList();
      # Call window initialization function
      InitWindow();
   }
   else {
      CtrlListWin.del();
      # Reset window variable
      CtrlListWin = nil;
   }
}
