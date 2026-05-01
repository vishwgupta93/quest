global class EOSTHoldRuleSchedule implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        String status = 'Results Ready';
        Boolean holdReleased=true;
        String query = 'select Id,Type__c,Lab_Panel_Test__c,Fulfillment_Order_Product__c,Is_Kit__c,Is_PSC__c,Kit_Detail__c,OMS_Status__c,Resulted_Date__c,Date_Reported__c from EOST_OMS_Notification_Detail__c where OMS_Status__c =: status and Hold_Released__c =:holdReleased';
        EOSTHoldRuleProcessHelper btch = new EOSTHoldRuleProcessHelper();
        btch.Query=query;
        btch.status=status;
        btch.holdReleased=holdReleased;

        Database.executeBatch(btch, 50);
     }
 }