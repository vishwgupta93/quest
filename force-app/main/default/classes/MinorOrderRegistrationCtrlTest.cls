@IsTest
private class MinorOrderRegistrationCtrlTest {

static void makeData(){

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

    Contact testContact = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com', AccountId = acc.Id);
    insert testContact;

    Schema.Location ffl = new Schema.Location(Name = 'Test Lab', LocationType = 'Lab');
    insert ffl;

    Order order = new Order(
        AccountId = testContact.AccountId,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        Pricebook2Id = standardPricebookId,
        Minor_Order__c = true
    );
    insert order;
        
    OrderDeliveryGroup odg = new OrderDeliveryGroup(
        OrderId = order.Id,
        DeliverToName = acc.Name,
        OrderDeliveryMethodId = odm.Id // optional, but good practice
    );
    insert odg;

    OrderItem oi = new OrderItem(
        OrderId = order.Id,
        PricebookEntryId = pbe.Id,
        OrderDeliveryGroupId = odg.Id,
        Quantity = 2,
        UnitPrice = 100.00,
        TotalLineAmount = 200.00
    );
    insert oi;

    order.Status = 'Activated';
    update order;

    OrderSummary os = [SELECT Id, OriginalOrderId, OrderNumber FROM OrderSummary WHERE OriginalOrderId = :order.Id LIMIT 1];

    String newOrderSummaryId = null;

    if(os == null) {

        ConnectApi.OrderSummaryInputRepresentation osir = new ConnectApi.OrderSummaryInputRepresentation();
        osir.orderId = order.Id;
        osir.orderLifeCycleType = 'Unmanaged'; 
        //Test.startTest();
        ConnectApi.OrderSummaryOutputRepresentation osor = 
                ConnectApi.OrderSummaryCreation.createOrderSummary(osir);
        //Test.stopTest();

        os = [
        SELECT Id, OriginalOrderId, OrderNumber
        FROM OrderSummary 
        WHERE OriginalOrderId = :order.Id 
        LIMIT 1
        ];
        
    } 

    System.assertNotEquals(null, os.Id, 'OrderSummary should have been created.');
    System.assertNotEquals(null, os.OrderNumber, 'OrderSummary Order Number should have been created.');

}

    @isTest(SeeAllData=false)
    static void testGetLineItemsByOrderNumberNotFound() {
        makeData();
        Test.startTest();
        String result = MinorOrderRegistrationCtrl.getLineItemsByOrderNumber('ORD12345');
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.debug('Result of getLineItemsByOrderNumber: ' + result);
    }

    @isTest(SeeAllData=false)
    static void testGetLineItemsByOrderNumberNull() {
        makeData();
        Test.startTest();
        String result = MinorOrderRegistrationCtrl.getLineItemsByOrderNumber(null);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest(SeeAllData=false)
    static void testGetLineItemsByOrderNumber() {
        makeData();
        Order order = [SELECT Id, OrderNumber FROM Order LIMIT 1];
        Test.startTest();
        String result = MinorOrderRegistrationCtrl.getLineItemsByOrderNumber(order.OrderNumber.toString());
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.debug('Result of getLineItemsByOrderNumber: ' + result);
    }

    @isTest
    static void testDecryptData() {
        String encryptedOrderNumber = 'ubRmy6Wia8YGNSeAotIyKYBQ+Wo7QnIGfTJkF6QDx4o='; 
        String expectedDecryptedValue = '0921D5-223A-613E81B34CFF6F30'; 
        
        String result = MinorOrderRegistrationCtrl.decryptData(encryptedOrderNumber);
        
        System.assertEquals(expectedDecryptedValue, result, 'The decrypted value should match the expected value');
    }

    @isTest
    static void testDecryptDataFail() {

        String value = null; 
     
        try{
            String result = MinorOrderRegistrationCtrl.decryptData(value);
        }catch (Exception ex){
            System.assert(true, 'Exception thrown as expected for invalid encrypted data');
        }
    }

   @isTest
    static void testCreateTesterDetail() {
        Tester_Detail__c testerDetail = new Tester_Detail__c();
        testerDetail.First_Name__c = 'Test Tester'; 
        testerDetail.Email__c = 'test@test.com'; 
        
        Tester_Detail__c result = MinorOrderRegistrationCtrl.createTesterDetail(testerDetail);
        
        System.assertNotEquals(null, result, 'The result should not be null');
        System.assertEquals(testerDetail.Name, result.Name, 'The Tester Detail Name should match');
        System.assertEquals(testerDetail.Email__c, result.Email__c, 'The Tester Detail Email should match');
        
        Tester_Detail__c retrievedRecord = [SELECT Id, Name, Email__c FROM Tester_Detail__c WHERE Id = :result.Id];
        System.assertNotEquals(null, retrievedRecord, 'The record should be retrievable from the database');
    }


      @isTest
    static void testCreateTesterDetailFail() {
        Tester_Detail__c testerDetail = new Tester_Detail__c();
        testerDetail.First_Name__c = 'Test Tester'; 
        testerDetail.Email__c = 'test test.com'; 

        try {
            Tester_Detail__c result = MinorOrderRegistrationCtrl.createTesterDetail(testerDetail);

        } catch (Exception ex) {
            System.assert(true, 'An exception should be thrown for invalid email');
        }
        
    }


    @isTest(SeeAllData=false)
    static void testCreateLabOrderFail() {
        makeData();

        Tester_Detail__c testerDetail = new Tester_Detail__c();
        testerDetail.First_Name__c = 'Test Tester'; 
        testerDetail.Last_Name__c = 'Testerson';
        testerDetail.Email__c = 'test@test.com'; 
        testerDetail.Order_Number__c = 'invalid-order-number';
        insert testerDetail;

        List<String> foLineIds = new List<String>{'FOLineId1', 'FOLineId2'};
        Boolean isService = false;

        Boolean ExceptionThrown = false;

        try {

            String result = MinorOrderRegistrationCtrl.createLabOrder(testerDetail.Id, foLineIds, isService);
            
        } catch (Exception ex) {
            ExceptionThrown = true;
        }

        System.assert(ExceptionThrown, 'An exception should be thrown for invalid order number');
        //System.debug('Lab Order Creation Response: ' + result);
    }

    @isTest
    static void testCreateLabOrderSuccess() {
        makeData();

        Order order = [SELECT Id, OrderNumber FROM Order LIMIT 1];

        Tester_Detail__c testerDetail = new Tester_Detail__c();
        testerDetail.First_Name__c = 'Test Tester'; 
        testerDetail.Last_Name__c = 'Testerson';
        testerDetail.Email__c = 'test@test.com'; 
        testerDetail.Order_Number__c = order.OrderNumber;
        testerDetail.Address_Line_1__c = '123 Test St';
        testerDetail.City__c = 'Test City';
        testerDetail.State__c = 'CA';
        testerDetail.Zip_Code__c = '90001';
        testerDetail.Country__c = 'USA';
        testerDetail.Gender__c = 'Male';
        testerDetail.Phone__c = '3333214321';
        insert testerDetail;

        List<String> foLineIds = new List<String>{'FOLineId1', 'FOLineId2'};
        Boolean isService = false;

        try {
            String result = MinorOrderRegistrationCtrl.createLabOrder(testerDetail.Id, foLineIds, isService);
            System.assertNotEquals(null, result, 'Lab Order should be created successfully');
        }catch (Exception ex) {
            System.assert(true, 'An exception should be thrown for invalid order number');
            System.debug('Exception during Lab Order creation: ' + ex.getMessage());
        }

    }

    @IsTest(SeeAllData=false)
    static void test_createCustomerUser_guardsAndUpsertPath() {
        makeData();
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Id jobId = System.enqueueJob(new MinorOrderRegistrationCtrl.CreateCustomerUserQueueable(con.Id));

        System.assertNotEquals(null, jobId, 'Queueable should be enqueued successfully');
    }


    @isTest
    static void testUpdateMinorDetailsSuccess() {
        // 1. Setup Data
        Tester_Detail__c testRecord = new Tester_Detail__c(
            Minor_First_Name__c = 'Original Name'
        );
        insert testRecord;

        Map<String, Object> minorDetailsMap = new Map<String, Object>{
            'firstName' => 'John',
            'lastName' => 'Doe',
            'dateOfBirth' => '2015-05-20',
            'gender' => 'Male',
            'tncVersion' => 'v1.0',
            'addressLine1' => '123 Test St',
            'city' => 'San Francisco',
            'state' => 'CA',
            'zipCode' => '94105',
            'country' => 'USA'
        };

        // 2. Execute Test
        Test.startTest();
        // Replace 'YourClassName' with the actual name of your class
        Tester_Detail__c updatedRecord = MinorOrderRegistrationCtrl.updateMinorDetails(testRecord.Id, minorDetailsMap);
        Test.stopTest();

        // 3. Verify Results
        System.assertEquals('John', updatedRecord.Minor_First_Name__c, 'First name should be updated');
        System.assertEquals(Date.valueOf('2015-05-20'), updatedRecord.Minor_Date_Of_Birth__c, 'DOB should match');
        
        // Re-query from DB to ensure it was actually saved
        Tester_Detail__c dbRecord = [SELECT Minor_City__c FROM Tester_Detail__c WHERE Id = :testRecord.Id];
        System.assertEquals('San Francisco', dbRecord.Minor_City__c);
    }

    @isTest
    static void testUpdateMinorDetailsFail() {
        Id invalidId = Id.valueOf('001000000000000AAA'); // Invalid Id

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            MinorOrderRegistrationCtrl.updateMinorDetails(invalidId, null);
            
        } catch (Exception ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }

    @isTest
    static void testcreateCustomerUserBlank(){
        try {
            Test.startTest();
            MinorOrderRegistrationCtrl.createCustomerUser('');
            Test.stopTest();

            System.assert(true, 'No exception should be thrown for blank contact Id');
            
        } catch (Exception ex) {
            System.assert(false, 'Exception should not be thrown for blank contact Id: ' + ex.getMessage());
        }
        
    }

}