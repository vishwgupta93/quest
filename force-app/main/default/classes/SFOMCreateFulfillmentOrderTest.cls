@IsTest
public class SFOMCreateFulfillmentOrderTest {
          
  public static Map<String,SObject> m_mapTestData = null;
    
   @IsTest (SeeAllData=true)
    static void SFOMCreateFOTest () {
        
        String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
 
        m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);       
        OrderDeliveryGroup newOrderDeliveryGroupTest  = (OrderDeliveryGroup ) m_mapTestData.get('newOrderDeliveryGroup');
            
        Order newOrder = (Order)m_mapTestData.get('newOrder');    
        SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' );                      
        List<OrderSummary> lstOS = [SELECT Id, Status , OrderNumber FROM OrderSummary where OriginalOrderId=:newOrder.Id ];
               
        SFOMCreateFulfillmentOrder.InputParameters obj = new SFOMCreateFulfillmentOrder.InputParameters();        
        obj.orderSummaryId = lstOS[0].Id;     
        List<SFOMCreateFulfillmentOrder.InputParameters> objLst = new List<SFOMCreateFulfillmentOrder.InputParameters>();
        objLst.add(obj);    
        SFOMCreateFulfillmentOrder.createTransaction(objLst); 
        
        List<Id> oSumIdLst = new List<Id>();
        oSumIdLst.add(lstOS[0].Id);
           
        FulfillmentOrder fo = [SELECT Id from FulfillmentOrder where OrderSummaryId =: lstOS[0].Id];
        fo.status = 'Pending Approval';                                                
        update fo;
        
        List<OrderItemSummary> OrderItemLst = [SELECT Id, TestType__c  from OrderItemSummary where OrderSummaryId IN :oSumIdLst and Type!='Delivery Charge'];
                                                                                                       
        //System.debug('foLineItemLst :::::' +foLineItemLst);
        for(OrderItemSummary item :OrderItemLst){       
           item.TestType__c='PSC';
        }
        
        update OrderItemLst;
        SFOMSetOrderAttributes.copyOrderAttributes(oSumIdLst);                  
    }
}