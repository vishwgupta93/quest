@isTest
public class PartnerLabOrderResource_Test {
    
    @testSetup
    static void prepareTestData(){
        
     Panel__c p = new Panel__c();
     p.Panel_Code__c = '7788';
     p.Panel_Name__c = 'test panel';
     insert p;
     
     Test__c t = new Test__c();
     t.Test_Code__c = '7788';
     t.Test_Name__c = 'demo test';
     insert t;

     Account accnt = new Account(Name='Test test');
        insert accnt;
        
        Contact con = new Contact();
        con.AccountId = accnt.id;
        con.LastName = 'test';
        insert con;

         // Insert mock Person and Lab_Order__c records
        Person_Record__c person = new Person_Record__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Email__c = 'john.doe@example.com',
            Address_Line_1__c = '123 Main St',
                     City__c = 'Anytown',
            Country__c = 'USA',
            State__c = 'CA',
            Postal_Code__c = '12345',
            Phone__c = '1234567890',
            Gender__c = 'Male',
            Date_of_Birth__c = Date.newInstance(1990, 1, 1),
            Contact__c = con.id,
            Unique_Identifier__c= 'fir@gmail.com:1985-09-09:lNe'
            
        );
        
        insert person;
     
     SalesChannel sc = new SalesChannel();
     sc.SalesChannelName = 'test';
     insert sc;
     SalesChannel sch =   [select id, SalesChannelName from SalesChannel where SalesChannelName = 'test' Limit 1];
     
     PartnerClientMap__c pmc = new PartnerClientMap__c();
     pmc.Sales_Channel__c = sch.Id;
     pmc.Partner_Name__c = 'google' ;
     pmc.Client_ID__c = 'google';
     pmc.Name = 'google';
     insert pmc;
     
     PartnerClientMap__c PCMt = [select id, Partner_Name__c, Client_ID__c from PartnerClientMap__c where Partner_Name__c = 'google' Limit 1];
     
     
     Lab_order__c lb = new Lab_Order__c();
     lb.Partner_Client_Map__c = PCMt.id;
     lb.Client_Name__c = 'lb';
     lb.Name = 'lb';
     lb.Status__c = 'Registered';
     lb.Person_Record__c = person.Id;
            lb.Account__c=accnt.Id;
     insert lb;
     
     Lab_order__c lb1 = new Lab_Order__c();
     lb1.Partner_Client_Map__c = PCMt.id;
     lb1.Client_Name__c = 'lb1';
     lb1.Name = 'lb1';
     lb1.Status__c = 'Registered';
      lb1.Person_Record__c = person.Id;
            lb1.Account__c=accnt.Id;
     insert lb1;
     
     Panel_Test__c pt = new Panel_Test__c();
     pt.Panel__c = p.id;
     pt.Test__c = t.Id;
     insert pt;
     
     Lab_Order_Panel__c LOP = new Lab_Order_Panel__c();
     LOP.Lab_Order__c = lb.id;
     LOP.Panel__c = p.id;
     insert LOP;
     
     Lab_Order_Panel__c LOP1 = new Lab_Order_Panel__c();
     LOP1.Lab_Order__c = lb1.id;
     LOP1.Panel__c = p.id;
     insert LOP1;
     
     Lab_Panel_Test__c lbt = new Lab_Panel_Test__c();
     lbt.Lab_Order_Panel__c = LOP.id;
     lbt.Status__c = 'Registered';
     lbt.Panel_Test__c = pt.id;
     lbt.Lab_Order__c= lb.id;
     insert lbt;
     
     
     Lab_Panel_Test__c lbt1 = new Lab_Panel_Test__c();
     lbt1.Lab_Order_Panel__c = LOP1.id;
     lbt1.Status__c = 'In Progress';
     lbt1.Panel_Test__c = pt.id;
     
     insert lbt1;
        
               
       
        
    }
    
    @isTest
    static void testSaveOrder(){
         string jsonBody ='{'+
            '"externalOrderId" : "AxK1Cs190",'+
            '"clientName" : "google",'+
            '"locationId" : "questLocation",'+
            '"paymentTransactionId": "not a required field",'+
            '"sh_app_secret": "11Zaes",'+
            '"appointmentCode": "11Zaes",'+
            '"customer": {'+
            '"firstName" : "fName",'+
             '"middleName" : "mName",'+
            '"lastName" : "lNe",'+
            '"dateOfBirth" : "1985-09-09",'+
            '"gender" : "Male",'+
            '"email" : "fir@gmail.com",'+
            '"phone": "4567890422",'+
            '"externalCustomerId": "11Zaes"'+
            '},'+
            '"address": {'+
            '"addressLine1" : "address1",'+
             '"addressLine2" : "address1",'+
            '"zip" : "15801",'+
            '"city" : "San Francisco",'+
            '"state" : "PA",'+
            '"country" : "US"'+
            '},'+
            '"orderSummaries": {'+
            '"orderItems" : [{'+
            '"testCode" : "7788",'+
            '"quantity" : 1,'+
            '"finalPrice" : "10.00"'+
            '		}]'+
            '	}'+
            '}';
        
        Test.startTest();
        system.debug(blob.valueOf(jsonBody));
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI  ='/services/apexrest/order/*';
        req.requestBody = blob.valueOf(jsonBody);
        req.httpMethod = 'Post';
        RestContext.request = req;
        RestContext.response= res;
        PartnerLabOrderResource.createOrder();
        //System.assertEquals(res.statusCode, 200);
        Test.stopTest();
    }
    
    
    @isTest
    static void testSaveOrder_Failure(){
        string jsonBody ='{'+
            '"externalOrderId" : "AxK1Cs190",'+
            '"clientName" : "goole",'+
            '"locationId" : "questLocation",'+
            '"paymentTransactionId": "not a required field",'+
            '"customer": {'+
            '"firstName" : "fName",'+
            '"lastName" : "lName",'+
            '"dateOfBirth" : "1988-10-18",'+
            '"gender" : "Male",'+
            '"email" : "sgh@yfredtpmail.com",'+
            '"phone": "4567890422",'+
            '"externalCustomerId": "11Zaes"'+
            '},'+
            '"address": {'+
            '"addressLine1" : "address1",'+
            '"zip" : "15801",'+
            '"city" : "San Francisco",'+
            '"state" : "PA",'+
            '"country" : "US"'+
            '},'+
            '"orderSummaries": {'+
            '"orderItems" : [{'+
            '"testCode" : "12767",'+
            '"quantity" : 1,'+
            '"finalPrice" : "10.00 "'+
            '		}]'+
            '	}'+
            '}';
        
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI  ='/services/apexrest/order/*';
        req.requestBody = blob.valueOf(jsonBody);
        req.httpMethod = 'Patch';
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        PartnerLabOrderResource.createOrder();
        System.assertEquals(res.statusCode, 400);
        Test.stopTest();
    }
    
    // @isTest
    // static void testSaveOrder_Update(){
    //     //Account acc =   [select id, PersonEmail from Account where PersonEmail = 'first@gmail.com' limit 1];
    //     // Contact con =   [select id, AccountId  from Contact where Email =: acc.PersonEmail];
        
    //     Person_Record__c ps = new Person_Record__c();
    //     ps.First_Name__c 		= 'FirstName';
    //     ps.Last_Name__c 		= 'lName';
    //     ps.Phone__c 			= '4569990422';
    //     ps.Date_of_Birth__c 	=  Date.parse('09/09/1985');
    //     ps.Gender__c 			= 'Male';
    //     ps.Email__c 			= 'first@gmail.com';
    //     ps.Address_Line_1__c 	= 'address';
    //     ps.City__c 				= 'kingston';
    //     ps.State__c 			= 'Newyork';
    //     ps.Country__c 			= 'US';
    //     ps.Postal_Code__c 		= '12041';
    //     ps.Unique_Identifier__c = 'first@gmail.com:'+'09/09/1985:' +'lName';
    //     // ps.Contact__c = con.id;
    //     insert ps;
        
    //     string jsonBody ='{'+
    //         '"externalOrderId" : "AxK1Cs190",'+
    //         '"clientName" : "google",'+
    //         '"locationId" : "questLocation",'+
    //         '"paymentTransactionId": "not a required field",'+
    //         '"sh_app_secret": "11Zaes",'+
    //         '"customer": {'+
    //         '"firstName" : "fName",'+
    //         '"lastName" : "lName",'+
    //         '"dateOfBirth" : "09/09/1985",'+
    //         '"gender" : "Male",'+
    //         '"email" : "first@gmail.com",'+
    //         '"phone": "4567890422",'+
    //         '"externalCustomerId": "11Zaes"'+
    //         '},'+
    //         '"address": {'+
    //         '"addressLine1" : "address1",'+
    //         '"zip" : "15801",'+
    //         '"city" : "San Francisco",'+
    //         '"state" : "PA",'+
    //         '"country" : "US"'+
    //         '},'+
    //         '"orderSummaries": {'+
    //         '"orderItems" : [{'+
    //         '"testCode" : "12767",'+
    //         '"quantity" : 1,'+
    //         '"finalPrice" : "10.00 "'+
    //         '		}]'+
    //         '	}'+
    //         '}';
        
    //     Test.startTest();
    //     RestRequest req = new RestRequest();
    //     RestResponse res = new RestResponse();
    //     req.requestURI  ='/services/apexrest/order/*';
    //     req.requestBody = blob.valueOf(jsonBody);
    //     req.httpMethod = 'Patch';
    //     RestContext.request = req;
    //     RestContext.response= res;
    //     PartnerLabOrderResource.createOrder();
    //     System.assertEquals(res.statusCode, 200);
    //     Test.stopTest();
    // }
    
    @isTest
    static void testSaveOrderCancel(){
        System.Test.setMock(HttpCalloutMock.class, new SendOrderDetailsToPHMock());
     PartnerClientMap__c partnerClientMap =    [select id, name, Partner_Name__c from PartnerClientMap__c where Partner_Name__c = 'google' Limit 1];
        Product2 productt = new Product2();
        productt.pwnEligible__c =true;
        productt.IsActive = true;
        productt.StockKeepingUnit = '1706';
        productt.performingSite__c = 'PHP';
        productt.Description = 'Vitamin D';
        productt.resultingRequired__c = true;
        productt.Min_age__c = '18';
     	productt.Name= 'Vitamin D Test';
        productt.Excluded_State_codes__c = 'AK;AZ;HI';
        productt.Franchise_Category__c = 'IDI';
        insert  productt;
        
        
        
        Product_Partner_Map__c pp = new Product_Partner_Map__c();
        pp.Cancellation_Fee__c = 10.00;
        pp.Product_Price__c = 5000.00;
        pp.Product__c = productt.id;
        pp.Partner_ID__c = partnerClientMap.id;
        insert pp;
        
         Product_Partner_Map__c pp1 = new Product_Partner_Map__c();
        pp1.Cancellation_Fee__c = 10.00;
        pp1.Product_Price__c = 5000.00;
        pp1.Product__c = productt.id;
        pp1.Partner_ID__c = partnerClientMap.id;
        insert pp1;
 		List<Product_Partner_Map__c> lstPP = [select id,Cancellation_Fee__c,Product_Price__c,Product__c,Partner_ID__c, Name from Product_Partner_Map__c where Partner_ID__c =:partnerClientMap.id AND  Product__c =:productt.id];
        string jsonBody ='{'+'"cancelReason" : "Cancel - Payment Capture Failure"'+'}';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        Lab_order__c lb =   [select id, Name,Captured_Amount__c, Cancellation_Service_Fee__c,Refund_Amount__c, Status__c from Lab_order__c limit 1];
        lb.Status__c = 'Cancelled';
        lb.Refund_Amount__c= 50.00;
        update lb;
        req.requestURI  ='/services/apexrest/order/'+lb.Name;
        system.debug(req.requestURI);
        req.requestBody = blob.valueOf(jsonBody);
        req.httpMethod = 'Patch';
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        PartnerLabOrderResource.cancelOrder();
        //System.assertEquals(res.statusCode, 200);
        Test.stopTest();
    }    
    
    @isTest
    static void testSaveOrderCance2(){
         
       
        
        Lab_Panel_Test__c singleLPT = [select id,Status__c  from Lab_Panel_Test__c   Limit 1];
        singleLPT.Status__c = 'In Progress';
        update singleLPT;
        string jsonBody ='{'+'"cancelReason" : "Cancel - Payment Capture Failure"'+'}';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI  ='/services/apexrest/order/*';
        system.debug(req.requestURI);
        req.requestBody = blob.valueOf(jsonBody);
        req.httpMethod = 'Patch';
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        PartnerLabOrderResource.cancelOrder();
        //System.assertEquals(res.statusCode, 500);
        Test.stopTest();
    }

	public class SendOrderDetailsToPHMock implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req1){
            HttpResponse res1 = new HttpResponse();
            res1.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            if(req1.getEndPoint().contains('refunds')){
                res1.setBody('{"amount_received":10000.00}');
                res1.setStatusCode(400);
            }
            else{
                res1.setbody('{"amount_received":10000.00}');
                res1.setStatusCode(200);
            }
            return res1;
        }
    }
    
    public class SendOrderDetailsToPHMock1 implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req1){
            HttpResponse res1 = new HttpResponse();
            res1.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            if(req1.getEndPoint().contains('refunds')){
                res1.setBody('{"amount_received":10000.00}');
                res1.setStatusCode(200);
            }
            else{
                res1.setbody('{"amount_received":10000.00}');
                res1.setStatusCode(200);
            }
            return res1;
        }
    }    
}