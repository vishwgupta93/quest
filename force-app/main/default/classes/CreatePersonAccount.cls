public without sharing class CreatePersonAccount {
    public class CreatePersonAccountInput {
        @InvocableVariable(label='Person Detail Id' description='Person Detail Id')
        public String testerId;
       }

    public class CreatePersonAccountOutput {
        @InvocableVariable(label='Account ID' description='Account ID')
        public String accountID;

        @InvocableVariable(label='Contact ID' description='Contact ID')
        public String contactID;
      }

    @InvocableMethod(label='Creates Person Account For the Given details' description='Creates Person Account For the Given details')
    public static List<CreatePersonAccountOutput> createPersonAccount(List<CreatePersonAccountInput> inputs) {

        List<CreatePersonAccountOutput> outputs = new List<CreatePersonAccountOutput>();

        for(CreatePersonAccountInput input : inputs)
        {
            CreatePersonAccountOutput output = new CreatePersonAccountOutput();

            Tester_Detail__c testerDetail = [select Id,Address_Line_1__c,Address_Line_2__c,City__c,Country__c,Date_Of_Birth__c,Email__c,First_Name__c,Gender__c	,Last_Name__c,Middle_Name__c,Phone__c,State__c,Zip_Code__c from Tester_Detail__c where Id =: input.testerId ];

            System.debug('Tester : ' + testerDetail);

            String accountId = '';
            String contactId = '';


                     
            // Create Person Account
            Account newPersonAccount = new Account();
            
            
            newPersonAccount.RecordTypeId = Label.SFOM_Person_Account_RecordType_Id; 
            newPersonAccount.PersonEmail = testerDetail.Email__c;
            newPersonAccount.PersonBirthdate = testerDetail.Date_Of_Birth__c;
            newPersonAccount.LastName = testerDetail.Last_Name__c;
            newPersonAccount.FirstName = testerDetail.First_Name__c;
            newPersonAccount.PersonGenderIdentity=testerDetail.Gender__c;
            newPersonAccount.PersonMobilePhone=testerDetail.Phone__c;

            // Set the billing address
            newPersonAccount.BillingStreet = testerDetail.Address_Line_1__c ;
            newPersonAccount.BillingCity = testerDetail.City__c;
            newPersonAccount.BillingState = testerDetail.State__c;
            newPersonAccount.BillingPostalCode = testerDetail.Zip_Code__c;
            newPersonAccount.BillingCountry = testerDetail.Country__c;
            insert newPersonAccount;
            Contact contact = [select Id from contact where accountId =: newPersonAccount.Id];
            contactId = contact.Id;
            
            

            output.accountID=newPersonAccount.Id;
            output.contactID=contactId;

            outputs.add(output);

        }

        System.debug(outputs);
        
        return outputs;

    }
}