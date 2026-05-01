@IsTest 
public class FHIRIdWebHookTest{
    
    
        public static Map<String,SObject> m_mapTestData = null;
    
   @IsTest (SeeAllData=true)
    static void FHIRIdWebHookTest() {
    
         String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
        m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);
        
   
        OrderDeliveryGroup newOrderDeliveryGroupTest  = (OrderDeliveryGroup ) m_mapTestData.get('newOrderDeliveryGroup');
        System.debug('newOrderDeliveryGroupTest   ==>'+newOrderDeliveryGroupTest );  
            
        Order newOrder = (Order)m_mapTestData.get('newOrder');
        //System.assert(newOrder != null);
        
        // activate orders and create ordersummary objects        
        SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' ); 
        
        System.debug('******newOrder.status *******'+newOrder.status );
        
        
       // List<OrderSummary> lstOS = [SELECT Id, Status FROM OrderSummary where OriginalOrderId =:newOrder.Id ];
        List<OrderSummary> lstOS = [SELECT Id, Status FROM OrderSummary where OriginalOrderId=:newOrder.Id ];
        
        OrderSummary oOrderSummary = new OrderSummary();
        oOrderSummary  = lstOS[0];
        System.debug('lstOS ==>'+lstOS[0]);
        String orderSummaryId = oOrderSummary.Id;
        List<ID> lstOSID = new List<ID>();
         lstOSID.add(orderSummaryId);
         
                        
         System.debug('******oOrderSummary *******'+oOrderSummary );
        
          List<OrderDeliveryGroupSummary> lstODGS = [SELECT Id, OrderSummaryId FROM OrderDeliveryGroupSummary where OrderSummaryId=:oOrderSummary.Id ];
            System.debug('******lstODGS  *******'+lstODGS  );
        
        
        Schema.Location location = (Schema.Location) m_mapTestData.get('newLocationUSCE');
        

        /***************************************************************************************************************************************/
        
        ConnectApi.FulfillmentOrderInputRepresentation fulfillmentOrderInput = new ConnectApi.FulfillmentOrderInputRepresentation();
        fulfillmentOrderInput.orderSummaryId = orderSummaryId;

        List<OrderDeliveryGroupSummary> orderDeliveryGroupSummaryList = [SELECT Id FROM OrderDeliveryGroupSummary WHERE OrderSummaryId =: orderSummaryId];

        for (OrderDeliveryGroupSummary orderDeliveryGroupSummary: orderDeliveryGroupSummaryList){

        fulfillmentOrderInput.orderDeliveryGroupSummaryId = orderDeliveryGroupSummary.Id;
        List<ConnectApi.FulfillmentGroupInputRepresentation> fulfillmentGroups = new List<ConnectApi.FulfillmentGroupInputRepresentation>();
        ConnectApi.FulfillmentGroupInputRepresentation fulfillmentGroup = new ConnectApi.FulfillmentGroupInputRepresentation();
        fulfillmentGroup.fulfilledFromLocationId = location.Id;
        fulfillmentGroup.fulfillmentType = location.LocationType;

        List<ConnectApi.OrderItemSummaryInputRepresentation> orderItemSummaries = new List<ConnectApi.OrderItemSummaryInputRepresentation>();

          List<OrderItemSummary> orderItemSummaryList = [Select Id, quantity FROM OrderItemSummary WHERE OrderSummaryId =: orderSummaryId AND OrderDeliveryGroupSummaryId =: orderDeliveryGroupSummary.Id];
          for(OrderItemSummary orderItemSummary : orderItemSummaryList){
            ConnectApi.OrderItemSummaryInputRepresentation oisInputRepresentation = new ConnectApi.OrderItemSummaryInputRepresentation();
            oisInputRepresentation.orderItemSummaryId = orderItemSummary.Id;
            oisInputRepresentation.quantity = orderItemSummary.quantity;
            orderItemSummaries.add(oisInputRepresentation);
          }

          fulfillmentGroup.orderItemSummaries = orderItemSummaries;
          fulfillmentGroups.add(fulfillmentGroup);      
          fulfillmentOrderInput.fulfillmentGroups = fulfillmentGroups;

        }

     ConnectApi.FulfillmentOrderOutputRepresentation result = ConnectAPI.FulfillmentOrder.createFulfillmentOrders(fulfillmentOrderInput);


        /***************************************************************************************************************************************/
        
            
       FulfillmentOrder fo = new FulfillmentOrder();
       fo.id= result.fulfillmentOrderIds[0];
       fo.RecordTypeId=Label.SFOM_In_Person_Record_Type_Id;
       fo.Status = 'Pending Approval';
       fo.LastName__c ='Doe';
       fo.FirstName__c ='John';
       fo.PWN_Status_Date__c = date.parse('4/17/2025');
       update fo;
    
      
       SFOMSetOrderAttributes.copyOrderAttributes(lstOSID);
      
         
         //String jsonRequest = '{\n\"identifier\": [{\n\t\t\"system\": \"https://www.questdiagnostics.com\",\n\t\t\"value\": \"fd047964d298685f36fd9b0c\"\n\t}, {\n\t\t\"type\": {\n\t\t\t\"coding\": [{\n\t\t\t\t\"system\": \"http://terminology.hl7.org/CodeSystem/v2-0203\",\n\t\t\t\t\"code\": \"ACSN\",\n\t\t\t\t\"display\": \"Accession ID\"\n\t\t\t}],\n\t\t\t\"text\": \"Accession Number\"\n\t\t},\n\t\t\"value\": \"CZ001078A\"\n\t}, {\n\t\t\"type\": {\n\t\t\t\"coding\": [{\n\t\t\t\t\"system\": \"http://terminology.hl7.org/CodeSystem/v2-0203\",\n\t\t\t\t\"code\": \"FILL\",\n\t\t\t\t\"display\": \"Filler\"\n\t\t\t}],\n\t\t\t\"text\": \"Filler\"\n\t\t},\n\t\t\"value\": \"CZ001078A\",\n\t\t\"assigner\": {\n\t\t\t\"reference\": \"Organization/f-97f298638fe527ffe49135d7\"\n\t\t}\n\t}, {\n\t\t\"type\": {\n\t\t\t\"coding\": [{\n\t\t\t\t\"system\": \"http://terminology.hl7.org/CodeSystem/v2-0203\",\n\t\t\t\t\"code\": \"PLAC\",\n\t\t\t\t\"display\": \"Placer\"\n\t\t\t}],\n\t\t\t\"text\": \"Placer\"\n\t\t},\n\t\t\"value\": '+ fo.id +'"\n\t}]\n}"';
        
        Test.StartTest();
      /*  HttpRequest req = new HttpRequest();
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/rest/FHIR');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonRequest);

        Http http = new Http();
        HttpResponse res = http.send(req); */
        
        // Create a JSON request body to simulate the incoming request
        Map<String, Object> requestBody = new Map<String, Object>{
            'identifier' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'system' => 'https://www.questdiagnostics.com',
                    'value' => '127jkjg1qii12'
                },
                new Map<String, Object>{
                    'type' => new Map<String, Object>{
                        'text' => 'Placer'
                    },
                    'value' => fo.id
                }
                // Add more data as needed for your test
            }
        };

        // Serialize the JSON request body
        String jsonBody = JSON.serialize(requestBody);
        
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
       req.requestBody = Blob.valueOf(jsonBody);
       
        RestContext.request = req;
        RestContext.response = res;
       
       FHIRIdWebHook.insertRecord();
       
       System.assertEquals(200, res.statusCode); // Check the HTTP status code
       
       
        Map<String, Object> requestBody1 = new Map<String, Object>{
            'identifier' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'system' => 'https://www.questdiagnostics.com',
                    'value' => '127jkjg1qii12'
                },
                new Map<String, Object>{
                    'type' => new Map<String, Object>{
                        'text' => 'Placer'
                    },
                    'value' => '1444324'
                }
                // Add more data as needed for your test
            }
        };

        // Serialize the JSON request body
        String jsonBody1 = JSON.serialize(requestBody1);
        
        
        RestRequest req1 = new RestRequest();
        RestResponse res1 = new RestResponse();
        
       req1.requestBody = Blob.valueOf(jsonBody1);
       
        RestContext.request = req1;
        RestContext.response = res1;
       
       FHIRIdWebHook.insertRecord();
       
       String responseBody1 = res1.responseBody.toString();
       Map<String, Object> jsonResponse1 = (Map<String, Object>) JSON.deserializeUntyped(responseBody1);
       
              System.assertEquals('OperationOutcome', jsonResponse1.get('resourceType')); // Check the HTTP status code
       
       
       
    RestRequest request = new RestRequest();
    RestResponse response = new RestResponse();

    // Set the required parameter 'orderNumber'
    request.params.put('orderNumber', 'dummy'); 

    // Set the request and response in RestContext
    RestContext.request = request;
    RestContext.response = response;

    // Call the getRecord method to test
    FHIRIdWebHook.getRecord();

    // Validate the response
   // System.assertEquals(200, response.statusCode);

    // Parse the response body
    String responseBody = response.responseBody.toString();
    Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

    // Validate the expected fields in the response
    System.assertEquals('Not found', jsonResponse.get('orderNumber'));
    System.assertEquals('Not found', jsonResponse.get('FHIRId'));
        
       Test.stopTest();
    
    }
    
    }