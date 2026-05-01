@IsTest
public class LabOrderSFMCEmailEventTest {
    @IsTest
    static void testRegistrationEvent()
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
            Person_Record__c = person.Id,
            Account__c=accnt.Id
        );
        insert labOrder;

        SFMC_OMS_Config__c  newConfig= new SFMC_OMS_Config__c (Channel__c = 'QD-CIT',Auth_Token__c ='77778888888812213', API__C = 'Common');
                insert newConfig;  

        System.Test.startTest();
        // Call the future method
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
              

        Lab_Order_SFMC_Event__e lbse = new Lab_Order_SFMC_Event__e();
        lbse.Event_Type__c = System.label.SFMC_Lab_Order_Register_Event;
        lbse.EventDefinitionKey__c = 'test_registration_confirmation_email';
        lbse.Lab_Order_Id__c = labOrder.Id ;
        EventBus.publish(lbse);
        System.Test.stopTest();
    }

    @IsTest
    static void testHRAEvent()
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
            Person_Record__c = person.Id,
            Account__c=accnt.Id
        );
        insert labOrder;

        SFMC_OMS_Config__c  newConfig= new SFMC_OMS_Config__c (Channel__c = 'QD-CIT',Auth_Token__c ='77778888888812213', API__C = 'Common');
                insert newConfig;  

        System.Test.startTest();
        // Call the future method
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
              

        Lab_Order_SFMC_Event__e lbse = new Lab_Order_SFMC_Event__e();
        lbse.Event_Type__c = System.label.SFMC_HRA_Email_Trigger_Event;
        lbse.EventDefinitionKey__c = 'hraEvent';
        lbse.Lab_Order_Id__c = labOrder.Id ;
        EventBus.publish(lbse);
        System.Test.stopTest();
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setBody('Mock response body');
            return res;
        }
    }
 @IsTest (SeeAllData=true)
     static void testResultEvent()
    {
        // Retrieve profile and role IDs outside of runAs
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        Id roleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'System_Administrator' LIMIT 1].Id;

        // Create a temporary user in System.runAs with all required fields
        User owner;
        System.runAs(new User(
            LastName = 'TempUser',
            Alias = 'tuser',
            Email = 'tempuser@example.com',
            Username = 'tempuser' + System.currentTimeMillis() + '@example.com',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        )) {
            owner = new User(
                LastName = 'User',
                Alias = 'tuser1',
                Email = 'testuser@example.com',
                Username = 'testuser' + System.currentTimeMillis() + '@example.com',
                ProfileId = profileId,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                UserRoleId = roleId, // Assign role
                IsActive = true
            );
            insert owner;
        }

        // Insert non-setup records (Account, Contact, etc.) after User creation
        Account testAccount = new Account(Name = 'Test Account', OwnerId = owner.Id);
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = testAccount.Id, Email = 'test@example.com');
        insert testContact;

User testUser = new User(
                LastName = 'User',
                Alias = 'tuser1',
                Email = 'testuser@example.com',
                Username = 'testuser' + System.currentTimeMillis() + '@example.com',
                ProfileId = [select Id from Profile where Name = 'Customer Community Login User'].Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ContactId = testContact.Id, // Assign role
                IsActive = true
            );
            insert testUser;

        // Create mock Person and Lab_Order__c records
        Person_Record__c person = new Person_Record__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Email__c = 'john.doe@example.com',
            Address_Line_1__c = '123 Main St',
            Unique_Identifier__c = 'Uniqu1',
            City__c = 'Anytown',
            Country__c = 'USA',
            State__c = 'CA',
            Postal_Code__c = '12345',
            Phone__c = '1234567890',
            Gender__c = 'Male',
            Contact__c = testContact.Id,
            Date_of_Birth__c = Date.newInstance(1990, 1, 1)
        );
        insert person;

        String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String merchantID = 'Quest_US';

        Map<String, SObject> m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode, currencyIsoCode, merchantID);
        Order newOrder = (Order) m_mapTestData.get('newOrder');
        SFOMTestDataFactory.UpdateOrderStatus(newOrder, 'Activated');
        List<OrderSummary> lstOS = [SELECT Id FROM OrderSummary WHERE OriginalOrderId = :newOrder.Id];

        Lab_Order__c labOrder = new Lab_Order__c(
            Name = 'Test Lab Order',
            Account__c = testAccount.Id,
            Person_Record__c = person.Id,
            Order_Summary__c = lstOS[0].Id
        );
        insert labOrder;

        // Configure mock SFMC_OMS_Config__c
        SFMC_OMS_Config__c config = new SFMC_OMS_Config__c(
            Channel__c = 'QD-CIT',
            API__c = 'Common',
            Auth_Token__c = 'dummyToken'
        );
        insert config;
        System.Test.startTest();
        // Set mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator1());

        Lab_Order__c lb =  [SELECT Id, FO_Record_Type__c from Lab_Order__c  where Name =: labOrder.Name];
        String isMFAEnabled = System.label.SFOM_MFA_Enabled;
        Boolean mfaEnabled = !String.isBlank(isMFAEnabled) && isMFAEnabled == 'false';
        Lab_Order_SFMC_Event__e lbse = new Lab_Order_SFMC_Event__e();
        lbse.Event_Type__c = System.label.SFMC_Results_Ready_Event;
        lbse.EventDefinitionKey__c = System.label.SFMC_Lab_Order_Results_Ready_Event_Definition;
        lbse.Test_type__c = lb.FO_Record_Type__c;
        lbse.Lab_Order_Id__c = lb.Id ;
        lbse.MFA_Enabled__c=mfaEnabled;
        EventBus.publish(lbse);
         System.Test.stopTest();
    }

    @IsTest
    static void testCancelEvent()
    {
        Account ac = new Account();
        ac.Name = 'Test account';
        insert ac;
        
        Contact con = new Contact();
        con.lastName = 'test con';
        con.Email = 'test@gmail.com';
        con.AccountId = ac.Id;
        insert con;
     
        SalesChannel SC = new SalesChannel();	
        SC.SalesChannelName = 'QDCIT Partner';
        SC.Description = 'QDCIT Partner';
        insert SC;
        
        PartnerClientMap__c PCM = new PartnerClientMap__c();
        PCM.Name = 'Google'; 
        PCM.Sales_Channel__c = SC.Id;
        PCM.Partner_Name__c = 'google';
        PCM.Client_ID__c = '34566';
       
        insert PCM;
        
        Panel__c p = new Panel__c();
        p.Panel_Code__c = '12767';
        p.Panel_Name__c = 'test panel';
        insert p;
        
        Test__c t = new Test__c();
        t.Test_Code__c = '12767';
        t.Test_Name__c = 'demo test';
        insert t;
        
      
        Person_Record__c pr = new Person_Record__c();
        pr.Email__c= 'test@gmail.com';
        pr.First_Name__c= 'Fname';
        pr.Last_Name__c= 'LName';
        pr.Phone__c= '4569990422';
        pr.Gender__c = 'Male';
        pr.Contact__c = con.Id;
        pr.Date_of_Birth__c=  date.valueOf('2000-12-12');
        pr.Address_Line_1__c= 'gfds';
        pr.City__c= 'Santa Barbara';
        pr.State__c= 'CA';
        pr.Postal_Code__c= '93110';
        pr.Country__c = 'US';
        pr.Unique_Identifier__c = 'test@gmail.com'+':'+'2000-12-12'+':'+'LName';
        insert pr;
        
        Lab_order__c lb = new Lab_Order__c();
        lb.Person_Record__c = pr.id;
        lb.Partner_Client_Map__c = PCM.id;
        lb.Client_Name__c = 'clientName';
        lb.Name = 'clientName';
        lb.Status__c = 'Registered';
        lb.Refund_Amount__c=24.00;
        insert lb;
        
        Panel_Test__c pt = new Panel_Test__c();
        pt.Panel__c = p.id;
        pt.Test__c = t.Id;
        insert pt;
        
        Lab_Order_Panel__c LOP = new Lab_Order_Panel__c();
        LOP.HRA_Req__c = true;
        LOP.Lab_Order__c = lb.id;
        LOP.Panel__c = p.id;
        insert LOP;
        
        Lab_Panel_Test__c lbt = new Lab_Panel_Test__c();
        lbt.Lab_Order_Panel__c = LOP.id;
        lbt.Status__c = 'Registered';
        lbt.Panel_Test__c = pt.id;
        insert lbt;

        SFMC_OMS_Config__c  newConfig= new SFMC_OMS_Config__c (Channel__c = 'QD-CIT',Auth_Token__c ='77778888888812213', API__C = 'Common');
                insert newConfig;  

        System.Test.startTest();
        // Call the future method
        System.Test.setMock(HttpCalloutMock.class, new LabOrderCancelMock());
     
                    

        Lab_Order_SFMC_Event__e lbse = new Lab_Order_SFMC_Event__e();
        lbse.Event_Type__c = System.label.SFMC_Order_Cancel_Event;
        lbse.EventDefinitionKey__c = System.Label.SFMC_Order_Cance_Event_Definition;
        lbse.Lab_Order_Id__c = lb.Id ;
        lbse.Test_type__c = 'InPerson' ;
        EventBus.publish(lbse);
        System.Test.stopTest();
    }

   
    public class LabOrderCancelMock implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if(req.getEndPoint().contains('event')){
                res.setBody('{"success":true,"memberId":"1MR141","calendarURL":"https://enrollment-dev.packhealth.com/calendar/eyJtZW1i","errorMessage": null}');
                res.setStatusCode(201);
            }
            else{
                res.setbody('{"message": "Invalid request body","detail": "[instance type (boolean) does (allowed: [\"string\"])]"}');
                res.setStatusCode(400);
            }
            return res;
        }
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