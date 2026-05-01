/**
* @File Name : FetchPWNHealthDetails.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : March 13, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 13, 2025 |   | Initial Version
**/

public class FetchPWNHealthDetails {
    
    public class InputPrameters {
        @InvocableVariable(label='Ping Fed Token' description='Ping Fed Token')
        public String token;
        
        @InvocableVariable(label='Lab Order RecordId' description='Lab Order RecordId')
        public String labOrderRecordId;
        
        
    }
    
    public class OutParameters {
        @InvocableVariable(label='Response Message' description='Response Message from PRS Service')
        public String responseMessage;
        
        @InvocableVariable(label='Response Code' description='Response Code from PRS Service')
        public String responseCode;
        
        @InvocableVariable(label='Request Payload' description='Request Payload')
        public String requestPayload;
        
        @InvocableVariable(label='Response Payload' description='Response Payload')
        public String responsePayload;
        
        @InvocableVariable(label='Status' description='Status')
        public String status; 
    }
    @InvocableMethod(label='Submit Approved orders To GPP' description='Submit Approved orders To GPP')
    public static List<OutParameters> fetchData(List<InputPrameters> inputs){
        OutParameters op = new OutParameters();
        List<OutParameters> lstOp = new List<OutParameters>();
        
        List<Lab_Order__c>  lstLabOrder =  [select id, PWN_ID__c,  Kit_Detail__r.Activation_Code__c from Lab_Order__c where id =:inputs[0].labOrderRecordId];
        
        
        String key = Label.GSS_PWN_API_Key;
        String secret = Label.GSS_PWN_API_Secret;
        String token = PWNTokenGeneration.generateToken(key,secret);    
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(Label.PWN_ORDER_STATUS_URL+lstLabOrder[0].PWN_ID__c);
        
        request.setHeader('accept', 'application/json');
        request.setHeader('content-type', 'application/json');
        request.setHeader('Authorization','Bearer ' + token);
        
        
        HttpResponse response = http.send(request);
        System.Debug('response:::' +response.getBody());
        if (response.getStatusCode() == 200) {
            
            Integer statusCode;
            try{
                Http http1 = new Http();
                HttpRequest request1 = new HttpRequest();
                HttpResponse response1;
                
                Map<String, Object> jsonResponseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                Map<String, Object> orderMap =   (Map<String, Object>)jsonResponseMap.get('order');
                Integer orderId =  (Integer)orderMap.get('id');
                String orderStatus =  (String)orderMap.get('status');
                String createdAt =  (String)orderMap.get('created_at');
                String updatedAt =  (String)orderMap.get('updated_at');
                String expiresAt =  (String)orderMap.get('expires_at');
                
                Map<String, Object> geneticReviewMap = (Map<String, Object>)orderMap.get('genetic_review');
                String reviewedAt =  (String)geneticReviewMap.get('reviewed_at');
                String reviewerName =  (String)geneticReviewMap.get('reviewer_name');
                List<Object> increasedRisk =  (List<Object>)geneticReviewMap.get('increased_risk');
                Boolean requiresResultsDeliverySession =  (Boolean)geneticReviewMap.get('requires_results_delivery_session');
                Map<String, Object> diseaseStatesReviewMap =   (Map<String, Object>)geneticReviewMap.get('disease_states_review');
                List<Object> diseasestatesLst =  (List<Object>)diseaseStatesReviewMap.get('disease_states');
                
                
                
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeNumberField('orderId',orderId);
                gen.writeStringField('orderStatus',orderStatus);
                gen.writeStringField('createdAt',createdAt);
                gen.writeStringField('updatedAt',updatedAt);
                gen.writeStringField('expiresAt',expiresAt);
                gen.writeFieldName('geneticReview');
                gen.writeStartObject();
                gen.writeStringField('reviewed_at',reviewedAt);
                gen.writeStringField('reviewer_name',reviewerName);
                gen.writeObjectField('increased_risk',increasedRisk);
                gen.writeBooleanField('requires_results_delivery_session',requiresResultsDeliverySession);
                gen.writeFieldName('disease_states_review');
                gen.writeStartObject();
                gen.writeFieldName('disease_states');
                
                gen.writeStartArray();
                for(Object eachDiseaseState : diseasestatesLst){
                    Map<String, Object> eachDisease = (Map<String, Object>) eachDiseaseState;
                    gen.writeStartObject();
                    gen.writeStringField('name',(String)eachDisease.get('name'));
                    gen.writeObjectField('message_categories',eachDisease.get('message_categories'));
                    gen.writeEndObject();
                }
                gen.writeEndArray();
                
                gen.writeEndObject();
                gen.writeEndObject();
                gen.writeEndObject(); 
                
                String requestBody = gen.getAsString();
                String endpoint = Label.OMS_Mule_Proxy_Ednpoint +'qdx-genetics-portal-proxy-api/pwn-order?kitId='+lstLabOrder[0].Kit_Detail__r.Activation_Code__c;
                
                request1.setMethod('PUT');
                request1.setEndpoint(endpoint);
                request1.setHeader('content-type', 'application/json');
                request1.setHeader('Authorization','Bearer ' + inputs[0].token);
                request1.setBody(requestBody);
                response1 = http1.send(request1);
                statusCode = response1.getStatusCode();    
                Map<String, Object> jsonResponseMap1 = (Map<String, Object>)JSON.deserializeUntyped(response1.getBody());
                System.debug(response1);
                if (response1.getStatusCode() == 200) {
                    op.responseCode=String.valueOf(response1.getStatusCode());
                    op.Status = 'Success';
                    op.requestPayload = requestBody;
                    op.responsePayload  = response1.getBody();
                    op.responseMessage  =  'Success';
                    
                }
                else if(statusCode==504){
                    op.responseCode=String.valueOf(statusCode);
                    op.responseMessage='Timeout';
                    op.Status='Timeout Error';
                }
                else {
                    String errorMessage=''; 
                    op.responseCode=String.valueOf(response1.getStatusCode());
                    op.Status='Error';
                    op.responsePayload  = response1.getBody();
                    op.requestPayload = requestBody;
                    op.responseMessage='Error';
                    
                }}catch(Exception e){
                    if(response != null)
                    {
                        op.responseCode=String.valueOf(statusCode);
                        op.responseMessage=response.getStatus() + ' Message: ' + response.getBody();
                        op.responsePayload = response.getBody();
                    }
                    else {
                        op.responseMessage=e.getMessage();
                        op.responsePayload = e.getMessage();
                        op.responseCode='504';
                    }
                    op.Status='Error';
                    
                }
            
        } else {
            
            String errorMessage=''; 
            op.responseCode=String.valueOf(response.getStatusCode());
            op.responseMessage='Error';
            op.responsePayload  = response.getBody();
            op.requestPayload = Label.PWN_ORDER_STATUS_URL+lstLabOrder[0].PWN_ID__c;
            op.Status='Error';
        }
        lstOp.add(op);
        return lstOp;
    }
}