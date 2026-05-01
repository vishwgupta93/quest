@isTest
public class CreatePersonAccountTest {

    @isTest
    static void testCreatePersonAccount() {
        // Step 1: Setup test data
        // Create a Tester_Detail__c record
        Tester_Detail__c testerDetail = new Tester_Detail__c(
            Address_Line_1__c = '456 Elm Street',
            Address_Line_2__c = 'Apt 200',
            City__c = 'Test City',
            Country__c = 'US',
            Date_Of_Birth__c = Date.newInstance(1995, 5, 15),
            Email__c = 'tester@example.com',
            First_Name__c = 'Jane',
            Gender__c = 'Female',
            Last_Name__c = 'Doe',
            Middle_Name__c = 'Marie',
            Phone__c = '987-654-3210',
            State__c = 'NY',
            Zip_Code__c = '54321'
        );
        insert testerDetail;

        // Step 2: Prepare inputs for the Invocable method
        CreatePersonAccount.CreatePersonAccountInput input = new CreatePersonAccount.CreatePersonAccountInput();
        input.testerId = testerDetail.Id;

        List<CreatePersonAccount.CreatePersonAccountInput> inputs = new List<CreatePersonAccount.CreatePersonAccountInput>{ input };

        // Step 3: Execute the method
        Test.startTest();
        List<CreatePersonAccount.CreatePersonAccountOutput> outputs = CreatePersonAccount.createPersonAccount(inputs);
        Test.stopTest();

        // Step 4: Validate the outputs
        System.assertEquals(1, outputs.size(), 'There should be one output for one input');
        CreatePersonAccount.CreatePersonAccountOutput output = outputs[0];

        // Validate the created Account and Contact
        System.assertNotEquals(null, output.accountID, 'Account ID should not be null');
        System.assertNotEquals(null, output.contactID, 'Contact ID should not be null');

        // Fetch and validate the Account details
        Account createdAccount = [SELECT Id, PersonEmail, PersonBirthdate, FirstName, LastName, PersonGenderIdentity, PersonMobilePhone, 
                                   BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                                   FROM Account WHERE Id = :output.accountID];
        System.assertEquals(testerDetail.Email__c, createdAccount.PersonEmail, 'Email should match');
        System.assertEquals(testerDetail.Date_Of_Birth__c, createdAccount.PersonBirthdate, 'Birthdate should match');
        System.assertEquals(testerDetail.First_Name__c, createdAccount.FirstName, 'First name should match');
        System.assertEquals(testerDetail.Last_Name__c, createdAccount.LastName, 'Last name should match');
        System.assertEquals(testerDetail.Gender__c, createdAccount.PersonGenderIdentity, 'Gender should match');
        System.assertEquals(testerDetail.Phone__c, createdAccount.PersonMobilePhone, 'Phone number should match');
        System.assertEquals(testerDetail.Address_Line_1__c, createdAccount.BillingStreet, 'Billing Street should match');
        System.assertEquals(testerDetail.City__c, createdAccount.BillingCity, 'City should match');
        System.assertEquals(testerDetail.State__c, createdAccount.BillingState, 'State should match');
        System.assertEquals(testerDetail.Zip_Code__c, createdAccount.BillingPostalCode, 'Postal Code should match');
        System.assertEquals(testerDetail.Country__c, createdAccount.BillingCountry, 'Country should match');

        // Fetch and validate the Contact details
        Contact createdContact = [SELECT Id, AccountId FROM Contact WHERE Id = :output.contactID];
        System.assertEquals(output.accountID, createdContact.AccountId, 'Contact should be linked to the created Account');
    }
}