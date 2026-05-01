@IsTest
public class CreateLabHUBServiceOrderTest {

    @IsTest
    static void testCreateHUBOrder_Success() {
        // Arrange
        List<CreateLabHUBServiceOrder.HUBServiceInput> inputs = new List<CreateLabHUBServiceOrder.HUBServiceInput>();
        
        

       Product2 product = new Product2();
            product.Name = 'Test';
            product.Description = 'Test';
            product.ProductCode = 'test';
            product.StockKeepingUnit = 'Test'+ String.valueOf(1);
            product.DisplayUrl = '';
            product.ExternalId = 'sku123';
            product.IsActive = true;
            product.testType__c='PSC';
            product.performingSite__c='PHP';
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
            Person_Record__c = person.Id,
            Name='TETS81892-12782323',
            PWN_ID__C='12671281',
            Physician_First_Name__c='asasd',
            Physician_Last_Name__c='bcvm',
            Physician_Npi__c='122121',
            Physician_Upin__c='12121',
            Minor_First_Name__c = 'Little',
            Minor_Last_Name__c = 'Guardian',
            Minor_Gender__c = 'Male',
            Minor_Date_of_Birth__c = Date.newInstance(2015, 5, 5),
            Consent_Minor_Date_Time__c = Date.newInstance(2024, 5, 5)
        );
        insert labOrder;

        // Insert Lab_Order_Panel__c and Lab_Panel_Test__c records
        Lab_Order_Panel__c labOrderPanel = new Lab_Order_Panel__c(Lab_Order__c = labOrder.Id,Status__c='Registered', AOE__c = '[{"isAoe":true}]');
        insert labOrderPanel;

        Lab_Panel_Test__c labPanelTest = new Lab_Panel_Test__c(Lab_Order_Panel__c = labOrderPanel.Id, Panel_Test__c=panelTest.Id,Status__c='Registered');
        insert labPanelTest;

        // Mock HTTP response
        System.Test.setMock(HttpCalloutMock.class, new MockPWNHttpResponse(201, '{"order": {"physicianReview": {"firstName": "John", "lastName": "Doe", "upin": "12345", "npi": "67890"}, "id": "pwnId123"}}'));

        CreateLabHUBServiceOrder.HUBServiceInput input = new CreateLabHUBServiceOrder.HUBServiceInput();
        input.token = 'mockToken';
        input.labOrderId = labOrder.Id;
        inputs.add(input);
        // Act
        System.Test.startTest();
        List<CreateLabHUBServiceOrder.HUBServiceOutput> result = CreateLabHUBServiceOrder.createHubOrder(inputs);
        System.Test.stopTest();

        // Assert
        System.assertEquals(1, result.size());
        CreateLabHUBServiceOrder.HUBServiceOutput output = result[0];
        System.assertEquals(labOrder.Id, output.labOrderId);
        System.assertEquals('Success', output.status);
        System.assertEquals('201', output.responseCode);
        System.assertEquals('Success', output.responseMessage);
        
    }

    @IsTest
    static void testCreateHUBOrder_Error() {
        // Arrange
        List<CreateLabHUBServiceOrder.HUBServiceInput> inputs = new List<CreateLabHUBServiceOrder.HUBServiceInput>();
        Product2 product = new Product2();
            product.Name = 'Test';
            product.Description = 'Test';
            product.ProductCode = 'test';
            product.StockKeepingUnit = 'Test'+ String.valueOf(1);
            product.DisplayUrl = '';
             product.ExternalId = 'sku123';
            product.IsActive = true;
            product.testType__c='PSC';
            product.performingSite__c='PHP';
            insert product;

        Panel__c panel =  new Panel__c(Product__c=product.Id);
        insert panel;

        Test__c test =  new Test__c(Test_Code__c='test',Test_Name__c='test',Description__c='test');
        insert test;

        Panel_Test__c panelTest= new Panel_Test__c(Panel__c=panel.Id,Test__c=test.Id);
        insert panelTest;

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
            Person_Record__c = person.Id,
            Name='TETS81892-12781',
            PWN_ID__C='12671281',
            Physician_First_Name__c='asasd',
            Physician_Last_Name__c='bcvm',
            Physician_Npi__c='122121',
            Physician_Upin__c='12121'
        );
        insert labOrder;

        Lab_Order_Panel__c labOrderPanel = new Lab_Order_Panel__c(Lab_Order__c = labOrder.Id,Status__c='Registered');
        insert labOrderPanel;

         Lab_Panel_Test__c labPanelTest = new Lab_Panel_Test__c(Lab_Order_Panel__c = labOrderPanel.Id, Panel_Test__c=panelTest.Id,Status__c='Registered');
        insert labPanelTest;

        // Mock HTTP response for error
        System.Test.setMock(HttpCalloutMock.class, new MockPWNHttpResponse(400, '{"error": {"fault": {"message": ["Invalid request data"]}}}'));

        CreateLabHUBServiceOrder.HUBServiceInput input = new CreateLabHUBServiceOrder.HUBServiceInput();
        input.token = 'mockToken';
        input.labOrderId = labOrder.Id;
        inputs.add(input);
        // Act
        System.Test.startTest();
        List<CreateLabHUBServiceOrder.HUBServiceOutput> result = CreateLabHUBServiceOrder.createHubOrder(inputs);
        System.Test.stopTest();

        // Assert
        System.assertEquals(1, result.size());
        CreateLabHUBServiceOrder.HUBServiceOutput output = result[0];
        // System.assertEquals('Error', output.status);
        // System.assertEquals('400', output.responseCode);
        // System.assertEquals('Invalid request data', output.responseMessage);
    }
    
    
    @IsTest
    static void testCreateHUBOrderIsKitTrue_Success() {
        // Arrange
        List<CreateLabHUBServiceOrder.HUBServiceInput> inputs = new List<CreateLabHUBServiceOrder.HUBServiceInput>();
        
    
        Kit_Details__c kit = new Kit_Details__c();
       // kit.Fulfillment_Order_Id__c=fo.Id;
       // kit.Order_Summary__c=fo1.OrderSummaryId;
       //  kit.Order_Number__c='QST-'+fo.Id;
        kit.Record_Type__c  = 'GSS';
        kit.Activation_Code__c = '12345';
        kit.Verification_ID__c = '123';
       kit.Date_of_Collection__c  =  System.today();
        kit.ActivationUser_Customer_Email__c='test@test.com';
        kit.ActivationUser_Customer_Id__c='1212121211';
        kit.Status__c='Activated';
        kit.Lab_Status__c='Sample Received';
        kit.Type__c='at_home';
     	kit.Prism_ID__c  = '12345';
        kit.Tracking_Number__c='1212344gjasd';
        kit.consent_To_Bank__c ='yes';
        kit.consent_To_Process__c='yes';
        kit.consent_To_Research__c='yes';
        kit.Consent_To_Bank_Version__c='1.0';
        kit.Consent_To_Process_Sample_Version__c='1.0';
        kit.Consent_To_Research_Version__c='1.0';
        insert kit;
        

       Product2 product = new Product2();
            product.Name = 'Test';
            product.Description = 'Test';
            product.ProductCode = 'test';
            product.StockKeepingUnit = 'Test'+ String.valueOf(1);
            product.DisplayUrl = '';
            product.ExternalId = 'sku123';
            product.IsActive = true;
            product.testType__c='PSC';
            product.performingSite__c='PHP';
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
            Kit_Detail__c = kit.id,
            Is_Kit__c = true,
           Is_Partner__c=true,
            Client_Id__c = '12345',
            Person_Record__c = person.Id,
            Name='TETS81892-12782323',
            PWN_ID__C='12671281',
            Physician_First_Name__c='asasd',
            Physician_Last_Name__c='bcvm',
            Physician_Npi__c='122121',
            Physician_Upin__c='12121'
        );
        insert labOrder;

        // Insert Lab_Order_Panel__c and Lab_Panel_Test__c records
        Lab_Order_Panel__c labOrderPanel = new Lab_Order_Panel__c(Lab_Order__c = labOrder.Id,Status__c='Registered', AOE__c = '[{"isAoe":true}]');
        insert labOrderPanel;

        Lab_Panel_Test__c labPanelTest = new Lab_Panel_Test__c(Lab_Order_Panel__c = labOrderPanel.Id, Panel_Test__c=panelTest.Id,Status__c='Registered');
        insert labPanelTest;

        // Mock HTTP response
        System.Test.setMock(HttpCalloutMock.class, new MockPWNHttpResponse(201, '{"order": {"physicianReview": {"firstName": "John", "lastName": "Doe", "upin": "12345", "npi": "67890"}, "id": "pwnId123"}}'));

        CreateLabHUBServiceOrder.HUBServiceInput input = new CreateLabHUBServiceOrder.HUBServiceInput();
        input.token = 'mockToken';
        input.labOrderId = labOrder.Id;
        inputs.add(input);
        // Act
        System.Test.startTest();
        List<CreateLabHUBServiceOrder.HUBServiceOutput> result = CreateLabHUBServiceOrder.createHubOrder(inputs);
        System.Test.stopTest();

        // Assert
        System.assertEquals(1, result.size());
        CreateLabHUBServiceOrder.HUBServiceOutput output = result[0];
        System.assertEquals(labOrder.Id, output.labOrderId);
        System.assertEquals('Success', output.status);
        System.assertEquals('201', output.responseCode);
        System.assertEquals('Success', output.responseMessage);
        
    }
    
    
    // Mock class for HTTP response
    private class MockPWNHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public MockPWNHttpResponse(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }

@IsTest(SeeAllData=true)
    static void testCreateHUBOrder_Success_Minor() {
        // Arrange
        List<CreateLabHUBServiceOrder.HUBServiceInput> inputs = new List<CreateLabHUBServiceOrder.HUBServiceInput>();

        //Account for Minors
        Account minorAccount = new Account(
            Name = 'Minor Account'
        );
        insert minorAccount;
        // Mock Product & Panel Data
        Product2 product = new Product2(
            Name = 'MinorTestProduct',
            ProductCode = 'MINOR001',
            ExternalId = 'skuMinor',
            IsActive = true,
            testType__c = 'PSC',
            performingSite__c = 'PHP'
        );
        insert product;

        Product2 shippingProduct = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode = 'Shipping' LIMIT 1];

        Product_AOE__c productAOE = new Product_AOE__c(
            Product__c = product.Id,
            Payload_Question__c = 'None of the above apply to me',
            Send_to_HUB__c = true,
            Option_Type__c = 'MULTISELECT',
            Question_Code__c = '22200003',
            Type__c = 'AOE'
        );
        insert productAOE;

        Product_AOE__c productAOESystem = new Product_AOE__c(
            Product__c = product.Id,
            Payload_Question__c = 'None of the above apply to me',
            Send_to_HUB__c = true,
            Option_Type__c = 'SYSTEM',
            Question_Code__c = '22200003',
            Type__c = 'AOE'
        );
        insert productAOESystem;

        Product_AOE_Option__c option1 = new Product_AOE_Option__c(
            Product_AOE__c = productAOE.Id,
            Option_Code__c = 'Do you have an active bleed or medical condition requiring immediate medical attention?'      
        );
        insert option1;
        Product_AOE_Option__c option2 = new Product_AOE_Option__c(
            Product_AOE__c = productAOESystem.Id,
            Option_Code__c = 'Do you have an active bleed or medical condition requiring immediate medical attention?'      
        );
        insert option2;

        Panel__c panel = new Panel__c(Product__c = product.Id);
        insert panel;

        Test__c test = new Test__c(Test_Code__c = 'MTEST', Test_Name__c = 'Minor Test', Description__c = 'Minor Desc');
        insert test;

        Panel_Test__c panelTest = new Panel_Test__c(Panel__c = panel.Id, Test__c = test.Id);
        insert panelTest;

        // Guardian (Person Record)
        Person_Record__c guardian = new Person_Record__c(
            First_Name__c = 'Parent',
            Last_Name__c = 'Guardian',
            Email__c = 'parent@example.com',
            Address_Line_1__c = '456 Elm St',
            Unique_Identifier__c = 'Parent001',
            City__c = 'Springfield',
            Country__c = 'USA',
            State__c = 'IL',
            Postal_Code__c = '62701',
            Phone__c = '5551234567',
            Gender__c = 'Female',
            Date_of_Birth__c = Date.newInstance(1985, 3, 14)
        );
        insert guardian;

        Id pricebookId = System.Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(    Id = pricebookId,    IsActive = true);
        update standardPricebook;

        //Order for Minor
        Order minor_order = new Order(
            AccountId = minorAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Client_Id__c = '12345',
            Minor_Order__c = true,
            Pricebook2Id = standardPricebook.Id
        );
        insert minor_order;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbe;

        Id deliveryMethodId = [
            SELECT Id 
            FROM OrderDeliveryMethod 
            WHERE Name = 'Standard' 
            LIMIT 1
        ].Id;

        OrderDeliveryGroup odg = new OrderDeliveryGroup(
            OrderId = minor_order.Id,
            DeliverToName = 'Minor Guardian',
            OrderDeliveryMethodId = deliveryMethodId
        );
        insert odg;

        OrderItem oi = new OrderItem(
            OrderId = minor_order.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00,
            OrderDeliveryGroupId = odg.Id,
            TotalLineAmount = 100.00
        );
        insert oi;

        OrderItem orderItem2 = new OrderItem(
            OrderId = minor_order.Id,
            Product2Id = shippingProduct.Id,
            PricebookEntryId = pbe.Id, //[SELECT Id FROM PricebookEntry WHERE Product2Id = :shippingProduct.Id AND Pricebook2Id = :standardPricebook.Id LIMIT 1].Id,
            Quantity = 1,
            UnitPrice = 0.00,
            OrderDeliveryGroupId = odg.Id,
            TotalLineAmount = 0.00
        );
        insert orderItem2;

        minor_order.Status = 'Activated';
        update minor_order;

        OrderSummary os = [SELECT Id FROM OrderSummary WHERE OriginalOrderId = :minor_order.Id LIMIT 1];

        String newOrderSummaryId = null;

        if (os == null) {
            // 1. Instantiate the Input Representation
            ConnectApi.OrderSummaryInputRepresentation orderSummaryInput = 
                new ConnectApi.OrderSummaryInputRepresentation();

            // 2. Set the required OrderId
            orderSummaryInput.orderId = minor_order.Id;

            // 3. (Optional but recommended) Set the OrderLifeCycleType
            // 'MANAGED' is the default and used by Salesforce Order Management.
            // 'UNMANAGED' is used for orders managed by an external system.
            orderSummaryInput.orderLifeCycleType = 'UNMANAGED'; 

            //orderSummaryInput.orderDeliveryMethodId = deliveryMethodId;
            // 4. Call the static creation method
            ConnectApi.OrderSummaryOutputRepresentation orderSummaryOutput = 
                ConnectApi.OrderSummaryCreation.createOrderSummary(orderSummaryInput);

            // The actual OrderSummary record ID is in the output:
            newOrderSummaryId = orderSummaryOutput.orderSummaryId;
        }else {
            newOrderSummaryId = os.Id;
        }

        
        // Minor Lab Order
        Lab_Order__c minorOrder = new Lab_Order__c(
            Is_Partner__c=true,
            Client_Id__c = '12345',
            Person_Record__c = guardian.Id,
            Name='TETS81892-12782323',
            PWN_ID__C='12671281',
            Physician_First_Name__c='asasd',
            Physician_Last_Name__c='bcvm',
            Physician_Npi__c='122121',
            Physician_Upin__c='12121',
            Minor_First_Name__c = 'Little',
            Minor_Last_Name__c = 'Guardian',
            Minor_Gender__c = 'Male',
            Minor_Date_of_Birth__c = Date.newInstance(2015, 5, 5),
            Consent_Minor_Date_Time__c = Date.newInstance(2024, 5, 5),
            Minor_Address_Line_1__c = '789 Minor St',
            Minor_Address_Line_2__c = 'Apt 2',
            Minor_City__c = 'Springfield',
            Minor_State__c = 'IL',
            Minor_Zip_Code__c = '62701',
            Minor_Country__c = 'USA',
            Order_Summary__c = newOrderSummaryId
        );
        insert minorOrder;

        // Lab Order Panel & Test
        Lab_Order_Panel__c minorPanel = new Lab_Order_Panel__c(
            Lab_Order__c = minorOrder.Id,
            Panel__c = panel.Id,
            Status__c = 'Registered',
            AOE__c = '[{"isAoe":true}]'
        );
        insert minorPanel;

        Lab_Order_Panel_AOE__c labOrderPanelAOE = new Lab_Order_Panel_AOE__c(
            Lab_Order_Panel__c = minorPanel.Id,
            Product_AOE__c = productAOE.Id,
            Product_AOE_Option__c = option1.Id
        );
        insert labOrderPanelAOE;

        Lab_Order_Panel_AOE__c labOrderPanelSystem = new Lab_Order_Panel_AOE__c(
            Lab_Order_Panel__c = minorPanel.Id,
            Product_AOE__c = productAOESystem.Id,
            Product_AOE_Option__c = option2.Id
        );
        insert labOrderPanelSystem;

        Lab_Panel_Test__c minorLabPanelTest = new Lab_Panel_Test__c(
            Panel_Test__c=panelTest.Id,
            Lab_Order_Panel__c = minorPanel.Id,
            Status__c = 'Registered'
        );
        insert minorLabPanelTest;

        // Mock HTTP Response
        System.Test.setMock(HttpCalloutMock.class, new MockPWNHttpResponse(201, '{"status":"success"}'));

        CreateLabHUBServiceOrder.HUBServiceInput input = new CreateLabHUBServiceOrder.HUBServiceInput();
        input.token = 'mockMinorToken';
        input.labOrderId = minorOrder.Id;
        inputs.add(input);

        // Act
        System.Test.startTest();
        List<CreateLabHUBServiceOrder.HUBServiceOutput> result = CreateLabHUBServiceOrder.createHubOrder(inputs);
        System.Test.stopTest();

        // Assert
        System.assertEquals(1, result.size(), 'Should return 1 result');
        CreateLabHUBServiceOrder.HUBServiceOutput output = result[0];
        System.assertEquals('Success', output.status);
        System.assertEquals('201', output.responseCode);
        //System.assert(output.requestPayload.contains('MinorFirst'), 'Minor first name must appear in request JSON');
        //System.assert(output.requestPayload.contains('Parent'), 'Guardian name should appear in next_of_kin section');
    }

}