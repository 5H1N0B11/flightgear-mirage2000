#

OmniRadar = {
	new: func (rate) {
		var nr = {parents: [OmniRadar, Radar]};

		nr.vector_aicontacts = [];
		nr.vector_aicontacts_for = [];
		nr.timer          = maketimer(rate, nr, func nr.scan());

		nr.OmniRadarRecipient = emesary.Recipient.new("OmniRadarRecipient");
		nr.OmniRadarRecipient.radar = nr;
		nr.OmniRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "AINotification") {
	        	#printf("NoseRadar recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.vector_aicontacts = notification.vector;
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(nr.OmniRadarRecipient);
		nr.OmniNotification = VectorNotification.new("OmniNotification");
		nr.OmniNotification.updateV(nr.vector_aicontacts_for);
		nr.timer.start();
		return nr;
	},

	scan: func () {
		if (!enableRWR) return;
		me.vector_aicontacts_for = [];
		foreach(contact ; me.vector_aicontacts) {
			if (!contact.isVisible()) { # moved to omniradar
				continue;
			}
			me.ber = contact.getBearing();
			me.head = contact.getHeading();
			me.test = me.ber+180-me.head;
			me.tp = contact.isTransponderEnable();
			me.radar = contact.isRadarEnable();
            if (math.abs(geo.normdeg180(me.test)) < 60 or me.tp) {
            	contact.storeThreat([me.ber,me.head,contact.getCoord(),me.tp,me.radar,contact.getDeviationHeading(),contact.getRangeDirect()*M2NM]);
				append(me.vector_aicontacts_for, contact);
			}
		}		
		emesary.GlobalTransmitter.NotifyAll(me.OmniNotification.updateV(me.vector_aicontacts_for));
		#print("In omni Field: "~size(me.vector_aicontacts_for));
	},
};
