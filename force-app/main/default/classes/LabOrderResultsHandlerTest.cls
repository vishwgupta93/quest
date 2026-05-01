@IsTest
public class LabOrderResultsHandlerTest {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true, "statusCode": 201, "message": "Event created successfully."}');
            return res;
        }
    }

 @IsTest (SeeAllData=true)
    static void testSendPayLoadWithUnVerifiedEmail() {
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

        // Set mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Execute the test scenario
        Test.startTest();
        LabOrderResultsHandler.sendPayLoad(labOrder.Id, 'EventKey123', 'Blood Test',false);
        Test.stopTest();

        // Assert success status on Event_Log__c
        Event_Log__c eventLog = [SELECT Status__c, Payload__c FROM Event_Log__c WHERE Lab_Order__c = :labOrder.Id];
        System.assertEquals('Success', eventLog.Status__c, 'Event log should indicate success.');
        System.assertNotEquals(null, eventLog.Payload__c, 'Payload should not be null.');
    }

    @IsTest (SeeAllData=true)
    static void testSendPayLoadWithVerifiedEmail() {
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
            Status__c='Results Ready',
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

        // Set mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Execute the test scenario
        Test.startTest();
        LabOrderResultsHandler.sendPayLoad(labOrder.Id, 'EventKey123', 'Blood Test',true);
        Test.stopTest();

        // Assert success status on Event_Log__c
        // Event_Log__c eventLog = [SELECT Status__c, Payload__c FROM Event_Log__c WHERE Lab_Order__c = :labOrder.Id];
        // System.assertEquals('Success', eventLog.Status__c, 'Event log should indicate success.');
        // System.assertNotEquals(null, eventLog.Payload__c, 'Payload should not be null.');
    }

    @IsTest (SeeAllData=true)
    static void testSendPayLoadWithVerifiedEmailPreShopRocket() {
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
            Status__c='Results Ready',
            Pre_Shop_Rocket__c=true,
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

        // Set mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Execute the test scenario
        Test.startTest();
        LabOrderResultsHandler.sendPayLoad(labOrder.Id, 'EventKey123', 'Blood Test',true);
        Test.stopTest();

        // Assert success status on Event_Log__c
        // Event_Log__c eventLog = [SELECT Status__c, Payload__c FROM Event_Log__c WHERE Lab_Order__c = :labOrder.Id];
        // System.assertEquals('Success', eventLog.Status__c, 'Event log should indicate success.');
        // System.assertNotEquals(null, eventLog.Payload__c, 'Payload should not be null.');
    }
}