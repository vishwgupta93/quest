/**
 * This class is to create return invoice in Avalra upon cancellation of orders or appeasement. 
 * Document date is the current date and tax date is the order summary creation date. 
 * 
 **/

public class SFOMAvaTax_CreateReturnInvoice {

/**
  Name:: createTransaction
  Description:: Creates the transaction in Avalra.
**/
    @InvocableMethod(label='AvaTax - Create Return Invoice' description='Creates Creates Return Invoice.')
    public static  List<OutputParameters>  createTransaction(List<InputParameters> inputs){
    List<OutputParameters> outputs = new List<OutputParameters>();
    Set<Id> orderIdSet = new  Set<Id> ();
    Set<String> orderSmryNoSet = new Set<String> ();
    Map<Id, List<OrderItem>> orderIdNdOrderItemsMap = new Map<Id, List<OrderItem>>(); 
    Map<String,OrderSummary> orderSummaryMap = new  Map<String,OrderSummary>(); 
        
    for(InputParameters input : inputs){
       String changeOrderId=input.changeOrderId; 
       orderIdSet.add(changeOrderId);
    }
    
    System.debug('*********************** + orderIdSet' +orderIdSet);
    Map<Id,Order> orderMap = new Map<Id,Order>([Select Id, OrderNumber,RelatedOrder.OrderReferenceNumber from Order where Id in: orderIdSet]);
    
    List<OrderItem>  oItemLst = [Select Id,OrderId, quantity,TotalPrice, Product2.Name,Product2.ProductCode, Description, order.Id,order.OrderNumber,order.RelatedOrder.OrderReferenceNumber,RelatedOrderItem.OrderDeliveryGroup.DeliverToCity, 
                                 RelatedOrderItem.OrderDeliveryGroup.DeliverToCountry,RelatedOrderItem.OrderDeliveryGroup.DeliverToPostalCode,RelatedOrderItem.OrderDeliveryGroup.DeliverToState,RelatedOrderItem.OrderDeliveryGroup.DeliverToStreet,
                                 RelatedOrderItem.Order.BillingEmailAddress,RelatedOrderItem.Order.OrderReferenceNumber from OrderItem where OrderId in: orderIdSet order by LineNumber asc];
    
   
   for(OrderItem oItem:oItemLst){
       orderSmryNoSet.add(oItem.order.RelatedOrder.OrderReferenceNumber);
       if(orderIdNdOrderItemsMap.containsKey(oItem.OrderId)){
          orderIdNdOrderItemsMap.get(oItem.orderId).add(oItem);
       }
       else{
           List<OrderItem> itemLst = new List<OrderItem>();
           itemLst.add(oItem);
           orderIdNdOrderItemsMap.put(oItem.orderId,itemLst);
       }
   }
   
   List<OrderSummary> oSummaryLst = [Select Id, OrderedDate,BillingEmailAddress, BillingStreet,BillingCity,BillingCountry,BillingPostalCode,BillingState, OrderNumber from OrderSummary where OrderNumber in : orderSmryNoSet];
   
   for(OrderSummary oSummary:oSummaryLst){
       orderSummaryMap.put(oSummary.OrderNumber,oSummary);
   }
   
    for(InputParameters input : inputs){
        Integer statusCode;
        OutputParameters output = new OutputParameters();       
        Id changeOrderId=input.changeOrderId; 
        Order changeOrder = orderMap.get(changeOrderId);
        String orderNo  = changeOrder.RelatedOrder.OrderReferenceNumber;
        String changeOrderNo = changeOrder.OrderNumber;
        String shippingStreet;
        String shippingCity;
        String shippingState;
        String shippingCountry;
        String shippingPostalCode;

        OrderSummary oSummary = orderSummaryMap.get(orderNo);
        List<OrderItem> oItemList = orderIdNdOrderItemsMap.get(changeOrderId);
               
        JSONGenerator gen = JSON.createGenerator(true);
          gen.writeStartObject();
            gen.writeStringField('type', 'ReturnInvoice');
            gen.writeStringField('companyCode', 'DEFAULT');
            gen.writeStringField('customerCode', oSummary.BillingEmailAddress);
            gen.writeStringField('code', oSummary.OrderNumber+'-'+changeOrderNo);
            gen.writeDateField('date', System.today());
            gen.writeBooleanField('commit', true);  
            gen.writeStringField('description', oSummary.OrderNumber);
          
            gen.writeFieldName('lines');
              gen.writeStartArray();
                Integer cnt = 1;
                for(OrderItem item: oItemList){
                     decimal qnty=item.quantity;
                     if(qnty==0)
                        qnty=1;
                     else if(qnty<0)
                       qnty=qnty*-1;
                        
                   gen.writeStartObject();
                     gen.writeStringField('number', cnt.format());                  
                     gen.writeNumberField('quantity',qnty);                 
                     gen.writeNumberField('amount', item.TotalPrice);
                     gen.writeStringField('itemCode', item.Product2.ProductCode);
                     gen.writeStringField('description', item.Product2.Name);
                  gen.writeEndObject();
                  
                  shippingStreet =item.RelatedOrderItem.OrderDeliveryGroup.DeliverToState;
                  shippingCity = item.RelatedOrderItem.OrderDeliveryGroup.DeliverToCity;
                  shippingState = item.RelatedOrderItem.OrderDeliveryGroup.DeliverToState;
                  shippingCountry =item.RelatedOrderItem.OrderDeliveryGroup.DeliverToCountry;
                  shippingPostalCode = item.RelatedOrderItem.OrderDeliveryGroup.DeliverToPostalCode;

                  cnt++;
                 }
          gen.writeEndArray();
          gen.writeFieldName('addresses');
          gen.writeStartObject();
              //gen.writeFieldName('singleLocation');
                gen.writeFieldName('shipFrom');
                 gen.writeStartObject();
                  gen.writeStringField('line1', shippingStreet);
                  gen.writeStringField('city', shippingCity);
                  gen.writeStringField('region', shippingState);
                  gen.writeStringField('country', shippingCountry);
                  gen.writeStringField('postalCode', shippingPostalCode);
                 gen.writeEndObject();
                 gen.writeFieldName('shipTo');
                 gen.writeStartObject();

                      gen.writeStringField('line1', '500 PLAZA DR');

                      gen.writeStringField('city', 'SECAUCUS');

                      gen.writeStringField('region', 'NJ');

                      gen.writeStringField('country', 'US');

                      gen.writeStringField('postalCode', '07094-3619');
                 gen.writeEndObject();
          
          gen.writeEndObject();
          
          gen.writeFieldName('taxOverride');
          gen.writeStartObject();
            gen.writeDateField('taxDate', date.newinstance(oSummary.OrderedDate.year(), oSummary.OrderedDate.month(), oSummary.OrderedDate.day()));
            gen.writeStringField('type', 'taxDate');
            gen.writeStringField('reason', 'create Transaction');
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
          output.errorMessage = 'Failed to create Return Invoice' + e.getMessage();
        }
        output.statusCode=statusCode;
        outputs.add(output);
   }  
     
    return outputs;
  }

    public class InputParameters {
        @InvocableVariable(required = true)
        public String changeOrderId;
    }

    public class OutputParameters {
        @InvocableVariable
        public Integer statusCode;
        @InvocableVariable
        public String errorMessage;
    }
    
}