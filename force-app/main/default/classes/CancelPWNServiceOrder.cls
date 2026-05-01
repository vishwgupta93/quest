public with sharing class CancelPWNServiceOrder {
    
    public class CancelPWNServiceInput {
        @InvocableVariable(label='Ping Fed Token' description='Ping Fed Token')
        public String token;
        @InvocableVariable(label='FulfillmentOrderID' description='Fulfillment order ID')
        public String FOID; 
    }

    public class CancelPWNServiceOutput {
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
    }
    
    
    @InvocableMethod(label='Cancel PWN Service Order' description='Cancels PWN Service Order')
    public static List<CancelPWNServiceOutput> cancelPWNOrder(List<CancelPWNServiceInput> inputs)
    {
        List<CancelPWNServiceOutput> output = new List<CancelPWNServiceOutput>();

        for(CancelPWNServiceInput serviceInput : inputs)
        {
        CancelPWNServiceOutput serviceOutput = new CancelPWNServiceOutput();
        String foId = serviceInput.FOID;
        String token = serviceInput.token;
        
        Integer statusCode;
        String responseMessage = '';
        Http http = new Http();
        HttpResponse response;
        HttpRequest request = new HttpRequest();
        Event_Log__c eventLog = new Event_Log__c();

        FulfillmentOrder fo = [select ID,OrderSummaryId,PWN_ID__c from FulfillmentOrder where Id =: foId];
        
        try
        {
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
                gen.writeFieldName('order');
                    gen.writeStartObject();
                        gen.writeStringField('cancelationReason', 'patient_requested');
                    gen.writeEndObject();
            gen.writeEndObject();

            String jsonStr = gen.getAsString();

            String endpoint = Label.OMS_Mule_Proxy_Ednpoint;
            
           
            
            request.setEndpoint(endpoint+'qdx-pwn-proxy-api/orders/' +fo.PWN_ID__c+'?testType=PSC');
            request.setMethod('PATCH');
            request.setHeader('Content-Type','application/json');
            request.setHeader('Authorization','Bearer ' + token);
            request.setBody(jsonStr);
            System.debug('Request::'+request);
            
                
            serviceOutput.summaryId = fo.OrderSummaryId;
            serviceOutput.requestPayload = jsonStr;

                response = http.send(request); 
                statusCode = response.getStatusCode();
                
            serviceOutput.responsePayload = response.getBody();
                Map<String, Object> jsonResponseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

               
                
                
                if(statusCode==201){                    
                    serviceOutput.responseCode=String.valueOf(statusCode);
                    serviceOutput.responseMessage='Success';
                    serviceOutput.Status='Success';
                }
                else {      
                    String errorMessage='';
                    String errorType = (String)  jsonResponseMap.get('errorType');
                    statusCode =  errorType == 'DATA_ERROR'   ? 400 : 500;  
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