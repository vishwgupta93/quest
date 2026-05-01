public with sharing class QuestSchedulingController {

    private static final String SCOPE =
        'M2MResourceServer/read M2MResourceServer/write ' +
        'M2MResourceServer/client:APPLE_HEALTH M2MResourceServer/service:SCHEDULING_SDK';

    // TODO: replace with Named Credential merge fields once External Credential permissions are resolved
    private static final String CLIENT_ID     = '3e1me24h4ink79nm8n5fm6060i';
    private static final String CLIENT_SECRET = 'ng41du28pt7hapgqri4g1p287424mr374al5hciqb2d3ejdiok';

    @AuraEnabled(cacheable=false)
    public static String getAccessToken() {
        try {
            String encoded = EncodingUtil.base64Encode(
                Blob.valueOf(CLIENT_ID + ':' + CLIENT_SECRET)
            );

            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api-stage-auth.questdiagnostics.com/oauth2/token');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setHeader('Authorization', 'Basic ' + encoded);
            req.setBody('grant_type=client_credentials&scope=' + EncodingUtil.urlEncode(SCOPE, 'UTF-8'));

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
}