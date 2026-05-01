public class ResponseOutputPackHealth {
 
    
        @AuraEnabled
        public String OrderSummaryId;
        
      
    	@AuraEnabled
        public String StatusCode;
        
      
    	@AuraEnabled
        public String Status;
        
       
    	@AuraEnabled
        public String memberId;
        
       
    	@AuraEnabled
        public String calendarURL;
        
        
    	@AuraEnabled
        public String errorMessage;
        
        
    	@AuraEnabled
        public String requestPayload;
       
        
    	@AuraEnabled
        public String responsePayload;
    
    	@AuraEnabled
        public String FulfillmentOrderLineItemID;
    
        @AuraEnabled
        public String FulfillmentOrderID;
    
    
    
   /* public ResponseOutputPackHealth(
        String OrderSummaryId,
        String StatusCode,
        String Status,
        String memberId,
        String calendarURL,
        String errorMessage,
        String requestPayload,
        String responsePayload,
        String FulfillmentOrderLineItemID,
        String FulfillmentOrderID
        
    ) {
        this.OrderSummaryId = OrderSummaryId;
        this.StatusCode = StatusCode;
        this.Status = Status;
        this.memberId = memberId;
        this.calendarURL =calendarURL;
        this.errorMessage = errorMessage;
        this.requestPayload = requestPayload;
        this.responsePayload = responsePayload;
        this.FulfillmentOrderLineItemID =FulfillmentOrderLineItemID;
        this.FulfillmentOrderID = FulfillmentOrderID;
    } */
 
    // Required no-argument constructor
    public ResponseOutputPackHealth() {}
}