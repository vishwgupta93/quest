@IsTest(SeeAllData=true)
public with sharing class QuestECOMShipmentPayloadTest {
   public static Map<String,String> inputIds= getFO();

    private class MockHttpResponseGeneratorSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

             Dom.Document doc = new Dom.Document();
        
        // Create the root element
        Dom.XmlNode root = doc.createRootElement('ShippingConfirmations', null, null);
        
        // Create the ShippingConfirmation element
        Dom.XmlNode shippingConfirmation = root.addChildElement('ShippingConfirmation', null, null);
        shippingConfirmation.setAttribute('OrderNumber', inputIds.get('foId'));
        shippingConfirmation.setAttribute('Shipper', 'J9UIU3');
        shippingConfirmation.setAttribute('ShipVia', 'FedEx Home Delivery');
        shippingConfirmation.setAttribute('ShipDate', '2024-03-04');
        shippingConfirmation.setAttribute('ClientID', '20231121155346746192');
        
        // Create the Tracking element
        Dom.XmlNode tracking = shippingConfirmation.addChildElement('Tracking', null, null);
        tracking.addTextNode('126191291261929');
        
        // Create the Item element
        Dom.XmlNode item = shippingConfirmation.addChildElement('Item', null, null);
        item.setAttribute('ItemNumber', '39751');
        item.setAttribute('LotNumber', 'I85Q6-03/31/2024');
        item.setAttribute('SerialNumber', 'QB021B8UI');
        item.setAttribute('ExpireDate', '2024-03-31');
        item.setAttribute('ShippedQty', '1');
        item.setAttribute('GLCode', inputIds.get('lineId'));
        item.setAttribute('LineNumber', '000001');
        
        // Create the TubeSerial element
        Dom.XmlNode tubeSerial = item.addChildElement('TubeSerial', null, null);
        tubeSerial.setAttribute('VerificationId', 'ZIMDP');
        tubeSerial.addTextNode('CITW1V791T2');
        
        // Create the ReturnTracking element
        Dom.XmlNode returnTracking = item.addChildElement('ReturnTracking', null, null);
        returnTracking.addTextNode('796645970318');

        JSONGenerator gen = JSON.createGenerator(true);
        
        gen.writeStartObject();
        gen.writeBooleanField('success', true);
        gen.writeFieldName('dataArray');
        gen.writeStartArray();
        
        // First data object
        gen.writeStartObject();
        gen.writeStringField('format', 'xml');
        gen.writeStringField('data', doc.toXmlString());
        gen.writeEndObject();
        
        gen.writeEndArray();
        gen.writeEndObject();

        HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody(gen.getAsString());
            return res;

        }
    }

    private class MockHttpResponseGeneratorFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('{"success":false}');
            return res;
        }
    }

    private class MockHttpResponseGeneratorCheckError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('');
            return res;
        }
    }

    private class PROOVMockHttpResponseGeneratorSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

             JSONGenerator gen = JSON.createGenerator(true);
        
        gen.writeStartObject(); // Start main object
        gen.writeFieldName('shipments');
        gen.writeStartArray(); // Start shipments array

        gen.writeStartObject(); // Start shipment object
        
        gen.writeStringField('shipmentId', '82205212103');
        gen.writeStringField('orderId', '12511212371037');
        gen.writeStringField('orderKey', '1666ca27d53b46ad9e6ea4e5ee592878');
        gen.writeStringField('userId', 'fae40f2f-e002-4b6c-b8ee-3e56ad05f6ec');
        gen.writeStringField('customerEmail', 'sk@gmail.com');
        gen.writeStringField('orderNumber', inputIds.get('foId'));
        gen.writeStringField('createDate', '2025-01-13T09:18:32.0430000');
        gen.writeStringField('shipDate', '2025-01-13');
        gen.writeNumberField('shipmentCost', 4.58);
        gen.writeNumberField('insuranceCost', 0.00);
        gen.writeStringField('trackingNumber', '9400111105502138833148');
        gen.writeBooleanField('isReturnLabel', false);
        gen.writeStringField('batchNumber', '145071');
        gen.writeStringField('carrierCode', 'stamps_com');
        gen.writeStringField('serviceCode', 'usps_first_class_mail');
        gen.writeNullField('packageCode');
        gen.writeNullField('confirmation');
        gen.writeNumberField('warehouseId', 643358);
        gen.writeBooleanField('voided', false);
        gen.writeNullField('voidDate');
        gen.writeBooleanField('marketplaceNotified', false);
        gen.writeNullField('notifyErrorMessage');

        gen.writeFieldName('shipTo');
        gen.writeStartObject();
        gen.writeStringField('name', 'Raisa Baranova');
        gen.writeNullField('company');
        gen.writeStringField('street1', '112 CONNEMARA DR');
        gen.writeStringField('street2', '');
        gen.writeNullField('street3');
        gen.writeStringField('city', 'STERLING');
        gen.writeStringField('state', 'VA');
        gen.writeStringField('postalCode', '20164-3545');
        gen.writeStringField('country', 'US');
        gen.writeStringField('phone', '7036297159');
        gen.writeNullField('residential');
        gen.writeNullField('addressVerified');
        gen.writeEndObject(); // End shipTo object

        gen.writeFieldName('weight');
        gen.writeStartObject();
        gen.writeNumberField('value', 2.00);
        gen.writeStringField('units', 'ounces');
        gen.writeNumberField('WeightUnits', 1);
        gen.writeEndObject(); // End weight object

        gen.writeFieldName('dimensions');
        gen.writeStartObject();
        gen.writeStringField('units', 'inches');
        gen.writeNumberField('length', 9.00);
        gen.writeNumberField('width', 6.00);
        gen.writeNumberField('height', 2.00);
        gen.writeEndObject(); // End dimensions object

        gen.writeFieldName('insuranceOptions');
        gen.writeStartObject();
        gen.writeNullField('provider');
        gen.writeBooleanField('insureShipment', false);
        gen.writeNumberField('insuredValue', 0.0);
        gen.writeEndObject(); // End insuranceOptions object

        gen.writeFieldName('advancedOptions');
        gen.writeStartObject();
        gen.writeStringField('billToParty', '4');
        gen.writeNullField('billToAccount');
        gen.writeNullField('billToPostalCode');
        gen.writeNullField('billToCountryCode');
        gen.writeNumberField('storeId', 424577);
        gen.writeEndObject(); // End advancedOptions object

        gen.writeNullField('shipmentItems');
        gen.writeNullField('labelData');
        gen.writeNullField('formData');

        gen.writeEndObject(); // End shipment object
        gen.writeEndArray(); // End shipments array

        gen.writeNumberField('total', 1);
        gen.writeNumberField('page', 1);
        gen.writeNumberField('pages', 1);
        
        gen.writeEndObject(); // End main object

        HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody(gen.getAsString());
            return res;

        }
    }

    private class PROOVMockHttpResponseGeneratorFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('{"success":false}');
            return res;
        }
    }

    private class PROOVMockHttpResponseGeneratorCheckError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('');
            return res;
        }
    }

    @IsTest (SeeAllData=true)
    static void validateGBFShipmentConfirmScheduleResponse_Failure()
    {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorFailure());
        Test.startTest();
        QuestTPTShipmentBatch btch= new QuestTPTShipmentBatch();
        btch.status = 'Order Acknowledged';
        btch.Id=inputIds.get('foId');
        btch.query = 'SELECT Id, OrderSummaryId,Location_Name__c FROM FulfillmentOrder WHERE Status =: status and Id =: id ';
        Database.executeBatch(btch,1);
        Test.stopTest();
    }

    @IsTest (SeeAllData=true)
    static void validateGBFShipmentConfirmScheduleResponse_Exception()
    {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorCheckError());
        Test.startTest();
        QuestTPTShipmentBatch btch= new QuestTPTShipmentBatch();
        btch.status = 'Order Acknowledged';
        btch.Id=inputIds.get('foId');
        btch.query = 'SELECT Id, OrderSummaryId,Location_Name__c FROM FulfillmentOrder WHERE Status =: status and Id =: id ';
        Database.executeBatch(btch,1);
        Test.stopTest();
    }



    @IsTest (SeeAllData=true)
    static void validateGBFShipmentConfirmScheduleResponse_Success()
    {
        

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());
        Test.startTest();
       

        QuestTPTShipmentBatch btch= new QuestTPTShipmentBatch();
        btch.status = 'Order Acknowledged';
        btch.Id=inputIds.get('foId');
        btch.query = 'SELECT Id, OrderSummaryId,Location_Name__c FROM FulfillmentOrder WHERE Status =: status and Id =: id ';
        Database.executeBatch(btch,1);
        Test.stopTest();
        
    }

    @IsTest (SeeAllData=true)
    static void validatePROOVShipmentConfirmScheduleResponse_Failure()
    {
        Schema.Location loc = new Schema.Location();
            loc.Name =  'PROOV';
            loc.LocationType = 'Warehouse';
            loc.ShouldSyncWithOci = true;
            loc.ExternalReference = 'PROOV_Test';
            insert loc;

            FulfillmentOrder fo = new FulfillmentOrder();
            fo.Id=inputIds.get('foId');
            fo.FulfilledFromLocationId=loc.Id;

            update fo;  

        Test.setMock(HttpCalloutMock.class, new PROOVMockHttpResponseGeneratorFailure());
        Test.startTest();
        QuestTPTShipmentBatch btch= new QuestTPTShipmentBatch();
        btch.status = 'Order Acknowledged';
        btch.Id=inputIds.get('foId');
        btch.query = 'SELECT Id, OrderSummaryId,Location_Name__c FROM FulfillmentOrder WHERE Status =: status and Id =: id ';
        Database.executeBatch(btch,1);
        Test.stopTest();
    }

    @IsTest (SeeAllData=true)
    static void validatePROOVShipmentConfirmScheduleResponse_Exception()
    {
        Schema.Location loc = new Schema.Location();
            loc.Name =  'PROOV';
            loc.LocationType = 'Warehouse';
            loc.ShouldSyncWithOci = true;
            loc.ExternalReference = 'PROOV_Test';
            insert loc;

            FulfillmentOrder fo = new FulfillmentOrder();
            fo.Id=inputIds.get('foId');
            fo.FulfilledFromLocationId=loc.Id;

            update fo;  

        Test.setMock(HttpCalloutMock.class, new PROOVMockHttpResponseGeneratorCheckError());
        Test.startTest();
        QuestTPTShipmentBatch btch= new QuestTPTShipmentBatch();
        btch.status = 'Order Acknowledged';
        btch.Id=inputIds.get('foId');
        btch.query = 'SELECT Id, OrderSummaryId,Location_Name__c FROM FulfillmentOrder WHERE Status =: status and Id =: id ';
        Database.executeBatch(btch,1);
        Test.stopTest();
    }



    @IsTest (SeeAllData=true)
    static void validatePROOVShipmentConfirmScheduleResponse_Success()
    {
            Schema.Location loc = new Schema.Location();
            loc.Name =  'PROOV';
            loc.LocationType = 'Warehouse';
            loc.ShouldSyncWithOci = true;
            loc.ExternalReference = 'PROOV_Test';
            insert loc;

            FulfillmentOrder fo = new FulfillmentOrder();
            fo.Id=inputIds.get('foId');
            fo.FulfilledFromLocationId=loc.Id;

            update fo;  

        Test.setMock(HttpCalloutMock.class, new PROOVMockHttpResponseGeneratorSuccess());
        Test.startTest();
        
        QuestTPTShipmentBatch btch= new QuestTPTShipmentBatch();
        btch.status = 'Order Acknowledged';
        btch.Id=inputIds.get('foId');
        btch.query = 'SELECT Id, OrderSummaryId,Location_Name__c FROM FulfillmentOrder WHERE Status =: status and Id =: id ';
        Database.executeBatch(btch,1);
        Test.stopTest();
        
    }
    


    private static Map<String,String> getFO()
    {

        Map<String,String> inputs= new Map<String,String>();
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

    
            Schema.Location loc = new Schema.Location();
            loc.Name =  'GBF';
            loc.LocationType = 'Warehouse';
            loc.ShouldSyncWithOci = true;
            loc.ExternalReference = 'GBF_Test';
            insert loc;
    
    List<OrderItemSummary> OrderItemLst = [SELECT Id, TestType__c  from OrderItemSummary where OrderSummaryId IN :lstOSID and Type!='Delivery Charge'];
    for(OrderItemSummary item :OrderItemLst){       
            item.TestType__c='at_home';
    }
 
 update OrderItemLst;
    

    SFOMCreateFulfillmentOrder.InputParameters obj = new SFOMCreateFulfillmentOrder.InputParameters();        
    obj.orderSummaryId = lstOS[0].Id;     
    List<SFOMCreateFulfillmentOrder.InputParameters> objLst = new List<SFOMCreateFulfillmentOrder.InputParameters>();
    objLst.add(obj);    
    SFOMCreateFulfillmentOrder.createTransaction(objLst); 

  List<Id> oSumIdLst = new List<Id>();
  oSumIdLst.add(lstOS[0].Id);
     
  List<FulfillmentOrder> fos = [SELECT Id from FulfillmentOrder where OrderSummaryId =: lstOS[0].Id];
  FulfillmentOrder fo = fos[0];
  fo.RecordTypeId=Label.SFOM_OTC_Cleared_Record_Type_Id;
       fo.Status = 'Order Acknowledged';
       fo.LastName__c ='Test';
       fo.FirstName__c ='Test';
       fo.Physician_First_Name__c='Test';
       fo.Physician_Last_Name__c='Test';
       fo.Physician_Npi__c='121212';
       fo.Physician_Upin__c='121121';
       fo.PWN_ID__c='12121';
       fo.RecordTypeId=Label.SFOM_OTC_Cleared_Record_Type_Id;
       fo.FulfilledToAddressLine1__c='124 Main St';
       fo.FulfilledToAddressLine2__c='Aasa';
       fo.FulfilledFromLocationId=loc.Id;

       update fo;  

       FulfillmentOrderLineItem foline = [select Id from FulfillmentOrderLineItem where FulfillmentOrderId = :fo.Id and Test_Type__c = 'at_home' LIMIT 1];     

        inputs.put('lineId',foline.Id);
        inputs.put('foId',fo.Id);

       return inputs;
    }

    @IsTest 
    static void QuestTPTShipmentScheduleTerritoryTest () {
        QuestTPTShipmentSchedule  obj = new QuestTPTShipmentSchedule();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, obj); 
  }   

 
}