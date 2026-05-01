public with sharing class QuestSSCreateOrder {
    public class QuestSSCreateOrderInput {
        @InvocableVariable(label='API_TOKEN' description='API Token')
        public String apiToken;
        @InvocableVariable(label='FO ID' description='Fulfillment Order Id')
        public String fulfillmentOrderId; 
        @InvocableVariable(label='Test' description='Flag to Indicate Test or PROD')
        public Boolean test; 
    }

    public class QuestSSCreateOrderOutput {
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

    @InvocableMethod(label='Create Quest Shipstation Order' description='Create Quest Shipstation Order')
    public static List<QuestSSCreateOrderOutput> createShipStationOrder(List<QuestSSCreateOrderInput> inputs)
    {
        List<QuestSSCreateOrderOutput> outputs = new List<QuestSSCreateOrderOutput>();

            for(QuestSSCreateOrderInput input : inputs)
                {
                    Http http = new Http();
                    HttpResponse response;
                    HttpRequest request = new HttpRequest();
                    Integer statusCode;
                    QuestSSCreateOrderOutput output = new QuestSSCreateOrderOutput();
                    try 
                    {
             
                        FulfillmentOrder order = [SELECT Id,OrderSummary.OrderedDate, FirstName__c,MiddleName__c,LastName__c,OrderSummary.CustomerId__c,OrderSummary.BillingPhoneNumber,OrderSummary.BillingEmailAddress,FulfilledToAddress,FulfilledToAddressLine1__c,FulfilledToPhone 
                            FROM FulfillmentOrder WHERE Id = :input.fulfillmentOrderId];

                        List<FulfillmentOrderLineItem> items= [SELECT Id,ProductCode__c, Quantity FROM FulfillmentOrderLineItem where  fulfillmentOrderId = :input.fulfillmentOrderId and Test_Type__c in ('at_home','GSS')];

                        String addressLine1 = '';
                        String phoneNumber = '';

                        if(order.OrderSummary.BillingPhoneNumber != null)
                        {
                            phoneNumber = order.OrderSummary.BillingPhoneNumber;
                        }
                        else {
                            phoneNumber = order.FulfilledToPhone;
                        }
                       
                            addressLine1 = order.FulfilledToAddressLine1__c;
                            Address address = order.FulfilledToAddress;

                            System.debug(order.MiddleName__c);
                            System.debug(order.LastName__c);
                       
                            String name = order.FirstName__c;
                            
                            if(order.MiddleName__c != null)
                            {
                                name = name + ' ' + order.MiddleName__c;
                            }
                                
                            if(order.LastName__c != null)
                            {
                                name = name + ' ' + order.LastName__c;
                            }
                                
                            if(input.test)
                            {
                                name = name + ' TEST';
                            }
                                
                            


                       // Create the JSON generator
                        JSONGenerator gen = JSON.createGenerator(true);

                        gen.writeStartObject();

                        // Write order details
                        gen.writeStringField('orderNumber', order.Id);
                        gen.writeStringField('orderDate', order.OrderSummary.OrderedDate.format('yyyy-MM-dd')); // Assuming static date
                        gen.writeNullField('paymentDate');
                        gen.writeNullField('shipByDate');
                        gen.writeStringField('orderStatus', 'awaiting_shipment');
                        gen.writeStringField('customerEmail', order.OrderSummary.BillingEmailAddress);

                        // Write shipTo details
                        gen.writeFieldName('shipTo');
                        gen.writeStartObject();
                        gen.writeStringField('name', name);
                        gen.writeNullField('company');
                        gen.writeStringField('street1', order.FulfilledToAddressLine1__c);
                        gen.writeNullField('street2');
                        gen.writeNullField('street3');
                        gen.writeStringField('city', address.city);  // Placeholder value
                        gen.writeStringField('state', address.state);      // Placeholder value
                        gen.writeStringField('postalCode', address.postalcode);       // Placeholder value
                        gen.writeStringField('country', address.country); // Placeholder value
                        gen.writeStringField('phone', phoneNumber.replaceAll('[^0-9]', ''));
                        gen.writeNullField('residential');
                        gen.writeEndObject();

                        // Write billTo details
                        gen.writeFieldName('billTo');
                        gen.writeStartObject();
                        gen.writeStringField('name', name);
                        gen.writeNullField('company');
                        gen.writeNullField('street1');
                        gen.writeNullField('street2');
                        gen.writeNullField('street3');
                        gen.writeNullField('city');
                        gen.writeNullField('state');
                        gen.writeNullField('postalCode');
                        gen.writeNullField('country');
                        gen.writeNullField('phone');
                        gen.writeNullField('residential');
                        gen.writeEndObject();

                        // Write items
                        gen.writeFieldName('items');
                        gen.writeStartArray();
                        for (FulfillmentOrderLineItem item : items) {
                            gen.writeStartObject();
                            gen.writeStringField('lineItemKey', item.Id);
                            gen.writeStringField('sku', item.ProductCode__c);
                            gen.writeStringField('name', ''); // Assuming name is empty
                            gen.writeNumberField('quantity', item.Quantity);
                            gen.writeEndObject();
                        }
                        gen.writeEndArray();

                        // Write other fields
                        gen.writeStringField('customerNotes', 'TEST');
                        gen.writeNullField('internalNotes');
                        gen.writeBooleanField('gift', false);
                        gen.writeNullField('giftMessage');
                        gen.writeNullField('paymentMethod');
                        gen.writeNullField('carrierCode');
                        gen.writeStringField('serviceCode', 'USPS Shipping');
                        gen.writeNullField('packageCode');
                        gen.writeNullField('confirmation');

                        // Write advancedOptions
                        gen.writeFieldName('advancedOptions');
                        gen.writeStartObject();
                        gen.writeStringField('storeId', '424577'); // Assuming static store ID
                        gen.writeEndObject();

                        gen.writeEndObject();

                        // Get the JSON string
                        String jsonString = gen.getAsString();
                        System.debug(jsonString);
                        
                        request.setEndpoint(Label.SS_Endpoint+'/orders/createorder');
                        request.setMethod('POST');
                        request.setHeader('Content-Type','application/json');
                        request.setHeader('Authorization','Basic ' + input.apiToken);
                        request.setBody(jsonString);
                        response = http.send(request);
                        statusCode = response.getStatusCode();
                        
                        if(statusCode==200)
                        {
                            output.responsePayload=response.getBody();
                            output.status='Success';
                            output.requestPayload=jsonString;
                            output.responseCode=String.valueOf(statusCode);
                            output.responseMessage=response.getStatus();
                        }
                        else {
                            output.responsePayload=response.getBody();
                            output.status='Error';
                            output.requestPayload=jsonString;
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