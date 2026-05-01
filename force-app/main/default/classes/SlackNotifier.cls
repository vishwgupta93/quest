public without sharing class SlackNotifier {
        
    public class RequestInput {
        @InvocableVariable(label='Message to publish' description='Message to publish')
        public String slackMessage;
        @InvocableVariable(label='Lab Order Id' description='Lab Order Id')
        public String labOrderId;
    }
    
    public class RequestOutput {      
        @InvocableVariable(label='Status' description='Status')
        public String status;
    }
    
        @InvocableMethod(label='Publish Slack Message' description='Sends Slack Notification Message on Case Creation')
        public static List<RequestOutput> sendSlackMessage(List<RequestInput> inputs) {
        List<RequestOutput> outputs = new List<RequestOutput>();
            String webhookUrl = Label.Slack_Webhook_URL;

        
        for(RequestInput input : inputs) {
            System.debug('input---------------- ' +  input);
            RequestOutput output = new RequestOutput();

            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(webhookUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('text', input.slackMessage);
            
            String body = JSON.serialize(payload);
            req.setBody(body);
            
            try {
                HttpResponse res = http.send(req);
                System.debug('Slack response: ' + res.getBody());
                output.status='Success';
            } catch (Exception e) {
                System.debug('Slack Notification Error: ' + e.getMessage());
                output.status='Error ' + e.getMessage();
            }

            outputs.add(output);
        }
        
        return outputs;
    }
}