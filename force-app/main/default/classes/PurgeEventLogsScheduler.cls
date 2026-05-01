public class PurgeEventLogsScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        PurgeEventLogsBulkBatch.run();
    }
}