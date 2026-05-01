@isTest
public class SFOMUpdateRefundOnCreditMemosTest {
    @isTest
    static void testExecute() {
        Test.startTest();

        // Create a new instance of the scheduled class
        SFOMUpdateRefundOnCreditMemos scheduledClassInstance = new SFOMUpdateRefundOnCreditMemos();

        // Execute the scheduled job
        scheduledClassInstance.execute(null);

        Test.stopTest();

        // Add assertions here if needed
    }
}