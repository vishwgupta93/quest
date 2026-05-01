@isTest

public class PartnerLabOrderRefundTest {

    private static Id testSetupMethod(){
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
        pcm.Payment_Key__c='hhgasskkhkj';
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
         lb.Payment_Transaction_Id__c = 'dasdasdasdasdasd';
          lb.Cancellation_Service_Fee__c = 10.00;
          lb.Refund_Amount__c=80.00;
          lb.Refund_Attempts__c=1;
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

        return lb.id;
    }

    @IsTest 
    public static void PartnerLabOrderRefundTest3 () {
          
        System.Test.setMock(HttpCalloutMock.class, new MockPRSProxyHelperHttpResponse(200,'{"amount_received":100.00}'));
       
       Id labOrderId = testSetupMethod();
        PartnerLabOrderRefund.Request PLR = new PartnerLabOrderRefund.Request();
        PLR.paymentIntentId = 'shsnkidvekdbdk283463';
        PLR.fullRefund = true;
        PLR.labOrderId = labOrderId;
        PLR.paymentKey = 'sdfghjkjhgfdrtyujk';
        PLR.cancellationFee = 10.00;
	    Test.startTest();
		List<PartnerLabOrderRefund.Request> lstPLR = new List<PartnerLabOrderRefund.Request>();
        lstPLR.add(PLR);
        PartnerLabOrderRefund.refundPartnerOrder(lstPLR);
        Test.stopTest();
    }
    
    @IsTest 
    public static void PartnerLabOrderRefundTest1 () {
          
        System.Test.setMock(HttpCalloutMock.class, new MockPRSProxyHelperHttpResponse(200,'{"amount_received":100.00}'));
       
        Id labOrderId = testSetupMethod();
        PartnerLabOrderRefund.Request PLR = new PartnerLabOrderRefund.Request();
        PLR.paymentIntentId = 'shsnkidvekdbdk283463';
        PLR.fullRefund = true;
        PLR.labOrderId = labOrderId;
        PLR.paymentKey = 'sdfghjkjhgfdrtyujk';
        PLR.cancellationFee = 10.00;
	    Test.startTest();
		List<PartnerLabOrderRefund.Request> lstPLR = new List<PartnerLabOrderRefund.Request>();
        lstPLR.add(PLR);
        PartnerLabOrderRefund.refundPartnerOrder(lstPLR);
        Test.stopTest();
    }
    
     @IsTest 
    public static void PartnerLabOrderRefundTest2 () {
          
        System.Test.setMock(HttpCalloutMock.class, new MockPRSProxyHelperHttpResponse(400,'{"amount_received":100.00}'));
       
         Id labOrderId = testSetupMethod();
        PartnerLabOrderRefund.Request PLR = new PartnerLabOrderRefund.Request();
        PLR.paymentIntentId = 'shsnkidvekdbdk283463';
        PLR.fullRefund = true;
        PLR.labOrderId = labOrderId;
        PLR.paymentKey = 'sdfghjkjhgfdrtyujk';
        PLR.cancellationFee = 10.00;
	    Test.startTest();
		List<PartnerLabOrderRefund.Request> lstPLR = new List<PartnerLabOrderRefund.Request>();
        lstPLR.add(PLR);
        PartnerLabOrderRefund.refundPartnerOrder(lstPLR);
        Test.stopTest();
    }
    
    @IsTest 
    public static void PartnerLabOrderRefundTest5 () {
           System.Test.setMock(HttpCalloutMock.class, new SendOrderDetailsToPHMock1());
       
       
         Id labOrderId = testSetupMethod();
        PartnerLabOrderRefund.Request PLR = new PartnerLabOrderRefund.Request();
        PLR.paymentIntentId = 'shsnkidvekdbdk283463';
        PLR.fullRefund = true;
        PLR.labOrderId = labOrderId;
        PLR.paymentKey = 'sdfghjkjhgfdrtyujk';
        PLR.cancellationFee = 10.00;
	    Test.startTest();
		List<PartnerLabOrderRefund.Request> lstPLR = new List<PartnerLabOrderRefund.Request>();
        lstPLR.add(PLR);
        PartnerLabOrderRefund.refundPartnerOrder(lstPLR);
        Test.stopTest();
    }

    @IsTest 
    public static void PartnerLabOrderRefundTest6 () {
           System.Test.setMock(HttpCalloutMock.class, new SendOrderDetailsToPHMock1());
       
       
         Id labOrderId = testSetupMethod();
       
	    Test.startTest();
		PartnerLabOrderRefundRetryBatch btch= new PartnerLabOrderRefundRetryBatch();
        btch.labOrderId= labOrderId;
        btch.query = 'SELECT Id, Payment_Transaction_Id__c,Captured_Amount__c,Cancellation_Service_Fee__c,Refund_Amount__c,Refund_Attempts__c,Partner_Client_Map__r.Payment_Key__c FROM Lab_Order__c WHERE Id =:labOrderId';
        Database.executeBatch(btch,1);
        Test.stopTest();
    }

     @IsTest 
    public static void PartnerLabOrderRefundTest7 () {
           System.Test.setMock(HttpCalloutMock.class, new SendOrderDetailsToPHMock());
       
       
         Id labOrderId = testSetupMethod();
       
	    Test.startTest();
		PartnerLabOrderRefundRetryBatch btch= new PartnerLabOrderRefundRetryBatch();
        btch.labOrderId= labOrderId;
        btch.query = 'SELECT Id, Payment_Transaction_Id__c,Captured_Amount__c,Cancellation_Service_Fee__c,Refund_Amount__c,Refund_Attempts__c,Partner_Client_Map__r.Payment_Key__c FROM Lab_Order__c WHERE Id =:labOrderId';
        Database.executeBatch(btch,1);
        Test.stopTest();
    }
    
    @IsTest 
    public static void PartnerLabOrderRefundTest4 () {
           System.Test.setMock(HttpCalloutMock.class, new SendOrderDetailsToPHMock());
       
       
       Id labOrderId = testSetupMethod();
        PartnerLabOrderRefund.Request PLR = new PartnerLabOrderRefund.Request();
        PLR.paymentIntentId = 'shsnkidvekdbdk283463';
        PLR.fullRefund = true;
        PLR.labOrderId = labOrderId;
        PLR.paymentKey = 'sdfghjkjhgfdrtyujk';
        PLR.cancellationFee = 10.00;
	    Test.startTest();
		List<PartnerLabOrderRefund.Request> lstPLR = new List<PartnerLabOrderRefund.Request>();
        lstPLR.add(PLR);
        PartnerLabOrderRefund.refundPartnerOrder(lstPLR);
        Test.stopTest();
    }

     @IsTest 
    static void ScheduleClassTerritoryCheck () {
        PartnerLabOrderRefundRetryBatchSchedule  obj = new PartnerLabOrderRefundRetryBatchSchedule();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, obj); 
  }   
    
     public class SendOrderDetailsToPHMock implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req1){
            HttpResponse res1 = new HttpResponse();
            res1.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            if(req1.getEndPoint().contains('refunds')){
                res1.setBody('{"amount_received":10000.00}');
                res1.setStatusCode(400);
            }
            else{
                res1.setbody('{"amount_received":10000.00}');
                res1.setStatusCode(200);
            }
            return res1;
        }
    }
    
    public class SendOrderDetailsToPHMock1 implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req1){
            HttpResponse res1 = new HttpResponse();
            res1.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            if(req1.getEndPoint().contains('refunds')){
                res1.setBody('{"amount_received":10000.00}');
                res1.setStatusCode(200);
            }
            else{
                res1.setbody('{"amount_received":10000.00}');
                res1.setStatusCode(200);
            }
            return res1;
        }
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