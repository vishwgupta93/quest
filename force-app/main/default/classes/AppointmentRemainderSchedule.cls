global with sharing class AppointmentRemainderSchedule implements Schedulable{
    global void execute(SchedulableContext sc) {   
        AppointmentRemainderEmailOutbound btch= new AppointmentRemainderEmailOutbound();
        List<String> statusList = new List<String>{'PA Approved','Pending Approval'};
        btch.statusList = statusList;
        btch.type = Label.SFOM_In_Person_Record_Type_Id;
        //btch.query = 'SELECT FulfillmentOrder.Id, FulfillmentOrder.orderSummary.OrderedDate,FulfillmentOrder.OrderSummary.OrderNumber,FulfillmentOrder.orderSummary.GrandTotalAmount,FulfillmentOrder.OrderSummary.BillingEmailAddress,FulfillmentOrder.OrderSummary.CustomerId__c,FulfillmentOrder.orderSummary.Account.PersonEmail,FulfillmentOrder.Expiration_Date__c,FulfillmentOrder.Days_Past_Confirm__c,FulfillmentOrder.OrderSummaryId FROM FulfillmentOrderLineItem WHERE FulfillmentOrder.Status =: status  and FulfillmentOrder.Days_past_Confirm__c in (6,12) and Date_of_Collection__c = null and Type!= : type and FulfillmentOrder.HUB_Success__c = true';
        btch.query = 'SELECT Id, orderSummary.OrderedDate,OrderSummary.OrderNumber,orderSummary.GrandTotalAmount,OrderSummary.BillingEmailAddress,OrderSummary.CustomerId__c,orderSummary.Account.PersonEmail,Expiration_Date__c,Days_Past_Confirm__c,OrderSummaryId FROM FulfillmentOrder WHERE RecordTypeId = :type and  Status IN : statusList  and Days_past_Confirm__c in (6,12) and HUB_Success__c = true';
        Database.executeBatch(btch,1);
      }
}