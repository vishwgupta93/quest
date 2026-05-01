@IsTest 
public class SFOMEventTriggerTest {    
  @IsTest
  static void publishEvent() {
       
   SFOM_Event__e event = new SFOM_Event__e(Event_Type__c= label.SFOM_Create_Invoice_And_Ensure_Funds_Event,Fulfillment_Order_Id__c='777788888888');    
   Test.startTest();        
   // Publish test event
   Database.SaveResult sr = EventBus.publish(event);            
   Test.stopTest();           
  }
       
}