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
    orderRecord.Name = '2e169764-97e3-4e4a-9779-db57a981cbc9';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jWNuYAM';
    orderRecord.Status__c = 'PA Approved';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '6734a501-c16c-4b34-bbee-dbd197f31998';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jSDsYAM';
    orderRecord.Status__c = 'PA Approved';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'da99d245-d2ae-4db4-9c1d-2f924304fd01';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jNz0YAE';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TGnnQQQA8GRwBGg13cuLR64';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '12ae5de3-7ac2-460e-a671-298965130359';
    orderRecord.LabRefId_Override__c = 'a0sVD000007ilaNYAQ';
    orderRecord.Status__c = 'PA Approved';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TGnkvQQA8GRwBGg0g86Il1k';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '6ae63294-22bf-4145-963b-eaed1376fd76';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jSddYAE';
    orderRecord.Status__c = 'PA Approved';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949616');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '24f02ec1-9cef-4ddd-942b-75f1423b0cc6';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jReLYAU';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '231e8937-4332-43fc-98f7-0293330faf8e';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jRJOYA2';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '0448d617-def5-45e9-b4d4-63e7fb9dfde8';
    orderRecord.LabRefId_Override__c = 'a0sVD000007j0fpYAA';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '971f5b6b-b34e-40f4-aba8-b2ee6ca7ba91';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jQdSYAU';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '1590ce9c-8eac-4b90-91f5-230d4791bd11';
    orderRecord.LabRefId_Override__c = 'a0sVD000007j2D4YAI';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'f859b6c9-7395-4eaa-bb66-aed90462adc3';
    orderRecord.LabRefId_Override__c = 'a0sVD000007iJseYAE';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '0bdfc4c3-09bb-4122-8a48-a2ea18191ca2';
    orderRecord.LabRefId_Override__c = 'a0sVD000007jQyQYAU';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'a2fd3816-dc85-4bb9-8689-238d7932b7d7';
    orderRecord.LabRefId_Override__c = 'a0sVD000007iounYAA';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '256b5bf7-4684-49a3-a24a-3b5df573e162';
    orderRecord.LabRefId_Override__c = 'a0sVD000007j3tpYAA';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '6d721d49-5516-4cf3-a97e-c1e81c2f6988';
    orderRecord.LabRefId_Override__c = 'a0sVD000007j2D3YAI';
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
System.debug('Lab order batch 5/7 complete. Records=' + orders.size());
