public without sharing class OrderController {
    @AuraEnabled(cacheable=true)
    public static Boolean isMinorOrder(String orderNumber) {
        System.debug('[OrderController] isMinorOrder called with orderNumber: ' + orderNumber);
        Integer ol = (orderNumber != null) ? orderNumber.length() : 0;
        System.debug('[OrderController] orderNumber length: ' + ol);
        
        try {
            Boolean result = false;
            result = OrderService.isMinorOrder(orderNumber);
            System.debug('[OrderController] OrderService.isMinorOrder returned: ' + result);
            return result;
        } catch (Exception e) {
            System.debug('[OrderController] Exception caught in isMinorOrder: ' + e.getMessage());
            System.debug('[OrderController] Exception type: ' + e.getTypeName());
            System.debug('[OrderController] Exception stack trace: ' + e.getStackTraceString());
            // Throw exception so it's visible in browser console for guest users
            throw new AuraHandledException('Error checking minor order for ' + orderNumber + ': ' + e.getMessage());
        }
    }
}