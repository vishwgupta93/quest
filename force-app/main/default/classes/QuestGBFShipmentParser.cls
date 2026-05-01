public with sharing class QuestGBFShipmentParser {
    public static void fetchAndParseShipment(String foId,String orderSummaryId)
    {
        Organization a_ORG = [Select Id, Name, IsSandbox from Organization];
        Event_Log__c eventLog = new Event_Log__c(); 
        eventLog.Order_Summary__c =orderSummaryId;                  
        eventLog.Event_Type__c ='GBF Shipment Confirmation';
        if(a_ORG.IsSandbox && !Test.isRunningTest()){

            List<OMS_Shipment_Payload__c> payloads = [select Fulfillment_Order__c,Payload__c from OMS_Shipment_Payload__c where Fulfillment_Order__c =:foId];
            FulfillmentOrder fo = [select Id,RecordTypeId from FulfillmentOrder where Id =:foId limit 1];
            Boolean kitRecord = false;
            if(fo.RecordTypeId == Label.SFOM_At_Home_Self_Record_Type_ID || fo.RecordTypeId == Label.SFOM_OTC_Cleared_Record_Type_Id || fo.RecordTypeId == Label.SFOM_GSS_Record_Type_Id)
            {
                kitRecord = true;
            }
            try{
        if(payloads.size() > 0)
        {
            OMS_Shipment_Payload__c payload =payloads[0];
            String shipmentPayload = payload.Payload__c;
            eventLog.Response_Payload__c = shipmentPayload;
            eventLog.Status__c = 'Success';          
            Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(shipmentPayload);
            System.debug('Map: ' + payloadMap);
            List<Object> dataArray = (List<Object>) payloadMap.get('dataArray');
            if(!dataArray.isEmpty())
            {                        
                parseAndPersist(dataArray,kitRecord);
        
            }
        } 
        else  {
            eventLog.Status__c = 'Error';
        }
        }
        catch(Exception ex){
                eventLog.Status__c = 'Error';
                System.debug('Exception:'+ex.getMessage());
        }
        
            
        }
        else {

                    FulfillmentOrder fo = [select Id,RecordTypeId from FulfillmentOrder where Id =:foId limit 1];
                    Boolean kitRecord = false;
                    if(fo.RecordTypeId == Label.SFOM_At_Home_Self_Record_Type_ID || fo.RecordTypeId == Label.SFOM_OTC_Cleared_Record_Type_Id || fo.RecordTypeId == Label.SFOM_GSS_Record_Type_Id)
                    {
                        kitRecord = true;
                    }
                    JSONGenerator gen = JSON.createGenerator(true);
                    gen.writeStartObject();
                        gen.writeStringField('orderNumber',foId);
                        gen.writeStringField('format','xml');
                    gen.writeEndObject();
                    HttpRequest request = new HttpRequest();
                    request.setEndpoint(Label.GBF_Confirm_API_Endpoint);
                    request.setMethod('POST');
                    request.setHeader('Content-Type','application/json');
                    request.setHeader('Authorization','Bearer ' + Label.GBF_ECOM_Order_API_Key);
                    request.setTimeout(30000);

                    request.setBody(gen.getAsString());
                    eventLog.Payload__c=gen.getAsString();
                    eventLog.Order_Summary__c =orderSummaryId;                  
                             
                    eventLog.Event_Type__c ='GBF Shipment Confirmation';
                    Http http = new Http();
                    HttpResponse res = http.send(request);

                    if(res.getStatusCode() == 200)
                        {
                            String payload =res.getBody();
                            eventLog.Response_Payload__c = payload;
                            eventLog.Status__c = 'Success';
                            System.debug('Response: ' + payload);
                            if(payload != '')
                            {
                                Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(payload);
                                System.debug('Map: ' + payloadMap);
                                List<Object> dataArray = (List<Object>) payloadMap.get('dataArray');
                                System.debug('List: ' + dataArray);
                                if(!dataArray.isEmpty())
                                {                        
                                    parseAndPersist(dataArray,kitRecord);
                            
                                }
                            }
                           
                                
                        }
                        else {
                            String payload =res.getBody();
                            eventLog.Response_Payload__c = payload;
                            eventLog.Status__c = 'Error';
                        }
        }

        insert eventLog;
    }

    private static void parseAndPersist(List<Object> dataArray,Boolean kitRecord)
    {
        for(Object dataObj: dataArray)
        {
            Map<String, Object> data = (Map<String, Object>)dataObj;
            String format = (String) data.get('format');
            String xmlData = (String) data.get('data');

            Dom.Document doc = new Dom.Document();
            doc.load(xmlData);
            Set<String> activationCodeSet = new Set<String>();

            for (Dom.XmlNode childNode : doc.getRootElement().getChildElements()) 
            {
                if(childNode.getName() == 'ShippingConfirmation')
                {
                    Dom.XmlNode shippingConfirmationNode = childNode;
                    String orderNumber = shippingConfirmationNode.getAttributeValue('OrderNumber', null);
                    String shipper = shippingConfirmationNode.getAttributeValue('Shipper', null);
                    String shipVia = shippingConfirmationNode.getAttributeValue('ShipVia', null);
                    Date shipDate = Date.valueOf(shippingConfirmationNode.getAttributeValue('ShipDate', null));
                    String tracking = shippingConfirmationNode.getChildElement('Tracking', null).getText();

                    Shipment shipment = new Shipment();
                    shipment.FulfillmentOrderId = orderNumber;
                    shipment.Shipping_Method__c=shipVia;
                    shipment.Provider=shipVia;
                    shipment.Status='Shipped';
                    shipment.TrackingNumber=tracking;
                    shipment.Ship_Date__c=shipDate;

                    insert shipment;

                    List<ShipmentItem> shipmentItemsToInsert = new List<ShipmentItem>();

                    for (Dom.XmlNode shipChildNode : shippingConfirmationNode.getChildElements()) 
                    {
                        System.debug(shipChildNode.getName());
                        if(shipChildNode.getName() == 'Item')
                        {
                            Dom.XmlNode itemNode= shipChildNode;
                            String glCode = '';
                            String lotNumber = '';
                            String serialNumber = '';
                            Date expireDate = null;
                            String returnTracking = '';
                            Integer shippedQty = null;
                             String tubeSerial = '';
                            String verificationId = '';
                            if(itemNode.getAttributeValue('GLCode',null) != null)
                            {
                                glCode = itemNode.getAttributeValue('GLCode',null);
                            }    
                            if(itemNode.getAttributeValue('LotNumber',null) != null)
                            {
                                lotNumber = itemNode.getAttributeValue('LotNumber',null);
                            }    
                            if(itemNode.getAttributeValue('SerialNumber',null) != null)
                            {
                                serialNumber = itemNode.getAttributeValue('SerialNumber',null);
                            }                            
                            if(itemNode.getAttributeValue('ExpireDate',null) != null && !String.isBlank(itemNode.getAttributeValue('ExpireDate',null)))
                            {
                                expireDate = Date.valueOf(itemNode.getAttributeValue('ExpireDate',null));
                            }
                            if(itemNode.getChildElement('ReturnTracking', null)!= null)
                            {
                                returnTracking = itemNode.getChildElement('ReturnTracking', null).getText();
                            }
                            if(itemNode.getAttributeValue('ShippedQty',null) !=null)
                            {
                                shippedQty = Integer.valueOf(itemNode.getAttributeValue('ShippedQty',null));
                            }                           
                           
                            if(kitRecord && itemNode.getChildElement('TubeSerial', null) != null)
                            {
                                tubeSerial = itemNode.getChildElement('TubeSerial', null).getText();
                                verificationId = itemNode.getChildElement('TubeSerial', null).getAttributeValue('VerificationId',null);
                            }
                            
                            // Check for duplicate TubeSerial within the payload
                            if (!kitRecord || (kitRecord && !activationCodeSet.contains(tubeSerial))) {
                                if(kitRecord)
                                {
                                    activationCodeSet.add(tubeSerial);
                                }
                                
                                // Add to shipment items list
                                shipmentItemsToInsert.add(new ShipmentItem(
                                    FulfillmentOrderLineItemId = glCode,
                                    LotNumber__c = lotNumber,
                                    Serial_Number__c = serialNumber,
                                    Expiration_Date__c = expireDate,
                                    Quantity = shippedQty,
                                    Activation_Code__c = tubeSerial,
                                    Verification_ID__c = verificationId,
                                    Return_Tracking_Number__c=returnTracking,
                                    Status__c='Kit Shipped',
                                    shipmentId = shipment.Id
                                ));
                            } 
                        }
                }
   
                    System.debug(shipmentItemsToInsert);
                    // Bulk insert shipment items
                    if (!shipmentItemsToInsert.isEmpty()) {
                        List<Database.SaveResult> results = Database.insert(shipmentItemsToInsert, false);
                        System.debug('Results : ' + results);
                        
                    }

                    // insert shipmentItemsToInsert;

                }
            }
        }

    }
}