global with sharing class LabOrderExpiryBatchSchedule implements Schedulable{
    global void execute(SchedulableContext sc) {   
        LabOrderExpiryBatch btch= new LabOrderExpiryBatch();
        btch.recordType='InPerson';
        btch.query = 'SELECT Id, Is_Partner__c,Order_Summary__c,Order_Summary__r.OriginalOrderId,Fulfillment_Order__c,Fulfillment_Order__r.GrandTotalAmount,Fulfillment_Order__r.Service_Fee__c FROM Lab_Order__c WHERE Eligible_To_Expire__c =true  and FO_Record_Type__c =: recordType   ';
        Database.executeBatch(btch,1);
      }
}