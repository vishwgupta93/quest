public with sharing class LabOrderCancellationEmailEventHandler {
    @future (callout=true)
    public static void sendPayLoad(String laborderId,  String testType, String eventKey )
    {
        Integer statusCode;
        DateTime currentTime = System.now();
        Lab_Order__c labOrder = [select Id,Name,Kit_Detail__r.Order_Number__c,CreatedDate,Person_Record__r.Contact__r.AccountId,Account__c,Person_Record__r.Email__c, Order_Summary__r.GrandTotalAmount,Refund_Amount__c
                            from Lab_Order__c where Id =: laborderId];


        boolean isGSS =  testType == 'GSS' ? true : false;
        String orderNumber = isGSS ? labOrder.Kit_Detail__r.Order_Number__c : labOrder.Name;

        String customerId = labOrder.Account__c;
        if(String.isBlank(customerId))
        {
            customerId = labOrder.Person_Record__r.Contact__r.AccountId;
        }
		System.debug('creating JSON');
        JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
        
            gen.writeStringField('ContactKey',labOrder.Person_Record__r.Contact__r.AccountId);
          //gen.writeStringField('ContactKey',String.valueOf(currentTime.getTime()));
            gen.writeStringField('EventDefinitionKey',eventKey);
            gen.writeFieldName('Data');
                gen.writeStartObject();
                    gen.writeStringField('customer_id', customerId);
                    gen.writeStringField('email_address',labOrder.Person_Record__r.Email__c);
                    gen.writeStringField('OrderSummaryId', labOrder.Id);
                    gen.writeStringField('Test_Type', testType);
                    gen.writeStringField('order_number', orderNumber);
                    gen.writeDateTimeField('order_date', labOrder.CreatedDate);
                    gen.writeNumberField('order_total',labOrder.Refund_Amount__c);
                    gen.writeStringField('Event_time', currentTime.format('yyyy-MM-dd HH:mm:ss') );
                    
                gen.writeEndObject();
            gen.writeEndObject();

            String jsonStr = gen.getAsString();
            String httpBody = jsonStr;
         //String endpoint = Label.SFMC_Rest_Endpoint + '/interaction/v1/events';
         //token = configs[0].Auth_Token__c;
         // List<SFMC_OMS_Config__c> configs = [select Id, Auth_Token__c from SFMC_OMS_Config__c  where Channel__c = 'QD-CIT' and API__C = 'Common'];
        //String token;
        
        String endpoint = '';
        if(!Test.isRunningTest()){
            //token = configs[0].Auth_Token__c; 
            endpoint = 'callout:SFMC_Endpoint/interaction/v1/events';  
        }
        
         
         
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
             eventLog.Lab_Order__c =laborderId;
             String eventType;
             if(eventKey == Label.SFMC_Order_Cance_Event_Definition)
             {
                eventType = 'Cancel';
             }
             else if(eventKey == Label.SFMC_Order_Expiry_Event_Definition)
             {
                eventType = 'Expiry';
             }
             else if(eventKey == Label.SFMC_Order_PWN_Reject_Event_Definition)
             {
                eventType = 'PWN Reject';
             }
                    
             eventLog.Event_Type__c =eventType;
            
            
             eventLog.Lab_Order__c =laborderId;
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