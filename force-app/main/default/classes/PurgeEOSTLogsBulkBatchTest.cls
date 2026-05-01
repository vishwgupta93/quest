@isTest
public class PurgeEOSTLogsBulkBatchTest {

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
        Test.setCreatedDate(t.Id, Date.today().addDays(-100));
       
        
        SalesChannel sc = new SalesChannel();
        sc.SalesChannelName = 'test';
        insert sc;
        Test.setCreatedDate(sc.Id, Date.today().addDays(-100));
        SalesChannel sch =   [select id, SalesChannelName from SalesChannel where SalesChannelName = 'test' Limit 1];
        
        
        PartnerClientMap__c pmc = new PartnerClientMap__c();
        pmc.Sales_Channel__c = sch.Id;
        pmc.Partner_Name__c = 'google' ;
        pmc.Client_ID__c = 'google';
        pmc.Name = 'google';
        insert pmc;
        
        Test.setCreatedDate(pmc.Id, Date.today().addDays(-100));
        PartnerClientMap__c PCMt = [select id, Partner_Name__c, Client_ID__c from PartnerClientMap__c where Partner_Name__c = 'google' Limit 1];
        
        
        
        Lab_order__c lb = new Lab_Order__c();
        lb.Partner_Client_Map__c = PCMt.id;
        lb.Client_Name__c = 'clientName';
        lb.Name = 'clientName';
        lb.Status__c = 'Results Ready';
        insert lb;
        
        Test.setCreatedDate(lb.Id, Date.today().addDays(-100));
        EOST_OMS_Log__c el1 = new EOST_OMS_Log__c(EOST_Payload__c = 'Response_Payload__c',  Lab_Order__c = lb.Id, Batch_Id__c = '1234567', Batch_Status__c = 'Processed');
        insert el1;
        Test.setCreatedDate(el1.Id, Date.today().addDays(-100));
       
        
         
        Panel_Test__c pt = new Panel_Test__c();
        pt.Panel__c = p.id;
        pt.Test__c = t.Id;
        insert pt;
        Test.setCreatedDate(pt.Id, Date.today().addDays(-100));
        
        
        Lab_Order_Panel__c LOP = new Lab_Order_Panel__c();
        LOP.Lab_Order__c = lb.id;
        LOP.Panel__c = p.id;
        insert LOP;
        Test.setCreatedDate(LOP.Id, Date.today().addDays(-100));
        
        Lab_Panel_Test__c lbt = new Lab_Panel_Test__c();
        lbt.Lab_Order_Panel__c = LOP.id;
        lbt.Status__c = 'Results Ready';
        lbt.Panel_Test__c = pt.id;
        insert lbt;
        Test.setCreatedDate(lbt.Id, Date.today().addDays(-100));
    }
    
    
     @isTest
    public static void testMethod1(){
       
        List<EOST_OMS_Log__c> lst =   [select id,Name,LastModifiedDate,CreatedDate from EOST_OMS_Log__c  limit 1];
        Test.startTest();
        Id jobid= Database.executeBatch(new PurgeEOSTLogsBulkBatch());
        Test.stopTest();
    }
    
    @isTest
    public static void testMethod2(){
       
        List<EOST_OMS_Log__c> lst =   [select id,Name,LastModifiedDate,CreatedDate from EOST_OMS_Log__c  limit 1];
        Test.startTest();
        PurgeEOSTLogsBulkBatch.run();
        Test.stopTest();
    }
    
}