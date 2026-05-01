public with sharing class SFOMStripeDirectCapturePayment {
    public class InputParameters {
        @InvocableVariable(required = true)
         public String GatewayRefNumber;
         @InvocableVariable(required = true)
         public String stripeAPIToken;
         @InvocableVariable(required = true)
         public Decimal amountToCapture;
         @InvocableVariable(required = true)
         public Boolean multiCapture;    
      }
      
      public class OutputParameters{
        @InvocableVariable
        public Integer statusCode;
        @InvocableVariable
        public String errorMessage;
        @InvocableVariable
        public String transactionType;
        @InvocableVariable
        public String responsePayload;
        @InvocableVariable
        public String requestPayload;
        @InvocableVariable
        public Decimal amountCaptured;
      } 

      @InvocableMethod(label='Stripe - Capture Payment' description='Capture Payment')
      public static List<OutputParameters>  capturePayment(List<InputParameters> inputs)
      {
        
        List<OutputParameters> outputs = new List<OutputParameters>();

        for (InputParameters input : inputs)
        {
            //Make first call to check the amount capturable against
            OutputParameters output = new OutputParameters(); 
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(label.SFOM_Stripe_URL+input.GatewayRefNumber );
            request.setMethod('GET');
            request.setHeader('Content-Type','application/x-www-form-urlencoded');
            request.setHeader('Authorization','Bearer '+input.stripeAPIToken );
            
                        
            try
            {
                HttpResponse response = http.send(request); 
                Integer statusCode = response.getStatusCode();
                output.statusCode=response.getStatusCode();
                if(statusCode>=400){
                    Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    Map<String, Object> errorMap = (Map<String, Object>) parsedJson.get('error');
                    output.statusCode=response.getStatusCode();
                    output.errorMessage=(String) errorMap.get('code') + ' : ' + (String) errorMap.get('message');
                    output.transactionType='GET Payment Intent'; 
                }
                else {
                    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    // Get the amount_capturable value
                    Decimal amountCapturable = (Decimal) jsonMap.get('amount_capturable');
                    amountCapturable = amountCapturable/100;
                    Decimal stripeAmountToCapture = Math.min(amountCapturable, input.amountToCapture);
                    String body = 'amount_to_capture=' + (stripeAmountToCapture * 100).intValue();
                    Boolean finalCapture=false;
                    if(input.multiCapture)
                    {
                        if(amountCapturable <= input.amountToCapture)
                            finalCapture=true;
                        body = body + '&final_capture=' + finalCapture;
                    }                    
                    
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint(label.SFOM_Stripe_URL+input.GatewayRefNumber+'/capture');
                    req.setMethod('POST');
                    req.setHeader('Authorization', 'Bearer ' + input.stripeAPIToken);
                    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

                    // Set the parameters for the POST request
                    
                    req.setBody(body);
                    output.requestPayload=body;

                    // Send the HTTP request
                    http = new Http();
                    response = http.send(req);

                    // Handle the response
                    if (response.getStatusCode() == 200) {
                        output.statusCode=response.getStatusCode();
                        output.responsePayload=response.getBody();
                        output.amountCaptured=stripeAmountToCapture;
                        System.debug('Response: ' + response.getBody());
                    } else {
                        Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                        Map<String, Object> errorMap = (Map<String, Object>) parsedJson.get('error');
                        output.statusCode=response.getStatusCode();
                        output.errorMessage=(String) errorMap.get('code') + ' : ' + (String) errorMap.get('message');
                        output.responsePayload=response.getBody();
                        output.amountCaptured=input.amountToCapture;
                        output.transactionType='Capture Payment Intent'; 
                        System.debug('Failed to capture payment intent. Status: ' + response.getStatus() + ', Response: ' + response.getBody());
                    }
                }
            }
            catch(Exception e)
            {
                output.errorMessage = 'Failed to capture payment: ' + e.getMessage();
            }

            outputs.add(output);
        }
        System.debug(outputs);
       return outputs;
      }
}