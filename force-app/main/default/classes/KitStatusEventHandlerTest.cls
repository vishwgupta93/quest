@IsTest
public with sharing class KitStatusEventHandlerTest {
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

@IsTest (SeeAllData=true)
static void testSendPayLoadSuccess() {

    FulfillmentOrder fo = getFO();

    FulfillmentOrder fo1 = [select OrderSummaryId from FulfillmentOrder where Id =: fo.Id];

    Kit_Details__c kit = new Kit_Details__c();
    kit.Fulfillment_Order_Id__c=fo.Id;
    kit.Order_Summary__c=fo1.OrderSummaryId;
    kit.ActivationUser_Customer_Email__c='test@test.com';
    kit.ActivationUser_Customer_Id__c='1212121211';
    kit.Status__c='Activated';
    kit.Lab_Status__c='Sample Received';
    kit.Type__c='at_home';
    kit.Order_Number__c='QST-'+fo.Id;
    kit.Tracking_Number__c='1212344gjasd';
    insert kit;
    Test.startTest();
    // Call the future method
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    KitStatusEventHandler.sendPayLoad(kit.ID, Label.SFMC_Kit_Sample_Received_Event_Definition_Key, false);
    Test.stopTest();

    List<Event_Log__c> eventLogs = [SELECT Id, Kit_Detail__c, Event_Type__c, Status__c FROM Event_Log__c where Kit_Detail__c =:kit.Id] ;
    System.assertEquals(1, eventLogs.size());
    Event_Log__c eventLog = eventLogs[0];
    System.assertEquals(kit.Id, eventLog.Kit_Detail__c);
    System.assertEquals('Sample Received', eventLog.Event_Type__c);
    System.assertEquals('Success', eventLog.Status__c);
    
}

@IsTest (SeeAllData=true)
static void testSendPayLoadError() {

    FulfillmentOrder fo = getFO();

    FulfillmentOrder fo1 = [select OrderSummaryId from FulfillmentOrder where Id =: fo.Id];

    Kit_Details__c kit = new Kit_Details__c();
    kit.Fulfillment_Order_Id__c=fo.Id;
    kit.Order_Summary__c=fo1.OrderSummaryId;
    kit.ActivationUser_Customer_Email__c='test@test.com';
    kit.ActivationUser_Customer_Id__c='1212121211';
    kit.Status__c='Activated';
    kit.Lab_Status__c='Sample Received';
    kit.Type__c='at_home';
    kit.Order_Number__c='QST-'+fo.Id;
    kit.Tracking_Number__c='1212344gjasd';
    insert kit;
    Test.startTest();
    // Call the future method
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorError());
    KitStatusEventHandler.sendPayLoad(kit.ID, Label.SFMC_Kit_Sample_Received_Event_Definition_Key, false);
    Test.stopTest();

    List<Event_Log__c> eventLogs = [SELECT Id, Kit_Detail__c, Event_Type__c, Status__c FROM Event_Log__c where Kit_Detail__c =:kit.Id] ;
    System.assertEquals(1, eventLogs.size());
    Event_Log__c eventLog = eventLogs[0];
    System.assertEquals(kit.Id, eventLog.Kit_Detail__c);
    System.assertEquals('Sample Received', eventLog.Event_Type__c);
    System.assertEquals('Error', eventLog.Status__c);
    
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