global with sharing class PWNPollingSchedule implements Schedulable{
    global void execute(SchedulableContext sc) {   
        PWNPollingJob btch= new PWNPollingJob();
        List<String> statusList = new List<String>{'Cancelled','Expired','PA Rejected'};
        btch.statusList = statusList;
        btch.query = 'SELECT Id,Is_Kit__c,Kit_Detail__c, PWN_ID__c FROM Lab_Order__c WHERE  Status__c NOT IN : statusList  and Is_PWN_Approved__c = false and PWN_Success__c = true AND Prescriptive_Authority__c != \'SMD\' Order by createdDate LIMIT 100';
        Database.executeBatch(btch,100);
      }
}