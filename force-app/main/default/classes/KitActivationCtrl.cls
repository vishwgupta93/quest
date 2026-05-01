public without sharing class KitActivationCtrl {
    
    @AuraEnabled
    public static List<Kit_Details__c> getActivatedKit(String orderNumber){
        try{
            return [Select Id, Ordered_Date__c, Activation_Code__c, Order_Summary__c,Partner_Name__c, Fulfillment_Order_Id__c, Fulfillment_Order_Line_Id__c, 
                    Product_Description__c, Status__c, Record_Type__c,  Product__r.Excluded_State_codes__c, Product__r.Min_age__c, 
                    Product__r.Max_age__c, Product__r.Gender__c From Kit_Details__c 
                    where Activation_Code__c =: orderNumber];
        } catch(Exception ex){
            throw new AurahandledException(ex.getMessage());
        }
    } 

    @AuraEnabled
    public static Tester_Detail__c createTesterDetail(Tester_Detail__c testerDetail){
        try{
            upsert testerDetail;
            return testerDetail;
        }catch(Exception ex){
            throw new AurahandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean createLabOrder(String testerDetailId, List<String> foLineIds){
        try{
            Map<String,Object> inputs = new Map<String, Object>();
            inputs.put('TesterID',testerDetailId);
            inputs.put('FOLineIDs',foLineIds);
            String contactId = '';
            Flow.Interview.Quest_Experience_Cloud_Submit_Action_Kit flow = new Flow.Interview.Quest_Experience_Cloud_Submit_Action_Kit(inputs);
            if(!System.Test.isRunningTest())
            {
                flow.start();
                contactId = (String) flow.getVariableValue('varContactId');                
            }
            createCustomerUser(contactId);
            return true;
        }catch(Exception ex){
            throw new AurahandledException(ex.getMessage());
        }
    }

    @future 
    public static void createCustomerUser(String contactId){
        if(String.isNotBlank(contactId)){
            Contact con = [SELECT Id,FirstName,LastName, Email FROM Contact WHERE Id =: contactId];
            List<User> users = [SELECT Id FROM User WHERE ContactId =: contactId];
            User u = new User();
            u.Alias = ((con.FirstName != null ? con.FirstName.left(1) : '') + con.LastName).left(7).toLowerCase();
            u.CommunityNickname = con.LastName.left(20) + '_' + contactId;
            u.ContactId = contactId;
            u.Email = con.Email; 
            u.EmailEncodingKey = 'UTF-8';
            u.IsActive = true;
            u.LanguageLocaleKey = 'en_US';
            u.LastName = con.LastName;
            u.FirstName = con.FirstName;
            u.LocaleSidKey = 'en_US';
            u.ProfileId = [SELECT ID FROM Profile WHERE Name = 'Customer Community Login User'].Id;
            u.TimeZoneSidKey = 'America/Chicago';
            u.Username = con.LastName.replaceAll(' ', '') + '_' + contactId + '@quest.com';
           if(!Test.isRunningTest())
            {
                if(users.isEmpty()){
                    insert u;
                }else{
                    u.Id = users[0].Id;
                    update u;
                }
            }
        }
    }
}