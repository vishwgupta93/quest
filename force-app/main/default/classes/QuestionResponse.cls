/**
 *      @author       Raj Rajen
 *      @date         11/01/2024
 *      @description  Utility class used to encapsulate the HRA question responses
 *
 *      Modification Log:
        ------------------------------------------------------------------------------------
        Developer                       Date                Description
        ------------------------------------------------------------------------------------
        Raj Rajen                     11/01/2024         Initial creation of class
 *
 */
public with sharing class QuestionResponse {
    @AuraEnabled @InvocableVariable
    public String Question;
    @AuraEnabled @InvocableVariable
    public String Answer;
    @AuraEnabled @InvocableVariable
    public String AnswerTag;
    @AuraEnabled @InvocableVariable
    public String AnswerType;
    @AuraEnabled @InvocableVariable
    public Boolean Calculate;

    public QuestionResponse(String question, String answer, String answerTag, String answerType, Boolean calculate) {
        this.Question = question;
        this.Answer = answer;
        this.AnswerTag = answerTag;
        this.AnswerType = answerType;
        this.Calculate = calculate;
    }

    public QuestionResponse()
    {
        
    }
}