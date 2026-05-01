/**
 * @description Controller for order lookup and registration processes in Experience Cloud.
 * It includes methods for retrieving order details, handling tester data,
 * creating lab orders via flow, and managing community users.
 */
public without sharing class MinorOrderRegistrationCtrl {

    public class OrderRegistrationException extends Exception {}

    /**
     * @description Retrieves FulfillmentOrderLineItems or Commerce_Order_Info__c based on order number.
     * @param orderNumber The order number to look up.
     * @return A JSON serialized OrderRegistrationUIWrapper object.
     */
    @AuraEnabled
    public static String getLineItemsByOrderNumber(String orderNumber) {
        try {
            OrderRegistrationUIWrapper wrapObj;

            if (String.isBlank(orderNumber) || orderNumber.startsWith(Label.Quest_Legacy_Order_Prefix)) {
                return JSON.serialize(new OrderRegistrationUIWrapper(new List<FulfillmentOrderLineItem>()));
            }
            
            List<FulfillmentOrderLineItem> folList = [
                SELECT Id, Description, Test_Type__c, FulfillmentOrder.Record_Type__c, 
                       FulfillmentOrder.OrderExpirationDate__c, FulfillmentOrder.Status,
                       FulfillmentOrderId, FulfillmentOrder.OrderSummary.OrderedDate, 
                       FulfillmentOrder.OrderSummary.OrderNumber, Is_Registered__c,
                       Product2.AOE_required__c, Product2.Gender__c, Product2.Exclude_from_registration__c, 
                       Product2.Excluded_State_codes__c, Product2.Max_age__c, Product2.Min_age__c,
                       Product2.ProductCode, FulfillmentOrder.OrderSummaryId, ProductName__c,
                       // Billing Address fields
                       FulfillmentOrder.OrderSummary.BillingAddressLine1__c, FulfillmentOrder.OrderSummary.BillingAddressLine2__c,
                       FulfillmentOrder.OrderSummary.BillingCity, FulfillmentOrder.OrderSummary.BillingCountry,
                       FulfillmentOrder.OrderSummary.BillingPostalCode, FulfillmentOrder.OrderSummary.BillingState,
                       FulfillmentOrder.OrderSummary.BillingPhoneNumber, FulfillmentOrder.OrderSummary.BillingEmailAddress,
                       // Other Fulfillment Order fields
                       FulfillmentOrder.FirstName__c, FulfillmentOrder.LastName__c, Is_Service__c,
                       // Minor Order fields
                       FulfillmentOrder.OrderSummary.Minor_Order__c
                FROM FulfillmentOrderLineItem
                WHERE FulfillmentOrder.OrderSummary.OrderNumber = :orderNumber
                AND Test_Type__c IN ('at_home', 'PSC', 'PackHealth', 'consult')
            ];

            System.debug('FulfillmentOrderLineItem count: ' + folList.size());

            if (!folList.isEmpty()) {
                wrapObj = new OrderRegistrationUIWrapper(folList,true);
            } else {
                // Fallback to Commerce_Order_Info__c when fulfillment order line items are empty
                System.debug('No fulfillment order line items found, checking Commerce_Order_Info__c for order number: ' + orderNumber);
                List<Commerce_Order_Info__c> coiList = [
                    SELECT Id, CreatedDate, Order_Number__c, Address_Line_1__c, 
                           Address_Line_2__c, City__c, Postal_Code__c, State__c, Email__c, 
                           Test_Codes__c, First_Name__c, Last_Name__c, Phone_Number__c 
                    FROM Commerce_Order_Info__c 
                    WHERE Order_Number__c = :orderNumber
                ];
                if (!coiList.isEmpty()) {
                    System.debug('Found Commerce_Order_Info__c record: ' + coiList[0].Id);
                    wrapObj = new OrderRegistrationUIWrapper(coiList[0]);
                    // Set minor order flag for commerce flow
                    if (wrapObj.orderInfo != null) {
                        wrapObj.orderInfo.minorOrder = true;
                    }
                } else {
                    System.debug('No order data found for order number: ' + orderNumber);
                }
            }
            
            return JSON.serialize(wrapObj);

        } catch (QueryException qe) {
            throw new OrderRegistrationException('Query Error: ' + qe.getMessage());
        } catch (Exception ex) {
            throw new OrderRegistrationException('An unexpected error occurred: ' + ex.getMessage());
        }
    }

    /**
     * @description Decrypts data (assumed to be an order number) using a utility class.
     * @param encryptedData The string to decrypt (e.g., an encrypted order number).
     * @return The decrypted string.
     */
    @AuraEnabled
    public static String decryptData(String encryptedData) {
        try {
            String result = LabOrderCryptoUtils.decodeOrderNumberFromSFCC(encryptedData);
            System.debug('RESULT:::' + result);
            return result;
        } catch(Exception ex) {
            throw new OrderRegistrationException('Decryption error: ' + ex.getMessage());
        }
    }

    /**
     * @description Upserts a single Tester_Detail__c record.
     * @param testerDetail The Tester_Detail__c record to upsert.
     * @return The upserted Tester_Detail__c record.
     */
    @AuraEnabled
    public static Tester_Detail__c createTesterDetail(Tester_Detail__c testerDetail) {

        try {
            upsert testerDetail;
            return testerDetail;
        } catch(DMLException dmlEx) {
            throw new OrderRegistrationException('Error performing upsert on Tester Detail: ' + dmlEx.getMessage());
        }
    }

    /**
     * @description Executes a flow to create a lab order and then creates a community user.
     * @param testerDetailId The Id of the created Tester_Detail__c record.
     * @param foLineIds List of FulfillmentOrderLineItem Ids to process.
     * @param isService Boolean indicating if the order is a service order.
     * @return A JSON serialized OrderRegistrationUIWrapper response with lab order details.
     */
    @AuraEnabled
    public static String createLabOrder(String testerDetailId, List<String> foLineIds, Boolean isService) {
        try {
            // Debug Tester Detail before flow
            Tester_Detail__c testerDetailRecord = [SELECT Id, First_Name__c, Last_Name__c, Email__c, Phone__c, 
                                                        Address_Line_1__c, City__c, State__c, Zip_Code__c, Country__c,
                                                        Minor_First_Name__c, Minor_Last_Name__c, Minor_Date_Of_Birth__c,
                                                        Minor_Gender__c, Minor_TnC_Version__c,
                                                        Minor_Address_Line_1__c, Minor_Address_Line_2__c, Minor_City__c,
                                                        Minor_State__c, Minor_Zip_Code__c, Minor_Country__c
                                                 FROM Tester_Detail__c 
                                                 WHERE Id = :testerDetailId];
            System.debug('Tester Detail Record being passed to flow: ' + JSON.serializePretty(testerDetailRecord));

            // 1. Prepare Flow Inputs
            Map<String, Object> inputs = new Map<String, Object>();
            inputs.put('TesterID', (Id)testerDetailId);
            inputs.put('FOLineIDs', foLineIds);

            System.debug('Flow inputs: ' + inputs);

            // 2. Execute Flow
            Flow.Interview.Quest_Experience_Cloud_Submit_Action_Minors flow = 
                new Flow.Interview.Quest_Experience_Cloud_Submit_Action_Minors(inputs);
            
            String contactId = null;
            String labOrderNumber = null;
            String errorMessage = null;
            
            //if (!System.Test.isRunningTest()) {

            flow.start();
            // Get output variables
            contactId = (String) flow.getVariableValue('varContactId');  
            labOrderNumber = (String) flow.getVariableValue('LabOrderNumber');
            errorMessage = (String) flow.getVariableValue('ErrorMessage');
            
            // Check for flow-assigned errors first
            if (String.isNotBlank(errorMessage)) {
                throw new OrderRegistrationException('Flow Error: ' + errorMessage);
            }

            //}

            System.debug('Flow output - contactId: ' + contactId);    
            System.debug('Flow output - LabOrderNumber: ' + labOrderNumber);
            
            // 3. Create/Update Community User (Moved to a Queueable for Asynchronous Processing)
            // This prevents the user creation from slowing down the primary transaction
            if (String.isNotBlank(contactId)) {
                System.enqueueJob(new CreateCustomerUserQueueable(contactId));
            }

            // 4. Prepare Response
            OrderRegistrationUIWrapper response = new OrderRegistrationUIWrapper();
            response.labOrderId = labOrderNumber;
            response.isService = isService;
            
            System.debug('Response wrapper: ' + response); 
            return JSON.serialize(response);

        } catch (Exception ex) {
            throw new OrderRegistrationException('Lab Order Creation Error: ' + ex.getMessage());
        }
    }
    
    //-------------------------------------------------------------------------
    // ASYNCHRONOUS USER CREATION
    //-------------------------------------------------------------------------

    /**
     * @description Queueable class to handle asynchronous creation/update of a community user.
     * This improves performance of the createLabOrder method.
     */
    public class CreateCustomerUserQueueable implements Queueable, Database.AllowsCallouts {
        private String contactId;

        public CreateCustomerUserQueueable(String cId) {
            this.contactId = cId;
        }

        public void execute(QueueableContext context) {
            MinorOrderRegistrationCtrl.createCustomerUser(this.contactId);
        }
    }
    
    /**
     * @description Creates or updates a community user for a given Contact.
     * This method is now called from a Queueable job.
     * @param contactId The Id of the Contact record.
     */
    /**
     * @description Updates an existing Tester_Detail__c record with minor information
     * @param testerDetailId The Id of the guardian's Tester_Detail__c record
     * @param minorDetails Map containing minor-specific fields to update
     * @return The updated Tester_Detail__c record
     */
    @AuraEnabled(cacheable=false)
    public static Tester_Detail__c updateMinorDetails(Id testerDetailId, Map<String, Object> minorDetails) {
        try {
            System.debug('Received testerDetailId: ' + testerDetailId);
            System.debug('Received minorDetails: ' + minorDetails);
            Tester_Detail__c testerRecord = [
                SELECT Id, Minor_First_Name__c, Minor_Last_Name__c, 
                       Minor_Date_Of_Birth__c, Minor_Gender__c, Minor_TnC_Version__c,
                       Minor_Address_Line_1__c, Minor_Address_Line_2__c, Minor_City__c,
                       Minor_State__c, Minor_Zip_Code__c, Minor_Country__c
                FROM Tester_Detail__c 
                WHERE Id = :testerDetailId
            ];

            // Update minor-specific fields
            testerRecord.Minor_First_Name__c = (String)minorDetails.get('firstName');
            testerRecord.Minor_Last_Name__c = (String)minorDetails.get('lastName');
            String dobString = (String)minorDetails.get('dateOfBirth');
            // Expecting date in YYYY-MM-DD format from UI
            if (String.isNotBlank(dobString)) {
                testerRecord.Minor_Date_Of_Birth__c = Date.valueOf(dobString);
            }
            testerRecord.Minor_Gender__c = (String)minorDetails.get('gender');
            testerRecord.Minor_TnC_Version__c = (String)minorDetails.get('tncVersion');
            
            // Update minor address fields
            testerRecord.Minor_Address_Line_1__c = (String)minorDetails.get('addressLine1');
            testerRecord.Minor_Address_Line_2__c = (String)minorDetails.get('addressLine2');
            testerRecord.Minor_City__c = (String)minorDetails.get('city');
            testerRecord.Minor_State__c = (String)minorDetails.get('state');
            testerRecord.Minor_Zip_Code__c = (String)minorDetails.get('zipCode');
            testerRecord.Minor_Country__c = (String)minorDetails.get('country');

            update testerRecord;
            return testerRecord;
        } catch(Exception ex) {
            throw new OrderRegistrationException('Error updating minor details: ' + ex.getMessage());
        }
    }

    @testVisible // Added for test coverage visibility
    public static void createCustomerUser(String contactId) {
        if (String.isBlank(contactId)) {
            return;
        }
        
        // Use a set to hold profile names for optimization and safety
        Set<String> profileNames = new Set<String>{'Customer Community Login User'};
        
        Map<String, Id> profileIdMap = new Map<String, Id>();
        for (Profile p : [SELECT Id, Name FROM Profile WHERE Name IN :profileNames]) {
            profileIdMap.put(p.Name, p.Id);
        }
        
        Id communityProfileId = profileIdMap.get('Customer Community Login User');
        if (communityProfileId == null) {
            System.debug('Community Profile not found. Cannot create user.');
            return;
        }
        
        List<Contact> contacts = [SELECT Id, FirstName, LastName, Email 
                                  FROM Contact 
                                  WHERE Id = :contactId];
        
        if (contacts.isEmpty() || String.isBlank(contacts[0].Email)) {
            System.debug('Contact not found or email is blank. Cannot create user.');
            return;
        }
        
        Contact con = contacts[0];
        
        List<User> existingUsers = [SELECT Id FROM User WHERE ContactId = :contactId];

        User u = new User();
        
        // Use safe access to avoid NullPointerExceptions
        String firstNameInitial = String.isNotBlank(con.FirstName) ? con.FirstName.left(1) : '';

        // Build unique and mandatory fields
        u.Alias = (firstNameInitial + con.LastName).left(7).toLowerCase();
        u.CommunityNickname = (con.LastName.left(20) + '_' + con.Id).replaceAll('[^a-zA-Z0-9_.]', ''); // Clean for API names
        u.ContactId = con.Id;
        u.Email = con.Email; 
        u.EmailEncodingKey = 'UTF-8';
        u.IsActive = true;
        u.LanguageLocaleKey = 'en_US';
        u.LastName = con.LastName;
        u.FirstName = con.FirstName;
        u.LocaleSidKey = 'en_US';
        u.ProfileId = communityProfileId;
        u.TimeZoneSidKey = 'America/Chicago';
        u.Username = con.LastName.replaceAll('[^a-zA-Z0-9_.]', '') + '_' + con.Id + '@quest.com'; // Ensure a unique and clean username
        
        try {
            if (existingUsers.isEmpty()) {
                Database.insert(u, false);
            } else {
                u.Id = existingUsers[0].Id;
                Database.update(u, false);
            }
        } catch (DMLException dmlEx) {
            System.debug('DML Error creating/updating User: ' + dmlEx.getMessage());
        }
    }
}