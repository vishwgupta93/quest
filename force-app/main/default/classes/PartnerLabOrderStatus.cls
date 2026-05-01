@RestResource(urlmapping = '/status')
global with sharing class PartnerLabOrderStatus{
    
    @httpPost
    global static void getOrderStatusAPI(){
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
       
        List<String> labOrderNumber = new  List<String>();
        
        
        Map<String, Object> params 	= (Map<String, Object>)System.JSON.deserializeUntyped(RestContext.request.requestBody.toString());
        List<Object> obj = (List<Object>)params.get('orderId');
        List<String> lstStr = new List<String>();
        for(Object obj1 : obj){
            String str = (String)obj1;
            lstStr.add(str);
            system.debug(lstStr);
        }
            List<Lab_Order__c> lstlabOrder = [
            SELECT Id, CreatedDate, Name
            FROM Lab_Order__c
            WHERE Name IN :lstStr OR External_Partner_Order_Id__c IN :lstStr
        ];

        Set<Id> labOrderIds = new Set<Id>();
        for (Lab_Order__c lo : lstlabOrder) {
            labOrderIds.add(lo.Id);
        }

        Map<Id, List<Lab_Panel_Test__c>> labOrderToPanelTestsMap = new Map<Id, List<Lab_Panel_Test__c>>();
        for (Lab_Panel_Test__c test : [
            SELECT Id, Status__c, Test_Code__c, Lab_Order__c
            FROM Lab_Panel_Test__c
            WHERE Lab_Order__c IN :labOrderIds
        ]) {
            if (!labOrderToPanelTestsMap.containsKey(test.Lab_Order__c)) {
                labOrderToPanelTestsMap.put(test.Lab_Order__c, new List<Lab_Panel_Test__c>());
            }
            labOrderToPanelTestsMap.get(test.Lab_Order__c).add(test);
        }

        List<Map<String, Object>> responseList = new List<Map<String, Object>>();

        for (Lab_Order__c order : lstlabOrder) {
            Map<String, Object> orderMap = new Map<String, Object>();
            orderMap.put('orderNumber', order.Name);
            orderMap.put('orderDate', String.valueOf(order.CreatedDate.date())); 

            List<Map<String, Object>> detailsList = new List<Map<String, Object>>();
            List<Lab_Panel_Test__c> panelTests = labOrderToPanelTestsMap.get(order.Id);

            if (panelTests != null) {
                for (Lab_Panel_Test__c test : panelTests) {
                    Map<String, Object> testMap = new Map<String, Object>();
                    testMap.put('product', test.Test_Code__c);
                    testMap.put('status', test.Status__c);
                    detailsList.add(testMap);
                }
            }

            orderMap.put('details', detailsList);
            responseList.add(orderMap);
        }

        String finalJson = JSON.serialize(responseList);

           
                res.statusCode = 200;
                res.responseBody = Blob.valueOf(finalJson);
            
        System.debug(' Final JSON :' + finalJson);
    }
}