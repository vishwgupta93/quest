public  class PRSProxyHelper {
    public class InputPrameters {
        @InvocableVariable(label='Ping Fed Token' description='Ping Fed Token')
        public String token;
        @InvocableVariable(label='ActivationUser PRS ID' description='ActivationUser PRS ID')
        public String ActivationUserPRSID; 
        @InvocableVariable(label='Kit Lab id' description='Kit Lab Id')
        public String kitLabId; 
    }
    
    public class OutParameters {
        
        @InvocableVariable(label='Response Message' description='Response Message from PWN Service')
        public String responseMessage;
        @InvocableVariable(label='Response Code' description='Response Code from PWN Service')
        public String responseCode;
        @InvocableVariable(label='Request Payload' description='Request Payload')
        public String requestPayload;
        @InvocableVariable(label='Response Payload' description='Response Payload')
        public String responsePayload;
        @InvocableVariable(label='Kit Order Id' description='Kit Order Id')
        public String kitOrderId;
        @InvocableVariable(label='Status' description='Status')
        public String status; 
        
        @InvocableVariable(label=' First Name' description=' First Name')
        public String firstName;
        @InvocableVariable(label=' Last Name' description=' Last Name')
        public String lastName;
        @InvocableVariable(label='DOB' description='DOB')
        public String DOB;
        @InvocableVariable(label='gender' description='gender')
        public String gender;
        @InvocableVariable(label='addressLine1' description='addressLine1')
        public String addressLine1;
        @InvocableVariable(label='addressLine2' description='addressLine2')
        public String addressLine2;
        @InvocableVariable(label='city' description='city')
        public String city;
        @InvocableVariable(label='stateProvince' description='stateProvince')
        public String stateProvince;
        @InvocableVariable(label='country' description='country')
        public String country;
        @InvocableVariable(label='zipPostal' description='zipPostal')
        public String zipPostal;
        @InvocableVariable(label='empiPatientId' description='empiPatientId')
        public String empiPatientId;
        @InvocableVariable(label='kitActivationCode' description='kitActivationCode')
        public String kitActivationCode;
        @InvocableVariable(label='ActivationUserPRSID' description='ActivationUserPRSID')
        public String ActivationUserPRS;
        @InvocableVariable(label='phone' description='phone')
        public String phone;
        
    }
    
    @InvocableMethod(label='Fetch PRS Details ' description='Fetch PRS Details')
    public static List<OutParameters> fetchPRSDetails(List<InputPrameters> inputs){
        List<OutParameters> output = new List<OutParameters>();
        OutParameters op= new OutParameters(); 
        
        for(InputPrameters serviceInput : inputs)
        {
            
            String token = serviceInput.token;
            Integer statusCode;
            Http http = new Http();
            HttpResponse response;
            HttpRequest request = new HttpRequest();
            
            try{
                
                Kit_Details__c kitDetail = [select id, ActivationUser_PRS_ID__c,Activation_Code__c  from Kit_Details__c where Id =: serviceInput.kitLabId];
                
                String endpoint = Label.OMS_Mule_Proxy_Ednpoint;
                endpoint = endpoint + 'qdx-prs-proxy-api/patients/'+kitDetail.ActivationUser_PRS_ID__c;                        
                request.setEndpoint(endpoint);
                request.setMethod('GET');
                request.setHeader('Content-Type','application/json');
                request.setHeader('Authorization','Bearer ' + token);
                response = http.send(request); 
                
                statusCode = response.getStatusCode();
                op.requestPayload = endpoint;
                op.responsePayload = response.getBody();
                op.responseCode  = String.valueOf(statusCode); 
                Map<String, Object> jsonResponseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                
                if(statusCode==200){
                    Map<String, Object> patientId = (Map<String, Object>)jsonResponseMap.get('patientId');
                    Map<String, Object> patientProfile = (Map<String, Object>)jsonResponseMap.get('patientProfile');
                    
                    if(patientProfile != null){
                        List<Object> addresses = (List<Object>)patientProfile.get('addresses');
                        List<Object> contacts = (List<Object>) patientProfile.get('contacts');
                        Map<String, Object> mapto = (Map<String, Object>)addresses[0];
                        
                        op.kitActivationCode = kitDetail.Activation_Code__c;
                        op.ActivationUserPRS = kitDetail.ActivationUser_PRS_ID__c;
                        op.empiPatientId = (String)patientId.get('empiPatientId');
                        op.firstName = (String)patientProfile.get('firstName');
                        op.lastName = (String)patientProfile.get('lastName');
                        op.gender = (String)patientProfile.get('gender') == 'M' ? 'Male' : 'Female';
                        op.DOB = (String)patientProfile.get('dateOfBirth');
                        op.addressLine1 = (String)mapto.get('addressLine1');
                        op.addressLine2 = mapto.containsKey('addressLine2') && mapto.get('addressLine2') != null ? (String)mapto.get('addressLine2'): '';
                        op.city =(String)mapto.get('city');
                        op.stateProvince =(String)mapto.get('stateProvince');
                        op.country =(String)mapto.get('country');
                        op.zipPostal =(String)mapto.get('zipPostal');
                        
                        for (Object contactObj : contacts) {
                            Map<String, Object> contact = (Map<String, Object>) contactObj;
                            if (contact.get('contactType') == 'PHONE' && contact.get('activeInd') == 'Y') {
                                op.phone =  (String) contact.get('contactAttrValue');
                            }
                            if (String.isBlank(op.phone) && contact.get('contactType') == 'SECONDARY_PHONE' && contact.get('activeInd') == 'Y') {
                                op.phone =  (String) contact.get('contactAttrValue');
                            }
                        }
                        op.responseMessage='Success';
                        op.Status='Success';
                    }
                }
                else if(statusCode==504){
                    op.responseCode=String.valueOf(statusCode);
                    op.responseMessage='Timeout';
                    op.Status='Timeout Error';
                }
                else {
                    String errorMessage='';    
                    if(jsonResponseMap.containsKey('error')){
                        Map<String, Object> errorMap = (Map<String, Object>) jsonResponseMap.get('error');
                        Map<String, Object> faultMap = (Map<String, Object>) errorMap.get('fault');
                        List<Object> messageList = (List<Object>) faultMap.get('message');
                        errorMessage = String.join(messageList, ' ');
                    }
                    op.responseCode=String.valueOf(statusCode);
                    op.responseMessage=errorMessage;
                    op.Status='Error';
                    
                }
            }
            catch(Exception e){
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
                System.debug('Failed to create Transaction' + e.getMessage());
            }
            output.add(op);
        }
        return output;
    }
}