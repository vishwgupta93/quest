@IsTest
public class DynamicAOEComponentHelperTest {
/*------------------------
 * Test Data Setup
 * -----------------------*/
    
 @testSetup
    static void setupData(){
        //Product2
        Product2 prod = new Product2(
        Name= 'Test Product',
            ProductCode = 'PROD-001',
            IsActive =true
        );
      insert prod;
        
        //Product_AOE__c (Question container)
        Product_AOE__c aoe = new Product_AOE__c(
        Product__c= prod.Id,
            Question__c='Is this supported?',
            Option_Type__c= 'SYSTEM',
            Expected_Answer__c='YES',
            Error_Message__c='Invalid',
            Link_URL__c='http://test.com',
            Question_Code__c='123',
            Type__c= '	AOE'
        );
        insert aoe;
        
        //Options
        Product_AOE_Option__c opt1= new Product_AOE_Option__c(
        Product_AOE__c = aoe.Id,
            Display_Name__c= 'Yes',
            Option_Code__c= 'YES'
        );
        
		Product_AOE_Option__c opt2= new Product_AOE_Option__c(
        Product_AOE__c = aoe.Id,
            Display_Name__c= 'No',
            Option_Code__c= 'NO'
        ); 
        
        insert new List<Product_AOE_Option__c>{opt1, opt2};
            
            //Existing Tester Details (to test delete logic)
            Tester_Details_AOE__c existing= new Tester_Details_AOE__c(
            Product_AOE__c=aoe.Id,
                Product_AOE_Option__c= opt1.Id,
              
                Product_Code__c= 'OLD'
            );
        insert existing;
        
    }
    
    /*----------------------------------------
     * Insert TesterAOERecords - single & multi select
     * ----------------------------------*/
    @IsTest
    static void testInsertTesterAoeRecords(){
        
        Product_AOE__c aoe= [SELECT Id, Product__c FROM Product_AOE__c LIMIT 1];
        
        Product_AOE_Option__c opt= [SELECT Id FROM Product_AOE_Option__c LIMIT 1];
        
        //Questions JSON
        List<Map<String, Object>> questions = new List<Map<String, Object>>();
        questions.add(new Map<String, Object>{
            'Id'=> aoe.Id,
                'Option_Type__c'=>'MULTISELECT',
                'Product__r'=> new Map<String, Object>{
                    'ProductCode'=>'PROD-001'
                }
        });
        
        // Options JSON
        List<Map<String, Object>> options = new List<Map<String, Object>>();
        options.add(new Map<String, Object> {
            'Id'=> opt.Id,
                'Option_Code__c'=>'YES'
        });
        
        //Responses JSON (multiselect)
        Map<String, Object> responses = new Map<String, Object>{
            aoe.Id=> new List<Object>{opt.Id}
        };
            
            Test.startTest();
        Map<String, String> result=
            DynamicAOEComponentHelper.insertTesterAoeRecords(
            JSON.serialize(questions),
                JSON.serialize(options),
                JSON.serialize(responses),
                null,
                new List<Id>{aoe.Id}
            );
        Test.stopTest();
        
        System.assertEquals(
        1,
            result.size(),
            'Product code map should be returned'
        );
        
        System.assertEquals(
        'PROD-001', 
            result.get(aoe.Id),
            'Correct product code should be returned'
        );
        
        
    }
    
    
    @IsTest
    static void testInsertTesterAoeRecords1(){
        
        Product_AOE__c aoe= [SELECT Id, Product__c FROM Product_AOE__c LIMIT 1];
        
        Product_AOE_Option__c opt= [SELECT Id FROM Product_AOE_Option__c LIMIT 1];
        
        //Questions JSON
        List<Map<String, Object>> questions = new List<Map<String, Object>>();
        questions.add(new Map<String, Object>{
            'Id'=> aoe.Id,
                'Option_Type__c'=>'MULTISELECT'
                
        });
        
        // Options JSON
        List<Map<String, Object>> options = new List<Map<String, Object>>();
        options.add(new Map<String, Object> {
            'Id'=> opt.Id,
                'Option_Code__c'=>'YES'
        });
        
        //Responses JSON (multiselect)
        Map<String, Object> responses = new Map<String, Object>{
            aoe.Id=> new List<Object>{opt.Id}
        };
            
            Test.startTest();
        Map<String, String> result=
            DynamicAOEComponentHelper.insertTesterAoeRecords(
            JSON.serialize(questions),
                JSON.serialize(options),
                JSON.serialize(responses),
                null,
                new List<Id>{aoe.Id}
            );
        Test.stopTest();
        
        System.assertEquals(
        1,
            result.size(),
            'Product code map should be returned'
        );
        
       
        
        
    }
    
    
    /*----------------------------------------
     * getProductCodes
     * ---------------------------------------*/
    
    @IsTest
    static void testGetProductCodes(){
        Product_AOE__c aoe = [SELECT Id FROM Product_AOE__c LIMIT 1];
        
        Test.startTest();
        Map<Id, String> result=
            DynamicAOEComponentHelper.getProductCodes(
                new List<Id>{aoe.Id}
            );
        Test.stopTest();
        
        System.assertEquals(1, result.size());
        System.assertEquals('PROD-001',result.get(aoe.Id));
    }
    
    /*----------------------------------------
     * getAOEQuestionsAndOptions
     * ---------------------------------*/
    @IsTest
    static void testGetAoeQuestionsAndOptions(){
        
        Test.startTest();
        Map<String, String> result = 
            DynamicAOEComponentHelper.getAoeQuestionsAndOptions(
            'PROD-001'
            );
        Test.stopTest();
        
        System.assert(result.containsKey('questions'));
        System.assert(result.containsKey('options'));
        
        
    }
    
    /*-------------------------------------
     * Negative / Edge Case Coverage
     * -----------------------------------*/
    
    @isTest
    static void testEmptyInputsDoNotFail(){
        
        Test.startTest();
        Map<String, String> result = 
            DynamicAOEComponentHelper.insertTesterAoeRecords(
            JSON.serialize(new List<Object>()),
              JSON.serialize(new List<Object>()),
                JSON.serialize(new Map<String, Object>()),
                null,
                new List<Id>()
            );
        Test.stopTest();
        
        System.assertEquals(0, result.size());
    }
    
    
}