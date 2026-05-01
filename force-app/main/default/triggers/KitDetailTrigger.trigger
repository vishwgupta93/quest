trigger KitDetailTrigger on Kit_Activation_Event__e (after insert) {

    Map<String,String> activationCodeMap= new Map<String,String>();
 

 for (Kit_Activation_Event__e event : Trigger.New) {
      if(event.Activation_Code__c!=null ) {
        activationCodeMap.put(event.Activation_Code__c,event.Lab_Ref_Id__c);
                  }
 }
 
 for(String activationCode : activationCodeMap.keySet())
 {
     KitDetailEventTriggerHandler.sendPayLoad(activationCode ,activationCodeMap.get(activationCode));
 }
}