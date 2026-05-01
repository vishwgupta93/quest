global with sharing class GSSPWNPollingschedule implements Schedulable{
    global void execute(SchedulableContext sc) {   
        GSSPWNPollingJob btch= new GSSPWNPollingJob();
        List<String> statusList = new List<String>{'Cancelled','Expired','PA Rejected'};
        String recordType = 'GSS';
        btch.type= recordType;
        btch.statusList = statusList;
        btch.query = 'SELECT Id,Is_Kit__c,Kit_Detail__c, PWN_ID__c FROM Lab_Order__c WHERE Status__c NOT IN : statusList  and Is_PWN_Approved__c = false and PWN_Success__c = true and FO_Record_Type__c = : type AND Prescriptive_Authority__c != \'SMD\' Order by createdDate LIMIT 100';
        Database.executeBatch(btch,100);
      }
}