public with sharing class ActivateCustomer {
    public class ActivateCustomerInput {
        @InvocableVariable(label='Ping Fed Token' description='Ping Fed Token')
        public String token;
        @InvocableVariable(label='Customer Id' description='Customer ID')
        public String customerId; 
    }

    public class ActivateCustomerOutput {
        @InvocableVariable(label='Response Message' description='Response Message from PWN Service')
        public String responseMessage;
        @InvocableVariable(label='Response Code' description='Response Code from PWN Service')
        public String responseCode;
        @InvocableVariable(label='Request Payload' description='Request Payload')
        public String requestPayload;
        @InvocableVariable(label='Response Payload' description='Response Payload')
        public String responsePayload;
        @InvocableVariable(label='Status' description='Status')
        public String status;
    }

    @InvocableMethod(label='Activate Customer' description='Activate Customer')
    public static List<ActivateCustomerOutput> enableCustomer(List<ActivateCustomerInput> inputs)
    {
        List<ActivateCustomerOutput> output = new List<ActivateCustomerOutput>();

        for(ActivateCustomerInput serviceInput : inputs)
        {
            ActivateCustomerOutput serviceOutput = new ActivateCustomerOutput();
        String customerId = serviceInput.customerId;
        String token = serviceInput.token;
        
        Integer statusCode;
        String responseMessage = '';
        Http http = new Http();
        HttpResponse response;
        HttpRequest request = new HttpRequest();
                       
        try
        {
            JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                        gen.writeBooleanField('enabled', true);
                        gen.writeBooleanField('emailVerficationOnly', true);
                    gen.writeEndObject();
           

            String jsonStr = gen.getAsString();

            System.debug(jsonStr);

            String endpoint = Label.OMS_Mule_Proxy_Ednpoint;
            
           
            
            request.setEndpoint(endpoint+'qdx-customers-xapi-v1/customers/' +customerId+'/activate');
            request.setMethod('PATCH');
            request.setHeader('Content-Type','application/json');
            request.setHeader('Authorization','Bearer ' + token);
            request.setBody(jsonStr);
            System.debug('Request::'+request);
            
                
           
            serviceOutput.requestPayload = jsonStr;

                response = http.send(request); 
                statusCode = response.getStatusCode();
                
            serviceOutput.responsePayload = response.getBody();
                Map<String, Object> jsonResponseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

                if(statusCode==200){                    
                    serviceOutput.responseCode=String.valueOf(statusCode);
                    serviceOutput.responseMessage='Success';
                    serviceOutput.Status='Success';
                }
                else {      
                    String errorMessage='';
                    if (jsonResponseMap.containsKey('fault')) {
                        Map<String, Object> faultMap = (Map<String, Object>) jsonResponseMap.get('fault');
                        List<Object> messageList = (List<Object>) faultMap.get('message');
                        errorMessage = String.join(messageList, ' ');
                        if(faultMap.get('type')=='NOT_FOUND' || faultMap.get('type')=='INVALID')
                            statusCode =400;  
                    }
                    serviceOutput.responseCode=String.valueOf(statusCode);
                    serviceOutput.responseMessage=errorMessage;
                    serviceOutput.Status='Error';
                    System.debug(jsonResponseMap);
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
        System.debug(output);  
        return output;

    }
}