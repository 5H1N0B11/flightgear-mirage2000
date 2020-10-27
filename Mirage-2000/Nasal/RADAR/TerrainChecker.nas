#

TerrainChecker = {
	new: func (rate) {
		var nr = {parents: [TerrainChecker]};

		nr.vector_aicontacts = [];
		nr.timer          = maketimer(rate, nr, func nr.scan());

		nr.TerrainCheckerRecipient = emesary.Recipient.new("TerrainCheckerRecipient");
		nr.TerrainCheckerRecipient.radar = nr;
		nr.TerrainCheckerRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "AINotification") {
	        	#printf("NoseRadar recv: %s", notification.NotificationType);
	    		me.radar.vector_aicontacts = notification.vector;
	    		me.radar.index = 0;
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(nr.TerrainCheckerRecipient);
		nr.index = 0;
		nr.timer.start();
		return nr;
	},

	scan: func () {
		#this loop is really fast. But we only check 1 contact per call
		if (me.index > size(me.vector_aicontacts)-1) {
			# will happen if there is no contacts
			return;
		}
		me.contact = me.vector_aicontacts[me.index];
        me.contact.setVisible(me.terrainCheck(me.contact));
        me.index += 1;
        if (me.index > size(me.vector_aicontacts)-1) {
        	me.index = 0;
        }
	},

	terrainCheck: func (contact) {
		me.myOwnPos = contact.getAcCoord();
		me.SelectCoord = contact.getCoord();
		if(me.myOwnPos.alt() > 8900 and me.SelectCoord.alt() > 8900) {
	      # both higher than mt. everest, so not need to check.
	      return TRUE;
	    }
	    
		me.xyz = {"x":me.myOwnPos.x(),                  "y":me.myOwnPos.y(),                 "z":me.myOwnPos.z()};
		me.dir = {"x":me.SelectCoord.x()-me.myOwnPos.x(),  "y":me.SelectCoord.y()-me.myOwnPos.y(), "z":me.SelectCoord.z()-me.myOwnPos.z()};

		# Check for terrain between own aircraft and other:
		me.v = get_cart_ground_intersection(me.xyz, me.dir);
		if (me.v == nil) {
			return TRUE;
			#printf("No terrain, planes has clear view of each other");
		} else {
			me.terrain = geo.Coord.new();
			me.terrain.set_latlon(me.v.lat, me.v.lon, me.v.elevation);
			me.maxDist = me.myOwnPos.direct_distance_to(me.SelectCoord);
			me.terrainDist = me.myOwnPos.direct_distance_to(me.terrain);
			if (me.terrainDist < me.maxDist) {
		 		#print("terrain found between the planes");
		 		return FALSE;
			} else {
		  		return TRUE;
		  		#print("The planes has clear view of each other");
			}
		}
	},
};
