public class ValidateFHIRInput {
    public static String orderNumber(String input) {
        
        String objectName = 'FulfillmentOrder';
        String attributeName = 'Fulfillment_Order_ID_Uppercase__c';
        String valueToCheck = input;
        String orderNo = '';
    
        String query = 'SELECT OrderSummaryId, Id FROM ' + objectName + ' WHERE ' + attributeName + ' = :valueToCheck LIMIT 1';
        SObject[] matchingRecords = Database.query(query);
        OrderSummary orderSummary;
        if (matchingRecords.size() > 0) {
            SObject existingRecord = matchingRecords[0];
            String OrderSummaryId = (String) existingRecord.get('OrderSummaryId');
            orderSummary = [SELECT OrderNumber FROM OrderSummary WHERE Id=:OrderSummaryId];
            orderNo = orderSummary.OrderNumber;
        }
        return orderNo;
    }

    public static String getFHIRId(String orderNumber){
        String FHIRId;
        //check if valid order
        orderNumber = String.escapeSingleQuotes(orderNumber);
        String objectName = 'OrderSummary';
        String attributeName = 'OrderNumber';
        String valueToCheck = String.escapeSingleQuotes(orderNumber);
        String query = 'SELECT Id FROM ' + objectName + ' WHERE ' + attributeName + ' = :valueToCheck LIMIT 1';
        SObject[] matchingRecords = Database.query(query);
        
        if(matchingRecords.size() > 0){
            objectName = 'Lab_Response__c';
            attributeName = 'OrderNumber__c';
            valueToCheck = String.escapeSingleQuotes(orderNumber);
            query = 'SELECT FHIR_Id__c FROM ' + objectName + ' WHERE ' + attributeName + ' = :valueToCheck LIMIT 1';
            SObject[] labResponse = Database.query(query);
            if(labResponse.size() > 0){
                SObject existingRecord = labResponse[0];
                FHIRId = (String) existingRecord.get('FHIR_Id__c');
            }
            
        }
        return FHIRId;
    }
}