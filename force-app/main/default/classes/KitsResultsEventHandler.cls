public with sharing class KitsResultsEventHandler {
   @future (callout=true)
        public static void sendPayLoad(String orderSummaryId, String eventKey, String testType, String email, String customerId, boolean isPartner)
        {
            
            
            
    
            Integer statusCode;
            DateTime currentTime = System.now();
            String eventTime = currentTime.format('yyyy-MM-dd HH:mm:ss');
            JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeStringField('ContactKey',String.valueOf(currentTime.getTime()));
                gen.writeStringField('EventDefinitionKey',eventKey);
                gen.writeFieldName('Data');
                    gen.writeStartObject();
                        gen.writeStringField('customer_id', customerId);
                        gen.writeStringField('email_address',email);
                        
                        if(!isPartner)
                        {
                            OrderSummary orderSummary = [select Account.PersonEmail,BillingEmailAddress,OrderNumber,CustomerId__c,OrderedDate,GrandTotalAmount,Partner_Name__c from OrderSummary where Id =: orderSummaryId];
                            gen.writeStringField('OrderSummaryId', orderSummaryId);
                            gen.writeStringField('order_number', orderSummary.OrderNumber);
                            gen.writeDateTimeField('order_date', orderSummary.OrderedDate);
                            gen.writeNumberField('order_total',orderSummary.GrandTotalAmount);
                        }   
                        
                        gen.writeStringField('Test_Type', testType);
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
               if(isPartner)
               {
                eventLog.Kit_Detail__c =orderSummaryId; 
               }
               else {
                eventLog.Order_Summary__c =orderSummaryId; 
               }
               
                      
               eventLog.Event_Type__c ='Results';
              
              
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