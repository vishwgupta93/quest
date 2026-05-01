@isTest
private class AWSStatusNotificationTest {
    
    @isTest
    static void testDefaultConstructor() {
        // Create an instance using the default constructor
        AWSStatusNotification notification = new AWSStatusNotification();

        // Set values using direct assignment
        notification.status = 'COMPLETED';
        notification.merchantOrderId = 'MO123';
        notification.shlKey = 'Key123';
        notification.shlLocation = 'Loc1';
        notification.namedCredential = 'My_Named_Credential';
        notification.labOrderNumber = 'LO123';
        notification.clientName = 'Test Client';

        // Assertions to validate the assignment (optional)
        System.assertEquals('COMPLETED', notification.status);
    }

    @isTest
    static void testParameterizedConstructor() {
        // Create an instance using the parameterized constructor
        AWSStatusNotification notification = new AWSStatusNotification(
            'FAILED',
            'MO456',
            'Key456',
            'Loc2',
            'Another_Named_Credential',
            'LO456',
            'Another Client'
        );

        
    }
}