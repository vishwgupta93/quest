@IsTest 
public class KitDetailTriggerTest {    
  @IsTest
  static void publishEvent() {
       
   Kit_Activation_Event__e event = new Kit_Activation_Event__e(Activation_Code__c= '777788888888',Lab_Ref_Id__c='777788888888');    
   Test.startTest();        
   // Publish test event
   Database.SaveResult sr = EventBus.publish(event);            
   Test.stopTest();           
  }
       
}