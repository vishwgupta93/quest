public class HRAEmailAPI {
    @future (callout=true)
    public static void captureOrderDetails(String laborderId,  String eventType, String eventDefinitionKey){
        Integer statusCode;
        List<Lab_Order_Panel__c> lstLOP = new List<Lab_Order_Panel__c>();
        List<OrderItemSummary> lstOIS = new  List<OrderItemSummary>();
        System.debug('HRAEMAIL');
        if(laborderId.startsWith('1Os')){ 
             System.debug('In OS');
            lstOIS = [SELECT Id, 
                      ProductCode, 
                      OrderSummaryId,
                      OrderSummary.Account.PersonEmail,
                      OrderSummary.AccountId FROM OrderItemSummary WHERE OrderSummaryId  =: laborderId AND HRAReq__c  = true];
            
            
        } else {
            System.debug('In Laborder');
            lstLOP = [Select Id,
                      Lab_Order__r.id,
                      Lab_Order__r.Person_Record__r.Contact__r.AccountId,
                      Lab_Order__r.Person_Record__r.Email__c,
                      Panel_Code__c, 
                      HRA_Req__c 
                      from Lab_Order_Panel__c where Lab_Order__r.id  =:laborderId AND HRA_Req__c = true];
        }
        
        
        
        
        DateTime currentTime = System.now();
        String eventTime = currentTime.format('yyyy-MM-dd HH:mm:ss');
        if(!lstLOP.isEmpty() || !lstOIS.isEmpty()){
            
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            if(laborderId.startsWith('1Os')){
            gen.writeStringField('ContactKey',lstOIS[0].OrderSummary.AccountId);
            }else {
            gen.writeStringField('ContactKey',lstLOP[0].Lab_Order__r.Person_Record__r.Contact__r.AccountId);
            }
            
            
            //gen.writeStringField('ContactKey',String.valueOf(currentTime.getTime()));
            gen.writeStringField('EventDefinitionKey',eventDefinitionKey);
            gen.writeFieldName('Data');
            gen.writeStartObject();
            
            if(laborderId.startsWith('1Os')){
                gen.writeStringField('customer_id',  lstOIS[0].OrderSummary.AccountId);
                gen.writeStringField('email_address',lstOIS[0].OrderSummary.Account.PersonEmail);
                gen.writeStringField('test_id',lstOIS[0].ProductCode);
                
            } else {
                //gen.writeStringField('customer_id',  lstLOP[0].Lab_Order__r.Person_Record__r.id);
                gen.writeStringField('customer_id',  lstLOP[0].Lab_Order__r.Person_Record__r.Contact__r.AccountId);
                system.debug(lstLOP[0].Lab_Order__r.Person_Record__r.Contact__r.AccountId);
                gen.writeStringField('email_address',lstLOP[0].Lab_Order__r.Person_Record__r.Email__c);
                gen.writeStringField('test_id',lstLOP[0].Panel_Code__c);
            }
            
            gen.writeBooleanField('hra_eligibility_status',true);
            gen.writeStringField('hra_url',System.label.HRAEmailURL+laborderId);
            gen.writeDateTimeField('event_date',System.Now());
            gen.writeEndObject();
            gen.writeEndObject();
            String jsonStr = gen.getAsString();
            
            String httpBody = jsonStr;
            //String endpoint = Label.SFMC_Rest_Endpoint + '/interaction/v1/events';
            //List<SFMC_OMS_Config__c> configs = [select Id, Auth_Token__c from SFMC_OMS_Config__c  where Channel__c = 'QD-CIT' and API__C = 'Common'];
            //String token;
            String endpoint ='';
            if(!Test.isRunningTest()){
                //token = configs[0].Auth_Token__c; 
               endpoint = 'callout:SFMC_Endpoint/interaction/v1/events';  
            }
            
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type','application/json');
            //request.setHeader('Authorization','Bearer ' + token);
            request.setBody(httpBody);
            System.debug('Request::'+request);
            System.debug(httpBody);
            
            try{
                HttpResponse response = http.send(request); 
                statusCode = response.getStatusCode(); 
                
                System.debug(statusCode ); 
                
                Event_Log__c eventLog = new Event_Log__c();
                if(laborderId.startsWith('1Os')){
                     eventLog.Order_Summary__c =laborderId;
                } else {
                     eventLog.Lab_Order__c =laborderId;
                }
               
                eventLog.Event_Type__c =eventType;
                eventLog.Payload__c=httpBody;    
                
                
                if(statusCode==201){
                    System.debug('Success : ' + response.getBody()); 
                    eventLog.Status__c='Success';
                    eventLog.Response_Payload__c=response.getBody();
                }
                else{
                    System.debug('Error : ' + response.getBody());
                    eventLog.Status__c='Error'; 
                    eventLog.Response_Payload__c=response.getBody();
                }
                insert eventLog;
            }
            catch(Exception e){
                System.debug('Failed to create Transaction' + e.getMessage());
            }
            
        } else{
            statusCode = 500;
        }
        
    }
}