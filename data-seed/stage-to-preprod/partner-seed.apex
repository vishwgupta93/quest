Set<String> clientIds = new Set<String>{
    '73949611',
    '73949616',
    '73942126',
    '73949620'
};
Map<String, PartnerClientMap__c> existingByClientId = new Map<String, PartnerClientMap__c>();
for (PartnerClientMap__c record : [SELECT Id, Client_ID__c FROM PartnerClientMap__c WHERE Client_ID__c IN :clientIds]) {
    existingByClientId.put(record.Client_ID__c, record);
}
List<PartnerClientMap__c> toInsert = new List<PartnerClientMap__c>();
if (!existingByClientId.containsKey('73949611')) toInsert.add(new PartnerClientMap__c(Name = 'APPLE_HEALTH', Client_ID__c = '73949611', Partner_Name__c = 'APPLE_HEALTH'));
if (!existingByClientId.containsKey('73949616')) toInsert.add(new PartnerClientMap__c(Name = 'GOOGLE_HEALTH_STUDY', Client_ID__c = '73949616', Partner_Name__c = 'google'));
if (!existingByClientId.containsKey('73942126')) toInsert.add(new PartnerClientMap__c(Name = 'saturn', Client_ID__c = '73942126', Partner_Name__c = 'Saturn'));
if (!existingByClientId.containsKey('73949620')) toInsert.add(new PartnerClientMap__c(Name = 'WEIGHT_WATCHERS', Client_ID__c = '73949620', Partner_Name__c = 'WEIGHT_WATCHERS'));
if (!toInsert.isEmpty()) insert toInsert;
System.debug('Partner seed complete. Inserted=' + toInsert.size());
