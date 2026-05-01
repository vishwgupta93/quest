global with sharing class QuestTPTShipmentSchedule implements Schedulable{
    global void execute(SchedulableContext sc) {   
        QuestTPTShipmentBatch btch= new QuestTPTShipmentBatch();
        btch.status = 'Order Acknowledged';
        btch.query = 'SELECT Id, OrderSummaryId,Location_Name__c FROM FulfillmentOrder WHERE Status =: status and Shipment_Success__c =true ';
        Database.executeBatch(btch,1);
      }
    }