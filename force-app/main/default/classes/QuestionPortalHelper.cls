public class QuestionPortalHelper {
    
    public class InputPrameters {
        @InvocableVariable(label='Ping Fed Token' description='Ping Fed Token')
        public String token;
        @InvocableVariable(label='ActivationUser PRS ID' description='ActivationUser PRS ID')
        public String ActivationUserPRSID; 
        @InvocableVariable(label='Kit Lab id' description='Kit Lab Id')
        public String kitLabId; 
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
        @InvocableVariable(label='Kit Order Id' description='Kit Order Id')
        public String kitOrderId;
        @InvocableVariable(label='Status' description='Status')
        public String status; 
        
        @InvocableVariable(label='prs Id' description='prs Id')
        public String prsId;
        @InvocableVariable(label='Reviewing Physician Id' description='Reviewing Physician Id')
        public String  ReviewingPhysicianId;
        @InvocableVariable(label='Reason For Testing' description='Reason For Testing')
        public String ReasonForTesting;
        @InvocableVariable(label='consent To Process' description='consent To Process')
        public String consentToProcess;
        @InvocableVariable(label='consent To Research' description='consent To Research')
        public String consentToResearch;
        @InvocableVariable(label='consent To Bank' description='consent To Bank')
        public String consentToBank;
        
        @InvocableVariable(label='Cancer Family History' description='Cancer Family History')
        public String cancerFamilyHistory;
        @InvocableVariable(label='Cardio Family History' description='Cardio Family History')
        public String cardioFamilyHistory;
        @InvocableVariable(label='Carrier Family History' description='Carrier Family History')
        public String carrierFamilyHistory;
        @InvocableVariable(label='Cancer Personal History' description='Cancer Personal History')
        public String cancerPersonalHistory;
        @InvocableVariable(label='Cardio Personal History' description='Cardio Personal History')
        public String cardioPersonalHistory;
        @InvocableVariable(label='Carrier Personal History' description='Carrier Personal History')
        public String carrierPersonalHistory;
        
        @InvocableVariable(label='Consent To Process Sample Version' description='Consent To Process Sample Version')
        public String consentToProcessSampleVersion;
        @InvocableVariable(label='Consent To Bank Version' description='Consent To Bank Version')
        public String consentToBankVersion;
        @InvocableVariable(label='Consent To Research Version' description='Consent To Research Version')
        public String consentToResearchVersion;
    }
    
    @InvocableMethod(label='Fetch Question Portal Details ' description='fetch Question Portal Details')
    public static List<OutParameters> fetchQuestionPortalDetails(List<InputPrameters> inputs){
        List<OutParameters> output = new List<OutParameters>();
        HealthResponseProcessor processor = new HealthResponseProcessor();
        OutParameters op = new OutParameters();
        HttpResponse response;
        
        for(InputPrameters serviceInput : inputs)
        {
            System.debug('kitLabId==' + serviceInput.kitLabId);
            
            String token = serviceInput.token;
            Integer statusCode;
            try{
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                
                Kit_Details__c kitDetail = [select id, ActivationUser_PRS_ID__c,Activation_Code__c  from Kit_Details__c where Id =: serviceInput.kitLabId];
                String endpoint = String.format(Label.OMS_Mule_Proxy_Ednpoint + 
                    'qdx-question-portal-proxy-api/saved-health-responses?PRSId={0}&kitId={1}&active=true&submitted=true&testCode=11957',
                    new List<String>{kitDetail.ActivationUser_PRS_ID__c, kitDetail.Activation_Code__c}
                ); 

                
                response = fetchHealthResponses(serviceInput.token,endpoint);
                output.add(processor.processResponse(response, endpoint));
            }catch(Exception e){
                OutParameters serviceOutput = new OutParameters();
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
            }
            
        }
        return output;
    }
    
    
    public static String formatStringKey(String key){
        List<String> ls = key.splitByCharacterTypeCamelCase();
        String newBuild = '';
        for(String s : ls){
            newBuild += s.toLowerCase()+'_';
        }
        String newStr = newBuild.removeEnd('_'); 
        return newStr;
    }
    
    
    
    public static HttpResponse fetchHealthResponses(String token, String endpoint) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + token);
        return new Http().send(request);
    }
    
    
    public class HealthResponseProcessor {
        private Map<String, String> mappingData;
        private Map<String, String> personalGeneticKeys;
        private Map<String, String> variantNameDiseaseMap;
        
        public HealthResponseProcessor() {
            initializeMappings();
        }
        
        private void initializeMappings() {
            mappingData = new Map<String, String>();
            personalGeneticKeys = new Map<String, String>();
            variantNameDiseaseMap = new Map<String, String>();
            
            for (GSS_PWN_Mapping__mdt mapping : [SELECT Mapping_Key__c, Mapping_Value__c, Disease_State_Name__c 
                                                 FROM GSS_PWN_Mapping__mdt]) {
                                                     mappingData.put(mapping.Mapping_Key__c, mapping.Mapping_Value__c);
                                                     variantNameDiseaseMap.put(mapping.Mapping_Key__c, mapping.Disease_State_Name__c);
                                                 }
            
            for (GSS_Genetic_Variant_Key__mdt mapping : [SELECT Key_to_Check__c, Disease_State_Name__c 
                                                         FROM GSS_Genetic_Variant_Key__mdt]) {
                                                             personalGeneticKeys.put(mapping.Key_to_Check__c, mapping.Disease_State_Name__c);
                                                         }
        }
        
        public QuestionPortalHelper.OutParameters processResponse(HttpResponse response, String endpoint) {
            QuestionPortalHelper.OutParameters output = new QuestionPortalHelper.OutParameters();
            
            if (response.getStatusCode() == 200) {
                processSuccessResponse(response, output);
                output.requestPayload = endpoint;
                output.responseMessage = 'Success';
                output.status = 'Success';
            } 
            else if(response.getStatusCode()==504){
                    output.responseCode=String.valueOf(response.getStatusCode());
                    output.responseMessage='Timeout';
                    output.Status='Timeout Error';
                }
            
            else {
                output.responseCode = String.valueOf(response.getStatusCode());
                output.responseMessage = '';
                output.status = 'Error';
            }
            
            output.responsePayload = response.getBody().substring(0, Math.min(50000, response.getBody().length()));
            output.responseCode = String.valueOf(response.getStatusCode());
            return output;
        }
        
        private void processSuccessResponse(HttpResponse response, QuestionPortalHelper.OutParameters output) {
            List<Object> jsonResponses = (List<Object>)JSON.deserializeUntyped(response.getBody());
            HistoryData historyData = new HistoryData();
            
            for (Object jsonResponse : jsonResponses) {
                Map<String, Object> responseMap = (Map<String, Object>)jsonResponse;
                String jsonQuestions = (String)responseMap.get('json_questions_response_payload');
                Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(jsonQuestions);
                
                processHeader(payload, output);
                processQAndAGroups(payload, historyData);
            }
            
            serializeHistoryData(historyData, output);
        }
        
        private void processHeader(Map<String, Object> payload, QuestionPortalHelper.OutParameters output) {
            Map<String, Object> header = (Map<String, Object>)payload.get('header');
            Map<String, Object> consentVersions = (Map<String, Object>)header.get('consentVersions');
            
            output.consentToProcessSampleVersion = (String)consentVersions.get('consentToProcessSampleVersion');
            output.consentToBankVersion = (String)consentVersions.get('consentToBankVersion');
            output.consentToResearchVersion = (String)consentVersions.get('consentToResearchVersion');
            output.prsId = (String)header.get('prismId');
            output.ReviewingPhysicianId = String.valueOf(((Map<String, Object>)header.get('physician')).get('id'));
        }
        
        private void processQAndAGroups(Map<String, Object> payload, HistoryData historyData) {
            List<Object> qAndAGroups = (List<Object>)payload.get('qAndAGroups');
            for (Object groupDetail : qAndAGroups) {
                Map<String, Object> groupMap = (Map<String, Object>)groupDetail;
                String groupId = (String)groupMap.get('groupId');
                
                switch on groupId {
                    when 'consumerDemographics' {
                        historyData.reasonForTesting = extractReasonForTesting(groupMap);
                    }
                    when 'consentToProcess' {
                        historyData.consentToProcess = extractConsent(groupMap, 'consentToProcess');
                    }
                    when 'consentToBank' {
                        historyData.consentToBank = extractConsent(groupMap, 'consentToBank');
                    }
                    when 'consentToResearch' {
                        historyData.consentToResearch = extractConsent(groupMap, 'consentToResearch');
                    }
                    when 'personalHistoryCancer' {
                        processPersonalCancerHistory(groupMap, historyData);
                    }
                    when 'personalHistoryCardio' {
                        processPersonalCardioHistory(groupMap, historyData);
                    }
                    when 'personalHistoryGeneticConditions' {
                        processPersonalGeneticConditions(groupMap, historyData);
                    }
                    when 'personalHistoryGeneticTestVariants' {
                        processPersonalGeneticVariants(groupMap, historyData);
                    }
                    when 'familyHistoryCancer' {
                        processFamilyCancerHistory(groupMap, historyData);
                    }
                    when 'familyHistoryCardio' {
                        processFamilyCardioHistory(groupMap, historyData);
                    }
                    when 'familyHistoryGeneticConditions' {
                        processFamilyGeneticConditions(groupMap, historyData);
                    }
                }
            }
        }
        
        private String extractReasonForTesting(Map<String, Object> groupMap) {
            List<Object> itemConfigs = (List<Object>)groupMap.get('itemConfig');
            for (Object config : itemConfigs) {
                Map<String, Object> itemConfig = (Map<String, Object>)config;
                if ('reasonForTesting'.equals(itemConfig.get('questionKey'))) {
                    List<Object> responses = (List<Object>)itemConfig.get('responses');
                    if (!responses.isEmpty()) {
                        Map<String, Object> response = (Map<String, Object>)responses[0];
                        return QuestionPortalHelper.formatStringKey(String.valueOf(response.get('key')));
                    }
                }
            }
            return null;
        }
        
        private String extractConsent(Map<String, Object> groupMap, String questionKey) {
            List<Object> itemConfigs = (List<Object>)groupMap.get('itemConfig');
            for (Object config : itemConfigs) {
                Map<String, Object> itemConfig = (Map<String, Object>)config;
                if (itemConfig.containsKey('scrollWindow')) {
                    List<Object> scrollWindows = (List<Object>)itemConfig.get('scrollWindow');
                    for (Object window : scrollWindows) {
                        Map<String, Object> windowMap = (Map<String, Object>)window;
                        if (questionKey.equals(windowMap.get('questionKey'))) {
                            List<Object> responses = (List<Object>)windowMap.get('responses');
                            for (Object response : responses) {
                                Map<String, Object> responseMap = (Map<String, Object>)response;
                                if (responseMap.containsKey('key')) {
                                    return (String)responseMap.get('key');
                                }
                            }
                        }
                    }
                }
            }
            return null;
        }
        
        private void processPersonalCancerHistory(Map<String, Object> groupMap, HistoryData historyData) {
            List<Object> itemConfigs = (List<Object>)groupMap.get('itemConfig');
            for (Object config : itemConfigs) {
                Map<String, Object> configMap = (Map<String, Object>)config;
                if ('cancerPersonalHistory'.equals(configMap.get('questionKey'))) {
                    List<Object> responses = (List<Object>)configMap.get('responses');
                    for (Object response : responses) {
                        Map<String, Object> responseMap = (Map<String, Object>)response;
                        String key = (String)responseMap.get('key');
                        if ('unknownCancer'.equals(key)) {
                            historyData.personalCancer.add(new Map<String, Object>{
                                'age' => 'unknown',
                                    'condition' => mappingData.get(key)
                                    });
                        } else if (responseMap.containsKey('followUps')) {
                            List<Object> followUps = (List<Object>)responseMap.get('followUps');
                            if (followUps != null) {
                                for (Object followUp : followUps) {
                                    Map<String, Object> followUpMap = (Map<String, Object>)followUp;
                                    List<Object> ages = (List<Object>)followUpMap.get('responses');
                                    for (Object age : ages) {
                                        historyData.personalCancer.add(new Map<String, Object>{
                                            'age' => String.valueOf(age),
                                                'condition' => mappingData.get(key)
                                                });
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        private void processPersonalCardioHistory(Map<String, Object> groupMap, HistoryData historyData) {
            List<Object> itemConfigs = (List<Object>)groupMap.get('itemConfig');
            for (Object config : itemConfigs) {
                Map<String, Object> configMap = (Map<String, Object>)config;
                if ('cardioPersonalHistory'.equals(configMap.get('questionKey'))) {
                    List<Object> responses = (List<Object>)configMap.get('responses');
                    for (Object response : responses) {
                        Map<String, Object> responseMap = (Map<String, Object>)response;
                        if (responseMap.containsKey('followUps')) {
                            List<Object> followUps = (List<Object>)responseMap.get('followUps');
                            if (followUps != null) {
                                for (Object followUp : followUps) {
                                    Map<String, Object> followUpMap = (Map<String, Object>)followUp;
                                    List<Object> ages = (List<Object>)followUpMap.get('responses');
                                    for (Object age : ages) {
                                        historyData.personalCardio.add(new Map<String, Object>{
                                            'age' => String.valueOf(age),
                                                'condition' => mappingData.get((String)responseMap.get('key'))
                                                });
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        private void processPersonalGeneticConditions(Map<String, Object> groupMap, HistoryData historyData) {
            List<Object> itemConfigs = (List<Object>)groupMap.get('itemConfig');
            for (Object config : itemConfigs) {
                Map<String, Object> configMap = (Map<String, Object>)config;
                String questionKey = (String)configMap.get('questionKey');
                if (personalGeneticKeys.containsKey(questionKey)) {
                    String diseaseName = personalGeneticKeys.get(questionKey);
                    List<Object> responses = (List<Object>)configMap.get('responses');
                    for (Object response : responses) {
                        Map<String, Object> responseMap = (Map<String, Object>)response;
                        String key = (String)responseMap.get('key');
                        if (!'none'.equals(key) && !'doNotKnow'.equals(key) && !responseMap.containsKey('followUps')) {
                            Map<String, Object> jsonObject = new Map<String, Object>{
                                'condition' => mappingData.get(key)
                                    };
                                        if ('cancer'.equals(diseaseName)) {
                                            historyData.personalCancer.add(jsonObject);
                                        } else if ('cardio'.equals(diseaseName)) {
                                            historyData.personalCardio.add(jsonObject);
                                        } else if ('carrier'.equals(diseaseName)) {
                                            historyData.personalCarrier.add(jsonObject);
                                        }
                        }
                    }
                }
            }
        }
        
        private void processPersonalGeneticVariants(Map<String, Object> groupMap, HistoryData historyData) {
            List<Object> itemConfigs = (List<Object>)groupMap.get('itemConfig');
            for (Object config : itemConfigs) {
                Map<String, Object> configMap = (Map<String, Object>)config;
                if ('variantPersonalHistory'.equals(configMap.get('questionKey'))) {
                    List<Object> responses = (List<Object>)configMap.get('responses');
                    for (Object response : responses) {
                        Map<String, Object> responseMap = (Map<String, Object>)response;
                        String key = (String)responseMap.get('key');
                        if (variantNameDiseaseMap.containsKey(key) && !'none'.equals(key) && !'doNotKnow'.equals(key)) {
                            String diseaseType = variantNameDiseaseMap.get(key);
                            Map<String, Object> jsonObject = new Map<String, Object>{
                                'condition' => mappingData.get(key)
                                    };
                                        if ('cancer'.equals(diseaseType)) {
                                            historyData.personalCancer.add(jsonObject);
                                        } else if ('cardio'.equals(diseaseType)) {
                                            historyData.personalCardio.add(jsonObject);
                                        }
                        }
                    }
                }
            }
        }
        
        private void processFamilyCancerHistory(Map<String, Object> groupMap, HistoryData historyData) {
            List<Object> itemConfigs = (List<Object>)groupMap.get('itemConfig');
            for (Object config : itemConfigs) {
                Map<String, Object> configMap = (Map<String, Object>)config;
                if ('cancerFamilyHistory'.equals(configMap.get('questionKey'))) {
                    List<Object> responses = (List<Object>)configMap.get('responses');
                    for (Object response : responses) {
                        Map<String, Object> responseMap = (Map<String, Object>)response;
                        String key = (String)responseMap.get('key');
                        if (!'none'.equals(key) && !'doNotKnow'.equals(key)) {
                            List<Object> followUps = (List<Object>)responseMap.get('followUps');
                            for (Object followUp : followUps) {
                                Map<String, Object> followUpMap = (Map<String, Object>)followUp;
                                if (followUpMap.containsKey('relationship')) {
                                    Map<String, Object> jsonObject = new Map<String, Object>{
                                        'relationship' => String.valueOf(followUpMap.get('relationship')),
                                            'conditions' => new List<Map<String, Object>>()
                                            };
                                                Map<String, Object> condition = new Map<String, Object>{
                                                    'condition' => mappingData.get(key)
                                                        };
                                                            List<Object> subFollowUps = (List<Object>)followUpMap.get('followUps');
                                    if (subFollowUps != null && !subFollowUps.isEmpty()) {
                                        Map<String, Object> subFollowUp = (Map<String, Object>)subFollowUps[0];
                                        String ageKey = String.valueOf(subFollowUp.get('key'));
                                        condition.put('age_of_onset', 'doNotKnow'.equals(ageKey) ? 
                                                      'unknown' : String.valueOf(subFollowUp.get('value')));
                                    }
                                    ((List<Map<String, Object>>)jsonObject.get('conditions')).add(condition);
                                    historyData.familyCancer.add(jsonObject);
                                }
                            }
                        }
                    }
                }
            }
        }
        
        private void processFamilyCardioHistory(Map<String, Object> groupMap, HistoryData historyData) {
            List<Object> itemConfigs = (List<Object>)groupMap.get('itemConfig');
            for (Object config : itemConfigs) {
                Map<String, Object> configMap = (Map<String, Object>)config;
                if ('cardioFamilyHistory'.equals(configMap.get('questionKey'))) {
                    List<Object> responses = (List<Object>)configMap.get('responses');
                    for (Object response : responses) {
                        Map<String, Object> responseMap = (Map<String, Object>)response;
                        String key = (String)responseMap.get('key');
                        if (!'none'.equals(key) && !'doNotKnow'.equals(key)) {
                            String ageOfOnset = 'unknown';
                            if ('pacemakerOrDefibrillator'.equals(key) || 'heartFailureOrTransplant'.equals(key)) {
                                List<Object> followUps = (List<Object>)responseMap.get('followUps');
                                for (Object followUp : followUps) {
                                    Map<String, Object> followUpMap = (Map<String, Object>)followUp;
                                    String value = (String)followUpMap.get('value');
                                    if ('pacemakerOrDefibrillator'.equals(key)) {
                                        ageOfOnset = 'No'.equals(value) ? '51' : '49';
                                    } else if ('heartFailureOrTransplant'.equals(key)) {
                                        ageOfOnset = 'No'.equals(value) ? '61' : '59';
                                    }
                                }
                            }
                            historyData.familyCardio.add(new Map<String, Object>{
                                'relationship' => System.label.Question_Portal_RelationShip,
                                    'age' => System.label.Question_Portal_Age,
                                    'deceased' => Boolean.valueOf(System.label.Question_Portal_deceased),
                                    'conditions' => new List<Map<String, Object>>{
                                        new Map<String, Object>{
                                            'condition' => mappingData.get(key),
                                                'age_of_onset' => ageOfOnset
                                                }
                                    }
                            });
                        }
                    }
                }
            }
        }
        
        private void processFamilyGeneticConditions(Map<String, Object> groupMap, HistoryData historyData) {
            List<Object> itemConfigs = (List<Object>)groupMap.get('itemConfig');
            for (Object config : itemConfigs) {
                Map<String, Object> configMap = (Map<String, Object>)config;
                String questionKey = (String)configMap.get('questionKey');
                if ('geneticConditionFamilyHistory'.equals(questionKey)) {
                    List<Object> responses = (List<Object>)configMap.get('responses');
                    for (Object response : responses) {
                        Map<String, Object> responseMap = (Map<String, Object>)response;
                        String key = (String)responseMap.get('key');
                        if (!'none'.equals(key) && !'doNotKnow'.equals(key)) {
                            historyData.familyCarrier.add(new Map<String, Object>{
                                'relationship' => System.label.Question_Portal_RelationShip,
                                    'age' => System.label.Question_Portal_Age,
                                    'deceased' => Boolean.valueOf(System.label.Question_Portal_deceased),
                                    'conditions' => new List<Map<String, Object>>{
                                        new Map<String, Object>{
                                            'condition' => mappingData.get(key),
                                                'age_of_onset' => 'unknown'
                                                }
                                    }
                            });
                        }
                    }
                } else if ('variantFamilyHistory'.equals(questionKey)) {
                    List<Object> responses = (List<Object>)configMap.get('responses');
                    for (Object response : responses) {
                        Map<String, Object> responseMap = (Map<String, Object>)response;
                        String key = (String)responseMap.get('key');
                        if (variantNameDiseaseMap.containsKey(key) && !'none'.equals(key) && !'doNotKnow'.equals(key)) {
                            String diseaseType = variantNameDiseaseMap.get(key);
                            Map<String, Object> jsonObject = new Map<String, Object>{
                                'relationship' => 'FAMMEMB',
                                    'conditions' => new List<Map<String, Object>>{
                                        new Map<String, Object>{
                                            'condition' => mappingData.get(key),
                                                'age_of_onset' => 'unknown'
                                                }
                                    }
                            };
                                if ('cancer'.equals(diseaseType)) {
                                    historyData.familyCancer.add(jsonObject);
                                } else if ('cardio'.equals(diseaseType)) {
                                    historyData.familyCardio.add(jsonObject);
                                }
                        }
                    }
                }
            }
        }
        
        private void serializeHistoryData(HistoryData historyData, QuestionPortalHelper.OutParameters output) {
            output.reasonForTesting = historyData.reasonForTesting;
            output.consentToProcess = historyData.consentToProcess;
            output.consentToBank = historyData.consentToBank;
            output.consentToResearch = historyData.consentToResearch;
            
            output.cancerPersonalHistory = serializeList(historyData.personalCancer);
            output.cardioPersonalHistory = serializeList(historyData.personalCardio);
            output.carrierPersonalHistory = serializeList(historyData.personalCarrier);
            output.cancerFamilyHistory = serializeList(historyData.familyCancer);
            output.cardioFamilyHistory = serializeList(historyData.familyCardio);
            output.carrierFamilyHistory = serializeList(historyData.familyCarrier);
        }
        
        private String serializeList(List<Map<String, Object>> data) {
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartArray();
            for (Map<String, Object> item : data) {
                gen.writeObject(item);
            }
            gen.writeEndArray();
            return gen.getAsString();
        }
    }
    
    // Helper class for history data
    public class HistoryData {
        public String reasonForTesting;
        public String consentToProcess;
        public String consentToBank;
        public String consentToResearch;
        public List<Map<String, Object>> personalCancer = new List<Map<String, Object>>();
        public List<Map<String, Object>> personalCardio = new List<Map<String, Object>>();
        public List<Map<String, Object>> personalCarrier = new List<Map<String, Object>>();
        public List<Map<String, Object>> familyCancer = new List<Map<String, Object>>();
        public List<Map<String, Object>> familyCardio = new List<Map<String, Object>>();
        public List<Map<String, Object>> familyCarrier = new List<Map<String, Object>>();
    }
    
}