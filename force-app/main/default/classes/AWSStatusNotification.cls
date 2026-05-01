public with sharing class AWSStatusNotification {

    @AuraEnabled @InvocableVariable
    public String status;
    @AuraEnabled @InvocableVariable
    public String merchantOrderId;
    @AuraEnabled @InvocableVariable
    public String shlKey;
    @AuraEnabled @InvocableVariable
    public String shlLocation;
    @AuraEnabled @InvocableVariable
    public String namedCredential;
    @AuraEnabled @InvocableVariable
    public String labOrderNumber;
    @AuraEnabled @InvocableVariable
    public String clientName;

    public AWSStatusNotification(String status, String merchantOrderId, String shlKey, String shlLocation, String namedCredential,String labOrderNumber,String clientName) {
        this.status = status;
        this.merchantOrderId = merchantOrderId;
        this.shlKey = shlKey;
        this.shlLocation = shlLocation; 
        this.namedCredential = namedCredential;
        this.labOrderNumber = labOrderNumber;       
        this.clientName = clientName;   
    }

   
    public AWSStatusNotification() {

    }
}