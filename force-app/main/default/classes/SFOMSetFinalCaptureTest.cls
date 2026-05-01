@IsTest
public class SFOMSetFinalCaptureTest {
          
  public static Map<String,SObject> m_mapTestData = null;
    
   @IsTest (SeeAllData=true)
    static void SFOMSetFinalCapture () {
        
        String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
 
        m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);       
        OrderDeliveryGroup newOrderDeliveryGroupTest  = (OrderDeliveryGroup ) m_mapTestData.get('newOrderDeliveryGroup');
            
        Order newOrder = (Order)m_mapTestData.get('newOrder');    
        SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' );                      
        List<OrderSummary> lstOS = [SELECT Id, Status , OrderNumber FROM OrderSummary where OriginalOrderId=:newOrder.Id ];
               
        SFOMSetFinalCapture.InputParameters obj = new SFOMSetFinalCapture.InputParameters();        
        obj.orderSummaryId = lstOS[0].Id;    
        obj.paymentAuthorizationId ='xyz';
        List<SFOMSetFinalCapture.InputParameters> objLst = new List<SFOMSetFinalCapture.InputParameters>();
        objLst.add(obj);    
        SFOMSetFinalCapture.createShipment(objLst); 
                
    }
}