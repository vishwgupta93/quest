public with sharing class QuestSSShipmentParser {
    public static void fetchAndParseShipmentData(String orderNumber, String orderSummaryId) {

        List<FulfillmentOrderLineItem> items= [SELECT Id,Test_Type__c,ProductCode__c, Quantity FROM FulfillmentOrderLineItem where  fulfillmentOrderId = :orderNumber and Test_Type__c in ('at_home','GSS')];

        Organization a_ORG = [Select Id, Name, IsSandbox from Organization];
        Event_Log__c eventLog = new Event_Log__c(); 
        eventLog.Order_Summary__c =orderSummaryId;                  
        eventLog.Event_Type__c ='PROOV Shipment Confirmation';
        if(a_ORG.IsSandbox && !Test.isRunningTest()){
            List<OMS_Shipment_Payload__c> payloads  = [select Fulfillment_Order__c,Payload__c from OMS_Shipment_Payload__c where Fulfillment_Order__c =:orderNumber];
            if(payloads.size() > 0)
            {
                OMS_Shipment_Payload__c payload =payloads[0];
                String shipmentPayload = payload.Payload__c;
                eventLog.Response_Payload__c = shipmentPayload;
                eventLog.Status__c = 'Success';
                parseAndPersist(shipmentPayload, orderNumber, items);
            }            
        }
        else {
            HttpRequest req = new HttpRequest();
            String endpoint = Label.SS_Endpoint + '/shipments?orderNumber=' + EncodingUtil.urlEncode(orderNumber, 'UTF-8');
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setTimeout(30000);
            req.setHeader('Authorization','Basic ' + Label.SS_API_Token);
            Http http = new Http();
            HttpResponse res = http.send(req);

            try {
                if (res.getStatusCode() == 200) {
                    
                    String jsonResponse = res.getBody();
                    eventLog.Response_Payload__c = jsonResponse;
                    eventLog.Status__c = 'Success';
                    parseAndPersist(jsonResponse, orderNumber, items);                
                }
                else {
                    String payload =res.getBody();
                    eventLog.Response_Payload__c = payload;
                    eventLog.Status__c = 'Error';
                }
            }

            catch(Exception e)
            {
                eventLog.Response_Payload__c = 'Callout error: ' + e.getMessage();
                eventLog.Status__c = 'Error';
                System.debug('Callout error: ' + e.getMessage());
            }
           
    }
    insert eventLog;

    }

    private static void parseAndPersist(String payload, String orderNumber,List<FulfillmentOrderLineItem> items)
    {
        QuestSSPayloadWrapper wrapper = (QuestSSPayloadWrapper) JSON.deserialize(payload, QuestSSPayloadWrapper.class);
                for (QuestSSPayloadWrapper.Shipment shipmentWrapper : wrapper.shipments) {

                    Shipment shipment = new Shipment();
                    shipment.FulfillmentOrderId = orderNumber;
                    shipment.Ship_Date__c = Date.valueOf(shipmentWrapper.shipDate);
                    shipment.Shipping_Method__c=shipmentWrapper.serviceCode;
                    shipment.Provider=shipmentWrapper.carrierCode;
                    shipment.TrackingNumber=shipmentWrapper.trackingNumber;
                    shipment.Status='Shipped';

                    insert shipment;

                    List<ShipmentItem> shipmentItems = new List<ShipmentItem>();

                    for(FulfillmentOrderLineItem item : items)
                    {
                        ShipmentItem shipmentItem = new ShipmentItem();
                        shipmentItem.FulfillmentOrderLineItemId = item.id;
                        shipmentItem.Status__c='Kit Shipped';
                        shipmentItem.Quantity=item.Quantity;
                        shipmentItem.ShipmentId=shipment.Id;
                        shipmentItems.add(shipmentItem);
                    }
                    insert shipmentItems;
                }
    }
}