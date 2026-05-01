@isTest
public class SFMCRefreshAuthTokenTest {

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
        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        // Schedule the job
        Test.startTest();
        String jobId = System.schedule('TestSFMCRefreshAuthToken', '0 0 1 * * ?', new SFMCRefreshAuthToken());
        Test.stopTest();

        // Verify that the job was scheduled successfully
        System.assertNotEquals(null, jobId, 'Job was not scheduled successfully');

           }
}