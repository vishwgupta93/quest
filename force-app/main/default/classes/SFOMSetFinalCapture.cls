public with sharing class SFOMSetFinalCapture {



  /**
     * Invocable method that is directly called by Flow action element.
  */
  @InvocableMethod(label='Mark Final Capture Stripe' description='Sets final capture to true in Stripe')
  public static List<OutputParameters> createShipment(List<InputParameters> inputs){
    List<OutputParameters> outputLst = new List<OutputParameters>();  
    Set<String> processedOrderSumIds = new Set<String>();
      
    for(InputParameters input : inputs){
       String orderSummaryId = input.orderSummaryId; 
       String authId = input.paymentAuthorizationId;
       OutputParameters outputParam = new OutputParameters();
       outputParam.orderSummaryId = orderSummaryId;
       
     if(!processedOrderSumIds.contains(orderSummaryId)){ 
     
       System.debug('Order Summary Id::' + orderSummaryId + ' ' +authId);
       Map<String,String> data = new Map<String,String>();
       data.put('make_final','true');
       ConnectApi.CaptureRequest AuthCaptureInput = new ConnectApi.CaptureRequest();
       AuthCaptureInput.amount = 0;
       AuthCaptureInput.additionalData = data;
       ConnectApi.CaptureResponse response;
       String exceptionMsg;
       try {
           response = ConnectApi.Payments.capture(AuthCaptureInput,authId);      
           System.debug('Response:::' + response);
       }
       catch(Exception e){
         exceptionMsg =e.getMessage();
       }
                     
       if(response!=null && response.gatewayResponse!=null && response.gatewayResponse.salesforceResultCode=='Success'){
           outputParam.IsSuccess=true; 
           outputParam.message='Success';  
       }
       else {
         outputParam.IsSuccess=false;
         if(exceptionMsg!=null)
           outputParam.message=exceptionMsg;
         if(response!=null && response.error!=null && response.error.message!=null)
           outputParam.message=response.error.message;
       }
       processedOrderSumIds.add(orderSummaryId);
     } 
     else {
           outputParam.IsSuccess=true; 
           outputParam.message='Success'; 
     }  
       
       outputLst.add(outputParam);
    }      
      return outputLst;
  }
       
  public class OutputParameters{
    @InvocableVariable
    public boolean IsSuccess;   
     @InvocableVariable
    public String message;   
     @InvocableVariable
    public String orderSummaryId;  
  }
  
   public class InputParameters {     
     @InvocableVariable(required = true)
     public String orderSummaryId;
     
     @InvocableVariable(required = true)
     public String paymentAuthorizationId;
   }     
}