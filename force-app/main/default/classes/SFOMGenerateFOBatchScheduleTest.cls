@IsTest 
public class SFOMGenerateFOBatchScheduleTest {
    
    
        public static Map<String,SObject> m_mapTestData = null;
    
   @IsTest
    static void SFOMGenerateFOBatchScheduleTest () {
        
        String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
 
        m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);
                          
        Order newOrder = (Order)m_mapTestData.get('newOrder');
        System.assert(newOrder != null);
       
        System.debug('Order ==>'+newOrder );
        
        
        
        // activate orders and create ordersummary objects        
        SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' ); 
        // SFOMTestDataFactory.activateOrders(); 
        
        System.debug('******newOrder.status *******'+newOrder.status );
        
        
        List<OrderSummary> lstOS = [SELECT Id, Status , OrderNumber , OrderedDate FROM OrderSummary where OriginalOrderId=:newOrder.Id ];
        System.assert(!lstOS.isEmpty());
       
        OrderSummary oOrderSummary = new OrderSummary();
        oOrderSummary  = lstOS[0];
        System.debug('lstOS ==>'+lstOS[0]);
        oOrderSummary.Status= 'Pending';
        update oOrderSummary;
        
        
        System.debug('Inside  SFOMGenerateFOBatchScheduleTest Status ==>'+oOrderSummary.Status);
        System.debug('Inside  SFOMGenerateFOBatchScheduleTest  Date ==>'+oOrderSummary.OrderedDate);
        
              
        SFOMGenerateFOBatchSchedule testsche = new SFOMGenerateFOBatchSchedule();
        String sch = '0 0 23 * * ?';
        
        Test.startTest();
        system.schedule('Test status Check', sch, testsche );
        Test.stopTest();

    }
}