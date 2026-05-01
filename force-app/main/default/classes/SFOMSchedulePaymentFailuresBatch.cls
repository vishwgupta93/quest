/**
Description:: Schedule the batch class to run payment failure batch class.
**/
global class SFOMSchedulePaymentFailuresBatch implements Schedulable {

   global void execute(SchedulableContext sc) {   
     SFOMPaymentFailureRetryBatch btch= new SFOMPaymentFailureRetryBatch();
     btch.cnt = integer.valueof(label.Payment_Failure_Retry_Cnt);
     btch.paymentAuthorizationDate = date.today() - 7;
     btch.status = 'Cancelled';
     btch.query = 'Select Id, orderSummaryId, Invoice.Ensure_Funds_Count__c, status from FulfillmentOrder where status!=:status and Invoice.Balance >0 AND CreatedDate >=:paymentAuthorizationDate  AND (Invoice.Ensure_Funds_Count__c = NULL OR Invoice.Ensure_Funds_Count__c<:cnt) ORDER BY CreatedDate asc LIMIT 12 ';
     Database.executeBatch(btch,1);
   }
   
}