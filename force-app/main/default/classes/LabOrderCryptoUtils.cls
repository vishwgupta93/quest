public with sharing class LabOrderCryptoUtils {
    
    public static String buildEncryptedURL(String baseUrl, String orderId, String orderNumber, String showOTP) {
        Datetime currentTime = Datetime.now();
        Integer expiryDays = Integer.valueOf(Label.Lab_Order_Results_URL_Expiry);  
        Datetime expirationTimestamp = currentTime.addDays(expiryDays);
        String dataToEncrypt = 'orderId=' + orderId + 
                               ':expirationTimestamp=' + expirationTimestamp.format() +
                               ':orderNumber=' + orderNumber +
                               ':showOTP=' + showOTP;                               
        String encryptedValue = encryptParameters(dataToEncrypt);
        String fullURL = baseUrl + '?data=' + EncodingUtil.urlEncode(encryptedValue, 'UTF-8');
        return fullURL;
    }

    public static String encryptParameters(String data) {
        Blob vector = EncodingUtil.base64Decode(Label.SFCC_Initializtion_Vector);
        Blob key = EncodingUtil.base64Decode(Label.SFCC_Private_Key);
                
        Blob encryptedData = Crypto.encrypt('AES256', key, vector, Blob.valueOf(data));
        return EncodingUtil.base64Encode(encryptedData);
    }

    public static String getDecryptedData(String encryptedData) {
       
        Blob vector = EncodingUtil.base64Decode(Label.SFCC_Initializtion_Vector);
        Blob key = EncodingUtil.base64Decode(Label.SFCC_Private_Key);
        Blob encrypted = EncodingUtil.base64Decode(encryptedData.replaceAll(' ', '+'));        
        Blob decrypted = Crypto.decrypt('AES256', key, vector, encrypted);
        return decrypted.toString();
    }

    public static String decodeOrderNumberFromSFCC(String orderNumber)
    {
        Blob vector = EncodingUtil.base64Decode(Label.SFCC_Initializtion_Vector);
        Blob key = EncodingUtil.base64Decode(Label.SFCC_Private_Key);
        Blob encrypted = EncodingUtil.base64Decode(orderNumber.replaceAll(' ', '+'));        
        Blob decrypted = Crypto.decrypt('AES256', key, vector, encrypted);
        return decrypted.toString();
    }

    public static String enryptOrderNumberFromSFCC(String orderNumber)
    {
        Blob vector = EncodingUtil.base64Decode(Label.SFCC_Initializtion_Vector);
        Blob key = EncodingUtil.base64Decode(Label.SFCC_Private_Key);
                
        Blob encryptedOrderNumber = Crypto.encrypt('AES256', key, vector, Blob.valueOf(orderNumber));
        return EncodingUtil.base64Encode(encryptedOrderNumber);
    }

    public static String mfaFlag()
    {
        return Label.SFOM_MFA_Enabled;
    }
}