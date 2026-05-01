public with sharing class CreatePWNServiceOrder {

    public class PWNServiceInput {
        @InvocableVariable(label='Ping Fed Token' description='Ping Fed Token')
        public String token;
        @InvocableVariable(label='FulfillmentOrderID' description='Fulfillment order ID')
        public String FOID; 
    }

    public class PWNServiceOutput {
        @InvocableVariable(label='Response Message' description='Response Message from PWN Service')
        public String responseMessage;
        @InvocableVariable(label='Response Code' description='Response Code from PWN Service')
        public String responseCode;
        @InvocableVariable(label='Request Payload' description='Request Payload')
        public String requestPayload;
        @InvocableVariable(label='Response Payload' description='Response Payload')
        public String responsePayload;
        @InvocableVariable(label='SummaryID' description='SummaryID')
        public String summaryId;
        @InvocableVariable(label='Status' description='Status')
        public String status;

        @InvocableVariable(label='Physician First Name' description='Physician First Name')
        public String firstName;
        @InvocableVariable(label='Physician Last Name' description='Physician Last Name')
        public String lastName;
        @InvocableVariable(label='UPIN' description='UPIN')
        public String upin;
        @InvocableVariable(label='NPI' description='NPI')
        public String npi;
        @InvocableVariable(label='PWNID' description='PWNID')
        public String pwnID;
    }

    @InvocableMethod(label='Create PWN Service Order' description='Creates PWN Service Order and Updates FO with Physician Details')
    public static List<PWNServiceOutput> createPWNOrder(List<PWNServiceInput> inputs)
    {
        List<PWNServiceOutput> output = new List<PWNServiceOutput>();

        for(PWNServiceInput serviceInput : inputs)
        {
        String foId = serviceInput.FOID;
        String token = serviceInput.token;
        
        Integer statusCode;
        String responseMessage = '';
        Http http = new Http();
        HttpResponse response;
        HttpRequest request = new HttpRequest();
        PWNServiceOutput serviceOutput = new PWNServiceOutput();

        FulfillmentOrder fo = [select Id,OrderSummary.Id,OrderSummary.Client_Id__c,OrderSummary.BillingPhoneNumber,OrderSummary.CustomerId__c,OrderSummary.CustomerDOB__c,OrderSummary.Gender__c,OrderSummary.Account.FirstName,OrderSummary.Account.LastName,OrderSummary.BillingEmailAddress,
        FulfilledToAddress,LastName__c,FirstName__c,FulfilledToPhone
                                from FulfillmentOrder where Id =: foId];
            
                                Address address = fo.FulfilledToAddress;

                                                             
        List<FulfillmentOrderLineItem> items = [select Id, FulfillmentOrderLineItem.OrderItemSummary.Product2.ProductCode,FulfillmentOrderLineItem.OrderItemSummary.attestationJSON__c from FulfillmentOrderLineItem where FulfillmentOrderId =: foId and Test_Type__c = 'PSC'];
        try{
           
            List<Map<String, Object>> customAttributes = new List<Map<String, Object>>();
            for (FulfillmentOrderLineItem item : items) {
                    
                    if(item.OrderItemSummary.attestationJSON__c != null)
                    {
                        List<Object> aoeList = (List<Object>) JSON.deserializeUntyped(item.OrderItemSummary.attestationJSON__c);
                        List<Map<String, Object>> attestationJSON = new List<Map<String, Object>>();

                        for (Object obj : aoeList) {
                            if (obj instanceof Map<String, Object>) {
                                attestationJSON.add((Map<String, Object>)obj);
                            }
                        }

                        for (Map<String, Object> question : attestationJSON) {
                            Map<String, Object> consentQuestion = new Map<String, Object>();
                            for (String fieldName : question.keySet()) {
                                Object value = question.get(fieldName);
                                if(value != null)
                                {
                                    if (value instanceof String) {
                                        consentQuestion.put(fieldName, (String)value);
                                    } else if (value instanceof Decimal) {
                                        consentQuestion.put(fieldName, String.valueOf(value));
                                    } else if (value instanceof Boolean && fieldName != 'isAoe') {
                                        consentQuestion.put(fieldName, (Boolean)value);
                                    }
                                    else if(fieldName == 'isAoe')
                                    {
                                        Boolean isAOE = (Boolean) value;
                                        consentQuestion.put('questionType', isAOE ? 'AOE':'CONSENT');
                                    }
                                }
                            }
                            
                            customAttributes.add(consentQuestion);
                    }
                }
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
                gen.writeFieldName('order');
                    gen.writeStartObject();
                        gen.writeFieldName('tests');
                            gen.writeStartArray();
                                for (FulfillmentOrderLineItem item : items) {
                                    gen.writeString(item.OrderItemSummary.Product2.ProductCode);
                                }
                            gen.writeEndArray();


                            gen.writeFieldName('customAttributes');
                                gen.writeStartObject();
                                    gen.writeFieldName('aoe');
                                        gen.writeStartArray();
                                            for (Map<String, Object> question : customAttributes) {
                                                gen.writeStartObject();
                                                    for (String fieldName : question.keySet()) {
                                                        Object value = question.get(fieldName);
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
                                gen.writeEndObject();

                            gen.writeStringField('reference', foId);
                            gen.writeStringField('accountNumber', fo.OrderSummary.Client_Id__c);
                            gen.writeFieldName('customer');
                                gen.writeStartObject();
                                    gen.writeStringField('externalId', fo.OrderSummary.CustomerId__c);
                                    gen.writeStringField('lastName', fo.LastName__c!= null ? fo.LastName__c : fo.OrderSummary.Account.LastName);
                                    gen.writeStringField('gender', fo.OrderSummary.Gender__c != null ? fo.OrderSummary.Gender__c :'');
                                    gen.writeStringField('email', fo.OrderSummary.BillingEmailAddress);
                                    gen.writeStringField('homePhone', phoneNumber!= null? phoneNumber.replaceAll('[^0-9]', '') : '');
                                    gen.writeStringField('birthDate', fo.OrderSummary.CustomerDOB__c != null ? fo.OrderSummary.CustomerDOB__c :'' );
                                    gen.writeStringField('firstName', fo.FirstName__c!= null ? fo.FirstName__c : fo.OrderSummary.Account.FirstName);
                                    gen.writeFieldName('address');
                                        gen.writeStartObject();
                                            gen.writeStringField('zip', address.PostalCode);
                                            gen.writeStringField('city', address.City);
                                            gen.writeStringField('state', address.State);
                                            gen.writeStringField('line', address.Street);
                                        gen.writeEndObject();
                                gen.writeEndObject();
                    gen.writeEndObject();
            gen.writeEndObject();

            String jsonStr = gen.getAsString();

            

            String endpoint = Label.OMS_Mule_Proxy_Ednpoint;
            
            
            request.setEndpoint(endpoint+'qdx-pwn-proxy-api/orders?testType=PSC');
            request.setMethod('POST');
            request.setHeader('Content-Type','application/json');
            request.setHeader('Authorization','Bearer ' + token);
            request.setBody(jsonStr);
            System.debug('Request::'+request);
            System.debug('Request 1 ::'+jsonStr);

            serviceOutput.summaryId = fo.OrderSummary.Id;
                serviceOutput.requestPayload = jsonStr;
            
                
                response = http.send(request); 
                statusCode = response.getStatusCode(); 
                System.debug('Response Status::'+response.getStatus());
                System.debug('Response Body::'+response.getBody());
                serviceOutput.responsePayload = response.getBody();

               
                Map<String, Object> jsonResponseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

               
                
                if(statusCode==201){
                    
                
                Map<String, Object> orderDetails = (Map<String, Object>)jsonResponseMap.get('order');

                if (orderDetails != null) {
                    Map<String, Object> physicianDetails = (Map<String, Object>)orderDetails.get('physicianReview');
                    if (physicianDetails != null) {
                        
                        serviceOutput.firstName = (String)physicianDetails.get('firstName');
                        serviceOutput.lastName = (String)physicianDetails.get('lastName');
                        serviceOutput.upin = (String)physicianDetails.get('upin');
                        serviceOutput.npi = (String)physicianDetails.get('npi');
                        serviceOutput.pwnID = String.valueOf(orderDetails.get('id'));
                        
                    }
                }
                    
                    serviceOutput.responseCode=String.valueOf(statusCode);
                    serviceOutput.responseMessage='Success';
                    serviceOutput.Status='Success';
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
                    serviceOutput.Status='Error';
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
            serviceOutput.Status='Error';
            System.debug('Failed to create Transaction' + e.getMessage());
          }
          
          output.add(serviceOutput);
        }
          return output;
    }    
}