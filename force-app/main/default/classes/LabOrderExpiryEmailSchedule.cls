global with sharing class LabOrderExpiryEmailSchedule implements Schedulable{
    global void execute(SchedulableContext sc) {   
        LabOrderExpiryEmailOutbound btch= new LabOrderExpiryEmailOutbound();
        btch.status = 'PA Approved';
        btch.type = 'InPerson';
        btch.query = 'SELECT Id, CreatedDate,Name,Order_Summary__c,Order_Summary__r.OrderNumber,Order_Summary__r.GrandTotalAmount,Person_Record__r.Id,Person_Record__r.Email__c,Expiration_Date__c,Days_to_expire__c,Order_Summary__r.Id,  Is_Partner__c,Partner_Client_Map__r.Suppress_Reminder_Email__c FROM Lab_Order__c WHERE Status__c =: status  and Days_to_expire__c in (30,10,7,3) and FO_Record_Type__c =: type';
        Database.executeBatch(btch,1);
      }
}