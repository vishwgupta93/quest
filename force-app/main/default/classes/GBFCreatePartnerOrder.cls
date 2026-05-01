public without sharing class GBFCreatePartnerOrder {
    public class GBFCreatePartnerOrderInput {
        @InvocableVariable(label='API_KEY' description='API Key')
        public String apiKey;
        @InvocableVariable(label='PartnerOrderId' description='Partner Order Id')
        public String partnerOrderId; 
        @InvocableVariable(label='Test' description='Flag to Indicate Test or PROD')
        public Boolean test; 
    }

    public class GBFCreatePartnerOrderOutput {
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

    @InvocableMethod(label='Create GBF Order' description='Create GBF Order')
    public static List<GBFCreatePartnerOrderOutput> createGBFOrder(List<GBFCreatePartnerOrderInput> inputs)
    {
        List<GBFCreatePartnerOrderOutput> outputs = new List<GBFCreatePartnerOrderOutput>();

            for(GBFCreatePartnerOrderInput input : inputs)
                {
                    Http http = new Http();
                    HttpResponse response;
                    HttpRequest request = new HttpRequest();
                    Integer statusCode;
                    GBFCreatePartnerOrderOutput output = new GBFCreatePartnerOrderOutput();
                    try 
                    {

                        System.debug('Parnter Order ID : ' + input.partnerOrderId);
             
                        Partner_Order__c order = [SELECT Id, Company_Name__c,First_Name__c,Last_Name__c, 
                        Address_Line_1__c,Address_Line_2__c,City__c, State__c,ZipCode__c,Country__c,Shipping_Method__c,
                        Retail_Partner__r.Client_ID__c,Email__c,PhoneNumber__c
                        FROM Partner_Order__c WHERE Id = :input.partnerOrderId];

                        String name = '';
                        String addressLine = order.Address_Line_1__c;

                        if(String.isNotBlank(order.Address_Line_2__c))
                        {
                            addressLine = addressLine + ' ' + order.Address_Line_2__c;
                        }

                        if(String.isNotBlank(order.First_Name__c) && String.isNotBlank(order.Last_Name__c))
                        {
                            name = order.First_Name__c + ' ' + order.Last_Name__c;
                        }
                        else{
                            name = order.Company_Name__c;
                        }                        

                         System.debug('Parnter Order : ' + order);

                         System.debug('Name : ' + name);

                        List<Partner_Order_Line_Item__c> items= [SELECT Id,Product__r.ProductCode, Quantity__c FROM Partner_Order_Line_Item__c where Partner_Order__c = :input.partnerOrderId];

                         System.debug('Parnter Order Lines : ' + items);

                        Dom.Document doc = new Dom.Document();
                        Dom.XmlNode orders = doc.createRootElement('Orders', null, null);
                        Dom.XmlNode orderNode = orders.addChildElement('Order', null, null);
                        orderNode.setAttribute('Test', String.valueOf(input.test));
                        orderNode.addChildElement('OrderNumber', null, null).addTextNode(order.Id);
                        orderNode.addChildElement('ClientId', null, null).addTextNode(order.Retail_Partner__r.Client_ID__c);

                        Dom.XmlNode shippingInfoNode = orderNode.addChildElement('ShippingInfo', null, null);
                        Dom.XmlNode addressNode = shippingInfoNode.addChildElement('Address', null, null);
                        addressNode.addChildElement('Company', null, null).addTextNode(name);
                        addressNode.addChildElement('AddressLine1', null, null).addTextNode(addressLine);
                        // addressNode.addChildElement('AddressLine2', null, null).addTextNode(order.Address_Line_2__c != null ? order.Address_Line_2__c : '');
                        addressNode.addChildElement('City', null, null).addTextNode(order.City__c);
                        addressNode.addChildElement('State', null, null).addTextNode(order.State__c);
                        addressNode.addChildElement('ZipCode', null, null).addTextNode(order.ZipCode__c);
                        addressNode.addChildElement('Country', null, null).addTextNode(order.Country__c);
                        addressNode.addChildElement('EmailAddress', null, null).addTextNode(order.Email__c);
                        addressNode.addChildElement('PhoneNumber', null, null).addTextNode(order.PhoneNumber__c.replaceAll('[^0-9]', ''));
                        //setTex(order.PhoneNumber__c.replaceAll('[^0-9]', ''));

                        shippingInfoNode.addChildElement('ShipMethod', null, null).addTextNode('FedEx Ground');

                        for (Partner_Order_Line_Item__c lineItem : items) {
                            Dom.XmlNode lineItemNode = orderNode.addChildElement('LineItem', null, null);
                            lineItemNode.setAttribute('GLCode', lineItem.Id);
                            lineItemNode.addChildElement('ItemNumber', null, null).addTextNode(lineItem.Product__r.ProductCode);
                            lineItemNode.addChildElement('ItemQuantity', null, null).addTextNode(String.valueOf(lineItem.Quantity__c));
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