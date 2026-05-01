@IsTest
public class CreateLabOrderPWNServiceTest {

    @IsTest
    static void testCreatePWNOrder_Success() {
        // Arrange
        List<CreateLabPWNServiceOrder.PWNServiceInput> inputs = new List<CreateLabPWNServiceOrder.PWNServiceInput>();
        
        

       Product2 product = new Product2();
            product.Name = 'Test';
            product.Description = 'Test';
            product.ProductCode = 'test';
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

        // Insert Lab_Order_Panel__c and Lab_Panel_Test__c records
        Lab_Order_Panel__c labOrderPanel = new Lab_Order_Panel__c(Lab_Order__c = labOrder.Id, AOE__c = '[{"isAoe":true}]');
        insert labOrderPanel;

        Lab_Panel_Test__c labPanelTest = new Lab_Panel_Test__c(Lab_Order_Panel__c = labOrderPanel.Id, Panel_Test__c=panelTest.Id);
        insert labPanelTest;

        // Mock HTTP response
        System.Test.setMock(HttpCalloutMock.class, new MockPWNHttpResponse(201, '{"order": {"physicianReview": {"firstName": "John", "lastName": "Doe", "upin": "12345", "npi": "67890"}, "id": "pwnId123"}}'));

        CreateLabPWNServiceOrder.PWNServiceInput input = new CreateLabPWNServiceOrder.PWNServiceInput();
        input.token = 'mockToken';
        input.labOrderId = labOrder.Id;
        inputs.add(input);
        // Act
        System.Test.startTest();
        List<CreateLabPWNServiceOrder.PWNServiceOutput> result = CreateLabPWNServiceOrder.createPWNOrder(inputs);
        System.Test.stopTest();

        // Assert
        System.assertEquals(1, result.size());
        CreateLabPWNServiceOrder.PWNServiceOutput output = result[0];
        System.assertEquals(labOrder.Id, output.labOrderId);
        System.assertEquals('Success', output.status);
        System.assertEquals('201', output.responseCode);
        System.assertEquals('Success', output.responseMessage);
        System.assertEquals('John', output.firstName);
        System.assertEquals('Doe', output.lastName);
        System.assertEquals('12345', output.upin);
        System.assertEquals('67890', output.npi);
        System.assertEquals('pwnId123', output.pwnID);
    }

    @IsTest
    static void testCreatePWNOrder_Error() {
        // Arrange
        List<CreateLabPWNServiceOrder.PWNServiceInput> inputs = new List<CreateLabPWNServiceOrder.PWNServiceInput>();
        
        Person_Record__c  pr = new Person_Record__c ();
        pr.First_Name__c = 'test';
        pr.Date_of_Birth__c = Date.valueOf('1994-09-30');
        pr.Gender__c = 'Male';
        pr.Address_Line_1__c = '2005 Lamberts Branch Road'; 
        pr.City__c = 'Taloga';
        pr.Email__c = 'srini491.03@yopmail.com';
        pr.Last_Name__c = 'TestLastName';
        pr.Phone__c = '7389768765';
        pr.Postal_Code__c = '73667';
        pr.State__c = 'Oklahoma';
        pr.Unique_Identifier__c = 'srini491.03@yopmail.com:1994-09-30:test';
        insert pr;
        

        Product2 product = new Product2();
            product.Name = 'Test';
            product.Description = 'Test';
            product.ProductCode = 'test';
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

        // Insert required records
        Lab_Order__c labOrder = new Lab_Order__c(
           Is_Partner__c=true,
            Client_Id__c = '12345',Person_Record__c = pr.id
        );
        insert labOrder;
        //String AOEString = 'Test';
        //Object obj = (Object)AOEString;
			List<Object> AOELst = new List<Object>();
       // AOELst.add(obj);
        Lab_Order_Panel__c labOrderPanel = new Lab_Order_Panel__c(Lab_Order__c = labOrder.Id);
        insert labOrderPanel;

         Lab_Panel_Test__c labPanelTest = new Lab_Panel_Test__c(Lab_Order_Panel__c = labOrderPanel.Id, Panel_Test__c=panelTest.Id);
        insert labPanelTest;

        // Mock HTTP response for error
        System.Test.setMock(HttpCalloutMock.class, new MockPWNHttpResponse(400, '{"error": {"fault": {"message": ["Invalid request data"]}}}'));

        CreateLabPWNServiceOrder.PWNServiceInput input = new CreateLabPWNServiceOrder.PWNServiceInput();
        input.token = 'mockToken';
        input.labOrderId = labOrder.Id;
        inputs.add(input);
        // Act
        System.Test.startTest();
        List<CreateLabPWNServiceOrder.PWNServiceOutput> result = CreateLabPWNServiceOrder.createPWNOrder(inputs);
        System.Test.stopTest();

        // Assert
        System.assertEquals(1, result.size());
        CreateLabPWNServiceOrder.PWNServiceOutput output = result[0];
        // System.assertEquals('Error', output.status);
        // System.assertEquals('400', output.responseCode);
        // System.assertEquals('Invalid request data', output.responseMessage);
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
static void testCreatePWNOrder_Success_Minor() {
        //Account for Minors
        Account minorAccount = new Account(
            Name = 'Minor Account'
        );
        insert minorAccount;

        Product2 shippingProduct = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode = 'Shipping' LIMIT 1];
        // Arrange
        List<CreateLabPWNServiceOrder.PWNServiceInput> inputs = new List<CreateLabPWNServiceOrder.PWNServiceInput>();
        
        // Mock related data setup        
       Product2 product = new Product2();
        product.Name = 'Test';
        product.Description = 'Test';
        product.ProductCode = 'test';
        product.StockKeepingUnit = 'Test'+ String.valueOf(1);
        product.DisplayUrl = '';
        product.ExternalId = 'sku123';
        product.IsActive = true;
        insert product;

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
            Product2Id = shippingProduct.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00,
            OrderDeliveryGroupId = odg.Id,
            TotalLineAmount = 149.0
        );
        insert oi;

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
            
            newOrderSummaryId = orderSummaryOutput.orderSummaryId;
        }else {
            newOrderSummaryId = os.Id;
        }

        // The actual OrderSummary record ID is in the output:
       

        Panel__c panel = new Panel__c(Product__c = product.Id);
        insert panel;

        Test__c test = new Test__c(Test_Code__c = 'TMINOR', Test_Name__c = 'Minor Test', Description__c = 'Minor flow test');
        insert test;

        Panel_Test__c panelTest = new Panel_Test__c(Panel__c = panel.Id, Test__c = test.Id);
        insert panelTest;

        // Insert Parent Person record
        Person_Record__c parent = new Person_Record__c(
            First_Name__c = 'Parent',
            Last_Name__c = 'Guardian',
            Email__c = 'parent.guardian@example.com',
            Address_Line_1__c = '123 Minor Ln',
            Unique_Identifier__c = 'MinorUniq1',
            City__c = 'Smalltown',
            Country__c = 'USA',
            State__c = 'CA',
            Postal_Code__c = '90001',
            Phone__c = '5555551234',
            Gender__c = 'Female',
            Date_of_Birth__c = Date.newInstance(1980, 2, 2)
        );
        insert parent;


        // Insert Lab Order (with Minor fields)
        Lab_Order__c labOrder = new Lab_Order__c(
            Client_Id__c = 'C-1001',
            Person_Record__c = parent.Id,
            Minor_First_Name__c = 'Little',
            Minor_Last_Name__c = 'Guardian',
            Minor_Gender__c = 'Male',
            Minor_Date_of_Birth__c = Date.newInstance(2015, 5, 5),
            Consent_Minor_Date_Time__c = Date.newInstance(2024, 5, 5),
            Minor_Address_Line_1__c = '123 Minor Ln',
            Minor_Address_Line_2__c = '',
            Minor_City__c = 'Smalltown',
            Minor_State__c = 'CA',
            Minor_Zip_Code__c = '90001',
            Minor_Country__c = 'USA',
            Order_Summary__c = newOrderSummaryId
        );
        insert labOrder;

        // Insert Lab_Order_Panel__c and Lab_Panel_Test__c
        Lab_Order_Panel__c labOrderPanel = new Lab_Order_Panel__c(
            Lab_Order__c = labOrder.Id,
            AOE__c = '[{"isAoe":true,"question":"Age?","answer":"10"}]'
        );
        insert labOrderPanel;

        Lab_Panel_Test__c labPanelTest = new Lab_Panel_Test__c(
            Lab_Order_Panel__c = labOrderPanel.Id,
            Panel_Test__c = panelTest.Id
        );
        insert labPanelTest;

        // Mock successful HTTP response
        System.Test.setMock(HttpCalloutMock.class, 
            new MockPWNHttpResponse(
                201,
                '{"order": {"physicianReview": {"firstName": "DrTest", "lastName": "Smith", "upin": "U123", "npi": "NPI123"}, "id": "PWN-MINOR-123"}}'
            )
        );

        // Prepare Invocable Input
        CreateLabPWNServiceOrder.PWNServiceInput input = new CreateLabPWNServiceOrder.PWNServiceInput();
        input.token = 'mockToken';
        input.labOrderId = labOrder.Id;
        inputs.add(input);

        // Act
        System.Test.startTest();
        List<CreateLabPWNServiceOrder.PWNServiceOutput> result = CreateLabPWNServiceOrder.createPWNOrder(inputs);
        System.Test.stopTest();

        // Assert
        System.assertEquals(1, result.size(), 'One result expected');
        CreateLabPWNServiceOrder.PWNServiceOutput output = result[0];
        Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(output.requestPayload);
        //nested objects
        Map<String, Object> order = (Map<String, Object>) payloadMap.get('order');
        Map<String, Object> customer = (Map<String, Object>) order.get('customer'); 
        //get the externalId
        String externalId = (String)customer.get('externalId');

        System.assertEquals(labOrder.Id, output.labOrderId);
        System.assertEquals('Success', output.status);
        System.assertEquals('201', output.responseCode);
        System.assertEquals('Success', output.responseMessage);
        System.assertEquals('DrTest', output.firstName);
        System.assertEquals('Smith', output.lastName);
        System.assertEquals('U123', output.upin);
        System.assertEquals('NPI123', output.npi);
        System.assertEquals('PWN-MINOR-123', output.pwnID);
        System.assertEquals(externalId == '' || externalId == null, true,'External Id should be empty when is a minor.');


    }


}