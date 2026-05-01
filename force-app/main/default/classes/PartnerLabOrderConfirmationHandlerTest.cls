@IsTest
public with sharing class PartnerLabOrderConfirmationHandlerTest {
    @IsTest
    static void testConfirmationEvent()
    {
        Product2 product = new Product2();
            product.Name = 'Test';
            product.Description = 'Test';
            product.ProductCode = 'test';
            product.StockKeepingUnit = 'Test'+ String.valueOf(1);
            product.DisplayUrl = '';
            product.ExternalId = 'sku123';
            product.IsActive = true;
            insert product;

        Panel__c panel =  new Panel__c(Product__c=product.Id);
        insert panel;

        Test__c test =  new Test__c(Test_Code__c='test',Test_Name__c='test',Description__c='test');
        insert test;

        Panel_Test__c panelTest= new Panel_Test__c(Panel__c=panel.Id,Test__c=test.Id);
        insert panelTest;

        Account accnt = new Account(Name='Test test');
        insert accnt;
        
        Contact con = new Contact();
        con.AccountId = accnt.id;
        con.LastName = 'test';
        insert con;

        // Insert mock Person and Lab_Order__c records
        Person_Record__c person = new Person_Record__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Email__c = 'john.doe@example.com',
            Address_Line_1__c = '123 Main St',
            Unique_Identifier__c ='Uniqu1',
            City__c = 'Anytown',
            Country__c = 'USA',
            State__c = 'CA',
            Postal_Code__c = '12345',
            Phone__c = '1234567890',
            Gender__c = 'Male',
            Date_of_Birth__c = Date.newInstance(1990, 1, 1),
            Contact__c = con.id
        );
        insert person;

        Lab_Order__c labOrder = new Lab_Order__c(
           Is_Partner__c=true,
            Client_Id__c = '12345',
            External_partner_Order_Id__c='12121',
            Person_Record__c = person.Id,
            Account__c=accnt.Id
        );
        insert labOrder;

        SFMC_OMS_Config__c  newConfig= new SFMC_OMS_Config__c (Channel__c = 'QD-CIT',Auth_Token__c ='77778888888812213', API__C = 'Common');
                insert newConfig;  

        System.Test.startTest();
        // Call the future method
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator1());
              

        Lab_Order_SFMC_Event__e lbse = new Lab_Order_SFMC_Event__e();
        lbse.Event_Type__c = System.label.SFMC_Partner_Lab_Order_Confirmation_Event;
        lbse.EventDefinitionKey__c = 'test_registration_confirmation_email';
        lbse.Lab_Order_Id__c = labOrder.Id ;
        EventBus.publish(lbse);
        System.Test.stopTest();
    }

     private class MockHttpResponseGenerator1 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true, "statusCode": 201, "message": "Event created successfully."}');
            return res;
        }
    }
}