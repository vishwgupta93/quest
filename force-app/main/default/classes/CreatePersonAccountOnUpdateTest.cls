@isTest
public class CreatePersonAccountOnUpdateTest {

    @isTest
    static void testCreatePersonAccount() {
        // Step 1: Setup test data
        // Create a test Person_Record__c record
        Person_Record__c personDetail = new Person_Record__c(
            Address_Line_1__c = '123 Main Street',
            Address_Line_2__c = 'Suite 100',
            City__c = 'Test City',
            Country__c = 'US',
            Date_Of_Birth__c = Date.newInstance(1990, 1, 1),
            Email__c = 'test@example.com',
            First_Name__c = 'John',
            Gender__c = 'Male',
            Last_Name__c = 'Doe',
            Phone__c = '123-456-7890',
            State__c = 'NY',
            Postal_Code__c = '12345',
            Unique_Identifier__c='test@example.com:Doe:1990-01-01'
        );
        insert personDetail;

        // Step 2: Prepare input for the Invocable method
        CreatePersonAccountOnUpdate.CreatePersonAccountInput input = 
            new CreatePersonAccountOnUpdate.CreatePersonAccountInput();
        input.personId = personDetail.Id;

        List<CreatePersonAccountOnUpdate.CreatePersonAccountInput> inputs = new List<CreatePersonAccountOnUpdate.CreatePersonAccountInput>{ input };

        // Step 3: Execute the method
        Test.startTest();
        List<CreatePersonAccountOnUpdate.CreatePersonAccountOutput> outputs = CreatePersonAccountOnUpdate.createPersonAccount(inputs);
        Test.stopTest();

        // Step 4: Assertions
        System.assertEquals(1, outputs.size(), 'There should be exactly one output');
        CreatePersonAccountOnUpdate.CreatePersonAccountOutput output = outputs[0];
        
        // Verify the Account ID and Contact ID are not null
        System.assertNotEquals(null, output.accountID, 'Account ID should not be null');
        System.assertNotEquals(null, output.contactID, 'Contact ID should not be null');

        // Verify the Account details match the Person_Record__c details
        Account createdAccount = [SELECT Id, PersonEmail, PersonBirthdate, FirstName, LastName, PersonGenderIdentity, PersonMobilePhone, 
                                   BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                                   FROM Account WHERE Id = :output.accountID];
        System.assertEquals(personDetail.Email__c, createdAccount.PersonEmail, 'Email should match');
        System.assertEquals(personDetail.Date_Of_Birth__c, createdAccount.PersonBirthdate, 'Birthdate should match');
        System.assertEquals(personDetail.First_Name__c, createdAccount.FirstName, 'First name should match');
        System.assertEquals(personDetail.Last_Name__c, createdAccount.LastName, 'Last name should match');
        System.assertEquals(personDetail.Gender__c, createdAccount.PersonGenderIdentity, 'Gender should match');
        System.assertEquals(personDetail.Phone__c, createdAccount.PersonMobilePhone, 'Phone number should match');
        System.assertEquals(personDetail.Address_Line_1__c, createdAccount.BillingStreet, 'Billing Street should match');
        System.assertEquals(personDetail.City__c, createdAccount.BillingCity, 'City should match');
        System.assertEquals(personDetail.State__c, createdAccount.BillingState, 'State should match');
        System.assertEquals(personDetail.Postal_Code__c, createdAccount.BillingPostalCode, 'Postal Code should match');
        System.assertEquals(personDetail.Country__c, createdAccount.BillingCountry, 'Country should match');

        // Verify the Contact is linked to the Account
        Contact createdContact = [SELECT Id, AccountId FROM Contact WHERE Id = :output.contactID];
        System.assertEquals(output.accountID, createdContact.AccountId, 'Contact should be linked to the created Account');
    }
}