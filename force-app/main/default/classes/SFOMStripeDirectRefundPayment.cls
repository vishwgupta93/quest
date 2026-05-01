public with sharing class SFOMStripeDirectRefundPayment {
    public class InputParameters {
        @InvocableVariable(required = true)
         public String GatewayRefNumber;
         @InvocableVariable(required = true)
         public String stripeAPIToken;
         @InvocableVariable(required = true)
         public Decimal amountToRefund;    
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
        public Decimal amountRefunded;
      }
      
      @InvocableMethod(label='Stripe - Refund Payment' description='Refund Payment')
      public static List<OutputParameters>  refundPayment(List<InputParameters> inputs)
      {
        
        List<OutputParameters> outputs = new List<OutputParameters>();

        for (InputParameters input : inputs)
        {
            //Make first call to check the amount capturable against
            OutputParameters output = new OutputParameters(); 
            
            
                        
            try
            {
                    Http http = new Http();
                    HttpRequest request = new HttpRequest();
                    request.setEndpoint(label.SFOM_Stripe_Refund_URL);
                    request.setMethod('POST');
                    request.setHeader('Content-Type','application/x-www-form-urlencoded');
                    request.setHeader('Authorization','Bearer '+input.stripeAPIToken );
                    // Set the parameters for the POST request
                    String body = 'amount=' + (input.amountToRefund * 100).intValue() + '&payment_intent=' + input.GatewayRefNumber;
                    request.setBody(body);
                    output.requestPayload=body;

                    // Send the HTTP request
                    http = new Http();
                    HttpResponse response = http.send(request);

                    // Handle the response
                    if (response.getStatusCode() == 200) {
                        output.statusCode=response.getStatusCode();
                        output.responsePayload=response.getBody();
                        output.amountRefunded=input.amountToRefund;
                        System.debug('Response: ' + response.getBody());
                    } else {
                        Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                        Map<String, Object> errorMap = (Map<String, Object>) parsedJson.get('error');
                        output.statusCode=response.getStatusCode();
                        output.errorMessage=(String) errorMap.get('code') + ' : ' + (String) errorMap.get('message');
                        output.responsePayload=response.getBody();
                        output.transactionType='Capture Payment Intent'; 
                        System.debug('Failed to capture payment intent. Status: ' + response.getStatus() + ', Response: ' + response.getBody());
                    }
                
            }
            catch(Exception e)
            {
                output.errorMessage = 'Failed to refund payment: ' + e.getMessage();
            }

            outputs.add(output);
        }
        System.debug(outputs);
       return outputs;
      }
}