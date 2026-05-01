public without sharing class CreateLabPWNServiceOrder {
    public class PWNServiceInput {
        @InvocableVariable(label='Ping Fed Token' description='Ping Fed Token')
        public String token;
        @InvocableVariable(label='Lab Order id' description='Lab Order Id')
        public String labOrderId; 
    }

    public class PWNServiceOutput {
        
        @InvocableVariable(label='Diagnosis Codes' description='Diagnosis Codes from PWN Service')
        public String diagnosisCodes;
        @InvocableVariable(label='Response Message' description='Response Message from PWN Service')
        public String responseMessage;
        @InvocableVariable(label='Response Code' description='Response Code from PWN Service')
        public String responseCode;
        @InvocableVariable(label='Request Payload' description='Request Payload')
        public String requestPayload;
        @InvocableVariable(label='Response Payload' description='Response Payload')
        public String responsePayload;
        @InvocableVariable(label='Lab Order Id' description='LabOrderId')
        public String labOrderId;
        @InvocableVariable(label='Status' description='Status')
        public String status;

        @InvocableVariable(label='Physician First Name' description='Physician First Name')
        public String firstName;
        @InvocableVariable(label='Physician Last Name' description='Physician Last Name')
        public String lastName;
        @InvocableVariable(label='UPIN' description='UPIN')
        public String upin;
        @InvocableVariable(label='NPI' description='NPI')
        public String npi;
        @InvocableVariable(label='PWNID' description='PWNID')
        public String pwnID;

        @InvocableVariable(label='Created At' description='Created At')
        public String createdAt;
        
        @InvocableVariable(label='Updated At' description='Updated At')
        public String updatedAt;
        
        @InvocableVariable(label='Expires At' description='Expires At')
        public String expiresAt;
    }
    @InvocableMethod(label='Create PWN Service Order' description='Creates PWN Service Order and Updates Lab Order with Physician Details')
    public static List<PWNServiceOutput> createPWNOrder(List<PWNServiceInput> inputs)
    {
        List<PWNServiceOutput> output = new List<PWNServiceOutput>();
        for(PWNServiceInput serviceInput : inputs)
        {
            String labOrderId = serviceInput.labOrderId;
            String token = serviceInput.token;
            PWNServiceOutput serviceOutput = new PWNServiceOutput();

            System.debug('Inputs: Lab Order Id : ' + labOrderId);
            
            Integer statusCode;
            String responseMessage = '';
            Http http = new Http();
            HttpResponse response;
            HttpRequest request = new HttpRequest();
            

            Lab_Order__c labOrder = [select Id,Order_Summary__c,Client_Id__c,Person_Record__r.First_Name__c,FO_Record_Type__c,
            Person_Record__r.Last_Name__c,Person_Record__r.Email__c,Person_Record__r.Address_Line_1__c,Person_Record__r.Address_Line_2__c,Person_Record__r.City__c,
            Person_Record__r.Country__c,Person_Record__r.State__c,Person_Record__r.Postal_Code__c,Person_Record__r.Phone__c,
            Person_Record__r.Gender__c,Person_record__r.Date_of_Birth__c, 
            Kit_Detail__c, Kit_Detail__r.Cancer_Family_History__c,Kit_Detail__r.Cancer_Personal_History__c,Kit_Detail__r.Cardio_Personal_History__c,
            Kit_Detail__r.Cardio_Family_History__c,Kit_Detail__r.Carrier_Family_History__c,Kit_Detail__r.Carrier_Personal_History__c,Kit_Detail__r.Reviewing_Physician_Id__c, 
            Kit_Detail__r.Activation_Code__c, Kit_Detail__r.ActivationUser_PRS_ID__c,Kit_Detail__r.Reason_For_Testing__c,Kit_Detail__r.Type__c,
            Order_Summary__r.Minor_Order__c, Minor_Last_Name__c,Minor_First_Name__c,Minor_Date_of_Birth__c,Minor_Gender__c,Consent_Minor_Date_Time__c,
            Minor_Address_Line_1__c,Minor_Address_Line_2__c,Minor_City__c,Minor_State__c,Minor_Zip_Code__c,Minor_Country__c
            from Lab_Order__c where Id =: labOrderId];
            
            Map<String, Map<String,String>> typeMap = new Map<String, Map<string,String>>();
            Map<String, String> cancerMap = new Map<String,String>{'family' => labOrder.Kit_Detail__r.Cancer_Family_History__c, 'personal' => labOrder.Kit_Detail__r.Cancer_Personal_History__c};
            Map<String, String> cardioMap = new Map<String,String>{'family' => labOrder.Kit_Detail__r.Cardio_Family_History__c, 'personal' => labOrder.Kit_Detail__r.Cardio_Personal_History__c};
            Map<String, String> carrierMap = new Map<String,String>{'family' => labOrder.Kit_Detail__r.Carrier_Family_History__c, 'personal' => labOrder.Kit_Detail__r.Carrier_Personal_History__c};
            typeMap.put('cancer', cancerMap);
            typeMap.put('cardio', cardioMap);
            typeMap.put('carrier', carrierMap);
                                                                                             
            List<Lab_Panel_Test__c> tests = [select Id, Test_Code__c from Lab_Panel_Test__c where Lab_Order_Panel__r.Lab_Order__c =: labOrderId];

            List<Lab_Order_Panel_AOE__c> aoes = [select Id, Product_AOE__r.Payload_Question__c,Product_AOE__r.Question_Code__c,Product_AOE__r.Type__c, Product_AOE_Option__r.Option_Code__c from Lab_Order_Panel_AOE__c where Lab_Order_Panel__r.Lab_Order__c =: labOrderId and Product_AOE__r.Send_to_PWN__c = true ];


            System.debug('Lab Orders : ' + labOrder);

            System.debug(' Tests : ' + tests);

            List<Map<String, Object>> aoeList = new List<Map<String, Object>>();

            for (Lab_Order_Panel_AOE__c aoe : aoes) {
                Map<String, Object> questionMap = new Map<String, Object>();
                
                questionMap.put('questionText', aoe.Product_AOE__r.Payload_Question__c);
                questionMap.put('code', aoe.Product_AOE__r.Question_Code__c);
                questionMap.put('value', aoe.Product_AOE_Option__r != null ? aoe.Product_AOE_Option__r.Option_Code__c : null);
                questionMap.put('questionType', aoe.Product_AOE__r.Type__c);

                aoeList.add(questionMap);
            }
            //MINOR DETAILS
            if(labOrder.Order_Summary__r.Minor_Order__c == true){
                Map<String, Object> questionMinorMap = new Map<String, Object>();
                questionMinorMap.put('type', 'consent');
                questionMinorMap.put('name', labOrder.Person_record__r.First_Name__c + ' ' + labOrder.Person_Record__r.Last_Name__c);
                questionMinorMap.put('date_time', String.valueOf(labOrder.Consent_Minor_Date_Time__c));
                aoeList.add(questionMinorMap);
            }

            Map<String, Object> customAttributes = new Map<String, Object>();
            customAttributes.put('aoe', aoeList);

           

            //DateTime dobDateTime = DateTime.newInstance(labOrder.Person_record__r.Date_of_Birth__c.year(), labOrder.Person_record__r.Date_of_Birth__c.month(), labOrder.Person_record__r.Date_of_Birth__c.day());
            //String formattedDOB = dobDateTime.format('yyyy-MM-dd');
            DateTime dobDateTime = labOrder.Person_record__r.Date_of_Birth__c != null ? DateTime.newInstance(labOrder.Person_record__r.Date_of_Birth__c.year(), labOrder.Person_record__r.Date_of_Birth__c.month(), labOrder.Person_record__r.Date_of_Birth__c.day()) : null;
            String formattedDOB = dobDateTime != null ? dobDateTime.format('yyyy-MM-dd') : '';

            //adding the same logic for minors
            DateTime dobMinorDateTime = null;
            String formattedMinorDOB = '';
            if(Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c)){
                dobMinorDateTime = labOrder.Minor_Date_of_Birth__c != null ? DateTime.newInstance(labOrder.Minor_Date_of_Birth__c.year(), labOrder.Minor_Date_of_Birth__c.month(), labOrder.Minor_Date_of_Birth__c.day()) : null;
                formattedMinorDOB = dobMinorDateTime != null ? dobMinorDateTime.format('yyyy-MM-dd') : '';
            }


            // Guardian address (used for next_of_kin) - concatenate into single line field
            String guardianAddress = labOrder.Person_Record__r.Address_Line_1__c != null ? labOrder.Person_Record__r.Address_Line_1__c : '';
            if(labOrder.Person_Record__r.Address_Line_2__c != null)
            {
                guardianAddress = guardianAddress + ' ' + labOrder.Person_Record__r.Address_Line_2__c;
            }
            
            // Customer address - use minor address for minor orders, guardian address otherwise
            String customerAddress;
            if(Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c)){
                customerAddress = labOrder.Minor_Address_Line_1__c != null ? labOrder.Minor_Address_Line_1__c : '';
                if(labOrder.Minor_Address_Line_2__c != null)
                {
                    customerAddress = customerAddress + ' ' + labOrder.Minor_Address_Line_2__c;
                }
            } else {
                customerAddress = guardianAddress;
            }


            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
                gen.writeFieldName('order');
                    gen.writeStartObject();
                        gen.writeFieldName('tests');
                            gen.writeStartArray();
                            if(labOrder.FO_Record_Type__c == 'GSS')
                            {
                                gen.writeString(Label.PWN_GSS_Test_Code);
                            }
                            else
                            {
                                for (Lab_Panel_Test__c test : tests) {
                                    if(test.Test_Code__c?.contains('-')){
                                        gen.writeString(test.Test_Code__c.substringBefore('-'));

                                    }else{
                                        gen.writeString(test.Test_Code__c);
                                    }
                                    
                                }
                            }
                                
                            gen.writeEndArray();


                            gen.writeFieldName('customAttributes');
                                gen.writeObject(customAttributes);

                            gen.writeStringField('reference', labOrderId);
                            gen.writeStringField('accountNumber', labOrder.FO_Record_Type__c == 'GSS'? Label.PWN_GSS_Account_Number : labOrder.Client_Id__c);
            // start
            
        if(labOrder.Kit_Detail__r.Type__c == 'GSS'){
            
                        // gen.writeStringField('reference', labOrder.Kit_Detail__r.Activation_Code__c);
                        gen.writeStringField('reviewing_physician_id', labOrder.Kit_Detail__r.Reviewing_Physician_Id__c);
                        gen.writeStringField('reason_for_testing', labOrder.Kit_Detail__r.Reason_For_Testing__c);
                            gen.writeFieldName('disease_states');
                                gen.writeStartArray();
                                    for(String eachType : typeMap.keySet()){
                                        gen.writeStartObject();
                                            gen.writeStringField('name', eachType);
                                            object familyObjs = (object) json.deserializeUntyped(typeMap.get(eachType).get('family'));
                                            gen.writeObjectField('familyHistory',familyObjs);
                                            object personalobjs = (object) json.deserializeUntyped(typeMap.get(eachType).get('personal'));
                                            gen.writeObjectField('personalHistory',personalobjs);
                                        gen.writeEndObject();
                                    }
                                gen.writeEndArray();
                        
        }
            
            ////end
            gen.writeFieldName('customer');
                gen.writeStartObject();
                    // gen.writeStringField('externalId', labOrder.Person_Record__r.External_Customer_Id__c != null ? labOrder.Person_Record__r.External_Customer_Id__c : labOrder.Person_record__c);
                    gen.writeStringField('externalId', Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) ? '' : labOrder.Person_record__c);
                    gen.writeStringField('lastName', Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) ? labOrder.Minor_Last_Name__c  : labOrder.Person_Record__r.Last_Name__c);
                    gen.writeStringField('gender', Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) ? labOrder.Minor_Gender__c : labOrder.Person_Record__r.Gender__c);
                    gen.writeStringField('email', labOrder.Person_Record__r.Email__c);
                    gen.writeStringField('homePhone', labOrder.Person_Record__r.Phone__c.replaceAll('[^0-9]', ''));
                    gen.writeStringField('birthDate', Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) ? formattedMinorDOB : formattedDOB);
                    gen.writeStringField('firstName', Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) ? labOrder.Minor_First_Name__c : labOrder.Person_Record__r.First_Name__c);
                    gen.writeFieldName('address');
                        gen.writeStartObject();
                            gen.writeStringField('zip', Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) ? labOrder.Minor_Zip_Code__c : labOrder.Person_Record__r.Postal_Code__c);
                            gen.writeStringField('city', Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) ? labOrder.Minor_City__c : labOrder.Person_Record__r.City__c);
                            gen.writeStringField('state', Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) ? labOrder.Minor_State__c : labOrder.Person_Record__r.State__c);
                            gen.writeStringField('line', customerAddress);
                        gen.writeEndObject();
                    gen.writeEndObject();
                    //Adding next of kin for minors
                    if(Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c)){
                            gen.writeFieldName('next_of_kin');
                            gen.writeStartObject();
                                gen.writeStringField('first_name', labOrder.Person_Record__r.First_Name__c);
                                gen.writeStringField('last_name', labOrder.Person_Record__r.Last_Name__c);
                                gen.writeStringField('phone', labOrder.Person_Record__r.Phone__c.replaceAll('[^0-9]', ''));
                                gen.writeStringField('email', labOrder.Person_Record__r.Email__c);
                                String guardianAddressLine1ForNextOfKin = labOrder.Person_Record__r.Address_Line_1__c != null ? labOrder.Person_Record__r.Address_Line_1__c : '';
                                String guardianAddressLine2ForNextOfKin = labOrder.Person_Record__r.Address_Line_2__c != null ? labOrder.Person_Record__r.Address_Line_2__c : '';
                                String guardianAddressForNextOfKin = '';
                                if (String.isNotBlank(guardianAddressLine1ForNextOfKin) && String.isNotBlank(guardianAddressLine2ForNextOfKin)) {
                                    guardianAddressForNextOfKin = guardianAddressLine1ForNextOfKin + ', ' + guardianAddressLine2ForNextOfKin;
                                } else if (String.isNotBlank(guardianAddressLine1ForNextOfKin)) {
                                    guardianAddressForNextOfKin = guardianAddressLine1ForNextOfKin;
                                } else if (String.isNotBlank(guardianAddressLine2ForNextOfKin)) {
                                    guardianAddressForNextOfKin = guardianAddressLine2ForNextOfKin;
                                }
                                gen.writeStringField('address', guardianAddressForNextOfKin);
                                gen.writeStringField('city', labOrder.Person_Record__r.City__c);
                                gen.writeStringField('state', labOrder.Person_Record__r.State__c);
                                gen.writeStringField('country', labOrder.Person_Record__r.Country__c);
                                gen.writeStringField('zip_code', labOrder.Person_Record__r.Postal_Code__c);
                                //gen.writeStringField('dob', formattedDOB);
                            gen.writeEndObject();
                    }
                gen.writeEndObject();
            gen.writeEndObject();


            String jsonStr = gen.getAsString();

            System.debug('2nd json to test'+jsonStr);
            try{
           // String endpoint = Label.OMS_Mule_Proxy_Ednpoint;

            //endpoint = labOrder.FO_Record_Type__c == 'GSS'? endpoint + 'qdx-pwn-proxy-api/orders?testType=GSS' : endpoint +'qdx-pwn-proxy-api/orders?testType=PSC';                      
            String endpoint = labOrder.FO_Record_Type__c == 'GSS'?  'callout:Quest_Base_EndPoint/qdx-pwn-proxy-api/orders?testType=GSS' : 'callout:Quest_Base_EndPoint/qdx-pwn-proxy-api/orders?testType=PSC';
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type','application/json');
            //request.setHeader('Authorization','Bearer ' + token);
            request.setBody(jsonStr);
            System.debug('Request::'+request);
            System.debug('Request 1 ::'+jsonStr);

            serviceOutput.labOrderId = labOrderId;
            serviceOutput.requestPayload = jsonStr;
            
                
                response = http.send(request); 
                statusCode = response.getStatusCode(); 
                System.debug('Response Status::'+response.getStatus());
                System.debug('Response Body::'+response.getBody());
                serviceOutput.responsePayload = response.getBody();

               
                Map<String, Object> jsonResponseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

               
                
                if(statusCode==201){
                    
                
                Map<String, Object> orderDetails = (Map<String, Object>)jsonResponseMap.get('order');
				String lstdiagnosesCodes = '';
                if (orderDetails != null) {
                    // changes on 13/03/2025  Starting
                    serviceOutput.createdAt = (String)orderDetails.get('createdAt');
                    serviceOutput.updatedAt = (String)orderDetails.get('updatedAt');
                    serviceOutput.expiresAt = (String)orderDetails.get('expiresAt');
                    // Ending
                    Map<String, Object> physicianDetails = (Map<String, Object>)orderDetails.get('physicianReview');
                    if (physicianDetails != null) {
                        
                        serviceOutput.firstName = (String)physicianDetails.get('firstName');
                        serviceOutput.lastName = (String)physicianDetails.get('lastName');
                        serviceOutput.upin = (String)physicianDetails.get('upin');
                        serviceOutput.npi = (String)physicianDetails.get('npi');
                        serviceOutput.pwnID = String.valueOf(orderDetails.get('id'));
                        //serviceOutput.diagnosisCodes = String.valueOf(orderDetails.get('diagnosis'));
                        
                    }
                    List<Object> lstdiagnoses = (List<Object>)orderDetails.get('diagnoses');
                    
                    if (lstdiagnoses != null) {
                        for(Object eachDiagnosesCode : lstdiagnoses ){
                            lstdiagnosesCodes =+ (String)eachDiagnosesCode+',';
                        }
                    }
                    
                } 
                    if(lstdiagnosesCodes != null || lstdiagnosesCodes != ''){
                      lstdiagnosesCodes =  lstdiagnosesCodes.removeEnd(',');
                    }
                    serviceOutput.diagnosisCodes = lstdiagnosesCodes;
                    serviceOutput.responseCode=String.valueOf(statusCode);
                    serviceOutput.responseMessage='Success';
                    serviceOutput.Status='Success';
                }
                else {      
                    String errorMessage='';          
                    if (jsonResponseMap.containsKey('error')) {
                        Map<String, Object> errorMap = (Map<String, Object>) jsonResponseMap.get('error');
                        Map<String, Object> faultMap = (Map<String, Object>) errorMap.get('fault');
                        List<Object> messageList = (List<Object>) faultMap.get('message');
                        errorMessage = String.join(messageList, ' ');
                    }
                    serviceOutput.responseCode=String.valueOf(statusCode);
                    serviceOutput.responseMessage=errorMessage;
                    serviceOutput.Status='Error';
                }
            }
            
        catch(Exception e){
            
            if(response != null)
            {
                serviceOutput.responseCode=String.valueOf(statusCode);
                serviceOutput.responseMessage=response.getStatus() + ' Message: ' + response.getBody();
                serviceOutput.responsePayload = response.getBody();
            }
            else {
                serviceOutput.responseMessage=e.getMessage();
                serviceOutput.responsePayload = e.getMessage();
                serviceOutput.responseCode='504';
            }
            
            serviceOutput.Status='Error';
            System.debug('Failed to create Transaction' + e.getMessage());
        }

                output.add(serviceOutput);
        }

        return output;
    }
}