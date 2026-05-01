@IsTest(SeeAllData=true)
private class RegisterLabOrderTest {

    @isTest
    static void testRegisterLabOrder_CommerceFlowTrue() {
        Product2 product = new Product2();
        product.Name = 'Test';
        product.Description = 'Test';
        product.ProductCode = 'CODE123';
        product.StockKeepingUnit = 'Test'+ String.valueOf(1);
        product.DisplayUrl = '';
        product.ExternalId = 'sku123';
        product.IsActive = true;
        insert product;

    Panel__c panel =  new Panel__c(Product__c=product.Id);
    insert panel;

    Test__c test =  new Test__c(Test_Code__c='test',Test_Name__c='test',Description__c='test');
    insert test;

    Panel_Test__c panelTest= new Panel_Test__c(Panel__c=panel.Id,Test__c=test.Id);
    insert panelTest;

    // Insert mock Person and Lab_Order__c records
    Person_Record__c person = new Person_Record__c(
        First_Name__c = 'John',
        Last_Name__c = 'Doe',
        Email__c = 'john.doe@example.com',
        Address_Line_1__c = '123 Main St',
        Unique_Identifier__c ='Uniqu1',
        City__c = 'Anytown',
        Country__c = 'USA',
        State__c = 'CA',
        Postal_Code__c = '12345',
        Phone__c = '1234567890',
        Gender__c = 'Male',
        Date_of_Birth__c = Date.newInstance(1990, 1, 1)
    );
    insert person;

    Lab_Order__c labOrder = new Lab_Order__c(
       Is_Partner__c=true,
        Client_Id__c = '12345',
        Person_Record__c = person.Id
    );
    insert labOrder;

    

        // Create Tester Detail with commerce flow
        Tester_Detail__c testerDetail = new Tester_Detail__c(
            Fulfillment_Order_Item_Id__c = '',
            Product_Codes__c = 'CODE123',
            Is_Commerce_Flow__c = true
        );
        insert testerDetail;

        //Object Intializations:
        Product_AOE__c paoe = new Product_AOE__c(
        Product__c= product.Id,
            Question_Code__c= '11111111',
            Type__c= 'AOE'
        );
        insert paoe;
        
        Product_AOE_Option__c pAOEOption= new Product_AOE_Option__c(
        Product_AOE__c= paoe.Id
        );
        insert pAOEOption;
        // Create AOE
        Tester_Details_AOE__c aoe = new Tester_Details_AOE__c(
            Tester_Detail_Id__c = testerDetail.Id,
            Product_Code__c = 'CODE123',
            AOE_response__c = 'AOE Example',
            Product_AOE__c= paoe.Id,
            Product_AOE_Option__c= pAOEOption.Id
        );
        insert aoe;

        // Prepare input
        RegisterLabOrder.InputParameters input = new RegisterLabOrder.InputParameters();
        input.testerId = testerDetail.Id;
        input.labOrderId = labOrder.Id;
        List<RegisterLabOrder.InputParameters> inputs = new List<RegisterLabOrder.InputParameters>{ input };

        System.Test.startTest();
        List<RegisterLabOrder.OutputParameters> result = RegisterLabOrder.registerLabOrder(inputs);
        System.Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return 1 output');
    }

    @IsTest(SeeAllData=true)
    static void testRegisterLabOrder_CommerceFlowFalse() {

        FulfillmentOrder fo = getFO();

        List<FulfillmentOrderLineItem> foLines = [select Id,Product2Id,ProductCode__c,OrderItemSummary.HRAReq__c from FulfillmentOrderLineItem where FulfillmentOrderId =: fo.Id and Test_Type__c = 'PSC'];

        
        List<Panel__c> panelsToInsert = new List<Panel__c>();
        List<Test__c> testsToInsert = new List<Test__c>();
        List<Panel_Test__c> panelTestsToInsert = new List<Panel_Test__c>();
        List<String> foLineIdList = new List<String>();

        Map<Id, Id> productToPanelMap = new Map<Id, Id>();

        for (FulfillmentOrderLineItem lineItem : foLines) {
            foLineIdList.add(lineItem.Id);
            // Create a Panel__c for each Product
            Panel__c panel = new Panel__c(
                  Product__c = lineItem.Product2Id
            );
            panelsToInsert.add(panel);

            // Create a Test__c (could be more customized if needed)
            Test__c test = new Test__c(
                Test_Code__c = 'Test_' + lineItem.ProductCode__c,
                Description__c = 'Auto-generated for ' + lineItem.ProductCode__c
            );
            testsToInsert.add(test);
        }

        // Insert Panels and Tests first
        insert panelsToInsert;
        insert testsToInsert;

        // Now create Panel_Test__c records using inserted IDs
        for (Integer i = 0; i < panelsToInsert.size(); i++) {
            Panel__c panel = panelsToInsert[i];
            Test__c test = testsToInsert[i];

            Panel_Test__c panelTest = new Panel_Test__c(
                Panel__c = panel.Id,
                Test__c = test.Id
            );
            panelTestsToInsert.add(panelTest);
        }

        insert panelTestsToInsert;

        String foLineIdsCsv = String.join(foLineIdList, ',');


    // Insert mock Person and Lab_Order__c records
    Person_Record__c person = new Person_Record__c(
        First_Name__c = 'John',
        Last_Name__c = 'Doe',
        Email__c = 'john.doe@example.com',
        Address_Line_1__c = '123 Main St',
        Unique_Identifier__c ='Uniqu1',
        City__c = 'Anytown',
        Country__c = 'USA',
        State__c = 'CA',
        Postal_Code__c = '12345',
        Phone__c = '1234567890',
        Gender__c = 'Male',
        Date_of_Birth__c = Date.newInstance(1990, 1, 1)
    );
    insert person;

    Lab_Order__c labOrder = new Lab_Order__c(
       Is_Partner__c=true,
        Client_Id__c = '12345',
        Person_Record__c = person.Id
    );
    insert labOrder;

    

        // Create Tester Detail with commerce flow
        Tester_Detail__c testerDetail = new Tester_Detail__c(
            Fulfillment_Order_Item_Id__c = foLineIdsCsv,
            // Product_Codes__c = 'CODE123',
            Is_Commerce_Flow__c = false
        );
        insert testerDetail;

        // Create AOE
        Tester_Details_AOE__c aoe = new Tester_Details_AOE__c(
            Tester_Detail_Id__c = testerDetail.Id,
            Product_Code__c = 'CODE123',
            AOE_response__c = 'AOE Example'
        );
        insert aoe;

        // Prepare input
        RegisterLabOrder.InputParameters input = new RegisterLabOrder.InputParameters();
        input.testerId = testerDetail.Id;
        input.labOrderId = labOrder.Id;
        List<RegisterLabOrder.InputParameters> inputs = new List<RegisterLabOrder.InputParameters>{ input };

        Test.startTest();
        List<RegisterLabOrder.OutputParameters> result = RegisterLabOrder.registerLabOrder(inputs);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return 1 output');
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
            item.HRAReq__c=true;
    }
 
 update OrderItemLst;

   
       return fo;
    }

}