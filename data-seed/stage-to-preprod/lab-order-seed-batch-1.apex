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
    orderRecord.Name = 'f84090ac-9679-443e-a1c0-6fc6dce7747a';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mNXoYAM';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH7NnQQA8GRwBGg1ClHYrUb';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '7cda16c8-fde3-4d8d-814b-b3c74a207d1a';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mgP7YAI';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 100;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949620');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '04ad2e3e-4367-4940-a8c4-1622ac1c249c';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mSAuYAM';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH74vQQA8GRwBGg1bQTJKH5';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'c468fa19-1b63-4750-ab1f-f2d0e369db60';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mDobYAE';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH74vQQA8GRwBGg0zGpUJae';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '0b93d711-6985-4492-a316-6fdf95fa8c81';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mKwXYAU';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH73rQQA8GRwBGg1ezrMQQx';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '3297cc62-749c-459b-9531-981d7404c72b';
    orderRecord.LabRefId_Override__c = 'a0sVD000007levjYAA';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH73rQQA8GRwBGg105nZXoY';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '4db2998a-4dfe-4b94-be51-f1abd8cd0f07';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mapzYAA';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH72oQQA8GRwBGg1EoMWWBV';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'abdc4973-f99d-4e16-8bc0-9a8761a4633b';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mfMbYAI';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH72oQQA8GRwBGg0zPSPdY7';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '9bcfedc3-c05b-480e-9f9d-6f1fed73816a';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mBJqYAM';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH71lQQA8GRwBGg0dgU6KhE';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'f74b20dc-d140-4348-b0d5-7038588a61ab';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mBA7YAM';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH71kQQA8GRwBGg0kodVpPk';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '2f916a7e-f0b0-49e2-a2eb-e8194b4567e7';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mE1VYAU';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH70hQQA8GRwBGg1YlTKkwe';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '25db71c2-4951-4134-a379-f51395fa3020';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mbywYAA';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH70hQQA8GRwBGg1zYmmIfC';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '17cc017c-8832-4090-91cc-b31eb339ca9c';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mAihYAE';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH6zeQQA8GRwBGg1qmFutBv';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '25954a0e-e2da-4298-b7a6-fbc4aa2dc5bc';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mWHjYAM';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH6zdQQA8GRwBGg0VYFANXN';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '6ca4b887-6ced-4601-9047-d62c54633f7a';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mF0oYAE';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH6ycQQA8GRwBGg07kWFOFu';
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
System.debug('Lab order batch 1/7 complete. Records=' + orders.size());
