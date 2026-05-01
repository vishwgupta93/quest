/* 
   Used an apex trigger to eliminate duplicate Fulfillment Order Id entries while invoking ensurefunds flow.
   In a scenario where there are multiple FOs under an order and all eligible to capture PWN service fee in the same transaction
   causes duplicate entries and here we are eliminating it.
     
**/
trigger SFOMEventTrigger on SFOM_Event__e (after Insert) {

 List<SFOM_Event__e> eventLst = new List<SFOM_Event__e>();
 Set<String> foIds = new Set<String>();
 
 for (SFOM_Event__e event : Trigger.New) {
      if(event.Event_Type__c == label.SFOM_Create_Invoice_And_Ensure_Funds_Event && event.Fulfillment_Order_Id__c!=null && !foIds.contains(event.Fulfillment_Order_Id__c)) {
         eventLst.add(new SFOM_Event__e(Event_Type__c= label.SFOM_Generate_Invoice_And_Capture_Funds ,Fulfillment_Order_Id__c=event.Fulfillment_Order_Id__c, Order_Summary_Id__c = event.Order_Summary_Id__c));   
         foIds.add(event.Fulfillment_Order_Id__c); 
      }
 }
 
 if(eventLst!=null && eventLst.size()>0) {
           EventBus.publish(eventLst);
    }

}