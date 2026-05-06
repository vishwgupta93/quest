public with sharing class QuestSchedulingController {

    private static Quest_API_Config__mdt getActiveConfig() {
        List<Quest_API_Config__mdt> configs = [
            SELECT Client_Id__c, Client_Secret__c, Auth_URL__c, Scope__c, API_Base_URL__c, VF_Origin__c
            FROM Quest_API_Config__mdt
            WHERE Is_Active__c = true
            LIMIT 1
        ];
        if (configs.isEmpty()) {
            throw new AuraHandledException('No active Quest API configuration found. Enable one Quest_API_Config__mdt record.');
        }
        return configs[0];
    }

    @AuraEnabled(cacheable=false)
    public static String getAccessToken() {
        try {
            Quest_API_Config__mdt config = getActiveConfig();

            String encoded = EncodingUtil.base64Encode(
                Blob.valueOf(config.Client_Id__c + ':' + config.Client_Secret__c)
            );

            HttpRequest req = new HttpRequest();
            req.setEndpoint(config.Auth_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setHeader('Authorization', 'Basic ' + encoded);
            req.setBody('grant_type=client_credentials&scope=' + EncodingUtil.urlEncode(config.Scope__c, 'UTF-8'));

            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                return (String) body.get('access_token');
            }

            throw new AuraHandledException(
                'Token request failed: HTTP ' + res.getStatusCode() + ' — ' + res.getBody()
            );
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to obtain access token: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getConfig() {
        try {
            Quest_API_Config__mdt config = getActiveConfig();
            return new Map<String, String>{
                'apiBaseUrl' => config.API_Base_URL__c,
                'vfOrigin'   => config.VF_Origin__c
            };
        } catch (Exception e) {
            throw new AuraHandledException('Failed to load API config: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String encryptOrderId(String orderId) {
        try {
            return LabOrderCryptoUtils.enryptOrderNumberFromSFCC(orderId);
        } catch (Exception e) {
            throw new AuraHandledException('Encryption failed: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String decryptOrderId(String encryptedId) {
        try {
            return LabOrderCryptoUtils.getDecryptedData(encryptedId);
        } catch (Exception e) {
            throw new AuraHandledException('Decryption failed: ' + e.getMessage());
        }
    }
}
