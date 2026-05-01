public with sharing class QuestGBFCreateOrder {
        public class QuestGBFCreateOrderInput {
            @InvocableVariable(label='API_KEY' description='API Key')
            public String apiKey;
            @InvocableVariable(label='FO ID' description='Fulfillment Order Id')
            public String fulfillmentOrderId; 
            @InvocableVariable(label='Test' description='Flag to Indicate Test or PROD')
            public Boolean test; 
        }
    
        public class QuestGBFCreateOrderOutput {
            @InvocableVariable(label='Response Message' description='Response Message from PWN Service')
            public String responseMessage;
            @InvocableVariable(label='Response Code' description='Response Code from PWN Service')
            public String responseCode;
            @InvocableVariable(label='Request Payload' description='Request Payload')
            public String requestPayload;
            @InvocableVariable(label='Response Payload' description='Response Payload')
            public String responsePayload;
            @InvocableVariable(label='Status' description='Status')
            public String status;
        }
    
        @InvocableMethod(label='Create Quest GBF Order' description='Create Quest GBF Order')
        public static List<QuestGBFCreateOrderOutput> createGBFOrder(List<QuestGBFCreateOrderInput> inputs)
        {
            List<QuestGBFCreateOrderOutput> outputs = new List<QuestGBFCreateOrderOutput>();
    
                for(QuestGBFCreateOrderInput input : inputs)
                    {
                        Http http = new Http();
                        HttpResponse response;
                        HttpRequest request = new HttpRequest();
                        Integer statusCode;
                        QuestGBFCreateOrderOutput output = new QuestGBFCreateOrderOutput();
                        try 
                        {
                 
                            FulfillmentOrder order = [SELECT Id, FirstName__c,LastName__c,FulfilledToAddressLine2__c,OrderSummary.Account.Id,OrderSummary.BillingPhoneNumber,OrderSummary.BillingEmailAddress,FulfilledToAddress,FulfilledToAddressLine1__c,FulfilledToPhone 
                                FROM FulfillmentOrder WHERE Id = :input.fulfillmentOrderId];
    
                            List<FulfillmentOrderLineItem> items= [SELECT Id,ProductCode__c, Quantity FROM FulfillmentOrderLineItem where  fulfillmentOrderId = :input.fulfillmentOrderId and Test_Type__c in ('at_home','GSS')];
    
                            String addressLine1 = '';
                            String addressLine2 = '';
                            String phoneNumber = '';

                            if(order.OrderSummary.BillingPhoneNumber != null)
                            {
                                phoneNumber = order.OrderSummary.BillingPhoneNumber;
                            }
                            else {
                                phoneNumber = order.FulfilledToPhone;
                            }
                           
                                addressLine1 = order.FulfilledToAddressLine1__c;
                                addressLine2 = order.FulfilledToAddressLine2__c;
                                String addressLine = addressLine1;
                                if(String.isBlank(addressLine2))
                                {
                                    addressLine2 = '';
                                }

                                Address address = order.FulfilledToAddress;
                           
                            Dom.Document doc = new Dom.Document();
                            Dom.XmlNode orders = doc.createRootElement('Orders', null, null);
                            Dom.XmlNode orderNode = orders.addChildElement('Order', null, null);
                            orderNode.setAttribute('Test', String.valueOf(input.test));
                            orderNode.addChildElement('OrderNumber', null, null).addTextNode(order.Id);
                            orderNode.addChildElement('ClientId', null, null).addTextNode(order.OrderSummary.Account.Id);
    
                            Dom.XmlNode shippingInfoNode = orderNode.addChildElement('ShippingInfo', null, null);
                            Dom.XmlNode addressNode = shippingInfoNode.addChildElement('Address', null, null);
                            addressNode.addChildElement('Company', null, null).addTextNode(order.FirstName__c + ' ' + order.LastName__c);
                            addressNode.addChildElement('AddressLine1', null, null).addTextNode(addressLine1);
                            addressNode.addChildElement('AddressLine2', null, null).addTextNode(addressLine2);
                            addressNode.addChildElement('City', null, null).addTextNode(address.City);
                            addressNode.addChildElement('State', null, null).addTextNode(address.State);
                            addressNode.addChildElement('ZipCode', null, null).addTextNode(address.PostalCode);
                            addressNode.addChildElement('Country', null, null).addTextNode(address.Country);
                            addressNode.addChildElement('EmailAddress', null, null).addTextNode(order.OrderSummary.BillingEmailAddress);
                            addressNode.addChildElement('PhoneNumber', null, null).addTextNode(phoneNumber.replaceAll('[^0-9]', ''));
                            //setTex(order.PhoneNumber__c.replaceAll('[^0-9]', ''));
    
                            shippingInfoNode.addChildElement('ShipMethod', null, null).addTextNode('FedEx Ground');
    
                            for (FulfillmentOrderLineItem lineItem : items) {
                                Dom.XmlNode lineItemNode = orderNode.addChildElement('LineItem', null, null);
                                lineItemNode.setAttribute('GLCode', lineItem.Id);
                                lineItemNode.addChildElement('ItemNumber', null, null).addTextNode(lineItem.ProductCode__c);
                                lineItemNode.addChildElement('ItemQuantity', null, null).addTextNode(String.valueOf(lineItem.Quantity));
                            }
    
                            System.debug(doc.toXmlString());
    
                            JSONGenerator gen = JSON.createGenerator(true);
                            gen.writeStartObject();
                            gen.writeStringField('orderXml', doc.toXmlString());
                            gen.writeBooleanField('test', input.test);
                            gen.writeEndObject();
    
                            System.debug(gen.getAsString());
    
                            String jsonStr = gen.getAsString();
                            
                            System.debug(jsonStr);
                            
                            request.setEndpoint(Label.GBF_Order_API_Endpoint);
                            request.setMethod('POST');
                            request.setHeader('Content-Type','application/json');
                            request.setHeader('Authorization','Bearer ' + input.apiKey);
                            request.setBody(jsonStr);
                            response = http.send(request);
                            statusCode = response.getStatusCode();
                            
                            if(statusCode==200)
                            {
                                output.responsePayload=response.getBody();
                                output.status='Success';
                                output.requestPayload=jsonStr;
                                output.responseCode=String.valueOf(statusCode);
                                output.responseMessage=response.getStatus();
                            }
                            else {
                                output.responsePayload=response.getBody();
                                output.status='Error';
                                output.requestPayload=jsonStr;
                                output.responseCode=String.valueOf(statusCode);
                                output.responseMessage=response.getStatus();
                            }
                        }
         catch (Exception e) {
            if(response != null)
            {
                output.responseCode=String.valueOf(statusCode);
                output.responseMessage=response.getStatus() + ' Message: ' + response.getBody();
                output.responsePayload = response.getBody();
            }
            else {
                output.responseMessage=e.getMessage();
                output.responsePayload = e.getMessage();
                output.responseCode='504';
            }
            output.Status='Error';
            System.debug('Failed to create Transaction' + e.getMessage());
        }
        outputs.add(output);
    }
    System.debug(outputs);    
            return outputs;
        }
}