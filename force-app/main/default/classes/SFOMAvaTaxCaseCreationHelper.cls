public class SFOMAvaTaxCaseCreationHelper {
    
    public class InputParameters {
      @InvocableVariable(required = true)
        public String foId;
      @InvocableVariable(required = true)
        public string OrderSummaryId;
      @InvocableVariable(required = true)
        public string errorMsg;
    }
   
	@InvocableMethod(label='AvaTax - Create Case' description='Creates Transaction.')
    public static  void createTransaction(List<InputParameters> inputs){
        
        List<OrderPaymentSummary> ops = new List<OrderPaymentSummary>([Select id, AuthorizationAmount from OrderPaymentSummary where OrderSummaryId =: inputs[0].OrderSummaryId]);
        Case c = new Case();
        c.Amount_Authorized__c = ops[0].AuthorizationAmount;
        c.subject = Label.Avalara_Tax_Calculation_Error;
        c.Description = inputs[0].errorMsg;
        c.Order_Number__c = inputs[0].foId;
        c.Order_Summary__c = inputs[0].OrderSummaryId;
        c.OwnerId = Label.OMS_Avalara_Case_Owner;
        c.Priority = 'Medium';
        c.Status = 'Open';
        c.Origin = 'Avalara Tax';
        
        insert c;
    }
}