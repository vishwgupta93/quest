@IsTest 
public class SFOMSchedulePaymentFailuresBatchTest {
    
    
        public static Map<String,SObject> m_mapTestData = null;
    
   @IsTest (SeeAllData=true)
    static void SFOMSchedulePaymentFailuresBatchTest () {
        
        String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
 
        m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);
        
   
          OrderDeliveryGroup newOrderDeliveryGroupTest  = (OrderDeliveryGroup ) m_mapTestData.get('newOrderDeliveryGroup');
          System.debug('newOrderDeliveryGroupTest   ==>'+newOrderDeliveryGroupTest );  
            
        Order newOrder = (Order)m_mapTestData.get('newOrder');
       // System.assert(newOrder != null);
        
        
        
        // activate orders and create ordersummary objects        
        SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' ); 
       //  SOMTestDataFactory.activateOrders(); 
        
        System.debug('******newOrder.status *******'+newOrder.status );
        
        
       // List<OrderSummary> lstOS = [SELECT Id, Status FROM OrderSummary where OriginalOrderId =:newOrder.Id ];
        List<OrderSummary> lstOS = [SELECT Id, Status , OrderNumber FROM OrderSummary where OriginalOrderId=:newOrder.Id ];
       // System.assert(!lstOS.isEmpty());
        OrderSummary oOrderSummary = new OrderSummary();
        oOrderSummary  = lstOS[0];
        System.debug('lstOS ==>'+lstOS[0]);
        String orderSummaryId = oOrderSummary.Id;
        
              
         System.debug('******oOrderSummary *******'+oOrderSummary );
        
          List<OrderDeliveryGroupSummary> lstODGS = [SELECT Id, OrderSummaryId FROM OrderDeliveryGroupSummary where OrderSummaryId=:oOrderSummary.Id ];
            System.debug('******lstODGS  *******'+lstODGS  );
        
        
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

          List<OrderItemSummary> orderItemSummaryList = [Select Id, quantity FROM OrderItemSummary WHERE OrderSummaryId =: orderSummaryId AND OrderDeliveryGroupSummaryId =: orderDeliveryGroupSummary.Id];
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
       
       System.debug('result ==>'+result);


        /***************************************************************************************************************************************/
        List<FulfillmentOrder> oFulfillmentOrders  = [Select Id, orderSummaryId, Invoice.Ensure_Funds_Count__c, status from FulfillmentOrder where  OrderSummaryId=:oOrderSummary.Id  ];
        system.debug('oFulfillmentOrder  ==>'+oFulfillmentOrders  );
        FulfillmentOrder oFulfillmentOrder = new FulfillmentOrder();
        oFulfillmentOrder =  oFulfillmentOrders[0];
        oFulfillmentOrder.Status = 'PA Approved';
        update oFulfillmentOrder;
        System.debug('oFulfillmentOrder  ==>'+oFulfillmentOrder);
          
       
       String fulfillmentOrderId = oFulfillmentOrder.Id;

        ConnectApi.FulfillmentOrderInvoiceInputRepresentation input = new ConnectApi.FulfillmentOrderInvoiceInputRepresentation();
        ConnectAPI.FulfillmentOrderInvoiceOutputRepresentation oFOresult = ConnectApi.FulfillmentOrder.createInvoice(fulfillmentOrderId, input);
        System.debug('oFOresult ==>'+oFOresult );
   
        
      //   List<FulfillmentOrder> oFulfillmentOrders1 = [Select Id, orderSummaryId, Invoice.Ensure_Funds_Count__c, status from FulfillmentOrder whereOrderSummaryId=:oOrderSummary.Id and Invoice.Balance >0 ];
      List<Invoice> oInvoice = [Select Id, ReferenceEntityId, Ensure_Funds_Count__c, status from Invoice where ReferenceEntityId=:oOrderSummary.OrderNumber ];
      System.debug('oInvoice ==>'+oInvoice );
      
        SFOMPaymentFailureRetryBatch btch = new SFOMPaymentFailureRetryBatch();
        btch.Id = fulfillmentOrderId;
        btch.query = 'Select Id, orderSummaryId, Invoice.Ensure_Funds_Count__c, status from FulfillmentOrder where Id=:Id';
        Database.executeBatch(btch,1);
        
      

       

    }

    @IsTest 
    static void SFOMSchedulePaymentFailuresTest () {
        SFOMSchedulePaymentFailuresBatch   testsche = new SFOMSchedulePaymentFailuresBatch ();
        String sch = '0 0 23 * * ?';
        system.schedule('Test status Check', sch, testsche );
  }   
}