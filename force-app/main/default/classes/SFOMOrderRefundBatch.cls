/**
  Class Name:: SFOMOrderRefundBatch 
  Description:: This class filters the eligible Orders and trigger Quest_Order_Ensure_Refind to refund
**/

global class SFOMOrderRefundBatch implements Database.Batchable <SObject> {
 Public String Query;
 Public String strOSId;
 Public String OrderSummaryId;
 Public String CreditMemoId;
 public Date refundDate; 
 global Database.QueryLocator start(Database.BatchableContext bc){
 return Database.getQueryLocator(Query);
 }
 global void execute(Database.BatchableContext bc, List<CreditMemo> lstRecords){
  //Below code used to call Ensure Funds for valid CreditMemo
   Map<String, Object> mInputs = new Map<String, Object>();
   Set<String> ordeSummaryIdLst = new Set<String>();
   Set<String> unSettledOrderSummaryIds = new Set<String>();
    for (CreditMemo cm : lstRecords) {
         if(cm.ReferenceEntityId!=null){
            ordeSummaryIdLst.add(cm.ReferenceEntityId);
            }
    }
    List<FulfillmentOrder> foLst = [Select Id, OrderSummaryId from FulfillmentOrder where OrderSummaryId  IN :ordeSummaryIdLst and  Is_Payment_Settled__c =false];
    if(foLst!=null){
       for(FulfillmentOrder fo:foLst){
          unSettledOrderSummaryIds.add(fo.OrderSummaryId);
       }
    }
    for (CreditMemo cm : lstRecords) {
          OrderSummaryId = cm.ReferenceEntityId;
          CreditMemoId = cm.Id;
          /** Decimal cnt = cm.Ensure_Refunds_Count__c;        
          if (cnt==null)
             cnt=1;
          else {
              cnt =cnt+1;
          }  **/           
          if(OrderSummaryId!=null && !unSettledOrderSummaryIds.contains(OrderSummaryId)) {
             mInputs.put('InputCreditMemoId', CreditMemoId );
             mInputs.put('InputOrderSummaryId', OrderSummaryId );
             //mInputs.put('retryCnt', cnt );            
          }
    }
     if(mInputs!=null && mInputs.size()>0){
        Flow.Interview.Quest_Order_Ensure_Refind flow = new Flow.Interview.Quest_Order_Ensure_Refind(mInputs);
        flow.start();
     }
 }
 global void finish(Database.BatchableContext bc) {
 }
}