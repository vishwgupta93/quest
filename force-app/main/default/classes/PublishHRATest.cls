@isTest
public class PublishHRATest {
    @isTest
    static void testPublishHRAQuestionnaireSuccess() {
        // Create mock Lab_Order__c and Lab_Panel_Test__c records
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

        // Prepare input data with QuestionResponse objects
        PublishHRA.PublishHRAInput input = new PublishHRA.PublishHRAInput();
        input.token = 'mockToken';
        input.referenceId = lb.Id;
        input.requisitionNumber = 'REQ12345';
        input.type = 'LO';
        input.responses = new List<QuestionResponse>{
            new QuestionResponse('Q1', 'Answer1', 'Tag1', 'Type1', true),
            new QuestionResponse('Q2', 'Answer2', 'Tag2', 'Type2', false)
        };

        List<PublishHRA.PublishHRAInput> inputs = new List<PublishHRA.PublishHRAInput>{ input };

        // Mock HTTP response
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setHeader('Content-Type', 'application/json');
        mockResponse.setBody('{"responseCode":"200", "responseMessage":"Success"}');
        mockResponse.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        List<PublishHRA.PublishHRAOutput> outputs = PublishHRA.publishHRAQuestionnaire(inputs);
        Test.stopTest();

        // Assertions
        // System.assertEquals(1, outputs.size());
        // System.assertEquals('Success', outputs[0].status);
        // System.assertEquals('200', outputs[0].responseCode);
        // System.assertEquals('Success', outputs[0].responseMessage);
    }

    @IsTest (SeeAllData=true)
    static void testPublishHRAFOQuestionnaireSuccess() {
        // Create mock Lab_Order__c and Lab_Panel_Test__c records
        FulfillmentOrder fo = getFO();

        // Prepare input data with QuestionResponse objects
        PublishHRA.PublishHRAInput input = new PublishHRA.PublishHRAInput();
        input.token = 'mockToken';
        input.referenceId = fo.Id;
        input.requisitionNumber = 'REQ12345';
        input.type = 'FO';
        input.responses = new List<QuestionResponse>{
            new QuestionResponse('Q1', 'Answer1', 'Tag1', 'Type1', true),
            new QuestionResponse('Q2', 'Answer2', 'Tag2', 'Type2', false)
        };

        List<PublishHRA.PublishHRAInput> inputs = new List<PublishHRA.PublishHRAInput>{ input };

        // Mock HTTP response
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setHeader('Content-Type', 'application/json');
        mockResponse.setBody('{"responseCode":"200", "responseMessage":"Success"}');
        mockResponse.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        List<PublishHRA.PublishHRAOutput> outputs = PublishHRA.publishHRAQuestionnaire(inputs);
        Test.stopTest();

        // Assertions
        // System.assertEquals(1, outputs.size());
        // System.assertEquals('Success', outputs[0].status);
        // System.assertEquals('200', outputs[0].responseCode);
        // System.assertEquals('Success', outputs[0].responseMessage);
    }

    @isTest
    static void testPublishHRAQuestionnaireError() {
        
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

        PublishHRA.PublishHRAInput input = new PublishHRA.PublishHRAInput();
        input.token = 'mockToken';
        input.referenceId = lb.Id;
        input.requisitionNumber = 'REQ12345';
        input.type = 'LO';
        input.responses = new List<QuestionResponse>{
            new QuestionResponse('Q1', 'Answer1', 'Tag1', 'Type1', true)
        };

        List<PublishHRA.PublishHRAInput> inputs = new List<PublishHRA.PublishHRAInput>{ input };

        // Mock HTTP error response
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setHeader('Content-Type', 'application/json');
        mockResponse.setBody('{"error":{"fault":{"message":["Invalid request"]}}}');
        mockResponse.setStatusCode(400);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        List<PublishHRA.PublishHRAOutput> outputs = PublishHRA.publishHRAQuestionnaire(inputs);
        Test.stopTest();

        // Assertions
        // System.assertEquals(1, outputs.size());
        // System.assertEquals('Error', outputs[0].status);
        // System.assertEquals('400', outputs[0].responseCode);
        // System.assertEquals('Invalid request', outputs[0].responseMessage);
    }

    private static FulfillmentOrder getFO()
    {
        // Test data setup
    String salesChannel = 'Quest_US';
    String currencyIsoCode = 'USD';
    String orderTypeCode = 'Web';
    String MerchantID = 'Quest_US';
    

    Map<String,SObject> m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);       

    Order newOrder = (Order)m_mapTestData.get('newOrder');    
    SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' );                      
    List<OrderSummary> lstOS = [SELECT Id FROM OrderSummary where OriginalOrderId=:newOrder.Id ];

    // System.assert(!lstOS.isEmpty());
    OrderSummary oOrderSummary = new OrderSummary();
    oOrderSummary  = lstOS[0];
    System.debug('lstOS ==>'+lstOS[0]);
    String orderSummaryId = oOrderSummary.Id;
    List<ID> lstOSID = new List<ID>();
     lstOSID.add(orderSummaryId);
          
     System.debug('******oOrderSummary *******'+oOrderSummary );
    
      List<OrderDeliveryGroupSummary> lstODGS = [SELECT Id, OrderSummaryId FROM OrderDeliveryGroupSummary where OrderSummaryId=:oOrderSummary.Id ];
        System.debug('******lstODGS  *******'+lstODGS  );
    
    
    Schema.Location location = (Schema.Location) m_mapTestData.get('newLocationUSCE');
    

    SFOMCreateFulfillmentOrder.InputParameters obj = new SFOMCreateFulfillmentOrder.InputParameters();        
    obj.orderSummaryId = lstOS[0].Id;     
    List<SFOMCreateFulfillmentOrder.InputParameters> objLst = new List<SFOMCreateFulfillmentOrder.InputParameters>();
    objLst.add(obj);    
    SFOMCreateFulfillmentOrder.createTransaction(objLst); 

  List<Id> oSumIdLst = new List<Id>();
  oSumIdLst.add(lstOS[0].Id);
     
  List<FulfillmentOrder> fos = [SELECT Id from FulfillmentOrder where OrderSummaryId =: lstOS[0].Id];
  FulfillmentOrder fo = fos[0];
  fo.RecordTypeId=Label.SFOM_In_Person_Record_Type_Id;
       fo.Status = 'Pending Approval';
       fo.LastName__c ='Test';
       fo.FirstName__c ='Test';
       fo.Physician_First_Name__c='Test';
       fo.Physician_Last_Name__c='Test';
       fo.Physician_Npi__c='121212';
       fo.Physician_Upin__c='121121';
       fo.PWN_ID__c='12121';

       update fo;
       
       List<OrderItemSummary> OrderItemLst = [SELECT Id, TestType__c  from OrderItemSummary where OrderSummaryId IN :oSumIdLst and Type!='Delivery Charge'];
    for(OrderItemSummary item :OrderItemLst){       
            item.TestType__c='PSC';
    }
 
 update OrderItemLst;

   
       return fo;
    }

    // Mock HTTP callout class
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse mockResponse;

        MockHttpResponseGenerator(HttpResponse response) {
            this.mockResponse = response;
        }

        public HttpResponse respond(HttpRequest req) {
            return mockResponse;
        }
    }
}