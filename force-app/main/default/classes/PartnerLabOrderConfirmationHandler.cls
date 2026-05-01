public with sharing class PartnerLabOrderConfirmationHandler {
    @future (callout=true)
    public static void sendPayLoad(String labOrderId, String eventKey)
    {
        
        Lab_Order__c labOrder = [select Id,Name,Account__c,CreatedDate,External_partner_Order_Id__c,Partner_Order_Total__c,Person_Record__r.Contact__r.AccountId,Person_Record__r.Id,Person_Record__r.Email__c,Order_Summary__r.acceptedConsents__c
                            from Lab_Order__c where Id =: labOrderId];



        String customerId = labOrder.Account__c;
        
        if(String.isBlank(customerId))
        {
          customerId = labOrder.Person_Record__r.Contact__r.AccountId;
        }

        String email = labOrder.Person_Record__r.Email__c;
        Integer statusCode;
        DateTime currentTime = System.now();
        String eventTime = currentTime.format('yyyy-MM-dd HH:mm:ss');
        JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('ContactKey',labOrder.Person_Record__r.Contact__r.AccountId);
            gen.writeStringField('EventDefinitionKey',eventKey);
            gen.writeFieldName('Data');
                gen.writeStartObject();
                    gen.writeStringField('customer_id', customerId);
                    gen.writeStringField('email_address',labOrder.Person_Record__r.Email__c);
                    gen.writeStringField('order_number', labOrder.External_partner_Order_Id__c);
                    gen.writeDateTimeField('order_date', labOrder.CreatedDate);
                    gen.writeNumberField('order_total', labOrder.Partner_Order_Total__c);
                    gen.writeStringField('Event_time', eventTime );
                    gen.writeStringField('sfmc_insert_date', Date.today().format());
                    gen.writeEndObject();
            gen.writeEndObject();

            String jsonStr = gen.getAsString();
                  
         String httpBody = jsonStr;
         String endpoint = Label.SFMC_Rest_Endpoint + '/interaction/v1/events';
        //  String endpoint = 'callout:SFMC_Endpoint/interaction/v1/events';
         List<SFMC_OMS_Config__c> configs = [select Id, Auth_Token__c from SFMC_OMS_Config__c  where Channel__c = 'QD-CIT' and API__C = 'Common'];
         
        String token = configs[0].Auth_Token__c;
         
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type','application/json');
        request.setHeader('Authorization','Bearer ' + token);
        request.setBody(httpBody);
        System.debug('Request::'+request);
        System.debug(httpBody);

       
        try{
          HttpResponse response = http.send(request); 
          statusCode = response.getStatusCode(); 
          
           System.debug(statusCode ); 
           
           Event_Log__c eventLog = new Event_Log__c();
           eventLog.Lab_Order__c =labOrder.id;
                  
           eventLog.Event_Type__c ='Order Confirmation';
          
          
           
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
        }
        catch(Exception e){
          System.debug('Failed to create Transaction' + e.getMessage());
          
        }
                    

    }
}