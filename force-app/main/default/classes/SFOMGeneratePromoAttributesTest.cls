@IsTest 
public class SFOMGeneratePromoAttributesTest{
    
    
        public static Map<String,SObject> m_mapTestData = null;
    
   @IsTest (SeeAllData=true)
    static void SFOMGeneratePromoAttributesTest() {
    
         String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
        m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);
        
   
        OrderDeliveryGroup newOrderDeliveryGroupTest  = (OrderDeliveryGroup ) m_mapTestData.get('newOrderDeliveryGroup');
        System.debug('newOrderDeliveryGroupTest   ==>'+newOrderDeliveryGroupTest );  
            
        Order newOrder = (Order)m_mapTestData.get('newOrder');
        //System.assert(newOrder != null);
        
        // activate orders and create ordersummary objects        
        SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' ); 
        
        System.debug('******newOrder.status *******'+newOrder.status );
        
        
       // List<OrderSummary> lstOS = [SELECT Id, Status FROM OrderSummary where OriginalOrderId =:newOrder.Id ];
        List<OrderSummary> lstOS = [SELECT Id, Status FROM OrderSummary where OriginalOrderId=:newOrder.Id ];
        
        OrderSummary oOrderSummary = new OrderSummary();
        oOrderSummary  = lstOS[0];
        System.debug('lstOS ==>'+lstOS[0]);
        String orderSummaryId = oOrderSummary.Id;
        List<ID> lstOSID = new List<ID>();
         lstOSID.add(orderSummaryId);
        
        Test.StartTest();
       SFOMGeneratePromoAttributes.generatePromoAttributes(lstOSID);
       Test.stopTest();
    
    }
    
    }