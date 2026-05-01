/* Used an apex trigger instead of flow because this is called from SFCC and 
   the integration user doesnt have access to Fulfillment order creation API.
   This Trigger changes the execution context from User to System mode. 
**/
trigger SFOMKitActivationTrigger on SFOM_Kit_Activation__e (after insert) {
 List<SFOM_Kit_Activation__e> eventLst = new List<SFOM_Kit_Activation__e>();

    for (SFOM_Kit_Activation__e event : Trigger.New) {
         if(!event.Activate_Kit__c && event.Shipment_Line_Item_Id__c!=null) {
            eventLst.add(new SFOM_Kit_Activation__e(Shipment_Line_Item_Id__c=event.Shipment_Line_Item_Id__c,Activate_Kit__c=true));
         }
    }
    
    if(eventLst!=null && eventLst.size()>0) {
           EventBus.publish(eventLst);
    }
}