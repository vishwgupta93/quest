/**
  Class Name:: SFOMOrderRefundBatchSchedule
  Description:: This class used to perform Order Refund. Query filters the credit memo which are eligible to refund
**/

global class SFOMOrderRefundBatchSchedule implements Schedulable {
   //String strOSId;
   global void execute(SchedulableContext sc) {   
   SFOMOrderRefundBatch btch = new SFOMOrderRefundBatch();
   btch.refundDate = date.today() - 7;
   
   btch.Query = 'SELECT id, ReferenceEntityId FROM CreditMemo where Refund_Pending__c=true and CreatedDate >=:refundDate and Balance > 0 ORDER BY CreatedDate asc LIMIT 12  ';
   //btch.Query = 'SELECT id, ReferenceEntityId FROM CreditMemo where Refund_Pending__c=true and ReferenceEntityId=:strOSId and Balance > 0 ';
   Database.executeBatch(btch,1);
   }
   
}