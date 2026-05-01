public with sharing class EOSTOMSNotificationTranslator {

    public static void formNotificationDetail(String batchId)
    {

        List<EOST_OMS_Log__c> logs = [select Id, Reference_ID__c,EOST_Payload__c from EOST_OMS_Log__c where Batch_ID__C =: batchId];
        Set<String> pscLabRefIds = new Set<String>();
        Set<String> kitLabRefIds = new Set<String>();
        Set<String> labRefIds = new Set<String>();
        Set<String> labOrderRefIds = new Set<String>();
        Map<String,EOST_OMS_Notification_Detail__c> refAndDetails = new Map<String,EOST_OMS_Notification_Detail__c>();
        Map<String,List<EOST_OMS_Log__c>> refIdAndLogsMap = new Map<String,List<EOST_OMS_Log__c>>();
        List<EOST_OMS_Notification_Detail__c> fullDetails = new List<EOST_OMS_Notification_Detail__c>();
        List<EOST_OMS_Log__c> updatedLogs = new List<EOST_OMS_Log__c>();
        String SF_Lab_Order_Key_Prefix = Label.SF_Lab_Order_Key_Prefix;
        for(EOST_OMS_Log__c log: logs)
        {
            if (!refIdAndLogsMap.containsKey(log.Reference_ID__c)) {
                refIdAndLogsMap.put(log.Reference_ID__c, new List<EOST_OMS_Log__c>());
            }
            log.Batch_Status__c='Processed';
            System.debug('Log : ' + log);
            refIdAndLogsMap.get(log.Reference_ID__c).add(log);

            String jsonPayload  = log.EOST_Payload__c;

            System.debug(jsonPayload);

            //jsonPayload = '"{\"sendNotification\":true,\"notification\":{\"version\":2,\"event\":{\"eventType\":\"requisitionStatusChanged\",\"eostRequisitionUuid\":\"6cd87528-9a9d-4826-a812-4a26de0bc4c8\",\"dateOfService\":\"2024-04-29T19:17:47Z\",\"internalRequistionNumber\":\"0136236\",\"accessionNumber\":\"CZ001794T\",\"performingSite\":\"TPH\",\"clientAccountNumber\":\"97554902\",\"labRefID\":\"0A36W0000000QTDAAA\",\"PID\":\"20240417154356006555\",\"statusCode\":2,\"statusDesc\":\"Processing\",\"notificationUuid\":\"e89e9e89-d901-4916-92ec-768e1aa54274\",\"dateOfCollection\":\"2024-04-29T15:19:00.000+00:00\",\"patient\":{\"patientLastName\":\"DOMO\",\"patientFirstName\":\"LANNY\",\"patientGender\":\"M\",\"patientDateOfBirth\":\"1974-10-10\"},\"provider\":{\"providerLastName\":\"SCHWARTZ\",\"providerFirstName\":\"ADINA\",\"providerId\":\"1531015356\"},\"orderedTests\":[{\"reflexTest\":false,\"statusCode\":\"processing\",\"testCode\":\"7788\",\"testCodeDescription\":\"BLOOD TYPE TEST\"},{\"reflexTest\":false,\"statusCode\":\"processing\",\"testCode\":\"7065\",\"testCodeDescription\":\"VITAMIN B12 \\\\T\\\\ FOLATE TEST\"}]}}}"';



            Map<String, Object> payloadMap = (Map<String, Object>)JSON.deserializeUntyped(jsonPayload);
            EOSTNotificationPayload payload = (EOSTNotificationPayload)JSON.deserialize(jsonPayload, EOSTNotificationPayload.class);
            Map<String,EOST_OMS_Notification_Detail__c> details = payload.convertToNotificationDetails(log.Id);

            System.debug('Debug 1 :: ' + details);
            refAndDetails.putAll(details);
            system.debug('payload.event.labRefID - '+payload.event.labRefID);
            system.debug('payload.event.labRefIdOverride - '+payload.event.labRefIdOverride);

            //it verifies if labRefIdOverride is present in payload coming from AWS, if yes then it adds to labOrderRefIds set
            if(payload.event.labRefIdOverride != null){
                system.debug('Inside labRefIdOverride');
                labOrderRefIds.add(payload.event.labRefIdOverride);
            }else{ //otherwise will do the normal flow
                if(payload.event.labRefID != null && payload.event.labRefID.startsWith('0A3') && payload.event.labRefID.length()==18)
                {
                    system.debug('Inside PSC');
                    pscLabRefIds.add(payload.event.labRefID);
                }
                else if(payload.event.labRefID != null && payload.event.labRefID.startsWith(SF_Lab_Order_Key_Prefix) && payload.event.labRefID.length()==18)
                {
                    system.debug('Inside LO');
                    labOrderRefIds.add(payload.event.labRefID);
                }
                else if(payload.event.labRefID != null && !payload.event.labRefID.startsWith('0A3') && !payload.event.labRefID.startsWith(SF_Lab_Order_Key_Prefix) && payload.event.labRefID != '')
                {
                    system.debug('Inside Kit');
                    kitLabRefIds.add(payload.event.labRefID);
                }
            }
        }


        System.debug(' Debug refIdAndLogsMap : ' + refIdAndLogsMap);

        System.debug('Debug 2 :: ' + refAndDetails);

        System.debug('Debug 3 :: ' + pscLabRefIds);

        System.debug('Debug 4 :: ' + kitLabRefIds);

        System.debug('Debug Lab Order ref Ids :: ' + labOrderRefIds);

        labRefIds.addAll(pscLabRefIds);
        labRefIds.addAll(kitLabRefIds);
        labRefIds.addAll(labOrderRefIds);

        if(!pscLabRefIds.isEmpty())
        {
            List<FulfillmentOrderLineItem> foLines = [select FulfillmentOrderId,FulfillmentOrder.Fulfillment_Order_ID_Uppercase__c,Id,OrderSummaryId__c,ProductCode__c from FulfillmentOrderLineItem where FulfillmentOrder.Fulfillment_Order_ID_Uppercase__c =:pscLabRefIds];
            if(!foLines.isEmpty())
            {
                   for (FulfillmentOrderLineItem line : foLines) {
                    string productCode = line.ProductCode__c;
                    integer lastHyphen= productCode.lastIndexOf('-');
                    if(lastHyphen>-1)
                    {
                        String suffix=productCode.substring(lastHyphen+1);

                        if(suffix.toLowerCase().startsWith('m')){
                            productCode=productCode.substring(0,lastHyphen);
                        }

                    }

                    String key = line.FulfillmentOrder.Fulfillment_Order_ID_Uppercase__c + productCode;

                    EOST_OMS_Notification_Detail__c detail = refAndDetails.remove(key);
                    System.debug('Key: ' + key +  ' detail::  ' + detail);


                        if(detail != null)
                        {
                            detail.Fulfillment_Order_Product__c = line.Id;
                            detail.Fulfillment_Order__c= line.FulfillmentOrder.Id;
                            detail.Order_Summary__c = line.OrderSummaryId__c;
                            detail.Is_PSC__c=true;


                            System.debug('FO Line: ' + line);



                            fullDetails.add(detail);
                        }


                    List<EOST_OMS_Log__c> logsToUpdate = refIdAndLogsMap.remove(line.FulfillmentOrder.Fulfillment_Order_ID_Uppercase__c);
                    if(logsToUpdate!=null && !logsToUpdate.isEmpty())
                    {
                        for(EOST_OMS_Log__c logToUpdate : logsToUpdate)
                        {
                            logToUpdate.Order_Summary__c=line.OrderSummaryId__c;
                            logToUpdate.Fulfillment_Order__c=line.FulfillmentOrder.Id;
                            updatedLogs.add(logToUpdate);
                        }
                    }

                }

                System.debug('Debug 5 :: ' + fullDetails);
            }
        }
        if(!labOrderRefIds.isEmpty())
        {
            List<Lab_Panel_Test__c> tests = [select Id,Lab_Order_Panel__r.Lab_Order__r.Kit_Detail__c,Lab_Order_Panel__c,Lab_Order_Panel__r.Lab_Order__r.Lab_Order_ID_Uppercase__c,Lab_Order_Panel__r.Lab_Order__c,Lab_Order_Panel__r.Lab_Order__r.Is_Kit__c,Lab_Order_Panel__r.Lab_Order__r.LabRefId__c,Lab_Order_Panel__r.Lab_Order__r.Fulfillment_Order__c,Lab_Order_Panel__r.Lab_Order__r.Order_Summary__c,Lab_Order_Panel__r.Fulfillment_Order_Product__c,Test_Code__c, Lab_Order_Panel__r.Lab_Order__r.LabRefId_Override__c 
                                                FROM Lab_Panel_Test__c 
                                                WHERE Lab_Order_Panel__r.Lab_Order__r.LabRefId_Override__c =:labOrderRefIds OR Lab_Order_Panel__r.Lab_Order__r.Lab_Order_ID_Uppercase__c =:labOrderRefIds];

            if(!tests.isEmpty())
            {
                for(Lab_Panel_Test__c test : tests)
                {
                    string testCode = test.Test_Code__c;
                    integer lastHyphen= testCode.lastIndexOf('-');
                    if(lastHyphen>-1)
                    {
                        String suffix=testCode.substring(lastHyphen+1);

                        if(suffix.toLowerCase().startsWith('m')){
                            testCode=testCode.substring(0,lastHyphen);
                        }

                    }
                    String labOrderKey = test.Lab_Order_Panel__r.Lab_Order__r.LabRefId_Override__c != null
                        ? test.Lab_Order_Panel__r.Lab_Order__r.LabRefId_Override__c
                        : test.Lab_Order_Panel__r.Lab_Order__r.Lab_Order_ID_Uppercase__c;

                    //String key = test.Lab_Order_Panel__r.Lab_Order__r.Lab_Order_ID_Uppercase__c + testCode;
                    String key = labOrderKey + testCode;
                    EOST_OMS_Notification_Detail__c detail = refAndDetails.remove(key);
                    System.debug('Key: ' + key +  ' detail::  ' + detail);
            
                        if(detail != null)
                        {
                            detail.Fulfillment_Order_Product__c = test.Lab_Order_Panel__r.Fulfillment_Order_Product__c;
                            detail.Fulfillment_Order__c= test.Lab_Order_Panel__r.Lab_Order__r.Fulfillment_Order__c;
                            detail.Order_Summary__c = test.Lab_Order_Panel__r.Lab_Order__r.Order_Summary__c;
                            if(test.Lab_Order_Panel__r.Lab_Order__r.Is_Kit__c)
                            {
                                detail.Is_Kit__c=true;
                                detail.Kit_Detail__c= test.Lab_Order_Panel__r.Lab_Order__r.Kit_Detail__c;
                            }
                            else {
                                detail.Is_PSC__c=true;
                            }

                            detail.Lab_Order__c=test.Lab_Order_Panel__r.Lab_Order__c;
                            detail.Lab_Order_Panel__c=test.Lab_Order_Panel__c;
                            detail.Lab_Panel_Test__c=test.Id;


                            System.debug('Lab Panel Test: ' + test);



                            fullDetails.add(detail);
                        }

                        List<EOST_OMS_Log__c> logsToUpdate = refIdAndLogsMap.remove(labOrderKey);
                        if(logsToUpdate!=null && !logsToUpdate.isEmpty())
                        {
                            for(EOST_OMS_Log__c logToUpdate : logsToUpdate)
                            {
                                logToUpdate.Order_Summary__c=test.Lab_Order_Panel__r.Lab_Order__r.Order_Summary__c;
                                logToUpdate.Fulfillment_Order__c=test.Lab_Order_Panel__r.Lab_Order__r.Fulfillment_Order__c;
                                logToUpdate.Lab_Order__c=test.Lab_Order_Panel__r.Lab_Order__c;
                                updatedLogs.add(logToUpdate);
                            }
                        }
                }
            }
        }
        if(!kitLabRefIds.isEmpty())
        {
            system.debug('Inside kitLabRefIds not null');
            List<Kit_Details__c> kits = [select Id,Activation_Code__c, Fulfillment_Order_Id__c,Order_Summary__c,Item_Code__c from Kit_Details__c where Activation_Code__c =: kitLabRefIds];
            system.debug('kitsize'+kits.size());
            if(!kits.isEmpty())
            {

                   for (Kit_Details__c kit : kits) {

                    String key = kit.Activation_Code__c + kit.Item_Code__c;
                    EOST_OMS_Notification_Detail__c detail = refAndDetails.remove(key);
                    List<Lab_Order__c> labOrder = [select Id from Lab_Order__c where Kit_Detail__c =: kit.Id];
                    system.debug('labOrderize'+labOrder.size());
                        if(detail != null)
                        {
                            if(kit.Fulfillment_Order_Id__c != null)
                            {
                                detail.Fulfillment_Order__c= kit.Fulfillment_Order_Id__c;
                            }
                            if(kit.Order_Summary__c != null)
                            {
                                detail.Order_Summary__c = kit.Order_Summary__c;
                            }


                            if(!labOrder.isEmpty())
                            {
                                system.debug('labOrder[0].Id'+labOrder[0].Id);
                                detail.Lab_Order__c=labOrder[0].Id;
                            }

                            detail.IS_Kit__c=true;

                            detail.Kit_Detail__c=kit.Id;
                            System.debug('Kit: ' + kit);

                            fullDetails.add(detail);
                        }


                    List<EOST_OMS_Log__c> logsToUpdate = refIdAndLogsMap.remove(kit.Activation_Code__c);
                    if(logsToUpdate!=null && !logsToUpdate.isEmpty())
                    {
                        for(EOST_OMS_Log__c logToUpdate : logsToUpdate)
                        {
                            if(kit.Fulfillment_Order_Id__c != null)
                            {
                                logToUpdate.Fulfillment_Order__c=kit.Fulfillment_Order_Id__c;
                            }
                            if(kit.Order_Summary__c != null)
                            {
                                logToUpdate.Order_Summary__c=kit.Order_Summary__c;
                            }
                            if(!labOrder.isEmpty())
                            {
                                logToUpdate.Lab_Order__c=labOrder[0].Id;
                            }
                            logToUpdate.Kit_Detail__c=kit.id;


                            updatedLogs.add(logToUpdate);
                        }
                    }

                }


            }
        }

        System.debug('Debug 5 :: ' + refAndDetails);
        System.debug('Debug 6 :: ' + fullDetails);
        System.debug('Debug 7 :: ' + updatedLogs);

        if(!refAndDetails.isEmpty())
        {
            List<EOST_OMS_Notification_Detail__c> pendingDetails =  refAndDetails.values();
            for(EOST_OMS_Notification_Detail__c pendingDetail : pendingDetails)
            {
                fullDetails.add(pendingDetail);
            }
        }

        if(!refIdAndLogsMap.isEmpty())
        {
            List<List<EOST_OMS_Log__c>> unProcessedLogs = refIdAndLogsMap.values();
            for(List<EOST_OMS_Log__c> openLogs : unProcessedLogs)
            {
                updatedLogs.addAll(openLogs);
            }

        }

        System.debug('Debug 8 :: ' + fullDetails);
        if(!fullDetails.isEmpty()){
             List<Database.UpsertResult> fullDetailsResults = Database.upsert(fullDetails, false);
        }

        if(!updatedLogs.isEmpty()){
             List<Database.UpsertResult> fullDetailsResults = Database.upsert(updatedLogs, false);
        }





    }
}