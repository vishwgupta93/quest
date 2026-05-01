global class EOSTMQReaderScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        EOSTResultsMQReader.readMQ();
     }
 }