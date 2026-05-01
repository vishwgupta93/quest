@IsTest
public class LaborderResultPageCtrlTest {
    @isTest static void getPDFTest(){
        PageReference pageRef = Page.LaborderResultPage;
        Test.setCurrentPage(pageRef);
        Lab_Order__c labOrder = new Lab_Order__c(
            Name = 'Test Lab Order',
            Client_Id__c='91801320',
            Accession_ID__c='Asaskhk',Date_Reported__c=Date.newInstance(2024, 8, 15),PerformingSite__c='PHP'
        );
        insert labOrder;
        Lab_Order__c labOrder1 = [select Id from Lab_Order__c WHERE Id =:labOrder.Id ];
        ApexPages.currentPage().getparameters().put('loid', labOrder1.Id);                    
        LaborderResultPageCtrl myController = new LaborderResultPageCtrl();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        myController.getPDF();
        Test.stopTest();
        // System.assertNotEquals(null, myController.pdfdata);
        // System.assertEquals('<html></html>', myController.pdfdata);
    }
    // Inner class to mock HTTP response
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            if(req.getEndPoint().contains('token')){
            	res.setBody('{"access_token": "121212121"}');
            }else{
                res.setBody(EncodingUtil.base64Encode(Blob.valueOf('<html></html>')));
            }
            return res;
        }
    }
}