@IsTest 
public class SFOMAvaTaxCaseCreationHelperTest {
    @IsTest(seeAllData = true)
    static void test_success(){
        FulfillmentOrder fo = getFO();
        SFOMAvaTaxCaseCreationHelper.InputParameters inputs = new SFOMAvaTaxCaseCreationHelper.InputParameters();
        inputs.foId = fo.Id;
        inputs.OrderSummaryId = fo.OrderSummaryId;
        inputs.errorMsg = 'Testing error message';
        
        SFOMAvaTaxCaseCreationHelper.createTransaction(new List<SFOMAvaTaxCaseCreationHelper.InputParameters>{inputs});
        
        List<Case> c = new List<Case>([select Id, subject from Case where Subject = 'Avalara Tax Calculation Error']);
        System.debug('cases = '+c);
        Assert.isNotNull(c);
        
    }
    private static FulfillmentOrder getFO()
    {
        // Test data setup
        String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
        
        Map<String,SObject> m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);       
        
        Order newOrder = (Order)m_mapTestData.get('newOrder');    
        SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' );                      
        List<OrderSummary> lstOS = [SELECT Id FROM OrderSummary where OriginalOrderId=:newOrder.Id ];
        
        // System.assert(!lstOS.isEmpty());
        OrderSummary oOrderSummary = new OrderSummary();
        oOrderSummary  = lstOS[0];
        System.debug('lstOS ==>'+lstOS[0]);
        String orderSummaryId = oOrderSummary.Id;
        List<ID> lstOSID = new List<ID>();
        lstOSID.add(orderSummaryId);
        
        System.debug('******oOrderSummary *******'+oOrderSummary );
        
        List<OrderDeliveryGroupSummary> lstODGS = [SELECT Id, OrderSummaryId FROM OrderDeliveryGroupSummary where OrderSummaryId=:oOrderSummary.Id ];
        System.debug('******lstODGS  *******'+lstODGS  );
        
        
        Schema.Location location = (Schema.Location) m_mapTestData.get('newLocationUSCE');
        
        
        SFOMCreateFulfillmentOrder.InputParameters obj = new SFOMCreateFulfillmentOrder.InputParameters();        
        obj.orderSummaryId = lstOS[0].Id;     
        List<SFOMCreateFulfillmentOrder.InputParameters> objLst = new List<SFOMCreateFulfillmentOrder.InputParameters>();
        objLst.add(obj);    
        SFOMCreateFulfillmentOrder.createTransaction(objLst); 
        
        List<Id> oSumIdLst = new List<Id>();
        oSumIdLst.add(lstOS[0].Id);
        
        FulfillmentOrder fo = [SELECT Id, OrderSummaryId from FulfillmentOrder where OrderSummaryId =: lstOS[0].Id limit 1];
        fo.RecordTypeId=Label.SFOM_In_Person_Record_Type_Id;
        fo.Status = 'Pending Approval';
        fo.LastName__c ='Test';
        fo.FirstName__c ='Test';
        fo.Physician_First_Name__c='Test';
        fo.Physician_Last_Name__c='Test';
        fo.Physician_Npi__c='121212';
        fo.Physician_Upin__c='121121';
        fo.PWN_ID__c='12121';
        
        update fo;
        
        List<OrderItemSummary> OrderItemLst = [SELECT Id, TestType__c  from OrderItemSummary where OrderSummaryId IN :oSumIdLst and Type!='Delivery Charge'];
        for(OrderItemSummary item :OrderItemLst){       
            item.TestType__c='PSC';
        }
        
        update OrderItemLst;
        PaymentAuthorization auth = (PaymentAuthorization) m_mapTestData.get('paymentAuth');
        System.debug('auth'+auth);
        ConnectApi.CreateOrderPaymentSummaryInputRepresentation orderPaymentSummaryInput = new ConnectApi.CreateOrderPaymentSummaryInputRepresentation();
        orderPaymentSummaryInput.orderSummaryId = fo.OrderSummaryId ;
        orderPaymentSummaryInput.paymentAuthorizationId = auth.Id;
        
        ConnectApi.CreateOrderPaymentSummaryOutputRepresentation opos= ConnectAPI.OrderPaymentSummary.createOrderPaymentSummary(orderPaymentSummaryInput);
        
        
        return fo;
    }
    
}