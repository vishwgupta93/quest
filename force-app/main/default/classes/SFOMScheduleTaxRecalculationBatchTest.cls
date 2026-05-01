@IsTest
public class SFOMScheduleTaxRecalculationBatchTest {
    
    
        public static Map<String,SObject> m_mapTestData = null;
    
    @TestSetup
    static void setup() {
        String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
       // m_mapTestData = SFOMTestDataFactory.initData(salesChannel, currencyIsoCode);  
       m_mapTestData = SFOMTestDataFactory.initData(salesChannel,  orderTypeCode, currencyIsoCode , MerchantID) ;
        Order newOrder = (Order)m_mapTestData.get('newOrder');
        //System.assert(newOrder != null);
        
        System.debug('Order ==>'+newOrder );
        
        // activate orders and create ordersummary objects        
       // SFOMTestDataFactory.activateOrders(); 
        SFOMTestDataFactory.activateOrders(); 
        
        List<OrderSummary> lstOS = [SELECT Id, Status FROM OrderSummary];
      //  System.assert(!lstOS.isEmpty());
        
        System.debug('OrderSummary ==>'+lstOS[0]);
    }
    
  
    @IsTest 
    static void ScheduleTaxRecalculationBatchTest() {
      List<OrderSummary> lstOS = [SELECT Id, OriginalOrderId , Status FROM OrderSummary];
        // System.assert(!lstOS.isEmpty());
        
        OrderSummary oOrderSummary = lstOS[0];
        oOrderSummary.isTaxEstimated__c = true;
        update oOrderSummary;
        
        System.debug('Inside  ScheduleTaxRecalculationBatchTest ==>'+lstOS[0]);
          
        SFOMScheduleTaxRecalculationBatch testsche = new SFOMScheduleTaxRecalculationBatch();
        String sch = '0 0 23 * * ?';
        Test.startTest();
        system.schedule('Test status Check', sch, testsche );
        Test.stopTest();
    }
}