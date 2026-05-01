@isTest
public class CreateHUBOrderTest {

    private class MockHttpResponseGeneratorSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(201);
            res.setBody('{"hubResponse": "order created successfully.","refId": "b2e85ca14ea9438ab7c62756d105d2b7"}');
            return res;
        }
    }

    
    private class MockHttpResponseGeneratorTimeout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(504);
            res.setBody('Time out');
            return res;
        }
    }

    
    private class MockHttpResponseGeneratorBadRequest implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('{"errorType":"DATA_ERROR",{"error": {"fault": {"message": ["Bad request"]}}}}');
            return res;
        }
    }

    @IsTest (SeeAllData=true)
public static void testCreateHUBOrder_Success() {
   
    
    FulfillmentOrder fo = getFO();

    CreateHubOrder.HUBServiceInput input = new CreateHubOrder.HUBServiceInput();
    input.token = 'sampleToken';
    input.FOID = fo.Id;

    List<CreateHubOrder.HUBServiceInput> inputs = new List<CreateHubOrder.HUBServiceInput>{input};

    // Mocking successful HTTP callout
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());
    Test.startTest();
    // Call the method
    List<CreateHubOrder.HUBServiceOutput> result = CreateHubOrder.createHUBOrder(inputs);
    Test.stopTest();

    // Assertions for success scenario
    System.assertEquals(1, result.size(), 'Expected one output record');
    CreateHubOrder.HUBServiceOutput output = result[0];
    System.debug('Response Body::'+output.responsePayload);
    System.assertEquals('Success', output.Status, 'Expected success status');
    System.assertEquals('201', output.responseCode, 'Expected response code 201');
}

@IsTest (SeeAllData=true)
static void testCreateHUBOrder_BadRequest() {
    // Test data setup
    FulfillmentOrder fo = getFO();
    

    CreateHubOrder.HUBServiceInput input = new CreateHubOrder.HUBServiceInput();
    input.token = 'sampleToken';
    input.FOID = fo.Id;

    List<CreateHubOrder.HUBServiceInput> inputs = new List<CreateHubOrder.HUBServiceInput>{input};

    // Mocking bad request HTTP callout
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorBadRequest());

    // Call the method
    Test.startTest();
    List<CreateHubOrder.HUBServiceOutput> result = CreateHubOrder.createHUBOrder(inputs);
    Test.stopTest();

    // Assertions for 400 error scenario
    System.assertEquals(1, result.size(), 'Expected one output record');
    CreateHubOrder.HUBServiceOutput output = result[0];
    System.assertEquals('Error', output.Status, 'Expected error status');
    System.assertEquals('400', output.responseCode, 'Expected response code 400');
   
}

    @IsTest (SeeAllData=true)
    static void testCreateHUBOrder_Timeout() {
        // Test data setup
        FulfillmentOrder fo = getFO();
        

        CreateHubOrder.HUBServiceInput input = new CreateHubOrder.HUBServiceInput();
        input.token = 'sampleToken';
        input.FOID = fo.Id;

        List<CreateHubOrder.HUBServiceInput> inputs = new List<CreateHubOrder.HUBServiceInput>{input};

        // Mocking timeout HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorTimeout());

        // Call the method
        Test.startTest();
        List<CreateHubOrder.HUBServiceOutput> result = CreateHubOrder.createHUBOrder(inputs);
        Test.stopTest();

        // Assertions for 504 error scenario
        System.assertEquals(1, result.size(), 'Expected one output record');
        CreateHubOrder.HUBServiceOutput output = result[0];
        System.assertEquals('Error', output.Status, 'Expected error status');
        System.assertEquals('504', output.responseCode, 'Expected response code 504');
        
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
       fo.FulfilledToAddressLine1__c = '123 Street';

       update fo;
       
       List<OrderItemSummary> OrderItemLst = [SELECT Id, TestType__c  from OrderItemSummary where OrderSummaryId IN :oSumIdLst and Type!='Delivery Charge'];
    for(OrderItemSummary item :OrderItemLst){       
            item.TestType__c='PSC';
    }
 
 update OrderItemLst;

    OrderSummary oOrderSummary1 = new OrderSummary();
    oOrderSummary1  = lstOS[0];
    oOrderSummary1.Partner_Name__c='Quest';

    update oOrderSummary1;

   
       return fo;
    }
   
}