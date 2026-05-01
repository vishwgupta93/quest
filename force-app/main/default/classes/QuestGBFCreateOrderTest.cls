@isTest
public with sharing class QuestGBFCreateOrderTest {
   
    private class MockHttpResponseGeneratorSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            return res;
        }
    }

       private class MockHttpResponseGeneratorError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            return res;
        }
    }

      @IsTest (SeeAllData=true)
public static void testCreateGBFOrder_Success() {

     FulfillmentOrder fo = getFO();

    QuestGBFCreateOrder.QuestGBFCreateOrderInput input = new QuestGBFCreateOrder.QuestGBFCreateOrderInput();
    input.apiKey = 'sampleToken';
    input.fulfillmentOrderId = fo.Id;
    input.test=true;

    List<QuestGBFCreateOrder.QuestGBFCreateOrderInput> inputs = new List<QuestGBFCreateOrder.QuestGBFCreateOrderInput>{input};

     Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());
    Test.startTest();
    // Call the method
    List<QuestGBFCreateOrder.QuestGBFCreateOrderOutput> result = QuestGBFCreateOrder.createGBFOrder(inputs);
    Test.stopTest();

}

@IsTest (SeeAllData=true)
public static void testCreateGBFOrder_Error() {

     FulfillmentOrder fo = getFO();

    QuestGBFCreateOrder.QuestGBFCreateOrderInput input = new QuestGBFCreateOrder.QuestGBFCreateOrderInput();
    input.apiKey = 'sampleToken';
    input.fulfillmentOrderId = fo.Id;
    input.test=true;

    List<QuestGBFCreateOrder.QuestGBFCreateOrderInput> inputs = new List<QuestGBFCreateOrder.QuestGBFCreateOrderInput>{input};

     Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorError());
    Test.startTest();
    // Call the method
    List<QuestGBFCreateOrder.QuestGBFCreateOrderOutput> result = QuestGBFCreateOrder.createGBFOrder(inputs);
    Test.stopTest();

}

@IsTest (SeeAllData=true)
public static void testCreateSSOrder_Success() {

    FulfillmentOrder fo = getFO();

    QuestSSCreateOrder.QuestSSCreateOrderInput input = new QuestSSCreateOrder.QuestSSCreateOrderInput();
    input.apiToken = 'sampleToken';
    input.fulfillmentOrderId = fo.Id;
    input.test=true;

    List<QuestSSCreateOrder.QuestSSCreateOrderInput> inputs = new List<QuestSSCreateOrder.QuestSSCreateOrderInput>{input};

     Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());
    Test.startTest();
    // Call the method
    List<QuestSSCreateOrder.QuestSSCreateOrderOutput> result = QuestSSCreateOrder.createShipStationOrder(inputs);
    Test.stopTest();

}

@IsTest (SeeAllData=true)
public static void testCreateSSOrder_Error() {

     FulfillmentOrder fo = getFO();

    QuestSSCreateOrder.QuestSSCreateOrderInput input = new QuestSSCreateOrder.QuestSSCreateOrderInput();
    input.apiToken = 'sampleToken';
    input.fulfillmentOrderId = fo.Id;
    input.test=true;

    List<QuestSSCreateOrder.QuestSSCreateOrderInput> inputs = new List<QuestSSCreateOrder.QuestSSCreateOrderInput>{input};

     Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorError());
    Test.startTest();
    // Call the method
    List<QuestSSCreateOrder.QuestSSCreateOrderOutput> result = QuestSSCreateOrder.createShipStationOrder(inputs);
    Test.stopTest();

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

    List<OrderItemSummary> OrderItemLst = [SELECT Id, TestType__c  from OrderItemSummary where OrderSummaryId IN :lstOSID and Type!='Delivery Charge'];
    for(OrderItemSummary item :OrderItemLst){       
            item.TestType__c='at_home';
    }
 
 update OrderItemLst;
    

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
       fo.FulfilledToAddressLine1__c='124 Main St';
       fo.FulfilledToAddressLine2__c='Aasa';

       update fo;
       
       

   
       return fo;
    }
}