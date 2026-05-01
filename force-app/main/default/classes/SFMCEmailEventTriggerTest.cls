@IsTest
public class SFMCEmailEventTriggerTest {    

@IsTest (SeeAllData=true)  
static void publishEventConfirm() {
    Test.startTest();        
    String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
 
        Map<String,SObject> m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);       
                    
        Order newOrder = (Order)m_mapTestData.get('newOrder');    
        SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' );                      
        List<OrderSummary> lstOS = [SELECT Id FROM OrderSummary where OriginalOrderId=:newOrder.Id ];

        List<SFMC_Email_Event__e> eventLst = new List<SFMC_Email_Event__e>();
      SFMC_OMS_Config__c  newConfig= new SFMC_OMS_Config__c (Channel__c = 'QD-CIT',Auth_Token__c ='77778888888812213', API__C = 'Common');
                insert newConfig;    
   SFMC_Email_Event__e event = new SFMC_Email_Event__e(Order_Summary_Id__c=lstOS[0].Id,EventDefinitionKey__c=Label.SFMC_OMS_Event_Name,Event_Type__c = Label.SFMC_Order_Confirm_Event);    
  
   // Publish test event
   eventLst.add(event);
   
   EventBus.publish(eventLst);
   Test.stopTest();    
   
  }

  // @IsTest
  // static void publishEventResultsPSC() {
  //   Test.startTest();        
  //   String salesChannel = 'Quest_US';
  //       String currencyIsoCode = 'USD';
  //       String orderTypeCode = 'Web';
  //       String MerchantID = 'Quest_US';
        
 
  //       Map<String,SObject> m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);       
                    
  //       Order newOrder = (Order)m_mapTestData.get('newOrder');    
  //       SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' );                      
  //       List<OrderSummary> lstOS = [SELECT Id FROM OrderSummary where OriginalOrderId=:newOrder.Id ];

  //       List<SFMC_Email_Event__e> eventLst = new List<SFMC_Email_Event__e>();
  //     SFMC_OMS_Config__c  newConfig= new SFMC_OMS_Config__c (Channel__c = 'QD-CIT',Auth_Token__c ='77778888888812213', API__C = 'Common');
  //               insert newConfig;    
  //               SFMC_Email_Event__e event = new SFMC_Email_Event__e(Order_Summary_Id__c=lstOS[0].Id,EventDefinitionKey__c=Label.SFMC_Results_Ready_Event,Is_Kit_Event__c=false,Test_type__c='InPerson',Event_Type__c = Label.SFMC_Results_Ready_Event);
  
  //  // Publish test event
  //  eventLst.add(event);
   
  //  EventBus.publish(eventLst);
  //  Test.stopTest();    
   
  // }

  // @IsTest
  // static void publishEventResultsKits() {
  //   Test.startTest();        
  //   String salesChannel = 'Quest_US';
  //       String currencyIsoCode = 'USD';
  //       String orderTypeCode = 'Web';
  //       String MerchantID = 'Quest_US';
        
 
  //       Map<String,SObject> m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);       
                    
  //       Order newOrder = (Order)m_mapTestData.get('newOrder');    
  //       SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' );                      
  //       List<OrderSummary> lstOS = [SELECT Id FROM OrderSummary where OriginalOrderId=:newOrder.Id ];

  //       List<SFMC_Email_Event__e> eventLst = new List<SFMC_Email_Event__e>();
  //     SFMC_OMS_Config__c  newConfig= new SFMC_OMS_Config__c (Channel__c = 'QD-CIT',Auth_Token__c ='77778888888812213', API__C = 'Common');
  //               insert newConfig;    
  //               SFMC_Email_Event__e event = new SFMC_Email_Event__e(Order_Summary_Id__c=lstOS[0].Id,EventDefinitionKey__c=Label.SFMC_Results_Ready_Event,Is_Kit_Event__c=true,Test_type__c='at_home',Event_Type__c = Label.SFMC_Results_Ready_Event,Customer_ID__c='212121',Is_Partner_Order__c=true,Email__c='ancas');
  
  //  // Publish test event
  //  eventLst.add(event);
   
  //  EventBus.publish(eventLst);
  //  Test.stopTest();    
   
  // }

  @IsTest (SeeAllData=true)
  static void publishEventCancel() {
    Test.startTest();        
    String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
 
        Map<String,SObject> m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);       
                    
        Order newOrder = (Order)m_mapTestData.get('newOrder');    
        SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' );                      
        List<OrderSummary> lstOS = [SELECT Id FROM OrderSummary where OriginalOrderId=:newOrder.Id ];

        List<SFMC_Email_Event__e> eventLst = new List<SFMC_Email_Event__e>();
      SFMC_OMS_Config__c  newConfig= new SFMC_OMS_Config__c (Channel__c = 'QD-CIT',Auth_Token__c ='77778888888812213', API__C = 'Common');
                insert newConfig;    
                SFMC_Email_Event__e event = new SFMC_Email_Event__e(Order_Summary_Id__c=lstOS[0].Id,EventDefinitionKey__c=Label.SFMC_Order_Cancel_Event,Test_type__c='InPerson',Event_Type__c = Label.SFMC_Order_Cancel_Event);   
                SFMC_Email_Event__e event1 = new SFMC_Email_Event__e(Order_Summary_Id__c=lstOS[0].Id,EventDefinitionKey__c=Label.SFMC_Order_Expiry_Event_Definition,Test_type__c='InPerson',Event_Type__c = Label.SFMC_Order_Cancel_Event);   
  
   // Publish test event
   eventLst.add(event);
   
   EventBus.publish(eventLst);
   Test.stopTest();    
   
  }

  @IsTest (SeeAllData=true)
  static void publishEventPayment() {
    Test.startTest();        
    String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
        //m_mapTestData = SFOMTestDataFactory.initData(salesChannel, currencyIsoCode);  
        Map<String,SObject>  m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);
        
   
          OrderDeliveryGroup newOrderDeliveryGroupTest  = (OrderDeliveryGroup ) m_mapTestData.get('newOrderDeliveryGroup');
          System.debug('newOrderDeliveryGroupTest   ==>'+newOrderDeliveryGroupTest );  
          
          PaymentAuthorization auth = (PaymentAuthorization) m_mapTestData.get('paymentAuth');
          System.debug('Auth ==>'+auth);  
            
        Order newOrder = (Order)m_mapTestData.get('newOrder');
      //  System.assert(newOrder != null);
        
        
        
        // activate orders and create ordersummary objects        
        SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' ); 

        
        System.debug('******newOrder.status *******'+newOrder.status );
        
        
       // List<OrderSummary> lstOS = [SELECT Id, Status FROM OrderSummary where OriginalOrderId =:newOrder.Id ];
        List<OrderSummary> lstOS = [SELECT Id,AccountId, Status FROM OrderSummary where OriginalOrderId=:newOrder.Id ];
    //    System.assert(!lstOS.isEmpty());
        OrderSummary oOrderSummary = new OrderSummary();
        oOrderSummary  = lstOS[0];
        System.debug('lstOS ==>'+lstOS[0]);
        String orderSummaryId = oOrderSummary.Id;
        String accountId= oOrderSummary.accountId;
        
              
         System.debug('******oOrderSummary *******'+oOrderSummary );
        
          List<OrderDeliveryGroupSummary> lstODGS = [SELECT Id, OrderSummaryId FROM OrderDeliveryGroupSummary where OrderSummaryId=:oOrderSummary.Id ];
            System.debug('******lstODGS  *******'+lstODGS  );
            
            
            
            
            ConnectApi.CreateOrderPaymentSummaryInputRepresentation orderPaymentSummaryInput = new ConnectApi.CreateOrderPaymentSummaryInputRepresentation();
            orderPaymentSummaryInput.orderSummaryId = orderSummaryId ;
            orderPaymentSummaryInput.paymentAuthorizationId = auth.Id;
            
            ConnectApi.CreateOrderPaymentSummaryOutputRepresentation opos= ConnectAPI.OrderPaymentSummary.createOrderPaymentSummary(orderPaymentSummaryInput);
            
            System.debug('%%%%%OPS Created***********' + opos.orderPaymentSummaryId);
            
            List<OrderPaymentSummary> lstOPS= [SELECT Id,paymentType__c, OrderSummaryId FROM OrderPaymentSummary where OrderSummaryId=:oOrderSummary.Id ];
            System.debug('******lstOPS*******'+lstOPS);
            
            OrderPaymentSummary ops = lstOPS[0];
            ops.paymentType__c='card';
            
            update ops;
            
                      
            lstOPS= [SELECT Id,paymentType__c, OrderSummaryId FROM OrderPaymentSummary where OrderSummaryId=:oOrderSummary.Id ];
            System.debug('******After Update lstOPS*******'+lstOPS);

        List<SFMC_Email_Event__e> eventLst = new List<SFMC_Email_Event__e>();
      SFMC_OMS_Config__c  newConfig= new SFMC_OMS_Config__c (Channel__c = 'QD-CIT',Auth_Token__c ='77778888888812213', API__C = 'Common');
                insert newConfig;    
   SFMC_Email_Event__e event = new SFMC_Email_Event__e(Order_Summary_Id__c=orderSummaryId,EventDefinitionKey__c=Label.SFMC_OMS_Event_Name,Event_Type__c = Label.SFMC_Payment_Capture_Event,Test_type__c='InPerson');    
  
   // Publish test event
   eventLst.add(event);
   
   EventBus.publish(eventLst);
   Test.stopTest();    
   
  }

  @IsTest(SeeAllData=true)
  static void publishEventShipment() {
    Test.startTest();        
    FulfillmentOrder fo = getFO();

    FulfillmentOrder fo1 = [select OrderSummaryId from FulfillmentOrder where Id =: fo.Id];

    Shipment ship = new Shipment();
    ship.OrderSummaryId = fo1.OrderSummaryId;
    ship.FulfillmentOrderId=fo.Id;
    ship.Shipping_Method__c= 'Fedex Ground';
    ship.Provider='Fedex';
    ship.TrackingNumber='121232434143';
    ship.Status='Shipped';
    insert ship;

        List<SFMC_Email_Event__e> eventLst = new List<SFMC_Email_Event__e>();
      SFMC_OMS_Config__c  newConfig= new SFMC_OMS_Config__c (Channel__c = 'QD-CIT',Auth_Token__c ='77778888888812213', API__C = 'Common');
                insert newConfig;    
                SFMC_Email_Event__e event = new SFMC_Email_Event__e(Shipment_ID__c=ship.Id,EventDefinitionKey__c=Label.SFMC_Shipment_Event_Definition_Key,Event_Type__c = Label.SFMC_Shipment_Event);   
  
   // Publish test event
   eventLst.add(event);
   
   EventBus.publish(eventLst);
   Test.stopTest();    
   
  }

  @IsTest(SeeAllData=true)
  static void publishEventKitStatus() {
    Test.startTest();        
    FulfillmentOrder fo = getFO();

    FulfillmentOrder fo1 = [select OrderSummaryId from FulfillmentOrder where Id =: fo.Id];

    Kit_Details__c kit = new Kit_Details__c();
    kit.Fulfillment_Order_Id__c=fo.Id;
    kit.Order_Summary__c=fo1.OrderSummaryId;
    kit.ActivationUser_Customer_Email__c='test@test.com';
    kit.ActivationUser_Customer_Id__c='1212121211';
    kit.Status__c='Activated';
    kit.Lab_Status__c='Sample Received';
    kit.Type__c='at_home';
    kit.Order_Number__c='QST-'+fo.Id;
    kit.Tracking_Number__c='1212344gjasd';
    insert kit;

        List<SFMC_Email_Event__e> eventLst = new List<SFMC_Email_Event__e>();
      SFMC_OMS_Config__c  newConfig= new SFMC_OMS_Config__c (Channel__c = 'QD-CIT',Auth_Token__c ='77778888888812213', API__C = 'Common');
                insert newConfig;    
                SFMC_Email_Event__e event = new SFMC_Email_Event__e(Kit_Detail_ID__c=kit.Id,Is_Partner_Order__c=false,EventDefinitionKey__c=Label.SFMC_Kit_Sample_Received_Event_Definition_Key,Event_Type__c = Label.SFMC_Kit_Events);   
  
   // Publish test event
   eventLst.add(event);
   
   EventBus.publish(eventLst);
   Test.stopTest();    
   
  }

    private static FulfillmentOrder getFO()
      {
          // Test data setup
      String salesChannel = 'Quest_US';
      String currencyIsoCode = 'USD';
      String orderTypeCode = 'Web';
      String MerchantID = 'Quest_US';
      

      Map<String,SObject> m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);       

      Order newOrder = (Order)m_mapTestData.get('newOrder');    
      SFOMTestDataFactory.UpdateOrderStatus(newOrder ,'Activated' );                      
      List<OrderSummary> lstOS = [SELECT Id FROM OrderSummary where OriginalOrderId=:newOrder.Id ];

      // System.assert(!lstOS.isEmpty());
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
      

      SFOMCreateFulfillmentOrder.InputParameters obj = new SFOMCreateFulfillmentOrder.InputParameters();        
      obj.orderSummaryId = lstOS[0].Id;     
      List<SFOMCreateFulfillmentOrder.InputParameters> objLst = new List<SFOMCreateFulfillmentOrder.InputParameters>();
      objLst.add(obj);    
      SFOMCreateFulfillmentOrder.createTransaction(objLst); 

    List<Id> oSumIdLst = new List<Id>();
    oSumIdLst.add(lstOS[0].Id);
      
    List<FulfillmentOrder> fos = [SELECT Id from FulfillmentOrder where OrderSummaryId =: lstOS[0].Id];
    FulfillmentOrder fo = fos[0];
    fo.RecordTypeId=Label.SFOM_In_Person_Record_Type_Id;
        fo.Status = 'Pending Approval';
        fo.LastName__c ='Test';
        fo.FirstName__c ='Test';
        fo.Physician_First_Name__c='Test';
        fo.Physician_Last_Name__c='Test';
        fo.Physician_Npi__c='121212';
        fo.Physician_Upin__c='121121';
        fo.PWN_ID__c='12121';
        fo.FulfilledToAddressLine1__c = '123 Street';

        update fo;
        
        List<OrderItemSummary> OrderItemLst = [SELECT Id, TestType__c  from OrderItemSummary where OrderSummaryId IN :oSumIdLst and Type!='Delivery Charge'];
      for(OrderItemSummary item :OrderItemLst){       
              item.TestType__c='PSC';
      }
  
  update OrderItemLst;

      OrderSummary oOrderSummary1 = new OrderSummary();
      oOrderSummary1  = lstOS[0];
      oOrderSummary1.Partner_Name__c='Quest';

      update oOrderSummary1;
      
        return fo;
      }
   
       
  
       
}