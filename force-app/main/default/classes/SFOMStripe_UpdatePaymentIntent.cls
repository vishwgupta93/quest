/***
SFOMStripe_UpdatePaymentIntent  use to trigger Stripe Update a PaymentIntent API
Inout to this class is Fulfillment Order ID 

**/
public class SFOMStripe_UpdatePaymentIntent {

    @InvocableMethod(label='Stripe - Update a PaymentIntent' description='Update a PaymentIntent')
    public static  List<OutputParameters>  createTransaction(List<InputParameters> inputs){
    List<OutputParameters> outputs = new List<OutputParameters>();
    
    Set<String> orderSummaryIds = new Set<String>();   
    Set<String> fulfillmentOrderIds = new Set<String>();
    
    
     
    for(InputParameters input : inputs){
        if(input.foId!=null)
          fulfillmentOrderIds.add(input.foId);
        if(input.orderSummaryId!=null)  
          orderSummaryIds.add(input.orderSummaryId);
     }
      
      Map<String, String> oSummaryNdPaymntGateWayRefNoMap = new Map<String, String>();
      List<PaymentAuthorization> pamentAuthLst = [SELECT GatewayRefNumber, Order_Summary_Id__c FROM PaymentAuthorization where Order_Summary_Id__c IN :orderSummaryIds and paymentType__c in ('card','apple_pay','klarna','affirm')];
      if(pamentAuthLst!=null){
       for(PaymentAuthorization ps:pamentAuthLst ){
           oSummaryNdPaymntGateWayRefNoMap.put(ps.Order_Summary_Id__c,ps.GatewayRefNumber);
         }
       }

       if(pamentAuthLst == null || pamentAuthLst.isEmpty())
       {
        List<Payment> captureLst = [SELECT GatewayRefNumber, Order_Summary_Id__c FROM Payment where Order_Summary_Id__c IN :orderSummaryIds and Payment_Type__c = 'klarna'];
        if(captureLst!=null)
        {
          for(Payment ps:captureLst ){
            oSummaryNdPaymntGateWayRefNoMap.put(ps.Order_Summary_Id__c,ps.GatewayRefNumber);
          }
        }
       }
      
      Map<String, OrderSummary> orderSummaryMap = new Map<String, OrderSummary>();
      List<OrderSummary> objOrderSummary= [SELECT Id, Status, PWN_Service_Fee__c, Service_Fee__c, TotalTaxAmount FROM OrderSummary where id IN :orderSummaryIds];
       if(objOrderSummary!=null){
       for(OrderSummary os:objOrderSummary){
          orderSummaryMap.put(os.Id,os);
         }
       }

       String strGatewayRefNumber;
       for(InputParameters input : inputs){
        String orderSummaryId =input.orderSummaryId;
        strGatewayRefNumber = oSummaryNdPaymntGateWayRefNoMap.get(orderSummaryId);
        System.debug('Input strGatewayRefNumber =>'+strGatewayRefNumber );
          
        Integer statusCode;
        OutputParameters output = new OutputParameters();       
        String body =BodyInput(orderSummaryMap.get(orderSummaryId));  
        System.debug('Input Body gen=>'+body );

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(label.SFOM_Stripe_URL+strGatewayRefNumber );
        request.setMethod('POST');
        request.setHeader('Content-Type','application/x-www-form-urlencoded');
        request.setHeader('Authorization','Bearer '+input.stripeAPIToken );
        request.setBody(body);

        System.debug('Request::'+request);
        
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
        public String foId;
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
    


     public Static String BodyInput(orderSummary inOrderSummary) {
        System.debug('generateBody orderSummary =>'+inOrderSummary);

        if(inOrderSummary == null){
         return null;
        }
       
        String strBodyInput = 'metadata[OrderSummaryId]='+inOrderSummary.Id
                        + '&metadata[Status]='+inOrderSummary.status
                        + '&metadata[PWN_Service_Fee]='+inOrderSummary.PWN_Service_Fee__c
                        + '&metadata[Non_Refundable_Fee]='+inOrderSummary.Service_Fee__c
                        +'&metadata[Tax]='+inOrderSummary.TotalTaxAmount;
                    

     System.debug('generateBody gen=>'+strBodyInput );
        return strBodyInput ;
    }
}