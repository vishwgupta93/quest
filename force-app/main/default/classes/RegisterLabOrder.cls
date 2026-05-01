public without sharing class RegisterLabOrder {
    public class InputParameters {
        @InvocableVariable(label='Tester ID' description='Tester ID')
        public String testerId;
        @InvocableVariable(label='Lab Order Id' description='Lab Order Id')
        public String labOrderId;
    }

    public class OutputParameters {

        @InvocableVariable(label='Lab Order Number' description='Lab Order Number')
        public String labOrderNumber;

        @InvocableVariable(label='Lab Order Id' description='Lab Order Id')
        public String labOrderId;
    }

    @InvocableMethod(label='Register Lab Order' description='Invokes the creation/register of Lab Order')
    public static List<OutputParameters> registerLabOrder(List<InputParameters> inputs)
    {
        List<OutputParameters> outputs = new List<OutputParameters>();

        for(InputParameters serviceInput : inputs)
        {
            OutputParameters output = new OutputParameters();
            outputs.add(output);

            String testerId = serviceInput.testerId;

            

                Tester_Detail__c testerDetails = [select Id, Fulfillment_Order_Item_Id__c,Product_Codes__c,Is_Commerce_Flow__c from Tester_Detail__c where Id =:testerId];
                String productCodes = testerDetails.Product_Codes__c;
                String foLineIds = testerDetails.Fulfillment_Order_Item_Id__c; 
                Boolean isCommerceFlow = testerDetails.Is_Commerce_Flow__c;

                Set<String> productCodeSet = new Set<String>();
                Set<String> foLineIdSet = new Set<String>();

                System.debug(
                    'registerLabOrder: productCodes: ' + productCodes + ' foLineIds: ' + foLineIds + ' isCommerceFlow: '+isCommerceFlow);
                    if (!String.isBlank(productCodes)) {
                        for (String code : productCodes.split(',')) {
                            if (!String.isBlank(code)) {
                                productCodeSet.add(code.trim());
                            }
                        }
                    }
                    
                    if (!String.isBlank(foLineIds)) {
                        for (String id : foLineIds.split(',')) {
                            if (!String.isBlank(id)) {
                                foLineIdSet.add(id.trim());
                            }
                        }
                    }
                    

                System.debug(
                    'registerLabOrder: productCodes: ' + productCodeSet + ' foLineIds: ' + foLineIdSet + ' isCommerceFlow: '+isCommerceFlow);

                if(isCommerceFlow)
                {
                    // Normalize product codes to uppercase for consistent matching
                    Set<String> normalizedProductCodeSet = new Set<String>();
                    for (String code : productCodeSet) {
                        if (String.isNotBlank(code)) {
                            normalizedProductCodeSet.add(code.toUpperCase());
                        }
                    }
                    
                    List<Panel_Test__c> panels = new List<Panel_Test__c>([select Id,Panel__c,Check_For_Results__c,Panel__r.Panel_Code__c from Panel_Test__c where Panel__r.Panel_Code__c IN: normalizedProductCodeSet]);

                   List<Tester_Details_AOE__c> aoes = [
                        SELECT Id, Product_Code__c, Tester_Detail_Id__c, Product_AOE__c, Product_AOE_Option__c
                        FROM Tester_Details_AOE__c
                        WHERE (Product_Code__c IN :normalizedProductCodeSet OR Product_Code__c IN :productCodeSet) AND Tester_Detail_Id__c = :testerId
                    ];

                    Map<String, List<Tester_Details_AOE__c>> aoeMap = new Map<String, List<Tester_Details_AOE__c>>();

                    for (Tester_Details_AOE__c aoe : aoes) {
                        String productCode = aoe.Product_Code__c;
                        if (String.isNotBlank(productCode)) {
                            // Normalize to uppercase for consistent matching
                            String normalizedCode = productCode.toUpperCase();
                            if (!aoeMap.containsKey(normalizedCode)) {
                                aoeMap.put(normalizedCode, new List<Tester_Details_AOE__c>());
                            }
                            aoeMap.get(normalizedCode).add(aoe);
                        }
                    }
                    System.debug(
                        'panels: panels: ' + panels + ' aoeMap : ' + aoeMap + ' normalizedProductCodeSet: ' + normalizedProductCodeSet);
                    
                    if (panels.isEmpty()) {
                        System.debug('WARNING: No panels found for product codes: ' + normalizedProductCodeSet + ' (original: ' + productCodeSet + ')');
                    }
                    
                    persistLabOrderPanelAndTest(serviceInput.labOrderId, panels, aoeMap, null, normalizedProductCodeSet, isCommerceFlow);
                }
                else {
                    List<FulfillmentOrderLineItem> foLines = [select Id,ProductCode__c,OrderItemSummary.HRAReq__c from FulfillmentOrderLineItem where Id in: foLineIdSet];
                    Map<String, FulfillmentOrderLineItem> foLineMap = new Map<String, FulfillmentOrderLineItem>();
                    Set<String> testCodes = new Set<String>();
                    for(FulfillmentOrderLineItem foLine : foLines){
                        if(foLine.ProductCode__c != null){
                            testCodes.add(foLine.ProductCode__c);
                            foLineMap.put(foLine.ProductCode__c,foLine);
                        }
                    }
                    
                    // Normalize test codes to uppercase for consistent matching
                    Set<String> normalizedTestCodes = new Set<String>();
                    for (String code : testCodes) {
                        if (String.isNotBlank(code)) {
                            normalizedTestCodes.add(code.toUpperCase());
                        }
                    }
                    
                    List<Panel_Test__c> panels = new List<Panel_Test__c>([select Id,Check_For_Results__c,Panel__c,Panel__r.Panel_Code__c from Panel_Test__c where Panel__r.Panel_Code__c IN: normalizedTestCodes OR Panel__r.Panel_Code__c IN: testCodes]);
                    
                    List<Tester_Details_AOE__c> aoes = [
                        SELECT Id, Product_Code__c, Tester_Detail_Id__c, Product_AOE__c, Product_AOE_Option__c
                        FROM Tester_Details_AOE__c
                        WHERE (Product_Code__c IN :normalizedTestCodes OR Product_Code__c IN :testCodes) AND Tester_Detail_Id__c = :testerId
                    ];

                    Map<String, List<Tester_Details_AOE__c>> aoeMap = new Map<String, List<Tester_Details_AOE__c>>();

                    for (Tester_Details_AOE__c aoe : aoes) {
                        String productCode = aoe.Product_Code__c;
                        if (String.isNotBlank(productCode)) {
                            // Normalize to uppercase for consistent matching
                            String normalizedCode = productCode.toUpperCase();
                            if (!aoeMap.containsKey(normalizedCode)) {
                                aoeMap.put(normalizedCode, new List<Tester_Details_AOE__c>());
                            }
                            aoeMap.get(normalizedCode).add(aoe);
                        }
                    }

                    System.debug(
                        'panels: panels: ' + panels + ' aoeMap : ' + aoeMap + ' normalizedTestCodes: ' + normalizedTestCodes);

                    if (panels.isEmpty()) {
                        System.debug('WARNING: No panels found for test codes: ' + normalizedTestCodes + ' (original: ' + testCodes + ')');
                    }
                    
                    persistLabOrderPanelAndTest(serviceInput.labOrderId, panels , aoeMap, foLineMap, normalizedTestCodes, isCommerceFlow);
                }
                }
//Logger.saveLog();
                return outputs;
       }
    

    private static void persistLabOrderPanelAndTest(String labOrderId, List<Panel_Test__c> panels,Map<String, List<Tester_Details_AOE__c>> aoeMap, Map<String, FulfillmentOrderLineItem> foLineMap, Set<String> normalizedProductCodes, boolean isCommerceFlow)
    {
        System.debug(
                    'registerLabOrder: panels: ' + panels + ' labOrderId: ' + labOrderId + ' normalizedProductCodes: ' + normalizedProductCodes);

        if (panels == null || panels.isEmpty()) {
            System.debug('ERROR: Cannot create Lab Order Panels - panels list is empty for labOrderId: ' + labOrderId);
            return;
        }
        
        List<Lab_Order_Panel__c> lopsToInsert = new List<Lab_Order_Panel__c>();
        Map<String,String> panelAndPanelCodeMap = new Map<String,String>();
        
        for(Panel_Test__c panel: panels){
            Lab_Order_Panel__c lop = new Lab_Order_Panel__c();
            String productCode = panel.Panel__r.Panel_Code__c;
            lop.Lab_Order__c = labOrderId;
            lop.Panel__c = panel.Panel__c;
            lop.Status__c = 'Registered';
            
            if(!isCommerceFlow)
            {
                FulfillmentOrderLineItem foLine = foLineMap.get(productCode);
                lop.Fulfillment_Order_Product__c =foLine.Id;
                lop.HRA_Req__c=foLine.OrderItemSummary.HRAReq__c;
            }

            panelAndPanelCodeMap.put(panel.Panel__c, productCode);
            lopsToInsert.add(lop);
        }
        
        insert lopsToInsert;

        System.debug(
                    'registerLabOrder: panels: ' + panels + ' lopsToInsert: ' + lopsToInsert + ' aoeMap: ' + aoeMap + ' panelAndPanelCodeMap: ' + panelAndPanelCodeMap) ;

        Map<Id, Lab_Order_Panel__c> lop_Panel_Map = new Map<Id, Lab_Order_Panel__c>();
        List<Lab_Order_Panel_AOE__c> aoeRecordsToInsert = new List<Lab_Order_Panel_AOE__c>();


            for (Lab_Order_Panel__c eachLOP : lopsToInsert) {
                lop_Panel_Map.put(eachLOP.Panel__c, eachLOP);
                
                String code = panelAndPanelCodeMap.get(eachLOP.Panel__c);
                System.debug('Get Panel AOE: code: ' + code + ' eachLOP: ' + eachLOP);

                if (String.isNotBlank(code) && !aoeMap.isEmpty()) {
                    // Try both normalized (uppercase) and original code for matching
                    String normalizedCode = code.toUpperCase();
                    List<Tester_Details_AOE__c> aoesForCode = aoeMap.get(normalizedCode);
                    if (aoesForCode == null) {
                        aoesForCode = aoeMap.get(code);
                    }
                    
                    if (aoesForCode != null && !aoesForCode.isEmpty()) {
                        for (Tester_Details_AOE__c aoe : aoesForCode) {
                            System.debug('Form Lab Panel AOE: code: ' + code + ' aoe: ' + aoe);
                            
                            Lab_Order_Panel_AOE__c panelAOE = new Lab_Order_Panel_AOE__c();
                            panelAOE.Lab_Order_Panel__c = eachLOP.Id;
                            panelAOE.Product_AOE__c = aoe.Product_AOE__c;
                            panelAOE.Product_AOE_Option__c = aoe.Product_AOE_Option__c;
                            aoeRecordsToInsert.add(panelAOE);
                        }
                    }
                }
            }


        System.debug(
                     ' aoeRecordsToInsert: ' + aoeRecordsToInsert);

        if(!aoeRecordsToInsert.isEmpty())
        {
            insert aoeRecordsToInsert;
        }

       

        System.debug(
                    'registerLabOrder: panels: ' + panels + ' lop_Panel_Map: ' + lop_Panel_Map  );
        
        List<Lab_Panel_Test__c> lptToInsert = new List<Lab_Panel_Test__c>();
        
        for(Panel_Test__c eachPanelTest : panels){
            Lab_Order_Panel__c lop = lop_Panel_Map.get(eachPanelTest.Panel__c);
            if (lop != null) {
                Lab_Panel_Test__c lopt = new Lab_Panel_Test__c();
                lopt.Lab_Order__c = labOrderId;
                lopt.Status__c = 'Registered';
                lopt.Lab_Order_Panel__c = lop.Id;
                lopt.Panel_Test__c = eachPanelTest.id;
                lopt.Check_for_Results__c=eachPanelTest.Check_For_Results__c;
                lptToInsert.add(lopt);
            } else {
                System.debug('Warning: No Lab_Order_Panel__c found for Panel__c: ' + eachPanelTest.Panel__c);
            }
        }
        
        System.debug(
                    'registerLabOrder: panels: ' + panels + ' lptToInsert: ' + lptToInsert );

                    //Logger.saveLog();
        insert lptToInsert;
    }
}