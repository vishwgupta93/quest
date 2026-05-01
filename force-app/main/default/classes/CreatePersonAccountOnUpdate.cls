public without sharing class CreatePersonAccountOnUpdate {
        public class CreatePersonAccountInput {
        @InvocableVariable(label='Person Detail Id' description='Person Detail Id')
        public String personId;
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

            Person_Record__c personDetail = [select Id,Address_Line_1__c,Address_Line_2__c,City__c,Country__c,Date_Of_Birth__c,Email__c,First_Name__c,Gender__c	,Last_Name__c,Phone__c,State__c,Postal_Code__c from Person_Record__c where Id =: input.personId ];

            System.debug('Tester : ' + personDetail);

            String accountId = '';
            String contactId = '';


                     
            // Create Person Account
            Account newPersonAccount = new Account();
            
            
            newPersonAccount.RecordTypeId = Label.SFOM_Person_Account_RecordType_Id; 
            newPersonAccount.PersonEmail = personDetail.Email__c;
            newPersonAccount.PersonBirthdate = personDetail.Date_Of_Birth__c;
            newPersonAccount.LastName = personDetail.Last_Name__c;
            newPersonAccount.FirstName = personDetail.First_Name__c;
            newPersonAccount.PersonGenderIdentity=personDetail.Gender__c;
            newPersonAccount.PersonMobilePhone=personDetail.Phone__c;

            // Set the billing address
            newPersonAccount.BillingStreet = personDetail.Address_Line_1__c ;
            newPersonAccount.BillingCity = personDetail.City__c;
            newPersonAccount.BillingState = personDetail.State__c;
            newPersonAccount.BillingPostalCode = personDetail.Postal_Code__c;
            newPersonAccount.BillingCountry = personDetail.Country__c;
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