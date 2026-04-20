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
    orderRecord.Name = 'a96e31ce-acf2-4ff4-aee6-33fe89914edf';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lw4XYAQ';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'c68a2585-8907-481c-ae2d-ca9d28821093';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lpxWYAQ';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949620');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'f645cca0-c4b2-4fc5-aa87-52a26f3c7e3a';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lNzjYAE';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '6148a2d9-f592-430b-aa08-6dfd23619471';
    orderRecord.LabRefId_Override__c = 'a0sVD000007knWUYAY';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'bf693ea3-ac67-4bfe-b06d-828838511765';
    orderRecord.LabRefId_Override__c = 'a0sVD000007l9NKYAY';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '407f3b20-fcca-4141-b807-c00ad37c6267';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lJcnYAE';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'ef4cc32c-aebc-4e94-a6c0-35d9a0d90a3e';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lucDYAQ';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'c5edba6c-6cf3-4e17-8fad-1b75e7dd8026';
    orderRecord.LabRefId_Override__c = 'a0sVD000007luU9YAI';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH2QFQQA8GRwBGg0sJ580uC';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '51e05e37-5487-4c12-bc30-5821984d8e2d';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lHj0YAE';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'f3e2d82a-c2b8-4988-8cae-1f6fa61599b8';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lTx1YAE';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '25829edb-dd52-4403-be82-f3148ed858d6';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lhvCYAQ';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '98dfe0e0-6470-4550-8f0a-9bc6395379d9';
    orderRecord.LabRefId_Override__c = 'a0sVD000007kXgAYAU';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 65;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949616');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '83f0ef4e-ae0a-48c9-ab43-80e4c720c84c';
    orderRecord.LabRefId_Override__c = 'a0sVD000007ktn3YAA';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TGwXIQQA8GRwBGg108tRKjH';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '242d336c-5dc8-4f18-9818-3a1a85fa4f74';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jQ5aYAE';
    orderRecord.Status__c = 'PA Approved';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '06f51b05-e6ee-4f90-95e3-dbfc4eecedd9';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jWqvYAE';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
Schema.SObjectField externalIdField = Lab_Order__c.Fields.getMap().get('LabRefId_Override__c');
Database.UpsertResult[] results = Database.upsert(orders, externalIdField, false);
for (Integer i = 0; i < results.size(); i++) {
    if (!results[i].isSuccess()) {
        throw new AuraHandledException('Lab order upsert failed for ' + (String) orders[i].get('LabRefId_Override__c') + ': ' + results[i].getErrors()[0].getMessage());
    }
}
System.debug('Lab order batch 4/7 complete. Records=' + orders.size());
