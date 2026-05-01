@IsTest
public class OMSTokenHandlerJobTest {
    
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
    static void testScheduledJob() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        
        Test.startTest();
        OMSTokenHandlerJob btch = new OMSTokenHandlerJob();
        btch.execute(null); 
        Test.stopTest();
        List<OMS_Mule_MQ_Token__c> tokens = [SELECT Id, Token__c FROM OMS_Mule_MQ_Token__c LIMIT 1];
        System.assertEquals('mockAccessToken', tokens[0].Token__c, 'Token value should be updated');

    }

    @IsTest 
    static void OMSTokenHandlerJobTest () {
        OMSTokenHandlerJob  obj = new OMSTokenHandlerJob();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, obj); 
  }     
}