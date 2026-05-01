public without sharing class PartnerLabOrderRefund {
    public class Request {
        @InvocableVariable(label='Payment Intent Id' required=true)
        public String paymentIntentId;

        @InvocableVariable(label='Full refund' required=true)
        public boolean fullRefund;

        @InvocableVariable(label='Lab Order ID' required=true)
        public String labOrderId;

        @InvocableVariable(label='Payment Key' required=true)
        public String paymentKey;

        @InvocableVariable(label='Cancellation Fee' required=true)
        public Double cancellationFee;
    }

    public class Response {
        @InvocableVariable(label='Payment Intent Id' required=true)
        public String paymentIntentId;

        @InvocableVariable(label='Is Refund Success' required=true)
        public boolean isRefundSuccess;

        @InvocableVariable(label='Lab Order ID' required=true)
        public String labOrderId;

        @InvocableVariable(label='Payment Key' required=true)
        public String paymentKey;

        @InvocableVariable(label='Amount Refunded' required=true)
        public Double amountRefunded;

        @InvocableVariable(label='Amount Captured' required=true)
        public Double amountCaptured;

        @InvocableVariable(label='Status' required=true)
        public String status;

        @InvocableVariable(label='Request Payload' required=true)
        public String requestPayload;

        @InvocableVariable(label='Response Payload' required=true)
        public String responsePayload;
    }

    @InvocableMethod(label='Refund Partner Order' description='Refunds partner order with details provided')
    public static List<Response> refundPartnerOrder(List<Request> inputs)
    {
        List<Response> responses = new List<Response>();

        for(Request curRequest : inputs)
        {
            Response curResponse = new Response();
            curResponse.labOrderId=curRequest.labOrderId;   
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
                    } else {
                        System.debug('Error from Stripe for GET call: ' + response.getBody());
                        curResponse.isRefundSuccess=false;
                        curResponse.status='Error';
                        curResponse.responsePayload='Stripe API call failed with status: ' + response.getBody()  + ' : '+ response.getStatus();                    
                    }

                    Decimal amountToRefund = amountReceived - curRequest.cancellationFee;


                    if(amountToRefund > 0.0)
                    {
                                    
                        try
                        {
                        
                            request.setEndpoint(label.SFOM_Stripe_Refund_URL);
                            request.setMethod('POST');
                            request.setHeader('Content-Type','application/x-www-form-urlencoded');
                            request.setHeader('Authorization','Bearer '+curRequest.paymentKey);
                            // Set the parameters for the POST request
                            String body = 'amount=' + (amountToRefund * 100).intValue() + '&payment_intent=' + curRequest.paymentIntentId;
                            request.setBody(body);
                            curResponse.requestPayload=body;
                            curResponse.amountRefunded=amountToRefund;
                           
                            System.debug('request : ' + request + ' Body : ' + body);

                            // Send the HTTP request
                            http = new Http();
                            response = http.send(request);

                            System.debug('response : ' + response);

                            // Handle the response
                            if (response.getStatusCode() == 200) {
                                curResponse.isRefundSuccess=true;
                                curResponse.status='Success';
                                curResponse.responsePayload=response.getBody();

                            } else {
                                Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                                Map<String, Object> errorMap = (Map<String, Object>) parsedJson.get('error');
                                String errorMessage=(String) errorMap.get('code') + ' : ' + (String) errorMap.get('message');
                                curResponse.isRefundSuccess=false;
                                curResponse.status='Error';
                                curResponse.responsePayload=errorMessage + ' :  '+response.getBody();
                            }
                        
                        }
                        catch(Exception e)
                        {
                            System.debug('Error : ' + e.getMessage());
                            curResponse.isRefundSuccess=false;
                            curResponse.status='Error';
                            curResponse.responsePayload='Failed to refund payment: ' + e.getMessage();
                        }

                    }
                    
           responses.add(curResponse);
                
        }

        return responses;
    }
}