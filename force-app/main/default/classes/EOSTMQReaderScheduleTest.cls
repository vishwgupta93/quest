@IsTest
public with sharing class EOSTMQReaderScheduleTest {
  
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

    @isTest
    static void testScheduledJob() {
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());

        
        
        OMS_Mule_MQ_Token__c setting = new OMS_Mule_MQ_Token__c();
        setting.Token__c = 'accessToken';
        insert setting;
        EOSTMQReaderScheduler btch = new EOSTMQReaderScheduler();
        btch.execute(null); 
        Test.stopTest();
        

    }

    @IsTest 
    static void EOSTMQReaderSchedulerTest () {
        EOSTMQReaderScheduler  obj = new EOSTMQReaderScheduler();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, obj); 
  }     

}