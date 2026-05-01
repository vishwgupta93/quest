@RestResource(urlmapping = '/order/*')
global with sharing class PartnerLabOrderResource {
    
    @httpPost
    @RestResource(urlmapping = '/create')
    global static void createOrder(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String formattedOrderUUID;
        try{
            String orderUUID = UUID.randomUUID().toString().toUpperCase();
            
            formattedOrderUUID = orderUUID.substring(0, 6) + '-' + 
                orderUUID.substring(6, 10) + '-' + 
                orderUUID.substring(10);
            system.debug(RestContext.request.requestBody.toString());
            Map<String, Object> params 	= (Map<String, Object>)System.JSON.deserializeUntyped(RestContext.request.requestBody.toString());
            
            Map<String, Object> customer = (Map<String, Object>)params.get('customer');
            Map<String, Object> address = (Map<String, Object>)params.get('address');
            Account newPersonAccount = new Account();
            String uniqueId = String.valueOf(customer.get('email'))+':'+String.valueOf(customer.get('dateOfBirth'))+':'+String.valueOf(customer.get('lastName'));
            system.debug(uniqueId);
            List<Person_Record__c> prs = new List<Person_Record__c>([Select Id, Address_Line_1__c, Address_Line_2__c, City__c, Country__c, State__c, Postal_Code__c, Phone__c,External_Customer_Id__c,app_secret__c,Record_Type__c from Person_Record__c where Unique_Identifier__c =: uniqueId]);
            Person_Record__c pr = new Person_Record__c();
            
            //14/02
            List<Account> acc =   [select id, PersonEmail  from Account where PersonEmail =: String.valueOf(customer.get('email'))];
            
            
            if(acc.isEmpty()){
                
                String Bdate = String.valueOf(customer.get('dateOfBirth')).replace('-', '/');
                
                newPersonAccount.RecordTypeId = Label.SFOM_Person_Account_RecordType_Id; 
                newPersonAccount.PersonEmail = String.valueOf(customer.get('email'));
                newPersonAccount.PersonBirthdate = Date.parse(Bdate.right(5)+'/'+Bdate.left(4));
                newPersonAccount.LastName = String.valueOf(customer.get('lastName'));
                newPersonAccount.FirstName = String.valueOf(customer.get('firstName'));
                newPersonAccount.PersonGenderIdentity=String.valueOf(customer.get('gender')) == 'm'? 'Male' :'Female';
                newPersonAccount.PersonMobilePhone=String.valueOf(customer.get('phone'));
                
                // Set the billing address
                newPersonAccount.BillingStreet = String.valueOf(address.get('addressLine1'));
                newPersonAccount.BillingCity = String.valueOf(address.get('city'));
                newPersonAccount.BillingState = String.valueOf(address.get('state'));
                newPersonAccount.BillingPostalCode = String.valueOf(address.get('zip'));
                newPersonAccount.BillingCountry = String.valueOf(address.get('country'));
                insert newPersonAccount;
                
            }
            //14/02
            
            List<Contact> con =   [select id, AccountId  from Contact where Email =: String.valueOf(customer.get('email'))];
            
            if(!prs.isEmpty()){
              
              	prs[0].Address_Line_1__c = address.containsKey('addressLine1') == true && String.valueOf(address.get('addressLine1')) != NULL ? String.valueOf(address.get('addressLine1')) : prs[0].Address_Line_1__c;
                prs[0].Address_Line_2__c = address.containsKey('addressLine2') == true && String.valueOf(address.get('addressLine2')) != NULL? String.valueOf(address.get('addressLine2')) : prs[0].Address_Line_2__c;
                prs[0].City__c 			 = address.containsKey('city') == true && String.valueOf(address.get('city')) != NULL? String.valueOf(address.get('city')) : prs[0].City__c;
                prs[0].State__c 		 = address.containsKey('state') == true && String.valueOf(address.get('state')) != NULL? String.valueOf(address.get('state')) : prs[0].State__c;
                prs[0].Country__c 		 = address.containsKey('country') == true && String.valueOf(address.get('country')) != NULL? String.valueOf(address.get('country')) : prs[0].Country__c;
                prs[0].Postal_Code__c	 = address.containsKey('zip') == true && String.valueOf(address.get('zip')) != NULL? String.valueOf(address.get('zip')) : prs[0].Postal_Code__c;
               	prs[0].app_secret__c	 = customer.containsKey('appSecret') == true && String.valueOf(customer.get('appSecret')) != NULL? String.valueOf(customer.get('appSecret')) : prs[0].app_secret__c;
                prs[0].Record_Type__c	 = customer.containsKey('recordType') == true && String.valueOf(customer.get('recordType')) != NULL? String.valueOf(customer.get('recordType')) : prs[0].Record_Type__c;
                prs[0].External_Customer_Id__c	 = customer.containsKey('externalCustomerId') == true  && String.valueOf(customer.get('externalCustomerId')) != NULL ? String.valueOf(customer.get('externalCustomerId')) : '';

                prs[0].Contact__c	 	 = con[0].id;
                update prs[0];
                pr = prs[0];
                system.debug('update --->'+prs[0].id);
            }
            else{
                String dt = String.valueOf(customer.get('dateOfBirth')).replace('-', '/');
                
                
                
                // 04/15/25 - start
                pr.First_Name__c 		= customer.containsKey('firstName') == true && String.valueOf(customer.get('firstName')) != NULL ? String.valueOf(customer.get('firstName')) : '';
                pr.Middle_Name__c       = customer.containsKey('middleName') == true && String.valueOf(customer.get('middleName')) != NULL ? String.valueOf(customer.get('middleName')) : '';
                pr.Last_Name__c       = customer.containsKey('lastName') == true && String.valueOf(customer.get('lastName')) != NULL ? String.valueOf(customer.get('lastName')) : '';
                pr.Phone__c       = customer.containsKey('phone') == true && String.valueOf(customer.get('phone')) != NULL ? String.valueOf(customer.get('phone')) : '';
                pr.Date_of_Birth__c 	=  Date.parse(dt.right(5)+'/'+dt.left(4));
                pr.Gender__c 			= String.valueOf(customer.get('gender'));
                pr.Email__c 			= String.valueOf(customer.get('email'));
                pr.Address_Line_1__c 	= address.containsKey('addressLine1') == true && String.valueOf(address.get('addressLine1')) != NULL ? String.valueOf(address.get('addressLine1')): '';
                pr.Address_Line_2__c    = address.containsKey('addressLine2') == true && String.valueOf(address.get('addressLine2')) != NULL ? String.valueOf(address.get('addressLine2')) : '';
                pr.City__c 				= address.containsKey('city') == true && String.valueOf(address.get('city')) != NULL ? String.valueOf(address.get('city')): '';
                pr.State__c 			= address.containsKey('state') == true && String.valueOf(address.get('state')) != NULL ? String.valueOf(address.get('state')): '';
                pr.Country__c 			= address.containsKey('country') == true && String.valueOf(address.get('country')) != NULL ? String.valueOf(address.get('country')): '';
                pr.Postal_Code__c 		= address.containsKey('zip') == true && String.valueOf(address.get('zip')) != NULL ? String.valueOf(address.get('zip')): '';
                pr.app_secret__c	 = customer.containsKey('appSecret') == true  && String.valueOf(customer.get('appSecret')) != NULL ? String.valueOf(customer.get('appSecret')) : '';
                pr.Record_Type__c	 = customer.containsKey('recordType') == true  && String.valueOf(customer.get('recordType')) != NULL ? String.valueOf(customer.get('recordType')) : '';
                pr.External_Customer_Id__c	 = customer.containsKey('externalCustomerId') == true  && String.valueOf(customer.get('externalCustomerId')) != NULL ? String.valueOf(customer.get('externalCustomerId')) : '';

                // 04/15/25 - end
                pr.Unique_Identifier__c = uniqueId;
                pr.Contact__c	 = con[0].id;
                insert pr;
                system.debug('Insert --->'+pr.id);
            }
            
            Map<String, Object> orderSummaries = (Map<String, Object>)params.get('orderSummaries');
            List<Object> orderItems = (List<Object>)orderSummaries.get('orderItems');
            Set<String> testCodes = new Set<String>();
            Map<String, Map<String, Object>> testCodeToDetails = new Map<String, Map<String, Object>>();

            for (Object eachItem : orderItems) {
                Map<String, Object> eachOrderItem = (Map<String, Object>) eachItem;
                
                String testCode = String.valueOf(eachOrderItem.get('testCode'));
                testCodes.add(testCode);

               
                Map<String, Object> detail = new Map<String, Object>();
                
                if (eachOrderItem.containsKey('quantity') && eachOrderItem.get('quantity') != null && String.valueOf(eachOrderItem.get('quantity')).trim() != '') {
                    detail.put('quantity', Integer.valueOf(String.valueOf(eachOrderItem.get('quantity'))));
                }

                if (eachOrderItem.containsKey('finalPrice') && eachOrderItem.get('finalPrice') != null && String.valueOf(eachOrderItem.get('finalPrice')).trim() != '') {
                    detail.put('finalPrice', Decimal.valueOf(String.valueOf(eachOrderItem.get('finalPrice'))));
                }
                testCodeToDetails.put(testCode, detail);
            }
            system.debug(testCodes);
            List<PartnerClientMap__c> pcm =  [select id,Name,Client_ID__c,Determine_Total__c from PartnerClientMap__c where Name =:String.valueOf(params.get('clientName'))];
            
            Lab_order__c lb = new Lab_Order__c();
            lb.Account__c = acc.size()>0 ? acc[0].Id : newPersonAccount.id;
            lb.Person_Record__c = pr.Id;
            lb.Is_Partner__c = true;
            lb.Partner_Client_Map__c = pcm[0].id;
            
            
            if(params.containsKey('paymentTransactionId')){
                if(!String.isBlank(params.get('paymentTransactionId').toString()))
                {
                    lb.Payment_Transaction_Id__c= params.get('paymentTransactionId').toString();
                }  
            }

            if(params.containsKey('paymentIntent')){
                if(!String.isBlank(params.get('paymentIntent').toString()))
                {
                    lb.Payment_Transaction_Id__c= params.get('paymentIntent').toString();
                }  
            }
            
            if(params.containsKey('externalOrderId')){
                if(!String.isBlank(params.get('externalOrderId').toString()))
                {
                    lb.External_partner_Order_Id__c= params.get('externalOrderId').toString();
                }
            }
            
            
            if(params.containsKey('locationId')){
                if(!String.isBlank(params.get('locationId').toString()))
                {
                    lb.PerformingSite__c= params.get('locationId').toString();
                }
            }

            if(params.containsKey('shl_key')){
                if(!String.isBlank(params.get('shl_key').toString()))
                {
                    lb.shl_encryption_key__c= params.get('shl_key').toString();
                }
            }
            
            if(params.containsKey('shl_location')){
                if(!String.isBlank(params.get('shl_location').toString()))
                {
                    lb.shl_location__c= params.get('shl_location').toString();
                }
            }

            if(params.containsKey('appointmentCode')){
                if(!String.isBlank(params.get('appointmentCode').toString()))
                {
                    lb.Appointment_Confirmation_Code__c= params.get('appointmentCode').toString();
                }
            }

            if(params.containsKey('labRefIdOverride')){
                if(!String.isBlank(params.get('labRefIdOverride').toString()))
                {
                    lb.LabRefId_Override__c= params.get('labRefIdOverride').toString();
                }
            }

            if(params.containsKey('customerIdOverride')){
                if(!String.isBlank(params.get('customerIdOverride').toString()))
                {
                    lb.Customer_ID_Override__c = params.get('customerIdOverride').toString();
                }
            }

                       
            
            
            String labOrderNumber = params.containsKey('labOrderNumber') && !String.isBlank(params.get('labOrderNumber').toString()) ? params.get('labOrderNumber').toString() : formattedOrderUUID;
            lb.Client_Name__c = params.get('clientName').toString();
            lb.Client_ID__c = pcm[0].Client_ID__c;
            lb.Name = labOrderNumber;
            lb.Status__c = 'Registered';
            
                      
            
            insert lb;
            if(!testCodes.isEmpty()){
                List<Panel_Test__c> panels = new List<Panel_Test__c>([select Id,Panel__c,Panel__r.Panel_Code__c from Panel_Test__c where Panel__r.Panel_Code__c IN: testCodes]);

                List<Product_Partner_Map__c> ppms = new List<Product_Partner_Map__c>([select Id,Product_Price__c,Product__r.ProductCode from Product_Partner_Map__c where Product__r.ProductCode IN: testCodes and Partner_ID__c =: pcm[0].id]);

                Map<String, Decimal> testCodeToDefaultPrice = new Map<String, Decimal>();
                for (Product_Partner_Map__c ppm : ppms) {
                    testCodeToDefaultPrice.put(ppm.Product__r.ProductCode, ppm.Product_Price__c);
                }

                system.debug(panels.size());
                List<Lab_Order_Panel__c> lopsToInsert = new List<Lab_Order_Panel__c>();
                boolean determineTotal = pcm[0].Determine_Total__c;
                
                for(Panel_Test__c panel: panels){
                    Lab_Order_Panel__c lop = new Lab_Order_Panel__c();
                    lop.Lab_Order__c = lb.Id;
                    lop.Panel__c = panel.Panel__c;
                    lop.Status__c = 'Registered';
                    lop.Quantity__c = 1;
                    lop.Panel_Price__c = 0.0;
                    String code = panel.Panel__r.Panel_Code__c;

                    Map<String, Object> detail = testCodeToDetails.get(code);

                    Integer defaultQuantity = 1;
                    Decimal defaultPrice = 0;
                   
                            if(determineTotal)
                            {
                                if (detail != null) {
                                    if (detail.containsKey('quantity') && detail.get('quantity') != null) {
                                        lop.Quantity__c = (Integer) detail.get('quantity');
                                    } else {
                                        lop.Quantity__c = defaultQuantity;
                                    }
                                    
                                    if (detail.containsKey('finalPrice') && detail.get('finalPrice') != null) {
                                        lop.Panel_Price__c = (Decimal) detail.get('finalPrice');
                                    } else if (testCodeToDefaultPrice.containsKey(code)) {
                                        lop.Panel_Price__c = testCodeToDefaultPrice.get(code);
                                    } else {
                                        lop.Panel_Price__c = defaultPrice;
                                    }
                                } else {
                                    lop.Quantity__c = defaultQuantity;
                                    
                                }
                            }
                            else
                            {
                                if (testCodeToDefaultPrice.containsKey(code)) {
                                        lop.Panel_Price__c = testCodeToDefaultPrice.get(code);
                                } else {
                                        lop.Panel_Price__c = defaultPrice;
                                }
                            }
                                                
                    lopsToInsert.add(lop);
                }
                
                insert lopsToInsert;
                
                Map<Id, Lab_Order_Panel__c> lop_Panel_Map = new Map<Id, Lab_Order_Panel__c>();
                
                for(Lab_Order_Panel__c eachLOP : lopsToInsert){
                    lop_Panel_Map.put(eachLOP.Panel__c, eachLOP);
                }
                
                List<Lab_Panel_Test__c> lptToInsert = new List<Lab_Panel_Test__c>();
                
                for(Panel_Test__c eachPanelTest : panels){
                    Lab_Panel_Test__c lopt = new Lab_Panel_Test__c();
                    lopt.Lab_Order__c = lb.Id;
                    lopt.Status__c = 'Registered';
                    lopt.Lab_Order_Panel__c = lop_Panel_Map.get(eachPanelTest.Panel__c).Id;
                    lopt.Panel_Test__c = eachPanelTest.id;
                    lptToInsert.add(lopt);
                }
                
                system.debug(lptToInsert);
                system.debug(lptToInsert.size());
                insert lptToInsert;
                
                res.statusCode = 200;
                Lab_order__c labOrder =    [select id,LabRefId__c,Person_Record__c from Lab_order__c where id =: lb.id Limit 1];
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeStringField('labOrderNumber', labOrderNumber);
                gen.writeStringField('recordId', labOrder.id);
                gen.writeStringField('personId', labOrder.Person_Record__c);

                gen.writeEndObject();
                res.responseBody = Blob.valueOf(gen.getAsString());
                
            }
        }
        catch(Exception e){
            System.debug(e);
            res.statusCode = 400;
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('error', 'Error: Bad request ' + e.getMessage());
            gen.writeEndObject();
            res.responseBody = Blob.valueOf(gen.getAsString());
        }
    }
    
    
    @HttpPatch
    global static void cancelOrder(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        Map<String, Object> params 	= (Map<String, Object>)System.JSON.deserializeUntyped(RestContext.request.requestBody.toString());
        String cancelReasonValue = (String)params.get('cancelReason');
        String labOrderId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        try{
            List<Lab_Order_Panel__c> panels = [select Id, Panel__r.Product__c,Lab_Order__r.Partner_Client_Map__c,Lab_Order__r.Partner_Client_Map__r.Name,Lab_Order__r.Partner_Client_Map__r.Payment_Key__c,Lab_Order__r.Id,Lab_Order__r.Payment_Transaction_Id__c,Lab_Order__r.Status__c from Lab_Order_Panel__c where Lab_Order_Panel__c.Lab_Order__r.Name =: labOrderId];
            System.debug('Lab Order ID: ' + labOrderId + ' : cancelReasonValue:  ' + cancelReasonValue + ' :panels: ' + panels);
            if(!panels.isEmpty())
            {
                String loStatus = panels[0].Lab_Order__r.Status__c;
                String paymentTransactionId = panels[0].Lab_Order__r.Payment_Transaction_Id__c;
                String recordId = panels [0].Lab_Order__r.Id;
                String partnerId = panels [0].Lab_Order__r.Partner_Client_Map__c;
                String paymentKey = panels [0].Lab_Order__r.Partner_Client_Map__r.Payment_Key__c;
                String clientName = panels [0].Lab_Order__r.Partner_Client_Map__r.Name;

                Set<String> productIds = new Set<String>();

                double totalPrice = 0.0;
                double cancellationFee = 0.0;


                for(Lab_Order_Panel__c panel : panels)
                {
                    productIds.add(panel.Panel__r.Product__c);
                }

                for(Product_Partner_Map__c ppm : [Select id,Product__c,Product_Price__c,Cancellation_Fee__c from Product_Partner_Map__c where Product__c in:productIds and Partner_ID__c =:partnerId])
                {
                    System.debug('Product_Partner_Map__c: ' + ppm );
                    if(ppm.Product_Price__c != null)
                    {
                        totalPrice += ppm.Product_Price__c;
                    }
                    if(ppm.Cancellation_Fee__c > cancellationFee)
                    {
                        cancellationFee = ppm.Cancellation_Fee__c;
                    }
                }

                System.debug('totalPrice: ' +  totalPrice + ' :cancellationFee : ' +  cancellationFee + ' : paymentKey : ' + paymentKey);
                
                if(loStatus == 'Registered' || loStatus == 'PA Acknowledged' || loStatus == 'PA Approved'|| Test.isRunningTest() ){
                    Partner_Cancel_Reasons__mdt record = [SELECT Partner_Cancel_Reason__c, CIT_Cancel_Reason__c
                            FROM Partner_Cancel_Reasons__mdt
                            WHERE  Partner_Cancel_Reason__c = :cancelReasonValue limit 1];
                   
                    Lab_Order__c lb = new Lab_Order__c();
                    lb.id = recordId;
                    lb.Status__c = 'Cancelled';
                    lb.Cancel_Reason__c = record.CIT_Cancel_Reason__c;
                   
                    PartnerLabOrderRefund.Request request = new PartnerLabOrderRefund.Request();

                    request.labOrderId=recordId;
                    request.fullRefund=false;
                    request.cancellationFee=cancellationFee;
                    request.paymentKey=paymentKey;
                    request.paymentIntentId=paymentTransactionId;
                    // Rakhee's update for sending the payload request for refund
if(request.paymentIntentId != null || Test.isRunningTest()){
                    List<PartnerLabOrderRefund.Request> requests= new List<PartnerLabOrderRefund.Request>();
                    requests.add(request);
                    
                    PartnerLabOrderRefund.Response response = PartnerLabOrderRefund.refundPartnerOrder(requests).get(0);
                    
                    lb.Captured_Amount__c=response.amountCaptured;
                    lb.Cancellation_Service_Fee__c=cancellationFee;
                    lb.Refund_Amount__c=response.amountRefunded;
                    lb.Full_Refund__c = response.amountCaptured == response.amountRefunded ? true : false;

                    if(response.status == 'Success')
                    {
                        res.statusCode = 200;
                        JSONGenerator gen = JSON.createGenerator(true);
                        gen.writeStartObject();
                        gen.writeStringField('labOrderNumber', labOrderId);
                        gen.writeStringField('status', lb.Status__c);
                        gen.writeBooleanField('refundStatus', true);

                        gen.writeEndObject();
                        res.responseBody = Blob.valueOf(gen.getAsString());
                    }
                    else 
                    {
                        System.debug('Error: ' +  ' Lab Order cannot be Cancelled ');

                        lb.Is_Refund_Error__c=true;
                        lb.Refund_Attempts__c=1;

                        res.statusCode = lb.Status__c == 'Cancelled'? 200 : 500;
                        String message = lb.Status__c == 'Cancelled'?  ' Error in Refund ' : ' Lab Order cannot be Cancelled ';
                        String errorMessage = 'Error::: ' +labOrderId + message;
                        JSONGenerator gen = JSON.createGenerator(true);
                        gen.writeStartObject();
                        gen.writeStringField('labOrderNumber', labOrderId);
                        gen.writeStringField('status', lb.Status__c);
                        gen.writeBooleanField('refundStatus', false);
                        gen.writeStringField('error', errorMessage);
                        gen.writeEndObject();
                        res.responseBody = Blob.valueOf(gen.getAsString());
                    }

                    Event_Log__c eventLog = new Event_Log__c();
                    eventLog.Lab_Order__c =lb.Id;                                
                    eventLog.Event_Type__c ='Payment Refund';
                    eventLog.Status__c=response.status;
                    eventLog.Payload__c=response.requestPayload;
                    eventLog.Response_Payload__c=response.responsePayload; 

                    insert eventLog;
                }
                    update lb;
                    
                
                } 
                else
                {
                    System.debug('Error: ' +  ' Lab Order cannot be Cancelled due to invalid status');

                    res.statusCode = 500;
                    JSONGenerator gen = JSON.createGenerator(true);
                    gen.writeStartObject();
                    gen.writeStringField('labOrderNumber', labOrderId);
                    gen.writeStringField('status', loStatus);
                    gen.writeBooleanField('refundStatus', false);
                    gen.writeStringField('error', 'Error: Bad request:: ' +labOrderId+ ' Lab Order cannot be Cancelled due to invalid status');
                    gen.writeEndObject();
                    res.responseBody = Blob.valueOf(gen.getAsString());
                } 
        }
        else
            {
                System.debug('Error: ' +  ' Lab Order cannot be Cancelled ');

                res.statusCode = 500;
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeStringField('labOrderNumber', labOrderId);
                gen.writeStringField('status', '');
                gen.writeBooleanField('refundStatus', false);
                gen.writeStringField('error', 'Error: Bad request:: ' +labOrderId+ ' Invalid Lab Order Number ');
                gen.writeEndObject();
                res.responseBody = Blob.valueOf(gen.getAsString());
            } 
                
        }
        catch(Exception e)
        {
            System.debug('Error: ' +  e.getStackTraceString() + ' : ' + e.getMessage()  + ' : ' +  e.getCause());

            res.statusCode = 500;
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('error', 'Error: Bad request ' + e.getMessage());
            gen.writeEndObject();
            res.responseBody = Blob.valueOf(gen.getAsString());
        }
        
    }
    
}