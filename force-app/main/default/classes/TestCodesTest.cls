@IsTest
private class TestCodesTest {
    
    @IsTest
    static void testDeserialize_ValidJson() {
        // Create test data in the format expected by Commerce_Order_Info__c.Test_Codes__c
        List<TestCodes> testCodesList = new List<TestCodes>();
        TestCodes tc1 = new TestCodes();
        tc1.Code = 'TEST-001';
        tc1.Name = 'Test Product 1';
        tc1.testType = 'PSC';
        tc1.isService = false;
        testCodesList.add(tc1);
        
        TestCodes tc2 = new TestCodes();
        tc2.Code = 'TEST-002-m06';
        tc2.Name = 'Minor Test Product';
        tc2.testType = 'at_home';
        tc2.isService = false;
        testCodesList.add(tc2);
        
        String jsonString = JSON.serialize(testCodesList);
        String doubleSerialized = JSON.serialize(jsonString);
        
        Test.startTest();
        List<TestCodes> result = TestCodes.parse(doubleSerialized);
        Test.stopTest();
        
        System.assertEquals(2, result.size(), 'Should deserialize 2 test codes');
        System.assertEquals('TEST-001', result[0].Code, 'First code should match');
        System.assertEquals('Test Product 1', result[0].Name, 'First name should match');
        System.assertEquals('PSC', result[0].testType, 'First test type should match');
        System.assertEquals(false, result[0].isService, 'First isService should match');
        
        System.assertEquals('TEST-002-m06', result[1].Code, 'Second code should match');
        System.assertEquals('Minor Test Product', result[1].Name, 'Second name should match');
    }
    
    @IsTest
    static void testDeserialize_BlankString() {
        Test.startTest();
        List<TestCodes> result = TestCodes.parse('');
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty list for blank string');
    }
    
    @IsTest
    static void testDeserialize_NullString() {
        Test.startTest();
        List<TestCodes> result = TestCodes.parse(null);
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty list for null string');
    }
    
    @IsTest
    static void testDeserialize_InvalidJson() {
        String invalidJson = 'not valid json';
        
        Test.startTest();
        List<TestCodes> result = TestCodes.parse(invalidJson);
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty list for invalid JSON');
    }
    
    @IsTest
    static void testSerialize_ValidList() {
        List<TestCodes> testCodesList = new List<TestCodes>();
        TestCodes tc1 = new TestCodes();
        tc1.Code = 'TEST-001';
        tc1.Name = 'Test Product';
        tc1.testType = 'PSC';
        tc1.isService = false;
        testCodesList.add(tc1);
        
        Test.startTest();
        String result = TestCodes.stringify(testCodesList);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return serialized string');
        System.assert(result.contains('TEST-001'), 'Should contain test code');
        
        // Verify it can be deserialized back
        List<TestCodes> deserialized = TestCodes.parse(result);
        System.assertEquals(1, deserialized.size(), 'Should deserialize back to 1 item');
        System.assertEquals('TEST-001', deserialized[0].Code, 'Code should match after round trip');
    }
    
    @IsTest
    static void testSerialize_EmptyList() {
        List<TestCodes> testCodesList = new List<TestCodes>();
        
        Test.startTest();
        String result = TestCodes.stringify(testCodesList);
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null for empty list');
    }
    
    @IsTest
    static void testSerialize_NullList() {
        Test.startTest();
        String result = TestCodes.stringify(null);
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null for null list');
    }
    
    @IsTest
    static void testIsMinorProduct_WithMinorCode() {
        TestCodes tc = new TestCodes();
        tc.Code = 'TEST-001-m06';
        tc.Name = 'Minor Product';
        tc.testType = 'PSC';
        tc.isService = false;
        
        Test.startTest();
        Boolean result = tc.isMinorProduct();
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should return true for minor product code ending in -m06');
    }
    
    @IsTest
    static void testIsMinorProduct_WithDifferentMinorAges() {
        List<String> minorCodes = new List<String>{'TEST-m06', 'TEST-m10', 'TEST-m13', 'PROD-ABC-m18', 'XYZ-m21'};
        
        Test.startTest();
        for (String code : minorCodes) {
            TestCodes tc = new TestCodes();
            tc.Code = code;
            Boolean result = tc.isMinorProduct();
            System.assertEquals(true, result, 'Should return true for minor product code: ' + code);
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testIsMinorProduct_WithNonMinorCode() {
        TestCodes tc = new TestCodes();
        tc.Code = 'TEST-001';
        tc.Name = 'Regular Product';
        tc.testType = 'PSC';
        tc.isService = false;
        
        Test.startTest();
        Boolean result = tc.isMinorProduct();
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false for non-minor product code');
    }
    
    @IsTest
    static void testIsMinorProduct_WithBlankCode() {
        TestCodes tc = new TestCodes();
        tc.Code = '';
        tc.Name = 'Product';
        
        Test.startTest();
        Boolean result = tc.isMinorProduct();
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false for blank code');
    }
    
    @IsTest
    static void testIsMinorProduct_WithNullCode() {
        TestCodes tc = new TestCodes();
        tc.Code = null;
        tc.Name = 'Product';
        
        Test.startTest();
        Boolean result = tc.isMinorProduct();
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false for null code');
    }
    
    @IsTest
    static void testIsMinorProduct_WithCodeContainingButNotEndingWithPattern() {
        TestCodes tc = new TestCodes();
        tc.Code = 'TEST-m06-EXTRA';
        tc.Name = 'Product';
        
        Test.startTest();
        Boolean result = tc.isMinorProduct();
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false when pattern is not at the end');
    }
    
    @IsTest
    static void testRoundTrip_SerializeAndDeserialize() {
        List<TestCodes> original = new List<TestCodes>();
        
        TestCodes tc1 = new TestCodes();
        tc1.Code = 'TEST-001';
        tc1.Name = 'Test Product 1';
        tc1.testType = 'PSC';
        tc1.isService = false;
        original.add(tc1);
        
        TestCodes tc2 = new TestCodes();
        tc2.Code = 'TEST-002-m10';
        tc2.Name = 'Minor Product';
        tc2.testType = 'at_home';
        tc2.isService = true;
        original.add(tc2);
        
        Test.startTest();
        String serialized = TestCodes.stringify(original);
        List<TestCodes> deserialized = TestCodes.parse(serialized);
        Test.stopTest();
        
        System.assertEquals(2, deserialized.size(), 'Should maintain 2 items through round trip');
        System.assertEquals(original[0].Code, deserialized[0].Code, 'First code should match');
        System.assertEquals(original[0].Name, deserialized[0].Name, 'First name should match');
        System.assertEquals(original[1].Code, deserialized[1].Code, 'Second code should match');
        System.assertEquals(original[1].Name, deserialized[1].Name, 'Second name should match');
        System.assertEquals(original[1].isService, deserialized[1].isService, 'Second isService should match');
    }
}