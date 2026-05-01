@isTest(SeeAllData=true)
public class KitActivationCtrlTest {
    
    @isTest static void getActivatedKitTest(){
        Product2 product = new Product2(Name = 'Test Product', Excluded_State_codes__c = 'AK', Min_age__c = '18', Max_age__c = '65', Gender__c = 'both');
        insert product;
        OrderSummary os = [SELECT Id from OrderSummary Limit 1];
        Kit_Details__c kit = new Kit_Details__c(
            Ordered_Date__c = Date.today(),
            Activation_Code__c = 'ORDER123',
            Order_Summary__c = os.Id,
            Fulfillment_Order_Id__c = 'Fulfill123',
            Fulfillment_Order_Line_Id__c = 'Line123',
            Product_Description__c = 'Test Product Description',
            Status__c = 'Activated',
            Record_Type__c = 'Standard',
            Product__c = product.Id
        );
        insert kit;
        
        Kit_Details__c kitList = [Select Id, Ordered_Date__c, Activation_Code__c, Order_Summary__c, Fulfillment_Order_Id__c, Fulfillment_Order_Line_Id__c, 
                              Product_Description__c, Status__c, Record_Type__c,  Product__r.Excluded_State_codes__c, Product__r.Min_age__c, 
                              Product__r.Max_age__c, Product__r.Gender__c From Kit_Details__c 
                              where Activation_Code__c != null LIMIT 1];
        List<Kit_Details__c> kits = KitActivationCtrl.getActivatedKit(kitList.Activation_Code__c);
        System.assert(!kits.isEmpty());
    }
    @isTest static void createTesterDetailTest(){
        Tester_Detail__c testerDetail = new Tester_Detail__c();
        testerDetail.First_Name__c = 'Test Tester'; 
        testerDetail.Email__c = 'test@test.com'; 
        
        Tester_Detail__c result = KitActivationCtrl.createTesterDetail(testerDetail);
        
        System.assertNotEquals(null, result, 'The result should not be null');
        System.assertEquals(testerDetail.Name, result.Name, 'The Tester Detail Name should match');
        System.assertEquals(testerDetail.Email__c, result.Email__c, 'The Tester Detail Email should match');
        
        Tester_Detail__c retrievedRecord = [SELECT Id, Name, Email__c FROM Tester_Detail__c WHERE Id = :result.Id];
        System.assertNotEquals(null, retrievedRecord, 'The record should be retrievable from the database');
    }
    @isTest
    static void testCreateLabOrder() {
            Tester_Detail__c testerDetail1 = new Tester_Detail__c(
            Address_Line_1__c = '456 Elm Street',
            Address_Line_2__c = 'Apt 200',
            City__c = 'Test City',
            Country__c = 'US',
            Date_Of_Birth__c = Date.newInstance(1995, 5, 15),
            Email__c = 'tester@example.com',
            First_Name__c = 'Jane',
            Gender__c = 'Female',
            Last_Name__c = 'Doe',
            Middle_Name__c = 'Marie',
            Phone__c = '987-654-3210',
            State__c = 'NY',
            Zip_Code__c = '54321'
        );
        insert testerDetail1;

        Tester_Detail__c testerDetail = [select Id,Address_Line_1__c,Address_Line_2__c,City__c,Country__c,Date_Of_Birth__c,Email__c,First_Name__c,Gender__c	,Last_Name__c,Middle_Name__c,Phone__c,State__c,Zip_Code__c from Tester_Detail__c where Id =: testerDetail1.Id ];

            System.debug('Tester : ' + testerDetail);

            String accountId = '';
            String contactId = '';


                     
            // Create Person Account
            Account newPersonAccount = new Account();
            
            
            newPersonAccount.RecordTypeId = Label.SFOM_Person_Account_RecordType_Id; 
            newPersonAccount.PersonEmail = testerDetail.Email__c;
            newPersonAccount.PersonBirthdate = testerDetail.Date_Of_Birth__c;
            newPersonAccount.LastName = testerDetail.Last_Name__c;
            newPersonAccount.FirstName = testerDetail.First_Name__c;
            newPersonAccount.PersonGenderIdentity=testerDetail.Gender__c;
            newPersonAccount.PersonMobilePhone=testerDetail.Phone__c;

            // Set the billing address
            newPersonAccount.BillingStreet = testerDetail.Address_Line_1__c ;
            newPersonAccount.BillingCity = testerDetail.City__c;
            newPersonAccount.BillingState = testerDetail.State__c;
            newPersonAccount.BillingPostalCode = testerDetail.Zip_Code__c;
            newPersonAccount.BillingCountry = testerDetail.Country__c;
            insert newPersonAccount;
            Contact contact = [select Id from contact where accountId =: newPersonAccount.Id];
            contactId = contact.Id;

        

        FulfillmentOrder fo = getFO();

        List<String> foLineIds = new List<String>(); 
       	FulfillmentOrderLineItem line = [SELECT Id, FulfillmentOrder.OrderSummary.OrderNumber FROM FulfillmentOrderLineItem WHERE FulfillmentOrderId =: fo.Id LIMIT 1];
		foLineIds.add(line.Id);
        
        

        Test.startTest();
        KitActivationCtrl.createLabOrder(testerDetail1.Id, foLineIds);
        KitActivationCtrl.createCustomerUser(contactId);
        Test.stopTest();
        

    }

      

    

    private static FulfillmentOrder getFO()
    {
        // Test data setup
    String salesChannel = 'Quest_US';
    String currencyIsoCode = 'USD';
    String orderTypeCode = 'Web';
    String MerchantID = 'Quest_US';
    

    Map<String,SObject> m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);       

    Order newOrder = (Order)m_mapTestData.get('newOrder');    
    SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' );                      
    List<OrderSummary> lstOS = [SELECT Id FROM OrderSummary where OriginalOrderId=:newOrder.Id ];

    // System.assert(!lstOS.isEmpty());
    OrderSummary oOrderSummary = new OrderSummary();
    oOrderSummary  = lstOS[0];
    System.debug('lstOS ==>'+lstOS[0]);
    String orderSummaryId = oOrderSummary.Id;
    List<ID> lstOSID = new List<ID>();
     lstOSID.add(orderSummaryId);
          
     System.debug('******oOrderSummary *******'+oOrderSummary );
    
      List<OrderDeliveryGroupSummary> lstODGS = [SELECT Id, OrderSummaryId FROM OrderDeliveryGroupSummary where OrderSummaryId=:oOrderSummary.Id ];
        System.debug('******lstODGS  *******'+lstODGS  );
    
    
    Schema.Location location = (Schema.Location) m_mapTestData.get('newLocationUSCE');
    

    SFOMCreateFulfillmentOrder.InputParameters obj = new SFOMCreateFulfillmentOrder.InputParameters();        
    obj.orderSummaryId = lstOS[0].Id;     
    List<SFOMCreateFulfillmentOrder.InputParameters> objLst = new List<SFOMCreateFulfillmentOrder.InputParameters>();
    objLst.add(obj);    
    SFOMCreateFulfillmentOrder.createTransaction(objLst); 

  List<Id> oSumIdLst = new List<Id>();
  oSumIdLst.add(lstOS[0].Id);
     
  List<FulfillmentOrder> fos = [SELECT Id from FulfillmentOrder where OrderSummaryId =: lstOS[0].Id];
  FulfillmentOrder fo = fos[0];
  fo.RecordTypeId=Label.SFOM_In_Person_Record_Type_Id;
       fo.Status = 'Pending Approval';
       fo.LastName__c ='Test';
       fo.FirstName__c ='Test';
       fo.Physician_First_Name__c='Test';
       fo.Physician_Last_Name__c='Test';
       fo.Physician_Npi__c='121212';
       fo.Physician_Upin__c='121121';
       fo.PWN_ID__c='12121';

       update fo;
       
       List<OrderItemSummary> OrderItemLst = [SELECT Id, TestType__c  from OrderItemSummary where OrderSummaryId IN :oSumIdLst and Type!='Delivery Charge'];
    for(OrderItemSummary item :OrderItemLst){       
            item.TestType__c='PSC';
    }
 
 update OrderItemLst;

   
       return fo;
    }

    
}