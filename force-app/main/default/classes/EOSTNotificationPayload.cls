public class EOSTNotificationPayload {

        public Integer version;
        public Event event;


    public class Event {
        public String eventType;
        public String eostRequisitionUuid;
        public String dateOfService;
        public String internalRequistionNumber;
        public String accessionNumber;
        public String performingSite;
        public String clientAccountNumber;
        public String labRefID;
        public String labRefIdOverride;
        public String PID;
        public Integer statusCode;
        public String statusDesc;
        public String notificationUuid;
        public String dateOfCollection;
        public String dateReported;
        public Patient patient;
        public Provider provider;
        public String eventDesc;
        public List<OrderedTest> orderedTests;
    }

    public class Patient {
        public String patientLastName;
        public String patientFirstName;
        public String patientGender;
        public String patientDateOfBirth;
    }

    public class Provider {
        public String providerLastName;
        public String providerFirstName;
        public String providerId;
    }

    public class OrderedTest {
        public Boolean reflexTest;
        public String statusCode;
        public String testCode;
        public String testCodeDescription;
        public String eventDesc;
    }

    // Method to convert payload into NotificationDetail objects
    public Map<String,EOST_OMS_Notification_Detail__c> convertToNotificationDetails(String logId) {
        Map<String,EOST_OMS_Notification_Detail__c> notificationDetails = new Map<String,EOST_OMS_Notification_Detail__c>();
        String SF_Lab_Order_Key_Prefix = Label.SF_Lab_Order_Key_Prefix;

        System.debug('1 - Event Details: ' + event);
        Boolean labRefIdOverrided = true;

            if(event.labRefID != null && event.labRefId != '' && event.labRefID.startsWith(SF_Lab_Order_Key_Prefix) && event.labRefID.length()==18)
            {
                List<Lab_Order__c>  lo_Record = new List<Lab_Order__c>([Select Id, name,EOST_Status_Code__c from Lab_Order__c where Lab_Order_ID_Uppercase__c =: event.labRefID limit 1]);
                if(lo_Record != null && lo_Record.size() > 0 && !lo_Record.isEmpty())
                {
                    lo_Record[0].EOST_Status_Code__c = String.valueOf(event.statusCode);
                    update lo_Record;
                    labRefIdOverrided = false;
                }

            } else if(event.labRefID != null && event.labRefId != '' && !event.labRefID.startsWith('0A3') && !event.labRefID.startsWith(SF_Lab_Order_Key_Prefix)){
                List<Lab_Order__c>  lo_Record = new List<Lab_Order__c>([Select Id, name,EOST_Status_Code__c from Lab_Order__c where Kit_Detail__r.Activation_Code__c =: event.labRefID limit 1]);
                if(lo_Record != null && lo_Record.size() > 0 && !lo_Record.isEmpty())
                {
                    lo_Record[0].EOST_Status_Code__c = String.valueOf(event.statusCode);
                    update lo_Record;
                    labRefIdOverrided = false;
                }

            }
            if(labRefIdOverrided){//if the payload comes from the AWS service
                List<Lab_Order__c>  lo_Record = new List<Lab_Order__c>([Select Id, name,EOST_Status_Code__c from Lab_Order__c where LabRefId_Override__c =: event.labRefID limit 1]);
                if(lo_Record != null && lo_Record.size() > 0 && !lo_Record.isEmpty())
                {
                    event.labRefIdOverride = event.labRefID;
                    lo_Record[0].EOST_Status_Code__c = String.valueOf(event.statusCode);
                    update lo_Record;
                }
            } 
        // Modified by Ramana reddy 19/06/2025 end here.

        if (event != null && event.orderedTests != null) {
            for (OrderedTest orderedTest : event.orderedTests) {
                EOST_OMS_Notification_Detail__c detail = new EOST_OMS_Notification_Detail__c();

                detail.Accession_Number__c = event.accessionNumber;
                detail.Date_of_Collection__c = parseDate(event.dateOfCollection);
                detail.Date_Reported__c =parseDate(event.dateReported);
                detail.EOST_Test_Code__c = orderedTest.testCode;
                detail.Performing_Site__c = event.performingSite;
                detail.Lab_Ref_Id__c = event.labRefID;
                detail.Resulted_Date__c = parseDate(event.dateReported);
                detail.Service_Date__c = parseDate(event.dateOfService);
                detail.Client_Account_Number__c= event.clientAccountNumber;
                //detail.EventType__c =event.eventType;

                detail.NCS_Accession_ID__c = event.accessionNumber;
                detail.NCS_Date_of_Collection__c = parseDate(event.dateOfCollection);
                detail.NCS_Date_Reported__c =parseDate(event.dateReported);
                detail.NCS_Test_Code__c = orderedTest.testCode;
                detail.NCS_Performing_Site__c = event.performingSite;
                detail.NCS_Lab_Ref_ID__c =  event.labRefID;
                detail.NCS_Resulted_Date__c = parseDate(event.dateReported);

                detail.EOST_OMS_Log__c=logId;

                detail.PID__c = event.PID;
                detail.Order_Status__c=event.statusDesc;

                detail.Test_Description__c = orderedTest.testCodeDescription;
                detail.Test_Status__c = orderedTest.statusCode;
                detail.Test_Event_Desc__c=orderedTest.eventDesc;
                detail.Order_Event_Desc__c=event.eventDesc;

                // Use labRefIdOverride if present, otherwise use labRefID
                String labRefId = event.labRefID;

                if(labRefId == null || labRefId == '') // is the labRefID coming null?
                {
                    system.debug('Inside labRefId unknown');
                    labRefId =  'UnKnown';
                }
                else {
                    if(labRefIdOverrided){
                        detail.Type__c='LO';
                    }else{
                        if(event.labRefID.startsWith('0A3') && event.labRefID.length()==18)
                        {
                            detail.Type__c='FO';
                        }
                        else if(event.labRefID.startsWith(SF_Lab_Order_Key_Prefix) && event.labRefID.length()==18)
                        {
                            detail.Type__c='LO';
                        }
                        else if(!event.labRefID.startsWith('0A3') && !event.labRefID.startsWith(SF_Lab_Order_Key_Prefix))
                        {
                            detail.Type__c='Kit';
                        }
                    }
                }

                notificationDetails.put(labRefId+orderedTest.testCode,detail);
            }
        }

        return notificationDetails;
    }

    private static Date parseDate(String dateString) {

        Date paresedDate = null;
        if(dateString != null)
        {
            System.debug(dateString);
            List<String> dateTimeParts = dateString.split('T');
            String datePart = dateTimeParts[0];
            try
            {
                paresedDate = Date.valueOf(datePart);
            }
            catch (Exception e)
            {
                System.debug( 'Invalid Date : ' + dateString);
                return null;
            }
        }
        return paresedDate;

    }
}