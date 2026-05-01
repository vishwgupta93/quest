public with sharing class CancelEmailEventHandler {
    @future (callout=true)
    public static void sendPayLoad(String orderSummaryId, String eventKey, String testType)
    {
        OrderSummary orderSummary = [select Account.PersonEmail,BillingEmailAddress,OrderNumber,CustomerId__c,OrderedDate,RefundTotal__c,Partner_Name__c from OrderSummary where Id =: orderSummaryId];

        List<OrderItemSummary> items = [select Id,TestType__c,resultingRequired__c,fulfillmentPartner__c from OrderItemSummary where OrderSummaryId =: orderSummaryId and TestType__c != 'PA' and Type != 'Delivery Charge'];

        Set<String> testTypes = new Set<String>();
        Boolean isMixedCart =false;
        Boolean isThirdParty=false;
        String thirdPartyPartner='';
        String eventType='';
          for(OrderItemSummary item : items)
          {
              testTypes.add(item.TestType__c);
              if(item.TestType__c != 'PSC' && !item.resultingRequired__c)
              {
                isThirdParty =true;
                thirdPartyPartner = item.fulfillmentPartner__c;
              }
          }
        String testsCommaSeparted = String.join(new List<String>(testTypes), ',');
        if (testTypes.size() > 1)
          isMixedCart = true;

        if(eventKey != Label.SFMC_Order_Cance_Event_Definition)
        {
          testType = testsCommaSeparted;
        }

        String email = orderSummary.Account.PersonEmail;
        Integer statusCode;
        DateTime currentTime = System.now();
        String eventTime = currentTime.format('yyyy-MM-dd HH:mm:ss');
        JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('ContactKey',String.valueOf(currentTime.getTime()));
            gen.writeStringField('EventDefinitionKey',eventKey);
            gen.writeFieldName('Data');
                gen.writeStartObject();
                    gen.writeStringField('customer_id',  orderSummary.Account.Id);
                    gen.writeStringField('email_address',email != null ? email : orderSummary.BillingEmailAddress);
                    gen.writeStringField('OrderSummaryId', orderSummaryId);
                    gen.writeStringField('order_number', orderSummary.OrderNumber);
                    gen.writeDateTimeField('order_date', orderSummary.OrderedDate);
                    gen.writeNumberField('order_total',orderSummary.RefundTotal__c);
                    gen.writeStringField('Test_Type', testType);
                    gen.writeStringField('Event_time', eventTime );
                    gen.writeBooleanField('Mixed_cart ', isMixedCart);
                    gen.writeStringField('sfmc_insert_date', Date.today().format());
                    if(eventKey != Label.SFMC_Order_Cance_Event_Definition)
                    {
                      gen.writeBooleanField('is_third_party', isThirdParty);     
                      gen.writeStringField('third_party_partner_name', thirdPartyPartner); 
                    }
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
           eventLog.Order_Summary__c =orderSummaryId;
           if(eventKey == Label.SFMC_Order_Cance_Event_Definition)
           {
              eventType = 'Cancel';
           }
           else if(eventKey == Label.SFMC_Order_Expiry_Event_Definition)
           {
              eventType = 'Expiry';
           }
           
                  
           eventLog.Event_Type__c =eventType;
          
          
           eventLog.Order_Summary__c =orderSummaryId;
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