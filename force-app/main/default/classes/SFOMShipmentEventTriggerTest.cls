@IsTest 
public class SFOMShipmentEventTriggerTest {    
  @IsTest
  static void publishEvent() {
       
   SFOM_Shipping_Notifications__e event = new SFOM_Shipping_Notifications__e(Event_Type__c= 'Create',Fulfillment_Order_Id__c='777788888888');    
   Test.startTest();        
   // Publish test event
   Database.SaveResult sr = EventBus.publish(event);            
   Test.stopTest();           
  }
       
}