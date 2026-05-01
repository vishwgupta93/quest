@isTest
public class SFOMStripeDirectCapturePaymentTest {
    @testSetup
    static void setup() {
        // Setup code to create any required test data.
    }

    @isTest
    static void testCapturePaymentSuccess() {
        // Arrange
        List<SFOMStripeDirectCapturePayment.InputParameters> inputParams = new List<SFOMStripeDirectCapturePayment.InputParameters>();

        SFOMStripeDirectCapturePayment.InputParameters inputParam = new SFOMStripeDirectCapturePayment.InputParameters();
        inputParam.GatewayRefNumber = 'testGatewayRefNumber';
        inputParam.stripeAPIToken = 'testAPIToken';
        inputParam.amountToCapture = 100.00;
        inputParam.multiCapture = false;
        inputParams.add(inputParam);

        // Mock HTTP responses
        List<MockHttpResponseGenerator> mockResponses = new List<MockHttpResponseGenerator>{
            new MockHttpResponseGenerator(200, '{"amount_capturable": 15000}', 'application/json'),
            new MockHttpResponseGenerator(200, '{"id": "pi_1Fh5xtD4d8tbDDd", "status": "succeeded"}', 'application/json')
        };
        
        // Set the mock responses
        Test.setMock(HttpCalloutMock.class, new CompositeHttpMockResponseGenerator(mockResponses));

        // Act
        Test.startTest();
        List<SFOMStripeDirectCapturePayment.OutputParameters> outputParams = SFOMStripeDirectCapturePayment.capturePayment(inputParams);
        Test.stopTest();

        // Assert
        System.assert(outputParams != null, 'Output parameters should not be null');
        System.assertEquals(1, outputParams.size(), 'There should be one output parameter');
        System.assertEquals(200, outputParams[0].statusCode, 'Status code should be 200');
        System.assertEquals(100.00, outputParams[0].amountCaptured, 'Amount captured should match the input amount');
        System.assert(outputParams[0].errorMessage == null, 'Error message should be null');
        System.assert(outputParams[0].responsePayload != null, 'Response payload should not be null');
    }

    @isTest
    static void testCapturePaymentFailure() {
        // Arrange
        List<SFOMStripeDirectCapturePayment.InputParameters> inputParams = new List<SFOMStripeDirectCapturePayment.InputParameters>();

        SFOMStripeDirectCapturePayment.InputParameters inputParam = new SFOMStripeDirectCapturePayment.InputParameters();
        inputParam.GatewayRefNumber = 'testGatewayRefNumber';
        inputParam.stripeAPIToken = 'testAPIToken';
        inputParam.amountToCapture = 100.00;
        inputParam.multiCapture = false;
        inputParams.add(inputParam);

        // Mock HTTP responses
        List<MockHttpResponseGenerator> mockResponses = new List<MockHttpResponseGenerator>{
            new MockHttpResponseGenerator(200, '{"amount_capturable": 15000}', 'application/json'),
            new MockHttpResponseGenerator(400, '{"error": {"code": "payment_intent_authentication_failure", "message": "The payment intent could not be authenticated"}}', 'application/json')
        };
        
        // Set the mock responses
        Test.setMock(HttpCalloutMock.class, new CompositeHttpMockResponseGenerator(mockResponses));

        // Act
        Test.startTest();
        List<SFOMStripeDirectCapturePayment.OutputParameters> outputParams = SFOMStripeDirectCapturePayment.capturePayment(inputParams);
        Test.stopTest();

        // Assert
        System.assert(outputParams != null, 'Output parameters should not be null');
        System.assertEquals(1, outputParams.size(), 'There should be one output parameter');
        System.assertEquals(400, outputParams[0].statusCode, 'Status code should be 400');
        System.assert(outputParams[0].errorMessage != null, 'Error message should not be null');
        System.assertEquals('payment_intent_authentication_failure : The payment intent could not be authenticated', outputParams[0].errorMessage, 'Error message should match the expected value');
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

    // Composite HTTP mock response generator to handle multiple mock responses
    private class CompositeHttpMockResponseGenerator implements HttpCalloutMock {
        private List<MockHttpResponseGenerator> mockResponses;
        private Integer currentIndex = 0;

        public CompositeHttpMockResponseGenerator(List<MockHttpResponseGenerator> mockResponses) {
            this.mockResponses = mockResponses;
        }

        public HttpResponse respond(HTTPRequest req) {
            if (currentIndex < mockResponses.size()) {
                return mockResponses[currentIndex++].respond(req);
            } else {
                throw new System.CalloutException('No more mock responses available');
            }
        }
    }
}