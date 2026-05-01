public with sharing class CancelLabHUBOrder {
    public class CancelLabHUBOrderInput {
        @InvocableVariable(label='Ping Fed Token' description='Ping Fed Token')
        public String token;
        @InvocableVariable(label='Lab Order Id' description='Lab Order Id')
        public String labOrderId;
        }

    public class CancelLabHUBOrderOutput {
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
    public static List<CancelLabHUBOrderOutput> createHubOrder(List<CancelLabHUBOrderInput> inputs) {

        List<CancelLabHUBOrderOutput> output = new List<CancelLabHUBOrderOutput>();

        for(CancelLabHUBOrderInput serviceInput : inputs)
        {
            CancelLabHUBOrderOutput serviceOutput = new CancelLabHUBOrderOutput();
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
            Kit_Detail__r.Record_Type__c,Kit_Detail__r.Verification_ID__c,Kit_Detail__r.Sample_Received_Date__c,Kit_Detail__r.Order_Number__c,
            Order_Summary__r.Minor_Order__c, Minor_Customer_Id__c,Minor_Date_of_Birth__c,Minor_Gender__c,Minor_Last_Name__c,Minor_First_Name__c, LabRefId_Override__c,Customer_ID_Override__c
                                from Lab_Order__c where Id =: labOrderId];
            
                                                                                             
            List<Lab_Panel_Test__c> tests = [select Id, Test_Name__c,Test_Description__c,Test_Code__c,
            Lab_Order_Panel__r.AOE__c,Lab_Order_Panel__r.Performing_Site__c,Lab_Order_Panel__r.Test_Type__c,Lab_Order_Panel__r.Quantity__c,Lab_Order_Panel__r.Status__c,
            Lab_Order_Panel__r.HRA_Req__c,Lab_Order_Panel__r.Questionnaire_Submitted__c from Lab_Panel_Test__c where Lab_Order_Panel__r.Lab_Order__c =: labOrderId];


            String testType = tests[0].Lab_Order_Panel__r.Test_Type__c;
            String performingSite = tests[0].Lab_Order_Panel__r.Performing_Site__c;
            String gender = '';
            String addressLine1 = labOrder.Person_Record__r.Address_Line_1__c;

            //a better practice is to use a map for such mappings.
            Map<String, String> GENDER_MAP = new Map<String, String>{
                'Male' => 'M',
                'Female' => 'F'
            };
            //verify if it's a minor order.
            Boolean isMinorOrder = Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) == true;
            //get the correct gender depending on minor or not.
            String rawGender = isMinorOrder ? labOrder.Minor_Gender__c : labOrder.Person_Record__r.Gender__c;
            //get the correct gender.
            gender = GENDER_MAP.containsKey(rawGender) ? GENDER_MAP.get(rawGender) : '';
            
            //DOB formatting depending on minor or not.
            Date dobDate = isMinorOrder ? labOrder.Minor_Date_of_Birth__c : labOrder.Person_record__r.Date_of_Birth__c;
            String formattedDOB = dobDate != null ? DateTime.newInstance(dobDate.year(), dobDate.month(), dobDate.day()).format('yyyy-MM-dd') : '';

            String formattedCollectionDate = '';
            if(labOrder.Is_Kit__c)
            {
                DateTime collectionDateTime = DateTime.newInstance(labOrder.Kit_Detail__r.Date_of_Collection__c.year(), labOrder.Kit_Detail__r.Date_of_Collection__c.month(), labOrder.Kit_Detail__r.Date_of_Collection__c.day());
                formattedCollectionDate = collectionDateTime.format('yyyy-MM-dd');
            }

            System.debug('Lab Orders : ' + labOrder);

            System.debug(' Tests : ' + tests);

            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
                gen.writefieldName('customers');
                gen.writeStartArray();
                    gen.writeStartObject();
                        gen.writeStringField('customerId', labOrder.Customer_ID_Override__c != null ? labOrder.Customer_ID_Override__c : (Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) ? labOrder.Minor_Customer_Id__c : labOrder.Person_record__c));
                        gen.writeStringField('lastName',  Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) ? labOrder.Minor_Last_Name__c :labOrder.Person_Record__r.Last_Name__c );
                        gen.writeStringField('firstName', Boolean.valueOf(labOrder.Order_Summary__r.Minor_Order__c) ? labOrder.Minor_First_Name__c : labOrder.Person_Record__r.First_Name__c);
                        gen.writeStringField('middleName',  '');
                        gen.writeStringField('gender', gender); 
                        gen.writeStringField('preferredGender', '7'); 
                        gen.writeStringField('email', labOrder.Person_Record__r.Email__c);
                        gen.writefieldName('billingAddress');
                            gen.writeStartObject();
                                gen.writeStringField('addressLine1', addressLine1 != null ? addressLine1 : '');
                                gen.writeStringField('addressLine2', labOrder.Person_Record__r.Address_Line_2__c != null ? labOrder.Person_Record__r.Address_Line_2__c : '');
                                gen.writeStringField('zip', labOrder.Person_Record__r.Postal_Code__c);
                                gen.writeStringField('city', labOrder.Person_Record__r.City__c);
                                gen.writeStringField('state', labOrder.Person_Record__r.State__c);
                                gen.writeStringField('country', labOrder.Person_Record__r.Country__c);
                            gen.writeEndObject();
                        gen.writeStringField('mobilePhone', labOrder.Person_Record__r.Phone__c.replaceAll('[^0-9]', ''));
                        gen.writeStringField('birthDate', formattedDOB) ;
                        gen.writefieldName('orderSummaries');
                        gen.writeStartArray();
                            gen.writeStartObject();
                                gen.writeStringField('id', labOrder.LabRefId_Override__c != null ? labOrder.LabRefId_Override__c : labOrderId);
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

                                        }
                                        else{
                                            gen.writeStringField('id', labOrder.LabRefId_Override__c != null ? labOrder.LabRefId_Override__c : labOrderId);
                                            gen.writeStringField('testType', testType);
                                        }
                                        gen.writeStringField('pwnOrderId',labOrder.PWN_ID__c); 
                                        gen.writeStringField('performingSite', performingSite); 
                                        gen.writeStringField('status', 'cancelled');
                                        gen.writeStringField('lid',  labOrder.LabRefId_Override__c != null ? Label.LabRefOverride_Prefix + labOrder.LabRefId_Override__c : labOrder.LabRefId__c);                                
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
                                                string TestCode =  test.Test_Code__c;
                                                integer lastHyphen= TestCode.lastIndexOf('-');
                                                if(lastHyphen>-1)
                                                {
                                                    String suffix=TestCode.substring(lastHyphen+1);

                                                    if(suffix.toLowerCase().startsWith('m')){
                                                        TestCode=TestCode.substring(0,lastHyphen);
                                                    }

                                                }
                                                gen.writeStringField('testCode',TestCode);
                                                gen.writeStringField('testDesc', test.Test_Description__c);
                                                gen.writeStringField('quantity', String.valueOf(test.Lab_Order_Panel__r.Quantity__c));
                                                gen.writeStringField('status', 'cancelled');
                                                gen.writeBooleanField('isHra', test.Lab_Order_Panel__r.HRA_Req__c);
                                                gen.writeBooleanField('questionnaireSubmitted', test.Lab_Order_Panel__r.Questionnaire_Submitted__c);
                                                if(labOrder.Is_Kit__c)
                                                {
                                                    gen.writeStringField('activationCode', labOrder.Kit_Detail__r.Activation_Code__c);
                                                    gen.writeBooleanField('kitActivated', true);
                                                    gen.writeStringField('verificationId',labOrder.Kit_Detail__r.Verification_ID__c);
                                                    gen.writeStringField('collectionDate',formattedCollectionDate);
                                                    gen.writeStringField('testType', labOrder.Kit_Detail__r.Record_Type__c);
                                                }
                                                else {
                                                    gen.writeBooleanField('kitActivated', false);
                                                    gen.writeStringField('testType', test.Lab_Order_Panel__r.Test_Type__c);
                                                }
                                                
                                                if(test.Lab_Order_Panel__r.AOE__c != null)
                                                {
                                                   
                                                   List<Object> aoeList = (List<Object>) JSON.deserializeUntyped(test.Lab_Order_Panel__r.AOE__c.unescapeHtml4());

                                                    List<Map<String, Object>> attestationJSON = new List<Map<String, Object>>();
                                                    for (Object obj : aoeList) {
                                                        if (obj instanceof Map<String, Object>) {
                                                            attestationJSON.add((Map<String, Object>)obj);
                                                        }
                                                    }
                                                   
                                                    // Map<String, Object> attestationJSON = (Map<String, Object>) JSON.deserializeUntyped(test.Lab_Order_Panel__r.AOE__c.unescapeHtml4());

                                                    // List<Map<String, Object>> attestationJSON = new List<Map<String, Object>>();
                                                    // for (Object obj : aoeList) {
                                                    //     if (obj instanceof Map<String, Object>) {
                                                    //         attestationJSON.add((Map<String, Object>)obj);
                                                    //     }
                                                    // }
                                                    

                                                    gen.writeFieldName('aoes');
                                                        gen.writeStartArray();
                                                        for (Map<String, Object> aoe : attestationJSON) {

                                                            if((Boolean)aoe.get('isAoe'))
                                                            {
                                                                gen.writeStartObject(); 
                                                             
                                                            for (String fieldName : aoe.keySet()) {
                                                                Object value = aoe.get(fieldName);
                                                                if(value != null)
                                                                {
                                                                    if (value instanceof String) {
                                                                        gen.writeStringField(fieldName, (String)value);
                                                                    } else if (value instanceof Decimal) {
                                                                        gen.writeStringField(fieldName, String.valueOf(value));
                                                                    }  else if (value instanceof Boolean && fieldName != 'isAoe') {
                                                                        gen.writeBooleanField(fieldName, (Boolean)value);
                                                                    }
                                                                    else if(fieldName == 'isAoe')
                                                                    {
                                                                        Boolean isAOE = (Boolean) value;
                                                                        gen.writeStringField('questionType',isAOE ? 'AOE':'CONSENT');
                                                                    }
                                                                }
                                                            }
                                                            gen.writeEndObject();
                                                            }
                                                            
                                                        }                                           
                                                        gen.writeEndArray();
                                                }
                                            gen.writeEndObject();
                                        }                                    
                                    gen.writeEndArray();
                                gen.writeEndObject();
                            gen.writeEndArray();
                        gen.writeEndObject();
                    gen.writeEndArray();
                gen.writeEndObject();
            gen.writeEndArray();
        gen.writeEndObject();

            System.debug(gen.getAsString());
            
            serviceOutput = callHubService(gen.getAsString(),token,serviceInput.labOrderId);

        output.add(serviceOutput);
            

        }

        return output;

    }

    private static CancelLabHUBOrderOutput callHubService(String requestJSON,String token,String labOrderId)
    {
        CancelLabHUBOrderOutput serviceOutput= new CancelLabHUBOrderOutput();
        Http http = new Http();
        HttpResponse response;
        HttpRequest request = new HttpRequest();
        Integer statusCode;
        try{
            
            String endpoint = Label.OMS_Mule_Proxy_Ednpoint;
            
            
            request.setEndpoint(endpoint+'qdx-quanum-hub-proxy-api/orders');
            request.setMethod('PATCH');
            request.setHeader('Content-Type','application/json');
            request.setHeader('Authorization','Bearer ' + token);
            request.setTimeout(60000);
            request.setBody(requestJSON);
            System.debug('Request::'+request);
                    
                
                serviceOutput.labOrderId = labOrderId;
                serviceOutput.requestPayload = requestJSON;

                response = http.send(request); 
                statusCode = response.getStatusCode(); 

                Map<String, Object> jsonResponseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                
               
                
                serviceOutput.responsePayload = response.getBody();

                if(statusCode==201 || statusCode==200){
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