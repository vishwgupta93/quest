@isTest
public class EOSTAWSStatusHelperTest {
    @testSetup
    public static void testSetupMethod(){
        SFMC_OMS_Config__c config = new SFMC_OMS_Config__c();
        config.Channel__c = 'QD-CIT';
        config.API__c = 'Common';
        config.Auth_Token__c = 'TestAuthToken';
        insert config;
        
        // Create mock Lab_Order__c and Lab_Panel_Test__c records
        Account ac = new Account();
        ac.Name = 'Test account';
        insert ac;
        
        Contact con = new Contact();
        con.lastName = 'test con';
        con.Email = 'test@gmail.com';
        con.AccountId = ac.Id;
        con.Phone = '234-234-2342' ;
        insert con;
        
        SalesChannel SC = new SalesChannel();	
        SC.SalesChannelName = 'QDCIT Partner';
        SC.Description = 'QDCIT Partner';
        insert SC;
        
        PartnerClientMap__c PCM = new PartnerClientMap__c();
        PCM.Name = 'Google'; 
        PCM.Sales_Channel__c = SC.Id;
        PCM.Partner_Name__c = 'Google';
        PCM.Client_ID__c = '34566';
        PCM.Suppress_Reminder_Email__c = false;
        insert PCM;
        
        
        Panel__c p = new Panel__c();
        p.Panel_Code__c = '12767';
        p.Panel_Name__c = 'test panel';
        insert p;
        
        Test__c t = new Test__c();
        t.Test_Code__c = '12767';
        t.Test_Name__c = 'demo test';
        insert t;
        
        
        Person_Record__c pr = new Person_Record__c();
        pr.Email__c= 'test@gmail.com';
        pr.First_Name__c= 'Fname';
        pr.Last_Name__c= 'LName';
        pr.Phone__c= '4569990422';
        pr.Gender__c = 'Male';
        pr.Contact__c = con.Id;
        pr.Date_of_Birth__c=  date.valueOf('2000-12-12');
        pr.Address_Line_1__c= 'gfds';
        pr.City__c= 'Santa Barbara';
        pr.State__c= 'CA';
        pr.Postal_Code__c= '93110';
        pr.Country__c = 'US';
        pr.Unique_Identifier__c = 'test@gmail.com'+':'+'2000-12-12'+':'+'LName';
        insert pr;
        
        Lab_order__c lb = new Lab_Order__c();
        lb.Person_Record__c = pr.id;
        lb.Partner_Client_Map__c = PCM.id;
        lb.Client_Name__c = 'saturn';
        lb.Name = 'clientName';
        lb.Status__c = 'Registered';
        lb.Is_Partner__c = true;
        lb.External_Partner_Order_Id__c = '123';
        lb.shl_encryption_key__c = 'shl_encryption';
        lb.shl_location__c = 'shl_location';
        insert lb;
        
        Panel_Test__c pt = new Panel_Test__c();
        pt.Panel__c = p.id;
        pt.Test__c = t.Id;
        insert pt;
        
        Lab_Order_Panel__c LOP = new Lab_Order_Panel__c();
        LOP.HRA_Req__c = true;
        LOP.Lab_Order__c = lb.id;
        LOP.Panel__c = p.id;
        insert LOP;
        
        Lab_Panel_Test__c lbt = new Lab_Panel_Test__c();
        lbt.Lab_Order_Panel__c = LOP.id;
        lbt.Status__c = 'Registered';
        lbt.Panel_Test__c = pt.id;
        insert lbt;
    }
  
    
    @IsTest 
    public static void LabOrderAppointmentRemainderScheduleTestPayload () {
         Lab_Order__c labOrder = [Select Id, 
                                  Name,
                                  Client_Name__c, 
                                  Status__c,
                                  shl_location__c,
                                  shl_encryption_key__c,
                                  External_Partner_Order_Id__c, 
                                  Partner_Client_Map__r.Named_credential_Name__c 
                                  FROM Lab_order__c Limit 1];
        AWSStatusNotification ASN = new AWSStatusNotification();
        ASN.status = 'Results Ready';
        ASN.merchantOrderId = '';
        ASN.shlKey = 'ahcHSlXsyNrqEJ';
        ASN.shlLocation = 'cfgvbhjkmnbvghjk';
        ASN.namedCredential = 'NamedCredential';
        ASN.labOrderNumber = 'LO-12345';
        ASN.clientName = 'Saturn';
       
        
        System.Test.setMock(HttpCalloutMock.class, new MockPRSProxyHelperHttpResponse(200,'{"order":{"merchant_order_id" : "123","partner_id" : "saturn","lab_order_number" : "clientName","status" : "order_confirmed","shl_key" : "shl_encryption","shl_location" : "shl_location"}}'));
       
        EOSTAWSStatusHelper.InputParameters flowInputs = new EOSTAWSStatusHelper.InputParameters();
        flowInputs.notification =ASN;
        List<EOSTAWSStatusHelper.InputParameters> flowInputsForTest = new List<EOSTAWSStatusHelper.InputParameters>();
        flowInputsForTest.add(flowInputs);
        Test.startTest();
        //  System.Test.setMock(HttpCalloutMock.class, new SendOrderDetailsToPHMock1());
        EOSTAWSStatusHelper.postStatusToAWS(flowInputsForTest);
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