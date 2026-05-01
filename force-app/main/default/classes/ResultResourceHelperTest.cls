@IsTest
public class ResultResourceHelperTest {
    

    @IsTest
    static void testGetResultsWithDates() {

        List<Result__c> results = new List<Result__c>();

        results.add(new Result__c(
            Accession_ID__c = 'ACC123',
            Client_ID__c = 'CLIENT1',
            Customer_ID__c = 'CUST1',
            Date_of_Collection__c = Date.today().addDays(-10),
            Date_Reported__c = Date.today().addDays(-5),
            Performing_Site__c = 'Site1',
            Test_Code__c = 'TEST1',
            Test_Name__c = 'Test Name 1'
        ));

        results.add(new Result__c(
            Accession_ID__c = '',
            Client_ID__c = 'CLIENT1',
            Customer_ID__c = 'CUST1',
            Date_of_Collection__c = Date.today().addDays(-8),
            Date_Reported__c = Date.today().addDays(-3),
            Performing_Site__c = 'Site1',
            Test_Code__c = 'TEST2',
            Test_Name__c = 'Test Name 2'
        ));

        insert results;

        // Create a RequestData instance with dates
        ResultResourceHelper.RequestData requestData = new ResultResourceHelper.RequestData();
        requestData.customerId = 'CUST1';
        requestData.startDate = String.valueOf(Date.today().addDays(-9));
        requestData.endDate = String.valueOf(Date.today().addDays(-4));

        Test.startTest();
        String result = ResultResourceHelper.getResults(requestData);
        Test.stopTest();

        System.debug('Results: ' + result);

        System.assert(result != null, 'Result should not be null');
        System.assert(result.containsAny('ACC123'), 'Accession is Present');
    }

    @IsTest
    static void testGetResultsWithoutDates() {


        List<Result__c> results = new List<Result__c>();

        results.add(new Result__c(
            Accession_ID__c = 'ACC123',
            Client_ID__c = 'CLIENT1',
            Customer_ID__c = 'CUST1',
            Date_of_Collection__c = Date.today().addDays(-10),
            Date_Reported__c = Date.today().addDays(-5),
            Performing_Site__c = 'Site1',
            Test_Code__c = 'TEST1',
            Test_Name__c = 'Test Name 1'
        ));

        results.add(new Result__c(
            Accession_ID__c = 'ACC124',
            Client_ID__c = 'CLIENT1',
            Customer_ID__c = 'CUST1',
            Date_of_Collection__c = Date.today().addDays(-8),
            Date_Reported__c = Date.today().addDays(-3),
            Performing_Site__c = 'Site1',
            Test_Code__c = '',
            Test_Name__c = 'Test Name 2'
        ));

        insert results;

        // Create a RequestData instance without dates
        ResultResourceHelper.RequestData requestData = new ResultResourceHelper.RequestData();
        requestData.customerId = 'CUST1';

        Test.startTest();
        String result = ResultResourceHelper.getResults(requestData);
        Test.stopTest();

        System.assert(result != null, 'Result should not be null');
        System.assert(result.containsAny('ACC123'), 'Accession is Present');
        System.assert(result.containsAny('ACC124'), 'Accession is Present');
    }

    @IsTest
    static void testGetResultsNoData() {


        List<Result__c> results = new List<Result__c>();

        results.add(new Result__c(
            Accession_ID__c = 'ACC123',
            Client_ID__c = 'CLIENT1',
            Customer_ID__c = 'CUST1',
            Date_of_Collection__c = Date.today().addDays(-10),
            Date_Reported__c = Date.today().addDays(-5),
            Performing_Site__c = 'Site1',
            Test_Code__c = 'TEST1',
            Test_Name__c = 'Test Name 1'
        ));

        results.add(new Result__c(
            Accession_ID__c = '',
            Client_ID__c = 'CLIENT1',
            Customer_ID__c = 'CUST1',
            Date_of_Collection__c = Date.today().addDays(-8),
            Date_Reported__c = Date.today().addDays(-3),
            Performing_Site__c = 'Site1',
            Test_Code__c = '',
            Test_Name__c = 'Test Name 2'
        ));

        insert results;


        // Create a RequestData instance with a non-matching customer ID
        ResultResourceHelper.RequestData requestData = new ResultResourceHelper.RequestData();
        requestData.customerId = 'CUST_NON_EXISTENT';

        Test.startTest();
        String result = ResultResourceHelper.getResults(requestData);
        Test.stopTest();

        System.assert(result != null, 'Result should not be null');
        System.assert(result.containsAny('"results":[]'), 'Result should be empty for a non-existent customer ID');
    }
}