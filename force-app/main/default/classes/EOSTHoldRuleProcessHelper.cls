global class EOSTHoldRuleProcessHelper implements Database.Batchable <SObject>{
 
    public String Query;
    public String Id;
    public String status;
    public Boolean holdReleased;
 
 global Database.QueryLocator start(Database.BatchableContext bc){
   return Database.getQueryLocator(Query);
 }

 global void execute(Database.BatchableContext bc, List<EOST_OMS_Notification_Detail__c> notifications){ 

    System.debug(notifications);
    if(!notifications.isEmpty())
    {
        List<FulfillmentOrderLineItem> foLines= new List<FulfillmentOrderLineItem>();
        List<Kit_Details__c> kits= new List<Kit_Details__c>();
        List<Lab_Panel_Test__c> tests= new List<Lab_Panel_Test__c>();
        Set<String> panelTestId = new Set<String>();
        Set<String> foLineId = new Set<String>();
        Set<String> kitId = new Set<String>();
        for(EOST_OMS_Notification_Detail__c notification: notifications)
        {
            if(notification.Type__c == 'FO' && foLineId.add(notification.Fulfillment_Order_Product__c))
            {
                FulfillmentOrderLineItem foLine = new FulfillmentOrderLineItem();
                foLine.Id= notification.Fulfillment_Order_Product__c;
                foLine.Status__c=notification.OMS_Status__c;
                foLine.Result_Date__c=notification.Resulted_Date__c;
                foLine.Date_Reported__c=notification.Date_Reported__c;
                foLines.add(foLine);
            }
            else if(notification.Type__c == 'LO' && panelTestId.add(notification.Lab_Panel_Test__c))
            {
                Lab_Panel_Test__c test = new Lab_Panel_Test__c();
                test.Id= notification.Lab_Panel_Test__c;
                test.Status__c=notification.OMS_Status__c;
                tests.add(test);
            }
            else if(notification.Is_Kit__c && kitId.add(notification.Kit_Detail__c))
            {
                Kit_Details__c kit = new Kit_Details__c();
                kit.Id= notification.Kit_Detail__c;
                kit.Lab_Status__c=notification.OMS_Status__c;
                kit.Result_Date__c=notification.Resulted_Date__c;
                kit.Date_Reported__c=notification.Date_Reported__c;
                kits.add(kit);
            }
        }

        update foLines;
        update kits;
        update tests;
    }
 
    
    
   }

 global void finish(Database.BatchableContext bc) {

  
 
 }
}