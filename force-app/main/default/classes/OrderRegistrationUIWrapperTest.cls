@IsTest
private class OrderRegistrationUIWrapperTest {
    
    @IsTest
    static void testEmptyConstructor() {
        Test.startTest();
        OrderRegistrationUIWrapper wrapper = new OrderRegistrationUIWrapper();
        Test.stopTest();
    }
    
    @IsTest
    static void testConstructorWithEmptyItems() {
        List<FulfillmentOrderLineItem> items = new List<FulfillmentOrderLineItem>();
        Test.startTest();
        OrderRegistrationUIWrapper wrapper = new OrderRegistrationUIWrapper(items);
        Test.stopTest();
    }
    
    @IsTest
    static void testConstructorWithEmptyItemsAndMinorTrue() {
        List<FulfillmentOrderLineItem> items = new List<FulfillmentOrderLineItem>();
        Test.startTest();
        OrderRegistrationUIWrapper wrapper = new OrderRegistrationUIWrapper(items, true);
        Test.stopTest();
    }
    
    @IsTest
    static void testConstructorWithEmptyItemsAndMinorFalse() {
        List<FulfillmentOrderLineItem> items = new List<FulfillmentOrderLineItem>();
        Test.startTest();
        OrderRegistrationUIWrapper wrapper = new OrderRegistrationUIWrapper(items, false);
        Test.stopTest();
    }
    
    @IsTest
    static void testConstructorWithCommerceOrderInfo_BlankTestCodes() {
        Commerce_Order_Info__c coi = new Commerce_Order_Info__c(
            Order_Number__c = 'ORD-001',
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Email__c = 'test@test.com',
            Address_Line_1__c = '123 St',
            City__c = 'City',
            State__c = 'NY',
            Postal_Code__c = '12345',
            Phone_number__c = '555-1234',
            Test_Codes__c = null
        );
        insert coi;
        Test.startTest();
        OrderRegistrationUIWrapper wrapper = new OrderRegistrationUIWrapper(coi);
        Test.stopTest();
    }
    
    @IsTest
    static void testConstructorWithCommerceOrderInfo_EmptyTestCodes() {
        Commerce_Order_Info__c coi = new Commerce_Order_Info__c(
            Order_Number__c = 'ORD-002',
            First_Name__c = 'Jane',
            Last_Name__c = 'Smith',
            Email__c = 'test2@test.com',
            Address_Line_1__c = '456 Ave',
            City__c = 'City2',
            State__c = 'CA',
            Postal_Code__c = '90210',
            Phone_number__c = '555-5678',
            Test_Codes__c = ''
        );
        insert coi;
        Test.startTest();
        OrderRegistrationUIWrapper wrapper = new OrderRegistrationUIWrapper(coi);
        Test.stopTest();
    }
    
    @IsTest
    static void testConstructorWithCommerceOrderInfo_WithProducts() {
        Product2 prod1 = new Product2(
            Name = 'Product 1',
            ProductCode = 'PSC-001',
            AOE_required__c = true,
            Gender__c = 'Male',
            Excluded_State_codes__c = 'NY',
            Max_age__c = '65',
            Min_age__c = '18',
            Exclude_from_registration__c = false
        );
        Product2 prod2 = new Product2(
            Name = 'Product 2',
            ProductCode = 'ATH-002',
            AOE_required__c = false,
            Gender__c = 'Female',
            Excluded_State_codes__c = 'CA',
            Max_age__c = '50',
            Min_age__c = '21',
            Exclude_from_registration__c = true
        );
        Product2 prod3 = new Product2(
            Name = 'Product 3',
            ProductCode = 'PKH-003',
            AOE_required__c = true,
            Gender__c = 'Both',
            Excluded_State_codes__c = 'OK',
            Max_age__c = '99',
            Min_age__c = '0',
            Exclude_from_registration__c = false
        );
        insert new List<Product2>{prod1, prod2, prod3};
        
        List<TestCodes> testCodesList = new List<TestCodes>();
        TestCodes tc1 = new TestCodes();
        tc1.Code = 'PSC-001';
        tc1.Name = 'Product 1';
        tc1.testType = 'PSC';
        tc1.isService = false;
        testCodesList.add(tc1);
        
        TestCodes tc2 = new TestCodes();
        tc2.Code = 'ATH-002';
        tc2.Name = 'Product 2';
        tc2.testType = 'at_home';
        tc2.isService = true;
        testCodesList.add(tc2);
        
        TestCodes tc3 = new TestCodes();
        tc3.Code = 'PKH-003';
        tc3.Name = 'Product 3';
        tc3.testType = 'PackHealth';
        tc3.isService = false;
        testCodesList.add(tc3);
        
        String testCodesJson = TestCodes.stringify(testCodesList);
        
        Commerce_Order_Info__c coi = new Commerce_Order_Info__c(
            Order_Number__c = 'ORD-003',
            First_Name__c = 'Bob',
            Last_Name__c = 'Jones',
            Email__c = 'bob@test.com',
            Address_Line_1__c = '789 Blvd',
            Address_Line_2__c = 'Suite 1',
            City__c = 'City3',
            State__c = 'TX',
            Postal_Code__c = '75001',
            Phone_number__c = '555-9999',
            Test_Codes__c = testCodesJson
        );
        insert coi;
        Test.startTest();
        OrderRegistrationUIWrapper wrapper = new OrderRegistrationUIWrapper(coi);
        Test.stopTest();
    }
    
    @IsTest
    static void testConstructorWithCommerceOrderInfo_InvalidTestType() {
        Product2 prod = new Product2(
            Name = 'Product',
            ProductCode = 'INV-001',
            AOE_required__c = false
        );
        insert prod;
        
        List<TestCodes> testCodesList = new List<TestCodes>();
        TestCodes tc = new TestCodes();
        tc.Code = 'INV-001';
        tc.Name = 'Product';
        tc.testType = 'invalid';
        tc.isService = false;
        testCodesList.add(tc);
        
        String testCodesJson = TestCodes.stringify(testCodesList);
        
        Commerce_Order_Info__c coi = new Commerce_Order_Info__c(
            Order_Number__c = 'ORD-004',
            First_Name__c = 'Test',
            Last_Name__c = 'User',
            Email__c = 'test@test.com',
            Address_Line_1__c = '111 St',
            City__c = 'City',
            State__c = 'NY',
            Postal_Code__c = '12345',
            Phone_number__c = '555-0000',
            Test_Codes__c = testCodesJson
        );
        insert coi;
        Test.startTest();
        OrderRegistrationUIWrapper wrapper = new OrderRegistrationUIWrapper(coi);
        Test.stopTest();
    }
    
    @IsTest
    static void testConstructorWithCommerceOrderInfo_MixedTestTypes() {
        Product2 prod1 = new Product2(
            Name = 'Valid Product',
            ProductCode = 'VALID-001',
            AOE_required__c = true
        );
        insert prod1;
        
        List<TestCodes> testCodesList = new List<TestCodes>();
        TestCodes tc1 = new TestCodes();
        tc1.Code = 'VALID-001';
        tc1.Name = 'Valid Product';
        tc1.testType = 'PSC';
        tc1.isService = false;
        testCodesList.add(tc1);
        
        TestCodes tc2 = new TestCodes();
        tc2.Code = 'VALID-001';
        tc2.Name = 'Valid Product';
        tc2.testType = 'invalid';
        tc2.isService = false;
        testCodesList.add(tc2);
        
        String testCodesJson = TestCodes.stringify(testCodesList);
        
        Commerce_Order_Info__c coi = new Commerce_Order_Info__c(
            Order_Number__c = 'ORD-005',
            First_Name__c = 'Mixed',
            Last_Name__c = 'Test',
            Email__c = 'mixed@test.com',
            Address_Line_1__c = '222 St',
            City__c = 'City',
            State__c = 'CA',
            Postal_Code__c = '90210',
            Phone_number__c = '555-1111',
            Test_Codes__c = testCodesJson
        );
        insert coi;
        Test.startTest();
        OrderRegistrationUIWrapper wrapper = new OrderRegistrationUIWrapper(coi);
        Test.stopTest();
    }
    
    @IsTest(SeeAllData=true)
    static void testConstructorWithFulfillmentOrderLineItems() {
        List<FulfillmentOrderLineItem> items = [
            SELECT Id, Description, Test_Type__c, FulfillmentOrder.Record_Type__c, 
                   FulfillmentOrder.OrderExpirationDate__c, FulfillmentOrder.Status,
                   FulfillmentOrderId, FulfillmentOrder.OrderSummary.OrderedDate, 
                   FulfillmentOrder.OrderSummary.OrderNumber, Is_Registered__c,
                   Product2.AOE_required__c, Product2.Gender__c, Product2.Exclude_from_registration__c, 
                   Product2.Excluded_State_codes__c, Product2.Max_age__c, Product2.Min_age__c,
                   Product2.ProductCode, FulfillmentOrder.OrderSummaryId, ProductName__c,
                   FulfillmentOrder.OrderSummary.BillingAddressLine1__c,
                   FulfillmentOrder.OrderSummary.BillingAddressLine2__c,
                   FulfillmentOrder.OrderSummary.BillingCity,
                   FulfillmentOrder.OrderSummary.BillingCountry,
                   FulfillmentOrder.OrderSummary.BillingPostalCode,
                   FulfillmentOrder.OrderSummary.BillingState,
                   FulfillmentOrder.OrderSummary.BillingPhoneNumber,
                   FulfillmentOrder.OrderSummary.BillingEmailAddress,
                   FulfillmentOrder.FirstName__c, FulfillmentOrder.LastName__c,
                   Is_Service__c
            FROM FulfillmentOrderLineItem
            LIMIT 10
        ];
        Test.startTest();
        OrderRegistrationUIWrapper wrapper = new OrderRegistrationUIWrapper(items);
        Test.stopTest();
    }
    
    @IsTest(SeeAllData=true)
    static void testConstructorWithFulfillmentOrderLineItemsAndMinor() {
        List<FulfillmentOrderLineItem> items = [
            SELECT Id, Description, Test_Type__c, FulfillmentOrder.Record_Type__c, 
                   FulfillmentOrder.OrderExpirationDate__c, FulfillmentOrder.Status,
                   FulfillmentOrderId, FulfillmentOrder.OrderSummary.OrderedDate, 
                   FulfillmentOrder.OrderSummary.OrderNumber, Is_Registered__c,
                   Product2.AOE_required__c, Product2.Gender__c, Product2.Exclude_from_registration__c, 
                   Product2.Excluded_State_codes__c, Product2.Max_age__c, Product2.Min_age__c,
                   Product2.ProductCode, FulfillmentOrder.OrderSummaryId, ProductName__c,
                   FulfillmentOrder.OrderSummary.BillingAddressLine1__c,
                   FulfillmentOrder.OrderSummary.BillingAddressLine2__c,
                   FulfillmentOrder.OrderSummary.BillingCity,
                   FulfillmentOrder.OrderSummary.BillingCountry,
                   FulfillmentOrder.OrderSummary.BillingPostalCode,
                   FulfillmentOrder.OrderSummary.BillingState,
                   FulfillmentOrder.OrderSummary.BillingPhoneNumber,
                   FulfillmentOrder.OrderSummary.BillingEmailAddress,
                   FulfillmentOrder.FirstName__c, FulfillmentOrder.LastName__c,
                   Is_Service__c
            FROM FulfillmentOrderLineItem
            LIMIT 10
        ];
        Test.startTest();
        OrderRegistrationUIWrapper wrapper = new OrderRegistrationUIWrapper(items, true);
        Test.stopTest();
    }
    
    @IsTest(SeeAllData=true)
    static void testConstructorWithFulfillmentOrderLineItemsMultipleFOs() {
        List<FulfillmentOrderLineItem> items = [
            SELECT Id, Description, Test_Type__c, FulfillmentOrder.Record_Type__c, 
                   FulfillmentOrder.OrderExpirationDate__c, FulfillmentOrder.Status,
                   FulfillmentOrderId, FulfillmentOrder.OrderSummary.OrderedDate, 
                   FulfillmentOrder.OrderSummary.OrderNumber, Is_Registered__c,
                   Product2.AOE_required__c, Product2.Gender__c, Product2.Exclude_from_registration__c, 
                   Product2.Excluded_State_codes__c, Product2.Max_age__c, Product2.Min_age__c,
                   Product2.ProductCode, FulfillmentOrder.OrderSummaryId, ProductName__c,
                   FulfillmentOrder.OrderSummary.BillingAddressLine1__c,
                   FulfillmentOrder.OrderSummary.BillingAddressLine2__c,
                   FulfillmentOrder.OrderSummary.BillingCity,
                   FulfillmentOrder.OrderSummary.BillingCountry,
                   FulfillmentOrder.OrderSummary.BillingPostalCode,
                   FulfillmentOrder.OrderSummary.BillingState,
                   FulfillmentOrder.OrderSummary.BillingPhoneNumber,
                   FulfillmentOrder.OrderSummary.BillingEmailAddress,
                   FulfillmentOrder.FirstName__c, FulfillmentOrder.LastName__c,
                   Is_Service__c
            FROM FulfillmentOrderLineItem
            LIMIT 20
        ];
        Test.startTest();
        OrderRegistrationUIWrapper wrapper = new OrderRegistrationUIWrapper(items);
        Test.stopTest();
    }
}