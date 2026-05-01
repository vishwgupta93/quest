global with sharing class GBFOrderStatusChecker implements Database.Batchable<SObject>, Database.AllowsCallouts {
    public static final String JOB_NAME = 'UpdateGBFPartnerOrdersStatusJob';

    public String query;
    public String status;

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query); 
    }

    global void execute(Database.BatchableContext BC, List<Partner_Order__c> openOrders) {
        
        List<Partner_Order__c> ordersToUpdate = new List<Partner_Order__c>();
        Map<String, Object> payload = new Map<String, Object>();
        if(!openOrders.isEmpty())
        {
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
                gen.writeFieldName('orderNumbers');
                    gen.writeStartArray();
                        for (Partner_Order__c order : openOrders) {           
                            gen.writeString(order.Id);    
                        }
                    gen.writeEndArray();
            gen.writeEndObject();

            System.debug(gen.getAsString());

            HttpRequest request = new HttpRequest();
            request.setEndpoint(Label.GBF_Status_API_Endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type','application/json');
            request.setHeader('Authorization','Bearer ' + openOrders[0].Retail_Partner__r.Fulfillment_Location_API_Key__c);

            request.setBody(gen.getAsString());

            Http http = new Http();
            HttpResponse res = http.send(request);

            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                System.debug(response);

                if (response.get('success') == true) {
                    List<Object> statuses = (List<Object>)response.get('statuses');

                    for (Object statusObj : statuses) {
                        Map<String, Object> status = (Map<String, Object>)statusObj;
                        Partner_Order__c orderToUpdate = new Partner_Order__c(Id=(String)status.get('orderNumber'));
                        orderToUpdate.Partner_Order_Status__c=(String)status.get('orderStatus');
                        if (status.get('orderStatus') == 'SHIPPED (SIMULATED)'
                          || status.get('orderStatus') == 'SHIPPED')
                         {                            
                            orderToUpdate.Status__c = 'Shipped';                           
                        }
                        System.debug(orderToUpdate);
                        ordersToUpdate.add(orderToUpdate);
                       
                    }
                }
            
        }
        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
        System.debug(ordersToUpdate);
        }
     
    }

    global void finish(Database.BatchableContext BC) {
       
    }
}