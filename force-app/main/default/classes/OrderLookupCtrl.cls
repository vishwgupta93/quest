public without sharing class OrderLookupCtrl {
    
    @AuraEnabled
    public static String getLineItemsByOrderNumber(String orderNumber){
        try{
            List<FulfillmentOrderLineItem> folList = new List<FulfillmentOrderLineItem> ();
            OrderRegistrationUIWrapper wrapObj;
            if (orderNumber == null || (orderNumber != null && orderNumber.startsWith(Label.Quest_Legacy_Order_Prefix))) 
            {
                wrapObj  =  new OrderRegistrationUIWrapper(folList);
                return JSON.Serialize(wrapObj);
            }
            folList = [SELECT   Id, Description, Test_Type__c, FulfillmentOrder.Record_Type__c, FulfillmentOrder.OrderExpirationDate__c, FulfillmentOrder.Status,
                                FulfillmentOrderId,FulfillmentOrder.OrderSummary.OrderedDate, FulfillmentOrder.OrderSummary.OrderNumber,Is_Registered__c,
                                Product2.AOE_required__c, Product2.Gender__c,Product2.Exclude_from_registration__c, Product2.Excluded_State_codes__c, Product2.Max_age__c, Product2.Min_age__c,
                                Product2.ProductCode, FulfillmentOrder.OrderSummaryId, ProductName__c,FulfillmentOrder.OrderSummary.BillingAddressLine1__c,
                                FulfillmentOrder.OrderSummary.BillingAddressLine2__c,FulfillmentOrder.OrderSummary.BillingCity,FulfillmentOrder.OrderSummary.BillingCountry,
                                FulfillmentOrder.OrderSummary.BillingPostalCode,FulfillmentOrder.OrderSummary.BillingState,FulfillmentOrder.OrderSummary.BillingPhoneNumber,
                                FulfillmentOrder.OrderSummary.BillingEmailAddress,
                                FulfillmentOrder.FirstName__c, 
                                FulfillmentOrder.LastName__c,
                                Is_Service__c
                                FROM FulfillmentOrderLineItem
                                WHERE FulfillmentOrder.OrderSummary.OrderNumber =: orderNumber
                                AND Test_Type__c IN ('at_home', 'PSC','PackHealth','consult')
                     ];
            

            system.debug('@21,'+folList);
            if(folList.isEmpty()){
                List<Commerce_Order_Info__c> coiList = [SELECT Id, CreatedDate, Order_Number__c, Address_Line_1__c, 
                                                        Address_Line_2__c, City__c, Postal_Code__c, State__c, Email__c, 
                                                        Test_Codes__c, First_Name__c, Last_Name__c,Phone_Number__c 
                                                        FROM Commerce_Order_Info__c 
                                                        WHERE Order_Number__c =: orderNumber];
                if(!coiList.isEmpty()){
                    system.debug('@29,'+coiList);
                    wrapObj =  new OrderRegistrationUIWrapper(coiList[0]);
                    System.debug(JSON.Serialize(wrapObj));
                }
            }else{
                system.debug('@33,'+folList);
                wrapObj = new OrderRegistrationUIWrapper(folList);
            }
            return JSON.Serialize(wrapObj);
        } catch(Exception ex){
            throw new AurahandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String decryptData(String orderNumber){
        String result = LabOrderCryptoUtils.decodeOrderNumberFromSFCC(orderNumber);
        System.Debug('RESULT:::'+result);
        return result;
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
    public static String createLabOrder(String testerDetailId, List<String> foLineIds, Boolean isService){
        try{
            Map<String,Object> inputs = new Map<String, Object>();
            inputs.put('TesterID',testerDetailId);
            inputs.put('FOLineIDs',foLineIds);
            String contactId = '';
            String labOrderNumber;
            system.debug('inputs-->'+inputs);  
            Flow.Interview.Quest_Experience_Cloud_Submit_Action flow = new Flow.Interview.Quest_Experience_Cloud_Submit_Action(inputs);
            if(!System.Test.isRunningTest())
            {
                flow.start();
                contactId = (String) flow.getVariableValue('varContactId');  
                labOrderNumber = (String) flow.getVariableValue('LabOrderNumber');
            }
            system.debug('contactId-->'+contactId);    
            system.debug('LabOrderId-->'+labOrderNumber);               
            createCustomerUser(contactId);
            
            OrderRegistrationUIWrapper response =  new OrderRegistrationUIWrapper();
            response.labOrderId= labOrderNumber;
            response.isService=isService;
            system.debug('response-->'+response); 
            String jsonResponse = JSON.serialize(response); 
            return jsonResponse;
        }catch(Exception ex){
            throw new AurahandledException(ex.getMessage());
        }
    }
    
    @future 
    public static void createCustomerUser(String contactId){
        if(String.isNotBlank(contactId))
        {
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