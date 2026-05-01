@isTest
public  class SFOMTestDataFactory {

     private static final String street = '120 Main St.';
    private static final String city = 'Kansas City';
    private static final String state = 'Missouri';
    private static final String postalCode = '64109';
    private static final String country = 'United States';
    private static String email = 'johndoe@test.com';
    private static final String phone = '201-227-1122';
    private static final String firstName = 'John';
    private static final String lastName = 'Doe';

    private static Integer productSequence = 0;
    private static String UniquePreFix=''; // Use to uniquely generate Test Data (when using SeeAllData=True)

    public SFOMTestDataFactory() {}

    
    public static Map<String, SObject> initData(String salesChannel,  String orderTypeCode, String CurrencyCode, String MerchantID) {
            Map<String,SObject> testData = new Map<String,SObject>();

   
            Account personAccount = createPersonAccount('John', 'Doe' + UniquePreFix, 'John' + ' Doe' + UniquePreFix);
            insert personAccount;
            
            

            Contact NewContact = CreateContact(personAccount, 'John', 'Doe'+ UniquePreFix, email, Phone);
            insert NewContact;
           

            Pricebook2 pricebook = createPriceBook();
            update pricebook;
            
            

            /**************************************************************************************/ 
            /*                                    Product                                         */
            /**************************************************************************************/
            Product2 newProduct1 = createProduct('SKU1'+UniquePreFix, 'Product 1' + UniquePreFix);
            insert newProduct1;
           
            
            PricebookEntry newPricebookEntry1 = createPricebookEntry(pricebook, newProduct1, 23.5);
            insert newPricebookEntry1;
            
                         
            Product2 newProduct2 = createProduct('SKU2'+  UniquePreFix, 'Product 2' + UniquePreFix);
            insert newProduct2;
            
            
            PricebookEntry newPricebookEntry2 = createPricebookEntry(pricebook, newProduct2, 23.5);
            insert newPricebookEntry2;
            
           
            Product2 newProductGiftCard = createProduct('GIFT_CARD', 'Gift Card' + UniquePreFix); //GIFT_CARD already exist in sandbox
            insert newProductGiftCard;
         
              
            PricebookEntry newPricebookEntryGiftCard = createPricebookEntry(pricebook, newProductGiftCard, 0);
            insert newPricebookEntryGiftCard;
            
           
            
            /**************************************************************************************/ 
            /*                           Shipping Product                                         */
            /**************************************************************************************/
           List<Product2> shippingProd = new List<Product2>([Select Id, Description from Product2 where ProductCode = 'Shipping']);
            Product2 shippingProduct = shippingProd.size()>0? shippingProd[0] : createShippingProduct();
            if(shippingProd == NULL)
        		insert shippingProduct;
            
        	List<PricebookEntry> pbEntry = new List<PriceBookEntry>([Select Id, Product2.Name, Pricebook2.Name, UnitPrice from PricebookEntry where Product2Id =: shippingProduct.Id]);
            PricebookEntry newShippingPricebookEntry = pbEntry.size()>0? pbEntry[0]: createPricebookEntry(pricebook, shippingProduct, 7.95);
        	if(pbEntry == NULL)    
        		insert newShippingPricebookEntry;
            else{
                newShippingPricebookEntry.UnitPrice = 7.95;
                update newShippingPricebookEntry;
            }
            
           
            OrderDeliveryMethod newOrderDeliveryMethodPRMAIL = createOrderDeliveryMethod(shippingProduct, 'PRMAIL', 'PRMAIL');
            insert newOrderDeliveryMethodPRMAIL;
            
            
            /**************************************************************************************/ 
            /*                                 Order                                              */
            /**************************************************************************************/
            SalesChannel newSalesChannel = createSalesChannel(salesChannel, MerchantID, CurrencyCode);
            insert newSalesChannel;

           

            Order newOrder = createOrder(personAccount, NewContact, pricebook, newSalesChannel, Street, City, State, PostalCode, Country, email, Phone, 'ORDREF'+UniquePreFix, 'Agent'+UniquePreFix);
            insert newOrder;
            
            


            /**************************************************************************************/ 
            /*                            Order Item Stuff                                        */
            /**************************************************************************************/
            OrderDeliveryGroup newOrderDeliveryGroup = createOrderDeliveryGroup(newOrder, newOrderDeliveryMethodPRMAIL, 'John' + ' Doe' + UniquePreFix, Street, City, State, PostalCode, Country, email, Phone,firstName,lastName);
            insert newOrderDeliveryGroup;

         
            OrderItem newOrderItem1 = createOrderItem(newOrder, newProduct1, newOrderDeliveryGroup, newPricebookEntry1, 'Order Product', 1);
            insert newOrderItem1;
            System.Debug('OrderItemIDValue'+ newOrderItem1.Id + ', OrdIDVal' + newOrderItem1.OrderId);

            OrderItemTaxLineItem newTaxOrderItem1 = createOrderItemTaxLineItem(newOrderItem1, .08, 1.88);
            insert newTaxOrderItem1;
         
            OrderItem newOrderItem2 = createOrderItem(newOrder, newProduct2, newOrderDeliveryGroup, newPricebookEntry2, 'Order Product', 2);
            insert newOrderItem2;
            System.Debug('OrderItemIDValue'+ newOrderItem2.Id + ', OrdIDVal' + newOrderItem2.OrderId);
            
            
            OrderItem newOrderItem3 = createPWNOrderItem(newOrder, newProduct2, newOrderDeliveryGroup, newPricebookEntry2, 'Order Product', 2);
            insert newOrderItem3;
            System.Debug('OrderItemIDValue'+ newOrderItem3.Id + ', OrdIDVal' + newOrderItem3.OrderId); 

            OrderItemTaxLineItem newTaxOrderItem2 = createOrderItemTaxLineItem(newOrderItem2, .08, 1.88);
            insert newTaxOrderItem2;
          
            OrderItem newShippingOrderItem = createOrderItem(newOrder, shippingProduct, newOrderDeliveryGroup, newShippingPricebookEntry, 'Delivery Charge', 1000);
            insert newShippingOrderItem;
        
            OrderItemTaxLineItem newTaxOrderItemShipping = createOrderItemTaxLineItem(newShippingOrderItem, .08, .64);
            insert newTaxOrderItemShipping;
          

            /**************************************************************************************/ 
            /*                            Payment                                                 */
            /**************************************************************************************/
            //Payment Gateway
            PaymentGateway stripePaymentGateway = createPaymentGateway('Stripe' + UniquePreFix);
            insert stripePaymentGateway ;
            
            // Payment Group
            PaymentGroup newPaymentGroup = createPaymentGroup(newOrder);
            insert newPaymentGroup;
            
           
            // Create a credit card payment
            CardPaymentMethod newCardPaymentMethod = createCardPaymentMethod(personAccount, stripePaymentGateway , 'CreditCard', 'Visa', 5, 2023, '', City, Country, PostalCode, State, Street, 'External', 'Active');
            insert newCardPaymentMethod;
           
            Payment newCardPayment = createCardPayment(9.35, newPaymentGroup, personAccount, newCardPaymentMethod, stripePaymentGateway , 'External', 'Processed', 'Sale', 'CREDITCARD');
            insert newCardPayment;
            
            PaymentAuthorization paymentAuth= createCardPaymentAuthorization(9.35, newPaymentGroup, personAccount, newCardPaymentMethod, stripePaymentGateway , 'External', 'Processed', 'Sale', 'CREDITCARD');
            insert paymentAuth;
            
            PaymentGatewayLog newCardPaymentGatewayLog = createPaymentGatewayLog(newCardPayment,'Success','Sale');
            insert newCardPaymentGatewayLog; 
                        
      
            /**************************************************************************************/ 
            /*             Location record for allocation to work                                 */
            /**************************************************************************************/
            // Location record for allocation to work
            Schema.Location newLocationUSCE = createLocation( 'USCommerceEast'+UniquePreFix,  'USCommerceEast'+UniquePreFix, 'Warehouse');
            insert new List<Schema.Location>{newLocationUSCE};
            
            System.debug('newLocationUSCE ==> '+ newLocationUSCE);

            Schema.Location newLocationUSCW = createLocation( 'USCommerceWest'+UniquePreFix,  'USCommerceWest'+UniquePreFix, 'Warehouse');
            insert new List<Schema.Location>{newLocationUSCW};

            LocationGroup newLocationGroupEastC = createLocationgroup('East'+UniquePreFix);
            insert newLocationGroupEastC;

            LocationGroup newLocationGroupWestC = createLocationgroup('West'+UniquePreFix);
            insert newLocationGroupWestC;

            LocationGroupAssignment newLocationGroupAssignmentEast = createLocationgroupAssignment(newLocationUSCE, newLocationGroupEastC);
            insert newLocationGroupAssignmentEast;

            LocationGroupAssignment newLocationGroupAssignmentWest = createLocationgroupAssignment(newLocationUSCW, newLocationGroupWestC);
            insert newLocationGroupAssignmentWest;


             /**
             * Adding all data into the data map to return
             */
            testData.put('personAccount', personAccount);
            testData.put('NewContact', NewContact);
            testData.put('pricebook', pricebook);
            testData.put('newProduct1', newProduct1);
            testData.put('PricebookEntry1', newPricebookEntry1);
            testData.put('newProduct2', newProduct2);
            testData.put('PricebookEntry2', newPricebookEntry2);
            testData.put('newProductGiftCard', newProductGiftCard);
            testData.put('newPricebookEntryGiftCard', newPricebookEntryGiftCard);
            testData.put('shippingProduct', shippingProduct);
            testData.put('newShippingPricebookEntry', newShippingPricebookEntry);
            testData.put('newOrderDeliveryMethodPRMAIL', newOrderDeliveryMethodPRMAIL);
            testData.put('newSalesChannel', newSalesChannel);
            testData.put('newOrder', newOrder);
            testData.put('newOrderDeliveryGroup', newOrderDeliveryGroup);
            testData.put('newOrderItem1', newOrderItem1);
            testData.put('newTaxOrderItem1', newTaxOrderItem1);
            testData.put('newOrderItem2', newOrderItem2);
            testData.put('newTaxOrderItem2', newTaxOrderItem2);
            testData.put('newShippingOrderItem', newShippingOrderItem);
            testData.put('newTaxOrderItemShipping', newTaxOrderItemShipping);
            testData.put('newPaymentGroup', newPaymentGroup);
            testData.put('adyenPaymentGateway', stripePaymentGateway);
            testData.put('newCardPaymentMethod', newCardPaymentMethod);
            testData.put('newCardPayment', newCardPayment);
              testData.put('paymentAuth', paymentAuth);
            testData.put('newCardPaymentGatewayLog', newCardPaymentGatewayLog);
            testData.put('newLocationUSCE', newLocationUSCE);
            testData.put('newLocationUSCW', newLocationUSCW);
            testData.put('newLocationGroupEastC', newLocationGroupEastC);
            testData.put('newLocationGroupWestC', newLocationGroupWestC);
            testData.put('newLocationGroupAssignmentEast', newLocationGroupAssignmentEast);
            testData.put('newLocationGroupAssignmentWest', newLocationGroupAssignmentWest);
            



            
            return testData;
           }
    
     
        public static Account createPersonAccount(String FirstName, String LastName, String FullName) {
            Account personAccount = new Account();
            personAccount.Name = FullName;
            return personAccount;
        }

        public static Contact createContact(Account account, String FirstName, String LastName, String ipEmail, String ipPhone) {
            Contact NewContact = new Contact();
            NewContact.FirstName = FirstName;
            NewContact.LastName = LastName;
            NewContact.Email = ipEmail;
            NewContact.Phone = ipPhone;
            NewContact.AccountId = account.id;
    
            NewContact.MailingStreet = '123 Some St';
            NewContact.MailingCity = 'McKinney';
            NewContact.MailingState = 'TX';
            NewContact.MailingCountry = 'USA';
            NewContact.MailingPostalCode = '75070';
            
            return NewContact;
        }

        public static Pricebook2 createPriceBook() {
            Pricebook2 priceBook = new Pricebook2();
            pricebook.Id = Test.getStandardPricebookId();
            if (pricebook.Id == null) { // Get Standard PriceBook ID
               pricebook.Id = '01s3h000004kmN2AAI';
            }
            priceBook.Name = 'Standard Price Book';
            priceBook.IsActive = true;
            return priceBook;
        }

        public static Product2 createProduct(String sku, String name) {
            productSequence = productSequence + 1;
    
            Product2 product = new Product2();
            product.Name = name;
            product.Description = name;
            product.ProductCode = sku;
            product.StockKeepingUnit = sku + String.valueOf(productSequence);
            product.DisplayUrl = '';
            product.ExternalId = sku;
            product.IsActive = true;
            return product;
        }

        public static PricebookEntry createPricebookEntry(Pricebook2 pricebook, Product2 product, Decimal fUnitPrice) {
            PricebookEntry newPricebookEntry = new PricebookEntry();
            newPricebookEntry.Pricebook2Id = pricebook.Id; // Test.getStandardPricebookId();
            newPricebookEntry.Product2Id = product.Id;
            newPricebookEntry.UnitPrice = fUnitPrice;
            newPricebookEntry.UseStandardPrice = false;
            newPricebookEntry.IsActive = true;
            return newPricebookEntry;
        }

        public static Product2 createShippingProduct() {
            Product2 product = new Product2();
            product.ProductCode = 'SHIPPING'; //SHIPPING already in sandbox
            product.Name = 'SHIPPING';
            product.Description = 'SHIPPING';
            //product.Weight__c = 0.0;
            product.IsActive = true;
            return product;
        }

        public static OrderDeliveryMethod createOrderDeliveryMethod(Product2 shippingProduct, String name, String referenceNumber) {
            OrderDeliveryMethod newOrderDeliveryMethodPRMAIL = new OrderDeliveryMethod();
            newOrderDeliveryMethodPRMAIL.Name = name;
            newOrderDeliveryMethodPRMAIL.isActive = true;
            newOrderDeliveryMethodPRMAIL.ProductId = shippingProduct.Id;
            newOrderDeliveryMethodPRMAIL.ReferenceNumber = referenceNumber;
            return newOrderDeliveryMethodPRMAIL;
        }

        public static SalesChannel createSalesChannel(String salesChannel, String MerchantID, String CurrencyCode) {
            SalesChannel newSalesChannel = new SalesChannel();
            newSalesChannel.SalesChannelName = salesChannel;
            //newSalesChannel.adyensompackage__AdyenMerchantID__c = MerchantID;
           // newSalesChannel.CurrencyIsoCode = CurrencyCode;
           // newSalesChannel.ExternalChannelNumber = salesChannel;
            //newSalesChannel.Description = salesChannel;
            return newSalesChannel;
        }

        public static Order createOrder(Account account, Contact contact, Pricebook2 pricebook, Saleschannel salesChannel, String ipStreet, String ipCity, String ipState, String ipPostalCode, String ipCountry, String ipemail, String ipphone, String OrdRef, String AgentName) {
            Order newOrder = new Order();
            newOrder.name = 'SFUS' + getRandomNumber(4);
            newOrder.AccountId = account.id;
            newOrder.BillToContactId = contact.id;
            newOrder.EffectiveDate = Date.today();
            newOrder.Status = 'Draft';
            newOrder.BillingStreet = street;
            newOrder.BillingCity = city;
            newOrder.BillingState = state;
            newOrder.BillingPostalCode = postalCode;
            newOrder.BillingCountry = country;
            newOrder.BillingEmailAddress = email;
            newOrder.BillingPhoneNumber = phone;
            newOrder.PriceBook2Id = pricebook.Id; //Test.getStandardPricebookId();
            newOrder.SalesChannelId = salesChannel.Id;
            newOrder.OrderReferenceNumber = OrdRef;
            newOrder.OrderedDate = Date.Today();
            newOrder.CustomerId__c='1212102809812';
            newOrder.Client_Id__c='0128918291';
            newOrder.CustomerDOB__c='1990-08-02';
            newOrder.Gender__c='Male';
            newOrder.promoAttributes_json__c= '{"promotions":[{"coupon_code__c":"","coupon_id__c":"","promo_type__c":"percent","promo_amount__c":13.4,"source_code__c":"abc123","customer_group__c":"group1,group2","campaign_id__c":"Generic Campaign","promo_id__c":"test-product-promo-1","start_date__c":"","end_date__c":""},{"coupon_code__c":"SAVE15","coupon_id__c":"test-coupon","promo_type__c":"dollar","promo_amount__c":15,"source_code__c":"","customer_group__c":"everyone","campaign_id__c":"Coupon Campaign","promo_id__c":"test-product-promo-2","start_date__c":"3/1/2023","end_date__c":"3/31/2023"}]}';
            newOrder.utmData__c='{"utm_source":"google","utm_medium":"cpc","utm_campaign":"unbr-mens-health","utm_content":"706088180122","utm_adgroup":"male-fertility-at-home-kit","utm_clickid":"EAIaIQobChMIy4G_89KAiwMVXZfuAR2WoAQUEAAYAiAAEgLdAfD_BwE","utm_device":"m","orderNo":"3C6A6D-C103-FAF4BFAD55580B09"}';
            return newOrder;
        }

        public static String getRandomNumber(integer stringLength) {
            final integer MAX = integer.valueOf(Math.pow(10,stringLength) - 1);
            return String.valueOf(Math.Round(Math.Random() * MAX)).leftPad(stringLength,'0');
        }
        public static OrderDeliveryGroup createOrderDeliveryGroup(Order order, OrderDeliveryMethod orderDeliveryMethod, String DeliverToName, String ipStreet, String ipCity, String ipState, String ipPostalCode, String ipCountry, String ipemail, String ipphone,String firstName,String lastName) {
            OrderDeliveryGroup newOrderDeliveryGroup = new OrderDeliveryGroup();
            newOrderDeliveryGroup.OrderId = order.Id;
            newOrderDeliveryGroup.DeliverToName = DeliverToName;
            newOrderDeliveryGroup.First_Name__c= firstName;
            newOrderDeliveryGroup.Last_Name__c = lastName;
            newOrderDeliveryGroup.DeliverToStreet = ipstreet;
            newOrderDeliveryGroup.DeliverToCity = ipcity;
            newOrderDeliveryGroup.DeliverToState = ipstate;
            newOrderDeliveryGroup.DeliverToPostalCode = ippostalCode;
            newOrderDeliveryGroup.DeliverToCountry = ipcountry;
            newOrderDeliveryGroup.EmailAddress = ipemail;
            newOrderDeliveryGroup.PhoneNumber = ipphone;
            newOrderDeliveryGroup.OrderDeliveryMethodId = orderDeliveryMethod.Id;
            return newOrderDeliveryGroup;
        }

        public static OrderItem createOrderItem(Order order, Product2 product, OrderDeliveryGroup orderDeliveryGroup, PricebookEntry pricebookEntry, String type, Integer lineNumber) {
            OrderItem newOrderItem = new OrderItem();
            newOrderItem.OrderId = order.Id;
            newOrderItem.OrderDeliveryGroupId = orderDeliveryGroup.Id;
            newOrderItem.Description = product.Description;
            newOrderItem.Type = type;
            newOrderItem.Product2Id = product.Id;
            newOrderItem.PricebookEntryId = pricebookEntry.Id;
            newOrderItem.Quantity = 1;
            newOrderItem.LineNumber = lineNumber;
            newOrderItem.UnitPrice = pricebookEntry.UnitPrice;
            newOrderItem.TotalLineAmount = pricebookEntry.UnitPrice;
            newOrderItem.TestType__c='PSC';
            newOrderItem.Is_Service__c=true;
            newOrderItem.HRAReq__c=true;
            newOrderItem.PerformingSite__c='PHP';
            if(lineNumber==1)
            {
                newOrderItem.Product_cancel_fee__c=15.00;    
            }
            else
            {
                 newOrderItem.Product_cancel_fee__c=30.00;    
            }
            newOrderItem.promoAttributes_json__c = '{"promotions":[{"coupon_code__c":"","coupon_id__c":"","promo_type__c":"percent","promo_amount__c":13.4,"source_code__c":"abc123","customer_group__c":"group1,group2","campaign_id__c":"Generic Campaign","promo_id__c":"test-product-promo-1","start_date__c":"","end_date__c":""},{"coupon_code__c":"SAVE15","coupon_id__c":"test-coupon","promo_type__c":"dollar","promo_amount__c":15,"source_code__c":"","customer_group__c":"everyone","campaign_id__c":"Coupon Campaign","promo_id__c":"test-product-promo-2","start_date__c":"3/1/2023","end_date__c":"3/31/2023"}]}';
            newOrderItem.attestationJSON__c='[{"questionText":"Sex/gender","code":22200015,"value":"F","isAoe":true},{"questionText":"Are you pregnant?","code":22200016,"value":"N","isAoe":false}]';
            system.debug(order.OrderReferenceNumber + '-' + lineNumber);
            return newOrderItem;
        }
        
        public static OrderItem createPWNOrderItem(Order order, Product2 product, OrderDeliveryGroup orderDeliveryGroup, PricebookEntry pricebookEntry, String type, Integer lineNumber) {
            OrderItem newOrderItem = new OrderItem();
            newOrderItem.OrderId = order.Id;
            newOrderItem.OrderDeliveryGroupId = orderDeliveryGroup.Id;
            newOrderItem.Description = product.Description;
            newOrderItem.Type = type;
            newOrderItem.Product2Id = product.Id;
            newOrderItem.PricebookEntryId = pricebookEntry.Id;
            newOrderItem.Quantity = 1;
            newOrderItem.LineNumber = lineNumber;
            newOrderItem.UnitPrice = pricebookEntry.UnitPrice;
            newOrderItem.TotalLineAmount = pricebookEntry.UnitPrice;
            newOrderItem.TestType__c='PA';
            newOrderItem.Is_Service__c=false;
            newOrderItem.HRAReq__c=false;
            newOrderItem.PerformingSite__c='PHP';
            system.debug(order.OrderReferenceNumber + '-' + lineNumber);
            return newOrderItem;
        }

        public static OrderItemTaxLineItem createOrderItemTaxLineItem(OrderItem orderItem, Decimal fRate, Decimal fAmount) {
            OrderItemTaxLineItem orderItemTaxLineItem = new OrderItemTaxLineItem();
            orderItemTaxLineItem.Name = (orderItem.Description + ' Tax');
            orderItemTaxLineItem.OrderItemId = orderItem.Id;
            orderItemTaxLineItem.TaxEffectiveDate = Date.today();
            orderItemTaxLineItem.Type = 'Estimated';
            orderItemTaxLineItem.Rate = fRate;
            orderItemTaxLineItem.Amount = fAmount;
            return orderItemTaxLineItem;
        }

        public static PaymentGateway createPaymentGateway(String gatewayName) {
            List<NamedCredential> lstNC = [select Id from NamedCredential where DeveloperName = 'Stripe'];
            if (lstNC.size() == 0) {
                System.debug('ERROR: Mock_Creds not found!!');
                return null;
            }
    
            List<PaymentGatewayProvider> lstPGP = [select Id from PaymentGatewayProvider where MasterLabel = 'CommercePaymentsStripeAdapter'];
            if (lstPGP.size() == 0) {
                System.debug('ERROR: payeezyAdapter not found');
                return null;
            }
    
            PaymentGateway newPaymentGateway = new PaymentGateway();
            newPaymentGateway.PaymentGatewayName = gatewayName;
            newPaymentGateway.PaymentGatewayProviderId = lstPGP[0].Id;
            newPaymentGateway.MerchantCredentialId = lstNC[0].Id;
            newPaymentGateway.Status = 'Active';
            return newPaymentGateway;
        }
        public static PaymentGatewayLog createPaymentGatewayLog(Payment payment, String Status, String InteractionType) {
            PaymentGatewayLog pymtGatewayLog = new PaymentGatewayLog();
            pymtGatewayLog.InteractionStatus = Status; // 'Success'
            pymtGatewayLog.InteractionType = InteractionType; // 'Sale'
            pymtGatewayLog.ReferencedEntityId = payment.Id;
            return pymtGatewayLog;
        }

        public static PaymentGroup createPaymentGroup(Order order) {
            PaymentGroup newPaymentGroup = new PaymentGroup();
            newPaymentGroup.SourceObject = order;
            return newPaymentGroup;
        }

        public static CardPaymentMethod createCardPaymentMethod(Account account, PaymentGateway paymentGateway, String CardCategory, String CardType, Integer ExpMonth, Integer ExpYr, String GateWayToken, String CPCity, String CPCountry, String CPPostalCode, String CPState, String CPStreet, String Mode, String Status) {
            CardPaymentMethod newCardPaymentMethod = new CardPaymentMethod();
            newCardPaymentMethod.AccountId = account.Id;
            newCardPaymentMethod.CardCategory = CardCategory; //'CreditCard';
            // newCardPaymentMethod.CardPaymentMethodNumber = '';
            newCardPaymentMethod.CardType = CardType; //'MasterCard';
            // newCardPaymentMethod.CardTypeCategory = 'MasterCard';
            newCardPaymentMethod.ExpiryMonth = ExpMonth; //5;
            newCardPaymentMethod.ExpiryYear = ExpYr; //2021;
            newCardPaymentMethod.GatewayToken = GatewayToken; //'8548145760632229';
            newCardPaymentMethod.PaymentGatewayId = paymentGateway.Id;
            newCardPaymentMethod.PaymentMethodCity = CPCity;
            newCardPaymentMethod.PaymentMethodCountry = CPcountry;
            newCardPaymentMethod.PaymentMethodPostalCode = CPPostalCode;
            newCardPaymentMethod.PaymentMethodState = CPState;
            newCardPaymentMethod.PaymentMethodStreet = CPStreet;
            newCardPaymentMethod.ProcessingMode = Mode; //'External'; 
            newCardPaymentMethod.Status = Status; //'Active';
            newCardPaymentMethod.paymentType__c='gift_card';
            //newCardPaymentMethod.Adyen_Log__c = AydenLog; 
            return newCardPaymentMethod;
        }

        public static Payment createCardPayment(Decimal amount, PaymentGroup paymentGroup, Account account, CardPaymentMethod cardPaymentMethod, PaymentGateway paymentGateway, String Mode, String Status, String Typ, String GatewayRefNbr) {
            Payment pymt = new Payment();
            pymt.Amount = amount;
            pymt.ProcessingMode = Mode; //'External'
            pymt.Status = Status; //'Processed'
            pymt.Type = Typ; //'Sale'
            pymt.PaymentGroupId = paymentGroup.Id;
            pymt.AccountId = account.Id;
            pymt.PaymentMethodId = cardPaymentMethod.Id;
            pymt.PaymentGatewayId = paymentGateway.Id;
            pymt.GatewayRefNumber = GatewayRefNbr; // 'CREDITCARD'
            return pymt;
        }
        
        public static PaymentAuthorization createCardPaymentAuthorization(Decimal amount, PaymentGroup paymentGroup, Account account, CardPaymentMethod cardPaymentMethod, PaymentGateway paymentGateway, String Mode, String Status, String Typ, String GatewayRefNbr) {
            PaymentAuthorization pymt = new PaymentAuthorization ();
            pymt.Amount = amount;
            pymt.ProcessingMode = Mode; //'External'
            pymt.Status = Status; //'Processed'
            pymt.paymentType__c= 'gift_card'; //'Sale'
            pymt.PaymentGroupId = paymentGroup.Id;
            pymt.AccountId = account.Id;
            pymt.PaymentMethodId = cardPaymentMethod.Id;
            pymt.PaymentGatewayId = paymentGateway.Id;
            pymt.GatewayRefNumber = 'GIFTCARD'; // 'CREDITCARD'
            return pymt;
        }


        public static Schema.Location createLocation( String name, String LocationCode, String LocationType ) {
            Schema.Location loc = new Schema.Location();
            loc.Name =  name;
            loc.LocationType = LocationType;
            loc.ShouldSyncWithOci = true;
            loc.ExternalReference = name;
            return loc;
        }
        
        public static LocationGroup createLocationgroup(String name) {
            LocationGroup locgrp = new LocationGroup();
            locgrp.LocationGroupName =  name;
            locgrp.ShouldSyncWithOci = true;
            locgrp.ExternalReference = name;
            return locgrp;
        }
        
        public static LocationGroupAssignment createLocationgroupAssignment(Schema.Location Location, LocationGroup LocationGroup) {
            LocationGroupAssignment locgrpAsgn = new LocationGroupAssignment();
            locgrpAsgn.LocationId =  Location.ID;
            locgrpAsgn.LocationGroupId = LocationGroup.ID;
            return locgrpAsgn;
        }

        public static void activateOrders() {
            List<Order> orders = [SELECT Id, Status FROM Order];
            for (Order order : orders) {
                order.Status = 'Activated';
            }
            update orders;
        }
        
        public static void UpdateOrderStatus(Order o, String Status) {
            o.Status = Status;
            // o.StatusCode = StatusCode;
            update o;
        }
        
        public static ConnectApi.FulfillmentOrderOutputRepresentation createFulfillmentOrderUsingCApi(OrderSummary orderSummary, Schema.Location location){ 
        ConnectApi.FulfillmentOrderInputRepresentation foir = new ConnectApi.FulfillmentOrderInputRepresentation();
        foir.orderSummaryId = orderSummary.Id; //replace this recordId with an appropriate value.
        foir.orderDeliveryGroupSummaryId = orderSummary.OrderDeliveryGroupSummaries[0].id;
        
        ConnectApi.FulfillmentGroupInputRepresentation fulfillmentGroupInput = new ConnectApi.FulfillmentGroupInputRepresentation();
        fulfillmentGroupInput.fulfilledFromLocationId = location.id;
        fulfillmentGroupInput.fulfillmentType = location.LocationType;

        List<ConnectApi.OrderItemSummaryInputRepresentation> oisirList =  new List<ConnectApi.OrderItemSummaryInputRepresentation>();
        
        for (OrderItemSummary ois : orderSummary.OrderItemSummaries) {
        if (ois.OrderDeliveryGroupSummaryId == orderSummary.OrderDeliveryGroupSummaries[0].Id) {
        Decimal quantityToFullfill = ois.Quantity;
        if (quantityToFullfill > 0) {
          ConnectApi.OrderItemSummaryInputRepresentation oisInputRepresentation = new ConnectApi.OrderItemSummaryInputRepresentation();
          oisInputRepresentation.orderItemSummaryId = ois.Id;
          oisInputRepresentation.quantity = quantityToFullfill;
          oisirList.add(oisInputRepresentation);
        }
        else {
             system.Debug('CreateFulfilmentOrder - Quantity Zero for OrderSummary ID:' + ois.Id);
        }}
        else {
             system.Debug('CreateFulfilmentOrder - OrderDeliveryGroup mis-match for OrderSummary ID:' + ois.Id);
             }
        }

        fulfillmentGroupInput.orderItemSummaries = oisirList;
        System.debug('SOMTestDataFactoryLN597:' + fulfillmentGroupInput);
        List<ConnectApi.FulfillmentGroupInputRepresentation> fulfillmentGroupInputList = new List<ConnectApi.FulfillmentGroupInputRepresentation>();
        fulfillmentGroupInputList.add(fulfillmentGroupInput);

        foir.fulfillmentGroups = fulfillmentGroupInputList;
         
        ConnectApi.FulfillmentOrderOutputRepresentation foor = ConnectApi.FulfillmentOrder.createFulfillmentOrders(foir);
        return foor;
    }
   
   public static Id adjustOrderItemSummarySubmit(Id osId, Id oisId) {
        ConnectApi.AdjustOrderItemSummaryInputRepresentation adjOisIp = new ConnectApi.AdjustOrderItemSummaryInputRepresentation();
        ConnectApi.AdjustItemInputRepresentation adjItem = new ConnectApi.AdjustItemInputRepresentation();
        adjItem.adjustmentType = 'AmountWithTax';
        adjItem.amount = -1.0;
        adjItem.orderItemSummaryId = oisId;
        adjItem.reason = 'System Cancellation';
        List<ConnectApi.AdjustItemInputRepresentation> adjItems = new List<ConnectApi.AdjustItemInputRepresentation>();
        adjItems.add(adjItem);
        adjOisIp.adjustItems = adjItems;
        ConnectApi.AdjustOrderSummaryOutputRepresentation adjOisOp = ConnectApi.OrderSummary.adjustSubmit(
            osId,
            adjOisIp
        );
        return adjOisOp.postFulfillmentChangeOrderId;
    }
    
    public static Id createCreditMemo(Id osId, Id changeOrderId) {
        ConnectApi.CreateCreditMemoInputRepresentation cmIp = new ConnectApi.CreateCreditMemoInputRepresentation();
        List<String> changeOrderIds = new List<String>();
        changeOrderIds.add(changeOrderId);
        cmIp.changeOrderIds = changeOrderIds;
        ConnectApi.CreateCreditMemoOutputRepresentation cmOp = ConnectApi.OrderSummary.createCreditMemo(osId, cmIp);
        return cmOp.creditMemoId;
    }
   
   public static Id createInvoice(string foId) {
        ConnectApi.FulfillmentOrderInvoiceInputRepresentation invIp = new ConnectApi.FulfillmentOrderInvoiceInputRepresentation();
        ConnectApi.FulfillmentOrderInvoiceOutputRepresentation invOp = ConnectApi.FulfillmentOrder.createInvoice(
            foId,
            invIp
        );
        return invOp.invoiceId;
    }
}