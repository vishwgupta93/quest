@IsTest
public class LabOrderResultsIIUtilTest {

public class MockHttpResponseGenerator implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        if (req.getEndpoint().contains(Label.OMS_Pingfed_URL)) {
            // Mocking token response
            res.setStatusCode(200);
            res.setBody('{"access_token": "mocked_token"}');
        } else if (req.getEndpoint().contains(Label.OMS_Mule_Proxy_Ednpoint)) {
            // Mocking data response
            res.setStatusCode(200);
            if (req.getEndpoint().contains('&format=pdf')) {
                // Mock PDF response as Blob if PDF format is requested
                Blob pdfBlob = Blob.valueOf('Mock PDF Data');
                res.setBodyAsBlob(pdfBlob);
            } else {
                // Mock base64 encoded string if not PDF
                res.setBody('"Mocked_Base64Encoded_String"');
            }
        } else {
            res.setStatusCode(404);
            res.setBody('{"error": "Endpoint not found"}');
        }
        return res;
    }
}


    @IsTest
    static void testFetchResultsWithPdfFormat() {
        // Set up test data
        Lab_Order__c labOrder = new Lab_Order__c(
            Client_Id__c = '12345',
            Accession_ID__c = 'ABC123',
            Date_Reported__c = Date.today(),
            PerformingSite__c = 'SiteA'
        );
        insert labOrder;

        // Set up the mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Call the method with PDF format
        Test.startTest();
        Object result = LabOrderResultsInteractiveInsightsUtil.fetchResults(labOrder.Id, true);
        Test.stopTest();

        // Verify the results
        System.assert(result instanceof Blob, 'Expected Blob for PDF format');
        System.assertEquals('Mock PDF Data', ((Blob)result).toString());
    }

    @IsTest
    static void testFetchResultsWithBase64Format() {
        // Set up test data
        Lab_Order__c labOrder = new Lab_Order__c(
            Client_Id__c = '12345',
            Accession_ID__c = 'ABC123',
            Date_Reported__c = Date.today(),
            PerformingSite__c = 'SiteA'
        );
        insert labOrder;

        // Set up the mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Call the method without PDF format
        Test.startTest();
        Object result = LabOrderResultsInteractiveInsightsUtil.fetchResults(labOrder.Id, false);
        Test.stopTest();

        // Verify the results
        System.assert(result instanceof String, 'Expected String for base64 format');
        System.assertEquals('Mocked_Base64Encoded_String', (String)result);
    }
}