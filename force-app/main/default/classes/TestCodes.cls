/**
 * Wrapper class for Test Codes JSON structure stored in Commerce_Order_Info__c.Test_Codes__c
 * The field contains a JSON string that needs to be deserialized twice.
 */
global class TestCodes {
    public String Code;
    public String Name;
    public String testType;
    public Boolean isService;

    /**
     * Deserializes Test Codes from Commerce_Order_Info__c.Test_Codes__c field
     * The field contains a JSON string that needs to be deserialized twice.
     * 
     * @param testCodesJson The JSON string from Test_Codes__c field
     * @return List of TestCodes objects, or empty list if parsing fails
     */
    global static List<TestCodes> parse(String testCodesJson) {
        System.debug('[TestCodes] parse called with testCodesJson length: ' + (testCodesJson != null ? testCodesJson.length() : 0));
        System.debug('[TestCodes] parse testCodesJson (first 200 chars): ' + (testCodesJson != null && testCodesJson.length() > 0 ? testCodesJson.substring(0, Math.min(200, testCodesJson.length())) : 'null or empty'));
        
        if (String.isBlank(testCodesJson)) {
            System.debug('[TestCodes] parse: testCodesJson is blank, returning empty list');
            return new List<TestCodes>();
        }

        try {
            // The field contains a JSON string that needs to be deserialized twice
            System.debug('[TestCodes] parse: First deserialization...');
            String jsonString = (String)JSON.deserialize(testCodesJson, String.class);
            System.debug('[TestCodes] parse: First deserialization result length: ' + jsonString.length());
            System.debug('[TestCodes] parse: First deserialization result (first 200 chars): ' + jsonString.substring(0, Math.min(200, jsonString.length())));
            
            System.debug('[TestCodes] parse: Second deserialization to List<TestCodes>...');
            List<TestCodes> result = (List<TestCodes>) JSON.deserialize(jsonString, List<TestCodes>.class);
            System.debug('[TestCodes] parse: Successfully parsed ' + result.size() + ' test code(s)');
            for (Integer i = 0; i < result.size(); i++) {
                System.debug('[TestCodes] parse: Test[' + i + '] Code=' + result[i].Code + ', Name=' + result[i].Name + ', testType=' + result[i].testType);
            }
            return result;
        } catch (Exception e) {
            System.debug('[TestCodes] parse: Error deserializing Test Codes JSON: ' + e.getMessage());
            System.debug('[TestCodes] parse: Exception type: ' + e.getTypeName());
            System.debug('[TestCodes] parse: Exception stack trace: ' + e.getStackTraceString());
            return new List<TestCodes>();
        }
    }

    /**
     * Serializes a list of TestCodes to the format expected by Commerce_Order_Info__c.Test_Codes__c
     * 
     * @param testCodes List of TestCodes to serialize
     * @return JSON string in the format expected by the field
     */
    global static String stringify(List<TestCodes> testCodes) {
        if (testCodes == null || testCodes.isEmpty()) {
            return null;
        }

        try {
            String jsonString = JSON.serialize(testCodes);
            return JSON.serialize(jsonString);
        } catch (Exception e) {
            System.debug('Error serializing Test Codes JSON: ' + e.getMessage());
            return null;
        }
    }

    /**
     * Checks if this test code represents a minor product.
     * Minor products have codes ending in "-mXX" where XX is the minimum age (e.g., "-m06", "-m10", "-m13")
     * or codes ending in "-min" (e.g., "5616-min").
     * 
     * @return true if the code matches the minor product pattern
     */
    public Boolean isMinorProduct() {
        System.debug('[TestCodes] isMinorProduct called for Code: ' + this.Code);
        
        if (String.isBlank(this.Code)) {
            System.debug('[TestCodes] isMinorProduct: Code is blank, returning false');
            return false;
        }
        
        Pattern minorPattern = Pattern.compile('(-m\\d{2}|-min)$');
        Matcher matcher = minorPattern.matcher(this.Code);
        Boolean result = matcher.find();
        System.debug('[TestCodes] isMinorProduct: Pattern match result for "' + this.Code + '": ' + result);
        return result;
    }
}