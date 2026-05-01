@IsTest
public class SFOMFOExpirationBatchScheduleTest {
    
    
        public static Map<String,SObject> m_mapTestData = null;
    
   @IsTest (SeeAllData=true)
    public static void SFOMFOExpirationBatchScheduleTest () {
        
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

ConnectApi.FulfillmentOrderInputRepresentation fulfillmentOrderInput2 = new ConnectApi.FulfillmentOrderInputRepresentation();
        fulfillmentOrderInput2.orderSummaryId = orderSummaryId;

for (OrderDeliveryGroupSummary orderDeliveryGroupSummary: orderDeliveryGroupSummaryList){

        fulfillmentOrderInput2.orderDeliveryGroupSummaryId = orderDeliveryGroupSummary.Id;
        List<ConnectApi.FulfillmentGroupInputRepresentation> fulfillmentGroups = new List<ConnectApi.FulfillmentGroupInputRepresentation>();
        ConnectApi.FulfillmentGroupInputRepresentation fulfillmentGroup = new ConnectApi.FulfillmentGroupInputRepresentation();
        fulfillmentGroup.fulfilledFromLocationId = location.Id;
        fulfillmentGroup.fulfillmentType = location.LocationType;

        List<ConnectApi.OrderItemSummaryInputRepresentation> orderItemSummaries = new List<ConnectApi.OrderItemSummaryInputRepresentation>();

          List<OrderItemSummary> orderItemSummaryList = [Select Id, quantity FROM OrderItemSummary WHERE OrderSummaryId =: orderSummaryId AND OrderDeliveryGroupSummaryId =: orderDeliveryGroupSummary.Id and TestType__c='PA'];
          for(OrderItemSummary orderItemSummary : orderItemSummaryList){
            ConnectApi.OrderItemSummaryInputRepresentation oisInputRepresentation = new ConnectApi.OrderItemSummaryInputRepresentation();
            oisInputRepresentation.orderItemSummaryId = orderItemSummary.Id;
            oisInputRepresentation.quantity = orderItemSummary.quantity;
            orderItemSummaries.add(oisInputRepresentation);
          }

          fulfillmentGroup.orderItemSummaries = orderItemSummaries;
          fulfillmentGroups.add(fulfillmentGroup);      
          fulfillmentOrderInput2.fulfillmentGroups = fulfillmentGroups;

        }

     
ConnectApi.FulfillmentOrderOutputRepresentation result2 = ConnectAPI.FulfillmentOrder.createFulfillmentOrders(fulfillmentOrderInput2);

        /***************************************************************************************************************************************/
        

   System.debug('FOs ' + result );
   
      System.debug('FOs2 ' + result2 );
        
         FulfillmentOrder lstFO = new FulfillmentOrder();
            System.debug('Welcome lstFO 1==>'+lstFO.id);         
            //FulfillmentOrder foo= lstFO[0];
            lstFO.id= result.fulfillmentOrderIds[0];
            lstFO.Status = 'PA Approved';
            lstFO.RecordTypeId=Label.SFOM_In_Person_Record_Type_Id;
            lstFO.PWN_Status_Date__c = date.parse('4/17/2022');
            lstFO.Service_Fee__c=20.00;
            update lstFO ;
            
            ConnectApi.FulfillmentOrderInvoiceInputRepresentation invIp = new ConnectApi.FulfillmentOrderInvoiceInputRepresentation();
        ConnectApi.FulfillmentOrderInvoiceOutputRepresentation invOp = ConnectApi.FulfillmentOrder.createInvoice(
            lstFO.Id,
            invIp
        );
        
        FulfillmentOrder pwn = new FulfillmentOrder();
            System.debug('Welcome lstFO 1==>'+lstFO.id);         
            //FulfillmentOrder foo= lstFO[0];
            pwn.id= result2 .fulfillmentOrderIds[0];
            pwn.RecordTypeId=Label.SFOM_PWN_Service_Record_Type_Id;
            update pwn ;
            
           
            
//FulfillmentOrder foInput = [Select  Id,RecordTypeId,InvoiceId,Status,OrderSummaryId,GrandTotalAmount,Service_Fee__c from FulfillmentOrder where Eligible_to_Expire__c = true  and Id=:lstFO.id];            
            
           // System.debug('%%%%%%%%%%%%%% FO Input ***************' + foInput  );
            
            FulfillmentOrder foInput2 = [Select  Id,RecordTypeId,OrderSummaryId from FulfillmentOrder where  Id=:pwn.id];            
            
            System.debug('%%%%%%%%%%%%%% FO Input ***************' + foInput2  );
            
       
    SFOMFulfillmentOrderExpirationBatch btch = new SFOMFulfillmentOrderExpirationBatch();
      btch.Id = lstFO.id;
     btch.StatusExpired = Label.SFOM_FO_Status_Expired;
     btch.Query = 'Select  Id,RecordTypeId,InvoiceId,Status,StatusCategory,OrderSummaryId,GrandTotalAmount,Service_Fee__c from FulfillmentOrder where Status!=:StatusExpired and StatusCategory != \'REJECTED\' and Id=:Id';
        
        Database.executeBatch(btch,1);
            
        
    }
    
    @IsTest 
    static void SFOMFOExpirationBatchScheduleFailuresTest () {
        SFOMFOExpirationBatchSchedule  obj = new SFOMFOExpirationBatchSchedule();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, obj); 
  }      
}