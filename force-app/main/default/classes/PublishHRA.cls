public without sharing class PublishHRA {
    public class PublishHRAInput {
        @InvocableVariable(label='Ping Fed Token' description='Ping Fed Token')
        public String token;
        @InvocableVariable(label='Reference Order id' description='Reference Order Id')
        public String referenceId;
        @InvocableVariable(label='HRA Reference Number' description='HRA Reference Number')
        public String requisitionNumber;
        @InvocableVariable(label='Type' description='Type')
        public String type;
        @InvocableVariable(label ='Question Responses' description='Question Responses')
        public List<QuestionResponse> responses; 
    }
    public class PublishHRAOutput {
        @InvocableVariable(label='Response Message' description='Response Message from PWN Service')
        public String responseMessage;
        @InvocableVariable(label='Response Code' description='Response Code from PWN Service')
        public String responseCode;
        @InvocableVariable(label='Request Payload' description='Request Payload')
        public String requestPayload;
        @InvocableVariable(label='Response Payload' description='Response Payload')
        public String responsePayload;
        @InvocableVariable(label='Reference Order id' description='Reference Order id')
        public String referenceId;
        @InvocableVariable(label='Status' description='Status')
        public String status;

    }

    @InvocableMethod(label='Store HRA Responses' description='Store HRA Responses')
    public static List<PublishHRAOutput> publishHRAQuestionnaire(List<PublishHRAInput> inputs)
    {
        List<PublishHRAOutput> outputs = new List<PublishHRAOutput>();
        for(PublishHRAInput input : inputs)
        {
            PublishHRAOutput output = new PublishHRAOutput();
            
            System.debug('Input: ' + input);

            ResponsePayload payload = new ResponsePayload();

            if(input.type == 'LO')
            {
                Lab_Order__c order = [select Id,LabRefId__c,Client_Id__c from Lab_Order__c where Id =: input.referenceId];

                List<Lab_Panel_Test__c> tests = [select Id, Lab_Order_Panel__r.Performing_Site__c from Lab_Panel_Test__c where Lab_Order_Panel__r.Lab_Order__c =: input.referenceId];

                payload.labReferenceId = order.Id;
                payload.client=order.Client_Id__c;
                payload.performingSite=tests[0].Lab_Order_Panel__r.Performing_Site__c;

            }
            if(input.type == 'FO')
            {
                FulfillmentOrder fo = [select Id,OrderSummaryId,OrderSummary.Client_Id__c
                                from FulfillmentOrder where Id =: input.referenceId];

                List<FulfillmentOrderLineItem> items = [select Id,PerformingSite__c
                    from FulfillmentOrderLineItem where FulfillmentOrderId =: input.referenceId and Test_Type__c = 'PSC'];

                payload.labReferenceId = fo.Id;
                payload.client=fo.OrderSummary.Client_Id__c;
                payload.performingSite=items[0].PerformingSite__c;

            }

            payload.requisitionNumber = input.requisitionNumber.substring(4);
            
            List<QuestionResponse> filteredResponses = new List<QuestionResponse>();

            for (QuestionResponse response : input.responses) {

               if (response != null && response.Answer != null) {
                    filteredResponses.add(response);
                }
            }

            Map<String, Object> responseWrapper = new Map<String, Object>{
                'QuestionaireResponses' => filteredResponses
            };
            payload.questionnaireResponses = JSON.serialize(responseWrapper);

            
            String requestJSON = JSON.serializePretty(payload);
            output = callHRAService(requestJSON,input.token,input.referenceId);
            outputs.add(output);

        }

        return outputs;
    }

    private static PublishHRAOutput callHRAService(String requestJSON,String token,String referenceId)
    {
        PublishHRAOutput serviceOutput= new PublishHRAOutput();
        Http http = new Http();
        HttpResponse response;
        HttpRequest request = new HttpRequest();
        Integer statusCode;
        try{
            
            String endpoint = Label.OMS_Mule_Proxy_Ednpoint;
            
            
            request.setEndpoint(endpoint+'qdx-elabs-proxy-api/orders/healthriskassessments');
            request.setMethod('POST');
            request.setHeader('Content-Type','application/json');
            request.setHeader('Authorization','Bearer ' + token);
            request.setTimeout(60000);
            request.setBody(requestJSON);
            System.debug('Request::'+request);
                    
                
                serviceOutput.referenceId = referenceId;
                serviceOutput.requestPayload = requestJSON;

                response = http.send(request); 
                statusCode = response.getStatusCode(); 

                Map<String, Object> jsonResponseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                
               
                
                serviceOutput.responsePayload = response.getBody();

                if(statusCode==200){
                    serviceOutput.responseCode=String.valueOf(statusCode);
                    serviceOutput.responseMessage='Success';
                    serviceOutput.Status='Success';
                }
                else if(statusCode==504){
                    serviceOutput.responseCode=String.valueOf(statusCode);
                    serviceOutput.responseMessage='Timeout';
                    serviceOutput.Status='Timeout Error';
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
          return serviceOutput;
    }

    
public class ResponsePayload{
    public String labReferenceId{get;set;}
    public String requisitionNumber{get;set;}
    public String client{get;set;}
    
    public String performingSite{get;set;}
    public String questionnaireResponses{get;set;}

    
}
}