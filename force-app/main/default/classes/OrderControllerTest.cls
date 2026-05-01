@IsTest
private class OrderControllerTest {
    static Order createOrderWithItems(Boolean isMinor) {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Id standardPricebookId = Test.getStandardPricebookId();

        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbe;

        OrderDeliveryMethod odm = new OrderDeliveryMethod(Name = 'Standard Shipping');
        insert odm;

        Order order = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = standardPricebookId,
            Minor_Order__c = isMinor
        );
        insert order;

        OrderDeliveryGroup odg = new OrderDeliveryGroup(
            OrderId = order.Id,
            DeliverToName = acc.Name,
            OrderDeliveryMethodId = odm.Id
        );
        insert odg;

        OrderItem oi = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = pbe.Id,
            OrderDeliveryGroupId = odg.Id,
            Quantity = 1,
            UnitPrice = 100.00
        );
        insert oi;

        order.Status = 'Activated';
        update order;

        return order;
    }

    @IsTest
    static void testIsMinorOrder_True() {
        // Create Commerce_Order_Info__c with minor product code
        List<TestCodes> testCodesList = new List<TestCodes>();
        TestCodes tc1 = new TestCodes();
        tc1.Code = '94366-m13';
        tc1.Name = 'Celiac Disease Panel';
        tc1.testType = 'PSC';
        tc1.isService = false;
        testCodesList.add(tc1);
        
        String jsonString = JSON.serialize(testCodesList);
        String doubleSerialized = JSON.serialize(jsonString);
        
        Commerce_Order_Info__c coi = new Commerce_Order_Info__c(
            Order_Number__c = 'TEST-MINOR-001',
            Test_Codes__c = doubleSerialized,
            First_Name__c = 'Test',
            Last_Name__c = 'User',
            Email__c = 'test@example.com',
            Address_Line_1__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'NY',
            Postal_Code__c = '12345',
            Phone_Number__c = '1234567890'
        );
        insert coi;
        
        Test.startTest();
        Boolean result = OrderController.isMinorOrder('TEST-MINOR-001');
        Test.stopTest();

        System.assertEquals(true, result, 'Should return true for minor order');
    }

    @IsTest
    static void testIsMinorOrder_False() {
        // Create Commerce_Order_Info__c without minor product code
        List<TestCodes> testCodesList = new List<TestCodes>();
        TestCodes tc1 = new TestCodes();
        tc1.Code = '94366';
        tc1.Name = 'Regular Test';
        tc1.testType = 'PSC';
        tc1.isService = false;
        testCodesList.add(tc1);
        
        String jsonString = JSON.serialize(testCodesList);
        String doubleSerialized = JSON.serialize(jsonString);
        
        Commerce_Order_Info__c coi = new Commerce_Order_Info__c(
            Order_Number__c = 'TEST-NON-MINOR-001',
            Test_Codes__c = doubleSerialized,
            First_Name__c = 'Test',
            Last_Name__c = 'User',
            Email__c = 'test@example.com',
            Address_Line_1__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'NY',
            Postal_Code__c = '12345',
            Phone_Number__c = '1234567890'
        );
        insert coi;

        Test.startTest();
        Boolean result = OrderController.isMinorOrder('TEST-NON-MINOR-001');
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false for non-minor order');
    }

    @IsTest
    static void testIsMinorOrder_BlankOrderNumber() {
        Test.startTest();
        Boolean result = OrderController.isMinorOrder('');
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false for blank order number');
    }

    @IsTest
    static void testIsMinorOrder_NonExistentOrder() {
        Test.startTest();
        Boolean result = OrderController.isMinorOrder('NON-EXISTENT-ORDER');
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false for non-existent order');
    }
}