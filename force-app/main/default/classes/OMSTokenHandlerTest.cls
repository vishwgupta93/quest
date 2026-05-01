@IsTest
public class OMSTokenHandlerTest {
        
    private class MockOMSMuleTokenHandler implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake HTTP response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setBody('{"access_token": "mockAccessToken"}');
        return res;
    }
}

private class MockOMSMuleTokenHandlerError implements HttpCalloutMock {
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
        
        Test.setMock(HttpCalloutMock.class, new MockOMSMuleTokenHandler());

        OMSMuleTokenHandler.fetchTokenAndUpdate();
        Test.stopTest();

        
        List<OMS_Mule_MQ_Token__c> tokens = [SELECT Id, Token__c FROM OMS_Mule_MQ_Token__c LIMIT 1];
        System.assertEquals(1, tokens.size(), 'Expected one OMS_Mule_MQ_Token__c record');
        System.assertEquals('mockAccessToken', tokens[0].Token__c, 'Token value should be updated');
    }

    @isTest
    static void testFetchTokenError() {
        
        
        try 
        {
            Test.startTest();
    
        Test.setMock(HttpCalloutMock.class, new MockOMSMuleTokenHandlerError());

    
        OMSMuleTokenHandler.fetchTokenAndUpdate();
        Test.stopTest();
        }
        catch(CalloutException e)
        {
            System.assertEquals('Authentication request failed with status code: 403', e.getMessage(), 'Token Exception');
        }

        

       
    }

    @isTest
    static void testFetchToken() {
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockOMSMuleTokenHandler());

        
        String accessToken = OMSMuleTokenHandler.fetchToken();
        Test.stopTest();

        
        System.assertEquals('mockAccessToken', accessToken, 'Token value should be fetched');
    }

}