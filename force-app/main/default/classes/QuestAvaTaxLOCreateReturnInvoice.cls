public with sharing class QuestAvaTaxLOCreateReturnInvoice {
    /**
  Name:: createTransaction
  Description:: Creates the transaction in Avalra.
**/
@InvocableMethod(label='LO AvaTax - Create Return Invoice' description='Creates Creates Return Invoice for LO.')
public static  List<OutputParameters>  createTransaction(List<InputParameters> inputs){
List<OutputParameters> outputs = new List<OutputParameters>();
Set<Id> orderIdSet = new  Set<Id> ();
Set<String> orderSmryNoSet = new Set<String> ();
Map<Id, List<OrderItem>> orderIdNdOrderItemsMap = new Map<Id, List<OrderItem>>(); 
Map<String,OrderSummary> orderSummaryMap = new  Map<String,OrderSummary>(); 

    
for(InputParameters input : inputs){
   String orderId=input.changeOrderId; 
Map<Id,Order> orderMap = new Map<Id,Order>([Select Id, OrderNumber,OrderReferenceNumber from Order where Id =:orderId]);
System.debug('*********************** + orderMap' +orderMap);

List<OrderItem>  oItemLst = [Select Id,OrderId, quantity,TotalPrice,TestType__c,TotalTaxAmount, Product_cancel_fee__c, Product2.Name,Product2.ProductCode, Description, order.Id,order.OrderNumber,order.OrderReferenceNumber,OrderItem.OrderDeliveryGroup.DeliverToCity, 
                             OrderItem.OrderDeliveryGroup.DeliverToCountry,OrderItem.OrderDeliveryGroup.DeliverToPostalCode,OrderItem.OrderDeliveryGroup.DeliverToState,OrderItem.OrderDeliveryGroup.DeliverToStreet,
                             OrderItem.Order.BillingEmailAddress from OrderItem where OrderId =:orderId order by LineNumber asc];


for(OrderItem oItem:oItemLst){
   orderSmryNoSet.add(oItem.order.OrderReferenceNumber);
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
Set<String> orderSummaryIdSet = new Set<String>();

for(OrderSummary oSummary:oSummaryLst){
   orderSummaryMap.put(oSummary.OrderNumber,oSummary);
   orderSummaryIdSet.add(oSummary.Id);
}
List<String> recordTypeList = new List<String>{Label.SFOM_At_Home_Self_Record_Type_ID,Label.SFOM_OTC_Cleared_Record_Type_Id};
Map<Id,FulfillmentOrder> foMap = new Map<Id,FulfillmentOrder>([Select Id, recordtypeid from FulfillmentOrder where OrderSummaryId in: orderSummaryIdSet and RecordTypeId in : recordTypeList]);
boolean isMixedCart = foMap != null && !foMap.isEmpty();

    Integer statusCode;
    OutputParameters output = new OutputParameters();       
    Id changeOrderId=input.changeOrderId; 
    Order changeOrder = orderMap.get(changeOrderId);
    String orderNo  = changeOrder.OrderReferenceNumber;
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
            boolean feeApplied=false;
            for(OrderItem item: oItemList){

              if(isMixedCart && item.TestType__c !='PSC'){
                  continue;
              }
              Decimal qnty = item.quantity;
              if(qnty == 0)
                  qnty = 1;
              else if(qnty < 0)
                  qnty = qnty * -1;

              Decimal amount = item.TotalPrice;
              if(!feeApplied && !item.Product2.ProductCode.startsWith('PWN'))
              {
                amount = amount -(input.isFullRefund== true ? 0: item.Product_cancel_fee__c) ;
                feeApplied=true;
              }
                    
               gen.writeStartObject();
                 gen.writeStringField('number', cnt.format());                  
                 gen.writeNumberField('quantity',qnty);                 
                 gen.writeNumberField('amount', -amount);
                 gen.writeNumberField('tax', -item.TotalTaxAmount);
                 gen.writeStringField('itemCode', item.Product2.ProductCode);
                 gen.writeStringField('description', item.Product2.Name);
              gen.writeEndObject();
              
              shippingStreet =item.OrderDeliveryGroup.DeliverToState;
              shippingCity = item.OrderDeliveryGroup.DeliverToCity;
              shippingState = item.OrderDeliveryGroup.DeliverToState;
              shippingCountry =item.OrderDeliveryGroup.DeliverToCountry;
              shippingPostalCode = item.OrderDeliveryGroup.DeliverToPostalCode;

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
    output.requestPayload=body;
    try{
      HttpResponse response = http.send(request); 
      statusCode = response.getStatusCode();
      output.responsePayload=response.getBody();
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
   
    @InvocableVariable(required = true)
    public Boolean isFullRefund;
}

public class OutputParameters {
    @InvocableVariable
    public Integer statusCode;
    @InvocableVariable
    public String errorMessage;
    @InvocableVariable
    public String requestPayload;
    @InvocableVariable
    public String responsePayload;
}

}