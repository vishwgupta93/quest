public class EmailEventHandler{
    
    @future (callout=true)
    public static void sendPayLoad(String orderSummaryId, String eventKey)
    {
        
        OrderSummary orderSummary = [select Account.PersonEmail,BillingAddress,BillingEmailAddress,OrderNumber,CustomerId__c,OrderedDate,GrandTotalAmount,Partner_Name__c,ecomCustomerId__c,acceptedConsents__c from OrderSummary where Id =: orderSummaryId];
        
        List<OrderItemSummary> items = [select Id,TestType__c,Is_Service__c,HRAReq__c,fulfillmentPartner__c,resultingRequired__c from OrderItemSummary where OrderSummaryId =: orderSummaryId and TestType__c != 'PA' and Type != 'Delivery Charge'];
        
         Address address = orderSummary.BillingAddress;

        Set<String> testTypes = new Set<String>();
        Boolean isMixedCart =false;
        Boolean isHomeCollectionKit = false;
        Boolean isExamOne =false;
        Boolean isHRA=false;
        Boolean isGoogle=false;
        Boolean isThirdParty=false;
        String thirdPartyPartner='';
        String email = orderSummary.Account.PersonEmail;
        
        
        for(OrderItemSummary item : items)
        {
            testTypes.add(item.TestType__c);
            if(item.Is_Service__c)
                isExamOne =true;
            if(item.HRAReq__c)
                isHRA=true;
            if(item.TestType__c == 'at_home')
                isHomeCollectionKit = true;
            if(item.TestType__c != 'PSC' && item.TestType__c != 'PackHealth' && !item.resultingRequired__c)
            {
                isThirdParty =true;
                thirdPartyPartner = item.fulfillmentPartner__c;
            }
            
            
        }
        
        if(orderSummary.Partner_Name__c =='google')
            isGoogle=true;
        
        String testsCommaSeparted = String.join(new List<String>(testTypes), ',');
        if (testTypes.size() > 1)
            isMixedCart = true;
        
        Integer statusCode;
        DateTime currentTime = System.now();
        
        String encryptedOrderNumber = LabOrderCryptoUtils.enryptOrderNumberFromSFCC(orderSummary.OrderNumber);
        String orderRegistrationURL = Label.Experience_Cloud_Registration_URL + '?ordernumber=' + encryptedOrderNumber;
        
        String eventTime = currentTime.format('yyyy-MM-dd HH:mm:ss');
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('ContactKey',orderSummary.Account.Id);
        //gen.writeStringField('ContactKey',String.valueOf(currentTime.getTime()));
        gen.writeStringField('EventDefinitionKey',eventKey);
        gen.writeFieldName('Data');
        gen.writeStartObject();
        
        gen.writeStringField('customer_id',  orderSummary.Account.Id);
        gen.writeStringField('email_address',email != null ? email : orderSummary.BillingEmailAddress);
        gen.writeStringField('OrderSummaryId', orderSummaryId);
        gen.writeStringField('order_number', orderSummary.OrderNumber);
        gen.writeDateTimeField('order_date', orderSummary.OrderedDate);
        gen.writeNumberField('order_total',orderSummary.GrandTotalAmount);
        gen.writeStringField('Test_Type', testsCommaSeparted);
        gen.writeStringField('Kit_Status', '');
        gen.writeBooleanField('Is_Kit_Event', false);
        gen.writeBooleanField('Mixed_cart', isMixedCart);
        gen.writeBooleanField('is_hra', isHRA);                   
        gen.writeBooleanField('is_google', isGoogle);
        gen.writeBooleanField('is_third_party', isThirdParty);    
        // System.debug('Third party : ' + isThirdParty); 
        gen.writeStringField('third_party_partner_name', thirdPartyPartner);            
        gen.writeBooleanField('quest_home_collection_kit', isHomeCollectionKit);
        gen.writeStringField('url', orderRegistrationURL);
        gen.writeBooleanField('is_examone', isExamOne);
        gen.writeStringField('Event_time', eventTime );
        gen.writeStringField('state_code', (address != null && address.state != null) ? address.State : '');
        gen.writeStringField('sfmc_insert_date', Date.today().format());
        gen.writeStringField('acceptedConsents', orderSummary.acceptedConsents__c != null ? orderSummary.acceptedConsents__c : ''); 
        gen.writeStringField('ecomCustomerId', orderSummary.ecomCustomerId__c != null ? orderSummary.ecomCustomerId__c: '');
        gen.writeStringField('legacyCustomerID', orderSummary.CustomerId__c != null ? orderSummary.CustomerId__c: '');
        
        
        
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
            
            System.debug(statusCode ); 
            
            Event_Log__c eventLog = new Event_Log__c();
            eventLog.Order_Summary__c =orderSummaryId;
            
            eventLog.Event_Type__c ='Order Confirmation';
            
            
            eventLog.Order_Summary__c =orderSummaryId;
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
            
            OrderSummary os = new OrderSummary();
            os.id = orderSummaryId;
            os.Registration_URL__c = orderRegistrationURL;
            update os;

            Contact contact = [select Id from Contact where AccountId =: orderSummary.Account.Id Limit 1];

             Contact updatedContact = new Contact(Id = contact.Id, ecomCustomerId__c = orderSummary.ecomCustomerId__c,Accepted_Consents__c=orderSummary.acceptedConsents__c);
             update updatedContact;
        }
        catch(Exception e){
            System.debug('Failed to create Transaction' + e.getMessage());
            
        }
    }
}