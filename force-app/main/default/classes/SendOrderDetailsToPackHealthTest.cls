@isTest(SeeAllData=true)
public class SendOrderDetailsToPackHealthTest {
    
    public class SendOrderDetailsToPHMock implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if(req.getEndPoint().contains('enrollment')){
                res.setBody('{"success":true,"memberId":"1MR141","calendarURL":"https://enrollment-dev.packhealth.com/calendar/eyJtZW1i","errorMessage": null}');
                res.setStatusCode(200);
            }
            else{
                res.setbody('{"message": "Invalid request body","detail": "[instance type (boolean) does (allowed: [\"string\"])]"}');
                res.setStatusCode(400);
            }
            return res;
        }
    }
    
    
    
    
    public class SendOrderDetailsToPHMock1 implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if(req.getEndPoint().contains('enrollment')){
                res.setBody('{"success":false,"memberId":"1MR141","calendarURL":"https://enrollment-dev.packhealth.com/calendar/eyJtZW1i","errorMessage": "test case"}');
                res.setStatusCode(400);
            }
            else{
                res.setbody('{"message": "Invalid request body","detail": "[instance type (boolean) does (allowed: [\"string\"])]"}');
                res.setStatusCode(400);
            }
            return res;
        }
    }


    public class SendOrderDetailsToPHMock2 implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if(req.getEndPoint().contains('enrollment')){
                res.setBody('{"success":false,"memberId":"1MR141","calendarURL":"https://enrollment-dev.packhealth.com/calendar/eyJtZW1i","errorMessage": "test case"}');
                res.setStatusCode(500);
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
        
      // List<OrderItemSummary> ordItem = [Select id,OrderSummary.Id, ProductCode,OrderSummaryId,OrderSummary.Account.FirstName,OrderSummary.Account.LastName, OrderSummary.Account.PersonEmail,OrderSummary.Account.Phone,OrderSummary.Account.BillingStreet,OrderSummary.Account.BillingCity,OrderSummary.Account.BillingState,OrderSummary.Account.BillingCountry,OrderSummary.Account.BillingPostalCode from OrderItemSummary where ProductCode = 'packhealth4' OR ProductCode = 'packhealth6' LIMIT 1]; 
       	FulfillmentOrder fo = getFO();
        List<FulfillmentOrderLineItem> ordItem = [Select id,
                                               FulfillmentOrder.Account.FirstName,
                                               FulfillmentOrder.Account.LastName,
                                               FulfillmentOrder.Account.PersonEmail,
                                               FulfillmentOrder.Account.Phone,
                                               FulfillmentOrder.Account.BillingStreet,
                                               FulfillmentOrder.Account.BillingCity,
                                               FulfillmentOrder.Account.BillingState,
                                               FulfillmentOrder.Account.BillingCountry,
                                               FulfillmentOrder.Account.BillingPostalCode,
                                               FulfillmentOrder.OrderSummary.BillingCity,
                                               FulfillmentOrder.OrderSummary.BillingEmailAddress,
                                               FulfillmentOrder.OrderSummary.BillingCountry,
                                               FulfillmentOrder.OrderSummary.BillingState,
                                               FulfillmentOrder.OrderSummary.BillingStreet,
                                               FulfillmentOrder.OrderSummary.BillingPhoneNumber,
                                               FulfillmentOrder.OrderSummary.BillingPostalCode,
                                               FulfillmentOrder.OrderSummary.id,
                                               Status__c,
                                               OrderItemSummary.ProductCode,
                                                  FulfillmentOrder.OrderSummaryId
                                               from FulfillmentOrderLineItem where Test_Type__c = 'PackHealth' AND Is_successful__c = false and FulfillmentOrderId =: fo.Id limit 1];
       
        SendOrderDetailsToPackHealth.FulfillmentOrderIdInput flowInputs = new SendOrderDetailsToPackHealth.FulfillmentOrderIdInput();
        flowInputs.ID = ordItem[0].FulfillmentOrderId  ;
        List<SendOrderDetailsToPackHealth.FulfillmentOrderIdInput> flowInputsForTest = new List<SendOrderDetailsToPackHealth.FulfillmentOrderIdInput>();
        flowInputsForTest.add(flowInputs);
        Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, new SendOrderDetailsToPHMock());
         SendOrderDetailsToPackHealth.captureOrderDetails(flowInputsForTest);
        
        Test.stopTest();
    }
    
    
    
   
    @isTest
    static void testMethod2(){
        
       FulfillmentOrder fo = getFO();
        List<FulfillmentOrderLineItem> ordItem = [Select id,
                                               FulfillmentOrder.Account.FirstName,
                                               FulfillmentOrder.Account.LastName,
                                               FulfillmentOrder.Account.PersonEmail,
                                               FulfillmentOrder.Account.Phone,
                                               FulfillmentOrder.Account.BillingStreet,
                                               FulfillmentOrder.Account.BillingCity,
                                               FulfillmentOrder.Account.BillingState,
                                               FulfillmentOrder.Account.BillingCountry,
                                               FulfillmentOrder.Account.BillingPostalCode,
                                               FulfillmentOrder.OrderSummary.BillingCity,
                                               FulfillmentOrder.OrderSummary.BillingEmailAddress,
                                               FulfillmentOrder.OrderSummary.BillingCountry,
                                               FulfillmentOrder.OrderSummary.BillingState,
                                               FulfillmentOrder.OrderSummary.BillingStreet,
                                               FulfillmentOrder.OrderSummary.BillingPhoneNumber,
                                               FulfillmentOrder.OrderSummary.BillingPostalCode,
                                               FulfillmentOrder.OrderSummary.id,
                                               Status__c,
                                               OrderItemSummary.ProductCode,
                                                  FulfillmentOrder.OrderSummaryId
                                               from FulfillmentOrderLineItem where Test_Type__c = 'PackHealth' AND Is_successful__c  = false and FulfillmentOrderId =: fo.Id limit 1];
        
        ordItem[0].FulfillmentOrder.Account.PersonEmail = null;
        ordItem[0].FulfillmentOrder.Account.Phone = null;
        ordItem[0].FulfillmentOrder.Account.BillingStreet = null;
        ordItem[0].FulfillmentOrder.Account.BillingCity = null;
        ordItem[0].FulfillmentOrder.Account.BillingState = null;
        ordItem[0].FulfillmentOrder.Account.BillingPostalCode = null;
        
        ordItem[0].FulfillmentOrder.OrderSummary.BillingCity = '132 My StreetKingstone';
        ordItem[0].FulfillmentOrder.OrderSummary.BillingState = 'New york';
        ordItem[0].FulfillmentOrder.OrderSummary.BillingStreet = 'south tone';
        ordItem[0].FulfillmentOrder.OrderSummary.BillingPhoneNumber = '2434123456';
        ordItem[0].FulfillmentOrder.OrderSummary.BillingPostalCode = '12401';
        ordItem[0].FulfillmentOrder.OrderSummary.BillingEmailAddress = 'ram.fd800@yopmail.com';
        
        
       
        SendOrderDetailsToPackHealth.FulfillmentOrderIdInput flowInputs = new SendOrderDetailsToPackHealth.FulfillmentOrderIdInput();
        flowInputs.ID = ordItem[0].FulfillmentOrderId  ;
        List<SendOrderDetailsToPackHealth.FulfillmentOrderIdInput> flowInputsForTest = new List<SendOrderDetailsToPackHealth.FulfillmentOrderIdInput>();
        flowInputsForTest.add(flowInputs);
        Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, new SendOrderDetailsToPHMock1());
         SendOrderDetailsToPackHealth.captureOrderDetails(flowInputsForTest);
        
        Test.stopTest();
    }
    
    
   @isTest
    static void testMethod3(){
        
       FulfillmentOrder fo = getFO();
        List<FulfillmentOrderLineItem> ordItem = [Select id,
                                               FulfillmentOrder.Account.FirstName,
                                               FulfillmentOrder.Account.LastName,
                                               FulfillmentOrder.Account.PersonEmail,
                                               FulfillmentOrder.Account.Phone,
                                               FulfillmentOrder.Account.BillingStreet,
                                               FulfillmentOrder.Account.BillingCity,
                                               FulfillmentOrder.Account.BillingState,
                                               FulfillmentOrder.Account.BillingCountry,
                                               FulfillmentOrder.Account.BillingPostalCode,
                                               FulfillmentOrder.OrderSummary.BillingCity,
                                               FulfillmentOrder.OrderSummary.BillingEmailAddress,
                                               FulfillmentOrder.OrderSummary.BillingCountry,
                                               FulfillmentOrder.OrderSummary.BillingState,
                                               FulfillmentOrder.OrderSummary.BillingStreet,
                                               FulfillmentOrder.OrderSummary.BillingPhoneNumber,
                                               FulfillmentOrder.OrderSummary.BillingPostalCode,
                                               FulfillmentOrder.OrderSummary.id,
                                               Status__c,
                                               OrderItemSummary.ProductCode,
                                                  FulfillmentOrder.OrderSummaryId
                                               from FulfillmentOrderLineItem where Test_Type__c = 'PackHealth' AND Is_successful__c  = false and FulfillmentOrderId =: fo.Id limit 1];
        
        ordItem[0].FulfillmentOrder.Account.PersonEmail = null;
        ordItem[0].FulfillmentOrder.Account.Phone = null;
        ordItem[0].FulfillmentOrder.Account.BillingStreet = null;
        ordItem[0].FulfillmentOrder.Account.BillingCity = null;
        ordItem[0].FulfillmentOrder.Account.BillingState = null;
        ordItem[0].FulfillmentOrder.Account.BillingPostalCode = null;
        
        ordItem[0].FulfillmentOrder.OrderSummary.BillingCity = '132 My StreetKingstone';
        ordItem[0].FulfillmentOrder.OrderSummary.BillingState = 'New york';
        ordItem[0].FulfillmentOrder.OrderSummary.BillingStreet = 'south tone';
        ordItem[0].FulfillmentOrder.OrderSummary.BillingPhoneNumber = '2434123456';
        ordItem[0].FulfillmentOrder.OrderSummary.BillingPostalCode = '12401';
        ordItem[0].FulfillmentOrder.OrderSummary.BillingEmailAddress = 'ram.fd800@yopmail.com';
        
        
       
        SendOrderDetailsToPackHealth.FulfillmentOrderIdInput flowInputs = new SendOrderDetailsToPackHealth.FulfillmentOrderIdInput();
        flowInputs.ID = ordItem[0].FulfillmentOrderId  ;
        List<SendOrderDetailsToPackHealth.FulfillmentOrderIdInput> flowInputsForTest = new List<SendOrderDetailsToPackHealth.FulfillmentOrderIdInput>();
        flowInputsForTest.add(flowInputs);
        Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, new SendOrderDetailsToPHMock2());
         SendOrderDetailsToPackHealth.captureOrderDetails(flowInputsForTest);
        
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
        List<OrderSummary> lstOS = [SELECT Id, AccountId FROM OrderSummary where OriginalOrderId=:newOrder.Id ];
        
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
        Id packHealthId = Schema.SObjectType.FulfillmentOrder.getRecordTypeInfosByName().get('PackHealth').getRecordTypeId();
		
        List<FulfillmentOrder> fos = [SELECT Id, Account.FirstName, Account.LastName from FulfillmentOrder where OrderSummaryId =: lstOS[0].Id];
        System.debug('acc Id'+ fos[0].Account.FirstName + ' ' + fos[0].Account.LastName);
        FulfillmentOrder fo = fos[0];
        fo.RecordTypeId=packHealthId;
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

        
        List<OrderItemSummary> OrderItemLst = [SELECT Id, TestType__c from OrderItemSummary where OrderSummaryId IN :oSumIdLst and Type!='Delivery Charge'];
        for(OrderItemSummary item :OrderItemLst){       
            item.TestType__c='PackHealth';
        }
        
        update OrderItemLst;
        
        FulfillmentOrderLineItem lineItem = new FulfillmentOrderLineItem();
        lineItem.FulfillmentOrderId = fo.Id;
        lineItem.OrderItemSummaryId = orderItemLst[0].id;
        lineItem.Status__c = 'Kit Shipped';
        lineItem.Quantity = 1;
        lineItem.OriginalQuantity = 1;
        lineItem.Type = 'Order Product';
        lineItem.TypeCode ='Product';
        //lineItem.AccountID__c = acc.id;
        insert lineItem;
        
        OrderSummary oOrderSummary1 = new OrderSummary();
        oOrderSummary1  = lstOS[0];
        oOrderSummary1.Partner_Name__c='Quest';
        
        update oOrderSummary1;
        
        
        return fo;
    }
}