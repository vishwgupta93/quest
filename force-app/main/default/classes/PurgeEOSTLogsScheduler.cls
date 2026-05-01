public class PurgeEOSTLogsScheduler implements Schedulable{
 public void execute(SchedulableContext sc) {
        PurgeEOSTLogsBulkBatch.run();
    }
}