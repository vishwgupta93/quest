public without sharing class PublishAppointmentConfirmation {
    public class Request {
        @InvocableVariable(label='Lab Order id' description='Lab Order Id')
        public String labOrderId; 
    }

    public class Response {
        
        @InvocableVariable(label='Response Message' description='Response Message from PWN Service')
        public String responseMessage;
        @InvocableVariable(label='Response Code' description='Response Code from PWN Service')
        public String responseCode;
        @InvocableVariable(label='Request Payload' description='Request Payload')
        public String requestPayload;
        @InvocableVariable(label='Response Payload' description='Response Payload')
        public String responsePayload;
        @InvocableVariable(label='Lab Order Id' description='LabOrderId')
        public String labOrderId;
        @InvocableVariable(label='Status' description='Status')
        public String status;
    }

    @InvocableMethod(label='Publish Appointment Confirmation' description='Publish Appointment Confirmation')
    public static List<Response> sendRequest(List<Request> requests)    
    {
        List<Response> responses = new List<Response>();

       
            for(Request request : requests)
            {
                Integer statusCode;
                String responseMessage = '';
                Http http = new Http();
                HttpResponse httpResponse;
                HttpRequest httpRequest = new HttpRequest();
                Response response = new Response();
                Lab_Order__c labOrder = [select Id,Lab_Order_ID_Uppercase__c,Partner_Client_Map__r.Client_ID__c,Appointment_Confirmation_Code__c  from Lab_Order__c where Id =: request.labOrderId];

                List<Lab_Order_Panel__c> tests = [ SELECT Id, Performing_Site__c FROM Lab_Order_Panel__c WHERE Lab_Order__c =: request.labOrderId ];
                
                String performingSite = tests[0].Performing_Site__c;

                Map<String, Object> payload = new Map<String, Object>{
                    'appointmentConfirmation' => labOrder.Appointment_Confirmation_Code__c,
                    'labReferenceID' => labOrder.Lab_Order_ID_Uppercase__c,
                    'performingSite' => performingSite,
                    'clientNumber' => labOrder.Partner_Client_Map__r.Client_ID__c
                };

                String jsonPayload = JSON.serialize(payload);

                String endpoint =  'callout:Quest_Base_EndPoint/qdx-partner-testing-proxy-api/appointment/order';
                httpRequest.setEndpoint(endpoint);
                httpRequest.setMethod('POST');
                httpRequest.setHeader('Content-Type','application/json');
                httpRequest.setBody(jsonPayload);
                System.debug('Request::'+httpRequest);
                System.debug('Request 1 ::'+jsonPayload);

                response.labOrderId = request.labOrderId;
                response.requestPayload = jsonPayload;
                
                try 
                {
                httpResponse = http.send(httpRequest); 
                statusCode = httpResponse.getStatusCode(); 
                System.debug('Response ::'+httpResponse);
                System.debug('Response Status::'+httpResponse.getStatus());
                System.debug('Response Body::'+httpResponse.getBody());
                response.responsePayload = httpResponse.getBody();

                
                if(statusCode==201 || statusCode==200)
                {               
                    response.responseCode=String.valueOf(statusCode);     
                    response.responseMessage='Success';
                    response.status='Success';
                }
                else 
                {      
                        Map<String, Object> jsonResponseMap = (Map<String, Object>)JSON.deserializeUntyped(httpResponse.getBody());
                                        System.debug('jsonResponseMap ::'+jsonResponseMap);

                        String errorMessage='';          
                        if (jsonResponseMap.containsKey('error')) {
                            Map<String, Object> errorMap = (Map<String, Object>) jsonResponseMap.get('error');
                            Map<String, Object> faultMap = (Map<String, Object>) errorMap.get('fault');
                            List<Object> messageList = (List<Object>) faultMap.get('message');
                            errorMessage = String.join(messageList, ' ');
                        }
                        response.responseCode=String.valueOf(statusCode);
                        response.responseMessage=errorMessage;
                        response.status='Error';
                }

                  
            }
            catch(Exception e)
            {
            
            System.debug('response ::'+httpResponse);

            if(httpResponse != null)
            {
                response.responseCode='504';
                response.responseMessage=httpResponse.getStatus() + ' Message: ' + httpResponse.getBody();
                response.responsePayload = httpResponse.getBody();
            }
            else {
                response.responseMessage=e.getMessage();
                response.responsePayload = e.getMessage();
                response.responseCode='504';
            }
            
            response.status='Error';
            System.debug('Failed to create Transaction' + e.getMessage());
            
        }
          responses.add(response);
        }
        return responses;

    }
        
}