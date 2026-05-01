public class PingFed {
    
    public Static List<String> PingFed() {
        List<String> results = new List<String>();
        return results;
    }

    public class OAuthInput {
        @InvocableVariable(label='Auth URL' description='Authentication URL')
        public String authUrl;
        @InvocableVariable(label='client_id' description='client_id for authentication')
        public String client_id;
        @InvocableVariable(label='client_secret' description='client_secret for authentication')
        public String client_secret;
    }

    public class OAuthOutput {
        @InvocableVariable(label='Pingfed Access Token' description='Access token retrieved from authentication')
        public String accessToken;
        public OAuthOutput(String accessToken) {
            this.accessToken = accessToken;
        }
    }

    @InvocableMethod(label='PingFed Token' description='PingFed token')
    public static List<OAuthOutput> authenticateAndgetToken(List<OAuthInput> inputValues) {
        List<OAuthOutput> outputList = new List<OAuthOutput>();
        for (OAuthInput input : inputValues) {
            String accessToken = authenticate(input.authUrl, input.client_id, input.client_secret);
            outputList.add(new OAuthOutput(accessToken));
        }
        return outputList;
    }

    private static String authenticate(String authUrl, String client_id, String client_secret) {
        HttpRequest authRequest = new HttpRequest();
        authRequest.setEndpoint(authUrl);
        authRequest.setMethod('POST');
        //String authHeader = 'Basic ' + token;
        //authRequest.setHeader('Authorization', authHeader);
        String requestBody = 'grant_type='+ EncodingUtil.urlEncode('client_credentials', 'UTF-8') + '&scope=edit' + '&client_id=' + EncodingUtil.urlEncode(client_id, 'UTF-8') + '&client_secret=' + EncodingUtil.urlEncode(client_secret, 'UTF-8');
        authRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        authRequest.setBody(requestBody);
        Http http = new Http();
        
        HttpResponse authResponse = http.send(authRequest);
        if (authResponse.getStatusCode() == 200) {
            Map<String, Object> authResponseData = (Map<String, Object>) JSON.deserializeUntyped(authResponse.getBody());
            
            return (String) authResponseData.get('access_token');
        } else {
            throw new CalloutException('Authentication request failed with status code: ' + authResponse.getStatusCode());
        }
    }

    
}