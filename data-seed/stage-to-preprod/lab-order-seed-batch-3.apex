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
    orderRecord.Name = '3fcdb2fa-03e8-42ae-9d4a-f1a9b4ae8107';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mLkTYAU';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949611');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '14a3f5dd-f121-48f7-929e-31ee50940d75';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lyxfYAA';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949611');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '4d9459ad-ff5d-4dbc-85fd-b23382b8ea6f';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lo0aYAA';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH4e7QQA8GRwBGg0mmFthzw';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '65ceeda5-b70e-4428-94d1-45af59d8bf0d';
    orderRecord.LabRefId_Override__c = 'a0sVD000007mBZrYAM';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949616');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '06f97988-584e-4147-b59a-b42672b75164';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lJWFYA2';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949620');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'bff9d430-6287-4de9-9ba3-4637fafe9077';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lp4iYAA';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH3EIQQA8GRwBGg1Xe5t47u';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '9264966a-a25e-4040-b087-715faa6395bd';
    orderRecord.LabRefId_Override__c = 'a0sVD000007ljTwYAI';
    orderRecord.Status__c = 'Registered';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH35hQQA8GRwBGg1rkbfexj';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'a3f9e7a0-a5dd-4a15-8da2-facd9ee0ae09';
    orderRecord.LabRefId_Override__c = 'a0sVD000007llynYAA';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH35aQQA8GRwBGg0g8H676r';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '50963fc7-55b7-4925-85f6-736c86ac2c5e';
    orderRecord.LabRefId_Override__c = 'a0sVD000007m2OTYAY';
    orderRecord.Status__c = 'PA Approved';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH32uQQA8GRwBGg0uyYvnei';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '7e6524b6-f171-495f-9ab1-58fb05fdd39d';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lMPGYA2';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH300QQA8GRwBGg0sL0qmVV';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '1d36b09d-e723-4e98-a22d-0ca16369a900';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lwpKYAQ';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949611');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '8256ac74-754a-4a9b-a804-db1dee184858';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lWRrYAM';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73949616');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '4b9c27c5-fc17-45a7-9cec-1d877675b1d8';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lxGkYAI';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Payment_Transaction_Id__c = 'pi_3TH2gkQQA8GRwBGg1LeEqc8p';
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = '1b1e4cfe-34d3-4f78-b1ac-c0dfb044ca30';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lVxDYAU';
    orderRecord.Status__c = 'PA Acknowledged';
    orderRecord.Partner_Order_Total__c = 0;
    orderRecord.Partner_Client_Map__c = partnerIdByClientId.get('73942126');
    orders.add(orderRecord);
}
{
    Lab_Order__c orderRecord = new Lab_Order__c();
    orderRecord.Name = 'c76beb15-6d79-42d2-9590-d473d5f64b4f';
    orderRecord.LabRefId_Override__c = 'a0sVD000007lvLOYAY';
    orderRecord.Status__c = 'PA Acknowledged';
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
System.debug('Lab order batch 3/7 complete. Records=' + orders.size());
