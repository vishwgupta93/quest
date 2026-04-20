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
    orderRecord.Name = '205ffb1c-4592-48ae-a100-7b168589efa1';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mOldYAE';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH6yaQQA8GRwBGg0mLDg8Qg';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '3825f565-91c1-4b05-8a07-5e93bc2541a0';
    orderRecord.LabRefId_Override__c = 'a0sVD000007meTmYAI';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH6xjQQA8GRwBGg0V58V4Wi';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '971361e6-6981-43f2-bc36-e50edb7bbd27';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mBExYAM';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH6xYQQA8GRwBGg1esNdGe8';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '0010e89b-e73e-472c-9b2a-b795c92c86ba';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mP0AYAU';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH6xWQQA8GRwBGg1ZX3g275';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '9906634e-b410-4f46-a315-26cca46550d2';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mTGeYAM';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH6wSQQA8GRwBGg0SLGPH3G';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'f990f85a-0d63-4903-8a1b-5c8584fa6b62';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mI8NYAU';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH6wSQQA8GRwBGg0mnxPhI0';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'd1460250-ca12-4c45-80c1-df15f9b5f5be';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mEnrYAE';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH6vNQQA8GRwBGg1bJRsSbg';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '92ee2809-84e9-4b0b-8a91-af730d17a73f';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lwMJYAY';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH6vNQQA8GRwBGg11KMXQWM';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '5fa5ba20-18fd-4eec-a836-6db87c1c3418';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mEBEYA2';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949616');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '15312bd0-cc49-4228-87c7-14023fb78c00';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mb4VYAQ';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949616');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '23313b9f-e418-4a2a-a831-706cce835ac5';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mdpRYAQ';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH6mxQQA8GRwBGg1OFTqwNp';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '67820dbc-3c21-4c5b-9b23-12529d9a9d9d';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mPeSYAU';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH6iYQQA8GRwBGg1LG9dwEn';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '61c5b44e-553d-43d9-b02f-d3ecdb239ee5';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lhrxYAA';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH6J9QQA8GRwBGg009hhRjJ';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'be59265e-acaf-4b3c-814c-edbc7029ddb4';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mTjfYAE';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949616');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '99ee23e8-3c8b-463a-b180-c39563a02a9e';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mQaXYAU';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH5sAQQA8GRwBGg0xsZubjd';
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
System.debug('Lab order batch 2/7 complete. Records=' + orders.size());
