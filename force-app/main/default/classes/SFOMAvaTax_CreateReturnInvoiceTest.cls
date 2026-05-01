@IsTest 
public class SFOMAvaTax_CreateReturnInvoiceTest  {
    
    
        public static Map<String,SObject> m_mapTestData = null;
    
   @IsTest (SeeAllData=true)
    static void SFOMAvaTax_CreateReturnInvoiceTest  () {
    
       Test.setMock(HttpCalloutMock.class, new MockTaxService()); 
        
        
        String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
        m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);
        
   
         OrderDeliveryGroup newOrderDeliveryGroupTest  = (OrderDeliveryGroup ) m_mapTestData.get('newOrderDeliveryGroup');
         System.debug('newOrderDeliveryGroupTest   ==>'+newOrderDeliveryGroupTest );  
            
        Order newOrder = (Order)m_mapTestData.get('newOrder');
     //   System.assert(newOrder != null);
        
        
        
        // activate orders and create ordersummary objects        
        SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' ); 
        
        System.debug('******newOrder.status *******'+newOrder.status );
        
        
       // List<OrderSummary> lstOS = [SELECT Id, Status FROM OrderSummary where OriginalOrderId =:newOrder.Id ];
        List<OrderSummary> lstOS = [SELECT Id, Status FROM OrderSummary where OriginalOrderId=:newOrder.Id ];
      //  System.assert(!lstOS.isEmpty());
        OrderSummary oOrderSummary = new OrderSummary();
        oOrderSummary  = lstOS[0];
        System.debug('oOrderSummary.Id==>'+oOrderSummary.Id );
        
      /*
         Below logic used to prepare and call the OrderSummary.submitCancel API
         public static ConnectApi.SubmitCancelOutputRepresentation submitCancel(String orderSummaryId, ConnectApi.ChangeInputRepresentation changeInput)  
         ConnectApi.SubmitCancelOutputRepresentation >> changeBalances and changeOrderId
      */


        List<OrderItemSummary> lstOIS = null;
        // AND Product2.ProductCode = 'SKU1'
       
       // Return one item
        lstOIS = [SELECT Id, OriginalOrderItemId, Product2Id, Product2.ProductCode, UnitPrice, Quantity FROM OrderItemSummary WHERE OrderSummaryId = :oOrderSummary.Id and ProductCode != 'Shipping'];
      //  System.assert(!lstOIS.isEmpty());
        ConnectApi.ChangeInputRepresentation changeInputRep = new ConnectApi.ChangeInputRepresentation();
        changeInputRep.changeItems = new List<ConnectApi.ChangeItemInputRepresentation>();
        ConnectApi.ChangeItemInputRepresentation changeItem = new ConnectApi.ChangeItemInputRepresentation();
        changeItem.orderItemSummaryId = lstOIS[0].Id;
        changeItem.quantity = lstOIS[0].Quantity;
        changeItem.reason = 'Unknown'; 
        changeItem.shippingReductionFlag = false; 
        changeInputRep.changeItems.add(changeItem);
        
        System.debug('oOrderSummary.Id==>'+oOrderSummary.Id );
        System.debug('changeInputRep ==>'+changeInputRep);
        
        ConnectApi.SubmitCancelOutputRepresentation  osscor = ConnectApi.OrderSummary.submitCancel(oOrderSummary.Id, changeInputRep);
        System.debug('osscor >'+osscor);
    
     
        List<SFOMAvaTax_CreateReturnInvoice.InputParameters> objLst = new List<SFOMAvaTax_CreateReturnInvoice.InputParameters>();
        SFOMAvaTax_CreateReturnInvoice.InputParameters obj = new SFOMAvaTax_CreateReturnInvoice.InputParameters();
        obj.changeOrderId =osscor.changeOrderId;
        objLst.add(obj);       
        SFOMAvaTax_CreateReturnInvoice.createTransaction(objLst); 
      
    }
    
    
    public class MockTaxService implements HttpCalloutMock {
   public httpResponse respond(HTTPrequest req) {
   System.debug('Welcome MockTaxService ==> Start');
   HttpResponse res = new HttpResponse();
   res.setHeader('Content-Type', 'application/json');
   res.setStatusCode(200);
   res.setStatus('OK');
   res.setBody('{"data":{"trackingUrl":"https://tracking.beta.trexity.com"}}');
   System.debug('Welcome MockTaxService ==> End');
   return res;
   }
  }
}