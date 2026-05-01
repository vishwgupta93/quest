@IsTest
public with sharing class GBFShipmentConfirmationTest {
   
    public static Map<String,String> inputIds= getPartnerOrder();
    
   
    private class MockHttpResponseGeneratorSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {


            // Create a new XML document
        Dom.Document doc = new Dom.Document();
        
        // Create the root element
        Dom.XmlNode root = doc.createRootElement('ShippingConfirmations', null, null);
        
        // Create the ShippingConfirmation element
        Dom.XmlNode shippingConfirmation = root.addChildElement('ShippingConfirmation', null, null);
        shippingConfirmation.setAttribute('OrderNumber', inputIds.get('partnerOrderId'));
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
        item.setAttribute('GLCode', inputIds.get('partnerOrderLineId'));
        item.setAttribute('LineNumber', '000001');
        
        // Create the TubeSerial element
        Dom.XmlNode tubeSerial = item.addChildElement('TubeSerial', null, null);
        tubeSerial.setAttribute('VerificationId', 'ZIMDP');
        tubeSerial.addTextNode('CITW1V791T2');
        
        // Create the ReturnTracking element
        Dom.XmlNode returnTracking = item.addChildElement('ReturnTracking', null, null);
        returnTracking.addTextNode('796645970318');

        // Create the Item element
        Dom.XmlNode item1 = shippingConfirmation.addChildElement('Item', null, null);
        item1.setAttribute('ItemNumber', '39751');
        item1.setAttribute('LotNumber', 'I85Q6-03/31/2024');
        item1.setAttribute('SerialNumber', 'QB021B8UI');
        item1.setAttribute('ExpireDate', '2024-03-31');
        item1.setAttribute('ShippedQty', '1');
        item1.setAttribute('GLCode', inputIds.get('partnerOrderLineId'));
        item1.setAttribute('LineNumber', '000001');
        
        // Create the TubeSerial element
        Dom.XmlNode tubeSerial1 = item1.addChildElement('TubeSerial', null, null);
        tubeSerial1.setAttribute('VerificationId', 'ZIMDP');
        tubeSerial1.addTextNode('CITW1V791T2');
        
        // Create the ReturnTracking element
        Dom.XmlNode returnTracking1 = item1.addChildElement('ReturnTracking', null, null);
        returnTracking1.addTextNode('796645970318');

        // Create the Item element
        Dom.XmlNode item2 = shippingConfirmation.addChildElement('Item', null, null);
        item2.setAttribute('ItemNumber', '39751');
        item2.setAttribute('LotNumber', 'I85Q6-03/31/2024');
        item2.setAttribute('SerialNumber', 'QB021B8UI');
        item2.setAttribute('ExpireDate', '2024-03-31');
        item2.setAttribute('ShippedQty', '1');
        item2.setAttribute('GLCode', inputIds.get('partnerOrderLineId'));
        item2.setAttribute('LineNumber', '000001');
        
        
        // Create the ReturnTracking element
        Dom.XmlNode returnTracking2 = item2.addChildElement('ReturnTracking', null, null);
        returnTracking2.addTextNode('796645970318');

        System.debug(doc.toXmlString());

            
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

    @IsTest (SeeAllData=true)
    static void validateGBFShipmentConfirmScheduleResponse_Exception()
    {
        OMS_Shipment_Payload__c payload = new OMS_Shipment_Payload__c();
        payload.Partner_Order__c = inputIds.get('partnerOrderId');
        payload.Payload__c = 'Dummy paylaod';

        insert payload;
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorFailure());

   Test.startTest();
   GBFShipmentConfirmation btch= new GBFShipmentConfirmation();
   btch.Id=inputIds.get('partnerOrderId');
   btch.query = 'SELECT Id,  Status__c, Retail_Partner__r.Fulfillment_Location_API_Key__c FROM Partner_Order__c WHERE  Id =: id';
   Database.executeBatch(btch,1);
   Test.stopTest();
    }



    @IsTest (SeeAllData=true)
    static void validateGBFShipmentConfirmScheduleResponse_Success()
    {
             // Create a new XML document
             Dom.Document doc = new Dom.Document();
        
             // Create the root element
             Dom.XmlNode root = doc.createRootElement('ShippingConfirmations', null, null);
             
             // Create the ShippingConfirmation element
             Dom.XmlNode shippingConfirmation = root.addChildElement('ShippingConfirmation', null, null);
             shippingConfirmation.setAttribute('OrderNumber', inputIds.get('partnerOrderId'));
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
             item.setAttribute('GLCode', inputIds.get('partnerOrderLineId'));
             item.setAttribute('LineNumber', '000001');
             
             // Create the TubeSerial element
             Dom.XmlNode tubeSerial = item.addChildElement('TubeSerial', null, null);
             tubeSerial.setAttribute('VerificationId', 'ZIMDP');
             tubeSerial.addTextNode('CITW1V791T2');
             
             // Create the ReturnTracking element
             Dom.XmlNode returnTracking = item.addChildElement('ReturnTracking', null, null);
             returnTracking.addTextNode('796645970318');
     
             // Create the Item element
             Dom.XmlNode item1 = shippingConfirmation.addChildElement('Item', null, null);
             item1.setAttribute('ItemNumber', '39751');
             item1.setAttribute('LotNumber', 'I85Q6-03/31/2024');
             item1.setAttribute('SerialNumber', 'QB021B8UI');
             item1.setAttribute('ExpireDate', '2024-03-31');
             item1.setAttribute('ShippedQty', '1');
             item1.setAttribute('GLCode', inputIds.get('partnerOrderLineId'));
             item1.setAttribute('LineNumber', '000001');
             
             // Create the TubeSerial element
             Dom.XmlNode tubeSerial1 = item1.addChildElement('TubeSerial', null, null);
             tubeSerial1.setAttribute('VerificationId', 'ZIMDP');
             tubeSerial1.addTextNode('CITW1V791T2');
             
             // Create the ReturnTracking element
             Dom.XmlNode returnTracking1 = item1.addChildElement('ReturnTracking', null, null);
             returnTracking1.addTextNode('796645970318');
     
             // Create the Item element
             Dom.XmlNode item2 = shippingConfirmation.addChildElement('Item', null, null);
             item2.setAttribute('ItemNumber', '39751');
             item2.setAttribute('LotNumber', 'I85Q6-03/31/2024');
             item2.setAttribute('SerialNumber', 'QB021B8UI');
             item2.setAttribute('ExpireDate', '2024-03-31');
             item2.setAttribute('ShippedQty', '1');
             item2.setAttribute('GLCode', inputIds.get('partnerOrderLineId'));
             item2.setAttribute('LineNumber', '000001');
             
             
             // Create the ReturnTracking element
             Dom.XmlNode returnTracking2 = item2.addChildElement('ReturnTracking', null, null);
             returnTracking2.addTextNode('796645970318');
     
             System.debug(doc.toXmlString());
     
                 
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

             String xml = gen.getAsString();
             OMS_Shipment_Payload__c payload = new OMS_Shipment_Payload__c();
             payload.Partner_Order__c = inputIds.get('partnerOrderId');
             payload.Payload__c = xml;

             insert payload;
        
     System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());

        Test.startTest();
        GBFShipmentConfirmation btch= new GBFShipmentConfirmation();
        btch.Id=inputIds.get('partnerOrderId');
        btch.query = 'SELECT Id,  Status__c, Retail_Partner__r.Fulfillment_Location_API_Key__c FROM Partner_Order__c WHERE  Id =: id';
        Database.executeBatch(btch,1);
        Test.stopTest();
        
    }

    @IsTest (SeeAllData=true)
    static void validateGBFShipmentConfirmScheduleTest () {
        GBFShipmentConfirmSchedule  obj = new GBFShipmentConfirmSchedule();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, obj); 
  }     


    private static Map<String,String> getPartnerOrder()
    {

        Map<String,String> inputs= new Map<String,String>();
        PartnerClientMap__c partner= new PartnerClientMap__c();
        partner.Client_ID__c= 'test1';
        partner.Partner_Name__c='test1';
        partner.Short_Code__c='test';

        insert partner;
        Partner_Order__c order = new Partner_Order__c();
        order.Retail_Partner__c = partner.Id;
        order.Address_Line_1__c='123 Test';
        order.City__c = 'Test';
        order.State__c='NY';
        order.ZipCode__c='12345';
        order.Country__c='US';
        order.Company_Name__c='Test Company';
        order.Shipping_Method__c='FedEx Ground';
        order.Email__c='test@gmail.com';
        order.PhoneNumber__c='1234567890';
        order.Status__c='Shipped';

        insert order;

        Product2 product = new Product2();
            product.Name = 'Test';
            product.Description = 'Test';
            product.ProductCode = 'Test123';
            product.StockKeepingUnit = 'Test123' + String.valueOf(12345);
            product.DisplayUrl = '';
            product.ExternalId = 'Test123';
            product.IsActive = true;
            insert  product;

        Partner_Order_Line_Item__c line= new Partner_Order_Line_Item__c();
        line.Partner_Order__c=order.Id;
        line.Product__c=product.Id;
        line.Quantity__c=1000;

        insert line;       

        inputs.put('partnerOrderLineId',line.Id);
        inputs.put('partnerOrderId',order.Id);

        return inputs;
    }
}