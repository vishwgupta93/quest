public class SendOrderDetailsToPackHealth {
    
    public class FulfillmentOrderIdInput {
        @InvocableVariable(label='FulfillmentOrderId' description='FulfillmentOrderId')
        public String ID;
        
    }
    
    
    public class Results {
        
        @InvocableVariable
        public List<ResponseOutputPackHealth> outputCollection; 
        
    }
    
    @InvocableMethod(label='PackHealth ' description='Packhealth via API')
    public static List<Results> captureOrderDetails(List<FulfillmentOrderIdInput> FOId){
        List<Results> lstResults = new List<Results>();
        Results Results = new Results();
        List<ResponseOutputPackHealth>  lstresponseoutput=New List<ResponseOutputPackHealth>();
       
        system.debug(FOId[0].ID);
        
        String se = '(732) 679-5555';
        
        List<FulfillmentOrderLineItem> lstFOLI = [Select id,
                                                  FulfillmentOrder.Account.FirstName,
                                                  FulfillmentOrder.Account.LastName,
                                                  FulfillmentOrder.Account.PersonEmail,
                                                  FulfillmentOrder.Account.Phone,
                                                  FulfillmentOrder.Account.BillingStreet,
                                                  FulfillmentOrder.Account.BillingCity,
                                                  FulfillmentOrder.Account.BillingState,
                                                  FulfillmentOrder.Account.BillingCountry,
                                                  FulfillmentOrder.Account.BillingPostalCode,
                                                  FulfillmentOrder.OrderSummary.BillingCity,
                                                  FulfillmentOrder.OrderSummary.BillingEmailAddress,
                                                  FulfillmentOrder.OrderSummary.BillingCountry,
                                                  FulfillmentOrder.OrderSummary.BillingState,
                                                  FulfillmentOrder.OrderSummary.BillingStreet,
                                                  FulfillmentOrder.OrderSummary.BillingPhoneNumber,
                                                  FulfillmentOrder.OrderSummary.BillingPostalCode,
                                                  Status__c,
                                                  OrderItemSummary.ProductCode,
                                                  FulfillmentOrder.OrderSummaryId,
                                                  FulfillmentOrderId,
                                                  Is_successful__c
                                                  from FulfillmentOrderLineItem where FulfillmentOrderId  =: FOId[0].ID AND Test_Type__c = 'PackHealth' AND Is_successful__c  = false];
        
        for(FulfillmentOrderLineItem eachFOLI : lstFOLI){
             ResponseOutputPackHealth responseoutput = new ResponseOutputPackHealth();
            JSONGenerator gen = JSON.createGenerator(true);
            
            gen.writeStartObject();
            gen.writeFieldName('enrollment');
            gen.writeStartObject();
            gen.writeStringField('affiliateCode', eachFOLI.OrderItemSummary.ProductCode == 'packhealth4' ? 'CITFOUR' : 'CITSIX');
            gen.writeStringField('firstName', eachFOLI.FulfillmentOrder.Account.FirstName != null ? eachFOLI.FulfillmentOrder.Account.FirstName : '');
            gen.writeStringField('lastName', eachFOLI.FulfillmentOrder.Account.LastName != null ? eachFOLI.FulfillmentOrder.Account.LastName : '');
            gen.writeStringField('email', eachFOLI.FulfillmentOrder.Account.PersonEmail != null ? eachFOLI.FulfillmentOrder.Account.PersonEmail : eachFOLI.FulfillmentOrder.OrderSummary.BillingEmailAddress);
            gen.writeStringField('phoneNumber', eachFOLI.FulfillmentOrder.Account.Phone != null ? eachFOLI.FulfillmentOrder.Account.Phone.replaceAll('[^0-9.]','') : eachFOLI.FulfillmentOrder.OrderSummary.BillingPhoneNumber.replaceAll('[^0-9.]','') );
          // gen.writeStringField('phoneNumber', eachFOLI.FulfillmentOrder.Account.Phone != null ? se : se.replaceAll('[^0-9.]',''));
            gen.writeStringField('programCode', 'GEN');
            gen.writeFieldName('mailingAddress');
            gen.writeStartObject();
            gen.writeStringField('street', eachFOLI.FulfillmentOrder.Account.BillingStreet != null ? eachFOLI.FulfillmentOrder.Account.BillingStreet : eachFOLI.FulfillmentOrder.OrderSummary.BillingStreet);
            gen.writeStringField('city', eachFOLI.FulfillmentOrder.Account.BillingCity != null ? eachFOLI.FulfillmentOrder.Account.BillingCity : eachFOLI.FulfillmentOrder.OrderSummary.BillingCity);
            gen.writeStringField('stateCode', eachFOLI.FulfillmentOrder.Account.BillingState != null ? eachFOLI.FulfillmentOrder.Account.BillingState : eachFOLI.FulfillmentOrder.OrderSummary.BillingState);
            gen.writeStringField('zipCode',  eachFOLI.FulfillmentOrder.Account.BillingPostalCode != null ? eachFOLI.FulfillmentOrder.Account.BillingPostalCode.replaceAll('[^0-9.]','') : eachFOLI.FulfillmentOrder.OrderSummary.BillingPostalCode.replaceAll('[^0-9.]',''));
            
            
            gen.writeEndObject();
            gen.writeEndObject();
            gen.writeEndObject();
            String payLoad = gen.getAsString();
            
            System.debug(gen);
            System.debug(payLoad);
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.label.packHealthAPIEndPoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('x-api-caller',System.label.packHealthAPICaller);
            request.setHeader('x-api-key',System.label.packHealthAPIKey);
            
            
            
            request.setBody(payLoad);
            Http http = new Http();
            HttpResponse response = http.send(request);
            System.Debug('response:::' +response.getBody());
            Map<String, Object> jsonResponseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
           
            if (response.getStatusCode() == 200) {
                //Map<String, Object> jsonResponseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                responseoutput.StatusCode=String.valueOf(response.getStatusCode());
                responseoutput.Status = 'Success';
                responseoutput.requestPayload = payLoad;
                  responseoutput.responsePayload  = response.getBody();
                responseoutput.OrderSummaryId =eachFOLI.FulfillmentOrder.OrderSummaryId;
                responseoutput.FulfillmentOrderLineItemID = eachFOLI.Id;
                responseoutput.FulfillmentOrderId = eachFOLI.FulfillmentOrderId;
                
                
                
            }else if(response.getStatusCode() == 400){
                String s ='' ;
                List<String> lststring = new List<String>();
                 if(jsonResponseMap.containsKey('detail')){
                Object responseDetil =  (Object)jsonResponseMap.get('detail');
                String detail = (String)responseDetil;
                system.debug(detail);
                
                 String delimiter = '),';
                detail.substringBefore(delimiter);
                List<String> lstStr = new List<String>();
                lstString.add(detail.substringBefore(delimiter));
                lstString.add(detail.substringAfter(delimiter));
                     system.debug(detail.substringBefore(delimiter));
                     system.debug(detail.substringAfter(delimiter));
                     
                for(String eachstr : lstString){
                    Pattern p = Pattern.compile('\"([^\"]*)\"');
                    Matcher m = p.matcher(eachstr);
                    if (m.find()){
                      
                        if(m.group(1) == eachFOLI.FulfillmentOrder.Account.FirstName  ){
                             s += '  First name should have atleast 2 charaters.';
                        } 
                        if(m.group(1) == eachFOLI.FulfillmentOrder.Account.LastName){
                            s += '  Last name should have atleast 2 charaters.';
                        } 
                        
                    }
                }
                     
                    
                
            }
                
                responseoutput.StatusCode=String.valueOf(response.getStatusCode());
                responseoutput.Status = 'Data_Error';
                responseoutput.requestPayload = payLoad;
                 responseoutput.errorMessage = s;
                 responseoutput.responsePayload =response.getBody();
                responseoutput.OrderSummaryId = eachFOLI.FulfillmentOrder.OrderSummaryId;
                responseoutput.FulfillmentOrderLineItemID = eachFOLI.Id;
                responseoutput.FulfillmentOrderId = eachFOLI.FulfillmentOrderId;
                
            }  else{
                
                responseoutput.StatusCode=String.valueOf(response.getStatusCode());
                responseoutput.Status = 'Tech_Error';
                responseoutput.requestPayload = payLoad;
                responseoutput.errorMessage= '500 Internal Server Error';
                responseoutput.responsePayload  = response.getBody();
                responseoutput.OrderSummaryId = eachFOLI.FulfillmentOrder.OrderSummaryId;
                responseoutput.FulfillmentOrderLineItemID = eachFOLI.Id;
                responseoutput.FulfillmentOrderId = eachFOLI.FulfillmentOrderId;
                
            }
           lstresponseoutput.add(responseoutput);  
        }
        Results.outputCollection = lstresponseoutput;
        lstResults.add(Results);
        System.debug(lstResults);
        return lstResults;
    }
}