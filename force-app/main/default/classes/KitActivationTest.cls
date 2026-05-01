@IsTest 
public class KitActivationTest {    
  @IsTest
  static void validateAPI() {
       
  Test.StartTest();
             
      Kit_Details__c kitDetail = new Kit_Details__c();
      kitDetail.Activation_Code__c = 'TST12121212';
      kitDetail.Status__c = 'Available';
      kitDetail.Type__c = 'GSS';
      kitDetail.Item_Code__c = '11757';
      kitDetail.Purchaser_PRS_ID__c = 'TST12121212';
      kitDetail.Lot_Number__c = 'TST12121212';
      kitDetail.ActivationUser_Customer_Id__c = 'TST12121212';
      
      insert kitDetail;
      
      KitActivation.RequestData requestData = new KitActivation.RequestData();
      requestData.activationCode='TST12121212';
      requestData.testTakerId='TST12121212';
      
      Kit_Details__c response = KitActivation.getKitDetail(requestData);      
       
      

    // Validate the expected fields in the response
    System.assertEquals(true, response.Eligible_For_Activation__c);
    
    Kit_Details__c kitDetail1 = new Kit_Details__c();
      kitDetail1.Activation_Code__c = 'TST121212146';
      kitDetail1.Status__c = 'Activated';
      kitDetail1.Type__c = 'GSS';
      kitDetail1.Item_Code__c = '11757';
      kitDetail1.Purchaser_PRS_ID__c = 'TST12121212';
      kitDetail1.Lot_Number__c = 'TST12121212';
      kitDetail1.ActivationUser_Customer_Id__c = 'TST12121212';
      
      insert kitDetail1;
      
      Kit_Details__c kitDetail2 = new Kit_Details__c();
      kitDetail2.Activation_Code__c = 'TST121212145';
      kitDetail2.Status__c = 'Available';
      kitDetail2.Type__c = 'GSS';
      kitDetail2.Item_Code__c = '11757';
      kitDetail2.Purchaser_PRS_ID__c = 'TST12121212';
      kitDetail2.Lot_Number__c = 'TST12121212';
      kitDetail2.ActivationUser_Customer_Id__c = 'TST12121212';
      
      insert kitDetail2;
      
      //KitActivation.RequestData requestData = new KitActivation.RequestData();
      requestData.activationCode='TST121212145';
      requestData.testTakerId='TST12121212';
      
      response = KitActivation.getKitDetail(requestData);      
       
      

    // Validate the expected fields in the response
    System.assertEquals(false, response.Eligible_For_Activation__c);
    
    Kit_Details__c kitDetail3 = new Kit_Details__c();
      kitDetail3.Activation_Code__c = 'TST12121288';
      kitDetail3.Status__c = 'Available';
      kitDetail3.Type__c = 'at_home';
      kitDetail3.Item_Code__c = '11757';
      kitDetail3.Purchaser_PRS_ID__c = 'TST12121212';
      kitDetail3.Lot_Number__c = 'TST12121212';
      kitDetail3.ActivationUser_Customer_Id__c = 'TST12121212';
      
      insert kitDetail3;
      
      //KitActivation.RequestData requestData = new KitActivation.RequestData();
      requestData.activationCode='TST12121288';
      requestData.testTakerId='TST12121212';
      
      response = KitActivation.getKitDetail(requestData);      
       
      

    // Validate the expected fields in the response
    System.assertEquals(true, response.Eligible_For_Activation__c);
    
    
    Kit_Details__c kitDetail4 = new Kit_Details__c();
      kitDetail4.Activation_Code__c = 'TST12121289';
      kitDetail4.Status__c = 'Activated';
      kitDetail4.Type__c = 'at_home';
      kitDetail4.Item_Code__c = '11757';
      kitDetail4.Purchaser_PRS_ID__c = 'TST12121212';
      kitDetail4.Lot_Number__c = 'TST12121212';
      kitDetail4.ActivationUser_Customer_Id__c = 'TST12121212';
      
      insert kitDetail4;
      
      //KitActivation.RequestData requestData = new KitActivation.RequestData();
      requestData.activationCode='TST12121289';
      requestData.testTakerId='TST12121212';
      
      response = KitActivation.getKitDetail(requestData);      
       
      

    // Validate the expected fields in the response
    System.assertEquals(false, response.Eligible_For_Activation__c);
           
       Test.stopTest();  
  }
       
}