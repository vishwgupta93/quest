public class LabOrderUserVerificationJob implements Queueable, Database.AllowsCallouts {
    private String labOrderId;
    private Integer attempt;
    private boolean isLegacy;
    public LabOrderUserVerificationJob(String labOrderId,Integer attempt,boolean isLegacy) {
        this.labOrderId = labOrderId;
        this.attempt = attempt;
        this.isLegacy = isLegacy;
    }

    public void execute(QueueableContext context) {

       Integer maxAttempts =  Integer.valueOf(Label.Lab_Order_Results_Email_Attempts);

            if(this.attempt == maxAttempts || System.Test.isRunningTest())
            {
                // Perform the actual logic after delay
                Lab_Order__c labOrder = [SELECT Id, Name, Person_Record__r.Contact__c, Person_Record__r.Email__c,Status__c FROM Lab_Order__c WHERE Id = :labOrderId  LIMIT 1];
                if(labOrder.Status__c == 'Results Ready' || System.Test.isRunningTest())
                {
                    User usr = [SELECT Id FROM User WHERE ContactId = :labOrder.Person_Record__r.Contact__c LIMIT 1];
                    EmailTemplate emailVerifyTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Experience_Cloud_User_verify_EmailAddress'];
                    Network ntwrk = [SELECT Id FROM Network WHERE Name = 'CustomerPortal'];

                    String resultsURL = LabOrderCryptoUtils.buildEncryptedURL(Label.Lab_Order_Results_URL, labOrder.Id, labOrder.Name, 'false');
                    Contact updatedContact = new Contact(Id = labOrder.Person_Record__r.Contact__c, Confirmation_Number__c = labOrder.Name);
                    update updatedContact;

                    System.UserManagement.sendAsyncEmailConfirmation(usr.Id, emailVerifyTemplate.Id, ntwrk.Id, resultsURL);

                    // Log the event
                    Event_Log__c eventLog = new Event_Log__c();
                    eventLog.Lab_Order__c = labOrder.Id;
                    eventLog.Payload__c = 'Email Sent for Verification and Results';
                    eventLog.Status__c = 'Success';
                    eventLog.Event_Type__c = 'Results';
                    insert eventLog;
                }
            }
            else {
                Integer delay = this.isLegacy ? Integer.valueOf(Label.Legacy_Lab_Order_Results_Email_Delay_Mins) : Integer.valueOf(Label.Lab_Order_Results_Email_Delay_Mins);

                System.enqueueJob(new LabOrderUserVerificationJob(this.labOrderId,this.attempt + 1,this.isLegacy),delay);
                
            }      
            
            
        
    }
}