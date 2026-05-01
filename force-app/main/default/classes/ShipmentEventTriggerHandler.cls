public class ShipmentEventTriggerHandler{
  private static Integer retries = 0;
    @future (callout=true)
    public static void sendPayLoad(String fullfillmentOrderId)
    {
    Integer statusCode;
         JSONGenerator gen = JSON.createGenerator(true);
         gen.writeStartObject();
          gen.writeFieldName('data');
            gen.writeStartObject();
                gen.writeFieldName('payload');
                gen.writeStartObject();
                    gen.writeStringField('Action_Type__c', 'Create');
                    gen.writeStringField('Fulfillment_Order_Id__c',fullfillmentOrderId );
                    
                gen.writeEndObject();
            gen.writeEndObject();
         gen.writeEndObject();
         
         String jsonStr = gen.getAsString();
         
         JSONGenerator body = JSON.createGenerator(true);
         body.writeStartObject();
             
             
                     body.writeFieldName('properties');
                         body.writeStartObject();
                             body.writeStringField('contentType', 'application/json; charset=UTF-8');    
                         body.writeEndObject();
         
                     body.writeStringField('body', jsonStr);
         
         body.writeEndObject();
         
         String httpBody = body.getAsString();
         String endPoint = Label.OMS_Mule_Endpoint;
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
            
          callMuleService(httpBody, token, endPoint, fullfillmentOrderId);
        }
        catch(Exception e){
          System.debug('Failed to create Transaction' + e.getMessage());
        }
    }
    private static HttpResponse callMuleService(String httpBody, String token,String endPoint, String fullfillmentOrderId)
    {
      retries = retries +1;
      Http http = new Http();
      HttpRequest request = new HttpRequest();
      request.setEndpoint(endpoint+'CIT-ORDERS-SHIPMENTS-OMS-LISTENER-Q/messages/'+fullfillmentOrderId+'-Order-Shipment-Create');
      request.setMethod('PUT');
      request.setHeader('Content-Type','application/json');
      request.setHeader('Authorization',token);
      request.setBody(httpBody);
         
        HttpResponse response = http.send(request); 
        Integer statusCode = response.getStatusCode(); 
          
          if(statusCode ==200 || statusCode ==201){
             System.debug(response.getBody()); 
          }
          else if(statusCode ==401) {
            System.debug(response.getBody()); 
            if(retries < 6)
            {
                token = OMSMuleTokenHandler.fetchToken();
                response = callMuleService(httpBody, token, endPoint, fullfillmentOrderId);
            }  
          }
          else {
            System.debug(response.getBody()); 
          }

          return response;
    }
    }