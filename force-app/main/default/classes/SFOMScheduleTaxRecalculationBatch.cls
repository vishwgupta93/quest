/**
Description:: Schedule the batch class to run payment failure batch class.
**/
global class SFOMScheduleTaxRecalculationBatch implements Schedulable {

   global void execute(SchedulableContext sc) {   
     SFOMTaxRecalculationBatch btch= new SFOMTaxRecalculationBatch();
     btch.recId='Cancelled';
     btch.isTaxEstimated = true;
     btch.query ='Select Id, SalesChannelId from orderSummary where isTaxEstimated__c=:isTaxEstimated and Status!=:recId';
     Database.executeBatch(btch,1);
   }
   
}