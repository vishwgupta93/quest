@isTest
private class KitDetailEventTriggerHandlerTest {

    @isTest
    static void testSendPayLoad_Success() {
        
        Test.startTest();
        // Set up the mock for a successful callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());
        OMS_Mule_MQ_Token__c setting = new OMS_Mule_MQ_Token__c();
        setting.Token__c = 'accessToken';
        insert setting;
        // Call the @future method
        KitDetailEventTriggerHandler.sendPayLoad('testFulfillmentOrderId','labRefId');
        Test.stopTest();

       
    }

    @isTest
    static void testSendPayLoad_Retries() {
        
        Test.startTest();
        // Set up the mock for a 401 unauthorized response to trigger retries
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorUnauthorized());
        OMS_Mule_MQ_Token__c setting = new OMS_Mule_MQ_Token__c();
        setting.Token__c = 'accessToken';
        insert setting;
        // Call the @future method
        KitDetailEventTriggerHandler.sendPayLoad('testFulfillmentOrderId','labRefId');
        Test.stopTest();

        
    }

   

    private class MockHttpResponseGeneratorSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a fake HTTP response for a successful callout
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
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