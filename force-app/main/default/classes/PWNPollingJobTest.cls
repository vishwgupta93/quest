@IsTest
public class PWNPollingJobTest {
    
    // Mock class for HTTP callout response
    private class MockHttpResponseGeneratorSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock HTTP response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            // Sample response for approved and rejected orders
            String responseBody = '{' +
                '"orders": [' +
                    '{"id": "PWN123", "status": "approved"}' +
                   
                ']' +
            '}';
            res.setBody(responseBody);

            return res;
        }
    }

    private class MockHttpResponseGeneratorReject implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock HTTP response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            // Sample response for approved and rejected orders
            String responseBody = '{' +
                '"orders": [' +
                     '{"id": "PWN456", "status": "rejected"}' +
                ']' +
            '}';
            res.setBody(responseBody);

            return res;
        }
    }

    @IsTest
    static void testPWNPollingJobSuccess() {

        Person_Record__c person = new Person_Record__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Email__c = 'john.doe@example.com',
            Address_Line_1__c = '123 Main St',
            Unique_Identifier__c ='Uniqu1',
            City__c = 'Anytown',
            Country__c = 'USA',
            State__c = 'CA',
            Postal_Code__c = '12345',
            Phone__c = '1234567890',
            Gender__c = 'Male',
            Date_of_Birth__c = Date.newInstance(1990, 1, 1)
        );
        insert person;


        // Set up test data
        Lab_Order__c labOrder1 = new Lab_Order__c(
           Is_Partner__c=true,
            Client_Id__c = '12345',
            Person_Record__c = person.Id,
            Name='TETS81892-12781',
            PWN_ID__C='PWN123',
            Status__c='PA Acknowledged',
            PWN_Success__c=true,
            Physician_First_Name__c='asasd',
            Physician_Last_Name__c='bcvm',
            Physician_Npi__c='122121',
            Physician_Upin__c='12121'
        );
        

        insert new List<Lab_Order__c> { labOrder1 };

        
        // Set the mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());

        Test.startTest();
        PWNPollingJob btch= new PWNPollingJob();
        List<String> statusList = new List<String>{'Cancelled','Expired','PA Rejected'};
        btch.statusList = statusList;
        btch.Id=labOrder1.Id;
        btch.query = 'SELECT Id,Is_Kit__c,Kit_Detail__c, PWN_ID__c FROM Lab_Order__c WHERE  Status__c NOT IN : statusList  and Is_PWN_Approved__c = false and PWN_Success__c = true and Id=:id ';
        Database.executeBatch(btch,1);

        Test.stopTest();

        // Reload the lab orders and kits to verify updates
        Lab_Order__c updatedOrder1 = [SELECT Id, Status__c,Is_PWN_Approved__c, PWN_Status_Date__c FROM Lab_Order__c WHERE Id = :labOrder1.Id];
       

        // // Validate updates for approved order
        System.assertEquals(true, updatedOrder1.Is_PWN_Approved__c, 'Order 1 should be approved');
        System.assertEquals(System.today(), updatedOrder1.PWN_Status_Date__c, 'Order 1 PWN_Status_Date__c should be today');
      

        // Validate updates for rejected order
        // System.assertEquals('PWN Rejected', updatedOrder2.Status__c, 'Order 2 status should be "PWN Rejected"');
        // System.assertEquals(true, updatedOrder2.Full_Refund__c, 'Order 2 Full_Refund__c should be true');
      
    }

    @IsTest
    static void testPWNPollingJobReject() {

        Account ac = new Account();
        ac.Name = 'Test account';
        insert ac;
        
        Contact con = new Contact();
        con.lastName = 'test con';
        con.Email = 'test@gmail.com';
        con.AccountId = ac.Id;
        insert con;

        Person_Record__c person = new Person_Record__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Email__c = 'john.doe@example.com',
            Address_Line_1__c = '123 Main St',
            Unique_Identifier__c ='Uniqu1',
            City__c = 'Anytown',
            Country__c = 'USA',
            Contact__c = con.Id,
            State__c = 'CA',
            Postal_Code__c = '12345',
            Phone__c = '1234567890',
            Gender__c = 'Male',
            Date_of_Birth__c = Date.newInstance(1990, 1, 1)
        );
        insert person;


        // Set up test data
        Lab_Order__c labOrder1 = new Lab_Order__c(
           Is_Partner__c=true,
            Client_Id__c = '12345',
            Person_Record__c = person.Id,
            Name='TETS81892-12781',
            PWN_ID__C='PWN456',
            Status__c='PA Acknowledged',
            PWN_Success__c=true,
            Physician_First_Name__c='asasd',
            Physician_Last_Name__c='bcvm',
            Physician_Npi__c='122121',
            Physician_Upin__c='12121',
            Refund_Amount__c=30.00
        );
        

        insert new List<Lab_Order__c> { labOrder1 };

        
        // Set the mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorReject());

        Test.startTest();
        PWNPollingJob btch= new PWNPollingJob();
        List<String> statusList = new List<String>{'Cancelled','Expired','PA Rejected'};
        btch.statusList = statusList;
        btch.Id=labOrder1.Id;
        btch.query = 'SELECT Id,Is_Kit__c,Kit_Detail__c, PWN_ID__c FROM Lab_Order__c WHERE  Status__c NOT IN : statusList  and Is_PWN_Approved__c = false and PWN_Success__c = true and Id=:id ';
        Database.executeBatch(btch,1);

        Test.stopTest();

        // Reload the lab orders and kits to verify updates
        Lab_Order__c updatedOrder1 = [SELECT Id, Status__c, Full_Refund__c FROM Lab_Order__c WHERE Id = :labOrder1.Id];
       

        // // Validate updates for approved order
        // System.assertEquals(true, updatedOrder1.Is_PWN_Approved__c, 'Order 1 should be approved');
        // System.assertEquals(System.today(), updatedOrder1.PWN_Status_Date__c, 'Order 1 PWN_Status_Date__c should be today');
      

        // Validate updates for rejected order
        System.assertEquals('PA Rejected', updatedOrder1.Status__c, 'Order 2 status should be "PA Rejected"');
        System.assertEquals(true, updatedOrder1.Full_Refund__c, 'Order 2 Full_Refund__c should be true');


        
      
    }

    @IsTest
    static void testGSSPWNPollingJobSuccess() {

        Person_Record__c person = new Person_Record__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Email__c = 'john.doe@example.com',
            Address_Line_1__c = '123 Main St',
            Unique_Identifier__c ='Uniqu1',
            City__c = 'Anytown',
            Country__c = 'USA',
            State__c = 'CA',
            Postal_Code__c = '12345',
            Phone__c = '1234567890',
            Gender__c = 'Male',
            Date_of_Birth__c = Date.newInstance(1990, 1, 1)
        );
        insert person;


        // Set up test data
        Lab_Order__c labOrder1 = new Lab_Order__c(
           Is_Partner__c=true,
            Client_Id__c = '12345',
            Person_Record__c = person.Id,
            Name='TETS81892-12781',
            PWN_ID__C='PWN123',
            Status__c='PA Acknowledged',
            PWN_Success__c=true,
            Physician_First_Name__c='asasd',
            Physician_Last_Name__c='bcvm',
            Physician_Npi__c='122121',
            Physician_Upin__c='12121'
        );
        

        insert new List<Lab_Order__c> { labOrder1 };

        
        // Set the mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());

        Test.startTest();
        GSSPWNPollingJob btch= new GSSPWNPollingJob();
        List<String> statusList = new List<String>{'Cancelled','Expired','PA Rejected'};
        btch.statusList = statusList;
        btch.Id=labOrder1.Id;
        btch.query = 'SELECT Id,Is_Kit__c,Kit_Detail__c, PWN_ID__c FROM Lab_Order__c WHERE  Status__c NOT IN : statusList  and Is_PWN_Approved__c = false and PWN_Success__c = true and Id=:id ';
        Database.executeBatch(btch,1);

        Test.stopTest();

        // Reload the lab orders and kits to verify updates
        Lab_Order__c updatedOrder1 = [SELECT Id, Status__c,Is_PWN_Approved__c, PWN_Status_Date__c FROM Lab_Order__c WHERE Id = :labOrder1.Id];
       

        // // Validate updates for approved order
        System.assertEquals(true, updatedOrder1.Is_PWN_Approved__c, 'Order 1 should be approved');
        System.assertEquals(System.today(), updatedOrder1.PWN_Status_Date__c, 'Order 1 PWN_Status_Date__c should be today');
      

        // Validate updates for rejected order
        // System.assertEquals('PWN Rejected', updatedOrder2.Status__c, 'Order 2 status should be "PWN Rejected"');
        // System.assertEquals(true, updatedOrder2.Full_Refund__c, 'Order 2 Full_Refund__c should be true');
      
    }

    @IsTest
    static void testGSSPWNPollingJobReject() {
        Account ac = new Account();
        ac.Name = 'Test account';
        insert ac;
        
        Contact con = new Contact();
        con.lastName = 'test con';
        con.Email = 'test@gmail.com';
        con.AccountId = ac.Id;
        insert con;
     
        Person_Record__c person = new Person_Record__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Email__c = 'john.doe@example.com',
            Address_Line_1__c = '123 Main St',
            Unique_Identifier__c ='Uniqu1',
            City__c = 'Anytown',
            Country__c = 'USA',
            State__c = 'CA',
            Contact__c = con.Id,
            Postal_Code__c = '12345',
            Phone__c = '1234567890',
            Gender__c = 'Male',
            Date_of_Birth__c = Date.newInstance(1990, 1, 1)
        );
        insert person;


        // Set up test data
        Lab_Order__c labOrder1 = new Lab_Order__c(
           Is_Partner__c=true,
            Client_Id__c = '12345',
            Person_Record__c = person.Id,
            Name='TETS81892-12781',
            PWN_ID__C='PWN456',
            Status__c='PA Acknowledged',
            PWN_Success__c=true,
            Physician_First_Name__c='asasd',
            Physician_Last_Name__c='bcvm',
            Physician_Npi__c='122121',
            Physician_Upin__c='12121',
            Refund_Amount__c=30.00
        );
        

        insert new List<Lab_Order__c> { labOrder1 };

        
        // Set the mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorReject());

        Test.startTest();
        GSSPWNPollingJob btch= new GSSPWNPollingJob();
        List<String> statusList = new List<String>{'Cancelled','Expired','PA Rejected'};
        btch.statusList = statusList;
        btch.Id=labOrder1.Id;
        btch.query = 'SELECT Id,Is_Kit__c,Kit_Detail__c, PWN_ID__c FROM Lab_Order__c WHERE  Status__c NOT IN : statusList  and Is_PWN_Approved__c = false and PWN_Success__c = true and Id=:id ';
        Database.executeBatch(btch,1);

        Test.stopTest();

        // Reload the lab orders and kits to verify updates
        Lab_Order__c updatedOrder1 = [SELECT Id, Status__c, Full_Refund__c FROM Lab_Order__c WHERE Id = :labOrder1.Id];
       

        // // Validate updates for approved order
        // System.assertEquals(true, updatedOrder1.Is_PWN_Approved__c, 'Order 1 should be approved');
        // System.assertEquals(System.today(), updatedOrder1.PWN_Status_Date__c, 'Order 1 PWN_Status_Date__c should be today');
      

        // Validate updates for rejected order
        System.assertEquals('PA Rejected', updatedOrder1.Status__c, 'Order 2 status should be "PA Rejected"');
        System.assertEquals(true, updatedOrder1.Full_Refund__c, 'Order 2 Full_Refund__c should be true');


        
      
    }

    @IsTest 
    static void validateStatusCheckScheduleTest () {
        PWNPollingSchedule testsche = new PWNPollingSchedule();

        GSSPWNPollingSchedule testsche1 = new GSSPWNPollingSchedule();
        String sch = '0 0 23 * * ?';
        
        Person_Record__c person = new Person_Record__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Email__c = 'john.doe@example.com',
            Address_Line_1__c = '123 Main St',
            Unique_Identifier__c ='Uniqu1',
            City__c = 'Anytown',
            Country__c = 'USA',
            State__c = 'CA',
            Postal_Code__c = '12345',
            Phone__c = '1234567890',
            Gender__c = 'Male',
            Date_of_Birth__c = Date.newInstance(1990, 1, 1)
        );
        insert person;


        // Set up test data
        Lab_Order__c labOrder1 = new Lab_Order__c(
           Is_Partner__c=true,
            Client_Id__c = '12345',
            Person_Record__c = person.Id,
            Name='TETS81892-12781',
            PWN_ID__C='PWN123',
            Status__c='PA Acknowledged',
            PWN_Success__c=true,
            Physician_First_Name__c='asasd',
            Physician_Last_Name__c='bcvm',
            Physician_Npi__c='122121',
            Physician_Upin__c='12121'
        );
        

        insert new List<Lab_Order__c> { labOrder1 };
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());


        Test.startTest();
        system.schedule('Test status Check', sch, testsche );
        system.schedule('Test status Check 1', sch, testsche1 );
        Test.stopTest();
  }      
}