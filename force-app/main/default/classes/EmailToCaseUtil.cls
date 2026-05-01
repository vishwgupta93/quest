public class EmailToCaseUtil {
    
    public class emailToCaseInput {
        @InvocableVariable(label='Email Subject' description='Email Subject')
        public String emailSubject;
        
    }

    public class EmailToCaseOutput {
        @InvocableVariable(label='Order Number' description='Order Number')
        public String orderNumber;
        //do regular expression here
    }

    @InvocableMethod(label='process email subject line' description='process email subject line')
    public static List<EmailToCaseOutput> EmailToCaseOutput(List<emailToCaseInput> inputs) {
        List<EmailToCaseOutput> output = new List<EmailToCaseOutput>();
        
        for(emailToCaseInput input : inputs){
            EmailToCaseOutput caseOutput = new EmailToCaseOutput();
            caseOutput.orderNumber = regex(input.emailSubject);
            output.add(caseOutput);
        }
        return output;
    }

    private static String regex(String text){

        //Health Study Cancel Order - BJDC-SB-010-00001205
        String regex = 'Health Study Cancel Order - (.*)';
        Matcher matcher = Pattern.compile(regex).matcher(text);

        // Find and return the matched digits
        if (matcher.find()) {
            //matcher.group();
            return matcher.group(1);
        } else {
            return ''; // No digits found
        }
    }
}