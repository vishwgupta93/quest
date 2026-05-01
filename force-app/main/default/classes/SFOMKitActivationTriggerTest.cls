@IsTest 
public class SFOMKitActivationTriggerTest {
        
    
  @IsTest
  static void activateKit() {
       
   SFOM_Kit_Activation__e event = new SFOM_Kit_Activation__e(Activate_Kit__c=false, Shipment_Line_Item_Id__c='777788888888');    
   Test.startTest();        
   // Publish test event
   Database.SaveResult sr = EventBus.publish(event);            
   Test.stopTest();           
  }
       
}