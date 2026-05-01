global with sharing class LabOrderExpiryBatch implements Database.Batchable <SObject>, Database.AllowsCallouts {
 public  String Query;
 public String labOrderId;
 public String orderSummaryId;
 public String paymentSummaryId;
 public String paymentAuthId;
 public String recordType;
 global Database.QueryLocator start(Database.BatchableContext bc){
 return Database.getQueryLocator(Query);
 }
 global void execute(Database.BatchableContext bc, List<Lab_Order__c> lstRecords){

    String recordTypeId = Label.SFOM_OTC_Cleared_Record_Type_Id;
    String paymentSummaryId='';
    String paymentAuthId='';
    String gatewayRefNumber='';
    Double refundAmount=0.0;

            for(Lab_Order__c order:lstRecords )
            {
                System.debug('order : ' + order);
                
                if(!order.Is_Partner__c)
                {

                    List<FulfillmentOrder> fos = [select Id  from FulfillmentOrder where OrderSummaryId =: order.Order_Summary__c and RecordTypeId =:recordTypeId];
                    System.debug('fos : ' + fos);

                    if(fos.isEmpty())
                    {
                        recordTypeId = label.SFOM_PWN_Service_Record_Type_Id;
                        FulfillmentOrder pwnFO = [select Id,GrandTotalAmount  from FulfillmentOrder where OrderSummaryId =: order.Order_Summary__c and RecordTypeId =:recordTypeId LIMIT 1];
                        refundAmount = order.Fulfillment_Order__r.GrandTotalAmount + pwnFO.GrandTotalAmount - order.Fulfillment_Order__r.Service_Fee__c;
                    }
                    else{
                        refundAmount = order.Fulfillment_Order__r.GrandTotalAmount - order.Fulfillment_Order__r.Service_Fee__c;
                    }
                }
                
                System.debug('refundAmount : ' + refundAmount);

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
                labOrderToUpdate.Refund_Amount__c=refundAmount;
                labOrderToUpdate.Cancellation_Service_Fee__c=order.Fulfillment_Order__r.Service_Fee__c;
                labOrderToUpdate.Status__c='Expired';
                labOrderToUpdate.Is_Expired__c=true;

               

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
                            labOrderToUpdate.Refund_Attempts__c=1;
                        }
                    
                    }
                    catch(Exception e)
                    {
                        labOrderToUpdate.Is_Refund_Error__c=true;
                        labOrderToUpdate.Refund_Attempts__c=1;
                        eventLog.Status__c='Error';
                        eventLog.Response_Payload__c='Failed to refund payment: ' + e.getMessage() ;
                        // output.errorMessage = 'Failed to refund payment: ' + e.getMessage();
                    }

                    System.debug('labOrderToUpdate : ' + labOrderToUpdate);

                    insert eventLog;
                }
                

                //Update Lab Order Panels

                List<Lab_Order_Panel__c> panels = [select Id from Lab_Order_Panel__c where Lab_Order__c =: order.Id];
                List<Lab_Order_Panel__c> panelsToUpdate = new List<Lab_Order_Panel__c>();
                for(Lab_Order_Panel__c panel : panels)
                {
                    Lab_Order_Panel__c panelToUpdate =  new Lab_Order_Panel__c();
                    panelToUpdate.Id=panel.Id;
                    panelToUpdate.Status__c='Expired';
                    panelsToUpdate.add(panelToUpdate);
                }

                //Update Lab Panel Tests

                List<Lab_Panel_Test__c> tests = [select Id from Lab_Panel_Test__c where Lab_Order__c =: order.Id];
                List<Lab_Panel_Test__c> testsToUpdate = new List<Lab_Panel_Test__c>();
                for(Lab_Panel_Test__c test : tests)
                {
                    Lab_Panel_Test__c testToUpdate =  new Lab_Panel_Test__c();
                    testToUpdate.Id=test.Id;
                    testToUpdate.Status__c='Expired';
                    testsToUpdate.add(testToUpdate);
                }

                System.debug('panelsToUpdate : ' + panelsToUpdate);
                System.debug('testsToUpdate : ' + testsToUpdate);
                update labOrderToUpdate;
                update panelsToUpdate;
                update testsToUpdate;
                

                //Raise Platform Event for Email
                Lab_Order_SFMC_Event__e cancelEvent = new Lab_Order_SFMC_Event__e();
                cancelEvent.Event_Type__c = System.Label.SFMC_Order_Cancel_Event;
                cancelEvent.EventDefinitionKey__c = System.Label.SFMC_Order_Expiry_Event_Definition;
                cancelEvent.Test_type__c = 'InPerson';
                cancelEvent.Lab_Order_Id__c = order.Id ;
                EventBus.publish(cancelEvent);

                //Raise Platform Event for PWN Cancel
                Lab_Order_Event__e pwnEvent = new Lab_Order_Event__e();
                pwnEvent.Action_Type__c = 'Cancel';
                pwnEvent.Event_type__c = 'PWN';
                pwnEvent.Lab_Order_Id__c = order.Id ;
                EventBus.publish(pwnEvent);

                Lab_Order_Event__e returnTaxEvent = new Lab_Order_Event__e();
                returnTaxEvent.Event_type__c = 'Return Invoice';
                returnTaxEvent.Lab_Order_Id__c = order.Id ;
                returnTaxEvent.Order_Id__c = order.Order_Summary__r.OriginalOrderId;
                returnTaxEvent.Order_Summary_Id__c = order.Order_Summary__c;
                EventBus.publish(returnTaxEvent);

            }
 }
 global void finish(Database.BatchableContext bc) {
 }
}