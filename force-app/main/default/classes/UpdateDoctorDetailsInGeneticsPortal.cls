/**
* @File Name : UpdateDoctorDetailsInGeneticsPortal.cls
* @Description :
* @Author : SingamReddy Ramanareddy
* @Last Modified By :
* @Last Modified On : March 13, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 13, 2025 |   | Initial Version
**/

public class UpdateDoctorDetailsInGeneticsPortal {
    
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
    
    @InvocableMethod(label='Send Doctor Details' description='Send Doctor Details')
    public static List<OutParameters> sendDoctorDetails(List<InputPrameters> inputs){
        
        List<Lab_Order__c>  lstLabOrder =  [select id, PWN_ID__c,Physician_First_Name__c, Physician_Last_Name__c, 
                                            Physician_Upin__c, Physician_Npi__c, Kit_Detail__r.Activation_Code__c,
                                            CreatedAt__c, UpdatedAt__c, ExpiresAt__c
                                            from Lab_Order__c where id =:inputs[0].labOrderRecordId];
        
        OutParameters op = new OutParameters();
        List<OutParameters> lstOp = new List<OutParameters>();
        String Name= lstLabOrder[0].Physician_First_Name__c+' '+lstLabOrder[0].Physician_Last_Name__c;
        HttpResponse response;
        Integer statusCode;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        for( InputPrameters eachInput : inputs){
            try{
                
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeStringField('orderId',lstLabOrder[0].PWN_ID__c);
                gen.writeStringField('orderStatus',System.label.Genetics_Portal_Proxy_Order_Status);
                gen.writeStringField('createdAt',lstLabOrder[0].CreatedAt__c);
                gen.writeStringField('updatedAt',lstLabOrder[0].UpdatedAt__c);
                gen.writeStringField('expiresAt',lstLabOrder[0].ExpiresAt__c);
                gen.writeFieldName('physicianReview');
                gen.writeStartObject();
                gen.writeStringField('name',Name);
                gen.writeStringField('first_name',lstLabOrder[0].Physician_First_Name__c);
                gen.writeStringField('last_name',lstLabOrder[0].Physician_Last_Name__c);
                gen.writeStringField('upin',lstLabOrder[0].Physician_Upin__c != null ? lstLabOrder[0].Physician_Upin__c : '');
                gen.writeStringField('npi',lstLabOrder[0].Physician_Npi__c);
                gen.writeEndObject();
                gen.writeEndObject();
                String requestBody = gen.getAsString();
                system.debug(gen.getAsString()); 
                String endpoint = Label.OMS_Mule_Proxy_Ednpoint +'qdx-genetics-portal-proxy-api/pwn-order?kitId='+lstLabOrder[0].Kit_Detail__r.Activation_Code__c;
                
                
                request.setMethod('PUT');
                request.setEndpoint(endpoint);
                request.setHeader('content-type', 'application/json');
                request.setHeader('Authorization','Bearer ' + eachInput.token);
                request.setBody(requestBody);
                response = http.send(request);
                Map<String, Object> jsonResponseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                System.debug(response);
                if (response.getStatusCode() == 200) {
                    
                    op.responseCode=String.valueOf(response.getStatusCode());
                    op.Status = 'Success';
                    op.requestPayload = requestBody;
                    op.responsePayload  = response.getBody();
                    op.responseMessage  = 'Success';
                    
                }else if(statusCode==504){
                    op.responseCode=String.valueOf(statusCode);
                    op.responseMessage='Timeout';
                    op.Status='Timeout Error';
                }
                else {
                    String errorMessage=''; 
                    op.responseCode=String.valueOf(response.getStatusCode());
                    op.responseMessage='Error';
                    op.responsePayload  = response.getBody();
                    op.requestPayload = requestBody;
                    op.Status='Error';
                }
            }catch(Exception e){
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
            lstOp.add(op);
        }
        return lstOp;
    }
}