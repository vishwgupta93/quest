global class SFOMExpireShipmentLineItemsBatchSchedule implements Schedulable {

 global void execute(SchedulableContext sc) {   
  
  SFOMExpireShipmentLineItemsBatch btch = new SFOMExpireShipmentLineItemsBatch();
  btch.Query='Select Id,Status__c,FulfillmentOrderLineItem.Quantity,FulfillmentOrderLineItem.Status__c,FulfillmentOrderLineItemId from ShipmentItem where Eligible_To_Expire__c=true';
  Database.executeBatch(btch,1);
 }
 
}