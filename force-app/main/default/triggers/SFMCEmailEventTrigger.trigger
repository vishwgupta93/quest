trigger SFMCEmailEventTrigger on SFMC_Email_Event__e (after insert) {

    
        
Set<String> summaryIds = new Set<String>();
 

 for (SFMC_Email_Event__e event : Trigger.New) {
        
      if(event.Event_Type__c == Label.SFMC_Order_Confirm_Event && summaryIds.add(event.Order_Summary_Id__c)) {
          EmailEventHandler.sendPayLoad(event.Order_Summary_Id__c,event.EventDefinitionKey__c
                                       )   ;
                                       
            // if(event.Send_Survey_Email__c)
            // {
            //     SurveyEmailEventHandler.sendPayLoad(event.Order_Summary_Id__c,Label.SFMC_Post_Purchase_Survey_Event_Definition_Key
            //     )   ; 
            // }
              }
       
        else if(event.Event_Type__c == Label.SFMC_Results_Ready_Event && summaryIds.add(event.Order_Summary_Id__c)) {
            if(!event.Is_Kit_Event__c)
            {
                ResultsEmailEventHandler.sendPayLoad(event.Order_Summary_Id__c,event.EventDefinitionKey__c,event.Test_type__c
                                             )   ;               
            }
            else {
                KitsResultsEventHandler.sendPayLoad(event.Order_Summary_Id__c,event.EventDefinitionKey__c,event.Test_type__c, event.Email__c, event.Customer_ID__c, event.Is_Partner_Order__c);
            } 
            }
              
        else if(event.Event_Type__c == Label.SFMC_Order_Cancel_Event && summaryIds.add(event.Order_Summary_Id__c)) {
            CancelEmailEventHandler.sendPayLoad(event.Order_Summary_Id__c,event.EventDefinitionKey__c,event.Test_type__c
                                                         )   ;               
            }  

         else if(event.Event_Type__c == Label.SFMC_Payment_Capture_Event && summaryIds.add(event.Order_Summary_Id__c)) {
            PaymentCaptureEmailEventHandler.sendPayLoad(event.Order_Summary_Id__c,event.EventDefinitionKey__c,event.Test_type__c
                                                             )   ;
                                                             
        
                }  
        
         else if(event.Event_Type__c == Label.SFMC_Kit_Events && summaryIds.add(event.Kit_Detail_ID__c)) {
            KitStatusEventHandler.sendPayLoad(event.Kit_Detail_ID__c,event.EventDefinitionKey__c,event.Is_Partner_Order__c
                                                                     )   ;
               }  
        else if(event.Event_Type__c == Label.SFMC_Shipment_Event && summaryIds.add(event.Shipment_ID__c)) {
            ShipmentEventEmailHandler.sendPayLoad(event.Shipment_ID__c,event.EventDefinitionKey__c)   ;
                }  

            
        
 }
 

}