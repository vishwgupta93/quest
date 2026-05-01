public without sharing class CreateLabHUBServiceOrder {
    public class HUBServiceInput {
        @InvocableVariable(label='Ping Fed Token' description='Ping Fed Token')
        public String token;
        @InvocableVariable(label='Lab Order Id' description='Lab Order Id')
        public String labOrderId;
    }
    
    public class HUBServiceOutput {
        @InvocableVariable(label='Response Message' description='Response Message from HUB Service')
        public String responseMessage;
        @InvocableVariable(label='Response Code' description='Response Code from HUB Service')
        public String responseCode;
        @InvocableVariable(label='Request Payload' description='Request Payload')
        public String requestPayload;
        @InvocableVariable(label='Response Payload' description='Response Payload')
        public String responsePayload;
        @InvocableVariable(label='Lab Order Id' description='LabOrderId')
        public String labOrderId;
        @InvocableVariable(label='Status' description='Status')
        public String status;
    }
    
    @InvocableMethod(label='Lab HUB Order' description='Creates Lab HUB Order and Updates Lab Order ')
    public static List<HUBServiceOutput> createHubOrder(List<HUBServiceInput> inputs) {
        
        List<HUBServiceOutput> output = new List<HUBServiceOutput>();
        
        for(HUBServiceInput serviceInput : inputs)
        {
            HUBServiceOutput serviceOutput = new HUBServiceOutput();
            String labOrderId = serviceInput.labOrderId;
            String token = serviceInput.token;
            
            
            Integer statusCode;
            String responseMessage = '';
            Http http = new Http();
            HttpResponse response;
            HttpRequest request = new HttpRequest();
            
            Lab_Order__c labOrder = [select Id,Is_Partner__c,Name,Is_Kit__c,Kit_Detail__r.Date_of_Collection__c,Kit_Detail__r.Activation_Code__c,Order_Summary__r.OrderNumber,Order_Summary__c,Client_Id__c,Person_Record__r.First_Name__c,
                                     Person_Record__r.Last_Name__c,Person_Record__r.Email__c,Person_Record__r.Address_Line_1__c,Person_Record__r.Address_Line_2__c,Person_Record__r.City__c,
                                     Person_Record__r.Country__c,Person_Record__r.State__c,Person_Record__r.Postal_Code__c,Person_Record__r.Phone__c,
                                     Person_Record__r.Gender__c,Person_record__r.Date_of_Birth__c,PWN_ID__c,Physician_First_Name__c,Physician_Last_Name__c,Physician_Upin__c,Physician_Npi__c,LabRefId__c,
                                     Kit_Detail__r.Record_Type__c,Kit_Detail__r.Emp_Patient_Id__c,Kit_Detail__r.Verification_ID__c,Kit_Detail__r.Sample_Received_Date__c,Kit_Detail__r.Order_Number__c,Diagnosis_Codes__c,
                                     Kit_Detail__r.Consent_To_Bank_Version__c, Kit_Detail__r.Consent_To_Process_Sample_Version__c, Kit_Detail__r.Consent_To_Research_Version__c,
                                     Kit_Detail__r.Consent_To_Bank__c, Kit_Detail__r.ActivationUser_Customer_Id__c, Kit_Detail__r.Consent_To_Process__c,  Kit_Detail__r.Consent_To_Research__c, Kit_Detail__r.Prism_ID__c,
                                     Order_Summary__r.Minor_Order__c, Minor_Last_Name__c,Minor_First_Name__c,Minor_Date_of_Birth__c,Minor_Gender__c,Consent_Minor_Date_Time__c,
                                     Minor_Address_Line_1__c,Minor_Address_Line_2__c,Minor_City__c,Minor_State__c,Minor_Zip_Code__c,Minor_Country__c, Minor_Customer_Id__c
                                     from Lab_Order__c where Id =: labOrderId];
            
            
            List<Lab_Panel_Test__c> tests = [select Id, Test_Name__c,Test_Description__c,Test_Code__c,Panel_Test__r.Panel__r.Product__c,
                                             Lab_Order_Panel__r.AOE__c,Lab_Order_Panel__r.Performing_Site__c,Lab_Order_Panel__r.Test_Type__c,Lab_Order_Panel__r.Quantity__c,Lab_Order_Panel__r.Status__c,
                                             Lab_Order_Panel__r.HRA_Req__c,Lab_Order_Panel__r.Questionnaire_Submitted__c from Lab_Panel_Test__c where Lab_Order_Panel__r.Lab_Order__c =: labOrderId];
            

            
            String testType = tests[0].Lab_Order_Panel__r.Test_Type__c;
            String performingSite = tests[0].Lab_Order_Panel__r.Performing_Site__c;
            String gender = '';
            
            // Customer billing address - use minor address for minor orders, guardian address otherwise
            String customerAddressLine1;
            String customerAddressLine2;
            String customerZip;
            String customerCity;
            String customerState;
            String customerCountry;
            
            if(Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c)){
                customerAddressLine1 = labOrder.Minor_Address_Line_1__c != null ? labOrder.Minor_Address_Line_1__c : '';
                customerAddressLine2 = labOrder.Minor_Address_Line_2__c != null ? labOrder.Minor_Address_Line_2__c : '';
                customerZip = labOrder.Minor_Zip_Code__c;
                customerCity = labOrder.Minor_City__c;
                customerState = labOrder.Minor_State__c;
                customerCountry = labOrder.Minor_Country__c != null ? labOrder.Minor_Country__c : 'US';
            } else {
                customerAddressLine1 = labOrder.Person_Record__r.Address_Line_1__c != null ? labOrder.Person_Record__r.Address_Line_1__c : '';
                customerAddressLine2 = labOrder.Person_Record__r.Address_Line_2__c != null ? labOrder.Person_Record__r.Address_Line_2__c : '';
                customerZip = labOrder.Person_Record__r.Postal_Code__c;
                customerCity = labOrder.Person_Record__r.City__c;
                customerState = labOrder.Person_Record__r.State__c;
                customerCountry = labOrder.Person_Record__r.Country__c;
            }
            
            if(labOrder.Person_Record__r.Gender__c == 'Male' || labOrder.Minor_Gender__c == 'Male')
            {
                gender = 'M';
            }
            else if (labOrder.Person_Record__r.Gender__c == 'Female' || labOrder.Minor_Gender__c == 'Female')
            {
                gender = 'F';
            }
            
            DateTime dobDateTime = labOrder.Person_record__r.Date_of_Birth__c != null ? DateTime.newInstance(labOrder.Person_record__r.Date_of_Birth__c.year(), labOrder.Person_record__r.Date_of_Birth__c.month(), labOrder.Person_record__r.Date_of_Birth__c.day()) : null;
            String formattedDOB = dobDateTime != null ? dobDateTime.format('yyyy-MM-dd') : '';
            
            //adding the same logic for minors
            DateTime dobMinorDateTime = null;
            String formattedMinorDOB = '';
            if(Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c)){
                dobMinorDateTime = labOrder.Minor_Date_of_Birth__c != null ? DateTime.newInstance(labOrder.Minor_Date_of_Birth__c.year(), labOrder.Minor_Date_of_Birth__c.month(), labOrder.Minor_Date_of_Birth__c.day()) : null;
                formattedMinorDOB = dobMinorDateTime != null ? dobMinorDateTime.format('yyyy-MM-dd') : '';
            }

            String formattedCollectionDate = '';
            if(labOrder.Is_Kit__c)
            {
                DateTime collectionDateTime = DateTime.newInstance(labOrder.Kit_Detail__r.Date_of_Collection__c.year(), labOrder.Kit_Detail__r.Date_of_Collection__c.month(), labOrder.Kit_Detail__r.Date_of_Collection__c.day());
                formattedCollectionDate = collectionDateTime.format('yyyy-MM-dd');
            }

            String customerId = Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) ? labOrder.Minor_Customer_Id__c : 
                (labOrder.Is_Kit__c && labOrder.Kit_Detail__r.Record_Type__c == 'GSS')? labOrder.Kit_Detail__r.ActivationUser_Customer_Id__c : labOrder.Person_record__c;
            
            System.debug('Lab Orders : ' + labOrder);
            
            System.debug(' Tests : ' + tests);
            
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writefieldName('customers');
            gen.writeStartArray();
            gen.writeStartObject();
            gen.writeStringField('customerId', customerId);
            gen.writeStringField('eid', String.isBlank(labOrder.Kit_Detail__r.Emp_Patient_Id__c)  ? '' : labOrder.Kit_Detail__r.Emp_Patient_Id__c);
            gen.writeStringField('lastName', Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) ? labOrder.Minor_Last_Name__c :labOrder.Person_Record__r.Last_Name__c  );
            gen.writeStringField('firstName', Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) ? labOrder.Minor_First_Name__c : labOrder.Person_Record__r.First_Name__c);
            gen.writeStringField('middleName',  '');
            gen.writeStringField('gender', gender); 
            gen.writeStringField('preferredGender', '7'); 
            gen.writeStringField('email', labOrder.Person_Record__r.Email__c);
            gen.writefieldName('billingAddress');
            gen.writeStartObject();
            gen.writeStringField('addressLine1', customerAddressLine1 != null ? customerAddressLine1 : '');
            gen.writeStringField('addressLine2', customerAddressLine2 != null ? customerAddressLine2 : '');
            gen.writeStringField('zip', customerZip);
            gen.writeStringField('city', customerCity);
            gen.writeStringField('state', customerState);
            gen.writeStringField('country', customerCountry);
            gen.writeEndObject();
            gen.writeStringField('mobilePhone', labOrder.Person_Record__r.Phone__c.replaceAll('[^0-9]', ''));
            gen.writeStringField('birthDate', Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) ?  formattedMinorDOB : formattedDOB) ;
            gen.writefieldName('orderSummaries');
            gen.writeStartArray();
            gen.writeStartObject();
            gen.writeStringField('id', labOrderId);
            gen.writeStringField('clientId', labOrder.Client_Id__c);
            if(!labOrder.Is_Partner__c)
            {
                if(labOrder.Order_Summary__c != null )
                {
                    gen.writeStringField('ecommOrderId', labOrder.Order_Summary__r.OrderNumber);
                }
                else if(labOrder.Order_Summary__c == null && labOrder.Is_Kit__c)
                {
                    gen.writeStringField('ecommOrderId', labOrder.Kit_Detail__r.Order_Number__c);
                }
                
            }
            else{
                gen.writeStringField('ecommOrderId', labOrder.Name); 
            }
            gen.writefieldName('fullfillmentOrders');
            gen.writeStartArray();
            gen.writeStartObject();
            if(labOrder.Is_Kit__c)
            {
                gen.writeStringField('id', labOrder.Kit_Detail__r.Activation_Code__c);
                gen.writeStringField('verificationId',labOrder.Kit_Detail__r.Verification_ID__c);
                gen.writeStringField('collectionDate',formattedCollectionDate);
                gen.writeStringField('testType', labOrder.Kit_Detail__r.Record_Type__c);
                if(labOrder.Kit_Detail__r.Record_Type__c == 'GSS'){
                    gen.writeStringField('status', 'approved') ;
                    gen.writeStringField('prismId', String.isBlank(labOrder.Kit_Detail__r.Prism_ID__c)  ? '' : labOrder.Kit_Detail__r.Prism_ID__c);
                }
                else {
                    gen.writeStringField('status', 'approval_pending') ;
                }
            }
                
             else{
                gen.writeStringField('id', labOrderId);
                gen.writeStringField('testType', testType);
                 gen.writeStringField('status', 'approval_pending');
            }
            gen.writeStringField('pwnOrderId',labOrder.PWN_ID__c); 
            gen.writeStringField('performingSite', performingSite); 
           
                    //added end
            //gen.writeStringField('status', 'approval_pending');
            gen.writeStringField('lid', labOrder.LabRefId__c);                                
            gen.writefieldName('physician');
            gen.writeStartObject();
            gen.writeStringField('name', labOrder.Physician_First_Name__c + ' ' + labOrder.Physician_Last_Name__c);
            gen.writeStringField('firstName', labOrder.Physician_First_Name__c != null ? labOrder.Physician_First_Name__c : '');
            gen.writeStringField('lastName', labOrder.Physician_Last_Name__c != null ? labOrder.Physician_Last_Name__c : '');
            gen.writeStringField('upin', labOrder.Physician_Upin__c != null ? labOrder.Physician_Upin__c : '');
            gen.writeStringField('npi', labOrder.Physician_Npi__c != null ? labOrder.Physician_Npi__c : '');
            gen.writeEndObject();
            gen.writefieldName('fullfillmentOrderItems');
            gen.writeStartArray();
            for (Lab_Panel_Test__c test : tests) {
                gen.writeStartObject();                                           
                gen.writeStringField('id', test.Id);
                gen.writeStringField('testName', test.Test_Name__c);
                gen.writeStringField('testCode', test.Test_Code__c?.contains('-') ? test.Test_Code__c.substringBefore('-') : test.Test_Code__c);
                gen.writeStringField('testDesc', test.Test_Description__c);
                gen.writeStringField('diagnosisCode', labOrder.Diagnosis_Codes__c != null ? labOrder.Diagnosis_Codes__c : '' );
                gen.writeStringField('quantity', String.valueOf(test.Lab_Order_Panel__r.Quantity__c));
                gen.writeStringField('status', test.Lab_Order_Panel__r.Status__c);
                gen.writeBooleanField('isHra', test.Lab_Order_Panel__r.HRA_Req__c);
                gen.writeBooleanField('questionnaireSubmitted', test.Lab_Order_Panel__r.Questionnaire_Submitted__c);
                if(labOrder.Is_Kit__c)
                {
                    gen.writeStringField('activationCode', labOrder.Kit_Detail__r.Activation_Code__c);
                    gen.writeBooleanField('kitActivated', true);
                    gen.writeStringField('verificationId',labOrder.Kit_Detail__r.Verification_ID__c);
                    gen.writeStringField('collectionDate',formattedCollectionDate);
                    gen.writeStringField('testType', labOrder.Kit_Detail__r.Record_Type__c);
                    if(labOrder.Kit_Detail__r.Record_Type__c == 'GSS'){
                        gen.writefieldName('consent');
                        gen.writeStartObject();
                        gen.writeStringField('consentToProcessSampleVersion',labOrder.Kit_Detail__r.Consent_To_Process_Sample_Version__c );
                        gen.writeStringField('consentToBankVersion',labOrder.Kit_Detail__r.Consent_To_Bank_Version__c );
                        gen.writeStringField('consentToResearchVersion',labOrder.Kit_Detail__r.Consent_To_Research_Version__c );
                        gen.writeStringField('consentToProcess',labOrder.Kit_Detail__r.consent_To_Process__c );
                        gen.writeStringField('consentToBank',labOrder.Kit_Detail__r.consent_To_Bank__c);
                        gen.writeStringField('consentToResearch',labOrder.Kit_Detail__r.consent_To_Research__c);
                        gen.writeEndObject();
                        
                        
                    }
                }
                else {
                    gen.writeBooleanField('kitActivated', false);
                    gen.writeStringField('testType', test.Lab_Order_Panel__r.Test_Type__c);
                }

                // List<Lab_Order_Panel_AOE__c> aoes = [select Id, Product_AOE__r.Question__c,Product_AOE__r.Question_Code__c,Product_AOE__r.Type__c, Product_AOE_Option__r.Option_Code__c from Lab_Order_Panel_AOE__c where Lab_Order_Panel__c =: test.Lab_Order_Panel__c and Product_AOE__r.Send_to_HUB__c = true ];


                // List<Map<String, Object>> aoeList = new List<Map<String, Object>>();

                // for (Lab_Order_Panel_AOE__c aoe : aoes) {
                //     Map<String, Object> questionMap = new Map<String, Object>();
                    
                //     questionMap.put('questionText', aoe.Product_AOE__r.Question__c);
                //     questionMap.put('code', aoe.Product_AOE__r.Question_Code__c);
                //     questionMap.put('value', aoe.Product_AOE_Option__r != null ? aoe.Product_AOE_Option__r.Option_Code__c : null);
                //    questionMap.put('questionType', aoe.Product_AOE__r.Type__c);


                //     aoeList.add(questionMap);
                // }

                    List<Lab_Order_Panel_AOE__c> aoes = [
                        SELECT Id,
                            Product_AOE__r.Payload_Question__c,
                            Product_AOE__r.Question_Code__c,
                            Product_AOE__r.Type__c,
                            Product_AOE__r.Option_Type__c,
                            Product_AOE_Option__r.Option_Code__c,
                            Product_AOE_Option__r.Mapping_Object__c,
                            Product_AOE_Option__r.Mapping_Field__c,
                            Product_AOE_Option__r.Mapping_Query__c
                        FROM Lab_Order_Panel_AOE__c
                        WHERE Lab_Order_Panel__c = :test.Lab_Order_Panel__c
                        AND Product_AOE__r.Send_to_HUB__c = true
                    ];

                    List<Product_AOE_Option__c> systemAOEs = [
                        SELECT Id,
                            Product_AOE__r.Payload_Question__c,
                            Product_AOE__r.Question_Code__c,
                            Product_AOE__r.Type__c,
                            Option_Code__c,
                            Mapping_Object__c,
                            Mapping_Field__c,
                            Mapping_Query__c
                        FROM Product_AOE_Option__c
                        WHERE Product_AOE__r.Product__c = :test.Panel_Test__r.Panel__r.Product__c
                        AND Product_AOE__r.Send_to_HUB__c = true
                        AND Product_AOE__r.Option_Type__c = 'SYSTEM'
                    ];

                    System.debug('System AOE: ' + systemAOEs);

                List<Map<String, Object>> aoeList = new List<Map<String, Object>>();

                for (Lab_Order_Panel_AOE__c aoe : aoes) {
                    Map<String, Object> questionMap = new Map<String, Object>();

                    questionMap.put('questionText', aoe.Product_AOE__r.Payload_Question__c);
                    questionMap.put('code', aoe.Product_AOE__r.Question_Code__c);
                    questionMap.put('questionType', aoe.Product_AOE__r.Type__c);
                    questionMap.put('value', aoe.Product_AOE_Option__r != null ? aoe.Product_AOE_Option__r.Option_Code__c : null);

                    aoeList.add(questionMap);
                }

                System.debug('User AOE List: ' + aoeList);

                for (Product_AOE_Option__c aoe : systemAOEs) {
                    Map<String, Object> questionMap = new Map<String, Object>();

                    questionMap.put('questionText', aoe.Product_AOE__r.Payload_Question__c);
                    questionMap.put('code', aoe.Product_AOE__r.Question_Code__c);
                    questionMap.put('questionType', aoe.Product_AOE__r.Type__c);

                    // Handle SYSTEM type AOE
                    
                        String objectName = aoe.Mapping_Object__c;
                        String fieldName = aoe.Mapping_Field__c;
                        String mappingQuery = aoe.Mapping_Query__c;

                        if (String.isNotBlank(objectName) && String.isNotBlank(fieldName) ) {
                            try {
                                // Dynamically form and run SOQL query
                                String queryCondition = 'Id = \'' + labOrderId + '\'';
                                 if (String.isNotBlank(mappingQuery)) {
                                    queryCondition += ' AND ' + mappingQuery;
                                 }
                                String dynamicQuery = 'SELECT Id,' + fieldName +
                                  ' FROM ' + objectName +
                                  ' WHERE ' + queryCondition +
                                  ' LIMIT 1';
                                System.debug('dynamicQuery: ' + dynamicQuery);
                                List<SObject> resultList = Database.query(dynamicQuery);

                                System.debug('resultList: ' + resultList);
                                
                                if (!resultList.isEmpty()) {
                                    SObject record = resultList[0];
                                    Object dynamicValue;
                                    String stringValue;


                                    if (fieldName.contains('.')) {
                                        // Handle nested relationship field (e.g. Person_Record__r.Email)
                                        List<String> parts = fieldName.split('\\.');
                                        if (parts.size() == 2) {
                                            String parentRel = parts[0];
                                            String childField = parts[1];

                                            SObject parent = record.getSObject(parentRel);
                                            if (parent != null) {
                                                dynamicValue = parent.get(childField);
                                            } else {
                                                dynamicValue = null;
                                            }
                                        } else {
                                            // Too deep — not supported
                                            System.debug('Unsupported nested field: ' + fieldName);
                                            dynamicValue = null;
                                        }
                                    } else {
                                        // Top-level field
                                        dynamicValue = record.get(fieldName);
                                    }

                                     // Convert value to string
                                    if (dynamicValue != null && dynamicValue instanceof Date) {
                                        Date d = (Date)dynamicValue;
                                        stringValue = d.year() + '-' + pad2(d.month()) + '-' + pad2(d.day());
                                    } else if (dynamicValue != null) {
                                        stringValue = String.valueOf(dynamicValue);
                                    } else {
                                        stringValue = null;
                                    } 


                                    questionMap.put('value', stringValue);
                                }
                                
                            } catch (Exception e) {
                                System.debug('Error with SYSTEM AOE: ' + e.getMessage());
                                questionMap.put('value', null);
                            }
                        } else {
                            questionMap.put('value', null);
                        }
                        aoeList.add(questionMap);
                    }

                    
                System.debug('Consolidated AOE List: ' + aoeList);

                
               if (!aoeList.isEmpty()) {
                    gen.writeFieldName('aoes');
                    gen.writeObject(aoeList); 
                }
                gen.writeEndObject();
            }                                    
            gen.writeEndArray();
            gen.writeEndObject();
            gen.writeEndArray();
            gen.writeEndObject();
            gen.writeEndArray();
            if(Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c)){
                gen.writeFieldName('next_of_kin');
                gen.writeStartObject();
                gen.writeStringField('firstName', labOrder.Person_Record__r.First_Name__c);
                gen.writeStringField('lastName', labOrder.Person_Record__r.Last_Name__c);
                gen.writeStringField('phone', labOrder.Person_Record__r.Phone__c);
                gen.writeStringField('email', labOrder.Person_Record__r.Email__c);
                gen.writeStringField('addressLine1', labOrder.Person_Record__r.Address_Line_1__c != null ? labOrder.Person_Record__r.Address_Line_1__c : '');
                gen.writeStringField('addressLine2', labOrder.Person_Record__r.Address_Line_2__c != null ? labOrder.Person_Record__r.Address_Line_2__c : '');
                gen.writeStringField('zip_code', labOrder.Person_Record__r.Postal_Code__c);
                gen.writeStringField('city', labOrder.Person_Record__r.City__c);
                gen.writeStringField('state', labOrder.Person_Record__r.State__c);
                gen.writeStringField('country', labOrder.Person_Record__r.Country__c);
                //gen.writeStringField('dob', formattedDOB);
                gen.writeEndObject();
            }
            gen.writeEndObject();
            gen.writeEndArray();
            gen.writeEndObject();
            
            System.debug(gen.getAsString());
            
            serviceOutput = callHubService(gen.getAsString(),token,serviceInput.labOrderId);
            
            output.add(serviceOutput);
            
            
        }

        //Logger.saveLog();
        
        return output;
        
    }

    private static String pad2(Integer n) {
            return (n < 10 ? '0' : '') + String.valueOf(n);
        }
    
    private static HUBServiceOutput callHubService(String requestJSON,String token,String labOrderId)
    {
        HUBServiceOutput serviceOutput= new HUBServiceOutput();
        Http http = new Http();
        HttpResponse response;
        HttpRequest request = new HttpRequest();
        Integer statusCode;
        try{
            
            //String endpoint = Label.OMS_Mule_Proxy_Ednpoint;
            //request.setEndpoint(endpoint+'qdx-quanum-hub-proxy-api/orders');
            //request.setHeader('Authorization','Bearer ' + token);
            
            request.setEndpoint('callout:Quest_Base_EndPoint/qdx-quanum-hub-proxy-api/orders');
            request.setMethod('POST');
            request.setHeader('Content-Type','application/json');
            request.setTimeout(60000);
            request.setBody(requestJSON);
            System.debug('Request::'+request);
            
            
            serviceOutput.labOrderId = labOrderId;
            serviceOutput.requestPayload = requestJSON;
            
            response = http.send(request); 
            statusCode = response.getStatusCode(); 
            
            Map<String, Object> jsonResponseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            
            
            
            serviceOutput.responsePayload = response.getBody();
            
            if(statusCode==201){
                serviceOutput.responseCode=String.valueOf(statusCode);
                serviceOutput.responseMessage='Success';
                serviceOutput.Status='Success';
            }
            else if(statusCode==504){
                serviceOutput.responseCode=String.valueOf(statusCode);
                serviceOutput.responseMessage='Timeout';
                serviceOutput.Status='Timeout Error';
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
        return serviceOutput;
    } 
}