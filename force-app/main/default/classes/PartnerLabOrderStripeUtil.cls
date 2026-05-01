public without sharing class PartnerLabOrderStripeUtil {
    public class Request {
        @InvocableVariable(label='Payment Intent Id' required=true)
        public String paymentIntentId;

        @InvocableVariable(label='Payment Key' required=true)
        public String paymentKey;
    }

    public class Response {
        @InvocableVariable(label='Payment Intent Id' required=true)
        public String paymentIntentId;

        @InvocableVariable(label='Payment Key' required=true)
        public String paymentKey;

        @InvocableVariable(label='Amount Captured' required=true)
        public Double amountCaptured;

        @InvocableVariable(label='Stripe Error' required=true)
        public Boolean isError;
    }

     @InvocableMethod(label='Get Partner Order Captured Amount' description='Get Partner Order Captured Amount')
    public static List<Response> refundPartnerOrder(List<Request> inputs)
    {
        List<Response> responses = new List<Response>();

        for(Request curRequest : inputs)
        {
            Response curResponse = new Response();
            System.debug('Request: ' + curRequest);
            boolean amountRefunded = false;
            Decimal amountReceived = 0.0;
           

                Http http = new Http();
                HttpRequest request = new HttpRequest();
            	request.setEndpoint(label.SFOM_Stripe_URL+curRequest.paymentIntentId );
                request.setMethod('GET');
                request.setHeader('Content-Type','application/x-www-form-urlencoded');
                request.setHeader('Authorization','Bearer '+curRequest.paymentKey);

                    HttpResponse response = http.send(request);
                    if (response.getStatusCode() == 200) {
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                        amountReceived = Double.valueOf(responseMap.get('amount_received'));
                        amountReceived = amountReceived != null ? amountReceived/100 : 0.0;
                        curResponse.amountCaptured=amountReceived;
                        System.debug('response: ' + response + ' : amountReceived:  ' + amountReceived );
                    }
                    else
                    {
                        curResponse.amountCaptured= amountReceived;
                        curResponse.isError= true;
                    }

            responses.add(curResponse);
        }

        return responses;
    }

}