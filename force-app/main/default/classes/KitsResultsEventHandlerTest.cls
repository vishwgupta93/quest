@isTest
public class KitsResultsEventHandlerTest {
    public static Map<String,SObject> m_mapTestData = null;
    @IsTest (SeeAllData=true)
    static void testSendPayLoadSuccess() {
        String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
        //m_mapTestData = SFOMTestDataFactory.initData(salesChannel, currencyIsoCode);  
        m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);
        
   
          OrderDeliveryGroup newOrderDeliveryGroupTest  = (OrderDeliveryGroup ) m_mapTestData.get('newOrderDeliveryGroup');
          System.debug('newOrderDeliveryGroupTest   ==>'+newOrderDeliveryGroupTest );  
          
          PaymentAuthorization auth = (PaymentAuthorization) m_mapTestData.get('paymentAuth');
          System.debug('Auth ==>'+auth);  
            
        Order newOrder = (Order)m_mapTestData.get('newOrder');
      //  System.assert(newOrder != null);
        
        
        
        // activate orders and create ordersummary objects        
        SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' ); 

        
        System.debug('******newOrder.status *******'+newOrder.status );
        
        
       // List<OrderSummary> lstOS = [SELECT Id, Status FROM OrderSummary where OriginalOrderId =:newOrder.Id ];
        List<OrderSummary> lstOS = [SELECT Id,AccountId, Status FROM OrderSummary where OriginalOrderId=:newOrder.Id ];
    //    System.assert(!lstOS.isEmpty());
        OrderSummary oOrderSummary = new OrderSummary();
        oOrderSummary  = lstOS[0];
        System.debug('lstOS ==>'+lstOS[0]);
        String orderSummaryId = oOrderSummary.Id;
        String accountId= oOrderSummary.accountId;
        
              
         System.debug('******oOrderSummary *******'+oOrderSummary );
        
          List<OrderDeliveryGroupSummary> lstODGS = [SELECT Id, OrderSummaryId FROM OrderDeliveryGroupSummary where OrderSummaryId=:oOrderSummary.Id ];
            System.debug('******lstODGS  *******'+lstODGS  );
            
            
            
            
            ConnectApi.CreateOrderPaymentSummaryInputRepresentation orderPaymentSummaryInput = new ConnectApi.CreateOrderPaymentSummaryInputRepresentation();
            orderPaymentSummaryInput.orderSummaryId = orderSummaryId ;
            orderPaymentSummaryInput.paymentAuthorizationId = auth.Id;
            
            ConnectApi.CreateOrderPaymentSummaryOutputRepresentation opos= ConnectAPI.OrderPaymentSummary.createOrderPaymentSummary(orderPaymentSummaryInput);
            
            System.debug('%%%%%OPS Created***********' + opos.orderPaymentSummaryId);
            
            List<OrderPaymentSummary> lstOPS= [SELECT Id,paymentType__c, OrderSummaryId FROM OrderPaymentSummary where OrderSummaryId=:oOrderSummary.Id ];
            System.debug('******lstOPS*******'+lstOPS);
            
            OrderPaymentSummary ops = lstOPS[0];
            ops.paymentType__c='card';
            
            update ops;
            
                      
            lstOPS= [SELECT Id,paymentType__c, OrderSummaryId FROM OrderPaymentSummary where OrderSummaryId=:oOrderSummary.Id ];
            System.debug('******After Update lstOPS*******'+lstOPS);
                    
        
        SFMC_OMS_Config__c config = new SFMC_OMS_Config__c(
            Channel__c = 'QD-CIT',
            API__c = 'Common',
            Auth_Token__c = 'TestAuthToken'
        );
        insert config;
        
        Test.startTest();
        // Call the future method
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        KitsResultsEventHandler.sendPayLoad(orderSummaryId, 'eventKey', 'testType', 'email', 'customerId', false);
        Test.stopTest();
        
        // Verify event log creation
        List<Event_Log__c> eventLogs = [SELECT Id, Order_Summary__c, Event_Type__c, Status__c FROM Event_Log__c where Order_Summary__c =:orderSummaryId] ;
        System.assertEquals(1, eventLogs.size());
        Event_Log__c eventLog = eventLogs[0];
        System.assertEquals(orderSummaryId, eventLog.Order_Summary__c);
        System.assertEquals('Results', eventLog.Event_Type__c);
        System.assertEquals('Success', eventLog.Status__c);
        // Add more assertions for payload and response payload as needed
    }
    @IsTest (SeeAllData=true)
    static void testSendPayLoadError() {
        String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
        //m_mapTestData = SFOMTestDataFactory.initData(salesChannel, currencyIsoCode);  
        m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);
        
   
          OrderDeliveryGroup newOrderDeliveryGroupTest  = (OrderDeliveryGroup ) m_mapTestData.get('newOrderDeliveryGroup');
          System.debug('newOrderDeliveryGroupTest   ==>'+newOrderDeliveryGroupTest );  
          
          PaymentAuthorization auth = (PaymentAuthorization) m_mapTestData.get('paymentAuth');
          System.debug('Auth ==>'+auth);  
            
        Order newOrder = (Order)m_mapTestData.get('newOrder');
      //  System.assert(newOrder != null);
        
        
        
        // activate orders and create ordersummary objects        
        SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' ); 

        
        System.debug('******newOrder.status *******'+newOrder.status );
        
        
       // List<OrderSummary> lstOS = [SELECT Id, Status FROM OrderSummary where OriginalOrderId =:newOrder.Id ];
        List<OrderSummary> lstOS = [SELECT Id,AccountId, Status FROM OrderSummary where OriginalOrderId=:newOrder.Id ];
    //    System.assert(!lstOS.isEmpty());
        OrderSummary oOrderSummary = new OrderSummary();
        oOrderSummary  = lstOS[0];
        System.debug('lstOS ==>'+lstOS[0]);
        String orderSummaryId = oOrderSummary.Id;
        String accountId= oOrderSummary.accountId;
        
              
         System.debug('******oOrderSummary *******'+oOrderSummary );
        
          List<OrderDeliveryGroupSummary> lstODGS = [SELECT Id, OrderSummaryId FROM OrderDeliveryGroupSummary where OrderSummaryId=:oOrderSummary.Id ];
            System.debug('******lstODGS  *******'+lstODGS  );
            
            
            
            
            ConnectApi.CreateOrderPaymentSummaryInputRepresentation orderPaymentSummaryInput = new ConnectApi.CreateOrderPaymentSummaryInputRepresentation();
            orderPaymentSummaryInput.orderSummaryId = orderSummaryId ;
            orderPaymentSummaryInput.paymentAuthorizationId = auth.Id;
            
            ConnectApi.CreateOrderPaymentSummaryOutputRepresentation opos= ConnectAPI.OrderPaymentSummary.createOrderPaymentSummary(orderPaymentSummaryInput);
            
            System.debug('%%%%%OPS Created***********' + opos.orderPaymentSummaryId);
            
            List<OrderPaymentSummary> lstOPS= [SELECT Id,paymentType__c, OrderSummaryId FROM OrderPaymentSummary where OrderSummaryId=:oOrderSummary.Id ];
            System.debug('******lstOPS*******'+lstOPS);
            
            OrderPaymentSummary ops = lstOPS[0];
            ops.paymentType__c='card';
            
            update ops;
            
                      
            lstOPS= [SELECT Id,paymentType__c, OrderSummaryId FROM OrderPaymentSummary where OrderSummaryId=:oOrderSummary.Id ];
            System.debug('******After Update lstOPS*******'+lstOPS);
                    
        
        SFMC_OMS_Config__c config = new SFMC_OMS_Config__c(
            Channel__c = 'QD-CIT',
            API__c = 'Common',
            Auth_Token__c = 'TestAuthToken'
        );
        insert config;
        
        Test.startTest();
        // Call the future method
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorError());
        KitsResultsEventHandler.sendPayLoad(orderSummaryId, 'eventKey', 'testType', 'email', 'customerId', false);
        Test.stopTest();
        
        // Verify event log creation
        List<Event_Log__c> eventLogs = [SELECT Id, Order_Summary__c, Event_Type__c, Status__c FROM Event_Log__c where Order_Summary__c =:orderSummaryId] ;
        System.assertEquals(1, eventLogs.size());
        Event_Log__c eventLog = eventLogs[0];
        System.assertEquals(orderSummaryId, eventLog.Order_Summary__c);
        System.assertEquals('Results', eventLog.Event_Type__c);
        System.assertEquals('Error', eventLog.Status__c);
        // Add more assertions for payload and response payload as needed
    }
    
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
}