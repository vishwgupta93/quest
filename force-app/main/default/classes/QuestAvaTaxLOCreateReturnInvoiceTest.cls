@IsTest(SeeAllData=true)
public class QuestAvaTaxLOCreateReturnInvoiceTest {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message": "Success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testCreateTransaction() {
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
                
            List<FulfillmentOrder> fos = [SELECT Id from FulfillmentOrder where OrderSummaryId =: lstOS[0].Id];
            FulfillmentOrder fo = fos[0];
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
                        item.HRAReq__c=true;
                }
            
            update OrderItemLst;

        // Register mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Prepare input
        QuestAvaTaxLOCreateReturnInvoice.InputParameters input = new QuestAvaTaxLOCreateReturnInvoice.InputParameters();
        input.changeOrderId = newOrder.Id;
        input.isFullRefund= false;

        List<QuestAvaTaxLOCreateReturnInvoice.InputParameters> inputs = new List<QuestAvaTaxLOCreateReturnInvoice.InputParameters>{ input };

        System.Test.startTest();
        List<QuestAvaTaxLOCreateReturnInvoice.OutputParameters> results = QuestAvaTaxLOCreateReturnInvoice.createTransaction(inputs);
        System.Test.stopTest();

        // System.assertEquals(1, results.size(), 'Should return one output parameter');
        // System.assertEquals(200, results[0].statusCode, 'Expected HTTP 200 OK');
        // System.assertEquals(null, results[0].errorMessage, 'Error message should be null');
        // System.assertNotEquals(null, results[0].requestPayload, 'Request payload should not be null');
        // System.assertNotEquals(null, results[0].responsePayload, 'Response payload should not be null');
    }

   
}