@IsTest
public class LabOrderCryptoUtilsTest {
    
       
    @IsTest
    static void testBuildEncryptedURL() {
        String baseUrl = 'https://example.com/labresults';
        String orderId = '12345';
        String orderNumber = 'ABC123';
        String showOTP = 'true';
        
        String resultURL = LabOrderCryptoUtils.buildEncryptedURL(baseUrl, orderId, orderNumber, showOTP);
        
        System.assertNotEquals(null, resultURL, 'Encrypted URL should not be null');
        System.assert(resultURL.startsWith(baseUrl), 'The URL should start with the base URL');
    }
    
    @IsTest
    static void testEncryptAndDecryptParameters() {
        String sampleData = 'orderId=12345:expirationTimestamp=2024-12-31 23:59:59:orderNumber=ABC123:showOTP=true';
        
        // Encrypt and then decrypt the data
        String encryptedData = LabOrderCryptoUtils.encryptParameters(sampleData);
        String decryptedData = LabOrderCryptoUtils.getDecryptedData(encryptedData);
        
        System.assertEquals(sampleData, decryptedData, 'Decrypted data should match the original data');
    }
    
    @IsTest
    static void testDecodeOrderNumberFromSFCC() {
        String orderNumber = 'ABC123';
        
        // Encrypt and then decrypt the order number
        String encryptedOrderNumber = LabOrderCryptoUtils.enryptOrderNumberFromSFCC(orderNumber);
        String decryptedOrderNumber = LabOrderCryptoUtils.decodeOrderNumberFromSFCC(encryptedOrderNumber);
        
        System.assertEquals(orderNumber, decryptedOrderNumber, 'Decrypted order number should match the original order number');
    }
    
    @IsTest
    static void testMfaFlag() {
        String mfaFlag = LabOrderCryptoUtils.mfaFlag();
        
        System.assertEquals('true', mfaFlag, 'MFA flag should be set to true as per the label');
    }
}