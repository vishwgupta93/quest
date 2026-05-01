global with sharing class LabOrderExpiryEmailOutbound implements Database.Batchable<SObject>, Database.AllowsCallouts{
    public String query;
    public String status;
    public String type;
    public String Id;
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Lab_Order__c> orders) {
        
        if(!orders.isEmpty())
        {
            List<Event_Log__c> eventLogs = new List<Event_Log__c>();
            Set<String> labOrderId =  new Set<String>();
            for(Lab_Order__c order : orders)
            {
                if((order.Is_Partner__c == true && order.Partner_Client_Map__r.Suppress_Reminder_Email__c == false) || order.Is_Partner__c == false){
                    
                    if(labOrderId.add(order.Id))
                    {
                        Integer statusCode;
                        DateTime currentTime = System.now();
                        String eventTime = currentTime.format('yyyy-MM-dd HH:mm:ss');
                        JSONGenerator gen = JSON.createGenerator(true);
                        gen.writeStartObject();
                        gen.writeStringField('ContactKey',String.valueOf(currentTime.getTime()));
                        gen.writeStringField('EventDefinitionKey',Label.SFMC_OMS_Expiry_Event);
                        gen.writeFieldName('Data');
                        gen.writeStartObject();
                        
                        gen.writeStringField('customer_id', order.Person_Record__r.Id);
                        gen.writeStringField('email_address',order.Person_Record__r.Email__c);
                        gen.writeStringField('OrderSummaryId', order.Order_Summary__c != null ? String.valueOf(order.Order_Summary__c) : '');
                        gen.writeStringField('order_number', order.Name);
                        gen.writeDateTimeField('order_date', order.CreatedDate);
                        gen.writeNumberField('order_total', order.Order_Summary__c != null ? order.Order_Summary__r.GrandTotalAmount : 0.0);
                        gen.writeNumberField('days_to_expiration', order.Days_to_expire__c);
                        gen.writeDateField('order_expiration', order.Expiration_Date__c);
                        gen.writeStringField('Event_time', eventTime );
                        gen.writeStringField('sfmc_insert_date', Date.today().format());
                        
                        gen.writeEndObject();
                        gen.writeEndObject();
                        
                        String jsonStr = gen.getAsString();
                        
                        String httpBody = jsonStr;
                        //String endpoint = Label.SFMC_Rest_Endpoint + '/interaction/v1/events';
                       // List<SFMC_OMS_Config__c> configs = [select Id, Auth_Token__c from SFMC_OMS_Config__c  where Channel__c = 'QD-CIT' and API__C = 'Common'];
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
                            
                            Event_Log__c eventLog = new Event_Log__c();
                            eventLog.Lab_Order__c =order.Id;
                            eventLog.Event_Type__c ='Order Expiry';
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
            }
            insert eventLogs;
        }
    }
    global void finish(Database.BatchableContext BC) {
        
    }
}