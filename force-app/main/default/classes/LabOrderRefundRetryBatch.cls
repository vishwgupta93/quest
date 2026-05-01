global with sharing class LabOrderRefundRetryBatch implements Database.Batchable <SObject>, Database.AllowsCallouts {
 public  String Query;
 public String labOrderId;

 global Database.QueryLocator start(Database.BatchableContext bc){
 return Database.getQueryLocator(Query);
 }
 global void execute(Database.BatchableContext bc, List<Lab_Order__c> lstRecords){

    String paymentSummaryId='';
    String paymentAuthId='';
    String gatewayRefNumber='';
    Double refundAmount=0.0;

            for(Lab_Order__c order:lstRecords )
            {
                System.debug('order : ' + order);

                refundAmount = order.Refund_Amount__c;

                List<PaymentAuthorization> paymentAuthorizations = [select Id,Amount,OrderPaymentSummaryId,Order_Summary_Id__c,GatewayRefNumber,paymentType__c  from PaymentAuthorization  where Order_Summary_Id__c =: order.Order_Summary__c ];

                for(PaymentAuthorization auth : paymentAuthorizations)
                {
                    if(auth.paymentType__c == 'gift_card')
                    {
                        refundAmount = refundAmount - auth.Amount;
                    }
                    else
                    {
                        paymentSummaryId=auth.OrderPaymentSummaryId;
                        paymentAuthId=auth.Id;
                        gatewayRefNumber=auth.GatewayRefNumber;
                    }
                }

                System.debug('Final refundAmount : ' + refundAmount + ' gatewayRefNumber:  ' + gatewayRefNumber);


                Lab_Order__c labOrderToUpdate =  new Lab_Order__c();
                labOrderToUpdate.id= order.Id;

                Refund refundRecord = new Refund();
                  
                
                if(refundAmount > 0.0)
                {
                        //Call Stripe
                        Event_Log__c eventLog = new Event_Log__c();
                        eventLog.Order_Summary__c =order.Order_Summary__c;                                
                        eventLog.Event_Type__c ='Payment Refund';                         
            
                    try
                    {
                        Http http = new Http();
                        HttpRequest request = new HttpRequest();
                        request.setEndpoint(label.SFOM_Stripe_Refund_URL);
                        request.setMethod('POST');
                        request.setHeader('Content-Type','application/x-www-form-urlencoded');
                        request.setHeader('Authorization','Bearer '+Label.SFOM_Stripe_Direct_Token );
                        // Set the parameters for the POST request
                        String body = 'amount=' + (refundAmount * 100).intValue() + '&payment_intent=' + gatewayRefNumber;
                        request.setBody(body);
                        eventLog.Payload__c=body;  

                        System.debug('request : ' + request + ' Body : ' + body);


                        // Send the HTTP request
                        http = new Http();
                        HttpResponse response = http.send(request);

                        System.debug('response : ' + response);


                        // Handle the response
                        if (response.getStatusCode() == 200) {
                            eventLog.Status__c='Success';
                            eventLog.Response_Payload__c=response.getBody();
                            labOrderToUpdate.Is_Refund_Error__c=false;
                            labOrderToUpdate.Refund_Attempts__c= order.Refund_Attempts__c + 1;

                            refundRecord.amount=refundAmount;
                            refundRecord.GatewayRefNumber=gatewayRefNumber;
                            refundRecord.OrderPaymentSummaryId=paymentSummaryId;
                            refundRecord.ProcessingMode='External';
                            refundRecord.Status='Processed';
                            refundRecord.Type='Referenced';

                            System.debug('refundRecord to persist : ' + refundRecord);

                            insert refundRecord;

                        } else {
                            Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                            Map<String, Object> errorMap = (Map<String, Object>) parsedJson.get('error');
                            // output.statusCode=response.getStatusCode();
                            String errorMessage=(String) errorMap.get('code') + ' : ' + (String) errorMap.get('message');
                            eventLog.Status__c='Error';
                            eventLog.Response_Payload__c=errorMessage + ' :  '+response.getBody();
                            labOrderToUpdate.Is_Refund_Error__c=true;
                            labOrderToUpdate.Refund_Attempts__c= order.Refund_Attempts__c + 1;
                        }
                    
                    }
                    catch(Exception e)
                    {
                        labOrderToUpdate.Is_Refund_Error__c=true;
                        labOrderToUpdate.Refund_Attempts__c= order.Refund_Attempts__c + 1;
                        eventLog.Status__c='Error';
                        eventLog.Response_Payload__c='Failed to refund payment: ' + e.getMessage() ;
                        // output.errorMessage = 'Failed to refund payment: ' + e.getMessage();
                    }
                    insert eventLog;
                }
                System.debug('labOrderToUpdate : ' + labOrderToUpdate);

                update labOrderToUpdate;
                
            }
 }
 global void finish(Database.BatchableContext bc) {
 }
}