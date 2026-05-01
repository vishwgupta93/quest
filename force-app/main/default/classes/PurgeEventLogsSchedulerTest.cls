@isTest
public class PurgeEventLogsSchedulerTest {
	@isTest
    static void testOrderBatchSchedule() {
        Test.startTest();
        PurgeEventLogsScheduler scheduler = new PurgeEventLogsScheduler();
        scheduler.execute(null);
        Test.stopTest();
    }
}