global with sharing class AppointmentRemainderEmailOutbound implements Database.Batchable<SObject>, Database.AllowsCallouts{
    public String query;
    public String type;
    public List<String> statusList;
    public String Id;

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<FulfillmentOrder> orders) {

        if(!orders.isEmpty())
        {
            List<Event_Log__c> eventLogs = new List<Event_Log__c>();
            Set<String> foID =  new Set<String>();
            for(FulfillmentOrder order : orders)
            {
                if(foID.add(order.Id))
                {
                    System.debug(foID);
                    String email = order.orderSummary.Account.PersonEmail;
                    Integer statusCode;
                    DateTime currentTime = System.now();
                    String eventTime = currentTime.format('yyyy-MM-dd HH:mm:ss');
                    JSONGenerator gen = JSON.createGenerator(true);
                    gen.writeStartObject();
                    gen.writeStringField('ContactKey',String.valueOf(currentTime.getTime()));
                    gen.writeStringField('EventDefinitionKey',Label.SFMC_Appointment_Remainder_Event_Defnition);
                    gen.writeFieldName('Data');
                        gen.writeStartObject();
                            
                                gen.writeStringField('customer_id', order.orderSummary.CustomerId__c);
                                gen.writeStringField('email_address',email != null ? email : order.orderSummary.BillingEmailAddress);
                                gen.writeStringField('OrderSummaryId', order.orderSummaryId);
                                gen.writeStringField('order_number', order.orderSummary.OrderNumber);
                                gen.writeDateTimeField('order_date', order.orderSummary.OrderedDate);
                                gen.writeNumberField('order_total',order.orderSummary.GrandTotalAmount);
                                gen.writeNumberField('days_past_order_conf', order.Days_Past_Confirm__c);
                                gen.writeDateField('order_expiration', order.Expiration_Date__c);
                                gen.writeBooleanField('scheduled_appt', false);
                                gen.writeStringField('Event_time', eventTime );
                                gen.writeStringField('sfmc_insert_date', Date.today().format());
                        
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
                    
                    System.debug(statusCode ); 
                    
                    Event_Log__c eventLog = new Event_Log__c();
                                                
                    eventLog.Event_Type__c ='Order Remainder';
                    
                    
                    eventLog.Order_Summary__c =order.orderSummaryId;
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
                    
                    eventLogs.add(eventLog);
                    }
                    catch(Exception e){
                    System.debug('Failed to create Transaction' + e.getMessage());
                    
                    }
                }
                
            }

            insert eventLogs;
            
        }

            
            
        
        }
    

    global void finish(Database.BatchableContext BC) {
       
    }
}