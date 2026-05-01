trigger PartnerOrderSFMCEventTrigger on Partner_Order_SFMC_Event__e (after insert) {

    Set<String> partnerOrderIds = new Set<String>();
 

        for (Partner_Order_SFMC_Event__e event : Trigger.New) {

            if(event.Event_Definition_Key__c == Label.SFMC_Partner_Order_Purchase_Confirmation && partnerOrderIds.add(event.Partner_Order_Id__c)) {
                POPurchaseConfirmationEmailHandler.sendPayLoad(event.Partner_Order_Id__c,event.Event_Definition_Key__c
                                                 )   ;
            }
            else if(event.Event_Definition_Key__c == Label.SFMC_Partner_Order_Shipment_Confirmation && partnerOrderIds.add(event.Partner_Order_Id__c)) {
                POShipmentConfirmationEmailHandler.sendPayLoad(event.Partner_Order_Id__c,event.Event_Definition_Key__c);
            }
        }

}