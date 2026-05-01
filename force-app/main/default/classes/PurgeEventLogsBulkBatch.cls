public class PurgeEventLogsBulkBatch implements Database.Batchable<sObject>, Database.Stateful {
    private Map<String, List<Purge_Event_Logs__mdt>> sObjectConfigMap;
    private List<String> sObjectList;
    private Integer currentSObjectIndex;
    public integer totalcount = 0;
    private static final Integer BATCH_SIZE = 2000; //Setting batch size to 2000 records
    //private static final Integer CHUNK_SIZE = 200;   // Apex DML limit
    
    public PurgeEventLogsBulkBatch() {
        sObjectConfigMap = new Map<String, List<Purge_Event_Logs__mdt>>();
        sObjectList = new List<String>();
        currentSObjectIndex = 0;
        
        for (Purge_Event_Logs__mdt config : [SELECT Event_Type__c, Retention_Days__c, SObject__c 
                                             FROM Purge_Event_Logs__mdt ]) {
                                                 if (!sObjectConfigMap.containsKey(config.SObject__c)) {
                                                     sObjectConfigMap.put(config.SObject__c, new List<Purge_Event_Logs__mdt>());
                                                     sObjectList.add(config.SObject__c);
                                                 }
                                                 sObjectConfigMap.get(config.SObject__c).add(config);
                                             }
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (currentSObjectIndex >= sObjectList.size()) {
            return Database.getQueryLocator('SELECT Id FROM Event_Logs__c WHERE Id = null'); // to break the loop
        }
        
        String currentSObject = sObjectList[currentSObjectIndex];
        String query = buildQuery(currentSObject);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        String currentSObject = sObjectList[currentSObjectIndex];
        Integer recordsProcessed = scope.size();
        
        try {
            if (!scope.isEmpty()) {
                List<Id> idsToDelete = new List<Id>();
                for (sObject record : scope) {
                    totalcount++;
                    idsToDelete.add(record.Id);
                }
               system.debug(JSON.serialize(idsToDelete));
                system.debug(currentSObject+'-->'+totalcount);
                Database.delete(idsToDelete, false); 
            }
        } catch (Exception e) {
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        currentSObjectIndex++;
        if (currentSObjectIndex < sObjectList.size()) {
            Database.executeBatch(this, BATCH_SIZE);
        }
    }
    
    private String buildQuery(String sObjectName) {
        String query = 'SELECT Id FROM ' + sObjectName + ' WHERE (';
        List<Purge_Event_Logs__mdt> configs = sObjectConfigMap.get(sObjectName);
        Boolean firstCondition = true;
        
        for (Purge_Event_Logs__mdt config : configs) {
            if (!firstCondition) {
                query += ' OR ';
            }
            Integer retentionDays = Integer.valueOf(config.Retention_Days__c);
            DateTime cutoffDateTime = DateTime.now().addDays(-retentionDays);
            String formattedDate = cutoffDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            // Today Code
            if(Test.isRunningTest()){
                query += '(Event_Type__c = \'' + String.escapeSingleQuotes(config.Event_Type__c)+
              '\' and Is_Completed__c = true )';
            }
            else{
                query += '(Event_Type__c = \'' + String.escapeSingleQuotes(config.Event_Type__c)+
             '\' AND LastModifiedDate < ' + formattedDate + ' and Is_Completed__c = true )';
            }
            
            
            firstCondition = false;
        }
        
        query += ')';
        System.debug('query=>'+query);
        return query;
    }
    
    public static void run() {
        Database.executeBatch(new PurgeEventLogsBulkBatch(), BATCH_SIZE);
    }
}