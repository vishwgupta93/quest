global class EmailAlertBatchJob implements Schedulable {
    global void execute(SchedulableContext sc) {   
        // EmailAlertBatch btch = new EmailAlertBatch();
        // Datetime oneHourAgo = System.now().addHours(-1);
        // List<String> status= new List<String>{'New','Open'};
        // String caseType= 'Tech';
        // btch.caseType=caseType;
        // btch.status=status;
        // btch.dateToLoad=oneHourAgo;
        // btch.Query = 'SELECT Id,Origin FROM Case WHERE Case_type__c = :caseType AND Status = :status AND LastModifiedDate >= :dateToLoad  ';
        // Database.executeBatch(btch,1);
        Flow.Interview.Quest_Send_Email_Alert_For_Tech_Errors flow = new Flow.Interview.Quest_Send_Email_Alert_For_Tech_Errors(new Map<String, Object>());
        flow.start();
      }
}