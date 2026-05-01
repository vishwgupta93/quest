@isTest
private class EmailAlertBatchJobTest {

    @isTest
    static void testEmailAlertBatchJob() {
        
        EmailAlertBatchJob jobInstance = new EmailAlertBatchJob();        
               
        Test.startTest();
        jobInstance.execute(null);
        Test.stopTest();
        
    }

    @IsTest 
    static void EmailAlertBatchJobTest () {
        EmailAlertBatchJob  obj = new EmailAlertBatchJob();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, obj); 
  }    

}