@IsTest
public class CancelLabHUBServiceOrderTest {

    @IsTest
    static void testCreateHUBOrder_Success() {
        // Arrange
        List<CancelLabHUBOrder.CancelLabHUBOrderInput> inputs = new List<CancelLabHUBOrder.CancelLabHUBOrderInput>();
        
        

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

        CancelLabHUBOrder.CancelLabHUBOrderInput input = new CancelLabHUBOrder.CancelLabHUBOrderInput();
        input.token = 'mockToken';
        input.labOrderId = labOrder.Id;
        inputs.add(input);
        // Act
        System.Test.startTest();
        List<CancelLabHUBOrder.CancelLabHUBOrderOutput> result = CancelLabHUBOrder.createHubOrder(inputs);
        System.Test.stopTest();

        // Assert
        System.assertEquals(1, result.size());
        
        
    }

    @IsTest
    static void testCreateHUBOrder_Error() {
        // Arrange
                List<CancelLabHUBOrder.CancelLabHUBOrderInput> inputs = new List<CancelLabHUBOrder.CancelLabHUBOrderInput>();
        
        

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
            Physician_Upin__c='12121'
        );
        insert labOrder;

        // Insert Lab_Order_Panel__c and Lab_Panel_Test__c records
        Lab_Order_Panel__c labOrderPanel = new Lab_Order_Panel__c(Lab_Order__c = labOrder.Id,Status__c='Registered', AOE__c = '[{"isAoe":true}]');
        insert labOrderPanel;

        Lab_Panel_Test__c labPanelTest = new Lab_Panel_Test__c(Lab_Order_Panel__c = labOrderPanel.Id, Panel_Test__c=panelTest.Id,Status__c='Registered');
        insert labPanelTest;

        // Mock HTTP response for error
        System.Test.setMock(HttpCalloutMock.class, new MockPWNHttpResponse(400, '{"error": {"fault": {"message": ["Invalid request data"]}}}'));

        CancelLabHUBOrder.CancelLabHUBOrderInput input = new CancelLabHUBOrder.CancelLabHUBOrderInput();
        input.token = 'mockToken';
        input.labOrderId = labOrder.Id;
        inputs.add(input);
        // Act
        System.Test.startTest();
        List<CancelLabHUBOrder.CancelLabHUBOrderOutput> result = CancelLabHUBOrder.createHubOrder(inputs);
        System.Test.stopTest();

        // Assert
        System.assertEquals(1, result.size());
        CancelLabHUBOrder.CancelLabHUBOrderOutput output = result[0];
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
}