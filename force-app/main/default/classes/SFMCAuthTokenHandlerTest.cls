@isTest
private class SFMCAuthTokenHandlerTest {

    private class MockHttpResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a mock HTTP response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"access_token":"mockAccessToken"}');
            return res;
        }
    }

    @isTest
    static void testFetchTokenAndUpdate() {
        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        // Call the method under test
        Test.startTest();
        SFMCAuthTokenHandler.fetchTokenAndUpdate();
        Test.stopTest();

        // Verify that the custom setting is updated
        SFMC_OMS_Config__c config = [SELECT Auth_Token__c FROM SFMC_OMS_Config__c WHERE Channel__c = 'QD-CIT' LIMIT 1];
        System.assertEquals('mockAccessToken', config.Auth_Token__c);
    }
}