/* 
   Used to generate Shipment Event messages and drop in Mule Endpoint
     
**/
trigger SFOMShipmentEventTrigger on SFOM_Shipping_Notifications__e (after insert) {
Set<String> foIds = new Set<String>();
 

 for (SFOM_Shipping_Notifications__e event : Trigger.New) {
      if(event.Fulfillment_Order_Id__c!=null && !foIds.contains(event.Fulfillment_Order_Id__c)) {
         foIds.add(event.Fulfillment_Order_Id__c); 
         ShipmentEventTriggerHandler.sendPayload(event.Fulfillment_Order_Id__c);
      }
 }
}