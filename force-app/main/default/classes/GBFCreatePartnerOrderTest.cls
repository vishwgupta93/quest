@isTest
public with sharing class GBFCreatePartnerOrderTest {
    private class MockHttpResponseGeneratorSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"success": true,"message": "0a36w0000000luRAAQ_O7L1P_20240405_001117.xml"}');
            return res;
        }
    }

    
    private class MockHttpResponseGeneratorTimeout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Simulate a timeout by not responding
            throw new CalloutException('Read timed out');
        }
    }

    
    private class MockHttpResponseGeneratorBadRequest implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('{"error": {"fault": {"message": ["Bad request"]}}}');
            return res;
        }
    }

    @IsTest (SeeAllData=true)
    public static void testCreateGBFOrder_Success() {

        Partner_Order__c partnerOrder = getPartnerOrder();

        GBFCreatePartnerOrder.GBFCreatePartnerOrderInput input = new GBFCreatePartnerOrder.GBFCreatePartnerOrderInput();
        input.apiKey = 'sampleToken';
        input.partnerOrderId = partnerOrder.Id;
        input.test=true;

        List<GBFCreatePartnerOrder.GBFCreatePartnerOrderInput> inputs = new List<GBFCreatePartnerOrder.GBFCreatePartnerOrderInput>{input};

        // Mocking successful HTTP callout
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());
    Test.startTest();
    // Call the method
    List<GBFCreatePartnerOrder.GBFCreatePartnerOrderOutput> result = GBFCreatePartnerOrder.createGBFOrder(inputs);
    Test.stopTest();

    // Assertions for success scenario
    System.assertEquals(1, result.size(), 'Expected one output record');
    GBFCreatePartnerOrder.GBFCreatePartnerOrderOutput output = result[0];
    System.debug('Response Body::'+output.responsePayload);
    System.assertEquals('Success', output.Status, 'Expected success status');
    System.assertEquals('200', output.responseCode, 'Expected response code 200');

    }

    @IsTest (SeeAllData=true)
    static void testCreateGBFOrder_BadRequest() {
            Partner_Order__c partnerOrder = getPartnerOrder();

            GBFCreatePartnerOrder.GBFCreatePartnerOrderInput input = new GBFCreatePartnerOrder.GBFCreatePartnerOrderInput();
            input.apiKey = 'sampleToken';
            input.partnerOrderId = partnerOrder.Id;
            input.test=true;

            List<GBFCreatePartnerOrder.GBFCreatePartnerOrderInput> inputs = new List<GBFCreatePartnerOrder.GBFCreatePartnerOrderInput>{input};

            // Mocking successful HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorBadRequest());
        Test.startTest();
        // Call the method
        List<GBFCreatePartnerOrder.GBFCreatePartnerOrderOutput> result = GBFCreatePartnerOrder.createGBFOrder(inputs);
        Test.stopTest();

  
    
        // Assertions for 400 error scenario
        System.assertEquals(1, result.size(), 'Expected one output record');
        GBFCreatePartnerOrder.GBFCreatePartnerOrderOutput output = result[0];
        System.assertEquals('Error', output.Status, 'Expected error status');
        System.assertEquals('400', output.responseCode, 'Expected response code 400');
        // Add more assertions for error handling fields
    
        // Clean up test data if needed
        // ...
    }
    
        @IsTest (SeeAllData=true)
        static void testCreateGBFOrder_Timeout() {
            Partner_Order__c partnerOrder = getPartnerOrder();

            GBFCreatePartnerOrder.GBFCreatePartnerOrderInput input = new GBFCreatePartnerOrder.GBFCreatePartnerOrderInput();
            input.apiKey = 'sampleToken';
            input.partnerOrderId = partnerOrder.Id;
            input.test=true;

            List<GBFCreatePartnerOrder.GBFCreatePartnerOrderInput> inputs = new List<GBFCreatePartnerOrder.GBFCreatePartnerOrderInput>{input};

            // Mocking successful HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorTimeout());
        Test.startTest();
        // Call the method
        List<GBFCreatePartnerOrder.GBFCreatePartnerOrderOutput> result = GBFCreatePartnerOrder.createGBFOrder(inputs);
        Test.stopTest();

  
    
        // Assertions for 400 error scenario
        System.assertEquals(1, result.size(), 'Expected one output record');
        GBFCreatePartnerOrder.GBFCreatePartnerOrderOutput output = result[0];
            System.assertEquals('Error', output.Status, 'Expected error status');
            System.assertEquals('504', output.responseCode, 'Expected response code 504');
            // Add more assertions for error handling fields
    
            // Clean up test data if needed
            // ...
        }


    private static Partner_Order__c getPartnerOrder()
    {

        PartnerClientMap__c partner= new PartnerClientMap__c();
        partner.Client_ID__c= 'test';
        partner.Partner_Name__c='test';
        partner.Short_Code__c='test';

        insert partner;
        Partner_Order__c order = new Partner_Order__c();
        order.Retail_Partner__c = partner.Id;
        order.Address_Line_1__c='123 Test';
        order.City__c = 'Test';
        order.State__c='NY';
        order.ZipCode__c='12345';
        order.Country__c='US';
        order.Company_Name__c='Test Company';
        order.Shipping_Method__c='FedEx Ground';
        order.Email__c='test@gmail.com';
        order.PhoneNumber__c='1234567890';

        insert order;

        Product2 product = new Product2();
            product.Name = 'Test';
            product.Description = 'Test';
            product.ProductCode = 'Test123';
            product.StockKeepingUnit = 'Test123' + String.valueOf(12345);
            product.DisplayUrl = '';
            product.ExternalId = 'Test123';
            product.IsActive = true;
            insert  product;

        Partner_Order_Line_Item__c line= new Partner_Order_Line_Item__c();
        line.Partner_Order__c=order.Id;
        line.Product__c=product.Id;
        line.Quantity__c=1000;

        insert line;

        return order;
    }

}