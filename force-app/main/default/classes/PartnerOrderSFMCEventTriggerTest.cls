/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class PartnerOrderSFMCEventTriggerTest {

    @isTest
    static void triggerPurchaseConfirmationEmailTest() {

        Partner_Order__c order = getPartnerOrder();

        Partner_Order_SFMC_Event__e event = new Partner_Order_SFMC_Event__e();
        event.Event_Definition_Key__c = Label.SFMC_Partner_Order_Purchase_Confirmation;
        event.Partner_Order_Id__c=order.Id;

        SFMC_OMS_Config__c  newConfig= new SFMC_OMS_Config__c (Channel__c = 'QD-CIT',Auth_Token__c ='77778888888812213', API__C = 'Common');
        insert newConfig;  

        System.Test.startTest();
        // Call the future method
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        EventBus.publish(event);
        System.Test.stopTest();
    }

    @isTest
    static void triggerPurchaseShipmentConfirmationEmailTest() {

        Partner_Order__c order = getPartnerOrder();

        Partner_Order_SFMC_Event__e event = new Partner_Order_SFMC_Event__e();
        event.Event_Definition_Key__c = Label.SFMC_Partner_Order_Shipment_Confirmation;
        event.Partner_Order_Id__c=order.Id;

        SFMC_OMS_Config__c  newConfig= new SFMC_OMS_Config__c (Channel__c = 'QD-CIT',Auth_Token__c ='77778888888812213', API__C = 'Common');
        insert newConfig;  

        System.Test.startTest();
        // Call the future method
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        EventBus.publish(event);
        System.Test.stopTest();
    }

    private static Partner_Order__c getPartnerOrder()
    {

        PartnerClientMap__c partner= new PartnerClientMap__c();
        partner.Client_ID__c= 'test1223';
        partner.Partner_Name__c='test12121';
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

        Partner_Shipment_Info__c psi = new Partner_Shipment_Info__c();
        psi.Tracking_Number__c = '12345';
        psi.Partner_Order__c = order.Id;
        psi.Ship_Via__c = 'Ship';
        insert psi;

        return order;
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setBody('Mock response body');
            return res;
        }
    }
}