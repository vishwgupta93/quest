/**
  Class Name:: SFOMFOExpirationBatchSchedule
  Description:: Schedulable class for SFOMFulfillmentOrderExpirationBatch
**/

global class SFOMFOExpirationBatchSchedule implements Schedulable {

   global void execute(SchedulableContext sc) {   
    SFOMFulfillmentOrderExpirationBatch btch = new SFOMFulfillmentOrderExpirationBatch();
    btch.StatusExpired = Label.SFOM_FO_Status_Expired;
    btch.recordType=Label.SFOM_In_Person_Record_Type_Id;
     btch.recordcreatedDate = Date.today() - 90;
    btch.Query = 'Select Id,RecordTypeId,InvoiceId,Status,OrderSummaryId,GrandTotalAmount,Service_Fee__c from FulfillmentOrder where Eligible_to_Expire__c = true and RecordTypeId=: recordType and  Status!=:StatusExpired AND CreatedDate >=:recordcreatedDate ';
    Database.executeBatch(btch,1);
   }
   
}