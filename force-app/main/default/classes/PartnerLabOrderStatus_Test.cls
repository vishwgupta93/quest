@isTest
public class PartnerLabOrderStatus_Test {
 @testSetup
 static void prepareTestData(){
     Panel__c p = new Panel__c();
     p.Panel_Code__c = '12767';
     p.Panel_Name__c = 'test panel';
     insert p;
     
     Test__c t = new Test__c();
     t.Test_Code__c = '12767';
     t.Test_Name__c = 'demo test';
     insert t;
     
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
     insert lb;
     
     Lab_order__c lb1 = new Lab_Order__c();
     lb1.Partner_Client_Map__c = PCMt.id;
     lb1.Client_Name__c = 'lb1';
     lb1.Name = 'lb1';
     lb1.Status__c = 'Registered';
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
    static void testStatus(){
       List<String> lstLabOrderNumber = new List<String>();
        String laborderName = '';
    	List<Lab_order__c> labOrderLst =   [select id, Name from Lab_order__c];
        
        for(Lab_order__c eachLabOrder : labOrderLst){
         laborderName += '"'+eachLabOrder.Name+'"' + ',';
        }
        
        String str = '[' +laborderName.removeEnd(',')+ ']';
       
        string jsonBody ='{"orderId":'+ str+'}';
        system.debug(jsonBody);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI  ='/services/apexrest/order/*';
        system.debug(req.requestURI);
        req.requestBody = blob.valueOf(jsonBody);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        PartnerLabOrderStatus.getOrderStatusAPI();
        System.assertEquals(res.statusCode, 200);
        Test.stopTest();
    }    
    
    
}