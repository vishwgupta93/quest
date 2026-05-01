global with sharing class QuestTPTShipmentBatch implements Database.Batchable<SObject>, Database.AllowsCallouts{
    public String query;
    public String status;
    public String Id;

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<FulfillmentOrder> openOrders) {

        if(!openOrders.isEmpty())
        {
            for(FulfillmentOrder order : openOrders)
            {
                if(order.Location_Name__c == 'GBF')
                {
                    QuestGBFShipmentParser.fetchAndParseShipment(order.Id, order.orderSummaryId);
                }
                else if(order.Location_Name__c == 'PROOV')
                {
                    QuestSSShipmentParser.fetchAndParseShipmentData(order.Id, order.orderSummaryId);
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
       
    }
}