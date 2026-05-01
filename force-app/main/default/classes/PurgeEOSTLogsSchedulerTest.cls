@isTest
public class PurgeEOSTLogsSchedulerTest {
	@isTest
    static void testOrderBatchSchedule() {
        Test.startTest();
        PurgeEOSTLogsScheduler scheduler = new PurgeEOSTLogsScheduler();
        scheduler.execute(null);
        Test.stopTest();
    }
}