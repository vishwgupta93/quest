@RestResource(urlMapping='/kits/*')
global with sharing class KitActivation {
        
     @HttpPost
     @RestResource(urlMapping='/detail/*')
    global static Kit_Details__c getKitDetail(RequestData requestData)
    {
//     System.debug(requestBody); 
        //RestRequest req = RestContext.request;
        //Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
//        RequestData requestData = (RequestData) JSON.deserialize(requestBody, RequestData.class);
        String activationCode = requestData.activationCode;
        String testTakerId = requestData.testTakerId;

        //String activationCode = req.params.get('activationCode');
        //String testTakerId = req.params.get('testTakerId');
        Kit_Details__c kitDetail = new Kit_Details__c();

        List<Kit_Details__c> kits = [select Id,Activation_Code__c,Status__c,Type__c,Item_Code__c,Ordered_Date__c,Purchaser_PRS_ID__c,Expiration_Date__c,Lot_Number__c,Serial_Number__c,Verification_ID__c,PerformingSite__c from Kit_Details__c where Activation_Code__c = :activationCode];
        
        if(!kits.isEmpty())
        {
            Kit_Details__c kit = kits[0];
            String status = kit.Status__c;
            String type = kit.Type__c;
            
            if(status == 'Available')
            {
                if(type == 'GSS')
                {
                List<String> statusesToIgnore= new List<String>{'Expired', 'Damaged','Available','Unavailable'};
                    List<Kit_Details__c> gssKit = [select Id from Kit_Details__c where ActivationUser_Customer_Id__c= :testTakerId and Status__c not in :statusesToIgnore and Override__c = false and Type__c = 'GSS'];
                    if(!gssKit.isEmpty())
                    {
                        kit.Eligible_For_Activation__c = false;
                    }
                 else
                {
                    kit.Eligible_For_Activation__c = true;
                }
                    
                }
                else
                {
                    kit.Eligible_For_Activation__c = true;
                }
            }
             else
                {
                    kit.Eligible_For_Activation__c = false;
                } 
                
                if(kit.Ordered_Date__c == null)
                    kit.Ordered_Date__c = System.today();               
                                
                kitDetail = kit;
        }
        
        return kitDetail ;
        
    }
    
    global class RequestData {
    public String activationCode { get; set; }
    public String testTakerId { get; set; }
}
}