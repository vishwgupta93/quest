public with sharing class GBFShipmentConfirmationParser {
    public static void processShipmentConfirmation(List<Object> dataArray) {        
       
        

        System.debug(dataArray);

        for(Object dataObj : dataArray)
        {
            
                Map<String, Object> data = (Map<String, Object>)dataObj;
                System.debug(data);

                       
                String format = (String) data.get('format');
                String xmlData = (String) data.get('data');

                System.debug(xmlData);

                // Parse XML data
                Dom.Document doc = new Dom.Document();
                doc.load(xmlData);

                // Extract Shipment Info
                Set<String> trackingNumbers= new Set<String>();

                for (Dom.XmlNode childNode : doc.getRootElement().getChildElements()) 
                {
                    if(childNode.getName() == 'ShippingConfirmation')
                    {
                        Dom.XmlNode shippingConfirmationNode = childNode;
                        String orderNumber = shippingConfirmationNode.getAttributeValue('OrderNumber', null);
                        String tracking = shippingConfirmationNode.getChildElement('Tracking', null).getText();
                        
                        Partner_Order__c order = [SELECT Id,  Status__c FROM Partner_Order__c WHERE Id =:orderNumber ];
                        if(order.Status__c == 'Shipped')
                        {
                            List<Partner_Shipment_Info__c> shipmentInfosInDB = [select Id,Partner_Order__c, Tracking_Number__c from Partner_Shipment_Info__c where Partner_Order__c =: orderNumber ];
                            System.debug('Shipment Infos: ' + shipmentInfosInDB);

                            if(shipmentInfosInDB.isEmpty())
                            {
                                processAndPersistShipmentInfo(shippingConfirmationNode);                
                            }
                            else 
                            {
                                for(Partner_Shipment_Info__c shipmentInfo : shipmentInfosInDB)
                                {
                                    if(shipmentInfo.Tracking_Number__c != null)
                                        trackingNumbers.add(shipmentInfo.Tracking_Number__c);
                                    
                                }
                                System.debug('Shipment Infos Tracking Numbers: ' + trackingNumbers);

                                if(!trackingNumbers.contains(tracking))
                                {
                                    processAndPersistShipmentInfo(shippingConfirmationNode); 
                                }
                            }
                        }

                
                    }
                }

                

                
        }
        
    }

    private static void processAndPersistShipmentInfo(Dom.XmlNode doc)
    {

        // Lists to hold records for bulk insert
        List<Partner_Order_Shipment_Item__c> shipmentItemsToInsert = new List<Partner_Order_Shipment_Item__c>();
        List<Partner_Order_Duplicate_Shipment_Item__c> duplicateItemsToInsert = new List<Partner_Order_Duplicate_Shipment_Item__c>();
        Set<String> activationCodeSet = new Set<String>();
        
        String orderNumber = doc.getAttributeValue('OrderNumber', null);
        String shipper = doc.getAttributeValue('Shipper', null);
        String shipVia = doc.getAttributeValue('ShipVia', null);
        Date shipDate = Date.valueOf(doc.getAttributeValue('ShipDate', null));
        String tracking = doc.getChildElement('Tracking', null).getText();

         // Create Partner_Order_Shipment_Info__c
        Partner_Shipment_Info__c shipmentInfo = new Partner_Shipment_Info__c(
                    Partner_Order__c = orderNumber,
                    Shipper__c = shipper,
                    Ship_Via__c = shipVia,
                    Shipped_Date__c = shipDate,
                    Tracking_Number__c = tracking
                );
        System.debug(shipmentInfo);
        insert shipmentInfo;

                // Process each Item in the Shipment
                    for (Dom.XmlNode childNode : doc.getChildElements()) 
                    {
                        System.debug(childNode.getName());
                        if(childNode.getName() == 'Item')
                        {
                            Dom.XmlNode itemNode= childNode;
                            String glCode = itemNode.getAttributeValue('GLCode',null);
                            String lotNumber = itemNode.getAttributeValue('LotNumber',null);
                            String serialNumber = itemNode.getAttributeValue('SerialNumber',null);
                            Date expireDate = Date.valueOf(itemNode.getAttributeValue('ExpireDate',null));
                            String returnTracking = itemNode.getChildElement('ReturnTracking', null).getText();
                            // Integer shippedQty = Integer.valueOf(itemNode.getAttributeValue('ShippedQty'));
                            
                            Dom.XmlNode tubeSerialNode = itemNode.getChildElement('TubeSerial', null);
                            String tubeSerial = '';
                            String verificationId = '';

                            if(tubeSerialNode == null)
                            {                               
                                Case dataCase = new Case();
                                dataCase.OwnerId= Label.Partner_Order_Error_Queue;
                                dataCase.Case_Type__c='Data';
                                dataCase.Status='New';
                                dataCase.Subject='Activation Code is not present';
                                dataCase.Partner_Order__c=orderNumber;
                                dataCase.Description='Activation Code is not present ' + tracking + ' : '+ shipper + ' : '+ serialNumber;
                                dataCase.Priority='Medium';
                                insert dataCase;
                            }
                            else {
                                tubeSerial = tubeSerialNode.getText();
                                verificationId = tubeSerialNode.getAttributeValue('VerificationId',null);
                                // Check for duplicate TubeSerial within the payload
                                if (!activationCodeSet.contains(tubeSerial)) {
                                    activationCodeSet.add(tubeSerial);
                                    // Add to shipment items list
                                    shipmentItemsToInsert.add(new Partner_Order_Shipment_Item__c(
                                        Line_Item__c = glCode,
                                        Lot_Number__c = lotNumber,
                                        Serial_Number__c = serialNumber,
                                        Expiration_Date__c = expireDate,
                                        // ShippedQty__c = shippedQty,
                                        Activation_Code__c = tubeSerial,
                                        Verification_ID__c = verificationId,
                                        returnTracking__c=returnTracking,
                                        Partner_Order_Shipment_Info__c = shipmentInfo.Id
                                    ));
                                    
                                } else {
                                    // Add to duplicate items list
                                    duplicateItemsToInsert.add(new Partner_Order_Duplicate_Shipment_Item__c(
                                        Line_Item__c = glCode,
                                        Lot_Number__c = lotNumber,
                                        Serial_Number__c = serialNumber,
                                        Expiration_Date__c = expireDate,
                                        // ShippedQty__c = shippedQty,
                                        Activation_Code__c = tubeSerial,
                                        Verification_ID__c = verificationId,
                                        returnTracking__c=returnTracking,
                                        Shipment__c = shipmentInfo.Id,
                                        Partner_Order__c=orderNumber
                                    ));
                                }
                            }
                            
                        }
                }
   
                    System.debug(shipmentItemsToInsert);
                    // Bulk insert shipment items
                    if (!shipmentItemsToInsert.isEmpty()) {
                        List<Database.SaveResult> results = Database.insert(shipmentItemsToInsert, false);
                        System.debug('Results : ' + results);
                        
                    }

                    // Bulk insert duplicate items
                    if (!duplicateItemsToInsert.isEmpty()) {
                        System.debug(duplicateItemsToInsert);
                        List<Database.SaveResult> results = Database.insert(duplicateItemsToInsert, false);
                        System.debug(results);
                    }
    }

    
}