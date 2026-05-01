@IsTest 
public class SFOMFOCancelEventTriggerTest {    
  @IsTest
  static void publishEvent() {
       
   SFOM_Fulfillment_Order_Cancel_Event__e event = new SFOM_Fulfillment_Order_Cancel_Event__e(Action_Type__c= 'Cancelled',Fulfillment_Order_Id__c='777788888888',Kit_Activated__c=false);    
   Test.startTest();        
   // Publish test event
   Database.SaveResult sr = EventBus.publish(event);            
   Test.stopTest();           
  }
       
}