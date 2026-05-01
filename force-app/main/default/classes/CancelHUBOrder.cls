public with sharing class CancelHUBOrder {
    public class CancelHUBOrderInput {
        @InvocableVariable(label='Ping Fed Token' description='Ping Fed Token')
        public String token;
        @InvocableVariable(label='FulfillmentOrderID' description='Fulfillment order ID')
        public String FOID; 
    }

    public class CancelHUBOrderOutput {
        @InvocableVariable(label='Response Message' description='Response Message from HUB Service')
        public String responseMessage;
        @InvocableVariable(label='Response Code' description='Response Code from HUB Service')
        public String responseCode;
        @InvocableVariable(label='Request Payload' description='Request Payload')
        public String requestPayload;
        @InvocableVariable(label='Response Payload' description='Response Payload')
        public String responsePayload;
        @InvocableVariable(label='SummaryID' description='SummaryID')
        public String summaryId;
        @InvocableVariable(label='Status' description='Status')
        public String status;
    }

    @InvocableMethod(label='Cancel HUB Order' description='Cancels HUB Order')
    public static List<CancelHUBOrderOutput> cancelHUBOrder(List<CancelHUBOrderInput> inputs)
    {
        List<CancelHUBOrderOutput> output = new List<CancelHUBOrderOutput>();

        for(CancelHUBOrderInput serviceInput : inputs)
        {
        CancelHUBOrderOutput serviceOutput = new CancelHUBOrderOutput();
        String foId = serviceInput.FOID;
        String token = serviceInput.token;
        
        Integer statusCode;
        String responseMessage = '';

        FulfillmentOrder fo = [select Id,OrderSummaryId,FirstName__c,LastName__c,MiddleName__c,
        OrderSummary.Client_Id__c,OrderSummary.BillingPhoneNumber,OrderSummary.CustomerId__c,
        OrderSummary.CustomerDOB__c,OrderSummary.Gender__c,OrderSummary.PreferredGender__c,
        OrderSummary.Account.FirstName,OrderSummary.Account.LastName,OrderSummary.Partner_Name__c,
        OrderSummary.BillingEmailAddress,FulfilledToAddressLine1__c,FulfilledToAddressLine2__c,
        OrderSummary.OrderNumber,LID__c,PWN_ID__c,Physician_First_Name__c,Physician_Last_Name__c,Physician_Upin__c,Physician_Npi__c,FulfilledToPhone,
                FulfilledToAddress
                                from FulfillmentOrder where Id =: foId];
            
                                Address address = fo.FulfilledToAddress;

                                                             
        List<FulfillmentOrderLineItem> items = [select Id,PerformingSite__c,Test_Type__c,Quantity,Status__c,
        FulfillmentOrderLineItem.OrderItemSummary.Name,
        FulfillmentOrderLineItem.OrderItemSummary.Description,
        FulfillmentOrderLineItem.OrderItemSummary.Product2.ProductCode,
         FulfillmentOrderLineItem.OrderItemSummary.HRAReq__c,Questionnaire_Submitted__c,
         FulfillmentOrderLineItem.OrderItemSummary.attestationJSON__c from FulfillmentOrderLineItem where FulfillmentOrderId =: foId and Test_Type__c = 'PSC'];

         String testType = items[0].Test_Type__c;
         String performingSite = items[0].PerformingSite__c;
         String gender = '';
         String addressLine1 = '';
         if(fo.OrderSummary.Gender__c == 'Male')
         {
            gender = 'M';
         }
         else if (fo.OrderSummary.Gender__c == 'Female')
         {
            gender = 'F';
         }
         if(fo.OrderSummary.Partner_Name__c == 'Google')
         {
            addressLine1 = address.street;
         }
         else {
            addressLine1 = fo.FulfilledToAddressLine1__c;
         }
         String phoneNumber = '';

         if(fo.OrderSummary.BillingPhoneNumber != null)
         {
            phoneNumber = fo.OrderSummary.BillingPhoneNumber;
         }
         else {
            phoneNumber = fo.FulfilledToPhone;
         }

         JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
            gen.writefieldName('customers');
            gen.writeStartArray();
                gen.writeStartObject();
                    gen.writeStringField('customerId', FO.OrderSummary.CustomerId__c);
                    gen.writeStringField('lastName', FO.LastName__c != null ? FO.LastName__c : fo.OrderSummary.Account.LastName );
                    gen.writeStringField('firstName', FO.FirstName__c != null ? FO.FirstName__c : fo.OrderSummary.Account.FirstName);
                    gen.writeStringField('middleName', FO.MiddleName__c != null ? FO.MiddleName__c : '');
                    gen.writeStringField('gender', gender); //we need to bring this SFCC
                    gen.writeStringField('preferredGender', '7'); //we need to bring this SFCC
                    gen.writeStringField('email', fo.OrderSummary.BillingEmailAddress);
                    gen.writefieldName('billingAddress');
                        gen.writeStartObject();
                            gen.writeStringField('addressLine1', addressLine1);
                            gen.writeStringField('addressLine2', FO.FulfilledToAddressLine2__c != null ? FO.FulfilledToAddressLine2__c : '');
                            gen.writeStringField('zip', address.PostalCode);
                            gen.writeStringField('city', address.City);
                            gen.writeStringField('state', address.State);
                            gen.writeStringField('country', address.Country);
                        gen.writeEndObject();
                    gen.writeStringField('mobilePhone', phoneNumber!= null? phoneNumber.replaceAll('[^0-9]', '') : '');
                    gen.writeStringField('homePhone', phoneNumber!= null? phoneNumber.replaceAll('[^0-9]', '') : '');
                    gen.writeStringField('birthDate', FO.OrderSummary.CustomerDOB__c != null ? FO.OrderSummary.CustomerDOB__c :'');
                    gen.writefieldName('orderSummaries');
                    gen.writeStartArray();
                        gen.writeStartObject();
                            gen.writeStringField('id', FO.OrderSummaryId);
                            gen.writeStringField('clientId', FO.OrderSummary.Client_Id__c);
                            gen.writeStringField('ecommOrderId', FO.OrderSummary.OrderNumber); 
                            gen.writeStringField('omsHomePhone', phoneNumber!= null? phoneNumber.replaceAll('[^0-9]', '') : ''); 
                            gen.writefieldName('fullfillmentOrders');
                            gen.writeStartArray();
                                gen.writeStartObject();
                                    gen.writeStringField('id', FO.Id);
                                    gen.writeStringField('pwnOrderId',Fo.PWN_ID__c); 
                                    gen.writeStringField('performingSite', performingSite); 
                                    gen.writeStringField('testType', testType);
                                    gen.writeStringField('status', 'cancelled');
                                    gen.writeStringField('lid', FO.LID__c);                                
                                gen.writefieldName('physician');
                                gen.writeStartObject();
                                    gen.writeStringField('name', FO.Physician_First_Name__c + ' ' + FO.Physician_Last_Name__c);
                                    gen.writeStringField('firstName', FO.Physician_First_Name__c != null ? FO.Physician_First_Name__c : '');
                                    gen.writeStringField('lastName', FO.Physician_Last_Name__c != null ? FO.Physician_Last_Name__c : '');
                                    gen.writeStringField('upin', FO.Physician_Upin__c != null ? FO.Physician_Upin__c : '');
                                    gen.writeStringField('npi', FO.Physician_Npi__c != null ? FO.Physician_Npi__c : '');
                                gen.writeEndObject();
                                gen.writefieldName('fullfillmentOrderItems');
                                gen.writeStartArray();
                                    for(FulfillmentOrderLineItem item : items){
                                        gen.writeStartObject();                                           
                                            gen.writeStringField('id', item.Id);
                                            gen.writeStringField('testName', item.OrderItemSummary.Name);
                                            gen.writeStringField('testCode', item.OrderItemSummary.Product2.ProductCode);
                                            gen.writeStringField('testType', item.Test_Type__c);
                                            gen.writeStringField('testDesc', item.OrderItemSummary.Description);
                                            gen.writeStringField('quantity', String.valueOf(item.Quantity));
                                            gen.writeStringField('status', 'cancelled');
                                            gen.writeBooleanField('isHra', item.OrderItemSummary.HRAReq__c);
                                            gen.writeBooleanField('questionnaireSubmitted', item.Questionnaire_Submitted__c);
                                            gen.writeBooleanField('kitActivated', false);
                                            if(item.OrderItemSummary.attestationJSON__c != null)
                                            {
                                                List<Object> aoeList = (List<Object>) JSON.deserializeUntyped(item.OrderItemSummary.attestationJSON__c);

                                                List<Map<String, Object>> attestationJSON = new List<Map<String, Object>>();
                                                for (Object obj : aoeList) {
                                                    if (obj instanceof Map<String, Object>) {
                                                        attestationJSON.add((Map<String, Object>)obj);
                                                    }
                                                }

                                                gen.writeFieldName('aoes');
                                                    gen.writeStartArray();
                                                    for (Map<String, Object> aoe : attestationJSON) {
                                                        gen.writeStartObject();  
                                                          for (String fieldName : aoe.keySet()) {
                                                            Object value = aoe.get(fieldName);
                                                            if(value != null)
                                                            {
                                                                if (value instanceof String) {
                                                                    gen.writeStringField(fieldName, (String)value);
                                                                } else if (value instanceof Decimal) {
                                                                    gen.writeStringField(fieldName, String.valueOf(value));
                                                                } else if (value instanceof Boolean) {
                                                                    gen.writeBooleanField(fieldName, (Boolean)value);
                                                                }
                                                            }
                                                        }
                                                        gen.writeEndObject();
                                                    }                                                    
                                                    gen.writeEndArray();
                                            }
                                        gen.writeEndObject();
                                    }                                    
                                gen.writeEndArray();
                            gen.writeEndObject();
                        gen.writeEndArray();
                    gen.writeEndObject();
                gen.writeEndArray();
            gen.writeEndObject();
        gen.writeEndArray();
    gen.writeEndObject();

        System.debug(gen.getAsString());

        serviceOutput = callHubService(gen.getAsString(),token,FO.OrderSummaryId);
        output.add(serviceOutput);
        }
        return output;

    }
    
    private static CancelHUBOrderOutput callHubService(String requestJSON,String token,String orderSummaryId)
    {
        CancelHUBOrderOutput serviceOutput= new CancelHUBOrderOutput();
        Http http = new Http();
        HttpResponse response;
        HttpRequest request = new HttpRequest();
        
        Integer statusCode;
        try{
            
            String endpoint = Label.OMS_Mule_Proxy_Ednpoint;
            request.setEndpoint(endpoint+'qdx-quanum-hub-proxy-api/orders');
            request.setMethod('PATCH');
            request.setHeader('Content-Type','application/json');
            request.setHeader('Authorization','Bearer ' + token);
            request.setTimeout(60000);
            request.setBody(requestJSON);
            System.debug('Request::'+request);

            serviceOutput.summaryId = orderSummaryId;
            serviceOutput.requestPayload = requestJSON;

            response = http.send(request); 
            statusCode = response.getStatusCode(); 

            Map<String, Object> jsonResponseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            
           
            
            serviceOutput.responsePayload = response.getBody();

                if(statusCode==200){
                    serviceOutput.responseCode=String.valueOf(statusCode);
                    serviceOutput.responseMessage='Success';
                    serviceOutput.status='Success';
                }
                else if(statusCode==504){
                    serviceOutput.responseCode=String.valueOf(statusCode);
                    serviceOutput.responseMessage='Timeout';
                    serviceOutput.status='Timeout Error';
                }
                else {      
                    String errorMessage='';          
                    if (jsonResponseMap.containsKey('error')) {
                        Map<String, Object> errorMap = (Map<String, Object>) jsonResponseMap.get('error');
                        Map<String, Object> faultMap = (Map<String, Object>) errorMap.get('fault');
                        List<Object> messageList = (List<Object>) faultMap.get('message');
                        errorMessage = String.join(messageList, ' ');
                    }
                    serviceOutput.responseCode=String.valueOf(statusCode);
                    serviceOutput.responseMessage=errorMessage;
                    serviceOutput.status='Error';
                }

                
          }
          catch(Exception e){
            if(response != null)
            {
                serviceOutput.responseCode=String.valueOf(statusCode);
                serviceOutput.responseMessage=response.getStatus() + ' Message: ' + response.getBody();
                serviceOutput.responsePayload = response.getBody();
            }
            else {
                serviceOutput.responseMessage=e.getMessage();
                serviceOutput.responsePayload = e.getMessage();
                serviceOutput.responseCode='504';
            }
            serviceOutput.status='Error';
            System.debug('Failed to create Transaction' + e.getMessage());
          }
          
          return serviceOutput;
    } 
}