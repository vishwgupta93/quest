/**
   Name:: SFOMTaxRecalulation
   Description:: This class is to recalulate the tax incase if Avalara service is downn during order submission.
                  If the Avalra service is unavailable, SFCC will apply a higher tax rate from the backup table, requiring SFOM to recalculate the tax.
                  If tax is not recalculated, no fulfillment order will be generated.
                  This class will create an event that will trigger the flow "Quest - Tax Recalculation," which will regenerate the order summary record with the calculated tax values.
                 
**/

global class SFOMTaxRecalculationBatch implements Database.Batchable <SObject>,Database.AllowsCallouts {
 
 Public String query;
 Public boolean isTaxEstimated;
 Public String recId;
 
 global Database.QueryLocator start(Database.BatchableContext bc){
   return Database.getQueryLocator(query);
 }
 
 global void execute(Database.BatchableContext bc, List<orderSummary> lstRecords){ 
    
    List<SFOM_Event__e> taxRecalcEventLst = new List<SFOM_Event__e>();
    List<avaoms.AvaTaxOrderSummaryTaxCalculator.Request> reqLst = new List<avaoms.AvaTaxOrderSummaryTaxCalculator.Request>();
    
    
    for (orderSummary oSummaryRec : lstRecords) {   
          System.debug('ID::::::::::'+oSummaryRec.Id);  
          
        /**  List<SFOMAvaTax_CreateTransaction.InputParameters> lstParams = new List<SFOMAvaTax_CreateTransaction.InputParameters>();
          SFOMAvaTax_CreateTransaction.InputParameters params = new SFOMAvaTax_CreateTransaction.InputParameters();
          params.orderSummaryId=oSummaryRec.Id;
          lstParams.add(params);
          SFOMAvaTax_CreateTransaction.createTransaction(lstParams) ; **/
        
          SFOM_Event__e taxRecalcEvent = new SFOM_Event__e(Order_Summary_Id__c=oSummaryRec.Id,Event_Type__c=label.SFOM_Tax_API_Invocation);          
          taxRecalcEventLst.add(taxRecalcEvent);
    }
    
    if(taxRecalcEventLst!=null && taxRecalcEventLst.size()>0)
       EventBus.publish(taxRecalcEventLst); 
        
 }
  
 global void finish(Database.BatchableContext bc) {
 
 } 
 
}