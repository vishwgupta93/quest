global with sharing class SFOMUpdateRefundOnCreditMemos implements Schedulable {
    
    
    global void execute(SchedulableContext sc) {   
    
        Flow.Interview.Quest_Update_Payment_Balance_For_Refunded_Memos flow1 = new Flow.Interview.Quest_Update_Payment_Balance_For_Refunded_Memos(new Map<String, Object>());
        flow1.start();

    }

}