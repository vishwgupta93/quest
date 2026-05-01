@isTest
private class PingFedTest {

    private class MockPingFedTokenHandler implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake HTTP response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"access_token": "mockAccessToken"}');
            return res;
        }
    }
    
    private class MockPingFedTokenHandlerError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Simulate an error by returning a 500 status code
            HttpResponse res = new HttpResponse();
            res.setStatusCode(403);
            return res;
        }
    }

    @isTest
    static void testFetchTokenAndUpdate() {
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockPingFedTokenHandler());

        PingFed.OAuthInput input = new PingFed.OAuthInput();
        input.authUrl='authUrl';
        input.client_id='clientId';
        input.client_secret='clientSecret';

        List<PingFed.OAuthInput> inputs= new List<PingFed.OAuthInput>();
        inputs.add(input);

        List<PingFed.OAuthOutput> results = PingFed.authenticateAndgetToken(inputs);
        Test.stopTest();

        
        System.assertEquals(1, results.size(), 'Expected one OMS_Mule_MQ_Token__c record');
        System.assertEquals('mockAccessToken', results[0].accessToken, 'Token value should be updated');
    }

    @isTest
    static void testFetchTokenError() {
        
        
        try 
        {
            Test.startTest();
    
        Test.setMock(HttpCalloutMock.class, new MockPingFedTokenHandlerError());

    
        PingFed.OAuthInput input = new PingFed.OAuthInput();
        input.authUrl='authUrl';
        input.client_id='clientId';
        input.client_secret='clientSecret';

        List<PingFed.OAuthInput> inputs= new List<PingFed.OAuthInput>();
        inputs.add(input);

        List<PingFed.OAuthOutput> results = PingFed.authenticateAndgetToken(inputs);
        Test.stopTest();
        }
        catch(CalloutException e)
        {
            System.assertEquals('Authentication request failed with status code: 403', e.getMessage(), 'Token Exception');
        }

        

       
    }
   
}