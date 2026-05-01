/**
* @File Name : QuestionPortalHelper_Test.cls
* @Description :
* @Author :SingamReddy RamanaReddy
* @Last Modified On : March 8, 2025

**/
@isTest
public class QuestionPortalHelper_Test {
    
    
    
    @isTest
    static void testMethod1(){
        String res = '{"header":{"prismId":"548163","consentVersions":{"consentToProcessSampleVersion":"1.0","consentToBankVersion":"1.0","consentToResearchVersion":"1.0","researchHippaAuthVersion":null},"physician":{"id":6009}},"qAndAGroups":[{"groupId": "personalHistoryGeneticTestVariants","itemConfig": [{"sequence": 4,"questionId": "QUDE10030","questionKey": "variantPersonalHistory","responses": [{"value": "POLE","valueHtml": "<i>POLE</i>","key": "poleVariant","singleton": false,"disable": false}]}]},{"groupId":"consumerDemographics","itemConfig":[{"questionKey":"reasonForTesting","responses":[{"key":"interestedInHealth"}]}]},{"groupId":"consentToProcess","itemConfig":[{"sequence":1,"conditionToShowMe":null,"scrollWindow":[{"sequence":2,"questionId":"QUDE10014","questionKey":"consentToProcess","responses":[{"key":"yes"}]}],"responses":[]}]},{"groupId":"consentToBank","itemConfig":[{"sequence":1,"conditionToShowMe":null,"scrollWindow":[{"sequence":2,"questionId":"QUDE10015","questionKey":"consentToBank","responses":[{"value":"Igiveconsent","valueHtml":"Igiveconsent","key":"yes","singleton":true}]}],"responses":[]}]},{"conditionToAskMe":null,"sequence":5,"groupId":"consentToResearch","itemConfig":[{"sequence":1,"conditionToShowMe":null,"scrollWindow":[{"questionKey":"consentToResearch","responses":[{"key":"yes"}]}],"responses":[]}]},{"groupId":"personalHistoryCancer","itemConfig":[{"questionKey":"cancerPersonalHistory","responses":[{"value":"Brain","valueHtml":"Brain","key":"brainCancer","singleton":false,"followUps":[{"sequence":1,"questionId":"QUDE10020","questionKey":"cancerDiagnosisAge","responses":[30],"followUps":[]}]}]}]},{"conditionToAskMe":null,"sequence":7,"groupId":"personalHistoryCardio","itemConfig":[{"questionKey":"cardioPersonalHistory","responses":[{"value":"Stroke","valueHtml":"Stroke","key":"stroke","singleton":false,"followUps":[{"sequence":1,"questionId":"QUDE10023","questionKey":"heartIssueAge","responses":[30],"followUps":[]}]},{"value":"Aneurysm","valueHtml":"Aneurysm","key":"aneurysm","singleton":false,"followUps":[{"sequence":1,"questionId":"QUDE10023","questionKey":"heartIssueAge","responses":[31],"followUps":[]}]},{"value":"Heartattack","valueHtml":"Heartattack","key":"heartAttack","singleton":false,"followUps":[{"sequence":1,"questionId":"QUDE10023","questionKey":"heartIssueAge","responses":[32],"followUps":[]}]},{"value":"Exercise-relatedfainting","valueHtml":"Exercise-relatedfainting","key":"exerciseRelatedFainting","singleton":false,"followUps":[{"sequence":1,"questionId":"QUDE10023","questionKey":"heartIssueAge","responses":[33],"followUps":[]}]},{"value":"Haveapacemakerordefibrillator(ICD)","valueHtml":"Haveapacemakerordefibrillator(ICD)","key":"pacemakerOrDefibrillator","singleton":false,"followUps":[{"sequence":1,"questionId":"QUDE10023","questionKey":"heartIssueAge","responses":[34],"followUps":[]}]},{"value":"Irregularheartbeat","valueHtml":"Irregularheartbeat","key":"irregularHeartbeat","singleton":false,"followUps":[{"sequence":1,"questionId":"QUDE10023","questionKey":"heartIssueAge","responses":[35],"followUps":[]}]},{"value":"Enlargedheart(cardiomegaly)","valueHtml":"Enlargedheart(cardiomegaly)","key":"enlargedHeart","singleton":false,"followUps":[{"sequence":1,"questionId":"QUDE10023","questionKey":"heartIssueAge","responses":[36],"followUps":[]}]},{"value":"Heartfailureorhearttransplant","valueHtml":"Heartfailureorhearttransplant","key":"heartFailureOrTransplant","singleton":false,"followUps":[{"sequence":1,"questionId":"QUDE10023","questionKey":"heartIssueAge","responses":[37],"followUps":[]}]}]}]},{"groupId":"personalHistoryGeneticConditions","itemConfig":[{"questionKey":"geneticConditionPersonalHistory","responses":[{"value":"Cysticfibrosis","valueHtml":"Cysticfibrosis","key":"cysticFibrosis","singleton":false,"disable":false}]}]},{"groupId":"familyHistoryCancer","itemConfig":[{"questionKey":"cancerFamilyHistory","responses":[{"value":"Breastcancer","valueHtml":"Breastcancer","key":"breastCancer","singleton":false,"followUps":[{"sequence":1,"questionId":"QUDE10032","questionKey":"fhCancerRelative","value":"Parent","valueHtml":"Parent","key":"parent","relationship":"PRN","singleton":false,"followUps":[{"sequence":1,"questionId":"QUDE10033","questionKey":"fhCancerRelativeDecade","value":"0-9","valueHtml":"0-9","key":"0-9"}]}]},{"value":"Coloncancer","valueHtml":"Coloncancer","key":"colonCancer","singleton":false,"followUps":[{"sequence":1,"questionId":"QUDE10032","questionKey":"fhCancerRelative","value":"Parent","valueHtml":"Parent","key":"parent","relationship":"PRN","singleton":false,"followUps":[{"sequence":1,"questionId":"QUDE10033","questionKey":"fhCancerRelativeDecade","value":"0-9","valueHtml":"0-9","key":"0-9"}]}]}]}]},{"groupId":"familyHistoryCardio","itemConfig":[{"questionKey":"cardioFamilyHistory","responses":[{"value":"Haveapacemakerordefibrillator(ICD)","valueHtml":"Haveapacemakerordefibrillator(ICD)","key":"pacemakerOrDefibrillator","singleton":false,"followUps":[{"sequence":1,"questionId":"QUDE10035","questionKey":"deviceImplanted50","key":"true","value":"Yes","valueHtml":"Yes","followUps":[]}]}]}]},{"groupId":"familyHistoryGeneticConditions","itemConfig":[{"questionKey":"geneticConditionFamilyHistory","responses":[{"value":"Cysticfibrosis","valueHtml":"Cysticfibrosis","key":"cysticFibrosis","singleton":false,"disable":false}]}]}]}';
        
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeStringField('json_questions_response_payload',res);
        gen.writeEndObject();
        gen.writeEndArray();
        gen.getAsString();
        
        
        Kit_Details__c kit = new Kit_Details__c(Activation_Code__c='KITREF1234', Item_Code__c='334', ActivationUser_PRS_ID__c = '123456', Lab_Status__c = 'Kit Activated');
        insert kit;
        List<Kit_Details__c> ordItem = [select id, Activation_Code__c, ActivationUser_PRS_ID__c, Lab_Status__c from Kit_Details__c  where id = :kit.id AND ActivationUser_PRS_ID__c != null AND Activation_Code__c != null AND Lab_Status__c = 'Kit Activated'];
        QuestionPortalHelper.InputPrameters flowInputs = new QuestionPortalHelper.InputPrameters();
        flowInputs.kitLabId = ordItem[0].Id  ;
        List<QuestionPortalHelper.InputPrameters> flowInputsForTest = new List<QuestionPortalHelper.InputPrameters>();
        flowInputsForTest.add(flowInputs);
        Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, new MockQPHelperHttpResponse(200, gen.getAsString()));
        QuestionPortalHelper.fetchQuestionPortalDetails(flowInputsForTest);
        
        Test.stopTest();
    }
    
    private class MockQPHelperHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public MockQPHelperHttpResponse(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
}