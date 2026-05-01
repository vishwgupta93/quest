@isTest
public class HRAEmailAPI_Test {
    @testSetup
    static void prepareTestData(){
        Account ac = new Account();
        ac.Name = 'Test account';
        insert ac;
        
        Contact con = new Contact();
        con.lastName = 'test con';
        con.Email = 'test@gmail.com';
        con.AccountId = ac.Id;
        insert con;
     
        SalesChannel SC = new SalesChannel();	
        SC.SalesChannelName = 'QDCIT Partner';
        SC.Description = 'QDCIT Partner';
        insert SC;
        
        PartnerClientMap__c PCM = new PartnerClientMap__c();
        PCM.Name = 'Google'; 
        PCM.Sales_Channel__c = SC.Id;
        PCM.Partner_Name__c = 'google';
        PCM.Client_ID__c = '34566';
       
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
        lb.Client_Name__c = 'clientName';
        lb.Name = 'clientName';
        lb.Status__c = 'Registered';
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
    
    
    public class SendOrderDetailsToPHMock implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if(req.getEndPoint().contains('events')){
                res.setBody('{"eventInstanceId":"14247b65-8a48-42d1-b584-b39d3cfc8c1a"}');
                res.setStatusCode(201);
            }
            else{
                res.setbody('{"message": "Invalid request body","detail": "[instance type (boolean) does (allowed: [\"string\"])]"}');
                res.setStatusCode(400);
            }
            return res;
        }
    }
    
    
     @isTest
    static void testMethod1(){
        List<Lab_Order_Panel__c> labId =  [Select Id,
                      Lab_Order__r.id,
                      Lab_Order__r.Person_Record__r.Id,
                      Lab_Order__r.Person_Record__r.Email__c,
                      Panel_Code__c, 
                      HRA_Req__c 
                      from Lab_Order_Panel__c where  HRA_Req__c = true Limit 1]; 
     
        Test.startTest();
        // Call the future method
        Test.setMock(HttpCalloutMock.class, new SendOrderDetailsToPHMock());
        HRAEmailAPI.captureOrderDetails(labId[0].Lab_Order__r.id,Label.SFMC_HRA_Email_Trigger_Event , Label.HRAEmailEventDefinitionKey );
        Test.stopTest();
    }
    
}