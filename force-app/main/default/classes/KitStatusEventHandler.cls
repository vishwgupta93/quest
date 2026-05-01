public with sharing class KitStatusEventHandler {
    @future (callout=true)
         public static void sendPayLoad(String kitID, String eventKey,  boolean isPartner)
         {
     
            Kit_Details__c kit = [select ActivationUser_Customer_Email__c,ActivationUser_Customer_Id__c,Type__c,Status__c,Lab_Status__c,Tracking_Number__c,Partner_Name__c,Order_Summary__c from Kit_Details__c where Id =: kitID];
             Integer statusCode;
             DateTime currentTime = System.now();
             String eventTime = currentTime.format('yyyy-MM-dd HH:mm:ss');
             JSONGenerator gen = JSON.createGenerator(true);
                 gen.writeStartObject();
                 gen.writeStringField('ContactKey',String.valueOf(currentTime.getTime()));
                 gen.writeStringField('EventDefinitionKey',eventKey);
                 gen.writeFieldName('Data');
                     gen.writeStartObject();
                         gen.writeStringField('customer_id', kit.ActivationUser_Customer_Id__c);
                         gen.writeStringField('email_address',kit.ActivationUser_Customer_Email__c);
                         
                         if(!isPartner)
                         {
                             OrderSummary orderSummary = [select OrderNumber,OrderedDate,GrandTotalAmount from OrderSummary where Id =: kit.Order_Summary__c];
                             gen.writeStringField('OrderSummaryId', kit.Order_Summary__c);
                             gen.writeStringField('order_number', orderSummary.OrderNumber);
                             gen.writeDateTimeField('order_date', orderSummary.OrderedDate);
                             gen.writeNumberField('order_total',orderSummary.GrandTotalAmount);
                         }   
                         
                         gen.writeStringField('Test_Type', kit.Type__c);
                         gen.writeStringField('tracking_number', kit.Tracking_Number__c);
                         gen.writeStringField('status', kit.Status__c);
                         gen.writeStringField('lab_status', kit.Lab_Status__c);
                         gen.writeStringField('partner_name', kit.Partner_Name__c);
                         gen.writeBooleanField('is_partner', isPartner);
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
             System.debug('Request::'+request);
             System.debug(httpBody);
     
            
             try{
               HttpResponse response = http.send(request); 
               statusCode = response.getStatusCode(); 
               
                System.debug(statusCode ); 
                
                Event_Log__c eventLog = new Event_Log__c();                
                eventLog.Kit_Detail__c =kitID;
                eventLog.Event_Type__c =kit.Lab_Status__c;
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