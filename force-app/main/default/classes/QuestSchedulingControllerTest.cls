@IsTest
private class QuestSchedulingControllerTest {

    private class MockTokenSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('POST', req.getMethod());
            System.assert(req.getEndpoint().contains('/oauth2/token'));

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"access_token":"mock-token-abc123","token_type":"Bearer","expires_in":3600}');
            return res;
        }
    }

    private class MockTokenFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);
            res.setBody('{"error":"unauthorized_client","error_description":"Invalid client credentials"}');
            return res;
        }
    }

    @IsTest
    static void testGetAccessTokenSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockTokenSuccess());

        Test.startTest();
        String token = QuestSchedulingController.getAccessToken();
        Test.stopTest();

        System.assertEquals('mock-token-abc123', token, 'Token should match mock response');
    }

    @IsTest
    static void testGetAccessTokenFailure() {
        Test.setMock(HttpCalloutMock.class, new MockTokenFailure());

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            QuestSchedulingController.getAccessToken();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'AuraHandledException should be thrown on auth failure');
    }
}