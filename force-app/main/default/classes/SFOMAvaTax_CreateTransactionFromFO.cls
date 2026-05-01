/**
Name:: SFOMAvaTax_CreateTransactionFromFO
Description:: This class to create a transaction in Avalra upon the fulfilment order status is set to PWN Approved.
              Documet Date - PWN approved date.
              Status - Commit.
**/

public class SFOMAvaTax_CreateTransactionFromFO {

  /**
       Invokes create transaction API (/api/v2/transactions/create) to create the transaction in Avalra.
       
  **/
  @InvocableMethod(label='AvaTax - Create Transaction From FO' description='Creates Transaction.')
  public static  List<OutputParameters>  createTransaction(List<InputParameters> inputs){
  
  List<OutputParameters> outputs = new List<OutputParameters>();
  Set<Id> foIdSet = new Set<Id>();
  Map<Id,List<FulfillmentOrderLineItem>> foIdNdFOLstMap = new Map<Id,List<FulfillmentOrderLineItem>>();
  
  for(InputParameters input : inputs){
     Id foId=input.foId;
     foIdSet.add(foId);
  }
  
  Map<Id,FulfillmentOrder> fulfillmentOrderMap = new Map<Id,FulfillmentOrder>([Select Id,Document_Date__c,FulfillmentOrderNumber, OrderSummary.BillingEmailAddress,OrderSummary.OrderNumber,OrderSummary.AccountId, OrderSummary.Account.Name, OrderSummary.Account.AccountNumber, OrderSummary.OrderedDate,
                                                    FulfilledToCity,FulfilledToStreet,FulfilledToPostalCode,FulfilledToState,FulfilledToCountry from FulfillmentOrder where Id in:foIdSet]);
    
  List<FulfillmentOrderLineItem>  foItemsLst = [select Id, FulfillmentOrderLineItemNumber,totalPrice, TotalTaxAmount, OrderItemSummary.Product2Id, OrderItemSummary.Product2.avaoms__UPC__c, 
                          OrderItemSummary.ProductCode , Description, OrderItemSummary.Status, OrderItemSummary.Product2.Name,OrderItemSummary.Product2.Description,OrderItemSummary.OrderSummaryId, Quantity, 
                          OrderItemSummary.QuantityOrdered, UnitPrice, FulfillmentOrderId,OrderItemSummary.OrderDeliveryGroupSummary.DeliverToCity,OrderItemSummary.OrderDeliveryGroupSummary.DeliverToCountry, 
                          OrderItemSummary.OrderDeliveryGroupSummary.DeliverToPostalCode,OrderItemSummary.OrderDeliveryGroupSummary.DeliverToState,OrderItemSummary.OrderDeliveryGroupSummary.DeliverToStreet,
                          OrderItemSummary.OrderSummary.OrderNumber FROM FulfillmentOrderLineItem where FulfillmentOrderId in:fulfillmentOrderMap.keySet() order by FulfillmentOrderLineItemNumber asc];
                           
  if(foItemsLst!=null && foItemsLst.size()>0) {
      for(FulfillmentOrderLineItem foItem: foItemsLst){
          Id foId= foItem.FulfillmentOrderId;
          if(foIdNdFOLstMap.containsKey(foId)){
             foIdNdFOLstMap.get(foId).add(foItem);
          }
          else{
             List<FulfillmentOrderLineItem> foLst = new List<FulfillmentOrderLineItem>();
             folst.add(foItem);
             foIdNdFOLstMap.put(foId,foLst);
          }
      }
  }
  
  for(InputParameters input : inputs){
        Integer statusCode;
        List< FulfillmentOrderLineItem>  foItemLst;
        OutputParameters output = new OutputParameters();       
        Id foId=input.foId; 
        
        FulfillmentOrder fo = fulfillmentOrderMap.get(foId);
        if(foIdNdFOLstMap.containsKey(foId))
           foItemLst = foIdNdFOLstMap.get(foId);
              
        JSONGenerator gen = JSON.createGenerator(true);
          gen.writeStartObject();
            gen.writeStringField('type', 'SalesInvoice');
            gen.writeStringField('companyCode', 'DEFAULT');
            gen.writeStringField('customerCode', fo.OrderSummary.BillingEmailAddress);
            //gen.writeStringField('code', fo.OrderSummary.OrderNumber);
            gen.writeStringField('code', fo.OrderSummary.OrderNumber+'-'+fo.FulfillmentOrderNumber);
            gen.writeDateField('date', fo.Document_Date__c);
            gen.writeBooleanField('commit', true);  
            gen.writeStringField('description', fo.OrderSummary.OrderNumber);
          
            gen.writeFieldName('lines');
              gen.writeStartArray();
                Integer cnt = 1;
                for(FulfillmentOrderLineItem item: foItemLst){
                   gen.writeStartObject();
                     gen.writeStringField('number', cnt.format()); 
                     gen.writeNumberField('quantity', item.Quantity);
                     gen.writeNumberField('amount', item.TotalPrice);
                     gen.writeStringField('itemCode', item.OrderItemSummary.ProductCode);
                     gen.writeStringField('description', item.OrderItemSummary.Product2.Name);
                  gen.writeEndObject();
                  cnt++;
                 }
          gen.writeEndArray();
          gen.writeFieldName('addresses');
          gen.writeStartObject();
              //gen.writeStringField('singleLocation', null);
                 gen.writeFieldName('shipFrom');
                 gen.writeStartObject();

                      gen.writeStringField('line1', '500 PLAZA DR');

                      gen.writeStringField('city', 'SECAUCUS');

                      gen.writeStringField('region', 'NJ');

                      gen.writeStringField('country', 'US');

                      gen.writeStringField('postalCode', '07094-3619');
                 gen.writeEndObject();
                 gen.writeFieldName('shipTo');
                 gen.writeStartObject();
                    if(fo.FulfilledToStreet!=null)
                      gen.writeStringField('line1', fo.FulfilledToStreet);
                   if(fo.FulfilledToCity!=null)   
                      gen.writeStringField('city', fo.FulfilledToCity);
                   if(fo.FulfilledToState!=null)
                      gen.writeStringField('region', fo.FulfilledToState);
                   if(fo.FulfilledToCountry!=null)
                      gen.writeStringField('country', fo.FulfilledToCountry);
                   if(fo.FulfilledToPostalCode!=null)
                      gen.writeStringField('postalCode', fo.FulfilledToPostalCode);
                 gen.writeEndObject();
          gen.writeEndObject();        
        gen.writeEndObject();     
          
        String body = gen.getAsString();   
        System.debug(body);
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Avalara/transactions/create');
        request.setMethod('POST');
        request.setHeader('Content-Type','application/json');
        request.setBody(body);
        try{
          HttpResponse response = http.send(request); 
          statusCode= response.getStatusCode(); 
          if(statusCode>=400){
             output.errorMessage=response.getBody(); 
          }
        }
        catch(Exception e){
          output.errorMessage = 'Failed to create Transaction' + e.getMessage();
        }
        outputs.add(output);
   }    
    return outputs;
  }
   
    public class InputParameters {
      @InvocableVariable(required = true)
        public String foId;
    }
    
    
    public class OutputParameters{
        @InvocableVariable
        public Integer statusCode;
        @InvocableVariable
        public String errorMessage;
    }   
}