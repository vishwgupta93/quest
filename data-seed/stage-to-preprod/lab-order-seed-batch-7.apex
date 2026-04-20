Set<String> clientIds = new Set<String>{
    '73949611',
    '73949616',
    '73942126',
    '73949620'
};
Map<String, Id> partnerIdByClientId = new Map<String, Id>();
for (PartnerClientMap__c record : [SELECT Id, Client_ID__c FROM PartnerClientMap__c WHERE Client_ID__c IN :clientIds]) {
    partnerIdByClientId.put(record.Client_ID__c, record.Id);
}
List<Lab_Order__c> orders = new List<Lab_Order__c>();
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'f3ddb878-c1fc-445b-8885-11cc5f22e8a4';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jFDNYA2';
    orderRecord.Status__c = 'PA Approved';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949616');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'c33b3d41-802a-4bfa-8f93-b843cdcf9b73';
    orderRecord.LabRefId_Override__c = 'a0sVD000007itBIYAY';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949620');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '219613bb-43a8-409d-a4b9-2d83e63b9973';
    orderRecord.LabRefId_Override__c = 'a0sVD000007iURTYA2';
    orderRecord.Status__c = 'PA Approved';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TGkJHQQA8GRwBGg0G6ZbG70';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'abe564c8-8889-4fe0-a012-c851d10e21ba';
    orderRecord.LabRefId_Override__c = 'a0sVD000007ip2tYAA';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 110;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949620');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '65329b7a-8188-4184-921e-771ad9ed6a4f';
    orderRecord.LabRefId_Override__c = 'a0sVD000007iZ7mYAE';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949616');
    orders.add(orderRecord);
}
Schema.SObjectField externalIdField = Lab_Order__c.Fields.getMap().get('LabRefId_Override__c');
Database.UpsertResult[] results = Database.upsert(orders, externalIdField, false);
for (Integer i = 0; i < results.size(); i++) {
    if (!results[i].isSuccess()) {
        throw new AuraHandledException('Lab order upsert failed for ' + (String) orders[i].get('LabRefId_Override__c') + ': ' + results[i].getErrors()[0].getMessage());
    }
}
System.debug('Lab order batch 7/7 complete. Records=' + orders.size());
