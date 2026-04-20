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
    orderRecord.Name = '8c4e28f9-473f-4fba-bd8e-42baff218885';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jMLKYA2';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'e66b4947-5ad7-4903-be51-8dc53c8aaa76';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jKHvYAM';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'a988186b-66d7-4079-8d4f-3a1dcd24a4b5';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jDQAYA2';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'c23fe49f-df1a-4b21-89bb-67f48a02fe33';
    orderRecord.LabRefId_Override__c = 'a0sVD000007in5xYAA';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '4d366179-3fc5-470e-98f1-1060cc2a2036';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jIJMYA2';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '3b883cf6-00da-4e49-a0e7-36f283302491';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jQf4YAE';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '90e55d80-2267-498f-ae57-bf871ce4d65f';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jNyxYAE';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '61654909-1787-490d-8221-cc62441f8eba';
    orderRecord.LabRefId_Override__c = 'a0sVD000007iwPLYAY';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '0541cd1e-50c7-409c-b0af-5f58b2495c88';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jM3bYAE';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '90dd54b2-65ae-427e-b59b-39b822393675';
    orderRecord.LabRefId_Override__c = 'a0sVD000007ipEEYAY';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'b088f4fe-448f-4c76-83b5-9b95c56637f9';
    orderRecord.LabRefId_Override__c = 'a0sVD000007it87YAA';
    orderRecord.Status__c = 'PA Approved';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '100a80aa-b38c-4baa-b8fe-b6349aa2af07';
    orderRecord.LabRefId_Override__c = 'a0sVD000007j1X6YAI';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '44beb596-7414-4fae-af8a-998257dab6f4';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jH79YAE';
    orderRecord.Status__c = 'PA Approved';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'b65a3cdf-211b-4e80-bdf0-fbec9f68296e';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jDQ9YAM';
    orderRecord.Status__c = 'PA Approved';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '54579db6-c493-47ab-aec9-df1cc7582b8f';
    orderRecord.LabRefId_Override__c = 'a0sVD000007j29oYAA';
    orderRecord.Status__c = 'PA Approved';
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
System.debug('Lab order batch 6/7 complete. Records=' + orders.size());
