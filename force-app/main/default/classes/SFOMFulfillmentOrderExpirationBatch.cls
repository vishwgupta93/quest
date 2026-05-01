/**
   Name:: SFOMFulfillmentOrderExpirationBatch
   Description:: This class is to set the status of the fullfilment order stauts to Expired if 
                  the customer never has their sample collected in PS even after 65 days from PWN approval date.
                  
                 
**/
global class SFOMFulfillmentOrderExpirationBatch implements Database.Batchable <SObject> {

 Public String Query;
 Public String Id;
 Public String recordType;
 Public String StatusExpired;
 public Date recordcreatedDate;
 global Database.QueryLocator start(Database.BatchableContext bc){
   return Database.getQueryLocator(Query);
 }
 
 global void execute(Database.BatchableContext bc, List<FulfillmentOrder> foLst){ 
 
  List<FulfillmentOrder> fulfillmentOrderLstToUpdate = new List<FulfillmentOrder>();
  for(FulfillmentOrder fo:foLst) {
    System.debug('fo.Id'+fo.Id);
      fo.Status =Label.SFOM_FO_Status_Expired;
      if(fo.RecordTypeId ==  label.SFOM_In_Person_Record_Type_Id && fo.InvoiceId != null)
      {
          //fo.Service_Fee__c = 20.00;
          Decimal totalRefund = fo.GrandTotalAmount - fo.Service_Fee__c;          

          List<OrderPaymentSummary> gcPayments = [select Id,CapturedAmount,BalanceAmount from OrderPaymentSummary where OrderSummaryId =: fo.OrderSummaryId and paymentType__c = 'gift_card' ];
          FulfillmentOrder pwnFO = [select Id from FulfillmentOrder where OrderSummaryId =: fo.OrderSummaryId and RecordTypeId =: label.SFOM_PWN_Service_Record_Type_Id limit 1];

          if(!gcPayments.isEmpty())
          {
            Decimal gcBalance = gcPayments[0].CapturedAmount - gcPayments[0].BalanceAmount;
            if(totalRefund <= gcBalance)
            {
                fo.Gift_Card__c = totalRefund;
                pwnFO.Gift_Card__c = gcBalance - totalRefund;
            }
            else {
                fo.Gift_Card__c = gcBalance;
                pwnFO.Gift_Card__c = 0.0;
            }
            fulfillmentOrderLstToUpdate.add(pwnFO);
          }

          
         
          fo.Full_Refund__c =false;


      }
      
      fulfillmentOrderLstToUpdate.add(fo);
      
  }
  
  if(fulfillmentOrderLstToUpdate!=null && fulfillmentOrderLstToUpdate.size()>0)
     update fulfillmentOrderLstToUpdate;
 }
 
 global void finish(Database.BatchableContext bc) {
 
 }

}