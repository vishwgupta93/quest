/**
   Name:: SFOMPaymentFailureRetries
   Description::  Retrieves fulfillment orders where payment capture fails and reprocesses them by invoking the flow - SFOM Create Invoice And Ensure Funds Event.
                 If the payment capture still fails after three successful attempts, a process exception will be raised from flow.

**/

global class SFOMPaymentFailureRetryBatch implements Database.Batchable <SObject> {

 public String query;
 public String Id;
 public String status;
 public Integer cnt;
 public Date paymentAuthorizationDate; 
  
 global Database.QueryLocator start(Database.BatchableContext bc){   
   return Database.getQueryLocator(query);
 }
 
 global void execute(Database.BatchableContext bc, List<FulfillmentOrder> lstRecords){ 
    
    List<SFOM_Event__e> eventLst = new List<SFOM_Event__e>();
    
    for (FulfillmentOrder fo : lstRecords) {   
         System.debug('ID::::::::::'+fo.Id); 
         eventLst.add(new SFOM_Event__e(Fulfillment_Order_Id__c= fo.id, Event_Type__c = Label.SFOM_Create_Invoice_And_Ensure_Funds_Event));
    }
    
    if(eventLst!=null && eventLst.size()>0) {
        EventBus.publish(eventLst);
    }
        
 }
  
 global void finish(Database.BatchableContext bc) {
 
 
 } 
 
}