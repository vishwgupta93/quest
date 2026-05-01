@IsTest(SeeAllData=true)
public with sharing class EOSTNotificationScheduleTest {
     
       
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
           fo.FulfilledToAddressLine1__c = '123 Street';
    
           update fo;
           
           List<OrderItemSummary> OrderItemLst = [SELECT Id, TestType__c  from OrderItemSummary where OrderSummaryId IN :oSumIdLst and Type!='Delivery Charge'];
        for(OrderItemSummary item :OrderItemLst){       
                item.TestType__c='PSC';
        }
     
     update OrderItemLst;
    
        OrderSummary oOrderSummary1 = new OrderSummary();
        oOrderSummary1  = lstOS[0];
        oOrderSummary1.Partner_Name__c='Quest';
    
        update oOrderSummary1;
    
       
           return fo;
        }
    
        @IsTest(SeeAllData=true)
        static void testFormNotificationDetail() {
            Test.startTest();
    
            FulfillmentOrder fo = getFO();

            List<FulfillmentOrderLineItem> foLines = [select Id,ProductCode__c from FulfillmentOrderLineItem where FulfillmentOrderId =: fo.Id and Test_Type__c = 'PSC'];
            String testCode = '';
            if(!foLines.isEmpty())
            {
                testCode = foLines[0].ProductCode__c;
            }
    
                // Insert test data for Kit_Details__c
            Kit_Details__c kit = new Kit_Details__c(Activation_Code__c='KITREF1234', Item_Code__c='334');
            insert kit;
    
            JSONGenerator gen = JSON.createGenerator(true);
            
            gen.writeStartObject();
            gen.writeNumberField('version', 2);
            
            gen.writeFieldName('event');
            gen.writeStartObject();
            gen.writeStringField('eventType', 'requisitionStatusChanged');
            gen.writeStringField('eostRequisitionUuid', '91946ca1-aab6-4fc4-a7df-b33810f1223f');
            gen.writeStringField('dateOfService', '2023-12-08T16:05:11Z');
            gen.writeStringField('internalRequistionNumber', '0131850');
            gen.writeStringField('accessionNumber', 'Ny991311T');
            gen.writeStringField('performingSite', 'TPH');
            gen.writeStringField('clientAccountNumber', '97554902');
            gen.writeStringField('labRefID',String.valueOf(fo.Id).toUpperCase() );
            gen.writeStringField('PID', '20220912140334704259');
            gen.writeNumberField('statusCode', 4);
            gen.writeStringField('statusDesc', 'ResultedFinal');
            gen.writeStringField('notificationUuid', '8e7363e5-82c8-4580-a68f-bdd3afa1f369');
            gen.writeStringField('dateOfCollection', '2023-12-08T00:00:00.000+00:00');
            gen.writeStringField('dateReported', '2023-12-08T14:40:52.000+00:00');
            
            gen.writeFieldName('patient');
            gen.writeStartObject();
            gen.writeStringField('patientLastName', 'CIT');
            gen.writeStringField('patientFirstName', 'ARTHI');
            gen.writeStringField('patientGender', 'F');
            gen.writeStringField('patientDateOfBirth', '1985-08-05');
            gen.writeEndObject(); // End patient
            
            gen.writeFieldName('provider');
            gen.writeStartObject();
            gen.writeStringField('providerLastName', 'PHYSICIAN KS');
            gen.writeStringField('providerFirstName', 'STAGING');
            gen.writeStringField('providerId', '1144272949');
            gen.writeEndObject(); // End provider
            
            gen.writeFieldName('orderedTests');
            gen.writeStartArray();
            gen.writeStartObject();
            gen.writeBooleanField('reflexTest', false);
            gen.writeStringField('statusCode', 'resulted-final');
            gen.writeStringField('testCode', testCode);
            gen.writeStringField('testCodeDescription', 'TOTAL CHOLESTEROL TEST');
            gen.writeEndObject(); // End orderedTests array element
            gen.writeEndArray(); // End orderedTests
            
            gen.writeEndObject(); // End event
            
            gen.writeEndObject();
    
            String pscString = gen.getAsString();
    
            JSONGenerator gen1 = JSON.createGenerator(true);
            
            gen1.writeStartObject();
            gen1.writeNumberField('version', 2);
            
            gen1.writeFieldName('event');
            gen1.writeStartObject();
            gen1.writeStringField('eventType', 'requisitionStatusChanged');
            gen1.writeStringField('eostRequisitionUuid', '91946ca1-aab6-4fc4-a7df-b33810f1223f');
            gen1.writeStringField('dateOfService', '2023-12-08T16:05:11Z');
            gen1.writeStringField('internalRequistionNumber', '0131850');
            gen1.writeStringField('accessionNumber', 'Ny991311T');
            gen1.writeStringField('performingSite', 'TPH');
            gen1.writeStringField('clientAccountNumber', '97554902');
            gen1.writeStringField('labRefID','KITREF1234' );
            gen1.writeStringField('PID', '20220912140334704259');
            gen1.writeNumberField('statusCode', 4);
            gen1.writeStringField('statusDesc', 'ResultedFinal');
            gen1.writeStringField('notificationUuid', '8e7363e5-82c8-4580-a68f-bdd3afa1f369');
            gen1.writeStringField('dateOfCollection', '2023-12-08T00:00:00.000+00:00');
            gen1.writeStringField('dateReported', '2023-12-08T14:40:52.000+00:00');
            
            gen1.writeFieldName('patient');
            gen1.writeStartObject();
            gen1.writeStringField('patientLastName', 'CIT');
            gen1.writeStringField('patientFirstName', 'ARTHI');
            gen1.writeStringField('patientGender', 'F');
            gen1.writeStringField('patientDateOfBirth', '1985-08-05');
            gen1.writeEndObject(); // End patient
            
            gen1.writeFieldName('provider');
            gen1.writeStartObject();
            gen1.writeStringField('providerLastName', 'PHYSICIAN KS');
            gen1.writeStringField('providerFirstName', 'STAGING');
            gen1.writeStringField('providerId', '1144272949');
            gen1.writeEndObject(); // End provider
            
            gen1.writeFieldName('orderedTests');
            gen1.writeStartArray();
            gen1.writeStartObject();
            gen1.writeBooleanField('reflexTest', false);
            gen1.writeStringField('statusCode', 'resulted-final');
            gen1.writeStringField('testCode', '334');
            gen1.writeStringField('testCodeDescription', 'TOTAL CHOLESTEROL TEST');
            gen1.writeEndObject(); // End orderedTests array element
            gen1.writeEndArray(); // End orderedTests
            
            gen1.writeEndObject(); // End event
            
            gen1.writeEndObject();
    
            String kitString = gen1.getAsString();
    
            List<EOST_OMS_Log__c> logs = new List<EOST_OMS_Log__c>();
            logs.add(new EOST_OMS_Log__c(
                Batch_ID__c = 'batch1',
                Reference_ID__c = String.valueOf(fo.Id).toUpperCase() ,
                EOST_Payload__c = pscString,
                Batch_Status__c='Open'
            ));
            logs.add(new EOST_OMS_Log__c(
                Batch_ID__c = 'batch1',
                Reference_ID__c = 'KITREF1234',
                EOST_Payload__c = kitString,
                Batch_Status__c='Open'
            ));
            insert logs;
                    
            // Call the method
            EOSTOMSNotificationTranslator.formNotificationDetail('batch1');
            
            Test.stopTest();
    
            // Verify the results
            List<EOST_OMS_Notification_Detail__c> details = [SELECT Id, Fulfillment_Order_Product__c, Fulfillment_Order__c, Order_Summary__c, Is_PSC__c, IS_Kit__c, Kit_Detail__c FROM EOST_OMS_Notification_Detail__c];
            System.assert(!details.isEmpty(), 'Notification Details should not be empty');
    
            List<EOST_OMS_Log__c> logss = [SELECT Id, Batch_Status__c, Order_Summary__c, Fulfillment_Order__c, Kit_Detail__c FROM EOST_OMS_Log__c WHERE Batch_ID__C = 'batch1'];
            for (EOST_OMS_Log__c log : logss) {
                System.assertEquals('Processed', log.Batch_Status__c, 'Log Batch Status should be Processed');
            }
        }
}