@RestResource(urlMapping='/results/*')
global with sharing class ResultResourceHelper {
    @HttpPost
     @RestResource(urlMapping='/fetch/*')
     global static String getResults(RequestData requestData)
     {
        String jsonPayload = '';
        String customerId = requestData.customerId;
        String startDateStr = requestData.startDate;
        String endDateStr = requestData.endDate;

        Date startDate = (startDateStr != null) ? Date.valueOf(startDateStr) : null;
        Date endDate = (endDateStr != null) ? Date.valueOf(endDateStr) : null;


       
        String query = 'SELECT Id, Accession_ID__c, Client_ID__c, Customer_ID__c, Date_of_Collection__c, Date_Reported__c, Performing_Site__c, Test_Code__c, Test_Name__c FROM Result__c WHERE Customer_ID__c = :customerId and Is_Service__c = false';


        if (startDate != null) {
            query += ' AND Date_Reported__c >= :startDate';
        }

        if (endDate != null) {
            query += ' AND Date_Reported__c <= :endDate';
        }

        List<Result__c> results = Database.query(query);
        // Generate the payload using JSONGenerator
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeFieldName('results');
        gen.writeStartArray();

        if(!results.isEmpty())
        {
            
            Map<String, List<String>> accessionIdToTestNames = new Map<String, List<String>>();
            Map<String, List<String>> accessionIdToTestCodes = new Map<String, List<String>>();


            for (Result__c result : results) 
            {   
                String accessionId = result.Accession_ID__c;
                String testName = result.Test_Name__c;
                String testCode = result.Test_Code__c;

                // Populate test names map
                if (!accessionIdToTestNames.containsKey(accessionId)) 
                {
                    accessionIdToTestNames.put(accessionId, new List<String>{testName});
                } 
                else 
                {
                    accessionIdToTestNames.get(accessionId).add(testName);
                }

                        // Populate test codes map
                if (!accessionIdToTestCodes.containsKey(accessionId)) 
                {
                    accessionIdToTestCodes.put(accessionId, new List<String>{testCode});
                } 
                else 
                {
                    accessionIdToTestCodes.get(accessionId).add(testCode);
                }
                
            }

            

            for (Result__c result : results) 
            {
                gen.writeStartObject();
                if(String.join(accessionIdToTestNames.get(result.Accession_ID__c), ', ') != null)
                {
                    gen.writeStringField('testname', String.join(accessionIdToTestNames.get(result.Accession_ID__c), ', '));
                }
                else {
                    gen.writeStringField('testname', '');
                }
                
                if(result.Date_Reported__c != null)
                {
                    gen.writeStringField('reportedDate', String.valueOf(result.Date_Reported__c));
                }
                else
                {
                    gen.writeStringField('reportedDate', '');
                }
                if(result.Date_of_Collection__c != null)
                {
                    gen.writeStringField('collectionDate', String.valueOf(result.Date_of_Collection__c ));
                }
                else
                {
                    gen.writeStringField('collectionDate', '');
                }
                if(result.Accession_ID__c!= null)
                {
                    gen.writeStringField('accessionId', result.Accession_ID__c);
                }
                else
                {
                    gen.writeStringField('accessionId', '');
                }
                if(result.Customer_ID__c!= null)
                {
                    gen.writeStringField('customerId', result.Customer_ID__c);
                }
                else
                {
                    gen.writeStringField('customerId', '');
                }
                if(result.Client_ID__c!= null)
                {
                    gen.writeStringField('clientId', result.Client_ID__c);
                }
                else
                {
                    gen.writeStringField('clientId', '');
                }
                if(result.Performing_Site__c!= null)
                {
                    gen.writeStringField('perfsite', result.Performing_Site__c);
                }
                else
                {
                    gen.writeStringField('perfsite', '');
                }
                

                // Write test codes array
                gen.writeFieldName('testCodes');
                gen.writeStartArray();
                for (String testCode : accessionIdToTestCodes.get(result.Accession_ID__c)) 
                {
                    if(testCode != null)
                    {
                        gen.writeString(testCode);    
                    }
    
                }
                gen.writeEndArray();

                gen.writeEndObject();
            }

            


        }
        gen.writeEndArray();
        gen.writeEndObject();
        jsonPayload = gen.getAsString();

        
        return jsonPayload;
     }
    
    global class RequestData {
        public String customerId { get; set; }
        public String startDate { get; set; }
        public String endDate { get; set; }
    }
}