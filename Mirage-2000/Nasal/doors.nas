print("*** LOADING doors.nas ... ***");
################################################################################
#
#                        m2005-5's DOORS SETTINGS
#
################################################################################

crew      = aircraft.door.new("/sim/model/door-positions/crew",      2, 1);
passenger = aircraft.door.new("/sim/model/door-positions/passenger", 2, 0);
temporary = aircraft.door.new("/sim/model/door-positions/temporary", 2, 0);
parachute = aircraft.door.new("/sim/model/door-positions/parachute", 2, 0);

# this function manages 3 positions of canopy : close, open and half-opened
# it uses the function interpolate(property, target value, speed of animation)
# witch allows to create an animation between different positions.
# we have to use 4 different values to obtain a cycle :
#
#          d ----> half-opened (0.095) ----> d
#          ^                                 |
#          |                                 V
#        opened (1)                       closed (0)
#          ^                                 |
#          |                                 V
#          d <-- half-opened (0.1000) <----- d
#
var move_canopy = func()
{
    var position = getprop("/sim/model/door-positions/crew/position-norm");
    
    # let's check current position :
    if(position <= 0.000)
    {
        # it's closed let's half open :
        interpolate("/sim/model/door-positions/crew/position-norm", 0.099, 2);
    }
    elsif(position > 0.098 and position <= 0.102)
    {
        # it's half-opened let's open :
        interpolate("/sim/model/door-positions/crew/position-norm", 1.000, 2);
    }
    elsif(position >= 1)
    {
        # it's opened let's half open :
        interpolate("/sim/model/door-positions/crew/position-norm", 0.095, 2);
    }
    else
    {
        # let's close :
        interpolate("/sim/model/door-positions/crew/position-norm", 0.000, 2);
    }

}
var move_canopy_byHand = func() {
    var position = getprop("/sim/model/door-positions/crew/position-norm");
    if(position > 0.090)
    {
        if(position == 1)
        {
            # it's opened let's half open :
            interpolate("/sim/model/door-positions/crew/position-norm", 0.095, 2);
        }
        else
        {
            # it's half-opened let's open :
            interpolate("/sim/model/door-positions/crew/position-norm", 1.000, 2);
        }
    }
}

var move_canopy_lock = func() {
    var position = getprop("/sim/model/door-positions/crew/position-norm");
    if(position<0.1){
        if(position <= 0.000)
        {
            # it's closed let's half open :
            interpolate("/sim/model/door-positions/crew/position-norm", 0.095, 2);
        }
        else
        {
            # let's close :
            interpolate("/sim/model/door-positions/crew/position-norm", 0.000, 2);
        }
    }
}
