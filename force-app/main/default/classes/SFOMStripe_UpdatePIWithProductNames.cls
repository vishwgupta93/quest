public class SFOMStripe_UpdatePIWithProductNames {

  @InvocableMethod(label='Stripe - Update ProductName' description='Update the PaymentIntent With Product Names')
  public static  List<OutputParameters>  updatePaymentIntent(List<InputParameters> inputs){
    
    List<OutputParameters> outputs = new List<OutputParameters>();
    Set<String> orderSummaryIdSet = new Set<String>();
    Map<String,String> ordSumIdNdPrdMap = new Map<String,String>();
    Map<String, Decimal > ordSumIdNdTaxMap = new Map<String, Decimal >();
    Map<String, String> oSummaryNdPaymntGateWayRefNoMap = new Map<String, String>();
    Map<String, OrderSummary> orderSummaryMap = new Map<String, OrderSummary>();
    
    
   
    for(InputParameters input : inputs){
        if(input.orderSummaryId!=null)
           orderSummaryIdSet.add(input.orderSummaryId);       
    }
     
    if(orderSummaryIdSet!=null && orderSummaryIdSet.size()>0){
    
      List<FulfillmentOrderLineItem> foLineItems = [Select FulfillmentOrder.OrderSummaryId, OrderItemSummary.Name,FulfillmentOrder.OrderSummary.TotalTaxAmount from FulfillmentOrderLineItem where FulfillmentOrder.OrderSummaryId in:orderSummaryIdSet];                                                         
      if(foLineItems!=null && foLineItems.size()>0) {
        for(FulfillmentOrderLineItem fo:foLineItems){ 
             if(ordSumIdNdPrdMap.containsKey(fo.FulfillmentOrder.OrderSummaryId)){
                String prdName = ordSumIdNdPrdMap.get(fo.FulfillmentOrder.OrderSummaryId) + ';' +fo.OrderItemSummary.Name;
                ordSumIdNdPrdMap.put(fo.FulfillmentOrder.OrderSummaryId,prdName);
             }
             else {
               ordSumIdNdPrdMap.put(fo.FulfillmentOrder.OrderSummaryId,fo.OrderItemSummary.Name);
             }
              ordSumIdNdTaxMap.put(fo.FulfillmentOrder.OrderSummaryId,fo.FulfillmentOrder.OrderSummary.TotalTaxAmount);
        }
      }  
      
      List<PaymentAuthorization> pamentAuthLst = [SELECT GatewayRefNumber, Order_Summary_Id__c FROM PaymentAuthorization where Order_Summary_Id__c IN :orderSummaryIdSet and paymentType__c in ('card','apple_pay','klarna','affirm')];
      if(pamentAuthLst!=null){
       for(PaymentAuthorization ps:pamentAuthLst ){
           oSummaryNdPaymntGateWayRefNoMap.put(ps.Order_Summary_Id__c,ps.GatewayRefNumber);
         }
       }
       if(pamentAuthLst == null || pamentAuthLst.isEmpty())
       {
        List<Payment> captureLst = [SELECT GatewayRefNumber, Order_Summary_Id__c FROM Payment where Order_Summary_Id__c IN :orderSummaryIdSet and Payment_Type__c = 'klarna'];
        if(captureLst!=null)
        {
          for(Payment ps:captureLst ){
            oSummaryNdPaymntGateWayRefNoMap.put(ps.Order_Summary_Id__c,ps.GatewayRefNumber);
          }
        }
       }
       
      /** List<OrderSummary> objOrderSummary= [SELECT Id, Status, PWN_Service_Fee__c, Service_Fee__c, TotalTaxAmount FROM OrderSummary where id IN :orderSummaryIdSet];
       if(objOrderSummary!=null){
       for(OrderSummary os:objOrderSummary){
            orderSummaryMap.put(os.Id,os);
         }
       } **/
    }
    
    for(InputParameters input : inputs){
        String orderSummaryId =input.orderSummaryId;
        String strGatewayRefNumber = oSummaryNdPaymntGateWayRefNoMap.get(orderSummaryId);
        System.debug('Input strGatewayRefNumber =>'+strGatewayRefNumber + orderSummaryId);
        Integer statusCode;

        OutputParameters output = new OutputParameters(); 
        String prdName = ordSumIdNdPrdMap.get(orderSummaryId);
        //orderSummary oSummary = orderSummaryMap.get(orderSummaryId); 
        Decimal tax = ordSumIdNdTaxMap.get(orderSummaryId);
        String body = 'metadata[OrderSummaryId]='+orderSummaryId + '&metadata[ProductName]='+prdName
                       // + '&metadata[Status]='+oSummary.status
                       // + '&metadata[PWN_Service_Fee]='+oSummary.PWN_Service_Fee__c
                       // + '&metadata[Non_Refundable_Fee]='+oSummary.Service_Fee__c
                        + '&metadata[Tax]='+tax;
       Http http = new Http();
       HttpRequest request = new HttpRequest();
       request.setEndpoint(label.SFOM_Stripe_URL+strGatewayRefNumber );
       request.setMethod('POST');
       request.setHeader('Content-Type','application/x-www-form-urlencoded');
       request.setHeader('Authorization','Bearer '+input.stripeAPIToken );
       request.setBody(body);
                 
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
     public String orderSummaryId;
    @InvocableVariable(required = true)
     public String stripeAPIToken;  
  }
  
  public class OutputParameters{
    @InvocableVariable
    public Integer statusCode;
    @InvocableVariable
    public String errorMessage;
  } 

}