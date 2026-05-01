global class OMSTokenHandlerJob implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        OMSMuleTokenHandler.fetchTokenAndUpdate();
     }
 }