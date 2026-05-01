/**
* @File Name : UpdateDoctorDetailsInGeneticsPortalTest.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : March 17, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 17, 2025 |   | Initial Version
**/
@IsTest
public class UpdateDoctorDetailsInGeneticsPortalTest {
	@IsTest
	public static void testSendDDToPWN_Success(){
        
        Kit_Details__c kit = new Kit_Details__c();
        Kit_Details__c kitDetail = new Kit_Details__c();
        kitDetail.Activation_Code__c='KITREF1234';
        kitDetail.Item_Code__c='334';
        kitDetail.ActivationUser_PRS_ID__c = '123456';
        kitDetail.Lab_Status__c = 'Kit Activated';
        kitDetail.Status__c = 'Activated';
        kitDetail.Type__c = 'GSS';
        kitDetail.Item_Code__c = '11757';
        kitDetail.Purchaser_PRS_ID__c = 'TST12121212';
        kitDetail.Lot_Number__c = 'TST12121212';
        kitDetail.ActivationUser_Customer_Id__c = 'TST12121212';
        insert kitDetail;
        
        Person_Record__c person = new Person_Record__c();
        person.First_Name__c = 'John';
        person.Last_Name__c = 'Doe';
        person.Email__c = 'john.doe@example.com';
        person.Address_Line_1__c = '123 Main St';
        person.Unique_Identifier__c ='Uniqu1';
        person.City__c = 'Anytown';
        person.Country__c = 'USA';
        person.State__c = 'CA';
        person.Postal_Code__c = '12345';
        person.Phone__c = '1234567890';
        person.Gender__c = 'Male';
        person.Date_of_Birth__c = Date.newInstance(1990, 1, 1);
        insert person;
        
        Lab_Order__c labOrder1 = new Lab_Order__c();
        labOrder1.Is_Partner__c=true;
        labOrder1.Client_Id__c = '12345';
        labOrder1.Person_Record__c = person.Id;
        labOrder1.Name='TETS81892-12781';
        labOrder1.PWN_ID__C='PWN123';
        labOrder1.Status__c='PA Acknowledged';
        labOrder1.PWN_Success__c=true;
        labOrder1.Physician_First_Name__c='asasd';
        labOrder1.Physician_Last_Name__c='bcvm';
        labOrder1.Physician_Npi__c='122121';
        labOrder1.Physician_Upin__c='12121';
        labOrder1.CreatedAt__c = '2025-03-14T20:08:36Z';
        labOrder1.UpdatedAt__c = '2025-03-14T20:08:36Z';
        labOrder1.ExpiresAt__c = '2026-03-14T20:08:36Z';
        insert labOrder1;
        
		        
       
        
        
        UpdateDoctorDetailsInGeneticsPortal.InputPrameters flowInputs = new UpdateDoctorDetailsInGeneticsPortal.InputPrameters();
        flowInputs.labOrderRecordId = labOrder1.id ;
        flowInputs.token = '123adds';
        System.Test.setMock(HttpCalloutMock.class, new MockDDInGPPttpResponse(200,'{"orderId" : "6879806","orderStatus" : "pending_genetic_review","createdAt" : "2025-03-14T20:08:36Z","updatedAt" : "2025-03-14T20:08:36Z","expiresAt" : "2026-03-14T20:08:36Z","physicianReview" : {"name" : "JohnDOE","first_name" : "John","last_name" : "DOE","upin" : "","npi" : "1528709359"}}'));

        List<UpdateDoctorDetailsInGeneticsPortal.InputPrameters> flowInputsForTest = new List<UpdateDoctorDetailsInGeneticsPortal.InputPrameters>();
        flowInputsForTest.add(flowInputs);
        Test.startTest();
       
         UpdateDoctorDetailsInGeneticsPortal.sendDoctorDetails(flowInputsForTest);
        
        Test.stopTest();
	}
    @IsTest
    public static void testSendDDToPWN_Error(){
        
        Kit_Details__c kit = new Kit_Details__c();
        Kit_Details__c kitDetail = new Kit_Details__c();
        kitDetail.Activation_Code__c='KITREF1234';
        kitDetail.Item_Code__c='334';
        kitDetail.ActivationUser_PRS_ID__c = '123456';
        kitDetail.Lab_Status__c = 'Kit Activated';
        kitDetail.Status__c = 'Activated';
        kitDetail.Type__c = 'GSS';
        kitDetail.Item_Code__c = '11757';
        kitDetail.Purchaser_PRS_ID__c = 'TST12121212';
        kitDetail.Lot_Number__c = 'TST12121212';
        kitDetail.ActivationUser_Customer_Id__c = 'TST12121212';
        insert kitDetail;
        
        Person_Record__c person = new Person_Record__c();
        person.First_Name__c = 'John';
        person.Last_Name__c = 'Doe';
        person.Email__c = 'john.doe@example.com';
        person.Address_Line_1__c = '123 Main St';
        person.Unique_Identifier__c ='Uniqu1';
        person.City__c = 'Anytown';
        person.Country__c = 'USA';
        person.State__c = 'CA';
        person.Postal_Code__c = '12345';
        person.Phone__c = '1234567890';
        person.Gender__c = 'Male';
        person.Date_of_Birth__c = Date.newInstance(1990, 1, 1);
        insert person;
        
        Lab_Order__c labOrder1 = new Lab_Order__c();
        labOrder1.Is_Partner__c=true;
        labOrder1.Client_Id__c = '12345';
        labOrder1.Person_Record__c = person.Id;
        labOrder1.Name='TETS81892-12781';
        labOrder1.PWN_ID__C='PWN123';
        labOrder1.Status__c='PA Acknowledged';
        labOrder1.PWN_Success__c=true;
        labOrder1.Physician_First_Name__c='asasd';
        labOrder1.Physician_Last_Name__c='bcvm';
        labOrder1.Physician_Npi__c='122121';
        labOrder1.Physician_Upin__c='12121';
        labOrder1.CreatedAt__c = '2025-03-14T20:08:36Z';
        labOrder1.UpdatedAt__c = '2025-03-14T20:08:36Z';
        labOrder1.ExpiresAt__c = '2026-03-14T20:08:36Z';
        insert labOrder1;
        
		        
       
        
        
        UpdateDoctorDetailsInGeneticsPortal.InputPrameters flowInputs = new UpdateDoctorDetailsInGeneticsPortal.InputPrameters();
        flowInputs.labOrderRecordId = labOrder1.id ;
        flowInputs.token = '123adds';
        System.Test.setMock(HttpCalloutMock.class, new MockDDInGPPttpResponse(400,'{"orderId" : "6879806","orderStatus" : "pending_genetic_review","createdAt" : "2025-03-14T20:08:36Z","updatedAt" : "2025-03-14T20:08:36Z","expiresAt" : "2026-03-14T20:08:36Z","physicianReview" : {"name" : "JohnDOE","first_name" : "John","last_name" : "DOE","upin" : "","npi" : "1528709359"}}'));

        List<UpdateDoctorDetailsInGeneticsPortal.InputPrameters> flowInputsForTest = new List<UpdateDoctorDetailsInGeneticsPortal.InputPrameters>();
        flowInputsForTest.add(flowInputs);
        Test.startTest();
       
         UpdateDoctorDetailsInGeneticsPortal.sendDoctorDetails(flowInputsForTest);
        
        Test.stopTest();
	}
    
    private class MockDDInGPPttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public MockDDInGPPttpResponse(Integer statusCode, String responseBody) {
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