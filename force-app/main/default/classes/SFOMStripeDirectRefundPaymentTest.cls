@isTest
public class SFOMStripeDirectRefundPaymentTest {
    
    @isTest
    static void testRefundPaymentSuccess() {
        // Arrange
        List<SFOMStripeDirectRefundPayment.InputParameters> inputParams = new List<SFOMStripeDirectRefundPayment.InputParameters>();

        SFOMStripeDirectRefundPayment.InputParameters inputParam = new SFOMStripeDirectRefundPayment.InputParameters();
        inputParam.GatewayRefNumber = 'testGatewayRefNumber';
        inputParam.stripeAPIToken = 'testAPIToken';
        inputParam.amountToRefund = 50.00;
        inputParams.add(inputParam);

        // Mock HTTP response for POST request (refund request)
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"id": "re_1G7df4D4fD8tbDDd", "amount": 5000, "status": "succeeded"}', 'application/json'));

        // Act
        Test.startTest();
        List<SFOMStripeDirectRefundPayment.OutputParameters> outputParams = SFOMStripeDirectRefundPayment.refundPayment(inputParams);
        Test.stopTest();

        // Assert
        System.assert(outputParams != null, 'Output parameters should not be null');
        System.assertEquals(1, outputParams.size(), 'There should be one output parameter');
        System.assertEquals(200, outputParams[0].statusCode, 'Status code should be 200');
        System.assertEquals(50.00, outputParams[0].amountRefunded, 'Amount refunded should match the input amount');
        System.assert(outputParams[0].errorMessage == null, 'Error message should be null');
        System.assert(outputParams[0].responsePayload != null, 'Response payload should not be null');
    }

    @isTest
    static void testRefundPaymentFailure() {
        // Arrange
        List<SFOMStripeDirectRefundPayment.InputParameters> inputParams = new List<SFOMStripeDirectRefundPayment.InputParameters>();

        SFOMStripeDirectRefundPayment.InputParameters inputParam = new SFOMStripeDirectRefundPayment.InputParameters();
        inputParam.GatewayRefNumber = 'testGatewayRefNumber';
        inputParam.stripeAPIToken = 'testAPIToken';
        inputParam.amountToRefund = 50.00;
        inputParams.add(inputParam);

        // Mock HTTP response for POST request with failure status
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, '{"error": {"code": "invalid_request_error", "message": "The refund could not be processed"}}', 'application/json'));

        // Act
        Test.startTest();
        List<SFOMStripeDirectRefundPayment.OutputParameters> outputParams = SFOMStripeDirectRefundPayment.refundPayment(inputParams);
        Test.stopTest();

        // Assert
        System.assert(outputParams != null, 'Output parameters should not be null');
        System.assertEquals(1, outputParams.size(), 'There should be one output parameter');
        System.assertEquals(400, outputParams[0].statusCode, 'Status code should be 400');
        System.assert(outputParams[0].errorMessage != null, 'Error message should not be null');
        System.assertEquals('invalid_request_error : The refund could not be processed', outputParams[0].errorMessage, 'Error message should match the expected value');
    }

    // Mock HTTP response generator
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        private String contentType;

        public MockHttpResponseGenerator(Integer statusCode, String responseBody, String contentType) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
            this.contentType = contentType;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            res.setHeader('Content-Type', contentType);
            return res;
        }
    }
}