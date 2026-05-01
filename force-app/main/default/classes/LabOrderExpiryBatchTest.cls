/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class LabOrderExpiryBatchTest {


    public static Map<String,SObject> m_mapTestData = null;
    
   @IsTest (SeeAllData=true)
    public static void testSuccess () {
        
        String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
        //m_mapTestData = SFOMTestDataFactory.initData(salesChannel, currencyIsoCode);  
        m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);
        
   
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
            ops.paymentType__c='gift_card';
            
            update ops;
            
                      
            lstOPS= [SELECT Id,paymentType__c, OrderSummaryId FROM OrderPaymentSummary where OrderSummaryId=:oOrderSummary.Id ];
            System.debug('******After Update lstOPS*******'+lstOPS);
                    
            
            
            
        
        
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

          List<OrderItemSummary> orderItemSummaryList = [Select Id, quantity FROM OrderItemSummary WHERE OrderSummaryId =: orderSummaryId AND OrderDeliveryGroupSummaryId =: orderDeliveryGroupSummary.Id and TestType__c='PSC'];
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

ConnectApi.FulfillmentOrderInputRepresentation fulfillmentOrderInput2 = new ConnectApi.FulfillmentOrderInputRepresentation();
        fulfillmentOrderInput2.orderSummaryId = orderSummaryId;

for (OrderDeliveryGroupSummary orderDeliveryGroupSummary: orderDeliveryGroupSummaryList){

        fulfillmentOrderInput2.orderDeliveryGroupSummaryId = orderDeliveryGroupSummary.Id;
        List<ConnectApi.FulfillmentGroupInputRepresentation> fulfillmentGroups = new List<ConnectApi.FulfillmentGroupInputRepresentation>();
        ConnectApi.FulfillmentGroupInputRepresentation fulfillmentGroup = new ConnectApi.FulfillmentGroupInputRepresentation();
        fulfillmentGroup.fulfilledFromLocationId = location.Id;
        fulfillmentGroup.fulfillmentType = location.LocationType;

        List<ConnectApi.OrderItemSummaryInputRepresentation> orderItemSummaries = new List<ConnectApi.OrderItemSummaryInputRepresentation>();

          List<OrderItemSummary> orderItemSummaryList = [Select Id, quantity FROM OrderItemSummary WHERE OrderSummaryId =: orderSummaryId AND OrderDeliveryGroupSummaryId =: orderDeliveryGroupSummary.Id and TestType__c='PA'];
          for(OrderItemSummary orderItemSummary : orderItemSummaryList){
            ConnectApi.OrderItemSummaryInputRepresentation oisInputRepresentation = new ConnectApi.OrderItemSummaryInputRepresentation();
            oisInputRepresentation.orderItemSummaryId = orderItemSummary.Id;
            oisInputRepresentation.quantity = orderItemSummary.quantity;
            orderItemSummaries.add(oisInputRepresentation);
          }

          fulfillmentGroup.orderItemSummaries = orderItemSummaries;
          fulfillmentGroups.add(fulfillmentGroup);      
          fulfillmentOrderInput2.fulfillmentGroups = fulfillmentGroups;

        }

     
ConnectApi.FulfillmentOrderOutputRepresentation result2 = ConnectAPI.FulfillmentOrder.createFulfillmentOrders(fulfillmentOrderInput2);

        /***************************************************************************************************************************************/
        

   System.debug('FOs ' + result );
   
      System.debug('FOs2 ' + result2 );
        
         FulfillmentOrder lstFO = new FulfillmentOrder();
            System.debug('Welcome lstFO 1==>'+lstFO.id);         
            //FulfillmentOrder foo= lstFO[0];
            lstFO.id= result.fulfillmentOrderIds[0];
            lstFO.Status = 'PA Approved';
            lstFO.RecordTypeId=Label.SFOM_In_Person_Record_Type_Id;
            lstFO.PWN_Status_Date__c = date.parse('4/17/2022');
            lstFO.Service_Fee__c=20.00;
            update lstFO ;
            
            ConnectApi.FulfillmentOrderInvoiceInputRepresentation invIp = new ConnectApi.FulfillmentOrderInvoiceInputRepresentation();
        ConnectApi.FulfillmentOrderInvoiceOutputRepresentation invOp = ConnectApi.FulfillmentOrder.createInvoice(
            lstFO.Id,
            invIp
        );
        
        FulfillmentOrder pwn = new FulfillmentOrder();
            System.debug('Welcome lstFO 1==>'+lstFO.id);         
            //FulfillmentOrder foo= lstFO[0];
            pwn.id= result2 .fulfillmentOrderIds[0];
            pwn.RecordTypeId=Label.SFOM_PWN_Service_Record_Type_Id;
            update pwn ;
            
           
            
FulfillmentOrder foInput = [Select  Id,RecordTypeId,InvoiceId,Status,OrderSummaryId,GrandTotalAmount,Service_Fee__c from FulfillmentOrder where Id=:lstFO.id];            
            
            System.debug('%%%%%%%%%%%%%% FO Input ***************' + foInput  );
            
            FulfillmentOrder foInput2 = [Select  Id,RecordTypeId,OrderSummaryId from FulfillmentOrder where  Id=:pwn.id];            
            
            System.debug('%%%%%%%%%%%%%% FO Input ***************' + foInput2  );

            Account ac = new Account();
            ac.Name = 'Test account';
            insert ac;
            
            Contact con = new Contact();
            con.lastName = 'test con';
            con.Email = 'test@gmail.com';
            con.AccountId = ac.Id;
            insert con;
         
            SalesChannel SC = new SalesChannel();	
            SC.SalesChannelName = 'QDCIT Partner';
            SC.Description = 'QDCIT Partner';
            insert SC;
            
            PartnerClientMap__c PCM = new PartnerClientMap__c();
            PCM.Name = 'Google12121'; 
            PCM.Sales_Channel__c = SC.Id;
            PCM.Partner_Name__c = 'google121';
            PCM.Client_ID__c = '34566121';
           
            insert PCM;
            
            Panel__c p = new Panel__c();
            p.Panel_Code__c = '12767';
            p.Panel_Name__c = 'test panel';
            insert p;
            
            Test__c t = new Test__c();
            t.Test_Code__c = '12767';
            t.Test_Name__c = 'demo test';
            insert t;
            
          
            Person_Record__c pr = new Person_Record__c();
            pr.Email__c= 'test@gmail.com';
            pr.First_Name__c= 'Fname';
            pr.Last_Name__c= 'LName';
            pr.Phone__c= '4569990422';
            pr.Gender__c = 'Male';
            pr.Contact__c = con.Id;
            pr.Date_of_Birth__c=  date.valueOf('2000-12-12');
            pr.Address_Line_1__c= 'gfds';
            pr.City__c= 'Santa Barbara';
            pr.State__c= 'CA';
            pr.Postal_Code__c= '93110';
            pr.Country__c = 'US';
            pr.Unique_Identifier__c = 'test@gmail.com'+':'+'2000-12-12'+':'+'LName';
            insert pr;
            
            Lab_order__c lb = new Lab_Order__c();
            lb.Person_Record__c = pr.id;
            lb.Partner_Client_Map__c = PCM.id;
            lb.Client_Name__c = 'clientName';
            lb.Name = 'clientName';
            lb.Status__c = 'PA Approved';
            lb.PWN_Status_Date__c = date.parse('4/17/2024');
            lb.Order_Summary__c=orderSummaryId;
            lb.Fulfillment_Order__c=lstFO.id;
            lb.Refund_Amount__c=10.00;
            lb.Refund_Attempts__c=2;
            insert lb;
            
            Panel_Test__c pt = new Panel_Test__c();
            pt.Panel__c = p.id;
            pt.Test__c = t.Id;
            insert pt;
            
            Lab_Order_Panel__c LOP = new Lab_Order_Panel__c();
            LOP.HRA_Req__c = true;
            LOP.Lab_Order__c = lb.id;
            LOP.Panel__c = p.id;
            insert LOP;
            
            Lab_Panel_Test__c lbt = new Lab_Panel_Test__c();
            lbt.Lab_Order_Panel__c = LOP.id;
            lbt.Status__c = 'Registered';
            lbt.Lab_Order__c=lb.id;
            lbt.Panel_Test__c = pt.id;
            insert lbt;

            
            Test.startTest();

            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

            
            
            LabOrderExpiryBatch btch= new LabOrderExpiryBatch();
            btch.recordType='InPerson';
            btch.labOrderId=lb.Id;
            btch.query = 'SELECT Id, Is_Partner__c,Order_Summary__c,Order_Summary__r.OriginalOrderId,Fulfillment_Order__c,Fulfillment_Order__r.GrandTotalAmount,Fulfillment_Order__r.Service_Fee__c FROM Lab_Order__c WHERE Id=:labOrderId  ';
            Database.executeBatch(btch,1);

            LabOrderRefundRetryBatch btch1= new LabOrderRefundRetryBatch();
            btch1.labOrderId=lb.Id;
            btch1.query = 'SELECT Id, Order_Summary__c,Refund_Amount__c,Refund_Attempts__c FROM Lab_Order__c WHERE Id=:labOrderId ';
            Database.executeBatch(btch1,1);

            Test.stopTest();
            
        
    }
    
    @IsTest 
    static void territoryCheckExpiryTest () {
        LabOrderExpiryBatchSchedule  obj = new LabOrderExpiryBatchSchedule();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, obj); 
  }  

  @IsTest 
  static void territoryCheckRefundTest () {
    LabOrderRefundRetryBatchSchedule  obj = new LabOrderRefundRetryBatchSchedule();
      String sch = '0 0 23 * * ?'; 
      system.schedule('Test Territory Check', sch, obj); 
}  


  @IsTest (SeeAllData=true)
    public static void testError () {
        
        String salesChannel = 'Quest_US';
        String currencyIsoCode = 'USD';
        String orderTypeCode = 'Web';
        String MerchantID = 'Quest_US';
        
        //m_mapTestData = SFOMTestDataFactory.initData(salesChannel, currencyIsoCode);  
        m_mapTestData = SFOMTestDataFactory.initData(salesChannel, orderTypeCode,  currencyIsoCode , MerchantID);
        
   
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
            ops.paymentType__c='gift_card';
            
            update ops;
            
                      
            lstOPS= [SELECT Id,paymentType__c, OrderSummaryId FROM OrderPaymentSummary where OrderSummaryId=:oOrderSummary.Id ];
            System.debug('******After Update lstOPS*******'+lstOPS);
                    
            
            
            
        
        
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

          List<OrderItemSummary> orderItemSummaryList = [Select Id, quantity FROM OrderItemSummary WHERE OrderSummaryId =: orderSummaryId AND OrderDeliveryGroupSummaryId =: orderDeliveryGroupSummary.Id and TestType__c='PSC'];
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

ConnectApi.FulfillmentOrderInputRepresentation fulfillmentOrderInput2 = new ConnectApi.FulfillmentOrderInputRepresentation();
        fulfillmentOrderInput2.orderSummaryId = orderSummaryId;

for (OrderDeliveryGroupSummary orderDeliveryGroupSummary: orderDeliveryGroupSummaryList){

        fulfillmentOrderInput2.orderDeliveryGroupSummaryId = orderDeliveryGroupSummary.Id;
        List<ConnectApi.FulfillmentGroupInputRepresentation> fulfillmentGroups = new List<ConnectApi.FulfillmentGroupInputRepresentation>();
        ConnectApi.FulfillmentGroupInputRepresentation fulfillmentGroup = new ConnectApi.FulfillmentGroupInputRepresentation();
        fulfillmentGroup.fulfilledFromLocationId = location.Id;
        fulfillmentGroup.fulfillmentType = location.LocationType;

        List<ConnectApi.OrderItemSummaryInputRepresentation> orderItemSummaries = new List<ConnectApi.OrderItemSummaryInputRepresentation>();

          List<OrderItemSummary> orderItemSummaryList = [Select Id, quantity FROM OrderItemSummary WHERE OrderSummaryId =: orderSummaryId AND OrderDeliveryGroupSummaryId =: orderDeliveryGroupSummary.Id and TestType__c='PA'];
          for(OrderItemSummary orderItemSummary : orderItemSummaryList){
            ConnectApi.OrderItemSummaryInputRepresentation oisInputRepresentation = new ConnectApi.OrderItemSummaryInputRepresentation();
            oisInputRepresentation.orderItemSummaryId = orderItemSummary.Id;
            oisInputRepresentation.quantity = orderItemSummary.quantity;
            orderItemSummaries.add(oisInputRepresentation);
          }

          fulfillmentGroup.orderItemSummaries = orderItemSummaries;
          fulfillmentGroups.add(fulfillmentGroup);      
          fulfillmentOrderInput2.fulfillmentGroups = fulfillmentGroups;

        }

     
ConnectApi.FulfillmentOrderOutputRepresentation result2 = ConnectAPI.FulfillmentOrder.createFulfillmentOrders(fulfillmentOrderInput2);

        /***************************************************************************************************************************************/
        

   System.debug('FOs ' + result );
   
      System.debug('FOs2 ' + result2 );
        
         FulfillmentOrder lstFO = new FulfillmentOrder();
            System.debug('Welcome lstFO 1==>'+lstFO.id);         
            //FulfillmentOrder foo= lstFO[0];
            lstFO.id= result.fulfillmentOrderIds[0];
            lstFO.Status = 'PA Approved';
            lstFO.RecordTypeId=Label.SFOM_In_Person_Record_Type_Id;
            lstFO.PWN_Status_Date__c = date.parse('4/17/2022');
            lstFO.Service_Fee__c=20.00;
            update lstFO ;
            
            ConnectApi.FulfillmentOrderInvoiceInputRepresentation invIp = new ConnectApi.FulfillmentOrderInvoiceInputRepresentation();
        ConnectApi.FulfillmentOrderInvoiceOutputRepresentation invOp = ConnectApi.FulfillmentOrder.createInvoice(
            lstFO.Id,
            invIp
        );
        
        FulfillmentOrder pwn = new FulfillmentOrder();
            System.debug('Welcome lstFO 1==>'+lstFO.id);         
            //FulfillmentOrder foo= lstFO[0];
            pwn.id= result2 .fulfillmentOrderIds[0];
            pwn.RecordTypeId=Label.SFOM_PWN_Service_Record_Type_Id;
            update pwn ;
            
           
            
FulfillmentOrder foInput = [Select  Id,RecordTypeId,InvoiceId,Status,OrderSummaryId,GrandTotalAmount,Service_Fee__c from FulfillmentOrder where  Id=:lstFO.id];            
            
            System.debug('%%%%%%%%%%%%%% FO Input ***************' + foInput  );
            
            FulfillmentOrder foInput2 = [Select  Id,RecordTypeId,OrderSummaryId from FulfillmentOrder where  Id=:pwn.id];            
            
            System.debug('%%%%%%%%%%%%%% FO Input ***************' + foInput2  );

            Account ac = new Account();
            ac.Name = 'Test account';
            insert ac;
            
            Contact con = new Contact();
            con.lastName = 'test con';
            con.Email = 'test@gmail.com';
            con.AccountId = ac.Id;
            insert con;
         
            SalesChannel SC = new SalesChannel();	
            SC.SalesChannelName = 'QDCIT Partner';
            SC.Description = 'QDCIT Partner';
            insert SC;
            
            PartnerClientMap__c PCM = new PartnerClientMap__c();
            PCM.Name = 'Google121211211'; 
            PCM.Sales_Channel__c = SC.Id;
            PCM.Partner_Name__c = 'googl1212e121';
            PCM.Client_ID__c = '34566121';
           
            insert PCM;
            
            Panel__c p = new Panel__c();
            p.Panel_Code__c = '12767';
            p.Panel_Name__c = 'test panel';
            insert p;
            
            Test__c t = new Test__c();
            t.Test_Code__c = '12767';
            t.Test_Name__c = 'demo test';
            insert t;
            
          
            Person_Record__c pr = new Person_Record__c();
            pr.Email__c= 'test@gmail.com';
            pr.First_Name__c= 'Fname';
            pr.Last_Name__c= 'LName';
            pr.Phone__c= '4569990422';
            pr.Gender__c = 'Male';
            pr.Contact__c = con.Id;
            pr.Date_of_Birth__c=  date.valueOf('2000-12-12');
            pr.Address_Line_1__c= 'gfds';
            pr.City__c= 'Santa Barbara';
            pr.State__c= 'CA';
            pr.Postal_Code__c= '93110';
            pr.Country__c = 'US';
            pr.Unique_Identifier__c = 'test@gmail.com'+':'+'2000-12-12'+':'+'LName';
            insert pr;
            
            Lab_order__c lb = new Lab_Order__c();
            lb.Person_Record__c = pr.id;
            lb.Partner_Client_Map__c = PCM.id;
            lb.Client_Name__c = 'clientName';
            lb.Name = 'clientName';
            lb.Status__c = 'PA Approved';
            lb.PWN_Status_Date__c = date.parse('4/17/2024');
            lb.Order_Summary__c=orderSummaryId;
            lb.Fulfillment_Order__c=lstFO.id;
            lb.Refund_Amount__c=10.00;
            lb.Refund_Attempts__c=2;
            insert lb;
            
            Panel_Test__c pt = new Panel_Test__c();
            pt.Panel__c = p.id;
            pt.Test__c = t.Id;
            insert pt;
            
            Lab_Order_Panel__c LOP = new Lab_Order_Panel__c();
            LOP.HRA_Req__c = true;
            LOP.Lab_Order__c = lb.id;
            LOP.Panel__c = p.id;
            insert LOP;
            
            Lab_Panel_Test__c lbt = new Lab_Panel_Test__c();
            lbt.Lab_Order_Panel__c = LOP.id;
            lbt.Status__c = 'Registered';
            lbt.Panel_Test__c = pt.id;
            lbt.Lab_Order__c=lb.id;
            insert lbt;

            
            Test.startTest();

            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorError());

            
            LabOrderExpiryBatch btch= new LabOrderExpiryBatch();
            btch.recordType='InPerson';
            btch.labOrderId=lb.Id;
            btch.query = 'SELECT Id, Is_Partner__c,Order_Summary__c,Order_Summary__r.OriginalOrderId,Fulfillment_Order__c,Fulfillment_Order__r.GrandTotalAmount,Fulfillment_Order__r.Service_Fee__c FROM Lab_Order__c WHERE Id=:labOrderId  ';
            Database.executeBatch(btch,1);

            
            LabOrderRefundRetryBatch btch1= new LabOrderRefundRetryBatch();
            
            btch1.query = 'SELECT Id, Order_Summary__c,Refund_Amount__c,Refund_Attempts__c FROM Lab_Order__c WHERE Id=:labOrderId ';
            Database.executeBatch(btch1,1);

            Test.stopTest();
            
        
    }


        // Inner class to mock HTTP response
        public class MockHttpResponseGenerator implements HttpCalloutMock {
            public HTTPResponse respond(HTTPRequest req) {
                HttpResponse res = new HttpResponse();
                res.setStatusCode(200);
                res.setBody('Mock response body');
                return res;
            }
        }

         // Inner class to mock HTTP response
         public class MockHttpResponseGeneratorError implements HttpCalloutMock {
            public HTTPResponse respond(HTTPRequest req) {
                HttpResponse res = new HttpResponse();
                res.setStatusCode(400);
                res.setBody('Mock response body');
                return res;
            }
        }
    

    
}