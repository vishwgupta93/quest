public without sharing class OrderService {
    public static Boolean isMinorOrder(String orderNumber) {
        System.debug('[OrderService] isMinorOrder called with orderNumber: ' + orderNumber);
        
        if (String.isBlank(orderNumber)) {
            System.debug('[OrderService] orderNumber is blank, returning false');
            return false;
        }

        System.debug('[OrderService] Querying Commerce_Order_Info__c for Order_Number__c: ' + orderNumber);
        
        // Query Commerce_Order_Info__c record by Order_Number__c
        List<Commerce_Order_Info__c> commerceOrders = [
            SELECT Test_Codes__c 
            FROM Commerce_Order_Info__c 
            WHERE Order_Number__c = :orderNumber 
            LIMIT 1
        ];

        System.debug('[OrderService] Query returned ' + commerceOrders.size() + ' record(s)');
        
        if (commerceOrders.isEmpty()) {
            System.debug('[OrderService] No records found, returning false');
            return false;
        }
        
        if (String.isBlank(commerceOrders[0].Test_Codes__c)) {
            System.debug('[OrderService] Test_Codes__c is blank, returning false');
            return false;
        }
        
        System.debug('[OrderService] Test_Codes__c value (first 200 chars): ' + commerceOrders[0].Test_Codes__c.substring(0, Math.min(200, commerceOrders[0].Test_Codes__c.length())));

        // Deserialize Test Codes using the TestCodes utility class
        List<TestCodes> tests = TestCodes.parse(commerceOrders[0].Test_Codes__c);
        System.debug('[OrderService] Parsed ' + tests.size() + ' test code(s)');

        // Check if any test code represents a minor product
        for (TestCodes test : tests) {
            System.debug('[OrderService] Checking test code: ' + test.Code + ', isMinorProduct: ' + test.isMinorProduct());
            if (test.isMinorProduct()) {
                System.debug('[OrderService] Found minor product, returning true');
                return true;
            }
        }

        System.debug('[OrderService] No minor products found, returning false');
        return false;
    }
}