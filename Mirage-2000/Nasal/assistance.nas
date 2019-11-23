print("*** LOADING assistance.nas ... ***");

#                               ~~~ README ~~~
#
#
# ORIGINAL FILE : see bourrasque : https://github.com/hardba11/bourrasque
#
#
# more infos here : https://forum.flightgear.org/viewtopic.php?f=18&t=34137
#
# how to install
# --------------
#
# 1- copy this file in a directory (tools/assistance_to_closest_airport for example)
#
# 2- add the nasal script in your aircraft -set.xml file :
#     <nasal>
#       ... other scripts
#       <tools>
#         <file type="string">tools/assistance_to_closest_airport/assistance.nas</file>
#       </tools>
#     </nasal>
#
# 3- add a new property in the property tree in your aircraft -set.xml file :
#     <controls>
#       ... other properties
#       <assistance type="bool">0</assistance>
#     </controls>
#
# 4- add a button or a menu gui to enable/disable assistance property
#    example (gui/dialogs/bourrasque-commands.xml) :
#     <!-- ~~~~~~~~~~~~~~~~~~ assistance -->
#     <group>
#       <layout>table</layout>
#       <halign>left</halign>
#       <button>
#         <row>0</row><col>0</col>
#         <legend>need assistance</legend>
#         <binding>
#           <command>property-assign</command>
#           <property>/controls/assistance</property>
#           <value>1</value>
#         </binding>
#       </button>
#       <button>
#         <row>0</row><col>1</col>
#         <legend>it is ok</legend>
#         <binding>
#           <command>property-assign</command>
#           <property>/controls/assistance</property>
#           <value>0</value>
#         </binding>
#       </button>
#     </group>
#


#===============================================================================
#                                                                 INITIALISATION

var nb_cycle = 1;
var previous_assistance_message = '';

var coord_airport = geo.Coord.new();
var airport = {
    'id':            '',
    'name':          '',
    'elevation_ft':  0,
    'rwy':           '',
    'rwy_length':    0,
    'heading':       0,
    'lng':           0,
    'lat':           0,
};

var coord_aircraft = geo.aircraft_position();
var aircraft = {
    'callsign':     '',
    'heading':      0,
    'altitude':     0,
    'speed':        0,
    'is_gear_down': 0,
    'is_wow':       0,
};

var atc = {
    'heading': 0,
    'speed':   0,
    'alt':     0,
    'circuit': '',
};

var h = 0;
var d = 0;


#===============================================================================
#                                                                      FUNCTIONS

#-------------------------------------------------------------------------------
#                                                             turn_left_or_right
# 
var turn_left_or_right = func(cur_heading, wanted_heading) {
    return((math.mod(cur_heading - wanted_heading, 360) < 180)
        ? 'left'
        : 'right');
}

#-------------------------------------------------------------------------------
#                                                              get_aircraft_info
# 
var get_aircraft_info = func() {
    var a = {};

    a['callsign']     = getprop("/sim/multiplay/callsign") or 'callsig';
    a['heading']      = getprop("/orientation/heading-magnetic-deg") or 0;
    a['altitude']     = getprop("/position/altitude-ft") or 0;
    a['speed']        = getprop("/velocities/airspeed-kt") or 0;
    a['is_gear_down'] = getprop("/controls/gear/gear-down") or 0;
    a['is_wow']       = getprop("/gear/gear[0]/wow") or 0;

    return a;
}

#-------------------------------------------------------------------------------
#                                                               get_airport_info
# 
var get_airport_info = func() {
    var a = {};

    # get some info on airport
    a['id'] = getprop("/sim/airport/closest-airport-id") or '';
    var arpt = airportinfo(a['id']);
    a['name']         = arpt.name;
    a['elevation_ft'] = (3.28 * arpt.elevation);

    # get longest runway
    var longest_rwy_id = '';
    var longest_rwy    = 0;
    var runways = arpt.runways;
    var rwy_keys = sort(keys(runways), string.icmp);
    foreach(var rwy_id; rwy_keys)
    {
        var r = runways[rwy_id];
        if(r.length > longest_rwy)
        {
            longest_rwy    = r.length;
            longest_rwy_id = rwy_id;
        }
    }
    my_runway = runways[longest_rwy_id];
    a['rwy']        = longest_rwy_id;
    a['heading']    = my_runway.heading;
    a['lng']        = my_runway.lon;
    a['lat']        = my_runway.lat;
    a['rwy_length'] = my_runway.length * 3.28;

    return a;
}

#-------------------------------------------------------------------------------
#                                                 find_in_which_zone_is_aircraft
# l idee est de faire une rotation puis translation de l ensemble
# l aeroport etant au centre de la zone qui a pour coord gps 0,0
# on doit donc aussi rotationner et translater les coords de l avion
# on recupere l angle + distance actuels de l avion par rapport a
# l aeroport
var find_in_which_zone_is_aircraft = func(lat, lng, heading, aircraft_bearing, aircraft_dist_nm) {

    var atc_zone = [
        {
            'id': 'zone1',
            'top_left_x': -.2,
            'top_left_y': 0,
            'bottom_right_x': -.015,
            'bottom_right_y': -.2,
            'speed': 200,
            'heading': 0,
            'alt': 2500,
            'circuit': 'entrance',
        },
        {
            'id': 'zone2_1',
            'top_left_x': -.2,
            'top_left_y': .1,
            'bottom_right_x': .1,
            'bottom_right_y': 0,
            'speed': 200,
            'heading': 90,
            'alt': 2500,
            'circuit': 'crosswind',
        },
        {
            'id': 'zone2_2',
            'top_left_x': .015,
            'top_left_y': 0,
            'bottom_right_x': .1,
            'bottom_right_y': -.1,
            'speed': 150,
            'heading': 90,
            'alt': 1500,
            'circuit': 'crosswind',
        },
        {
            'id': 'zone3_1',
            'top_left_x': .1,
            'top_left_y': .1,
            'bottom_right_x': .2,
            'bottom_right_y': -.15,
            'speed': 150,
            'heading': 180,
            'alt': 1500,
            'circuit': 'downwind',
        },
        {
            'id': 'zone3_2',
            'top_left_x': .05,
            'top_left_y': -.1,
            'bottom_right_x': .1,
            'bottom_right_y': -.15,
            'speed': 150,
            'heading': 180,
            'alt': 1500,
            'circuit': 'downwind',
        },
        {
            'id': 'zone4',
            'top_left_x': .015,
            'top_left_y': -.1,
            'bottom_right_x': .05,
            'bottom_right_y': -.2,
            'speed': 150,
            'heading': 315,
            'alt': 1500,
            'circuit': 'base',
        },
        {
            'id': 'zone5',
            'top_left_x': .05,
            'top_left_y': -.15,
            'bottom_right_x': .2,
            'bottom_right_y': -.2,
            'speed': 150,
            'heading': 270,
            'alt': 1500,
            'circuit': 'base',
        },
        {
            'id': 'zone6',
            'top_left_x': -.015,
            'top_left_y': 0,
            'bottom_right_x': .015,
            'bottom_right_y': -.2,
            'speed': 150,
            'heading': 0,
            'alt': 1500,
            'circuit': 'final',
        },
    ];

    var coord = geo.Coord.new();
    coord.set_latlon(lat, lng);

    # on rotationnes les coordonnees de l avion
    var rotated_aircraft_position = coord.apply_course_distance((aircraft_bearing - heading), (aircraft_dist_nm * NM2M));

    # et on translate les coordonnees de l avion
    var translated_aircraft_lat = rotated_aircraft_position.lat() - lat;
    var translated_aircraft_lng = rotated_aircraft_position.lon() - lng;

    # a ce moment on a un aeroport avec la piste la plus longue alignee
    # vers le nord, les coordonnes de l aeroport sont 0, 0
    # les coordonnees de l avion ont ete transposees dans le nouveau repere
    # on recherche alors dans quelle zone l avion se trouve
    foreach(var zone; atc_zone)
    {
        if((translated_aircraft_lng > zone['top_left_x'])
            and (translated_aircraft_lng < zone['bottom_right_x'])
            and (translated_aircraft_lat > zone['bottom_right_y'])
            and (translated_aircraft_lat < zone['top_left_y']))
        {
            return zone;
        }
    }

    # if not found, return default zone
    var zone = {
        'id': 'OUTSIDE',
        'speed': 300,
        'heading': 0,
        'alt': 5000,
        'circuit': 'outside',
    };

    return zone
}

#-------------------------------------------------------------------------------
#                                                                assistance_loop
# 
var assistance_loop = func() {

    var is_enabled = getprop("/controls/assistance") or 0;

    if(is_enabled == 1)
    {
        # get some info on aircraft
        aircraft = get_aircraft_info();

        # end of assistance if landed
        if(aircraft['is_wow'])
        {
            is_enabled = 0;
            setprop("/controls/assistance", is_enabled);

            assistance_message = "You landed, congratulations, have a good day ! Over.";
            print(assistance_message);
            setprop("/sim/messages/atc", assistance_message);
        }

        # on recupere l aeroport le plus proche si il n a pas deja ete choisi
        # on fait ca pour eviter la bascule vers un nouvel aeroport plus proche
        # lorsqu on navigue dans le circuit
        if(airport['id'] == '')
        {
            airport = get_airport_info();

            assistance_message = sprintf(
                    "%s, You asked for assistance, I will help you to reach the closest airport : %s",
                    aircraft['callsign'],
                    airport['id']);
            print(assistance_message);
            setprop("/sim/messages/atc", assistance_message);

            assistance_message = sprintf(
                    "Follow my instructions, heading in magnetic, set altitude %.2f inhg",
                    getprop("/environment/pressure-sea-level-inhg"));
            print(assistance_message);
            setprop("/sim/messages/atc", assistance_message);

            #printf("DEBUG : AIRPORT %s - %s - %s - %s - %d - RUNWAY %s - %d - %d", airport['id'], airport['name'], airport['lng'], airport['lat'], airport['elevation_ft'], airport['rwy'], airport['rwy_length'], airport['heading']);
            #DEBUG : AIRPORT LFRQ - Quimper Pluguffan - -4.1722096 - 47.972947 - 296 - RUNWAY 10 - 7052 - 93
        }

        # on recupere les coordonnees de l aeroport et de l avion
        coord_airport.set_latlon(airport['lat'], airport['lng']);
        coord_aircraft = geo.aircraft_position();

        var from = coord_airport;
        var to = coord_aircraft;
        var (aircraft_bearing_from_airport, dist_nm) = courseAndDistance(from, to);
        var airport_bearing_from_aircraft = math.mod((aircraft_bearing_from_airport + 180), 360);
        var zone = find_in_which_zone_is_aircraft(airport['lat'], airport['lng'], airport['heading'], aircraft_bearing_from_airport, dist_nm);

        atc['heading'] = math.mod(airport['heading'] + zone['heading'], 360);
        atc['speed']   = zone['speed'];
        atc['alt']     = (sprintf('%d', zone['alt'] / 100) + sprintf('%d', airport['elevation_ft'] / 100)) * 100;
        atc['circuit'] = zone['circuit'];

        var assistance_message            = '';
        var assistance_message_header     = sprintf('atc %s, %s.', airport['id'], aircraft['callsign']);
        var assistance_message_horizontal = '';
        var assistance_message_vertical   = '';
        var assistance_message_vitesse    = '';
        var assistance_message_bonus      = '';


# GESTION DES MESSAGES POUR LA PARTIE HORIZONTALE
        # on gere differemment selon si l avion est dans ou hors zone
        if(atc['circuit'] != 'outside')
        {
            # avion en finale
            # zone final leg :
            if(atc['circuit'] == 'final')
            {
                # message de correction d alignement avec la piste
                # alignment with runway
                var correction = math.mod((airport_bearing_from_aircraft + (airport_bearing_from_aircraft - airport['heading']) * 2), 360);

                if(sprintf('%d', aircraft['heading']) != sprintf('%d', correction))
                {
                    assistance_message_horizontal = sprintf('%s leg, align to runway %s, turn %s heading %03d.',
                        atc['circuit'],
                        airport['rwy'],
                        turn_left_or_right(aircraft['heading'], correction),
                        correction);
                }
                else
                {
                    assistance_message_horizontal = sprintf('%s leg, align to runway %s, maintain heading %03d.',
                        atc['circuit'],
                        airport['rwy'],
                        correction);
                }
            }
            elsif(math.cos((aircraft['heading'] - atc['heading']) * D2R) > math.cos(5 * D2R))
            {
                # autres zones, l avion est au cap correct dans le circuit
                # other zones - maintain
                assistance_message_horizontal = sprintf('%s leg, maintain heading %03d.',
                    atc['circuit'],
                    atc['heading']);
            }
            else
            {
                # autres zones
                # other zones - turn
                assistance_message_horizontal = sprintf('%s leg, turn %s heading %03d.',
                    atc['circuit'],
                    turn_left_or_right(aircraft['heading'], atc['heading']),
                    atc['heading']);
            }
        }
        else
        {
            if(h == 0) h = airport_bearing_from_aircraft;
            if(d == 0) d = dist_nm;
            if(nb_cycle == 1)
            {
                h = airport_bearing_from_aircraft;
                d = dist_nm;
            }
            # avion hors zone, on va donner a l avion le cap direct vers l aeroport
            assistance_message_horizontal = sprintf('turn %s heading %03d - airport at %d NM.',
                turn_left_or_right(aircraft['heading'], airport_bearing_from_aircraft),
                h,
                d);
        }

# GESTION DES MESSAGES POUR LA PARTIE VERTICALE
        # avion en finale
        if(atc['circuit'] == 'final')
        {
            assistance_message_vertical = sprintf('airport altitude:%d ft.',
                airport['elevation_ft']);
        }
        elsif(atc['circuit'] == 'outside')
        {
            assistance_message_vertical = '';
        }
        elsif(aircraft['altitude'] > (atc['alt'] + 100))
        {
            assistance_message_vertical = sprintf('descend to %d ft.',
                atc['alt']);
        }
        elsif(aircraft['altitude'] < (atc['alt'] - 100))
        {
            assistance_message_vertical = sprintf('climb to %d ft.',
                atc['alt']);
        }
        else
        {
            assistance_message_vertical = sprintf('maintain %d ft.',
                atc['alt']);
        }

# GESTION DES MESSAGES POUR LA PARTIE VITESSE
        # avion en finale
        if(atc['circuit'] == 'final')
        {
            assistance_message_vitesse = '';
        }
        elsif(aircraft['speed'] > (atc['speed'] + 20))
        {
            assistance_message_vitesse = sprintf('lower speed to %d kt.',
                atc['speed']);
        }
        elsif(aircraft['speed'] < (atc['speed'] - 20))
        {
            assistance_message_vitesse = sprintf('raise speed to %d kt.',
                atc['speed']);
        }
        else
        {
            assistance_message_vitesse = sprintf('maintain speed %d kt.',
                atc['speed']);
        }

        if(((atc['circuit'] == 'downwind') or (atc['circuit'] == 'base') or (atc['circuit'] == 'final'))
            and (aircraft['is_gear_down'] == 0))
        {
            assistance_message_bonus = 'check gears down.';
        }

# AFFICHAGE DES MESSAGES
        assistance_message = sprintf('%s %s %s %s %s',
            assistance_message_header,
            assistance_message_horizontal,
            assistance_message_vertical,
            assistance_message_vitesse,
            assistance_message_bonus);

        if(assistance_message != previous_assistance_message)
        {
            print(assistance_message);
            setprop("/sim/messages/atc", assistance_message);
            previous_assistance_message = assistance_message;
        }
        elsif(nb_cycle > 10)
        {
            nb_cycle = 0;
            setprop("/sim/messages/atc", assistance_message);
        }
        nb_cycle += 1;
    }
    else
    {
        # assistance disabled
        airport['id'] = '' ;
    }
    settimer(assistance_loop, 1);
}

setlistener("/sim/signals/fdm-initialized", assistance_loop);











