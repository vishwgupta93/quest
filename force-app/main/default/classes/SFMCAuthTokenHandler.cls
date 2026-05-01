public class SFMCAuthTokenHandler{
 public class TokenResponse {
        public String access_token { get; set; }
    }
    
    public class TokenRequest {
        public String grant_type { get; set; }
        public String client_id { get; set; }
        public String client_secret { get; set; }
        public String account_id { get; set; }
    }
    @future(callout=true)
    public static void fetchTokenAndUpdate() {
        // Set up the request data

        List<SFMC_OMS_Config__c> configsToUpsert = new List<SFMC_OMS_Config__c>();
        TokenRequest tokenRequest = new TokenRequest();
         


        // Set up the request data
        tokenRequest = new TokenRequest();
         tokenRequest.grant_type = 'client_credentials';
        tokenRequest.client_id = Label.SFMC_Common_Client_ID;
        tokenRequest.client_secret = Label.SFMC_Common_Client_Secret;
        tokenRequest.account_id = Label.SFMC_Common_Account_ID;

        // Convert request data to JSON
        String requestJson = JSON.serialize(tokenRequest);

        // Set up the HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(Label.SFMC_Auth_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(requestJson);

        // Set up the HTTP response
        Http http = new Http();
        HttpResponse res = http.send(req);

        // Check the response status
        if (res.getStatusCode() == 200) {
            
            TokenResponse tokenResponse = (TokenResponse)JSON.deserialize(res.getBody(), TokenResponse.class);
            String newToken = tokenResponse.access_token;

            // Update the Custom Setting
           List<SFMC_OMS_Config__c> configs = [select Id, Auth_Token__c from SFMC_OMS_Config__c  where Channel__c = 'QD-CIT' and API__c = 'Common'];
            if (configs.isEmpty()) {
                SFMC_OMS_Config__c  newConfig= new SFMC_OMS_Config__c (Channel__c = 'QD-CIT',Auth_Token__c =newToken,API__c = 'Common');
                configsToUpsert.add(newConfig);
            }
            else
            {
                SFMC_OMS_Config__c config= configs[0];
                config.Auth_Token__c= newToken;
                configsToUpsert.add(config);
            }
            
        } else {
           
            System.debug('Error fetching token. Status code: ' + res.getStatusCode() + ', Response: ' + res.getBody());
        }

        upsert configsToUpsert;
    }
}