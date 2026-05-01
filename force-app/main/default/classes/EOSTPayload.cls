public with sharing class EOSTPayload {
    
        public class Headers {
            public String lockId;
            public String messageId;
        }

        
    
        public class PayloadWrapper {
            public Headers headers;
            public String body;
            
        }
    
        public static List<PayloadWrapper> parsePayload(String jsonString) {
            return (List<PayloadWrapper>) JSON.deserialize(jsonString, List<PayloadWrapper>.class);
        }
    
    
}