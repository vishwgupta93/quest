global with sharing class LabOrderAppointmentRemainderSchedule implements Schedulable{
    global void execute(SchedulableContext sc) {   
        LabOrderAppointmentEmailOutbound btch= new LabOrderAppointmentEmailOutbound();
        List<String> statusList = new List<String>{'PA Acknowledged','PA Approved'};
        btch.statusList = statusList;
        btch.type = 'InPerson';
        btch.query = 'SELECT Id, CreatedDate,Name,Order_Summary__r.OrderNumber,Order_Summary__r.GrandTotalAmount,Person_Record__r.Id,Person_Record__r.Email__c,Expiration_Date__c,Days_Past_Confirm__c,Order_Summary__r.Id, Is_Partner__c,Partner_Client_Map__r.Suppress_Reminder_Email__c FROM Lab_Order__c WHERE  Status__c IN : statusList  and Days_past_Confirm__c in (6,12) and HUB_Success__c = true and FO_Record_Type__c =: type';
        Database.executeBatch(btch,1);
      }
}