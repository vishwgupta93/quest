trigger SFOMFOCancellationTrigger on SFOM_Fulfillment_Order_Cancel_Event__e (after insert) {
Map<String,Boolean> foIdsMap= new Map<String,Boolean>();
 

 for (SFOM_Fulfillment_Order_Cancel_Event__e event : Trigger.New) {
      if(event.Fulfillment_Order_Id__c!=null ) {
        foIdsMap.put(event.Fulfillment_Order_Id__c,event.Kit_Activated__c);
                  }
 }
 
 for(String foId : foIdsMap.keySet())
 {
     FOCancelEventTriggerHandler.sendPayLoad(foId ,foIdsMap.get(foId));
 }
}