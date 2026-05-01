public with sharing class ShipmentEventEmailHandler {
    @future (callout=true)
         public static void sendPayLoad(String shipmentId, String eventKey)
         {
     
            Shipment shipment = [select Id,orderSummaryId,FulfillmentOrderId,orderSummary.OrderedDate,OrderSummary.OrderNumber,OrderSummary.acceptedConsents__c,orderSummary.GrandTotalAmount,OrderSummary.BillingEmailAddress,OrderSummary.Account.Id,orderSummary.Account.PersonEmail,Shipping_Method__c,Shipment_Tracking_URL__c from Shipment where Id =: shipmentId];

            List<FulfillmentOrderLineItem> items = [select Id,Test_Type__c from FulfillmentOrderLineItem where FulfillmentOrderId =: shipment.FulfillmentOrderId and Test_Type__c != 'PA' and Type != 'Delivery Charge'];

            Set<String> testTypes = new Set<String>();
            for(FulfillmentOrderLineItem item : items)
            { 
              testTypes.add(item.Test_Type__c);
            }
            String testsCommaSeparted = String.join(new List<String>(testTypes), ',');
            String email = shipment.orderSummary.Account.PersonEmail; 
            Integer statusCode;
             DateTime currentTime = System.now();
             String eventTime = currentTime.format('yyyy-MM-dd HH:mm:ss');
             JSONGenerator gen = JSON.createGenerator(true);
                 gen.writeStartObject();
                 gen.writeStringField('ContactKey',shipment.orderSummary.Account.Id);
                 gen.writeStringField('EventDefinitionKey',eventKey);
                 gen.writeFieldName('Data');
                     gen.writeStartObject();
                         gen.writeStringField('customer_id', shipment.orderSummary.Account.Id);
                         gen.writeStringField('email_address',email != null ? email : shipment.orderSummary.BillingEmailAddress);
                         gen.writeStringField('OrderSummaryId', shipment.orderSummaryId);
                         gen.writeStringField('order_number', shipment.orderSummary.OrderNumber);
                         gen.writeDateTimeField('order_date', shipment.orderSummary.OrderedDate);
                         gen.writeNumberField('order_total',shipment.orderSummary.GrandTotalAmount);
                         gen.writeStringField('shipping_method', shipment.Shipping_Method__c);
                         gen.writeStringField('shipment_tracking_url', shipment.Shipment_Tracking_URL__c);
                         gen.writeStringField('status', 'Kit Shipped');
                         gen.writeStringField('Test_Type', testsCommaSeparted);
                         gen.writeStringField('Event_time', eventTime );
                         gen.writeStringField('sfmc_insert_date', Date.today().format());
                        //  gen.writeStringField('acceptedConsents', shipment.orderSummary.acceptedConsents__c != null ? shipment.orderSummary.acceptedConsents__c : '');
                         gen.writeEndObject();
                 gen.writeEndObject();
     
                 String jsonStr = gen.getAsString();
                       
              String httpBody = jsonStr;
              //String endpoint = Label.SFMC_Rest_Endpoint + '/interaction/v1/events';
             // List<SFMC_OMS_Config__c> configs = [select Id, Auth_Token__c from SFMC_OMS_Config__c  where Channel__c = 'QD-CIT' and API__C = 'Common'];//
              //String token = configs[0].Auth_Token__c;
              String endpoint = 'callout:SFMC_Endpoint/interaction/v1/events';
             Http http = new Http();
             HttpRequest request = new HttpRequest();
             request.setEndpoint(endpoint);
             request.setMethod('POST');
             request.setHeader('Content-Type','application/json');
             //request.setHeader('Authorization','Bearer ' + token);
             request.setBody(httpBody);
             System.debug('Request::'+request);
             System.debug(httpBody);
     
            
             try{
               HttpResponse response = http.send(request); 
               statusCode = response.getStatusCode(); 
               
                System.debug(statusCode ); 
                
                Event_Log__c eventLog = new Event_Log__c();                
                eventLog.Order_Summary__c =shipment.OrderSummaryId;
                eventLog.Event_Type__c ='Shipment';
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