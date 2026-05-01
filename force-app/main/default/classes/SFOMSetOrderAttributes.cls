/**
 Name:: SFOMSetOrderAttributes
 Description:: This class is to assign record type on FO based on test type of the line items.
**/
global class SFOMSetOrderAttributes {
    @InvocableMethod(label='Set Fulfillment Order Attributes' description='Set attributes on Fulfillment Order' category='Fulfillment Order')
    public static void copyOrderAttributes(List<ID> lstOrderSummaryIds) {     
        
        Map<String,Schema.RecordTypeInfo> RecordTypeInfo = Schema.getGlobalDescribe().get('FulfillmentOrder').getDescribe().getRecordTypeInfosByDeveloperName();
        String atHomeOTCClearedTypeId =  RecordTypeInfo.get('At_home_OTC_Cleared').getRecordTypeId();  //Label.SFOM_OTC_Cleared_Record_Type_Id;
        String atHomeSelfRecTypeId = RecordTypeInfo.get('At_home_Self').getRecordTypeId(); //Label.SFOM_At_Home_Self_Record_Type_ID;
        String gssRecTypeId = RecordTypeInfo.get('GSS').getRecordTypeId(); //label.SFOM_GSS_Record_Type_Id;
        String inPersonRecTypeId = RecordTypeInfo.get('InPerson').getRecordTypeId(); //label.SFOM_In_Person_Record_Type_Id;
        String pwnServiceRecTypeId = RecordTypeInfo.get('PWN_Service').getRecordTypeId(); //label.SFOM_PWN_Service_Record_Type_Id;
        String thirdPartyRecTypeId = RecordTypeInfo.get('Third_Party').getRecordTypeId(); //label.SFOM_Third_Party_Record_Type_Id;
		String packHealthRecTypeId = RecordTypeInfo.get('PackHealth').getRecordTypeId(); 


        
        
        Map<Id, FulfillmentOrder> FulfillmentOrdersToUpdate = new Map<Id, FulfillmentOrder>();
        Map<Id,Decimal> foCancellationFeeMap= new Map<Id,Decimal>();
        Map<Id,Boolean> foMobilePhlebotomyMap= new Map<Id,Boolean>();
      

        // and Test_Type__c!='PSC'
        List<FulfillmentOrderLineItem> foLineItemLst = [SELECT Id,Test_Type__c, Resulting_Required__c,OrderItemSummary.Is_Service__c,OrderItemSummary.OTCCleared__c,FulfillmentOrderId,OrderItemSummary.OrderDeliveryGroupSummaryId,OrderItemSummary.OrderDeliveryGroupSummary.First_Name__c,OrderItemSummary.OrderDeliveryGroupSummary.Last_Name__c,
                                                        OrderItemSummary.OrderDeliveryGroupSummary.ShippingAddressLine1__c,OrderItemSummary.OrderDeliveryGroupSummary.ShippingAddressLine2__c, Customer_Id__c,OrderItemSummary.OrderDeliveryGroupSummary.companyName__c,
                                                       OrderItemSummary.Product_cancel_fee__c
                                                        
                                                        from FulfillmentOrderLineItem where FulfillmentOrder.OrderSummaryId IN :lstOrderSummaryIds and FulfillmentOrder.StatusCategory ='Activated' and Test_Type__c!=null and Type!='Delivery Charge'];
       
        for(FulfillmentOrderLineItem foLineItem:foLineItemLst){
            String recordTypeId;
            

            FulfillmentOrder fo = new FulfillmentOrder(Id=foLineItem.FulfillmentOrderId,FirstName__c=foLineItem.OrderItemSummary.OrderDeliveryGroupSummary.First_Name__c,
            LastName__c=foLineItem.OrderItemSummary.OrderDeliveryGroupSummary.Last_Name__c,
                                                       FulfilledToAddressLine1__c=foLineItem.OrderItemSummary.OrderDeliveryGroupSummary.ShippingAddressLine1__c, 
                                                       FulfilledToAddressLine2__c = foLineItem.OrderItemSummary.OrderDeliveryGroupSummary.ShippingAddressLine2__c,
                                                       Business_Name__c=foLineItem.OrderItemSummary.OrderDeliveryGroupSummary.companyName__c);
            
            
           if(!foLineItem.Resulting_Required__c && foLineItem.Test_Type__c !='PA' && foLineItem.Test_Type__c != label.SFOM_Inperson_Test_Type && 
                foLineItem.Test_Type__c != Label.SFOM_Test_Type_GSS && foLineItem.Test_Type__c != 'PackHealth') {
               recordTypeId =thirdPartyRecTypeId;
            }            
            else if(foLineItem.Test_Type__c == label.SFOM_Inperson_Test_Type){
               recordTypeId =inPersonRecTypeId;
               
               System.debug('******************'+ foLineItem.OrderItemSummary.Is_Service__c);
               
               if(foLineItem.OrderItemSummary.Is_Service__c)
               {
               foMobilePhlebotomyMap.put(foLineItem.FulfillmentOrderId,true);
                 
               }
               
            }
            else if(foLineItem.Test_Type__c == label.SFOM_Test_Type_At_home && foLineItem.OrderItemSummary.OTCCleared__c){
               recordTypeId = atHomeOTCClearedTypeId;             
            }
            else if(foLineItem.Test_Type__c == label.SFOM_Test_Type_At_home && !foLineItem.OrderItemSummary.OTCCleared__c) {
               recordTypeId = atHomeSelfRecTypeId;
            }           
            else if(foLineItem.Test_Type__c == Label.SFOM_Test_Type_GSS) {
               recordTypeId=gssRecTypeId;
            }
            else if(foLineItem.Test_Type__c =='PA') {
                recordTypeId=pwnServiceRecTypeId;
            } 
            //08/10/24 changes by ramana
           else if(foLineItem.Test_Type__c == 'PackHealth'){
                fo.Is_Packhealth__c = true;
                recordTypeId = packHealthRecTypeId;
            }
            //ends
            if(recordTypeId!=pwnServiceRecTypeId)
            {
                Decimal foCancellationFee = foLineItem.OrderItemSummary.Product_cancel_fee__c;
                Decimal currentCancellationFee=foCancellationFeeMap.get(foLineItem.FulfillmentOrderId);
                if(foCancellationFee > 0 || currentCancellationFee != null)
                {                    
                    if(currentCancellationFee == null)
                    {
                        foCancellationFeeMap.put(foLineItem.FulfillmentOrderId,foCancellationFee);
                    }
                    else if(currentCancellationFee<foCancellationFee)
                    {
                        foCancellationFeeMap.put(foLineItem.FulfillmentOrderId,foCancellationFee);
                    }
                    fo.Service_Fee__c=foCancellationFeeMap.get(foLineItem.FulfillmentOrderId);
                }
                else
                {
                    fo.Service_Fee__c=20.0;
                }
                
            }
            
           
            
            if(recordTypeId!=null) {
              fo.recordTypeId=recordTypeId;
              if(foMobilePhlebotomyMap.get(foLineItem.FulfillmentOrderId) != null && foMobilePhlebotomyMap.get(foLineItem.FulfillmentOrderId) == true)
              {
                  fo.Is_Mobile_Phlebotomy__c = true;
              }
              
              FulfillmentOrdersToUpdate.put(foLineItem.FulfillmentOrderId,fo);
            }
        }
        
  
        
        
        System.debug('FO to Update ******************'+FulfillmentOrdersToUpdate);
        if(FulfillmentOrdersToUpdate!=null && FulfillmentOrdersToUpdate.size()>0){
            update FulfillmentOrdersToUpdate.values();
        }
    }
    
}