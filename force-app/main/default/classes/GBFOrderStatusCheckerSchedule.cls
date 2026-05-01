global with sharing class GBFOrderStatusCheckerSchedule implements Schedulable {

    global void execute(SchedulableContext sc) {   
        GBFOrderStatusChecker btch= new GBFOrderStatusChecker();
       btch.status = 'Acknowledged';
        btch.query = 'SELECT Id,  Status__c, Retail_Partner__r.Fulfillment_Location_API_Key__c FROM Partner_Order__c WHERE Status__c =: status '; 
        Database.executeBatch(btch,1); 
      }
   
}