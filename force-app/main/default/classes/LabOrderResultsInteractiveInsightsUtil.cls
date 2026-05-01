public without sharing class LabOrderResultsInteractiveInsightsUtil {

    public static Object fetchResults(String labOrderId, Boolean formatPdf)
    {
        HttpRequest authRequest = new HttpRequest();
        authRequest.setEndpoint(Label.OMS_Pingfed_URL);
        authRequest.setMethod('POST');
        //String authHeader = 'Basic ' + token;
        //authRequest.setHeader('Authorization', authHeader);
        String requestBody = 'grant_type='+ EncodingUtil.urlEncode('client_credentials', 'UTF-8') + '&scope=edit' + '&client_id=' + EncodingUtil.urlEncode(Label.OMS_Pingfed_Client_Id, 'UTF-8') + '&client_secret=' + EncodingUtil.urlEncode(Label.OMS_Pingfed_Client_Secret, 'UTF-8');
        authRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        authRequest.setBody(requestBody);
        Http http = new Http();
        
        HttpResponse authResponse = http.send(authRequest);
        if (authResponse.getStatusCode() == 200) {
            Map<String, Object> authResponseData = (Map<String, Object>) JSON.deserializeUntyped(authResponse.getBody());
            
            String token = (String) authResponseData.get('access_token');

            Lab_Order__c labOrder = [select Id,Client_Id__c,Accession_ID__c,Date_Reported__c,PerformingSite__c from Lab_Order__c where Id =: labOrderId];
            HttpResponse res;
            
            HttpRequest request = new HttpRequest();
                    
            try {
                
                    DateTime dateTimeReported = DateTime.newInstance(labOrder.Date_Reported__c.year(), labOrder.Date_Reported__c.month(), labOrder.Date_Reported__c.day());

                    String formattedDate = dateTimeReported.format('yyyy-MM-dd');
                    String endpoint = Label.OMS_Mule_Proxy_Ednpoint + 'qdx-interactive-insights-proxy-api/labResultsReport?perfsite='+labOrder.PerformingSite__c+'&clientId='+labOrder.Client_Id__c+'&accessionId='+labOrder.Accession_ID__c+'&reportedDate='+formattedDate;

                    System.debug('Fromat PDF : ' + formatPdf);

                    if(formatPdf)
                    {
                        endpoint = endpoint +'&format=pdf';
                    }
                    
                    
                    System.debug('Endpoint : ' + endpoint);
                   
                    request.setEndpoint(endpoint);
                    request.setMethod('GET');
                    request.setHeader('Content-Type','application/json');
                    request.setHeader('Authorization','Bearer ' + token);
                                      
                        res = http.send(request);

                        if (res.getStatusCode() == 200) {
                            if(formatPdf)
                            {
                                return res.getBodyAsBlob(); 
                            }
                            else {
                                String base64EncodedPdf = res.getBody();
                                if (base64EncodedPdf.startsWith('"') && base64EncodedPdf.endsWith('"')) {
                                    base64EncodedPdf = base64EncodedPdf.substring(1, base64EncodedPdf.length() - 1);
                                }
                            return base64EncodedPdf;    
                            }
                            
                        }
                        else{
                            System.debug('Exception Occured : ' + res.getBody());
                            return 'Error: ' + res.getBody();                       
                         }
                    }
                catch (Exception e)  {
                    System.debug('Exception Occured : ' + e.getMessage());
                    return 'Error: ' + e.getMessage();   
                } 
            }
            else {
                System.debug('Exception Occured : ' + authResponse.getBody());
                    return 'Error: ' + authResponse.getBody();  
            }
    }
}