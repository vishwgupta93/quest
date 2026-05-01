global with sharing class  PartnerLabOrderRefundRetryBatchSchedule implements Schedulable{
    global void execute(SchedulableContext sc) {   
        PartnerLabOrderRefundRetryBatch btch= new PartnerLabOrderRefundRetryBatch();
        btch.query = 'SELECT Id, Payment_Transaction_Id__c,Captured_Amount__c,Cancellation_Service_Fee__c,Refund_Amount__c,Refund_Attempts__c,Partner_Client_Map__r.Payment_Key__c FROM Lab_Order__c WHERE Refund_Attempts__c < 4 and Is_Refund_Error__c = true and Is_Partner__c = true';
        Database.executeBatch(btch,1);
      }
}