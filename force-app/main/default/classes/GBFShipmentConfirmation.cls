global with sharing class GBFShipmentConfirmation implements Database.Batchable<SObject>, Database.AllowsCallouts{
    public String query;
    public String status;
    public String Id;

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Partner_Order__c> openOrders) {

        if(!openOrders.isEmpty())
        {

            List<Partner_Event_Log__c> logs = new List<Partner_Event_Log__c>();
            Organization a_ORG = [Select Id, Name, IsSandbox from Organization];
 
            if(a_ORG.IsSandbox)
            {
                
                for (Partner_Order__c order : openOrders)
                {
                    List<OMS_Shipment_Payload__c> payloads = [select Partner_Order__c,Payload__c from OMS_Shipment_Payload__c where Partner_Order__c =:order.id];
                    if(payloads.size() > 0)
                    {
                        // Partner_Event_Log__c log = new Partner_Event_Log__c(); 
                        // log.Event_Type__c= 'Shipment';
                        // log.Partner_Order__c = order.id;
                        // log.Payload__c = generateRequest(order.id);
                        OMS_Shipment_Payload__c payload =payloads[0];
                        String shipmentPayload = payload.Payload__c;
                        // String eventLogPayload = shipmentPayload;
                        // if(shipmentPayload.length() > 131072)
                        // {
                        //     eventLogPayload = shipmentPayload.substring(0, 131071);
                        // }
                        HttpResponse res = new HttpResponse();
                        res.setHeader('Content-Type', 'application/json');
                        res.setStatusCode(200);
                        res.setBody(shipmentPayload);

                        Partner_Event_Log__c log = parseResponse(order.id,generateRequest(order.id),res);                
                        logs.add(log);

                        // log.Response_Payload__c = eventLogPayload;
                        // log.Status__c = 'Success';
                        // Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(shipmentPayload);
                        // System.debug('Map: ' + payloadMap);
                        // List<Object> dataArray = (List<Object>) payloadMap.get('dataArray');
                        // if(!dataArray.isEmpty())
                        // { 
                        //     System.debug(' Calling GBF Parser with Data Array : ' + dataArray);                       
                        //     GBFShipmentConfirmationParser.processShipmentConfirmation(dataArray);
                        // }
                        // logs.add(log);
                    }
                }
            }
            else{
                System.debug('This is Production'); 
                
                for (Partner_Order__c order : openOrders)
                {
                    String requestStr = generateRequest(order.id);
                    System.debug(requestStr);

                HttpRequest request = new HttpRequest();
                    request.setEndpoint(Label.GBF_Confirm_API_Endpoint);
                    request.setMethod('POST');
                    request.setHeader('Content-Type','application/json');
                    request.setHeader('Authorization','Bearer ' + order.Retail_Partner__r.Fulfillment_Location_API_Key__c);
                    request.setTimeout(30000);

                    request.setBody(requestStr);

                Http http = new Http();
                HttpResponse res = http.send(request);
                Partner_Event_Log__c log = parseResponse(order.id,requestStr,res);                
                logs.add(log);
                }
               
            }

            insert logs;
            
        
        }
    }

    private String generateRequest(String orderId)
    {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
            gen.writeStringField('orderNumber',orderId);
            gen.writeStringField('format','xml');
        gen.writeEndObject();
        return gen.getAsString();
    }

    @TestVisible
    private Partner_Event_Log__c parseResponse (String orderId, String request,HttpResponse res)
    {
        Partner_Event_Log__c log = new Partner_Event_Log__c();
        try 
                {
                    log.Event_Type__c= 'Shipment';
                    log.Partner_Order__c = orderId;
                    log.Payload__c = request;

                    if(res.getStatusCode() == 200)
                    {
                        String payload =res.getBody();
                        String eventLogPayload = payload;
                        System.debug('Response: ' + payload + ' and Length: ' + payload.length());
                        if(payload.length() > 131072)
                        {
                            eventLogPayload = payload.substring(0, 131071);
                        }
                        log.Response_Payload__c = eventLogPayload;
                        log.Status__c = 'Success';
                        System.debug('Response: ' + payload);
                        Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(payload);
                        System.debug('Map: ' + payloadMap);
                        List<Object> dataArray = (List<Object>) payloadMap.get('dataArray');
                        System.debug('List: ' + dataArray);
                        if(!dataArray.isEmpty())
                        {                        
                            GBFShipmentConfirmationParser.processShipmentConfirmation(dataArray);
                        }
                            
                    }
                    else {
                        constructErrorResponse(log,res,'');
                    }
                } 
                catch (Exception e)  {
                       constructErrorResponse(log,res,e.getMessage());
                        log.Status__c = 'Error';
                }

                return log;
    }

    private void constructErrorResponse(Partner_Event_Log__c log,HttpResponse res,String exceptionMessage )
    {
                    String payload =res.getBody();
                    log.Response_Payload__c = payload +  ' ' + exceptionMessage;
                    log.Status__c = 'Error';
    } 

    global void finish(Database.BatchableContext BC) {
       
    }
}