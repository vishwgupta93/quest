@IsTest
public with sharing class EmailToCaseOutputTest {

    @IsTest
    static void testCaseOutputSuccess()
    {
        EmailToCaseUtil.emailToCaseInput input = new EmailToCaseUtil.emailToCaseInput();
        input.emailSubject= 'Health Study Cancel Order - BJDC-SB-010-00001205';

        List<EmailToCaseUtil.emailToCaseInput> inputs =new List<EmailToCaseUtil.emailToCaseInput>();
        inputs.add(input);

        List<EmailToCaseUtil.EmailToCaseOutput> outputs =   EmailToCaseUtil.EmailToCaseOutput(inputs);
        EmailToCaseUtil.EmailToCaseOutput output = outputs[0];

        System.assertEquals(1, outputs.size());
        System.assertEquals(output.orderNumber, 'BJDC-SB-010-00001205');

    }

    @IsTest
    static void testCaseOutputError()
    {
        EmailToCaseUtil.emailToCaseInput input = new EmailToCaseUtil.emailToCaseInput();
        input.emailSubject= 'Health Study Cancel';

        List<EmailToCaseUtil.emailToCaseInput> inputs =new List<EmailToCaseUtil.emailToCaseInput>();
        inputs.add(input);

        List<EmailToCaseUtil.EmailToCaseOutput> outputs =   EmailToCaseUtil.EmailToCaseOutput(inputs);
        EmailToCaseUtil.EmailToCaseOutput output = outputs[0];

        System.assertEquals(1, outputs.size());
        System.assertEquals(output.orderNumber, '');

    }
    
}