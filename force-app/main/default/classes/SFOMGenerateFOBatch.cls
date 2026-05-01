/**
Class:: SFOMGenerateFOBatch
Description:: This class to generate Fulfillment orders from Order summary. 
              This class is scheduled to generate FO after remorse period.  

**/

global class SFOMGenerateFOBatch implements Database.Batchable <SObject> {
 
 Public String query;
 Public boolean eligibleForFOCreation;
 Public String recId;
 
 global Database.QueryLocator start(Database.BatchableContext bc){
   return Database.getQueryLocator(query);
 }
 
 global void execute(Database.BatchableContext bc, List<orderSummary> lstRecords){ 
    
    
    for (orderSummary oSummaryRec : lstRecords) {   
          
          Map<String, Object> input = new Map<String, Object>();
          input.put('recordId', oSummaryRec.Id);        
          Flow.Interview.Quest_Create_Fulfillment_Order_Auto_Launched flow = new Flow.Interview.Quest_Create_Fulfillment_Order_Auto_Launched(input);
          flow.start();                     
    }        
 }
  
 global void finish(Database.BatchableContext bc) {
 
 } 
 
}