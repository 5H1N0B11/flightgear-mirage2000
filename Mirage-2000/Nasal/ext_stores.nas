print("*** LOADING ext_stores.nas ... ***");
################################################################################
#
#                     m2005-5's EXTERNAL STORES SETTINGS
#
################################################################################

var weaponARRAY = ["","GUN","IR","EM","GND"];
var weaponARRAY_Index = 0;
var PayloadARRAY = [];



# check then drop
var dropTanks = func() {
    for(var i = 2 ; i < 5 ; i += 1)
    {
        var select = getprop("/sim/weight["~ i ~"]/selected");
        if(select == "1300 l Droptank" or select == "1700 l Droptank")
        {
            m2000_load.dropLoad(i);
        }
    }
}

# compile all load in a multiplay variable
var Encode_Load = func() {
    var list = [
        "none",
        "1300 l Droptank",
        "1700 l Droptank",
        "AGM65",
        "AIM-54",
        "aim-9",
        "AIM120",
        "GBU12",
        "GBU16",
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
    var compiled = "";
    
    for(var i = 0 ; i < 9 ; i += 1)
    {
        # Load name
        var select = getprop("sim/weight["~ i ~"]/selected");
        
        # fireable or not : may displays the pylons if there a weight but fire = 0
        var released = getprop("controls/armament/station["~ i ~"]/release");
        
        # selection of the index load for each pylon
        # We get the children of the tree sim weight[actual]
        for(var y = 0 ; y < size(list) ; y += 1)
        {
            if(list[y] == select)
            {
                var select_Index = y;
            }
        }
        
        # now we select the index
        compiled = compiled ~"#"~ i ~ released ~ select_Index;
    }
    
    # we put it in a multiplay string
    setprop("sim/multiplay/generic/string[1]", compiled);
}

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
                if(chr(myString[i]) == '#')
                {
                    append(myIndexArray, i);
                }
            }
            
            # now we can split the substring
            for(i = 0 ; i < size(myIndexArray) ; i += 1)
            {
                if(i < size(myIndexArray) - 1)
                {
                    # index of weight :
                    var myWeightIndex = substr(myString, myIndexArray[i] + 1, 1);
                    
                    # has been fired (display pylons or not)
                    var myFired = substr(myString, myIndexArray[i] + 2, 1) == 1;
                    
                    # what to put in weight[]/selected index
                    var myWeightOptIndex = substr(myString, myIndexArray[i] + 3, (myIndexArray[i + 1] - 1) - (myIndexArray[i] + 2));
                    var myWeight = me.loadList[myWeightOptIndex];
                    
                    # rebuilt the property Tree
                    me.mySelf.getNode("sim/weight["~ myWeightIndex ~"]/selected", 1).setValue(myWeight);
                    me.mySelf.getNode("controls/armament/station["~ myWeightIndex ~"]/release", 1).setValue(myFired);
                }
                else
                {
                    # index of weight :
                    var myWeightIndex = substr(myString, myIndexArray[i] + 1, 1);
                    #print(myWeightIndex);
                    
                    # has been fired (display pylons or not)
                    var myFired = substr(myString, myIndexArray[i] + 2, 1) == 1;
                    #print(myFired);
                    
                    # what to put in weight[]/selected
                    var myWeightOptIndex = substr(myString, myIndexArray[i] + 3, size(myString) - (myIndexArray[i] + 2));
                    var myWeight = me.loadList[myWeightOptIndex];
                    
                    # rebuilt the property Tree
                    me.mySelf.getNode("sim/weight["~ myWeightIndex ~"]/selected", 1).setValue(myWeight);
                    me.mySelf.getNode("controls/armament/station["~ myWeightIndex ~"]/release", 1).setValue(myFired);
                    
                    if(me.running == 1)
                    {
                        settimer(func(){ me.decode(); }, me.updateTime);
                    }
                }
            }
        }
    },
    stop: func()
    {
        me.running = 0;
    },
};

# Here is where quick load management is managed...
# These 4 function can't be active when flying : This mean a little preparation for the mission
# It's an anti kiddo script
var Po = func() {
    if(getprop("/gear/gear[2]/wow") == 1)
    {
        # pylon 0
        setprop("/sim/weight[0]/selected",                   "none");
        
        # pylon 1
        setprop("/sim/weight[1]/selected",                   "Matra R550 Magic 2");
        
        # pylon 2
        setprop("/sim/weight[2]/selected",                   "none");
        setprop("/consumables/fuel/tank[2]/selected",        0);
        setprop("/consumables/fuel/tank[2]/capacity-gal_us", 0);
        setprop("/consumables/fuel/tank[2]/level-gal_us",    0);
        
        # pylon 3
        setprop("/sim/weight[3]/selected",                   "1300 l Droptank");
        setprop("/consumables/fuel/tank[3]/selected",        1);
        setprop("/consumables/fuel/tank[3]/capacity-gal_us", 343);
        setprop("/consumables/fuel/tank[3]/level-gal_us",    342);
        
        # pylon 4
        setprop("/sim/weight[4]/selected",                   "none");
        setprop("/consumables/fuel/tank[4]/selected",        0);
        setprop("/consumables/fuel/tank[4]/capacity-gal_us", 0);
        setprop("/consumables/fuel/tank[4]/level-gal_us",    0);
        
        # pylon 5
        setprop("/sim/weight[5]/selected",                   "Matra R550 Magic 2");
        
        # pylon 6
        setprop("/sim/weight[6]/selected",                   "none");
        
        # pylon 7
        setprop("/sim/weight[7]/selected",                   "none");
        
        # pylon 8
        setprop("/sim/weight[8]/selected",                   "none");
        
        FireableAgain();
    }
}

var FoxOldYears = func() {
    if(getprop("/gear/gear[2]/wow") == 1)
    {
        # pylon 0
        setprop("/sim/weight[0]/selected",                   "none");
        
        # pylon 1
        setprop("/sim/weight[1]/selected",                   "Matra R550 Magic 2");
        
        # pylon 2
        setprop("/sim/weight[2]/selected",                   "Matra Super 530D");
        setprop("/consumables/fuel/tank[2]/selected",        0);
        setprop("/consumables/fuel/tank[2]/capacity-gal_us", 0);
        setprop("/consumables/fuel/tank[2]/level-gal_us",    0);
        
        # pylon 3
        setprop("/sim/weight[3]/selected",                   "1300 l Droptank");
        setprop("/consumables/fuel/tank[3]/selected",        1);
        setprop("/consumables/fuel/tank[3]/capacity-gal_us", 343);
        setprop("/consumables/fuel/tank[3]/level-gal_us",    342);
        
        # pylon 4
        setprop("/sim/weight[4]/selected",                   "Matra Super 530D");
        setprop("/consumables/fuel/tank[4]/selected",        0);
        setprop("/consumables/fuel/tank[4]/capacity-gal_us", 0);
        setprop("/consumables/fuel/tank[4]/level-gal_us",    0);
        
        # pylon 5
        setprop("/sim/weight[5]/selected",                   "Matra R550 Magic 2");
        
        # pylon 6
        setprop("/sim/weight[6]/selected",                   "none");
        
        # pylon 7
        setprop("/sim/weight[7]/selected",                   "none");
        
        # pylon 8
        setprop("/sim/weight[8]/selected",                   "none");
        
        FireableAgain();
    }
}

var Fox = func() {
    if(getprop("/gear/gear[2]/wow") == 1)
    {
        # pylon 0
        setprop("/sim/weight[0]/selected",                   "Matra MICA");
        
        # pylon 1
        setprop("/sim/weight[1]/selected",                   "Matra R550 Magic 2");
        
        # pylon 2
        setprop("/sim/weight[2]/selected",                   "none");
        setprop("/consumables/fuel/tank[2]/selected",        0);
        setprop("/consumables/fuel/tank[2]/capacity-gal_us", 0);
        setprop("/consumables/fuel/tank[2]/level-gal_us",    0);
        
        # pylon 3
        setprop("/sim/weight[3]/selected",                   "1300 l Droptank");
        setprop("/consumables/fuel/tank[3]/selected",        1);
        setprop("/consumables/fuel/tank[3]/capacity-gal_us", 343);
        setprop("/consumables/fuel/tank[3]/level-gal_us",    342);
        
        # pylon 4
        setprop("/sim/weight[4]/selected",                   "none");
        setprop("/consumables/fuel/tank[4]/selected",        0);
        setprop("/consumables/fuel/tank[4]/capacity-gal_us", 0);
        setprop("/consumables/fuel/tank[4]/level-gal_us",    0);
        
        # pylon 5
        setprop("/sim/weight[5]/selected",                   "Matra R550 Magic 2");
        
        # pylon 6
        setprop("/sim/weight[6]/selected",                   "Matra MICA");
        
        # pylon 7
        setprop("/sim/weight[7]/selected",                   "Matra MICA");
        
        # pylon 8
        setprop("/sim/weight[8]/selected",                   "Matra MICA");
        
        FireableAgain();
    }
}

var FoxFullMica = func() {
    if(getprop("/gear/gear[2]/wow") == 1)
    {
        # pylon 0
        setprop("/sim/weight[0]/selected",                   "Matra MICA");
        
        # pylon 1
        setprop("/sim/weight[1]/selected",                   "Matra MICA IR");
        
        # pylon 2
        setprop("/sim/weight[2]/selected",                   "none");
        setprop("/consumables/fuel/tank[2]/selected",        0);
        setprop("/consumables/fuel/tank[2]/capacity-gal_us", 0);
        setprop("/consumables/fuel/tank[2]/level-gal_us",    0);
        
        # pylon 3
        setprop("/sim/weight[3]/selected",                   "1300 l Droptank");
        setprop("/consumables/fuel/tank[3]/selected",        1);
        setprop("/consumables/fuel/tank[3]/capacity-gal_us", 343);
        setprop("/consumables/fuel/tank[3]/level-gal_us",    342);
        
        # pylon 4
        setprop("/sim/weight[4]/selected",                   "none");
        setprop("/consumables/fuel/tank[4]/selected",        0);
        setprop("/consumables/fuel/tank[4]/capacity-gal_us", 0);
        setprop("/consumables/fuel/tank[4]/level-gal_us",    0);
        
        # pylon 5
        setprop("/sim/weight[5]/selected",                   "Matra MICA IR");
        
        # pylon 6
        setprop("/sim/weight[6]/selected",                   "Matra MICA");
        
        # pylon 7
        setprop("/sim/weight[7]/selected",                   "Matra MICA");
        
        # pylon 8
        setprop("/sim/weight[8]/selected",                   "Matra MICA");
        
        FireableAgain();
    }
}

var Bravo = func() {
    if(getprop("/gear/gear[2]/wow") == 1)
    {
        # pylon 0
        setprop("/sim/weight[0]/selected",                   "Matra MICA");
        
        # pylon 1
        setprop("/sim/weight[1]/selected",                   "Matra R550 Magic 2");
        
        # pylon 2
        setprop("/sim/weight[2]/selected",                   "1700 l Droptank");
        setprop("/consumables/fuel/tank[2]/selected",        1);
        setprop("/consumables/fuel/tank[2]/capacity-gal_us", 448.50);
        setprop("/consumables/fuel/tank[2]/level-gal_us",    447);
        
        # pylon 3
        setprop("/sim/weight[3]/selected",                   "none");
        setprop("/consumables/fuel/tank[3]/selected",        0);
        setprop("/consumables/fuel/tank[3]/capacity-gal_us", 0);
        setprop("/consumables/fuel/tank[3]/level-gal_us",    0);
        
        # pylon 4
        setprop("/sim/weight[4]/selected",                   "1700 l Droptank");
        setprop("/consumables/fuel/tank[4]/selected",        1);
        setprop("/consumables/fuel/tank[4]/capacity-gal_us", 448.50);
        setprop("/consumables/fuel/tank[4]/level-gal_us",    447);
        
        # pylon 5
        setprop("/sim/weight[5]/selected",                   "Matra R550 Magic 2");
        
        # pylon 6
        setprop("/sim/weight[6]/selected",                   "Matra MICA");
        
        # pylon 7
        setprop("/sim/weight[7]/selected",                   "Matra MICA");
        
        # pylon 8
        setprop("/sim/weight[8]/selected",                   "Matra MICA");
        
        FireableAgain();
    }
}

var Kilo = func() {
    if(getprop("/gear/gear[2]/wow") == 1)
    {
        # pylon 0
        setprop("/sim/weight[0]/selected",                   "Matra MICA");
        
        # pylon 1
        setprop("/sim/weight[1]/selected",                   "Matra MICA IR");
        
        # pylon 2
        setprop("/sim/weight[2]/selected",                   "1700 l Droptank");
        setprop("/consumables/fuel/tank[2]/selected",        1);
        setprop("/consumables/fuel/tank[2]/capacity-gal_us", 448.50);
        setprop("/consumables/fuel/tank[2]/level-gal_us",    447);
        
        # pylon 3
        setprop("/sim/weight[3]/selected",                   "1300 l Droptank");
        setprop("/consumables/fuel/tank[3]/selected",        1);
        setprop("/consumables/fuel/tank[3]/capacity-gal_us", 343);
        setprop("/consumables/fuel/tank[3]/level-gal_us",    342);
        
        # pylon 4
        setprop("/sim/weight[4]/selected",                   "1700 l Droptank");
        setprop("/consumables/fuel/tank[4]/selected",        1);
        setprop("/consumables/fuel/tank[4]/capacity-gal_us", 448.50);
        setprop("/consumables/fuel/tank[4]/level-gal_us",    447);
        
        # pylon 5
        setprop("/sim/weight[5]/selected",                   "Matra MICA IR");
        
        # pylon 6
        setprop("/sim/weight[6]/selected",                   "Matra MICA");
        
        # pylon 7
        setprop("/sim/weight[7]/selected",                   "Matra MICA");
        
        # pylon 8
        setprop("/sim/weight[8]/selected",                   "Matra MICA");
        
        FireableAgain();
    }
}

var NoLoad = func() {
    if(getprop("/gear/gear[2]/wow") == 1)
    {
        # pylon 0
        setprop("/sim/weight[0]/selected",                   "none");
        
        # pylon 1
        setprop("/sim/weight[1]/selected",                   "none");
        
        # pylon 2
        setprop("/sim/weight[2]/selected",                   "none");
        setprop("/consumables/fuel/tank[2]/selected",        0);
        setprop("/consumables/fuel/tank[2]/capacity-gal_us", 0);
        setprop("/consumables/fuel/tank[2]/level-gal_us",    0);
        
        # pylon 3
        setprop("/sim/weight[3]/selected",                   "none");
        setprop("/consumables/fuel/tank[3]/selected",        0);
        setprop("/consumables/fuel/tank[3]/capacity-gal_us", 0);
        setprop("/consumables/fuel/tank[3]/level-gal_us",    0);
        
        # pylon 4
        setprop("/sim/weight[4]/selected",                   "none");
        setprop("/consumables/fuel/tank[4]/selected",        0);
        setprop("/consumables/fuel/tank[4]/capacity-gal_us", 0);
        setprop("/consumables/fuel/tank[4]/level-gal_us",    0);
        
        # pylon 5
        setprop("/sim/weight[5]/selected",                   "none");
        
        # pylon 6
        setprop("/sim/weight[6]/selected",                   "none");
        
        # pylon 7
        setprop("/sim/weight[7]/selected",                   "none");
        
        # pylon 8
        setprop("/sim/weight[8]/selected",                   "none");
        FireableAgain();
    }
}

var AirToGround = func() {
    if(getprop("/gear/gear[2]/wow") == 1)
    {
        # pylon 0
        setprop("/sim/weight[0]/selected",                   "none");
        
        # pylon 1
        setprop("/sim/weight[1]/selected",                   "Matra MICA IR");
        
        # pylon 2
        setprop("/sim/weight[2]/selected",                   "1700 l Droptank");
        setprop("/consumables/fuel/tank[2]/selected",        1);
        setprop("/consumables/fuel/tank[2]/capacity-gal_us", 448.50);
        setprop("/consumables/fuel/tank[2]/level-gal_us",    447);
        
        # pylon 3
        setprop("/sim/weight[3]/selected",                   "Double GBU12");
        setprop("/consumables/fuel/tank[3]/selected",        0);
        setprop("/consumables/fuel/tank[3]/capacity-gal_us", 0);
        setprop("/consumables/fuel/tank[3]/level-gal_us",    0);
        
        # pylon 4
        setprop("/sim/weight[4]/selected",                   "1700 l Droptank");
        setprop("/consumables/fuel/tank[4]/selected",        1);
        setprop("/consumables/fuel/tank[4]/capacity-gal_us", 448.50);
        setprop("/consumables/fuel/tank[4]/level-gal_us",    447);
        
        # pylon 5
        setprop("/sim/weight[5]/selected",                   "Matra MICA IR");
        
        # pylon 6
        setprop("/sim/weight[6]/selected",                   "PDLCT");
        
        # pylon 7
        setprop("/sim/weight[7]/selected",                   "none");
        
        # pylon 8
        setprop("/sim/weight[8]/selected",                   "none");
        
        FireableAgain();
    }
}

var m2000N = func() {
    if(getprop("/gear/gear[2]/wow") == 1)
    {
        # pylon 0
        setprop("/sim/weight[0]/selected",                   "none");
        
        # pylon 1
        setprop("/sim/weight[1]/selected",                   "Matra R550 Magic 2");
        
        # pylon 2
        setprop("/sim/weight[2]/selected",                   "1700 l Droptank");
        setprop("/consumables/fuel/tank[2]/selected",        1);
        setprop("/consumables/fuel/tank[2]/capacity-gal_us", 448.50);
        setprop("/consumables/fuel/tank[2]/level-gal_us",    447);
        
        # pylon 3
        setprop("/sim/weight[3]/selected",                   "ASMP");
        setprop("/consumables/fuel/tank[3]/selected",        0);
        setprop("/consumables/fuel/tank[3]/capacity-gal_us", 0);
        setprop("/consumables/fuel/tank[3]/level-gal_us",    0);
        
        # pylon 4
        setprop("/sim/weight[4]/selected",                   "1700 l Droptank");
        setprop("/consumables/fuel/tank[4]/selected",        1);
        setprop("/consumables/fuel/tank[4]/capacity-gal_us", 448.50);
        setprop("/consumables/fuel/tank[4]/level-gal_us",    447);
        
        # pylon 5
        setprop("/sim/weight[5]/selected",                   "Matra R550 Magic 2");
        
        # pylon 6
        setprop("/sim/weight[6]/selected",                   "none");
        
        # pylon 7
        setprop("/sim/weight[7]/selected",                   "none");
        
        # pylon 8
        setprop("/sim/weight[8]/selected",                   "none");
        
        FireableAgain();
    }
}

var weaponWeight = {
      "none":                 0,
      "GBU16":                1000,
      "GBU12":                800,
      "Double GBU12":         1600,
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

var FireableAgain = func() {
    for(var i = 0 ; i < 9 ; i += 1)
    {
        # to make it fireable again
        setprop("/controls/armament/station["~ i ~"]/release", 0);
        
        # To add weight to pylons
        var select = getprop("/sim/weight["~ i ~"]/selected");
        #print("select" ~ select);
        setprop("/sim/weight["~ i ~"]/weight-lb", weaponWeight[select]);        
    }
    init_weaponSytem();
}

# Begining of the dropable function.
# It has to be simplified and generic made
# Need to know how to make a table
dropLoad = func(number) {
    print("func DropLoad OK");
    var select = getprop("/sim/weight["~ number ~"]/selected");
    if(select != "none")
    {
        if(select == "1300 l Droptank" or select == "1700 l Droptank")
        {
            tank_submodel(number, select);
            setprop("/consumables/fuel/tank["~ number ~"]/selected", 0);
            setprop("/consumables/fuel/tank["~ number ~"]/capacity-m3", 0);
            setprop("/consumables/fuel/tank["~ number ~"]/level-kg", 0);
            setprop("/controls/armament/station["~ number ~"]/release", 1);
            setprop("/sim/weight["~ number ~"]/weight-lb", 0);
        }
        else
        {
            if(select == "ASMP")
            {
                m2000_load.nuc();
            }
            else
            {
                if(getprop("/controls/armament/station["~ number ~"]/release") == 0)
                {
                    m2000_load.dropMissile(number);
                }
            }
        }
    }
}

# Need to be changed
dropLoad_stop = func(n) {
    #setprop("/controls/armament/station["~ n ~"]/release", 0);
}

  var weaponNames = {
      # translate weapon names used in stores dialog into names used in missile code:
      #
      # Notice that names used in missile code are without space, and case is important.
      # They also match the folder names. Lowercase of missile code names are used to get xml stats and name of xml.
      #
      "AGM65":                "AGM65",
      "AIM-54":               "AIM-54",
      "?":                    "aim-7",
      "aim-9":                "aim-9",
      "AIM120":               "AIM120",
      "GBU12":                "GBU12",
      "GBU16":                "GBU16",
      "Double GBU12":          "GBU12",
      "MATRA-R530":           "MATRA-R530",
      "Matra MICA":           "MatraMica",
      "Matra MICA IR":        "MatraMicaIR",
      "Matra R550 Magic 2":   "MatraR550Magic2",
      "Meteor":               "Meteor",
      "R74":                  "R74",
      "SCALP":                "SCALP",
      "Sea Eagle":            "SeaEagle",
      "Exocet":               "Exocet",
      "Matra Super 530D":     "Matra-super530d" #Nmae of the Folder : Aircraft/Mirage-2000/Missiles/Matra-super530d/
};

dropMissile = func(number)
{
    print("Function dropMissile OK");
    var target = mirage2000.myRadar3.GetTarget();
    var typeMissile = getprop("/sim/weight["~ number ~"]/selected");
    
    typeMissile = weaponNames[typeMissile];

    if(target == nil or typeMissile == nil)
    {
        return;
    }
    missile.contact = target;
    print("typeMissile:"~typeMissile);
    var Current_missile = missile.AIM.new(number, typeMissile, typeMissile);
    if (Current_missile != -1) {
        Current_missile.start();
    } else {
        return;
    }
    settimer(func dropMissile2(Current_missile, number), 0.10);
}

dropMissile2 = func(Current_missile, number)
{
    print("Function dropMissile2 OK");
    if (Current_missile.status == 1) {
        dropMissile3(Current_missile, number);
    } else {
        settimer(func dropMissile3(Current_missile, number), 0.2);
    }
}

dropMissile3 = func(Current_missile, number)
{
    print("Function dropMissile3 OK");
    if (Current_missile.status == 1) {
        Current_missile.release();
    } else {
        print("Weapon got no lock on target (probably out of range, out of view or wrong target type), deleting weapon.");
        Current_missile.del();
        return;
    }
    var phrase = Current_missile.brevity ~ " at: " ~ Current_missile.Tgt.get_Callsign();# change this to what you want Shinobi
    if (getprop("/controls/armament/mp-messaging")) {
      missile.defeatSpamFilter(phrase);
    } else {
      setprop("/sim/messages/atc", phrase);
    }
    print(phrase);
    var typeMissile = getprop("/sim/weight["~ number ~"]/selected");
    if(getprop("/sim/weight["~ number ~"]/weight-lb") == weaponWeight[typeMissile] and typeMissile =="Double GBU12"){
      setprop("/sim/weight["~ number ~"]/weight-lb", 800);
    }else{
      setprop("/sim/weight["~ number ~"]/weight-lb", 0);
      setprop("/controls/armament/station["~ number ~"]/release", 1);
    }
    
    
    #If auto focus on missile is activated the we call the function
    if(getprop("/controls/armament/automissileview"))
    {
      view_firing_missile(Current_missile);
    }        
      
    
    after_fire_next();
}

var tank_submodel = func(pylone, select)
{
    # 1300 Tanks
    var release = 0;
    if(pylone == 2 and select == "1300 l Droptank")
    {
        release = "/controls/armament/station[2]/release-L1300";
    }
    if(pylone == 3 and select == "1300 l Droptank")
    {
        release = "/controls/armament/station[3]/release-C1300";
    }
    if(pylone == 4 and select == "1300 l Droptank")
    {
        release ="/controls/armament/station[4]/release-R1300";
    }
    # 1700 Tanks
    if(pylone == 2 and select == "1700 l Droptank")
    {
        release ="/controls/armament/station[2]/release-L1700";
    }
    if(pylone == 4 and select == "1700 l Droptank")
    {
        release ="/controls/armament/station[4]/release-R1700";
    }
    setprop(release, 1);
    settimer(func{setprop(release, 0);}, 0, 5);
}

var inscreased_selected_pylon = func()
{
    var SelectedPylon = getprop("/controls/armament/missile/current-pylon");
    var out = 0;
    var mini = loadsmini();
    var max = loadsmaxi();
    
    if(SelectedPylon == max)
    {
        SelectedPylon=-1;
    }
    
    for(var i = SelectedPylon + 1 ; i < 9 ; i += 1)
    {
        if(getprop("/sim/weight["~ i ~"]/selected"))
        {
            if(getprop("/sim/weight["~ i ~"]/weight-lb") > 1)
            {
                if(mini == -1)
                {
                    mini = i;
                }
                max = i;
                if(out == 0)
                {
                    SelectedPylon = i;
                    out = 1;
                }
            }
        }
    }
    if(SelectedPylon == getprop("/controls/armament/missile/current-pylon"))
    {
        SelectedPylon = mini;
    }
    setprop("/controls/armament/name", getprop("/sim/weight["~ SelectedPylon ~"]/selected"));
    setprop("/controls/armament/missile/current-pylon", SelectedPylon);
}

var decreased_selected_pylon = func()
{
}

# smallest index of load
var loadsmini = func()
{
    var out = 0;
    for(var i = 0 ; i < 9 ; i += 1)
    {
        if(getprop("/sim/weight["~ i ~"]/weight-lb") > 1)
        {
            if(out == 0)
            {
                var mini = i;
                out = 1;
            }
            var maxi = i;
        }
    }
    return mini;
}

# Biggest index of load
var loadsmaxi = func()
{
    var out = 0;
    for(var i = 0 ; i < 9 ; i += 1)
    {
        if(getprop("/sim/weight["~ i ~"]/weight-lb") > 1)
        {
            if(out == 0)
            {
                var mini = i;
                out = 1;
            }
            var maxi = i;
        }
    }
    return maxi;
}

# next missile after fire
var after_fire_next2 = func()
{
    var SelectedPylon = getprop("/controls/armament/missile/current-pylon");
#    if(SelectedPylon == "nil")
    if(SelectedPylon == nil)
    {
        SelectedPylon = 0;
    }
    var out = 0;
    
    # pylons 2 and 4
    if(SelectedPylon == 4)
    {
        SelectedPylon = 2;
    }
    elsif(SelectedPylon == 2)
    {
        SelectedPylon = 4;
    }
    
    # pylons 1 and 5
    if(SelectedPylon == 5)
    {
        SelectedPylon = 1;
    }
    elsif(SelectedPylon == 1)
    {
        SelectedPylon = 5;
    }
    
    # pylons 0 and 6
    if(SelectedPylon == 6)
    {
        SelectedPylon = 0;
    }
    elsif(SelectedPylon == 0)
    {
        SelectedPylon = 6;
    }
    
    # pylons 7 and 8
    if(SelectedPylon == 8)
    {
        SelectedPylon = 7;
    }
    elsif(SelectedPylon == 7)
    {
        SelectedPylon = 8;
    }
    
    if(getprop("/sim/weight["~ SelectedPylon ~"]/weight-lb") < 1)
    {
        for(var i = 0 ; i < 9 ; i += 1)
        {
            if(getprop("/sim/weight["~ i ~"]/weight-lb") > 1)
            {
                if(out == 0)
                {
                    SelectedPylon = i;
                    out = 1;
                }
            }
        }
        setprop("/controls/armament/name", getprop("/sim/weight["~ SelectedPylon ~"]/selected"));
        setprop("/controls/armament/missile/current-pylon", SelectedPylon);
    }
    else
    {
        setprop("/controls/armament/name", getprop("/sim/weight["~ SelectedPylon ~"]/selected"));
        setprop("/controls/armament/missile/current-pylon", SelectedPylon);
    }
}

var view_firing_missile = func(myMissile)
{

    # We select the missile name
    var myMissileName = string.replace(myMissile.ai.getPath(), "/ai/models/", "");

    # We memorize the initial view number
    var actualView = getprop("/sim/current-view/view-number");

    # We recreate the data vector to feed the missile_view_handler  
    var data = { node: myMissile.ai, callsign: myMissileName, root: myMissile.ai.getPath()};

    # We activate the AI view (on this aircraft it is the number 9)
    setprop("/sim/current-view/view-number",9);

    # We feed the handler
    view.missile_view_handler.setup(data);
}

var weaponGuidance = {
    # translate weapon names used in stores dialog into names used in missile code:
    #
    # Notice that names used in missile code are without space, and case is important.
    # They also match the folder names. Lowercase of missile code names are used to get xml stats and name of xml.
    #
    "heat":                 "IR",
    "radar":                "EM",
    "semi-radar":           "EM",
    "laser":                "GND",
    "gps":                  "GND",
    "vision":               "GND",
    "vision":               "GND",
};

var areFirable = {
            "none"            : 0,
            "1300 l Droptank" : 0,
            "1700 l Droptank" : 0,
            "AGM65"           : 1,
            "AIM-54"          : 1,
            "aim-9"           : 1,
            "AIM120"          : 1,
            "GBU12"           : 1,
            "Double GBU12"    : 1,
            "GBU16"           : 1,
            "Matra MICA"      : 1,
            "MATRA-R530"      : 1,
            "Matra R550 Magic 2": 1,
            "Meteor"          : 1,
            "R74"             : 1,
            "R77"             : 1,
            "SCALP"           : 1,
            "Sea Eagle"       : 1,
            "SmokePod"        : 0,
            "ASMP"            : 0,
            "PDLCT"           : 0,
            "Matra MICA IR"   : 1,
            "Exocet"          : 1,
            "Matra Super 530D": 1,

};

#####   New weapons selector system  #########################

var after_fire_next = func(){
  init_weaponSytem();
}


var weaponSelector = func (){
  weaponARRAY_Index = weaponARRAY_Index + 1>size(weaponARRAY)-1?0:weaponARRAY_Index+1;
  if(weaponARRAY[weaponARRAY_Index] == "GUN"){
      setprop("controls/armament/stick-selector",1);
    }else{
      setprop("controls/armament/stick-selector",0);
      setprop("/controls/armament/name",weaponARRAY[weaponARRAY_Index]);
    }
  init_weaponSytem();
}


var init_weaponSytem = func() {
  #heat/radar/semi-radar/laser/gps/vision/unguided
  
  #var weaponARRAY = ["","GUN","IR","EM","GND"];
  #weaponARRAY_Index = 1;
  PayloadARRAY = [];
  
  setprop("/controls/armament/missile/current-pylon", "");
  if(weaponARRAY[weaponARRAY_Index] !="GUN"){setprop("/controls/armament/name",weaponARRAY[weaponARRAY_Index]);}
  
  for(var i = 1 ; i < 9 ; i += 1)
  {
    var select   = getprop("/sim/weight["~ i ~"]/selected");
    var myweight = getprop("/sim/weight["~ i ~"]/weight-lb");
    
    if(areFirable[select] ==1 and myweight>1){
      var actual_kind = getprop("/payload/armament/"~ string.lc(weaponNames[select]) ~ "/guidance");
      #print(string.lc(weaponNames[select]));
      #print(actual_kind);
      if(weaponGuidance[actual_kind] == weaponARRAY[weaponARRAY_Index]){
        append(PayloadARRAY,i);
        
        select = getprop("/sim/weight["~ PayloadARRAY[0] ~"]/selected");
        if(select=="Double GBU12"){select="GBU12";}
        #print("Name : " ~ string.lc(weaponNames[select]) ~ "Kind : " ~ actual_kind, " PayloadARRAY[0] : " ~ select);

        setprop("/controls/armament/missile/current-pylon", PayloadARRAY[0]);
        setprop("/controls/armament/name",select);
      }
    }
  }
  
}
init_weaponSytem();


####################################################################

##
# nuc switch
##
var nuc = func {
    var mpmessaging = getprop("/controls/armament/mp-messaging");
    if(mpmessaging == 0)
    {
        ltext = "Sorry, Nuke will never be available on this plane(t)!";
        screen.log.write(ltext);
    }
    else
    {
        var message1 = "This mirage have been Hijacked by a moron who want to nuke the planet."; 
        var message2 = "Too all operating aircraft, this mirage is your top priority target";
        
        settimer(func {m2000_load.setMessage(message1)},1);
        settimer(func {m2000_load.setMessage(message2)},2);
        
        setprop('/instrumentation/transponder/id-code',"7500");
        mirage2000.init_Transpondeur();
    }
}
var setMessage = func(msg) {
    setprop("/sim/multiplay/chat",msg);
}

var MPMessaging = props.globals.getNode("/controls/armament/mp-messaging", 1);
MPMessaging.setBoolValue(0);

var MPReport = func() {
    if(MPMessaging.getValue() == 1)
    {
        MPMessaging.setBoolValue(0);
    }
    else
    {
        MPMessaging.setBoolValue(1);
    }
    var phrase = (MPMessaging.getValue()) ? "Activated" : "Desactivated";
    phrase = "MP messaging : "~ phrase;
    setprop("/sim/messages/atc", phrase);
}

