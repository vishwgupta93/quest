global with sharing class GBFShipmentConfirmSchedule implements Schedulable{
    global void execute(SchedulableContext sc) {   
      GBFShipmentConfirmation btch= new GBFShipmentConfirmation();
        btch.status = 'Shipped';
        btch.query = 'SELECT Id,  Status__c, Retail_Partner__r.Fulfillment_Location_API_Key__c FROM Partner_Order__c WHERE Status__c =: status ';
        Database.executeBatch(btch,1);
      }
}