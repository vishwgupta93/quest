public class PWNTokenGeneration{
    
    public static String base64url(String source) {
        Blob sourceBlob = Blob.valueOf(source);
        String encodedSource = EncodingUtil.base64Encode(sourceBlob);
        encodedSource = encodedSource.replaceAll('=+$', '');
        encodedSource = encodedSource.replaceAll('\\+', '-');
        encodedSource = encodedSource.replaceAll('\\/', '_');
        return encodedSource;
    }

    public static Map<String, Object> payload(String key) {
        Integer now = Math.floor(System.now().getTime() / 1000).intValue();
        Map<String, Object> content = new Map<String, Object>();
        content.put('iss', key);
        content.put('iat', now);
        content.put('exp', now + (24 * 60 * 60)); // 1 day
        content.put('ver', 1);
        return content;
    }

    public static String generateToken(String key, String secret) {
        Map<String, Object> header = new Map<String, Object>();
        header.put('typ', 'JWT');
        header.put('alg', 'HS256');

        String encodedHeader = base64url(JSON.serialize(header));
        String encodedData = base64url(JSON.serialize(payload(key)));

        String token = encodedHeader + '.' + encodedData;

        Blob tokenBlob = Blob.valueOf(token);
        Blob secretBlob = Blob.valueOf(secret);
        Blob signatureBlob = Crypto.generateMac('HMACSHA256', tokenBlob, secretBlob);
        String signature = EncodingUtil.base64Encode(signatureBlob);
        signature = signature.replaceAll('=+$', '');
        signature = signature.replaceAll('\\+', '-');
        signature = signature.replaceAll('\\/', '_');

        String signedToken = token + '.' + signature;
        System.debug(signedToken);
        return signedToken ;
    }
}