@IsTest 
public class SFOMExpireShipmentLineItemsBatchTest {
            public static Map<String,SObject> m_mapTestData = null;
    
       @IsTest (SeeAllData=true)
    static void SFOMExpireShipmentLineItemsBatchTest() {
        
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
       // System.assert(!lstOS.isEmpty());
        OrderSummary oOrderSummary = new OrderSummary();
        oOrderSummary  = lstOS[0];
        System.debug('lstOS ==>'+lstOS[0]);
        String orderSummaryId = oOrderSummary.Id;
        
              
         System.debug('******oOrderSummary *******'+oOrderSummary );
        
          List<OrderDeliveryGroupSummary> lstODGS = [SELECT Id, OrderSummaryId FROM OrderDeliveryGroupSummary where OrderSummaryId=:oOrderSummary.Id ];
            System.debug('******lstODGS  *******'+lstODGS  );
        
        
        Schema.Location location = (Schema.Location) m_mapTestData.get('newLocationUSCE');
        
        /***************************************************************************************************************************************/
      
       // ConnectApi.FulfillmentOrderOutputRepresentation result = SFOMTestDataFactory.createFulfillmentOrderUsingCApi(orderSummaryId, location );
      
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
   
        System.debug('Welcome fulfillment​OrderIds1==>'+result.fulfillmentOrderIds[0]);
        
        
 
       FulfillmentOrder fo = new FulfillmentOrder();
       fo.id= result.fulfillmentOrderIds[0];
       fo.RecordTypeId=Label.SFOM_In_Person_Record_Type_Id;
       fo.Status = 'PA Approved';
       fo.LastName__c ='SelvaRaj';
       fo.PWN_Status_Date__c = date.parse('4/17/2022');
       update fo;
 
       FulfillmentOrder fOrder = [select Id, OrderSummaryId, Record_Type_Name__c,RecordTypeId, RecordType.DeveloperName from FulfillmentOrder where id =:fo.id];

                    
      // Create Shipment
      Shipment s = new Shipment();
      s.FulfillmentOrderId = fOrder.id;
      s.OrderSummaryId = fOrder.OrderSummaryId;
      //s.ShipToName = 'Balaji Selvaraj';
      s.shipping_Method__c = 'FedEx 2 Day';
      s.Provider = 'UPS' ;
      s.TrackingNumber = '1ZA757R70340971417';
      s.TrackingUrl = 'https://www.ups.com/';                        
      s.ShipFromStreet = '4201 Monterey Oaks Blvd';
      s.ShipFromCity = 'Austin';
      s.ShipFromState = 'TX';
      s.ShipFromCountry = 'USA';
      s.ShipFromPostalCode = '78749';                       
      s.ExpectedDeliveryDate  =  Date.newInstance(2022,07,20);
      s.Description = 'Test';
      s.Status = 'Shipped';
      s.ShipToStreet = '4212 Querida Avenue';
      s.ShipToCity  = 'Mckinney';
      s.ShipToState  = 'TX';
      s.ShipToCountry  = 'USA';
      s.ShipToPostalCode = '54070';
      s.Cancellation_Date__c =  Date.newInstance(2022,08,20);
      s.ShipToName='test';
      insert s;
      
      List<Shipment > fOShipment= [select Id, ExpectedDeliveryDate, Status from Shipment where FulfillmentOrderId =:fo.id];
      System.debug('Welcome fOShipment 1==>'+fOShipment);
     
      List<FulfillmentOrderLineItem> fOrderLine = [select Id, Eligible_to_Expire__c, Status__c,  Kit_Expiration_Date__c, OrderItemId, OrderItemSummaryId  from FulfillmentOrderLineItem where FulfillmentOrderId =:fo.id];
      System.debug('Welcome FulfillmentOrderLineItem 1==>'+fOrderLine );

      List<OrderItem > fOrderItem = [ select id, Product2Id  from OrderItem where id=:fOrderLine[0].OrderItemId];
      System.debug('Welcome OrderItem 1==>'+fOrderItem );

     // Create Shipment Line 
     ShipmentItem shpItem = new ShipmentItem();
     shpItem.ShipmentId = fOShipment[0].Id;                        
     shpItem.FulfillmentOrderLineItemId = fOrderLine[0].id;
     shpItem.OrderItemSummaryId = fOrderLine[0].OrderItemSummaryId;
     shpItem.Product2Id = fOrderItem[0].Product2Id;   
     shpItem.Status__c = 'Kit Shipped'; 
     shpItem.Activation_Code__c = '89898989';
     shpItem.LotNumber__c = '999';                
     shpItem.Quantity = 1;
     shpItem.Expiration_Date__c = Date.newInstance(2022,07,20);
     shpItem.Return_Tracking_URL__c = 'https://www.ups.com/';
     shpItem.Return_Tracking_Number__c = '1ZA757R703409710097';
     shpItem.DNAGenotekId__c = '5555555';
     shpItem.Serial_Number__c = 'sfsdfsd8989988';
     insert shpItem;

    
       List<ShipmentItem> fOShipmentLine= [select Id, ExpectedDeliveryDate, Status__c, Eligible_To_Expire__c from ShipmentItem where ShipmentId=:fOShipment[0].Id];
       System.debug('Welcome fOShipmentLine 1==>'+fOShipmentLine[0].Id);
       System.debug('Welcome fOShipmentLine 2==>'+fOShipmentLine[0].ExpectedDeliveryDate);
       System.debug('Welcome fOShipmentLine 3==>'+fOShipmentLine[0].Status__c );
       System.debug('Welcome fOShipmentLine 3==>'+fOShipmentLine[0].Eligible_To_Expire__c);

      
        Test.StartTest();
        SFOMExpireShipmentLineItemsBatch btch = new SFOMExpireShipmentLineItemsBatch();
        btch.id=fOShipmentLine[0].Id;
        btch.Query='Select Id,Status__c,FulfillmentOrderLineItem.Quantity,FulfillmentOrderLineItem.Status__c,FulfillmentOrderLineItemId from ShipmentItem where id=:id';
        System.debug('Welcome SFOMExpireShipmentLineItemsBatchSchedule  1==>'+btch);
        Database.executeBatch(btch,1);
        Test.stopTest();
        SFOMExpireShipmentLineItemsBatchSchedule obj = new SFOMExpireShipmentLineItemsBatchSchedule();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, obj);
        
    }
}