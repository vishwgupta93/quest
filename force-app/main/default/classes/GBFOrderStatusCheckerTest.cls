@IsTest
public with sharing class GBFOrderStatusCheckerTest {
    
    public static String partnerOrderId = getPartnerOrder().Id;

    private class MockHttpResponseGeneratorSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

            JSONGenerator gen= JSON.createGenerator(true);
            gen.writeStartObject();
                gen.writeBooleanField('success', true);
                gen.writeStringField('errorMessage', '');
                gen.writeFieldName('statuses');
                gen.writeStartArray();
                
                // First status object
                    gen.writeStartObject();
                    gen.writeStringField('orderNumber',  partnerOrderId);
                    gen.writeStringField('orderStatus', 'SHIPPED (SIMULATED)');
                    gen.writeStringField('statusMessage', '');
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

    @IsTest (SeeAllData=true)
    static void validateStatusCheckTest()
    {
        

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());
        Test.startTest();
        GBFOrderStatusChecker btch= new GBFOrderStatusChecker();
      //  btch.Id=partnerOrderId;
        btch.status = 'Acknowledged';
        btch.query = 'SELECT Id,  Status__c,Partner_Order__c.Retail_Partner__r.Fulfillment_Location_API_Key__c FROM Partner_Order__c WHERE Status__c =: status and Id=\'' + partnerOrderId+'\'';
        Database.executeBatch(btch,1);
        Test.stopTest();
        
    }

    @IsTest (SeeAllData=true)
    static void validateStatusCheckScheduleTest () {
        GBFOrderStatusCheckerSchedule  obj = new GBFOrderStatusCheckerSchedule();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, obj); 
  }      








    private static Partner_Order__c getPartnerOrder()
    {

        PartnerClientMap__c partner= new PartnerClientMap__c();
        partner.Client_ID__c= 'test1';
        partner.Partner_Name__c='test1';
        partner.Short_Code__c='test';
         partner.Fulfillment_Location_API_Key__c = '12345';

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
        order.Status__c='Acknowledged';

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

        return order;
    }
}