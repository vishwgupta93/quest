public class LabOrderResultsHandler {
    
    @future (callout=true)
    public static void sendPayLoad(String labOrderId, String eventKey, String testType, Boolean isMFAEnabled)
    {
        
        Event_Log__c eventLog = new Event_Log__c();
        Lab_Order__c labOrder = [select Id,Name,CreatedDate,Order_Summary__c,Client_Id__c,Kit_Detail__c,Is_Leagcy__c,Pre_Shop_Rocket__c,
        Account__c,Person_Record__r.Contact__r.AccountId,Person_Record__r.Email__c,Person_Record__r.Contact__c,Order_Summary__r.GrandTotalAmount, Order_Summary__r.acceptedConsents__c,
        Kit_Detail__r.Lab_Status__c,Kit_Detail__r.Tracking_Number__c,Kit_Detail__r.Partner_Name__c,Kit_Detail__r.Order_Number__c
                            from Lab_Order__c where Id =: labOrderId];

         eventLog.Lab_Order__c =labOrder.id;
         eventLog.Kit_Detail__c=laborder.Kit_Detail__c;                        
         eventLog.Event_Type__c ='Results';
        
        // Check if the User is Verified

        User usr = null;
        boolean isGSS =  testType == 'GSS' ? true : false;


        if(!isGSS)
            usr = [SELECT Id, Email, IsActive FROM User WHERE ContactId = :labOrder.Person_Record__r.Contact__c Limit 1];
        
        List<TwoFactorMethodsInfo> verifiedInfo ;
        boolean isUserVerified = false;

       if (!System.Test.isRunningTest() && !isGSS && usr!=null) {
                verifiedInfo = [SELECT HasUserVerifiedEmailAddress FROM TwoFactorMethodsInfo WHERE UserId = :usr.Id];
                isUserVerified = !verifiedInfo.isEmpty() && verifiedInfo[0].HasUserVerifiedEmailAddress == true;
        } else {
            verifiedInfo = new List<TwoFactorMethodsInfo>();
        }

        boolean isSFMCEvent = !isMFAEnabled || isUserVerified || isGSS;
        
        if (isSFMCEvent) {
             String customerId = labOrder.Account__c;
            if(String.isBlank(customerId))
            {
                customerId = labOrder.Person_Record__r.Contact__r.AccountId;
            }

            String resultsURL = !isGSS ? LabOrderCryptoUtils.buildEncryptedURL(Label.Lab_Order_Results_URL, labOrder.Id, labOrder.Name,'true') : '';
            String orderNumber = isGSS ? labOrder.Kit_Detail__r.Order_Number__c : labOrder.Name;
            String email = labOrder.Person_Record__r.Email__c;
            Integer statusCode;
            DateTime currentTime = System.now();
            String eventTime = currentTime.format('yyyy-MM-dd HH:mm:ss');
            JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeStringField('ContactKey',labOrder.Person_Record__r.Contact__r.AccountId);
            
                gen.writeStringField('EventDefinitionKey',eventKey);
                gen.writeFieldName('Data');
                    gen.writeStartObject();
                        gen.writeStringField('customer_id', customerId);
                        gen.writeStringField('email_address',labOrder.Person_Record__r.Email__c);
                        gen.writeStringField('OrderSummaryId', labOrder.Id);
                        gen.writeStringField('order_number', orderNumber);
                        gen.writeDateTimeField('order_date', labOrder.CreatedDate);
                        gen.writeNumberField('order_total',labOrder.Order_Summary__r.GrandTotalAmount != null ? labOrder.Order_Summary__r.GrandTotalAmount : 0.0);
                        gen.writeStringField('Test_Type', testType);
                        gen.writeStringField('url', resultsURL);

                        if(isGSS)
                        {
                            //GSS
                            gen.writeStringField('tracking_number', labOrder.Kit_Detail__r.Tracking_Number__c);
                            gen.writeStringField('lab_status', labOrder.Kit_Detail__r.Lab_Status__c);
                            gen.writeStringField('partner_name', labOrder.Kit_Detail__r.Partner_Name__c);
                            gen.writeBooleanField('is_partner', labOrder.Kit_Detail__r.Partner_Name__c == 'Quest' ? false : true);

                        }

                        gen.writeStringField('Event_time', eventTime );
                        gen.writeStringField('sfmc_insert_date', Date.today().format());
                        gen.writeEndObject();
                gen.writeEndObject();

                String jsonStr = gen.getAsString();
                    
            String httpBody = jsonStr;
            //String endpoint = Label.SFMC_Rest_Endpoint + '/interaction/v1/events';
            //List<SFMC_OMS_Config__c> configs = [select Id, Auth_Token__c from SFMC_OMS_Config__c  where Channel__c = 'QD-CIT' and API__C = 'Common'];
            //String token = configs[0].Auth_Token__c;
            
            String endpoint = 'callout:SFMC_Endpoint/interaction/v1/events';
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type','application/json');
            //request.setHeader('Authorization','Bearer ' + token);
            request.setBody(httpBody);
            System.debug('Request::'+request);
            System.debug(httpBody);

        
            try{
                HttpResponse response = http.send(request); 
                statusCode = response.getStatusCode(); 
                System.debug(response.getBody());  
                System.debug(statusCode );               
                                
                eventLog.Payload__c=httpBody;    
    
            
            if(statusCode==201){
                System.debug('Success : ' + response.getBody()); 
                eventLog.Status__c='Success';
                eventLog.Response_Payload__c=response.getBody();
            }
            else{
                System.debug('Error : ' + response.getBody());
                eventLog.Status__c='Error'; 
                eventLog.Response_Payload__c=response.getBody();
            }

            
            
            insert eventLog;
            
        }
         catch(Exception e){
                System.debug('Failed to create Transaction' + e.getMessage());
                eventLog.Status__c = 'Error';
                eventLog.Response_Payload__c = e.getMessage();
            
            }
        }
        else{
            if(labOrder.Pre_Shop_Rocket__c)
            {
                    usr = [SELECT Id FROM User WHERE ContactId = :labOrder.Person_Record__r.Contact__c LIMIT 1];
                    EmailTemplate emailVerifyTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Experience_Cloud_User_verify_EmailAddress'];
                    Network ntwrk = [SELECT Id FROM Network WHERE Name = 'CustomerPortal'];

                    String resultsURL = LabOrderCryptoUtils.buildEncryptedURL(Label.Lab_Order_Results_URL, labOrder.Id, labOrder.Name, 'false');
                    Contact updatedContact = new Contact(Id = labOrder.Person_Record__r.Contact__c, Confirmation_Number__c = labOrder.Name);
                    update updatedContact;

                    System.UserManagement.sendAsyncEmailConfirmation(usr.Id, emailVerifyTemplate.Id, ntwrk.Id, resultsURL);

                    // Log the event
                    eventLog = new Event_Log__c();
                    eventLog.Lab_Order__c = labOrder.Id;
                    eventLog.Payload__c = 'Email Sent for Verification and Results';
                    eventLog.Status__c = 'Success';
                    eventLog.Event_Type__c = 'Results';
                    insert eventLog;
            }
            else{
                Integer delay = labOrder.Is_Leagcy__c ? Integer.valueOf(Label.Legacy_Lab_Order_Results_Email_Delay_Mins) : Integer.valueOf(Label.Lab_Order_Results_Email_Delay_Mins);

                System.enqueueJob(new LabOrderUserVerificationJob(labOrder.Id,1,labOrder.Is_Leagcy__c),delay);
            }


           
        }

        

    }
}