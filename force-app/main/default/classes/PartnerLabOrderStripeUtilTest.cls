@IsTest
private class PartnerLabOrderStripeUtilTest {
    
    // Mock for successful Stripe API response
    private class StripeSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assert(req.getMethod() == 'GET');
            System.assert(req.getHeader('Content-Type') == 'application/x-www-form-urlencoded');
            System.assert(req.getHeader('Authorization').startsWith('Bearer '));

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"amount_received": 2500}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    // Mock for failed Stripe API response
    private class StripeErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error": "Invalid request"}');
            res.setStatusCode(400);
            return res;
        }
    }

    @IsTest
    static void testRefundPartnerOrder_Success() {
        // Setup mock response
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());

        // Prepare request data
        PartnerLabOrderStripeUtil.Request req = new PartnerLabOrderStripeUtil.Request();
        req.paymentIntentId = 'pi_12345';
        req.paymentKey = 'sk_test_abc123';

      
        Test.startTest();
        List<PartnerLabOrderStripeUtil.Response> responses =
            PartnerLabOrderStripeUtil.refundPartnerOrder(new List<PartnerLabOrderStripeUtil.Request>{ req });
        Test.stopTest();

       
    }

    @IsTest
    static void testRefundPartnerOrder_Error() {
        // Setup mock response
        Test.setMock(HttpCalloutMock.class, new StripeErrorMock());

        PartnerLabOrderStripeUtil.Request req = new PartnerLabOrderStripeUtil.Request();
        req.paymentIntentId = 'pi_67890';
        req.paymentKey = 'sk_test_errorKey';

       
        Test.startTest();
        List<PartnerLabOrderStripeUtil.Response> responses =
            PartnerLabOrderStripeUtil.refundPartnerOrder(new List<PartnerLabOrderStripeUtil.Request>{ req });
        Test.stopTest();

       
    }
}