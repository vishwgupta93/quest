public  class EOSTAWSStatusHelper {
    
    public class InputParameters {
        
        @InvocableVariable(label='Notification Details' description='Notification Details')
        public AWSStatusNotification notification;  

   }
    
    public class OutputParameters {
        @InvocableVariable(label='Response Message' description='Response Message from AWS System')
        public String responseMessage;
        
        @InvocableVariable(label='Response Code' description='Response Code from AWS System')
        public String responseCode;
        
        @InvocableVariable(label='Request Payload' description='Request Payload')
        public String requestPayload;
        
        @InvocableVariable(label='Response Payload' description='Response Payload')
        public String responsePayload;
        
        @InvocableVariable(label='Status' description='Status')
        public String status; 

        @InvocableVariable(label='SHL Key' description='SHL Key')
        public String shlKey; 

        @InvocableVariable(label='SHL Location' description='SHL Location')
        public String shlLocation; 
    }
  
    @InvocableMethod(label='Send Lab order status TO AWS ' description='Send Lab order status TO AWS')
    public static List<OutputParameters> postStatusToAWS(List<InputParameters> inputs){
       

        List<OutputParameters> lstOutput = new List<OutputParameters>();
        Map<String, String> statusMap = new Map<String, String>();

        System.debug('Inputs: ' + inputs);

        try {
            for(InputParameters input: inputs)
          {
            OutputParameters output = new OutputParameters();
            System.debug('Notification : ' + input.notification);

            AWSStatusNotification notification =    input.notification;            
           
            for (TPT_Partner_Status_Mapping__mdt record : [
                    SELECT Lab_Order_Status__c, External_Order_Status__c
                            FROM TPT_Partner_Status_Mapping__mdt
                            WHERE TPT_Partner_Name__c = :notification.clientName
                ]) {
                    statusMap.put(record.Lab_Order_Status__c, record.External_Order_Status__c);
                }

                System.debug('statusMap : ' + statusMap);
            JSONGenerator gen = JSON.createGenerator(true);
                    gen.writeStartObject();
                        gen.writeStringField('merchant_order_id',notification.merchantOrderId);
                        gen.writeStringField('partner_id',notification.clientName);
                        gen.writeStringField('lab_order_number',notification.labOrderNumber);
                        gen.writeObjectField('status',statusMap.get(notification.status));
                        gen.writeStringField('shl_key',String.isNotBlank(notification.shlKey) ? notification.shlKey : '');
                        gen.writeStringField('shl_location',String.isNotBlank(notification.shlLocation) ? notification.shlLocation : '');
                    gen.writeEndObject();
                    String requestPayLoad = gen.getAsString();
				    system.debug(requestPayLoad);
                    
                    System.debug('requestPayLoad : ' + requestPayLoad);
                    
                    Http http = new Http();
                    HttpResponse response;
                    HttpRequest request = new HttpRequest();
                    request.setHeader('Content-Type', 'application/json');
                    String endpoint = 'callout:'+notification.namedCredential;
                    request.setEndpoint(endpoint);
                    request.setMethod('POST');
                    request.setBody(requestPayLoad);
                    response = http.send(request);


                    output.requestPayload= requestPayLoad;
                    output.responsePayload= response.getBody();

                    System.debug('response : ' + response + ' Response Body: ' + response.getBody());
                    
                    if (response.getStatusCode() == 200) {
                       
                        Map<String, Object> payloadMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

                        // Extract the 'order' part
                        Map<String, Object> orderMap = (Map<String, Object>)payloadMap.get('order');
                        String shl_key = (String)orderMap.get('shl_key');
                        String shl_location = (String)orderMap.get('shl_location');

                        output.status= 'Success';
                        output.shlKey=shl_key;
                        output.shlLocation=shl_location;
                       
                       
                    }else {
                       
                        output.status= 'Error';
                        
                    }

                    lstOutput.add(output);
                
           
          }
        } catch (Exception e) {
            System.debug(' Error :  ' + e.getMessage());
        }                   
          
          return lstOutput;
            
        }
       
    
}