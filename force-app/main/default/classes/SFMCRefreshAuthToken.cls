global class SFMCRefreshAuthToken implements Schedulable {
    
   global void execute(SchedulableContext sc) {
        SFMCAuthTokenHandler.fetchTokenAndUpdate();
    }
}