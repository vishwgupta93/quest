@IsTest 
public class SFOMAvaTax_CreateTransactionTest {
    
    
        public static Map<String,SObject> m_mapTestData = null;
    
   @IsTest (SeeAllData=true)
    static void SFOMAvaTax_CreateTransactionTest () {
    
       Test.setMock(HttpCalloutMock.class, new MockTaxService()); 
        
        
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
        
        System.debug('******newOrder.status *******'+newOrder.status );
        
       // List<OrderSummary> lstOS = [SELECT Id, Status FROM OrderSummary where OriginalOrderId =:newOrder.Id ];
        List<OrderSummary> lstOS = [SELECT Id, Status FROM OrderSummary where OriginalOrderId=:newOrder.Id ];
     //   System.assert(!lstOS.isEmpty());
        OrderSummary oOrderSummary = new OrderSummary();
        oOrderSummary  = lstOS[0];
        oOrderSummary.isTaxEstimated__c = true;
        update oOrderSummary;
        System.debug('lstOS ==>'+lstOS[0]);
        String orderSummaryId = oOrderSummary.Id;
        
        OrderSummary oSummary = [Select Id, OrderedDate,isTaxEstimated__c ,BillingEmailAddress, BillingStreet,BillingCity,BillingCountry,BillingPostalCode,BillingState, OrderNumber from OrderSummary where Id = : orderSummaryId];
        OrderDeliveryGroupSummary odgs1 = [SELECT DeliverToCity,DeliverToCountry,DeliverToPostalCode,DeliverToState,DeliverToStreet FROM OrderDeliveryGroupSummary where OrderSummaryId =:orderSummaryId limit 1];
         List<OrderItemSummary>  oItemSummaryLst  =  [Select Id, quantity,TotalPrice, ProductCode, Description from OrderItemSummary where OrderSummaryId=:orderSummaryId order by LineNumber asc];
                
         Test.StartTest();
         List<SFOMAvaTax_CreateTransaction.InputParameters> objLst = new List<SFOMAvaTax_CreateTransaction.InputParameters>();
         SFOMAvaTax_CreateTransaction.InputParameters obj = new SFOMAvaTax_CreateTransaction.InputParameters();
         obj.orderSummaryId = oOrderSummary.Id;
         objLst.add(obj);
         SFOMAvaTax_CreateTransaction.createTransaction(objLst);         
         Test.stopTest();   
      
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