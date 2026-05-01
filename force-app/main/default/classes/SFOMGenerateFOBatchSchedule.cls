/**
  Class Name:: SFOMGenerateFOBatchSchedule
  Description:: Schedulable class for SFOMGenerateFOBatchSchedule
**/

global class SFOMGenerateFOBatchSchedule implements Schedulable {

   global void execute(SchedulableContext sc) {   
     SFOMGenerateFOBatch btch = new SFOMGenerateFOBatch();
     btch.eligibleForFOCreation=true;
     btch.Query='Select Id from orderSummary where Eligible_for_FO_Creation__c =: eligibleForFOCreation order by OrderedDate desc';
     Database.executeBatch(btch,1);
   }
   
}