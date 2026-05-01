/**
    Description:: This class is to update status of the shipment Line item and FO Line Item to Kit Expired upon the Kit Expiration.
**/

global class SFOMExpireShipmentLineItemsBatch implements Database.Batchable <SObject> {

 Public String Query;
 Public String Id;
 Public String StatusExpired;

 global Database.QueryLocator start(Database.BatchableContext bc){
    return Database.getQueryLocator(Query);
 }
 
 global void execute(Database.BatchableContext bc, List<ShipmentItem> lstRecords){ 
 
  List<FulfillmentOrderLineItem> fOLineItemsToUpdateLst = new List<FulfillmentOrderLineItem>();
  List<ShipmentItem> shipmentItemsToUpdateLst = new List<ShipmentItem>();
  
  for(ShipmentItem shipmentItem : lstRecords){
      if(shipmentItem.Status__c != Label.SFOM_Status_Kit_Expired) {
         shipmentItem.Status__c =  Label.SFOM_Status_Kit_Expired;
         shipmentItem.Can_Not_Activate__c=true;
         shipmentItem.Cancellation_reason__c='Expired';
         shipmentItemsToUpdateLst.add(shipmentItem);
      }
      if(shipmentItem.FulfillmentOrderLineItem.Quantity==1 && shipmentItem.FulfillmentOrderLineItem.Status__c!=Label.SFOM_FO_Status_Expired) {
         fOLineItemsToUpdateLst.add(new FulfillmentOrderLineItem(id= shipmentItem.FulfillmentOrderLineItemId,Status__c= Label.SFOM_FO_Status_Expired));
      }
  }
   
   if(shipmentItemsToUpdateLst!=null && shipmentItemsToUpdateLst.size()>0){
     update shipmentItemsToUpdateLst;
   }
   
   if(fOLineItemsToUpdateLst!=null && fOLineItemsToUpdateLst.size()>0){
     update fOLineItemsToUpdateLst;
   }
    
   
 }
 
 global void finish(Database.BatchableContext bc) {
 
 }
 
}