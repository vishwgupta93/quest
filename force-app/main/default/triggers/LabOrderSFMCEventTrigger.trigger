trigger LabOrderSFMCEventTrigger on Lab_Order_SFMC_Event__e (after insert) {

    Set<String> labOrderIds = new Set<String>();
 

        for (Lab_Order_SFMC_Event__e event : Trigger.New) {

            if(event.Event_Type__c == Label.SFMC_Lab_Order_Register_Event && labOrderIds.add(event.Lab_Order_Id__c)) {
                LabOrderRegistrationHandler.sendPayLoad(event.Lab_Order_Id__c,event.EventDefinitionKey__c
                                                 )   ;
            }
            else if(event.Event_Type__c == Label.SFMC_Partner_Lab_Order_Confirmation_Event && labOrderIds.add(event.Lab_Order_Id__c)) {
                PartnerLabOrderConfirmationHandler.sendPayLoad(event.Lab_Order_Id__c,event.EventDefinitionKey__c
                                                 )   ;
            }
            else if(event.Event_Type__c == Label.SFMC_Results_Ready_Event && labOrderIds.add(event.Lab_Order_Id__c)) {
                LabOrderResultsHandler.sendPayLoad(event.Lab_Order_Id__c,event.EventDefinitionKey__c,event.Test_type__c,event.MFA_Enabled__c);
            }
            else if(event.Event_Type__c == Label.SFMC_Order_Cancel_Event && labOrderIds.add(event.Lab_Order_Id__c)) {
               LabOrderCancellationEmailEventHandler.sendPayLoad(event.Lab_Order_Id__c, event.Test_type__c, event.EventDefinitionKey__c);
            }
            else if(event.Event_Type__c == Label.SFMC_HRA_Email_Trigger_Event && labOrderIds.add(event.Lab_Order_Id__c)) {
                HRAEmailAPI.captureOrderDetails(event.Lab_Order_Id__c, event.Event_Type__c, event.EventDefinitionKey__c);
            }
        }

}