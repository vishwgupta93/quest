@isTest
private class PublishAppointmentConfirmationTest {

    // Mock for a successful HTTP response
    public class SuccessMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message": "Success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    // Mock for an error HTTP response
    public class ErrorMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error": {"fault": {"message": ["Invalid Request", "Missing Data"]}}}');
            res.setStatusCode(500);
            return res;
        }
    }

    private static Id setupTestData() {
        // Create Partner_Client_Map__c
        PartnerClientMap__c clientMap = new PartnerClientMap__c(Name = 'Test Map', Client_ID__c = 'CL123');
        insert clientMap;

         Person_Record__c  pr = new Person_Record__c ();
        pr.First_Name__c = 'test';
        pr.Date_of_Birth__c = Date.valueOf('1994-09-30');
        pr.Gender__c = 'Male';
        pr.Address_Line_1__c = '2005 Lamberts Branch Road'; 
        pr.City__c = 'Taloga';
        pr.Email__c = 'srini491.03@yopmail.com';
        pr.Last_Name__c = 'TestLastName';
        pr.Phone__c = '7389768765';
        pr.Postal_Code__c = '73667';
        pr.State__c = 'Oklahoma';
        pr.Unique_Identifier__c = 'srini491.03@yopmail.com:1994-09-30:test';
        insert pr;
        

        Product2 product = new Product2();
            product.Name = 'Test';
            product.Description = 'Test';
            product.ProductCode = 'test';
            product.StockKeepingUnit = 'Test'+ String.valueOf(1);
            product.DisplayUrl = '';
             product.ExternalId = 'sku123';
            product.IsActive = true;
            insert product;

        Panel__c panel =  new Panel__c(Product__c=product.Id);
        insert panel;

        Test__c test =  new Test__c(Test_Code__c='test',Test_Name__c='test',Description__c='test');
        insert test;

        Panel_Test__c panelTest= new Panel_Test__c(Panel__c=panel.Id,Test__c=test.Id);
        insert panelTest;

        // Insert required records
        Lab_Order__c labOrder = new Lab_Order__c(
           Is_Partner__c=true,
           Partner_Client_Map__c=clientMap.Id,           
            Client_Id__c = '12345',Person_Record__c = pr.id
        );
        insert labOrder;

         Lab_Order_Panel__c labOrderPanel = new Lab_Order_Panel__c(Lab_Order__c = labOrder.Id, Panel__c = panel.Id);
        insert labOrderPanel;

         Lab_Panel_Test__c labPanelTest = new Lab_Panel_Test__c(Lab_Order_Panel__c = labOrderPanel.Id, Panel_Test__c=panelTest.Id);
        insert labPanelTest;

        return labOrder.Id;
    }

    @isTest
    static void testSuccessResponse() {
        Test.setMock(HttpCalloutMock.class, new SuccessMockResponse());
        Id labOrderId = setupTestData();

        PublishAppointmentConfirmation.Request req = new PublishAppointmentConfirmation.Request();
        req.labOrderId = labOrderId;

        Test.startTest();
        List<PublishAppointmentConfirmation.Response> result = PublishAppointmentConfirmation.sendRequest(new List<PublishAppointmentConfirmation.Request>{req});
        Test.stopTest();

        // System.assertEquals(1, result.size());
        // System.assertEquals('Success', result[0].status);
        // System.assertEquals('200', result[0].responseCode);
        // System.assertEquals('Success', result[0].responseMessage);
        // System.assertNotEquals(null, result[0].requestPayload);
        // System.assertNotEquals(null, result[0].responsePayload);
    }

    @isTest
    static void testErrorResponse() {
        Test.setMock(HttpCalloutMock.class, new ErrorMockResponse());
        Id labOrderId = setupTestData();

        PublishAppointmentConfirmation.Request req = new PublishAppointmentConfirmation.Request();
        req.labOrderId = labOrderId;

        Test.startTest();
        List<PublishAppointmentConfirmation.Response> result = PublishAppointmentConfirmation.sendRequest(new List<PublishAppointmentConfirmation.Request>{req});
        Test.stopTest();

        // System.assertEquals(1, result.size());
        // System.assertEquals('Error', result[0].status);
        // System.assertEquals('500', result[0].responseCode);
        // System.assert(result[0].responseMessage.contains('Invalid Request'));
    }
}