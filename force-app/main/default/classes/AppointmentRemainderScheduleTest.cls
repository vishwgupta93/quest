@IsTest
public class AppointmentRemainderScheduleTest {
    
    
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
    
   @IsTest (SeeAllData=true)
    public static void AppointmentRemainderScheduleTestPayload () {
        
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
            ops.paymentType__c='gift_card';
            
            update ops;
            
                      
            lstOPS= [SELECT Id,paymentType__c, OrderSummaryId FROM OrderPaymentSummary where OrderSummaryId=:oOrderSummary.Id ];
            System.debug('******After Update lstOPS*******'+lstOPS);
                    
            
            
            
        
        
        Schema.Location location = (Schema.Location) m_mapTestData.get('newLocationUSCE');
        
        /***************************************************************************************************************************************/
        
        ConnectApi.FulfillmentOrderInputRepresentation fulfillmentOrderInput = new ConnectApi.FulfillmentOrderInputRepresentation();
        fulfillmentOrderInput.orderSummaryId = orderSummaryId;

        List<OrderDeliveryGroupSummary> orderDeliveryGroupSummaryList = [SELECT Id FROM OrderDeliveryGroupSummary WHERE OrderSummaryId =: orderSummaryId];

        for (OrderDeliveryGroupSummary orderDeliveryGroupSummary: orderDeliveryGroupSummaryList){

        fulfillmentOrderInput.orderDeliveryGroupSummaryId = orderDeliveryGroupSummary.Id;
        List<ConnectApi.FulfillmentGroupInputRepresentation> fulfillmentGroups = new List<ConnectApi.FulfillmentGroupInputRepresentation>();
        ConnectApi.FulfillmentGroupInputRepresentation fulfillmentGroup = new ConnectApi.FulfillmentGroupInputRepresentation();
        fulfillmentGroup.fulfilledFromLocationId = location.Id;
        fulfillmentGroup.fulfillmentType = location.LocationType;

        List<ConnectApi.OrderItemSummaryInputRepresentation> orderItemSummaries = new List<ConnectApi.OrderItemSummaryInputRepresentation>();

          List<OrderItemSummary> orderItemSummaryList = [Select Id, quantity FROM OrderItemSummary WHERE OrderSummaryId =: orderSummaryId AND OrderDeliveryGroupSummaryId =: orderDeliveryGroupSummary.Id and TestType__c='PSC'];
          for(OrderItemSummary orderItemSummary : orderItemSummaryList){
            ConnectApi.OrderItemSummaryInputRepresentation oisInputRepresentation = new ConnectApi.OrderItemSummaryInputRepresentation();
            oisInputRepresentation.orderItemSummaryId = orderItemSummary.Id;
            oisInputRepresentation.quantity = orderItemSummary.quantity;
            orderItemSummaries.add(oisInputRepresentation);
          }

          fulfillmentGroup.orderItemSummaries = orderItemSummaries;
          fulfillmentGroups.add(fulfillmentGroup);      
          fulfillmentOrderInput.fulfillmentGroups = fulfillmentGroups;

        }

ConnectApi.FulfillmentOrderOutputRepresentation result = ConnectAPI.FulfillmentOrder.createFulfillmentOrders(fulfillmentOrderInput);



        /***************************************************************************************************************************************/
        

   System.debug('FOs ' + result );
   
           
         FulfillmentOrder lstFO = new FulfillmentOrder();
            System.debug('Welcome lstFO 1==>'+lstFO.id);         
            //FulfillmentOrder foo= lstFO[0];
            lstFO.id= result.fulfillmentOrderIds[0];
            lstFO.Status = 'PA Approved';
            lstFO.RecordTypeId=Label.SFOM_In_Person_Record_Type_Id;
            lstFO.PWN_Status_Date__c = date.parse('4/17/2024');
            lstFO.Service_Fee__c=20.00;
            lstFO.HUB_Success__c=true;
            update lstFO ;
            
            ConnectApi.FulfillmentOrderInvoiceInputRepresentation invIp = new ConnectApi.FulfillmentOrderInvoiceInputRepresentation();
        ConnectApi.FulfillmentOrderInvoiceOutputRepresentation invOp = ConnectApi.FulfillmentOrder.createInvoice(
            lstFO.Id,
            invIp
        );   
       
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();

        SFMC_OMS_Config__c config = new SFMC_OMS_Config__c(
        Channel__c = 'QD-CIT',
        API__c = 'Common',
        Auth_Token__c = 'TestAuthToken'
    );
    insert config;
            
            AppointmentRemainderEmailOutbound btch = new AppointmentRemainderEmailOutbound();
    List<String> statusList = new List<String>{'PA Approved','Pending Approval'};
        btch.statusList = statusList;
        btch.type = Label.SFOM_In_Person_Record_Type_Id;
      btch.Id = lstFO.id;
          btch.Query = 'SELECT Id, orderSummary.OrderedDate,OrderSummary.OrderNumber,orderSummary.GrandTotalAmount,OrderSummary.BillingEmailAddress,OrderSummary.CustomerId__c,orderSummary.Account.PersonEmail,Expiration_Date__c,Days_Past_Confirm__c,OrderSummaryId FROM FulfillmentOrder WHERE RecordTypeId = :type and  Status IN : statusList  and HUB_Success__c = true and Id=:Id';
        
        Database.executeBatch(btch,1);
        Test.stopTest();
            
        
    }
    
    @IsTest 
    static void AppointmentRemainderScheduleTerritoryTest () {
        AppointmentRemainderSchedule  obj = new AppointmentRemainderSchedule();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, obj); 
  }      
}