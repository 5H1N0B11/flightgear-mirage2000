print("*** LOADING MP.nas ... ***");
# Here is where load and lights MP variables are decoded

### Object decode
var Decode_Load = {
    new: func(mySelf, myString, updateTime)
    {
        var m = { parents: [Decode_Load] };
        m.mySelf = mySelf;
        m.myString = myString;
        m.updateTime = updateTime;
        m.running = 1;
        m.loadList = [
            "none",
            "1300 l Droptank",
            "1700 l Droptank",
            "AGM65",
            "AIM-54",
            "aim-9",
            "AIM120",
            "GBU12",
            "GBU16",
            "Double GBU12",
            "Double GBU12_1",
            "Matra MICA",
            "MATRA-R530",
            "Matra R550 Magic 2",
            "Meteor",
            "R74",
            "R77",
            "SCALP",
            "Sea Eagle",
            "SmokePod",
            "ASMP",
            "PDLCT",
            "Matra MICA IR",
            "Exocet",
            "Matra Super 530D"
        ];
        m.weaponWeight = {
          "none":                 0,
          "GBU16":                1000,
          "GBU12":                800,
          "Double GBU12":         1600,
          "Double GBU12_1":       800,
          "PDLCT":                280,
          "Matra MICA":           246.91,
          "Matra MICA IR":        246.91,
          "Matra R550 Magic 2":   196.21,
          "ASMP":                 1850,
          "SCALP":                2866,
          "Exocet":               1460,
          "Matra Super 530D":     595.2,
          "1700 l Droptank":      280,
          "1300 l Droptank":      220
        };
        return m;
    },
    
    decode: func()
    {
        #print("Upload On going");
        var myString = me.myString.getValue();
        var myIndexArray = [];
        
        if(myString != nil)
        {
            #print("the string :"~ myString);
            #print("test" ~ me.loadList[3]);
            # Here to detect each substring index
            for(i = 0 ; i < size(myString) ; i += 1)
            {
                #print(chr(myString[i]));
                if(chr(myString[i]) == '#')
                {
                    #print("We got one : " ~ i );
                    append(myIndexArray, i);
                }
                #print(size(myIndexArray));
            }
            
            # now we can split the substring
            for(i = 0 ; i < size(myIndexArray) ; i += 1)
            {
                if(i < size(myIndexArray) - 1)
                {
                    #print(substr(myString, myIndexArray[i], myIndexArray[i + 1] - myIndexArray[i]));
                    
                    # index of weight :
                    var myWeightIndex = substr(myString, myIndexArray[i] + 1, 1);
                    #print("myWeightIndex:"~ myWeightIndex);
                    
                    # has been fired (display pylons or not)
                    var myFired = substr(myString, myIndexArray[i] + 2, 1) == 1;
                    #print(myFired);
                    
                    # what to put in weight[]/selected index
                    var myWeightOptIndex = substr(myString, myIndexArray[i] + 3, (myIndexArray[i + 1] - 1) - (myIndexArray[i] + 2));
                    var mySelection = me.loadList[myWeightOptIndex];
                    #var myWeight = getprop("sim/weight["~ myWeightIndex ~"]/opt[" ~ myWeightOptIndex ~ "]/name");
                    #print("myWeight: " ~ myWeight);
                    
                    # rebuilt the property Tree
                    me.mySelf.getNode("sim/weight["~ myWeightIndex ~"]/selected", 1).setValue(mySelection);
                    if(fired){me.mySelf.getNode("sim/weight["~ myWeightIndex ~"]/selected", 1).setValue(me.weaponWeigh(mySelection));}
                    me.mySelf.getNode("controls/armament/station["~ myWeightIndex ~"]/release", 1).setValue(myFired);
                }
                else
                {
                    #print(substr(myString, myIndexArray[i], size(myString) - myIndexArray[i]));
                    
                    # index of weight :
                    var myWeightIndex = substr(myString, myIndexArray[i] + 1, 1);
                    #print(myWeightIndex);
                    
                    # has been fired (display pylons or not)
                    var myFired = substr(myString, myIndexArray[i] + 2, 1) == 1;
                    #print(myFired);
                    
                    # what to put in weight[]/selected
                    var myWeightOptIndex = substr(myString, myIndexArray[i] + 3, size(myString) - (myIndexArray[i] + 2));
                    var mySelection = me.loadList[myWeightOptIndex];
                    #var myWeight = getprop("sim/weight["~ myWeightIndex ~"]/opt[" ~ myWeightOptIndex ~ "]/name");
                    #print(myWeight);
                    
                    # rebuilt the property Tree
                    me.mySelf.getNode("sim/weight["~ myWeightIndex ~"]/selected", 1).setValue(mySelection);
                    if(fired){me.mySelf.getNode("sim/weight["~ myWeightIndex ~"]/selected", 1).setValue(me.weaponWeigh(mySelection));}
                    me.mySelf.getNode("controls/armament/station["~ myWeightIndex ~"]/release", 1).setValue(myFired);
                    
                    if(me.running == 1)
                    {
                      #settimer(func(){ me.decode(); }, me.updateTime);
                    }
                }
            }
        }
        #print(me.mySelf.getName() ~ "["~ me.mySelf.getIndex() ~"]");
    },
    stop: func()
    {
        me.running = 0;
    },
};

var Encode_Bool = func(){
  var mycomp = mirage2000.landing1_switch.getValue();
  mycomp       = mirage2000.formation_switch.getValue()                         ~ mycomp;
  mycomp       = mirage2000.position_switch.getValue()                          ~ mycomp;
  mycomp       = mirage2000.tailLight_switch.getValue()                         ~ mycomp;
  mycomp       = mirage2000.strobe2_switch.getValue()                           ~ mycomp;
  mycomp       = mirage2000.strobe_switch.getValue()                            ~ mycomp;
  mycomp       = props.globals.getNode("/gear/gear[0]/wow").getValue()          ~ mycomp;
  mycomp       = props.globals.getNode("/gear/gear[1]/wow").getValue()          ~ mycomp;
  mycomp       = props.globals.getNode("/gear/gear[2]/wow").getValue()          ~ mycomp;
  mycomp       = props.globals.getNode("/controls/ground-equipment").getValue() ~ mycomp;

  var myIntBool = bits.value(mycomp);
  setprop("sim/multiplay/generic/int[8]",myIntBool);
}

### Object decode
var Decode_Bool = {
    new: func(mySelf, myIntObject, updateTime)
    {
        var m = { parents: [Decode_Bool] };
        m.mySelf = mySelf;
        m.myIntObject = myIntObject;
        m.updateTime = updateTime;
        m.running = 1;
        m.strobe_switch = m.mySelf.getNode("systems/electrical/outputs/strobe", 1);
        m.strobe2_switch = m.mySelf.getNode("systems/electrical/outputs/strobe2", 1);
        m.tailLight_switch = m.mySelf.getNode("systems/electrical/outputs/tailLight", 1);
        m.position_switch = m.mySelf.getNode("systems/electrical/outputs/position", 1);
        m.formation_switch = m.mySelf.getNode("systems/electrical/outputs/formation-lights", 1);
        m.landing1_switch = m.mySelf.getNode("systems/electrical/outputs/landing-lights", 1);
        
        m.wow0 = m.mySelf.getNode("gear/gear[0]/wow", 1);
        m.wow1 = m.mySelf.getNode("gear/gear[1]/wow", 1);
        m.wow2 = m.mySelf.getNode("gear/gear[2]/wow", 1);
        
        m.groudEquipement = m.mySelf.getNode("controls/ground-equipment", 1);
        
        return m;
    },
    init:func() {
    },
    
    decode: func()
    {
        #print("Upload On going");
        #print(me.mySelf.getPath());
        var myLocalIntObject = me.myIntObject.getValue();
        
        var receivedString = bits.string(myLocalIntObject, 10);
        #print("myLocalIntObject"~myLocalIntObject);
        #print("receivedString"~receivedString);
        
        me.mySelf.getNode("controls/ground-equipment", 1).setValue(chr(receivedString[size(receivedString)-10]));
        me.mySelf.getNode("gear/gear[0]/wow", 1).setValue(chr(receivedString[size(receivedString)-9]));
        me.mySelf.getNode("gear/gear[1]/wow", 1).setValue(chr(receivedString[size(receivedString)-8]));
        me.mySelf.getNode("gear/gear[2]/wow", 1).setValue(chr(receivedString[size(receivedString)-7]));
        
        
        me.mySelf.getNode("systems/electrical/outputs/strobe", 1).setValue(chr(receivedString[size(receivedString)-6]));
        me.mySelf.getNode("systems/electrical/outputs/strobe2", 1).setValue(chr(receivedString[size(receivedString)-5]));
        me.mySelf.getNode("systems/electrical/outputs/tailLight", 1).setValue(chr(receivedString[size(receivedString)-4]));
        me.mySelf.getNode("systems/electrical/outputs/position", 1).setValue(chr(receivedString[size(receivedString)-3]));
        me.mySelf.getNode("systems/electrical/outputs/formation-lights", 1).setValue(chr(receivedString[size(receivedString)-2]));
        me.mySelf.getNode("systems/electrical/outputs/landing-lights", 1).setValue(chr(receivedString[size(receivedString)-1]));
        

        if(me.running == 1)
        {
            #settimer(func(){ me.decode(); }, me.updateTime);
        }
        
    },
    start:func()
    {
       me.running=1;
       me.init();
       settimer(func(){ me.decode(); }, me.updateTime);
    },
    stop: func()
    {
        me.running = 0;
    },
};

### Object decode
var MP_light = {
    new: func(mySelf)
    {
        var m = { parents: [MP_light] };
        m.mySelf = mySelf;
        #m.myIntObject = myIntObject;
        #m.updateTime = updateTime;
        #m.running = 1;
        
        m.strobe_switch      = m.mySelf.getNode("systems/electrical/outputs/strobe", 1);
        m.strobe2_switch     = m.mySelf.getNode("systems/electrical/outputs/strobe2", 1);
        m.tailLight_switch   = m.mySelf.getNode("systems/electrical/outputs/tailLight", 1);
        m.position_switch    = m.mySelf.getNode("systems/electrical/outputs/position", 1);
        m.formation_switch   = m.mySelf.getNode("systems/electrical/outputs/formation-lights", 1);
        m.landing1_switch    = m.mySelf.getNode("systems/electrical/outputs/landing-lights", 1);

        m.FinalStrobe        = m.mySelf.getNode("sim/model/lights/strobe");
        m.FinalStrobe2       = m.mySelf.getNode("sim/model/lights/strobe2");
        m.FinaltailLight     = m.mySelf.getNode("sim/model/lights/tailLight");
        m.Finalposition      = m.mySelf.getNode("sim/model/lights/position");
        m.Finalformation     = m.mySelf.getNode("sim/model/lights/formation");
        m.Finallanding       = m.mySelf.getNode("sim/model/lights/landing");
        
        m.FinalStrobeObject  = aircraft.light.new(m.mySelf.getPath() ~"/sim/model/lights/strobe", [0.03, 1.5], m.strobe_switch);
        m.FinalStrobe2       = aircraft.light.new(m.mySelf.getPath() ~"/sim/model/lights/strobe2", [0.03, 1.4], m.strobe2_switch);
        m.FinaltailLight     = aircraft.light.new(m.mySelf.getPath() ~"/sim/model/lights/tailLight", [0], m.tailLight_switch);
        m.Finalposition      = aircraft.light.new(m.mySelf.getPath() ~"/sim/model/lights/position", [0], m.position_switch);
        m.Finalformation     = aircraft.light.new(m.mySelf.getPath() ~"/sim/model/lights/formation", [0], m.formation_switch);
        m.Finallanding       = aircraft.light.new(m.mySelf.getPath() ~"/sim/model/lights/landing", [0], m.landing1_switch);
        
        return m;
    },
    init:func() {
    },
  };
  
  var MP_missile = func(self){
      # start missile over MP
      #  
      var skip = 0;
      var lat = self.getNode("rotors/main/blade[0]/flap-deg");
      var lon = self.getNode("rotors/main/blade[1]/flap-deg");
      var alt = self.getNode("rotors/main/blade[2]/flap-deg");
      if (alt == nil or alt.getValue() == nil) {
        skip = 1;
      }

      var objs = {};

      var loop = func () {

        if(alt.getValue() != 0) {
          var objModel = objs["first"];
          if (objModel == nil) {
            # create model
            #print("creating missile");
            var n = props.globals.getNode("models", 1);
            var i = 0;
            for (i = 0; 1==1; i += 1) {
              if (n.getChild("model", i, 0) == nil) {
                break;
              }
            }
            objModel = n.getChild("model", i, 1);

            objModel.getNode("elevation",1).setDoubleValue(0);
            objModel.getNode("latitude",1).setDoubleValue(0);
            objModel.getNode("longitude",1).setDoubleValue(0);
            objModel.getNode("elevation-ft-prop",1).setValue(objModel.getPath()~"/elevation");
            objModel.getNode("latitude-deg-prop",1).setValue(objModel.getPath()~"/latitude");
            objModel.getNode("longitude-deg-prop",1).setValue(objModel.getPath()~"/longitude");
            objModel.getNode("heading-deg",1).setDoubleValue(0);
            objModel.getNode("pitch-deg",1).setDoubleValue(0);
            objModel.getNode("roll-deg",1).setDoubleValue(0);
            objModel.getNode("path",1).setValue("Aircraft/Mirage-2000/Missiles/MP_missile/mp_missile.xml");

            var loadNode = objModel.getNode("load", 1);
            loadNode.setBoolValue(1);

            objs["first"] = objModel;
            loadNode.remove();
          }
        }
        var exist = 0;
        if(alt.getValue() != 0) {
          exist = 1;

          var objModel = objs["first"];
          if (objModel == nil) {
            print("error: did not find mp missile.");
            return;
          }# else {
          #  print("found a missile!");
          #}
          objModel.getNode("latitude").setDoubleValue(lat.getValue());
          objModel.getNode("longitude").setDoubleValue(lon.getValue());
          objModel.getNode("elevation").setDoubleValue(alt.getValue()*M2FT);

        }
        if (exist == 0) {
          # remove model
          var objModel = objs["first"];
          if (objModel != nil) {
            objModel.remove();
            delete(objs, "first");
          }
        }

        if (self.getNode("valid") == 0 or self.getNode("valid") == nil) {
          return;
        }
        settimer(loop, 0.05);
      }

      if (skip == 0) {
          loop();
      }
      #
      # end missile over MP
    
  }
