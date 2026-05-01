@isTest
public class EOSTResultsMQReaderTest {
    
    @isTest
    static void testReadMQWithExistingToken() {
        // Setup mock HTTP response
        OMS_Mule_MQ_Token__c setting = new OMS_Mule_MQ_Token__c();
        setting.Token__c = 'accessToken';
        insert setting;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());
        
        // Call the method
        Test.startTest();
        EOSTResultsMQReader.readMQ();
        Test.stopTest();
        
        // Verify the results
        // List<EOST_OMS_Log__c> logs = [SELECT Id, EOST_Payload__c FROM EOST_OMS_Log__c];
        // System.assertEquals(1, logs.size(), 'Expected one log entry.');
        
    }

    @isTest
    static void testExceptionHandling() {
        // Setup mock HTTP response that throws an exception
        OMS_Mule_MQ_Token__c setting = new OMS_Mule_MQ_Token__c();
        setting.Token__c = 'accessToken';
        insert setting;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorUnauthorized());
        
        // Call the method
        Test.startTest();
        EOSTResultsMQReader.readMQ();
        Test.stopTest();
        
        // Verify no logs are created
        // List<EOST_OMS_Log__c> logs = [SELECT Id, EOST_Payload__c FROM EOST_OMS_Log__c];
        // System.assertEquals(0, logs.size(), 'Expected no log entries due to exception.');
        
       
    }

    // Mock HttpCalloutMock class
    private class MockHttpResponseGeneratorSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('[{\"headers\": {\"lockId\": \"mockLockId\", \"messageId\": \"mockMessageId\"}, \"body\": \"{\\\"event\\\": {\\\"labRefID\\\": \\\"mockLabRefID\\\"}}\"}]');
            return res;
        }
    }

    private class MockHttpResponseGeneratorUnauthorized implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a fake HTTP response for a 401 unauthorized response to trigger retries
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);
            return res;
        }
    }
}