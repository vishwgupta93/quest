public class OrderRegistrationUIWrapper {
    public OrderInfo orderInfo;
    public String labOrderId;
    public Boolean isService;
    
    public class OrderInfo {
        public String id;
        public String orderNumber;
        public Datetime orderedDate;
        public String billingAddressLine1;
        public String billingAddressLine2;
        public String billingCity;
        public String billingState;
        public String billingPostalCode;
        public String billingCountry;
        public String billingPhoneNumber;
        public String billingEmailAddress;
        public Boolean isCommerceFlow;
        public Boolean minorOrder;
        
        public List<FOInfo> fos = new List<FOInfo>();
    }
    
    public class FOInfo {
        public String id;
        public String recordType;
        public Datetime orderExpirationDate;
        public String status;
        public String firstName;
        public String lastName;
        
        public List<FOLineInfo> lines = new List<FOLineInfo>();
    }
    
    public class FOLineInfo {
        public String id;
        public String description;
        public String testType;
        public Boolean isRegistered;
        public Boolean excludeFromRegistration;
        public Boolean isService;
        public String productName;
        public String productCode;
        public Boolean aoeRequired;
        public String gender;
        public String excludedStateCodes;
        public String maxAge;
        public String minAge;
    }
    

    public OrderRegistrationUIWrapper()
    {
        
    }
    public OrderRegistrationUIWrapper(List<FulfillmentOrderLineItem> items, Boolean isMinor) {
        this(items);
        if (this.orderInfo != null) {
            this.orderInfo.minorOrder = isMinor;
        }
    }
    public OrderRegistrationUIWrapper(List<FulfillmentOrderLineItem> items) {
        initializeWrapper(items);
    }
    
    private void initializeWrapper(List<FulfillmentOrderLineItem> items) {
        if (!items.isEmpty()) {
            // Initialize OrderInfo only once
            this.orderInfo = new OrderInfo();
            FulfillmentOrderLineItem firstItem = items[0];
            
            // Populate OrderInfo based on the first record
            this.orderInfo.id = firstItem.FulfillmentOrder.OrderSummaryId;
            this.orderInfo.orderNumber = firstItem.FulfillmentOrder.OrderSummary.OrderNumber;
            this.orderInfo.orderedDate = firstItem.FulfillmentOrder.OrderSummary.OrderedDate;
            this.orderInfo.billingAddressLine1 = firstItem.FulfillmentOrder.OrderSummary.BillingAddressLine1__c;
            this.orderInfo.billingAddressLine2 = firstItem.FulfillmentOrder.OrderSummary.BillingAddressLine2__c;
            this.orderInfo.billingCity = firstItem.FulfillmentOrder.OrderSummary.BillingCity;
            this.orderInfo.billingState = firstItem.FulfillmentOrder.OrderSummary.BillingState;
            this.orderInfo.billingPostalCode = firstItem.FulfillmentOrder.OrderSummary.BillingPostalCode;
            this.orderInfo.billingCountry = firstItem.FulfillmentOrder.OrderSummary.BillingCountry;
            this.orderInfo.billingPhoneNumber = firstItem.FulfillmentOrder.OrderSummary.BillingPhoneNumber;
            this.orderInfo.billingEmailAddress = firstItem.FulfillmentOrder.OrderSummary.BillingEmailAddress;
            this.orderInfo.isCommerceFlow=false;
            
            Map<String, List<FulfillmentOrderLineItem>> groupedItems = new Map<String, List<FulfillmentOrderLineItem>>();
            for (FulfillmentOrderLineItem item : items) {
                if (!groupedItems.containsKey(item.FulfillmentOrderId)) {
                    groupedItems.put(item.FulfillmentOrderId, new List<FulfillmentOrderLineItem>());
                }
                groupedItems.get(item.FulfillmentOrderId).add(item);
            }
            
            // Populate FOInfo and FOLineInfo for each group
            for (String fulfillmentOrderId : groupedItems.keySet()) {
                List<FulfillmentOrderLineItem> orderItems = groupedItems.get(fulfillmentOrderId);
                FOInfo foInfo = new FOInfo();
                FulfillmentOrderLineItem firstOrderItem = orderItems[0];
                
                // Populate FOInfo
                foInfo.id = firstOrderItem.FulfillmentOrderId;
                foInfo.recordType = firstOrderItem.FulfillmentOrder.Record_Type__c;
                foInfo.orderExpirationDate = firstOrderItem.FulfillmentOrder.OrderExpirationDate__c;
                foInfo.status = firstOrderItem.FulfillmentOrder.Status;
                foInfo.firstName = firstOrderItem.FulfillmentOrder.FirstName__c;
                foInfo.lastName = firstOrderItem.FulfillmentOrder.LastName__c;
                
                // Populate FOLineInfo for each line item
                for (FulfillmentOrderLineItem orderItem : orderItems) {
                    FOLineInfo lineInfo = new FOLineInfo();
                    lineInfo.id = orderItem.Id;
                    lineInfo.description = orderItem.Description;
                    lineInfo.testType = orderItem.Test_Type__c;
                    lineInfo.isRegistered = orderItem.Is_Registered__c;
                    lineInfo.isService = orderItem.Is_Service__c;
                    lineInfo.productName = orderItem.ProductName__c;
                    lineInfo.productCode = orderItem.Product2.ProductCode;
                    lineInfo.aoeRequired = orderItem.Product2.AOE_required__c;
                    lineInfo.gender = orderItem.Product2.Gender__c;
                    lineInfo.excludedStateCodes = orderItem.Product2.Excluded_State_codes__c;
                    lineInfo.maxAge = orderItem.Product2.Max_age__c;
                    lineInfo.minAge = orderItem.Product2.Min_age__c;
                    lineInfo.excludeFromRegistration=orderItem.Product2.Exclude_from_registration__c;
                    
                    foInfo.lines.add(lineInfo);
                }
                
                // Add FOInfo to OrderInfo
                this.orderInfo.fos.add(foInfo);
            }
        }
    }
    
    public OrderRegistrationUIWrapper(Commerce_Order_Info__c comOrder) {
        this.orderInfo = new OrderInfo();
        
        // Populate OrderInfo fields from Commerce_Order_Info__c
        this.orderInfo.orderNumber = comOrder.Order_Number__c;
        this.orderInfo.orderedDate = comOrder.CreatedDate;
        this.orderInfo.billingAddressLine1 = comOrder.Address_Line_1__c;
        this.orderInfo.billingAddressLine2 = comOrder.Address_Line_2__c;
        this.orderInfo.billingCity = comOrder.City__c;
        this.orderInfo.billingState = comOrder.State__c;
        this.orderInfo.billingPostalCode = comOrder.Postal_Code__c;
        this.orderInfo.billingCountry = 'US'; 
        this.orderInfo.billingPhoneNumber = comOrder.Phone_number__c; 
        this.orderInfo.billingEmailAddress = comOrder.Email__c;
        this.orderInfo.isCommerceFlow=true;
        
        // Create FOInfo object
        FOInfo foInfo = new FOInfo();
        foInfo.recordType = 'Commerce Order'; 
        foInfo.orderExpirationDate = null; 
        foInfo.status = 'Pending'; 
        foInfo.firstName = comOrder.First_Name__c;
        foInfo.lastName = comOrder.Last_Name__c;
        Map<String,TestCodes> testData = new Map<String,TestCodes> ();
        
        List<ProductData> productDetails = new List<ProductData>();
        System.debug('Test Codes : ' + comOrder.Test_Codes__c );
        if(String.isNotBlank(comOrder.Test_Codes__c)){
            List<TestCodes> tests = TestCodes.parse(comOrder.Test_Codes__c);
            Set<String> productCodeList = new Set<String> ();            
            for(TestCodes obj: tests){       
                if(obj.testType == 'PSC' || obj.testType == 'at_home' || obj.testType == 'PackHealth')
                {
                    testData.put(obj.Code,obj);
                }    
                
            }
            for(Product2 prd: [SELECT Id, Name, ProductCode, AOE_required__c, Gender__c,
                               Excluded_State_codes__c, Max_age__c, Min_age__c,Exclude_from_registration__c
                               FROM Product2 WHERE ProductCode IN : testData.keySet() 
                               ])
            {
                productDetails.add(new ProductData(prd));
            }
        }
        if(!productDetails.isEmpty()){
            // Map productDetails to FOLineInfo
            for (ProductData product : productDetails) {
                FOLineInfo lineInfo = new FOLineInfo();
                lineInfo.id = product.productCode; 
                lineInfo.description = 'Details for ' + product.productName; 

                TestCodes test = testData.get(product.productCode);
                lineInfo.isRegistered = false; 
                lineInfo.testType =test.testType;                 
                lineInfo.isService = test.isService; 
                
                // Populate product-specific fields
                lineInfo.productName = product.productName;
                lineInfo.productCode = product.productCode;
                lineInfo.aoeRequired = product.aoeRequired;
                lineInfo.gender = product.gender;
                lineInfo.excludedStateCodes = product.excludedStateCodes;
                lineInfo.maxAge = product.maxAge;
                lineInfo.minAge = product.minAge;
                lineInfo.excludeFromRegistration=product.excludeFromRegistration;
                
                foInfo.lines.add(lineInfo);
            }
            
            // Add FOInfo to OrderInfo
            this.orderInfo.fos.add(foInfo);
        }
    }
    
}