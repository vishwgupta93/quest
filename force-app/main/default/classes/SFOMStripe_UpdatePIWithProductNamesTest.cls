@IsTest 
public class SFOMStripe_UpdatePIWithProductNamesTest{
    
   public static Map<String,SObject> m_mapTestData = null;
    
   @IsTest (SeeAllData=true)
    static void SFOMStripe_UpdatePIWithProductNamesTest() {
        Test.setMock(HttpCalloutMock.class, new MockTaxService()); 
        
        String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
        m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);
   
        OrderDeliveryGroup newOrderDeliveryGroupTest  = (OrderDeliveryGroup ) m_mapTestData.get('newOrderDeliveryGroup');
        System.debug('newOrderDeliveryGroupTest   ==>'+newOrderDeliveryGroupTest );            
        Order newOrder = (Order)m_mapTestData.get('newOrder');        
        // activate orders and create ordersummary objects        
        SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' ); 
        
        System.debug('******newOrder.status *******'+newOrder.status );
        
        List<OrderSummary> lstOS = [SELECT Id, Status FROM OrderSummary where OriginalOrderId=:newOrder.Id ];
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
        /***************************************************************************************************************************************/       
        FulfillmentOrder   lstFO = (FulfillmentOrder) [ SELECT Id, OrderSummaryId FROM FulfillmentOrder where  id = :result.fulfillmentOrderIds[0]] ;
        System.debug('Welcome lstFO 1==>'+lstFO.id);                         
        List<SFOMStripe_UpdatePIWithProductNames.InputParameters> objLst = new List<SFOMStripe_UpdatePIWithProductNames.InputParameters>();
        SFOMStripe_UpdatePIWithProductNames.InputParameters obj = new SFOMStripe_UpdatePIWithProductNames.InputParameters();
        //obj.foId=lstFO.id;
        obj.orderSummaryId = lstFO.orderSummaryId;
        objLst.add(obj);          
        SFOMStripe_UpdatePIWithProductNames.updatePaymentIntent(objLst);      
    }
    
    
   public class MockTaxService implements HttpCalloutMock {
       public httpResponse respond(HTTPrequest req) {
       HttpResponse res = new HttpResponse();
       res.setHeader('Content-Type', 'application/json');
       res.setStatusCode(200);
       res.setStatus('OK');
       res.setBody('{"data":{"trackingUrl":"https://tracking.Quest.com"}}');
       return res;
       }
  }
}