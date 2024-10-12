print("*** LOADING rwr.nas ... ***");

var lineWidth = 3;

RWRCanvas = {
    new: func (_ident, root, center, diameter) {
        var rwr = {parents: [RWRCanvas]};
        rwr.max_icons = 12;
        var radius = diameter/2;
        rwr.inner_radius = radius*0.30;
        rwr.outer_radius = radius*0.75;
        rwr.circle_radius_big = radius*0.5;
        rwr.circle_radius_small = radius*0.125;
        var tick_long = radius*0.25;
        var tick_short = tick_long*0.5;
        var font = int(0.08*diameter);
        var colorG = [0.3,1,0.3];
        var colorLG = [0,0.5,0];
        rwr.fadeTime = 7; #seconds
        rwr.rootCenter = root.createChild("group")
                .setTranslation(center[0],center[1]);
        var rootOffset = root.createChild("group")
                .setTranslation(center[0]-diameter/2,center[1]-diameter/2);

        rootOffset.createChild("path") # inner circle
           .moveTo(diameter/2-rwr.circle_radius_small, diameter/2)
           .arcSmallCW(rwr.circle_radius_small, rwr.circle_radius_small, 0, rwr.circle_radius_small*2, 0)
           .arcSmallCW(rwr.circle_radius_small, rwr.circle_radius_small, 0, -rwr.circle_radius_small*2, 0)
           .setStrokeLineWidth(lineWidth)
           .setColor(colorLG);
        rootOffset.createChild("path") # outer circle
           .moveTo(diameter/2-rwr.circle_radius_big, diameter/2)
           .arcSmallCW(rwr.circle_radius_big, rwr.circle_radius_big, 0, rwr.circle_radius_big*2, 0)
           .arcSmallCW(rwr.circle_radius_big, rwr.circle_radius_big, 0, -rwr.circle_radius_big*2, 0)
           .setStrokeLineWidth(lineWidth)
           .setColor(colorLG);
        rootOffset.createChild("path") # cross in the middle
           .moveTo(diameter/2-rwr.circle_radius_small/2, diameter/2)
           .lineTo(diameter/2+rwr.circle_radius_small/2, diameter/2)
           .moveTo(diameter/2, diameter/2-rwr.circle_radius_small/2)
           .lineTo(diameter/2, diameter/2+rwr.circle_radius_small/2)
           .setStrokeLineWidth(lineWidth)
           .setColor(colorLG);
        rootOffset.createChild("path") #
           .moveTo(0,diameter*0.5)
           .horiz(tick_long)
           .moveTo(diameter,diameter*0.5)
           .horiz(-tick_long)
           .moveTo(diameter*0.5,0)
           .vert(tick_long)
           .moveTo(diameter*0.5,diameter)
           .vert(-tick_long)
           .setStrokeLineWidth(lineWidth)
           .setColor(colorLG);
        rwr.rootCenter.createChild("path") # ticks like clock at outer ring
           .moveTo(radius*math.cos(30*D2R),radius*math.sin(-30*D2R))
           .lineTo((radius-tick_short)*math.cos(30*D2R),(radius-tick_short)*math.sin(-30*D2R))
           .moveTo(radius*math.cos(60*D2R),radius*math.sin(-60*D2R))
           .lineTo((radius-tick_short)*math.cos(60*D2R),(radius-tick_short)*math.sin(-60*D2R))
           .moveTo(radius*math.cos(30*D2R),radius*math.sin(30*D2R))
           .lineTo((radius-tick_short)*math.cos(30*D2R),(radius-tick_short)*math.sin(30*D2R))
           .moveTo(radius*math.cos(60*D2R),radius*math.sin(60*D2R))
           .lineTo((radius-tick_short)*math.cos(60*D2R),(radius-tick_short)*math.sin(60*D2R))

           .moveTo(-radius*math.cos(30*D2R),radius*math.sin(-30*D2R))
           .lineTo(-(radius-tick_short)*math.cos(30*D2R),(radius-tick_short)*math.sin(-30*D2R))
           .moveTo(-radius*math.cos(60*D2R),radius*math.sin(-60*D2R))
           .lineTo(-(radius-tick_short)*math.cos(60*D2R),(radius-tick_short)*math.sin(-60*D2R))
           .moveTo(-radius*math.cos(30*D2R),radius*math.sin(30*D2R))
           .lineTo(-(radius-tick_short)*math.cos(30*D2R),(radius-tick_short)*math.sin(30*D2R))
           .moveTo(-radius*math.cos(60*D2R),radius*math.sin(60*D2R))
           .lineTo(-(radius-tick_short)*math.cos(60*D2R),(radius-tick_short)*math.sin(60*D2R))
           .setStrokeLineWidth(lineWidth)
           .setColor(colorLG);
        rwr.texts = setsize([],rwr.max_icons);
        for (var i = 0;i<rwr.max_icons;i+=1) {
            rwr.texts[i] = rwr.rootCenter.createChild("text")
                .setText("00")
                .setAlignment("center-center")
                .setColor(colorG)
                .setFontSize(font, 1.0)
                .hide();

        }
        rwr.symbol_hat = setsize([],rwr.max_icons);
        for (var i = 0;i<rwr.max_icons;i+=1) {
            rwr.symbol_hat[i] = rwr.rootCenter.createChild("path")
                    .moveTo(0,-font)
                    .lineTo(font*0.7,-font*0.5)
                    .moveTo(0,-font)
                    .lineTo(-font*0.7,-font*0.5)
                    .setStrokeLineWidth(lineWidth)
                    .setColor(colorG)
                    .hide();
        }
        rwr.symbol_launch = setsize([],rwr.max_icons);
        for (var i = 0;i<rwr.max_icons;i+=1) {
            rwr.symbol_launch[i] = rwr.rootCenter.createChild("path")
                    .moveTo(font*1.2, 0)
                    .arcSmallCW(font*1.2, font*1.2, 0, -font*2.4, 0)
                    .arcSmallCW(font*1.2, font*1.2, 0, font*2.4, 0)
                    .setStrokeLineWidth(lineWidth)
                    .setColor(colorG)
                    .hide();
        }
        rwr.symbol_new = setsize([],rwr.max_icons);
        for (var i = 0;i<rwr.max_icons;i+=1) {
            rwr.symbol_new[i] = rwr.rootCenter.createChild("path")
                    .moveTo(font*1.2, 0)
                    .arcSmallCCW(font*1.2, font*1.2, 0, -font*2.4, 0)
                    .setStrokeLineWidth(lineWidth)
                    .setColor(colorG)
                    .hide();
        }
        rwr.symbol_priority = rwr.rootCenter.createChild("path")
                    .moveTo(0, font*1.2)
                    .lineTo(font*1.2, 0)
                    .lineTo(0,-font*1.2)
                    .lineTo(-font*1.2,0)
                    .lineTo(0, font*1.2)
                    .setStrokeLineWidth(lineWidth)
                    .setColor(colorG)
                    .hide();

        rwr.AIRCRAFT_UNKNOWN  = "U";
        rwr.ASSET_AI          = "AI";
        rwr.AIRCRAFT_SEARCH   = "S";

        rwr.shownList = [];
        #
        # recipient that will be registered on the global transmitter and connect this
        # subsystem to allow subsystem notifications to be received
        rwr.recipient = emesary.Recipient.new(_ident);
        rwr.recipient.parent_obj = rwr;

        rwr.recipient.Receive = func(notification)
        {
            if (notification.NotificationType == "FrameNotification" and notification.FrameCount == 2)
            {
                me.parent_obj.update(radar_system.f16_rwr.vector_aicontacts_threats, "normal");
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        emesary.GlobalTransmitter.Register(rwr.recipient);

        return rwr;
    },
    assignSepSpot: func {
        # me.dev        angle_deg
        # me.sep_spots  0 to 2  45, 20, 15
        # me.threat     0 to 2
        # me.sep_angles
        # return   me.dev,  me.threat
        me.newdev = me.dev;
        me.assignIdealSepSpot();
        me.plus = me.sep_angles[me.threat];
        me.dir  = 0;
        me.count = 1;
        while(me.sep_spots[me.threat][me.spot] and me.count < size(me.sep_spots[me.threat])) {

            if (me.dir == 0) me.dir = 1;
            elsif (me.dir > 0) me.dir = -me.dir;
            elsif (me.dir < 0) me.dir = -me.dir+1;

            #printf("%2s: Spot %d taken. Trying %d direction.",me.typ, me.spot, me.dir);

            me.newdev = me.dev + me.plus * me.dir;

            me.assignIdealSepSpot();
            me.count += 1;
        }

        me.sep_spots[me.threat][me.spot] += 1;

        # finished assigning spot
        #printf("%2s: Spot %d assigned. Ring=%d",me.typ, me.spot, me.threat);
        me.dev = me.spot * me.plus;
        if (me.threat == 0) {
            me.threat = me.sep1_radius;
        } elsif (me.threat == 1) {
            me.threat = me.sep2_radius;
        } elsif (me.threat == 2) {
            me.threat = me.sep3_radius;
        }
    },
    assignIdealSepSpot: func {
        me.spot = math.round(geo.normdeg(me.newdev)/me.sep_angles[me.threat]);
        if (me.spot >= size(me.sep_spots[me.threat])) me.spot = 0;
    },
    update: func (list, type) {
		me.sep = 0; # not yet implemented - in F16 getprop("f16/ews/rwr-separate");
        me.showUnknowns = 1;
        me.elapsed = getprop("sim/time/elapsed-sec");
        me.pri5 = 0;  #only used to align with F16
        var sorter = func(a, b) {
            if(a[1] > b[1]){
                return -1; # A should before b in the returned vector
            }elsif(a[1] == b[1]){
                return 0; # A is equivalent to b
            }else{
                return 1; # A should after b in the returned vector
            }
        }
        me.sortedlist = sort(list, sorter);

        me.sep_spots = [[0,0,0,0,0,0,0,0],#45 degs  8
                        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],# 20 degs  18
                        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]];# 15 degs  24
        me.sep_angles = [45,20,15];

        me.newList = [];
        me.i = 0;
        me.prio = 0;
        me.newsound = 0;
        me.priCount = 0; # only added to align with F16 - not used
        me.priFlash = 0; # only added to align with F16 - not used
        me.unkFlash = 0; # aligned with F16 - although in the M2000 it is a sound not a flash
        foreach(me.contact; me.sortedlist) {
            me.dbEntry = radar_system.getDBEntry(me.contact[0].getModel());
            me.typ = me.dbEntry.rwrCode;
            if (me.i > me.max_icons-1) {
                break;
            }
            if (me.typ == nil) {
                me.typ = me.AIRCRAFT_UNKNOWN;
                if (!me.showUnknowns) {
                  me.unkFlash = 1;
                  continue;
                }
            }
            if (me.typ == me.ASSET_AI) {
                if (!me.showUnknowns) {
                  #me.unkFlash = 1; # We don't flash for AI, that would just be distracting
                  continue;
                }
            }
            if (me.contact[0].get_range() > 170) { # deviates from F16, which has 150
                continue;
            }

            me.threat = me.contact[1];#print(me.threat);

            if (me.threat <= 0) {
                continue;
            }

            if (me.pri5 and me.priCount >= 5) {
                me.priFlash = 1;
                continue;
            }
            me.priCount += 1;



            if (!me.sep) {

                if (me.threat > 0.5 and me.typ != me.AIRCRAFT_UNKNOWN and me.typ != me.AIRCRAFT_SEARCH) {
                    me.threat = me.inner_radius;# inner circle
                } else {
                    me.threat = me.outer_radius;# outer circle
                }

                me.dev = -me.contact[2]+90;
            } else {
                me.dev = -me.contact[2]+90;

                if (me.threat > 0.5 and me.typ != me.AIRCRAFT_UNKNOWN and me.typ != me.AIRCRAFT_SEARCH) {
                    me.threat = 0;
                } elsif (me.threat > 0.25) {
                    me.threat = 1;
                } else {
                    me.threat = 2;
                }
                me.assignSepSpot();
            }




            me.x = math.cos(me.dev*D2R)*me.threat;
            me.y = -math.sin(me.dev*D2R)*me.threat;
            me.texts[me.i].setTranslation(me.x,me.y);
            me.texts[me.i].setText(me.typ);
            me.texts[me.i].show();
            if (me.prio == 0 and me.typ != me.ASSET_AI and me.typ != me.AIRCRAFT_UNKNOWN) {#
                me.symbol_priority.setTranslation(me.x,me.y);
                me.symbol_priority.show();
                me.prio = 1;
            }
            if (me.contact[0].getType() == armament.AIR) {
                #air-borne
                me.symbol_hat[me.i].setTranslation(me.x,me.y);
                me.symbol_hat[me.i].show();
            } else {
                me.symbol_hat[me.i].hide();
            }
            if (me.contact[0].get_Callsign()==getprop("sound/rwr-launch") and 10*(me.elapsed-int(me.elapsed))>5) {#blink 2Hz
                me.symbol_launch[me.i].setTranslation(me.x,me.y);
                me.symbol_launch[me.i].show();
            } else {
                me.symbol_launch[me.i].hide();
            }
            me.popupNew = me.elapsed;
            foreach(me.old; me.shownList) {
                if(me.old[0].getUnique()==me.contact[0].getUnique()) {
                    me.popupNew = me.old[1];
                    break;
                }
            }
            if (me.popupNew == me.elapsed) {
                me.newsound = 1;
            }
            if (me.popupNew > me.elapsed-me.fadeTime) {
                me.symbol_new[me.i].setTranslation(me.x,me.y);
                me.symbol_new[me.i].show();
                me.symbol_new[me.i].update();
            } else {
                me.symbol_new[me.i].hide();
            }
            #printf("display %s %d",contact[0].get_Callsign(), me.threat);
            append(me.newList, [me.contact[0],me.popupNew]);
            me.i += 1;
        }
        me.shownList = me.newList;
        for (;me.i<me.max_icons;me.i+=1) {
            me.texts[me.i].hide();
            me.symbol_hat[me.i].hide();
            me.symbol_new[me.i].hide();
            me.symbol_launch[me.i].hide();
        }
        if (me.prio == 0) {
            me.symbol_priority.hide();
        }
        if (me.newsound == 1) setprop("sound/rwr-new", !getprop("sound/rwr-new"));
        setprop("sound/rwr-pri", me.prio);
        setprop("sound/rwr-unk", me.unkFlash);
    },
};
var rwr = nil;
var cv = nil;

var setGroup = func (root) {
    root.createChild("path").horiz(768).vert(576).horiz(-768).vert(-576).setColorFill(0,0,0).setColor(0,0,0);
    rwr = RWRCanvas.new("RWRCanvas",root, [768/2,576/2],576);
};
