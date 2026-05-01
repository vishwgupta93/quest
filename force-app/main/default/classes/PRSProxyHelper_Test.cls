/**
* @File Name : PRSProxyHelper_Test.cls
* @Author : Singam reddy Ramana reddy
* @Last Modified On : March 8, 2025
**/

@isTest
public class PRSProxyHelper_Test {
    
    @isTest
    static void testPRSProxyHelper_Success(){
        
        System.Test.setMock(HttpCalloutMock.class, new MockPRSProxyHelperHttpResponse(200, '{"patientId":{"empiPatientId":"1237866515"},"patientProfile":{"lastName":"cit","gender":"F","dateOfBirth":"1985-08-05","demographicAuthInd":"Y","firstName":"arthi","profileType":"P","activeInd":"Y", "contacts": [{"activeInd": "Y","contactType": "PHONE","contactAttrValue":"123456"}],"addresses":[{"country":"US","zipPostal":"08820","city":"edison","stateProvince":"NJ","addressLine1":"671 hall ave" }]}}'
                ));
        
        Kit_Details__c kit = new Kit_Details__c(Activation_Code__c='KITREF1234', Item_Code__c='334', ActivationUser_PRS_ID__c = '123456', Lab_Status__c = 'Kit Activated');
        insert kit;
        List<Kit_Details__c> ordItem = [select id, Activation_Code__c, ActivationUser_PRS_ID__c, Lab_Status__c from Kit_Details__c  where id = :kit.id AND ActivationUser_PRS_ID__c != null AND Activation_Code__c != null AND Lab_Status__c = 'Kit Activated'];
        
        PRSProxyHelper.InputPrameters flowInputs = new PRSProxyHelper.InputPrameters();
        flowInputs.kitLabId = ordItem[0].Id  ;
        List<PRSProxyHelper.InputPrameters> flowInputsForTest = new List<PRSProxyHelper.InputPrameters>();
        
        flowInputsForTest.add(flowInputs);
        Test.startTest();
        // System.Test.setMock(HttpCalloutMock.class, new MockPRSProxyHelperHttpResponse(200,));
        PRSProxyHelper.fetchPRSDetails(flowInputsForTest);
        
        Test.stopTest();
    }
    
    
    @isTest
    static void testPRSProxyHelper_Error(){
        System.Test.setMock(HttpCalloutMock.class, new MockPRSProxyHelperHttpResponse(400, '{"error":{"fault":{"type":"NOT_FOUND","message": ["The specified Patient Profile was not found."]}}}'));
        
        Kit_Details__c kit = new Kit_Details__c(Activation_Code__c='KITREF1234', Item_Code__c='334', ActivationUser_PRS_ID__c = '123456', Lab_Status__c = 'Kit Activated');
        insert kit;
        List<Kit_Details__c> ordItem = [select id, Activation_Code__c, ActivationUser_PRS_ID__c, Lab_Status__c from Kit_Details__c  where id = :kit.id AND ActivationUser_PRS_ID__c != null AND Activation_Code__c != null AND Lab_Status__c = 'Kit Activated'];
        PRSProxyHelper.InputPrameters flowInputs = new PRSProxyHelper.InputPrameters();
        flowInputs.kitLabId = ordItem[0].Id  ;
        List<PRSProxyHelper.InputPrameters> flowInputsForTest = new List<PRSProxyHelper.InputPrameters>();
        flowInputsForTest.add(flowInputs);
        Test.startTest();
        //  System.Test.setMock(HttpCalloutMock.class, new SendOrderDetailsToPHMock1());
        PRSProxyHelper.fetchPRSDetails(flowInputsForTest);
        
        Test.stopTest();
    }
    
    
    
    private class MockPRSProxyHelperHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public MockPRSProxyHelperHttpResponse(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
    
    
    
}