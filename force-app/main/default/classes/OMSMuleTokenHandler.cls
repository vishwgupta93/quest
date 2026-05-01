public with sharing class OMSMuleTokenHandler {
   
    @future(callout=true)    
    public static void fetchTokenAndUpdate()
    {
        HttpRequest authRequest = new HttpRequest();
        String authUrl = Label.OMS_Mule_MQ_Auth_URL;
        String clientId = Label.OMS_Mule_MQ_Client_Id;
        String clientSecret = Label.OMS_Mule_MQ_Client_Secret;
        authRequest.setEndpoint(authUrl);
        authRequest.setMethod('POST');        
        String requestBody = 'grant_type='+ EncodingUtil.urlEncode('client_credentials', 'UTF-8') +  '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') + '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8');
        authRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        authRequest.setBody(requestBody);
        Http http = new Http();
        String accessToken = '';
        
        HttpResponse authResponse = http.send(authRequest);
        if (authResponse.getStatusCode() == 200) {
            Map<String, Object> authResponseData = (Map<String, Object>) JSON.deserializeUntyped(authResponse.getBody());
            
            accessToken =  (String) authResponseData.get('access_token');
            updateToken(accessToken);
            
        } else {
            throw new CalloutException('Authentication request failed with status code: ' + authResponse.getStatusCode());
        }

        
    }

    public static String fetchToken()
    {
        HttpRequest authRequest = new HttpRequest();
        String authUrl = Label.OMS_Mule_MQ_Auth_URL;
        String clientId = Label.OMS_Mule_MQ_Client_Id;
        String clientSecret = Label.OMS_Mule_MQ_Client_Secret;
        authRequest.setEndpoint(authUrl);
        authRequest.setMethod('POST');        
        String requestBody = 'grant_type='+ EncodingUtil.urlEncode('client_credentials', 'UTF-8') +  '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') + '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8');
        authRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        authRequest.setBody(requestBody);
        Http http = new Http();
        String accessToken = '';
        
        HttpResponse authResponse = http.send(authRequest);
        if (authResponse.getStatusCode() == 200) {
            Map<String, Object> authResponseData = (Map<String, Object>) JSON.deserializeUntyped(authResponse.getBody());
            
            accessToken =  (String) authResponseData.get('access_token');
            
        } else {
            throw new CalloutException('Authentication request failed with status code: ' + authResponse.getStatusCode());
        }

        return accessToken;
    }

    public static void updateToken(String accessToken)
    {
             System.debug('Token: ' + accessToken);
            List<OMS_Mule_MQ_Token__c> settings =  [SELECT Id, Token__c FROM OMS_Mule_MQ_Token__c LIMIT 1];
            if (!settings.isEmpty()) {
                OMS_Mule_MQ_Token__c setting = settings[0];
                setting.Token__c = accessToken;
                update setting;
                System.debug('Custom setting updated with Token value: ' + setting.Token__c);
            }
            else
            {
                OMS_Mule_MQ_Token__c setting = new OMS_Mule_MQ_Token__c();
                setting.Token__c = accessToken;
                insert setting;
                System.debug('Custom setting created with Token value: ' + setting.Token__c);
            }
    }
}