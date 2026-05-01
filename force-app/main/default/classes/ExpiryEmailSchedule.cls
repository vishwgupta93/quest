global with sharing class ExpiryEmailSchedule implements Schedulable{
    global void execute(SchedulableContext sc) {   
        ExpiryEmailOutbound btch= new ExpiryEmailOutbound();
        btch.status = 'PA Approved';
        btch.query = 'SELECT Id, orderSummary.OrderedDate,OrderSummary.OrderNumber,orderSummary.GrandTotalAmount,OrderSummary.BillingEmailAddress,OrderSummary.CustomerId__c,orderSummary.Account.PersonEmail,Expiration_Date__c,Days_to_expire__c,OrderSummaryId FROM FulfillmentOrder WHERE Status =: status  and Days_to_Expire__c in (30,10,7,3)';
        Database.executeBatch(btch,1);
      }
}