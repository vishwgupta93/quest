global with sharing class  LabOrderRefundRetryBatchSchedule implements Schedulable{
    global void execute(SchedulableContext sc) {   
        LabOrderRefundRetryBatch btch= new LabOrderRefundRetryBatch();
        btch.query = 'SELECT Id, Order_Summary__c,Refund_Amount__c,Refund_Attempts__c FROM Lab_Order__c WHERE Refund_Attempts__c < 4 and Is_Refund_Error__c = true ';
        Database.executeBatch(btch,1);
      }
}