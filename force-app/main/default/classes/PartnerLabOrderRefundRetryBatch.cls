global with sharing class PartnerLabOrderRefundRetryBatch implements Database.Batchable <SObject>, Database.AllowsCallouts {
 public  String Query;
 public String labOrderId;

 global Database.QueryLocator start(Database.BatchableContext bc){
 return Database.getQueryLocator(Query);
 }
 global void execute(Database.BatchableContext bc, List<Lab_Order__c> lstRecords){

    
    Decimal amountToRefund=0.0;
    

            for(Lab_Order__c order:lstRecords )
            {
                System.debug('order : ' + order);
                Lab_Order__c labOrderToUpdate =  new Lab_Order__c();
                labOrderToUpdate.Id=order.Id;

                amountToRefund = order.Refund_Amount__c;

                Decimal amountReceived = 0.0;
                Double cancellationFee = order.Cancellation_Service_Fee__c;
                Event_Log__c eventLog = new Event_Log__c();
                eventLog.Lab_Order__c =order.Id;                                
                eventLog.Event_Type__c ='Payment Refund'; 


                    Http http = new Http();
                    HttpRequest request = new HttpRequest();
                    HttpResponse response = new HttpResponse();
                    if(order.Captured_Amount__c == null)
                    {
                        request.setEndpoint(label.SFOM_Stripe_URL+order.Payment_Transaction_Id__c );
                        request.setMethod('GET');
                        request.setHeader('Content-Type','application/x-www-form-urlencoded');
                        request.setHeader('Authorization','Bearer '+order.Partner_Client_Map__r.Payment_Key__c);

                        response = http.send(request);
                        if (response.getStatusCode() == 200) {
                            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                            amountReceived = Double.valueOf(responseMap.get('amount_received'));
                            amountReceived = amountReceived != null ? amountReceived/100 : 0.0;
                            System.debug('response: ' + response + ' : amountReceived:  ' + amountReceived );
                            amountToRefund = amountReceived - cancellationFee;
                        } else {
                            System.debug('Error from Stripe for GET call: ' + response.getBody());
                            labOrderToUpdate.Is_Refund_Error__c=true;
                            labOrderToUpdate.Refund_Attempts__c= order.Refund_Attempts__c+1;
                            eventLog.Status__c='Error';
                            eventLog.Response_Payload__c='Stripe API call failed with status: ' + response.getBody()  + ' : '+ response.getStatus();                    
                        }
                    }
                
                if(amountToRefund > 0.0)
                {
                    
                                  
                    try
                    {
                        
                        request.setEndpoint(label.SFOM_Stripe_Refund_URL);
                        request.setMethod('POST');
                        request.setHeader('Content-Type','application/x-www-form-urlencoded');
                        request.setHeader('Authorization','Bearer '+order.Partner_Client_Map__r.Payment_Key__c );
                        String body = 'amount=' + (amountToRefund * 100).intValue() + '&payment_intent=' + order.Payment_Transaction_Id__c;
                        request.setBody(body);
                        eventLog.Payload__c=body;
                        
                        System.debug('request : ' + request + ' Body : ' + body);

                        // Send the HTTP request
                        http = new Http();
                        response = http.send(request);

                        System.debug('response : ' + response);

                        // Handle the response
                        if (response.getStatusCode() == 200) {
                            eventLog.Status__c='Success';
                            eventLog.Response_Payload__c=response.getBody();
                        } else {
                            Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                            Map<String, Object> errorMap = (Map<String, Object>) parsedJson.get('error');
                            // output.statusCode=response.getStatusCode();
                            String errorMessage=(String) errorMap.get('code') + ' : ' + (String) errorMap.get('message');
                            eventLog.Status__c='Error';
                            eventLog.Response_Payload__c=errorMessage + ' :  '+response.getBody();
                            labOrderToUpdate.Is_Refund_Error__c=true;
                            labOrderToUpdate.Refund_Attempts__c= order.Refund_Attempts__c+1;
                        }
                    
                    }
                    catch(Exception e)
                    {
                        System.debug('Error : ' + e.getMessage());
                        labOrderToUpdate.Is_Refund_Error__c=true;
                        labOrderToUpdate.Refund_Attempts__c= order.Refund_Attempts__c+1;
                        eventLog.Status__c='Error';
                        eventLog.Response_Payload__c='Failed to refund payment: ' + e.getMessage() ;
                    }

                    labOrderToUpdate.Refund_Amount__c=amountToRefund;
                    labOrderToUpdate.Captured_Amount__c= amountReceived;
                    labOrderToUpdate.Cancellation_Service_Fee__c= cancellationFee;

                    System.debug('labOrderToUpdate : ' + labOrderToUpdate);

                    insert eventLog;
                    
                }
                System.debug('labOrderToUpdate : ' + labOrderToUpdate);

                update labOrderToUpdate;
                
            }
 }
 global void finish(Database.BatchableContext bc) {
 }
}