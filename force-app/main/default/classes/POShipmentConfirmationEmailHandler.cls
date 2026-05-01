public with sharing class POShipmentConfirmationEmailHandler {
    @future (callout=true)
         public static void sendPayLoad(String partnerOrderId, String eventDefinitionKey)
         {
            Partner_Shipment_Info__c shipmentInfo = [select Tracking_URL__c,Partner_Order__c,Partner_Order__r.Partner_Order_Number__c,Partner_Order__r.Email__c,
            Partner_Order__r.CreatedDate,Ship_Via__c
                            from Partner_Shipment_Info__c where Partner_Order__c =: partnerOrderId];
        
       
        Integer statusCode;
        DateTime currentTime = System.now();
        String eventTime = currentTime.format('yyyy-MM-dd HH:mm:ss');
        JSONGenerator gen = JSON.createGenerator(true);
                 gen.writeStartObject();
                 gen.writeStringField('ContactKey',String.valueOf(currentTime.getTime()));
                 gen.writeStringField('EventDefinitionKey',eventDefinitionKey);
                 gen.writeFieldName('Data');
                     gen.writeStartObject();
                         gen.writeStringField('customer_id', shipmentInfo.Partner_Order__r.Email__c);
                         gen.writeStringField('email_address',shipmentInfo.Partner_Order__r.Email__c);
                         gen.writeStringField('OrderSummaryId', shipmentInfo.Partner_Order__c);
                         gen.writeStringField('order_number', shipmentInfo.Partner_Order__r.Partner_Order_Number__c);
                         gen.writeDateTimeField('order_date', shipmentInfo.Partner_Order__r.CreatedDate);
                         gen.writeNumberField('order_total',0.0);
                         gen.writeStringField('shipping_method', shipmentInfo.Ship_Via__c);
                         gen.writeStringField('shipment_tracking_url', shipmentInfo.Tracking_URL__c);
                         gen.writeStringField('status', 'Kit Shipped');
                         gen.writeStringField('Test_Type', 'GSS');
                         gen.writeStringField('Event_time', eventTime );
                         gen.writeStringField('sfmc_insert_date', Date.today().format());
                        //  gen.writeStringField('acceptedConsents', shipment.orderSummary.acceptedConsents__c != null ? shipment.orderSummary.acceptedConsents__c : '');
                         gen.writeEndObject();
                 gen.writeEndObject();
     
            String jsonStr = gen.getAsString();
                  
         String httpBody = jsonStr;
         String endpoint = Label.SFMC_Rest_Endpoint + '/interaction/v1/events';
         
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
          
           
          Partner_Event_Log__c eventLog = new Partner_Event_Log__c();                
          eventLog.Partner_Order__c =shipmentInfo.Partner_Order__c;
          eventLog.Event_Type__c ='Shipment Confirmation';
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