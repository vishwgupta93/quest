public with sharing class POPurchaseConfirmationEmailHandler {
    @future (callout=true)
         public static void sendPayLoad(String partnerOrderId, String eventDefinitionKey)
         {

            Partner_Order__c partnerOrder = [select Id,Order_Number__c,Email__c,CreatedDate
                            from Partner_Order__c where Id =: partnerOrderId];
            System.debug('this.partnerOrder==' + partnerOrder);
       
        Integer statusCode;
        DateTime currentTime = System.now();
        String eventTime = currentTime.format('yyyy-MM-dd HH:mm:ss');
        JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('ContactKey',String.valueOf(currentTime.getTime()));
            gen.writeStringField('EventDefinitionKey',eventDefinitionKey);
            gen.writeFieldName('Data');
                gen.writeStartObject();
                    gen.writeStringField('email', partnerOrder.Email__c);
                    // gen.writeStringField('customer_id', partnerOrder.Email__c);
                    gen.writeStringField('lab_order_id', partnerOrder.Order_Number__c);
                    gen.writeDateTimeField('created_date', partnerOrder.CreatedDate);
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

        System.debug('Request==' + request + ' Body: ' + httpBody);

               
        try{
          HttpResponse response = http.send(request); 
          statusCode = response.getStatusCode(); 

          System.debug('HttpResponse==' + response);
          
           
          Partner_Event_Log__c eventLog = new Partner_Event_Log__c();                
          eventLog.Partner_Order__c =partnerOrderId;
          eventLog.Event_Type__c ='Purchase Confirmation';
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

         System.debug('Partner_Event_Log__c==' + eventLog);
         
         insert eventLog;
        }
        catch(Exception e){
          System.debug('Failed to create Transaction' + e.getMessage());
          
        }
    }
}