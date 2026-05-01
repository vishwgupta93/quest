@IsTest
public class SlackNotifierTest {
    @IsTest
    static void testCreateHUBOrder_Success() {
       
        

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
        List<SlackNotifier.RequestInput> inputs = new List<SlackNotifier.RequestInput>();
                System.Test.setMock(HttpCalloutMock.class, new MockSlackHttpResponse(201, '{"order"}'));
		 SlackNotifier.RequestInput input = new SlackNotifier.RequestInput();
        input.slackMessage = 'messageTest';
        input.labOrderId = labOrder.Name;
        inputs.add(input);
         System.Test.startTest();
         SlackNotifier.sendSlackMessage(inputs);
        System.Test.stopTest();
        
    }

    private class MockSlackHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public MockSlackHttpResponse(Integer statusCode, String responseBody) {
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