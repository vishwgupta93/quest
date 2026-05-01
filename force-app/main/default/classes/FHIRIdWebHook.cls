@RestResource(urlMapping='/FHIR/*')
global with sharing class FHIRIdWebHook {
    @HttpPost
    global static void insertRecord(){ 
        String jsonInput = RestContext.request.requestBody.toString();

        Map<String,Object> jsonRequest = (Map<String, Object>)JSON.deserializeUntyped(jsonInput);
        List<Object> lst = (List<Object>)jsonRequest.get('identifier');
        Map <String, String> output = new Map<String, String>();
        for(Object fld : lst){
            Map<String,Object> data = (Map<String,Object>)fld;
            try{
                if(data.get('system').toString() != null && data.get('system').toString() == 'https://www.questdiagnostics.com'){
                    output.put('fhirID', data.get('value').toString());
                    break;
                }
            }catch(System.NullPointerException e){

            }
        }

        for(Object fld : lst){
            Map<String,Object> data = (Map<String,Object>)fld;
            try{
                Map<String, Object> type = (Map<String,Object>)data.get('type');
                if(type.get('text') == 'Placer'){
                    output.put('labRefId', data.get('value').toString());
                }
            }catch(System.NullPointerException e){
            }   
        }

        String orderNumber = ValidateFHIRInput.orderNumber(output.get('labRefId'));
        RestContext.response.addHeader('Content-Type', 'application/fhir+json');
        RestResponse response = RestContext.response;
        
        if(orderNumber != ''){
            Health_Gorilla_FHIR__e event = new Health_Gorilla_FHIR__e(
                FHIR_ID__c = output.get('fhirID'), 
                LabRef_ID__c = output.get('labRefId'),
                OrderNumber__c= orderNumber
            );
            Database.SaveResult sr = EventBus.publish(event);
            response.statusCode = 200;
        } else {
            JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                // "resourceType" field
                gen.writeStringField('resourceType', 'OperationOutcome');

                // "id" field
                gen.writeStringField('id', 'exception');

                // "text" field
                gen.writeFieldName('text');
                gen.writeStartObject();
                gen.writeStringField('status', 'generated');
                gen.writeStringField('div', '<div xmlns=\"http://www.w3.org/1999/xhtml\">\n      <p>SQL Link Communication Error (dbx = 34234)</p>\n    </div>');
                gen.writeEndObject();

                // "issue" field
                gen.writeFieldName('issue');
                gen.writeStartArray();
                gen.writeStartObject();
                gen.writeStringField('severity', 'error');
                gen.writeStringField('code', 'exception');
                // "details" field within "issue"
                gen.writeFieldName('details');
                gen.writeStartObject();
                gen.writeStringField('text', 'SQL Link Communication Error (dbx = 34234)');
                gen.writeEndObject();
                gen.writeEndObject();
                gen.writeEndArray();
                gen.writeEndObject();
                String jsonString = gen.getAsString();
                
                response.responseBody = Blob.valueOf(gen.getAsString());
           
        }
        
    }

    @HttpGet
    global static void getRecord(){
        JSONGenerator gen = JSON.createGenerator(true);
        
        String orderNo = RestContext.request.params.get('orderNumber');
        String FHIRId = ValidateFHIRInput.getFHIRId(orderNo);

        if(FHIRId == null){
            orderNo = 'Not found';
            FHIRId = 'Not found';
        }
        gen.writeStartObject();
            gen.writeStringField('orderNumber', orderNo);
            gen.writeStringField('FHIRId', FHIRId);
        gen.writeEndObject();
        RestContext.response.responseBody = Blob.valueOf(gen.getAsString());
    }

}