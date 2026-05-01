/**
 * Name:: SFOMAvaTax_CreateTransaction
 * Description:: Creates the tranaction in Avalra.This class is invoked when the order summary record is created with tax recalulation flag is set to true.
 * 
 * 
 **/

public class SFOMAvaTax_CreateTransaction {

    @InvocableMethod(label='AvaTax - Create Transaction' description='Creates Transaction.')

    public static  List<OutputParameters>  createTransaction(List<InputParameters> inputs){
    List<OutputParameters> outputs = new List<OutputParameters>();
    Set<Id> orderSummaryIdSet = new Set<Id>();
    Map<Id,List<OrderItemSummary>> oSumIdNdItemsLstMap = new Map<Id,List<OrderItemSummary>>();
   
    for(InputParameters input : inputs){
        String orderSummaryId=input.orderSummaryId; 
        orderSummaryIdSet.add(orderSummaryId);
    }
    
    Map<Id,OrderSummary> OrderSummaryMap = new Map<Id,OrderSummary>([Select Id, OrderedDate,BillingEmailAddress, BillingStreet,BillingCity,BillingCountry,BillingPostalCode,BillingState, OrderNumber from OrderSummary where Id in: orderSummaryIdSet]);
    
    List<OrderItemSummary>  oItemSmryLst = [Select Id, OrderSummaryId,quantity,TotalPrice, ProductCode, Description, OrderDeliveryGroupSummary.DeliverToCity,OrderDeliveryGroupSummary.DeliverToCountry,OrderDeliveryGroupSummary.DeliverToPostalCode,
                                                 OrderDeliveryGroupSummary.DeliverToState,OrderDeliveryGroupSummary.DeliverToStreet from OrderItemSummary where OrderSummaryId in:OrderSummaryMap.keySet() order by LineNumber asc];
    
    
    if(oItemSmryLst!=null && oItemSmryLst.size()>0) {
      for(OrderItemSummary orderItem: oItemSmryLst){
          Id oSummaryId= orderItem.OrderSummaryId;
          if(oSumIdNdItemsLstMap.containsKey(oSummaryId)){
             oSumIdNdItemsLstMap.get(oSummaryId).add(orderItem);
          }
          else{
             List<OrderItemSummary> oItemLst = new List<OrderItemSummary>();
             oItemLst.add(orderItem);
             oSumIdNdItemsLstMap.put(oSummaryId,oItemLst);
          }
      }
   }
                                           
    for(InputParameters input : inputs){
    
        Integer statusCode;
        OutputParameters output = new OutputParameters();       
        Id orderSummaryId=input.orderSummaryId; 
        
        
        //JSONGenerator gen = generateBody(orderSummaryId);
        OrderSummary oSummary = OrderSummaryMap.get(orderSummaryId);
        List<OrderItemSummary> oItemSummaryLst = oSumIdNdItemsLstMap.get(orderSummaryId); 

        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('type', 'SalesInvoice');
        gen.writeStringField('companyCode', 'DEFAULT');
        gen.writeStringField('customerCode', oSummary.BillingEmailAddress);
        gen.writeStringField('code', oSummary.OrderNumber);
        gen.writeDateField('date', date.newinstance(oSummary.OrderedDate.year(), oSummary.OrderedDate.month(), oSummary.OrderedDate.day()));
        gen.writeBooleanField('commit', false);  
        gen.writeStringField('description', oSummary.OrderNumber);
      
        gen.writeFieldName('lines');
          gen.writeStartArray();
            Integer cnt = 1;
            for(OrderItemSummary item: oItemSummaryLst){
               gen.writeStartObject();
               gen.writeStringField('number', cnt.format()); 
               gen.writeNumberField('quantity', item.quantity);
               gen.writeNumberField('amount', item.TotalPrice);
               gen.writeStringField('itemCode', item.ProductCode);
               gen.writeStringField('description', item.Description);
                 
              gen.writeEndObject();
              cnt++;
             }
      gen.writeEndArray();
      gen.writeFieldName('addresses');
      gen.writeStartObject();
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

               if(oSummary.BillingStreet!=null)
                  gen.writeStringField('line1', oSummary.BillingStreet);
               if(oSummary.BillingCity!=null)   
                  gen.writeStringField('city', oSummary.BillingCity);
               if(oSummary.BillingState!=null)
                  gen.writeStringField('region', oSummary.BillingState);
               if(oSummary.BillingCountry!=null)
                  gen.writeStringField('country', oSummary.BillingCountry);
               if(oSummary.BillingPostalCode!=null)
                 gen.writeStringField('postalCode', oSummary.BillingPostalCode);
             gen.writeEndObject();
      gen.writeEndObject();             
    gen.writeEndObject(); 
    
    String body = gen.getAsString(); 
     
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Avalara/transactions/create');
        request.setMethod('POST');
        request.setHeader('Content-Type','application/json');
        request.setBody(body);
        System.debug('Request::'+request);
        System.debug(body);
        try{
          HttpResponse response = http.send(request); 
          statusCode = response.getStatusCode(); 
          
          if(statusCode>=400){
             output.errorMessage=response.getBody(); 
          }
        }
        catch(Exception e){
          output.errorMessage = 'Failed to create Transaction' + e.getMessage();
        }
        output.statusCode=statusCode;
        outputs.add(output);
   }  
     
    return outputs;
  }

    public class InputParameters {
        @InvocableVariable(required = true)
        public String orderSummaryId;
    }

    public class OutputParameters {
        @InvocableVariable
        public Integer statusCode;
        @InvocableVariable
        public String errorMessage;
    }

   /**    public Static JSONGenerator

 generateBody(String orderSummaryId) {
      
      OrderSummary oSummary = [Select Id, OrderedDate,BillingEmailAddress, BillingStreet,BillingCity,BillingCountry,BillingPostalCode,BillingState, OrderNumber from OrderSummary where Id = : orderSummaryId];
      OrderDeliveryGroupSummary odgs = [SELECT DeliverToCity,DeliverToCountry,DeliverToPostalCode,DeliverToState,DeliverToStreet FROM OrderDeliveryGroupSummary where OrderSummaryId =:orderSummaryId limit 1];
      List<OrderItemSummary>  oItemSummaryLst = [Select Id, quantity,TotalPrice, ProductCode, Description, OrderDeliveryGroupSummary.DeliverToCity,OrderDeliveryGroupSummary.DeliverToCountry,OrderDeliveryGroupSummary.DeliverToPostalCode,
                                                 OrderDeliveryGroupSummary.DeliverToState,OrderDeliveryGroupSummary.DeliverToStreet from OrderItemSummary where OrderSummaryId=:orderSummaryId order by LineNumber asc];
      

                         
      JSONGenerator gen = JSON.createGenerator(true);
      gen.writeStartObject();
        gen.writeStringField('type', 'SalesInvoice');
        gen.writeStringField('companyCode', 'DEFAULT');
        gen.writeStringField('customerCode', oSummary.BillingEmailAddress);
        gen.writeStringField('code', oSummary.OrderNumber);
        gen.writeDateField('date', date.newinstance(oSummary.OrderedDate.year(), oSummary.OrderedDate.month(), oSummary.OrderedDate.day()));
        gen.writeBooleanField('commit', false);  
        gen.writeStringField('description', oSummary.OrderNumber);
      
        gen.writeFieldName('lines');
          gen.writeStartArray();
            Integer cnt = 1;
            for(OrderItemSummary item: oItemSummaryLst){
               gen.writeStartObject();
               gen.writeStringField('number', cnt.format()); 
               gen.writeNumberField('quantity', item.quantity);
               gen.writeNumberField('amount', item.TotalPrice);
               gen.writeStringField('itemCode', item.ProductCode);
               gen.writeStringField('description', item.Description);
                 
              gen.writeEndObject();
              cnt++;
             }
      gen.writeEndArray();
      gen.writeFieldName('addresses');
      gen.writeStartObject();
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
               gen.writeStringField('line1', odgs.DeliverToStreet);
               gen.writeStringField('city', odgs.DeliverToCity);
               gen.writeStringField('region', odgs.DeliverToState);
               gen.writeStringField('country', odgs.DeliverToCountry);
               gen.writeStringField('postalCode', odgs.DeliverToPostalCode);
             gen.writeEndObject();
      gen.writeEndObject();     
    gen.writeEndObject();     
      return gen;
    }
    **/
}