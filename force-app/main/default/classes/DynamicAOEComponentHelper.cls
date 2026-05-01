public without sharing class DynamicAOEComponentHelper {
    @AuraEnabled
    public static Map<String, String> insertTesterAoeRecords(String questionsJson, String optionsJson, String responsesJson, String testerId, List<Id> productAoeIds) {
        List<Tester_Details_AOE__c> testerAoeRecords = new List<Tester_Details_AOE__c>();
        
        // Debug the raw input
        System.debug('Raw questionsJson: ' + questionsJson);
        System.debug('Raw optionsJson: ' + optionsJson);

        // Delete existing records for the given testerId
        if (String.isNotBlank(testerId)) {
            try {
                List<Tester_Details_AOE__c> existingRecords = [SELECT Id 
                                                              FROM Tester_Details_AOE__c 
                                                              WHERE Tester_Detail_Id__c = :testerId 
                                                              WITH SECURITY_ENFORCED];
                if (!existingRecords.isEmpty()) {
                    delete as system existingRecords;
                    System.debug('Deleted ' + existingRecords.size() + ' existing records for testerId: ' + testerId);
                }
            } catch (DmlException e) {
                System.debug('Error deleting existing records: ' + e.getMessage());
                throw new AuraHandledException('Error deleting existing records: ' + e.getMessage());
            }
        }

        // Deserialize JSON into lists
        List<Object> questionsList = (List<Object>)JSON.deserializeUntyped(questionsJson);
        Map<String, Map<String, Object>> questionsMap = new Map<String, Map<String, Object>>();
        for (Object obj : questionsList) {
            try {
                Map<String, Object> q = (Map<String, Object>)obj;
                Object idObj = q.get('Id');
                if (idObj != null) {
                    String questionId = (String)idObj;
                    questionsMap.put(questionId, q);
                } else {
                    System.debug('Skipping object due to null Id: ' + JSON.serialize(q));
                }
            } catch (Exception e) {
                System.debug('Error processing question object: ' + JSON.serialize(obj) + ' Exception: ' + e.getMessage());
                continue; // Skip invalid objects
            }
        }

        List<Object> optionsList = (List<Object>)JSON.deserializeUntyped(optionsJson);
        Map<String, Map<String, Object>> optionsMap = new Map<String, Map<String, Object>>();
        for (Object obj : optionsList) {
            try {
                Map<String, Object> opt = (Map<String, Object>)obj;
                Object idObj = opt.get('Id');
                if (idObj != null) {
                    String optionId = (String)idObj;
                    optionsMap.put(optionId, opt);
                } else {
                    System.debug('Skipping object due to null Id: ' + JSON.serialize(opt));
                }
            } catch (Exception e) {
                System.debug('Error processing option object: ' + JSON.serialize(obj) + ' Exception: ' + e.getMessage());
                continue; // Skip invalid objects
            }
        }

        Map<String, Object> responsesMap = (Map<String, Object>)JSON.deserializeUntyped(responsesJson);
        
        // Build product code map from question data - this ensures each question gets its correct product code
        // even if multiple products share the same Product_AOE__c question
        Map<Id, String> productCodeMap = new Map<Id, String>();
        for (Map<String, Object> q : questionsMap.values()) {
            String questionId = (String)q.get('Id');
            if (questionId != null) {
                // Extract product code from Product__r.ProductCode nested object
                String productCode = null;
                Object productObj = q.get('Product__r');
                if (productObj != null && productObj instanceof Map<String, Object>) {
                    Map<String, Object> productMap = (Map<String, Object>)productObj;
                    productCode = (String)productMap.get('ProductCode');
                }
                // Fallback to getProductCodes if Product__r.ProductCode is not available
                if (String.isBlank(productCode)) {
                    Map<Id, String> fallbackMap = getProductCodes(new List<Id>{ (Id)questionId });
                    productCode = fallbackMap.get((Id)questionId);
                }
                if (String.isNotBlank(productCode)) {
                    productCodeMap.put((Id)questionId, productCode);
                } else {
                    productCodeMap.put((Id)questionId, 'N/A');
                }
            }
        }

        // Build a map of option values (Id or Option_Code__c) to option records for lookup
        Map<String, Map<String, Object>> optionValueMap = new Map<String, Map<String, Object>>();
        for (Map<String, Object> opt : optionsMap.values()) {
            String id = (String)opt.get('Id');
            String optionCode = (String)opt.get('Option_Code__c');
            if (id != null) optionValueMap.put(id, opt);
            if (optionCode != null) optionValueMap.put(optionCode, opt);
        }

        // Process responses and create records
        for (String questionId : responsesMap.keySet()) {
            Map<String, Object> question = questionsMap.get(questionId);
            if (question == null) {
                System.debug('Question not found for questionId: ' + questionId);
                continue;
            }
            Object response = responsesMap.get(questionId);
            Boolean isMultiSelect = (String)question.get('Option_Type__c') == 'MULTISELECT';
            
            // Get product code for this specific question
            String productCode = productCodeMap.get((Id)questionId);
            if (String.isBlank(productCode)) {
                productCode = 'N/A';
            }

            if (isMultiSelect && response instanceof List<Object>) {
                for (Object optionValue : (List<Object>)response) {
                    String optionId = (String)optionValue;
                    Map<String, Object> option = optionValueMap.get(optionId);
                    if (option != null) {
                        testerAoeRecords.add(createTesterAoeRecord(questionId, (String)option.get('Id'), testerId, productCode));
                    }
                }
            } else {
                String optionId = (String)response;
                Map<String, Object> option = optionValueMap.get(optionId);
                if (option != null) {
                    testerAoeRecords.add(createTesterAoeRecord(questionId, (String)option.get('Id'), testerId, productCode));
                }
            }
        }

        try {
            if (!testerAoeRecords.isEmpty()) {
                insert as system testerAoeRecords;
                // Return a map of questionId to Product_Code__c
                Map<String, String> resultMap = new Map<String, String>();
                for (Tester_Details_AOE__c record : testerAoeRecords) {
                    resultMap.put(record.Product_AOE__c, record.Product_Code__c);
                }
                return resultMap;
            }
            return new Map<String, String>(); // Empty map if no records inserted
        } catch (DmlException e) {
            throw new AuraHandledException('Error inserting records: ' + e.getMessage());
        }
    }

    private static Tester_Details_AOE__c createTesterAoeRecord(String productAoeId, String productAoeOptionId, String testerId, String productCode) {
        return new Tester_Details_AOE__c(
            Product_AOE__c = (Id)productAoeId,
            Product_AOE_Option__c = (Id)productAoeOptionId,
            Tester_Detail_Id__c = testerId,
            Product_Code__c = productCode != null ? productCode : 'N/A'
        );
    }

    @AuraEnabled(cacheable=true)
    public static Map<Id, String> getProductCodes(List<Id> productAoeIds) {
        Map<Id, String> productCodeMap = new Map<Id, String>();
        if (productAoeIds == null || productAoeIds.isEmpty()) {
            return productCodeMap;
        }

        List<Product_AOE__c> productAoes = [SELECT Id, Product__c, Product__r.ProductCode 
                                           FROM Product_AOE__c 
                                           WHERE Id IN :productAoeIds 
                                           ];
        
        for (Product_AOE__c pAoe : productAoes) {
            if (pAoe.Product__c != null && pAoe.Product__r?.ProductCode != null) {
                productCodeMap.put(pAoe.Id, pAoe.Product__r.ProductCode);
            } else {
                productCodeMap.put(pAoe.Id, 'N/A');
            }
        }
        return productCodeMap;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getAoeQuestionsAndOptions(String productIds) {
        List<String> productIdList = productIds.split(',');

        // Split the incoming product codes
        List<String> productCodeList = productIds.split(',');
        // Normalize product codes to handle case sensitivity and trim spaces
        Set<String> productCodeSet = new Set<String>();
        for (String code : productCodeList) {
            productCodeSet.add(code.trim().toUpperCase());
        }

        // Query Product2 to get IDs corresponding to the product codes
        List<Product2> products = [
            SELECT Id
            FROM Product2
            WHERE ProductCode IN :productCodeSet
        ];
        // Extract Product2 IDs
        Set<Id> productIdSet = new Set<Id>();
        for (Product2 prod : products) {
            productIdSet.add(prod.Id);
        }

        List<Product_AOE__c> questions = [
            SELECT Id, Question__c, Option_Type__c, Expected_Answer__c, Error_Message__c, Product__c, Product__r.ProductCode, Link_URL__c
            FROM Product_AOE__c
            WHERE Product__c IN :productIdSet AND Option_Type__c != 'SYSTEM'
        ];
        List<Product_AOE_Option__c> options = [
            SELECT Id, Product_AOE__c, Display_Name__c, Option_Code__c
            FROM Product_AOE_Option__c
            WHERE Product_AOE__r.Product__c IN :productIdSet AND Product_AOE__r.Option_Type__c != 'SYSTEM'
        ];
        return new Map<String, String>{
            'questions' => JSON.serialize(questions),
            'options' => JSON.serialize(options)
        };
    }
}