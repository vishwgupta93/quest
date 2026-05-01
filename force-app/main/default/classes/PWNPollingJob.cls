global with sharing class PWNPollingJob implements Database.Batchable<SObject>, Database.AllowsCallouts{
    public String query;
    public String type;
    public List<String> statusList;
    public String Id;

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Lab_Order__c> orders) {

        if(!orders.isEmpty())
        {
            List<Lab_Order__c> updatedLabOrders = new List<Lab_Order__c>();
            List<Kit_Details__c> updatedKits = new List<Kit_Details__c>();
            Set<String> labOrderId =  new Set<String>();
            Set<String> pwnIds = new Set<String>();
            Map<String,String> pwnIDLabOrderMap = new Map<String,String>();
            Map<String,String> labOrderIdKitMap = new Map<String,String>();
            for(Lab_Order__c order : orders)
            {
                if(labOrderId.add(order.Id))
                {
                    pwnIds.add(order.PWN_ID__c);
                    pwnIDLabOrderMap.put(order.PWN_ID__c,order.Id);
                    System.debug('pwnIDLabOrderMap: ' + pwnIDLabOrderMap);
                    if(order.Is_Kit__c)
                        labOrderIdKitMap.put(order.Id, order.Kit_Detail__c);
                }
                
            }

            String requestBody = '{"order_ids":' + JSON.serialize(pwnIds) + '}';

            System.debug(requestBody);

            String key = Label.PWN_API_KEY;
            String secret = Label.PWN_API_SECRET;
            String token = PWNTokenGeneration.generateToken(key,secret);    
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            
            request.setMethod('POST');
            request.setEndpoint(Label.PWN_ORDER_STATUS_URL+'get_batch');
            request.setHeader('accept', 'application/json');
            request.setHeader('content-type', 'application/json');
            request.setHeader('Authorization','Bearer ' + token);
            request.setBody(requestBody);

             System.debug(request);
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                System.debug('API Call Success: ' + response.getBody());

                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> pwnOrders = (List<Object>) responseMap.get('orders');

                for (Object pwnOrder : pwnOrders) {
                    Map<String, Object> pwnOrderMap = (Map<String, Object>) pwnOrder;
                    String pwnId = String.valueOf(pwnOrderMap.get('id'));
                    String status = (String) pwnOrderMap.get('status');
                    if(status == 'approved')
                    {
                        Lab_Order__c loToUpdate = new Lab_Order__c();
                        loToUpdate.Id=pwnIDLabOrderMap.get(pwnId);
                        loToUpdate.Is_PWN_Approved__c=true;
                        loToUpdate.PWN_Status_Date__c = System.today();
                        updatedLabOrders.add(loToUpdate);
                        if(labOrderIdKitMap.get(pwnIDLabOrderMap.get(pwnId))!=null)
                        {
                            Kit_Details__c updatedKit = new Kit_Details__c();
                            updatedKit.Id = labOrderIdKitMap.get(pwnIDLabOrderMap.get(pwnId));
                            updatedKit.Is_PWN_Approved__c=true;
                            updatedKit.PWN_Status_Date__c = System.today();
                            updatedKits.add(updatedKit);
                        }
                    }
                    else if(status == 'rejected')
                    {
                        Lab_Order__c loToUpdate = new Lab_Order__c();
                        loToUpdate.Id=pwnIDLabOrderMap.get(pwnId);
                        loToUpdate.Status__c='PA Rejected';
                        loToUpdate.Full_Refund__c=true;
                        updatedLabOrders.add(loToUpdate);
                        if(labOrderIdKitMap.get(pwnIDLabOrderMap.get(pwnId))!=null)
                        {
                            Kit_Details__c updatedKit = new Kit_Details__c();
                            updatedKit.Id = labOrderIdKitMap.get(pwnIDLabOrderMap.get(pwnId));
                            updatedKit.Lab_Status__c='PA Rejected';
                            updatedKit.PWN_Status_Date__c = System.today();
                            updatedKits.add(updatedKit);
                        }
                    }
                    
                }            
            } 
            else {
            System.debug('Error: ' + response.getStatusCode() + ' ' + response.getBody());
        }

        update updatedLabOrders;
        update updatedKits;
            
            
        }

            
            
        
        }
    

    global void finish(Database.BatchableContext BC) {
       
    }
}