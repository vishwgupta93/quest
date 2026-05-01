global with sharing class SFOMSProcessExceptionSchedule implements Schedulable {
    
    
        global void execute(SchedulableContext sc) {   
        //     SFOMSProcessExceptionBatch btch=new SFOMSProcessExceptionBatch();
                     
        //     btch.category='Payment';
        //     btch.status='New';
        //     btch.summaryId='1Os530000000ghHCAQ';
        //     btch.query='Select OrderSummaryId from ProcessException where OrderSummaryId =: summaryId and  Category =:category and Status =:status and CreatedDate >= LAST_N_DAYS:3';
        //   Database.executeBatch(btch,1);
        Flow.Interview.Quest_Update_GC_Process_Exceptions flow = new Flow.Interview.Quest_Update_GC_Process_Exceptions(new Map<String, Object>());
        flow.start();

        // Flow.Interview.Quest_Send_Email_Alert_For_Tech_Errors flow = new Flow.Interview.Quest_Send_Email_Alert_For_Tech_Errors(new Map<String, Object>());
        // flow.start();
        }
    
}