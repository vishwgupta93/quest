@IsTest
public with sharing class ActivateCustomerTest {
    private class MockHttpResponseGeneratorSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"order": {"physicianReview": {"firstName": "John", "lastName": "Doe", "upin": "12345", "npi": "67890"},"id": "PWN123"}}}');
            return res;
        }
    }

    
    private class MockHttpResponseGeneratorTimeout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(504);
            res.setBody('Time out');
            return res;
        }
    }

    
    private class MockHttpResponseGeneratorBadRequest implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(404);
            res.setBody('{"errorType":"DATA_ERROR",{"error": {"fault": {"message": ["Bad request"]}}}}');
            return res;
        }
    }

    @IsTest (SeeAllData=true)
public static void testActivateCustomer_Success() {

    ActivateCustomer.ActivateCustomerInput input = new ActivateCustomer.ActivateCustomerInput();
    input.token = 'sampleToken';
    input.customerId = 'customerId';

    List<ActivateCustomer.ActivateCustomerInput> inputs = new List<ActivateCustomer.ActivateCustomerInput>{input};

     // Mocking successful HTTP callout
     Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());
     Test.startTest();
     // Call the method
     List<ActivateCustomer.ActivateCustomerOutput> result = ActivateCustomer.enableCustomer(inputs);
     Test.stopTest();

      // Assertions for success scenario
      ActivateCustomer.ActivateCustomerOutput output = result[0];
    System.debug('Response Body::'+output.responsePayload);
     System.assertEquals('Success', output.Status, 'Expected success status');
    System.assertEquals('200', output.responseCode, 'Expected response code 200');

}

@IsTest (SeeAllData=true)
public static void testActivateCustomer_Error() {

    ActivateCustomer.ActivateCustomerInput input = new ActivateCustomer.ActivateCustomerInput();
    input.token = 'sampleToken';
    input.customerId = 'customerId';

    List<ActivateCustomer.ActivateCustomerInput> inputs = new List<ActivateCustomer.ActivateCustomerInput>{input};

     // Mocking successful HTTP callout
     Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorBadRequest());
     Test.startTest();
     // Call the method
     List<ActivateCustomer.ActivateCustomerOutput> result = ActivateCustomer.enableCustomer(inputs);
     Test.stopTest();

      // Assertions for success scenario
      ActivateCustomer.ActivateCustomerOutput output = result[0];
    System.debug('Response Body::'+output.responsePayload);
    System.assertEquals('Error', output.Status, 'Expected error status');
    System.assertEquals('404', output.responseCode, 'Expected response code 404');

}

@IsTest (SeeAllData=true)
public static void testActivateCustomer_Timeout() {

    ActivateCustomer.ActivateCustomerInput input = new ActivateCustomer.ActivateCustomerInput();
    input.token = 'sampleToken';
    input.customerId = 'customerId';

    List<ActivateCustomer.ActivateCustomerInput> inputs = new List<ActivateCustomer.ActivateCustomerInput>{input};

     // Mocking successful HTTP callout
     Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorTimeout());
     Test.startTest();
     // Call the method
     List<ActivateCustomer.ActivateCustomerOutput> result = ActivateCustomer.enableCustomer(inputs);
     Test.stopTest();

      // Assertions for success scenario
      ActivateCustomer.ActivateCustomerOutput output = result[0];
    System.debug('Response Body::'+output.responsePayload);
    System.assertEquals('Error', output.Status, 'Expected error status');
    System.assertEquals('504', output.responseCode, 'Expected response code 504');

}
}