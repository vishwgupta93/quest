@isTest
public with sharing class LabOrderAppointmentEmailOutboundTest {
    public static Map<String,SObject> m_mapTestData = null;

         // Inner class to mock HTTP response
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setBody('Mock response body');
            return res;
        }
    }

    public class MockHttpResponseGeneratorError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('Mock response body');
            return res;
        }
    }
    
   @IsTest 
       public static void LabOrderAppointmentRemainderScheduleTestPayload () {
        
         
       
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();

        SFMC_OMS_Config__c config = new SFMC_OMS_Config__c(
        Channel__c = 'QD-CIT',
        API__c = 'Common',
        Auth_Token__c = 'TestAuthToken'
    );
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
        lb.Client_Name__c = 'Google';
        lb.Name = 'clientName';
        lb.Status__c = 'PA Approved';
        lb.PWN_Status_Date__c = date.parse('4/17/2024');
        lb.Is_Partner__c = true;  
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
            
        LabOrderAppointmentEmailOutbound btch= new LabOrderAppointmentEmailOutbound();
        List<String> statusList = new List<String>{'PA Acknowledged','PA Approved'};
        btch.statusList = statusList;
        btch.Id=lb.Id;
        btch.query = 'SELECT Id, CreatedDate,Name,Order_Summary__c,Order_Summary__r.OrderNumber,Order_Summary__r.GrandTotalAmount,Person_Record__r.Id,Person_Record__r.Email__c,Expiration_Date__c,Days_Past_Confirm__c,Order_Summary__r.Id,Is_Partner__c,Partner_Client_Map__r.Suppress_Reminder_Email__c FROM Lab_Order__c WHERE  Id=:Id ';
        Database.executeBatch(btch,1);

        LabOrderExpiryEmailOutbound btch1= new LabOrderExpiryEmailOutbound();
        btch1.Id=lb.Id;
        btch1.query = 'SELECT Id, CreatedDate,Name,Order_Summary__c,Order_Summary__r.OrderNumber,Order_Summary__r.GrandTotalAmount,Person_Record__r.Id,Person_Record__r.Email__c,Expiration_Date__c,Days_to_expire__c,Order_Summary__r.Id,Is_Partner__c,Partner_Client_Map__r.Suppress_Reminder_Email__c FROM Lab_Order__c WHERE  Id=:Id ';
        Database.executeBatch(btch1,1);
           
           LabOrderExpiryEmailOutbound btch2= new LabOrderExpiryEmailOutbound();
        btch2.Id=lb.Id;
        btch2.query = 'SELECT Id, CreatedDate,Name,Order_Summary__c,Order_Summary__r.OrderNumber,Order_Summary__r.GrandTotalAmount,Person_Record__r.Id,Person_Record__r.Email__c,Expiration_Date__c,Days_to_expire__c,Order_Summary__r.Id,Is_Partner__c,Partner_Client_Map__r.Suppress_Reminder_Email__c   FROM Lab_Order__c WHERE  Id=:Id ';
        Database.executeBatch(btch2,1);

        Test.stopTest();
            
        
    }
    
    @IsTest 
    static void LabOrderAppointmentRemainderScheduleTerritoryTest () {
        LabOrderAppointmentRemainderSchedule  obj = new LabOrderAppointmentRemainderSchedule();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, obj); 
  }   

  @IsTest 
    static void LabOrderExpiryScheduleTerritoryTest () {
        LabOrderExpiryEmailSchedule  obj = new LabOrderExpiryEmailSchedule();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, obj); 
  }   
}