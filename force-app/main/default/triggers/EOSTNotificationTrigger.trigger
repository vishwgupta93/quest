trigger EOSTNotificationTrigger on EOST_Platorm_Event__e (after insert) {

    Set<String> batchIds = new Set<String>();
 

    for (EOST_Platorm_Event__e event : Trigger.New) {
         if(event.Event_Type__c == Label.EOST_OMS_Payload_Process ) {
            batchIds.add(event.Batch_ID__c);
                     }
    }
    
    for(String batchId : batchIds)
    {
        EOSTOMSNotificationTranslator.formNotificationDetail(batchId);
    }

}