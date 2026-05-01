@isTest(SeeAllData=true)
public class ResultLookupCtrlTest {
    
    @isTest 
    static void verifyInputDataTest(){

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

        Panel__c p = new Panel__c();
        p.Panel_Code__c = '12767';
        p.Panel_Name__c = 'test panel';
        insert p;
        
        Test__c t = new Test__c();
        t.Test_Code__c = '12767';
        t.Test_Name__c = 'demo test';
        insert t;

        Lab_Order__c lo = new Lab_Order__c(
            Name = 'Test Lab Order',
            Account__c = testAccount.Id,
            Person_Record__c = person.Id
           );
        insert lo;

        Panel_Test__c pt = new Panel_Test__c();
        pt.Panel__c = p.id;
        pt.Test__c = t.Id;
        insert pt;
        
        Lab_Order_Panel__c LOP = new Lab_Order_Panel__c();
        LOP.HRA_Req__c = true;
        LOP.Lab_Order__c = lo.id;
        LOP.Panel__c = p.id;
        insert LOP;
        
        Lab_Panel_Test__c lbt = new Lab_Panel_Test__c();
        lbt.Lab_Order_Panel__c = LOP.id;
        lbt.Lab_Order__c=lo.id;
        lbt.Status__c = 'Results Ready';
        lbt.Panel_Test__c = pt.id;
        insert lbt;

        

        Lab_Order__c labOrder = [SELECT Id, Name, Status__c, Person_Record__r.Email__c,  Person_Record__r.Last_Name__c, Person_Record__r.Date_of_Birth__c, Person_Record__r.Contact__c
                                FROM Lab_Order__c
                                where Id =: lo.Id];
        
        String DOB = string.valueOf(labOrder.Person_Record__r.Date_of_Birth__c );
        
        Test.startTest();
        ResultLookupCtrl.verifyInputData(labOrder.Id, '', labOrder.Person_Record__r.Last_Name__c , DOB );
        ResultLookupCtrl.verifyInputData('', labOrder.Name, labOrder.Person_Record__r.Last_Name__c , DOB );
        ResultLookupCtrl.reSendOTP(testUser.id,labOrder.Id);
        ResultLookupCtrl.showResultData(labOrder.Id);
        
        try{
             ResultLookupCtrl.showResultData('23jdk4');
            ResultLookupCtrl.verifyInputData('', '23jdk4', labOrder.Person_Record__r.Last_Name__c , DOB );
            
        }catch(Exception ex){}
        Test.stopTest();
    }
    @isTest
    public static void getCustomlabelsTest() {
        String isMFAEnabled = ResultLookupCtrl.isMFAEnabled();
        System.assert(isMFAEnabled != null);
        String vfURL = ResultLookupCtrl.getVFURL();
        System.assert(vfURL != null);
        String passphrase = ResultLookupCtrl.getPassphrase();
        System.assert(passphrase != null);
    }
    @isTest
    public static void verifyInputDataFail1() {
         try{
        ResultLookupCtrl.verifyInputData('', '', '' , '');
         }catch(Exception ex){}
    }
    @isTest
    public static void verifyInputDataFail2() {
         try{
        Lab_Order__c labOrder = [SELECT Id, Name, Status__c, Person_Record__r.Email__c,  Person_Record__r.Last_Name__c, Person_Record__r.Date_of_Birth__c, Person_Record__r.Contact__c
                                FROM Lab_Order__c
                                where Status__c ='Cancelled' LIMIT 1];
        ResultLookupCtrl.verifyInputData(labOrder.Id, '', '' , '');
         }catch(Exception ex){}
    }
    @isTest static void decryptLabOrderTest(){
        
        String encryptedOrderNumber = 'ubRmy6Wia8YGNSeAotIyKYBQ+Wo7QnIGfTJkF6QDx4o='; 
        String expectedDecryptedValue = '0921D5-223A-613E81B34CFF6F30'; 
        
        String result = ResultLookupCtrl.decryptLabOrder(encryptedOrderNumber);
        
        System.assertEquals(expectedDecryptedValue, result, 'The decrypted value should match the expected value');
    }
    
    @isTest
    public static void verifyInputsAndSendEmailOTPTest() {
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

        Panel__c p = new Panel__c();
        p.Panel_Code__c = '12767';
        p.Panel_Name__c = 'test panel';
        insert p;
        
        Test__c t = new Test__c();
        t.Test_Code__c = '12767';
        t.Test_Name__c = 'demo test';
        insert t;

        Lab_Order__c lo = new Lab_Order__c(
            Name = 'Test Lab Order',
            Account__c = testAccount.Id,
            Person_Record__c = person.Id
           );
        insert lo;

        Panel_Test__c pt = new Panel_Test__c();
        pt.Panel__c = p.id;
        pt.Test__c = t.Id;
        insert pt;
        
        Lab_Order_Panel__c LOP = new Lab_Order_Panel__c();
        LOP.HRA_Req__c = true;
        LOP.Lab_Order__c = lo.id;
        LOP.Panel__c = p.id;
        insert LOP;
        
        Lab_Panel_Test__c lbt = new Lab_Panel_Test__c();
        lbt.Lab_Order_Panel__c = LOP.id;
        lbt.Lab_Order__c=lo.id;
        lbt.Status__c = 'Results Ready';
        lbt.Panel_Test__c = pt.id;
        insert lbt;
        Lab_Order__c labOrder = [Select id, Name,Person_Record__r.Last_Name__c, Person_Record__r.Date_of_Birth__c from Lab_Order__c
                                 where id =: lo.id];
        
        String DOB = string.valueOf(labOrder.Person_Record__r.Date_of_Birth__c );

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            
            ResultLookupCtrl.verifyInputsAndSendEmailOTP(labOrder.Id, labOrder.Name, labOrder.Person_Record__r.Last_Name__c, DOB);
            

        } catch(Exception ex) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        // 3. Assert
        System.assertEquals(true, exceptionThrown);
        
    }
    
    @isTest
    public static void verifyEmailOTPTest() {
        Test.startTest();
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
        try{
            ResultLookupCtrl.verifyEmailOTP(testUser.Id, 'identifier', '12345');
        }catch(Exception ex){}
        Test.stopTest();
        
    }
    @isTest
    public static void reSendResultsReadyLinkTest() {
        
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

        

        Lab_Order__c lo = new Lab_Order__c(
            Name = 'Test Lab Order',
            Account__c = testAccount.Id,
            Person_Record__c = person.Id,
             Status__c='Results Ready'
           );
        insert lo;
        
        Lab_Order__c labOrder = [Select id, Name,Person_Record__r.Last_Name__c, Person_Record__r.Date_of_Birth__c from Lab_Order__c
                                 where Id =: Lo.id];
        
        
        Test.startTest();
        ResultLookupCtrl.reSendResultsReadyLink(labOrder.Name);
        Test.stopTest();
        
    } 
    
}