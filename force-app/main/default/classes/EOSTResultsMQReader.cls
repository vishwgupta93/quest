public with sharing class EOSTResultsMQReader {
  private static Integer retries = 0;
  @future(callout=true)  
    public static void readMQ()
    {
    
        String endPoint = Label.OMS_Mule_Endpoint;
        Integer statusCode;

        String token = '';
        List<OMS_Mule_MQ_Token__c> settings =  [SELECT Id, Token__c FROM OMS_Mule_MQ_Token__c LIMIT 1];
        if(!settings.isEmpty())
        {
          token = settings[0].Token__c;
        }
        else {
          token = OMSMuleTokenHandler.fetchToken();
        }
        
        
            
        try{
            
          callMuleService(token, endPoint);
        }
        catch(Exception e){
          System.debug('Failed to create Transaction' + e.getMessage());
        }
       
       
    }

    private static HttpResponse callMuleService(String token,String endPoint)
    {
      HttpResponse response = new HttpResponse();
      
      try {
        retries = retries +1;
        String batchSize = Label.OMS_EOST_Batchsize;
        
        
        String getEndpoint = 'callout:EOST_OMS_Mule_Endpoint/CIT-RESULTS-EOST-Q/messages' + '?batchSize=' + EncodingUtil.urlEncode(batchSize, 'UTF-8');

        //String getEndpoint = endPoint +'CIT-RESULTS-EOST-Q/messages' + '?batchSize=' + EncodingUtil.urlEncode(batchSize, 'UTF-8');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(getEndpoint);
        request.setMethod('GET');
        request.setHeader('Content-Type','application/json');
        request.setTimeout(20000);
        //request.setHeader('Authorization',token);
         
        response = http.send(request); 
        Integer statusCode = response.getStatusCode(); 
          
          if(statusCode ==200 ){
            String jsonString = response.getBody();

            System.debug(response.getBody()); 

            List<EOST_OMS_Log__c> payloads = new List<EOST_OMS_Log__c>();
            String batchId= String.valueOf(System.currentTimeMillis());
            Map<String,String>lockIds= new Map<String,String>();

           List<EOSTPayload.PayloadWrapper> payloadList = EOSTPayload.parsePayload(jsonString);
           for (EOSTPayload.PayloadWrapper payload : payloadList) {
               
               String lockId = payload.headers.lockId;
               String body = payload.body;
                // Process lockId and body as needed
                System.debug('LockId: ' + lockId);
                System.debug('Body: ' + body);
                
               EOST_OMS_Log__c eostPayload = new EOST_OMS_Log__c();               
               Map<String, Object> bodyMap = new Map<String, Object>();
               
               try {
                bodyMap = (Map<String, Object>) JSON.deserializeUntyped(body);
               } catch (Exception e1) {
                System.debug('Failed to parse the payload ' + e1.getMessage() + ' : payload  ' +  body);
               }
               
               if (bodyMap != null && !bodyMap.isEmpty() && bodyMap.containsKey('event')) {
                   Map<String, Object> eventMap = (Map<String, Object>) bodyMap.get('event');
                   String labRefID = (String) eventMap.get('labRefID');
                   eostPayload.EOST_Payload__c = body;
                   eostPayload.Batch_Id__c=batchId;
                   eostPayload.Batch_Status__c='Open';
                   eostPayload.Reference_ID__c = labRefID;
                   lockIds.put(lockId,payload.headers.messageId);
                   payloads.add(eostPayload);  
               }

                            
               System.debug(eostPayload);
           }
           System.debug(payloads);
           
           System.debug('LockIds: ' + lockIds);

           // List to store JSON payloads
           
           String deleteEndpoint = 'callout:EOST_OMS_Mule_Endpoint/CIT-RESULTS-EOST-Q/messages/' ;

           // Iterate over lockIds map to create JSON payloads
           for (String key : lockIds.keySet()) {

               Map<String, Object> payloadMap = new Map<String, Object>();
               
               payloadMap.put('lockId', key);
               String jsonPayload = JSON.serialize(payloadMap);

               System.debug(jsonPayload);
               HttpRequest req = new HttpRequest();
              //  req.setEndpoint( endPoint + 'CIT-RESULTS-EOST-Q/messages/'+lockIds.get(key));
               req.setEndpoint( deleteEndpoint +lockIds.get(key));
               req.setMethod('DELETE');
               req.setHeader('Content-Type', 'application/json');
              //  req.setHeader('Authorization',token);
               req.setBody(jsonPayload);
               System.debug(req);

               HttpResponse res = http.send(req);

               // Handle the response if needed
               System.debug(res.getStatusCode());
               System.debug(res.getBody());
               
               
           }
           insert payloads;
           
           // EOST_OMS_Payload_Process

           EOST_Platorm_Event__e event = new EOST_Platorm_Event__e();
           event.Batch_Id__c=batchId;
           event.Event_Type__c=Label.EOST_OMS_Payload_Process;
           EventBus.publish(event);
           
                        
          }
          else if(statusCode ==401) {
            System.debug(response.getBody()); 
            if(retries < 6)
            {
                token = OMSMuleTokenHandler.fetchToken();
                response = callMuleService( token, endPoint);
            }  
          }
          else {
            System.debug(response.getBody()); 
          }
      } 
      

          catch (Exception e) {
            System.debug('Failed to create Transaction ' + e.getMessage());
            
            // Database.releaseSavepoint(sp);
          }

          return response;
    }
}