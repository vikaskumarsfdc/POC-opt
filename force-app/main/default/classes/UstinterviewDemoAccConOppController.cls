public with sharing class UstinterviewDemoAccConOppController {
    
    @AuraEnabled(Cacheable=true)
    public static List<Account> getAcc(){
        return [SELECT Id, Name, Rating, Phone FROM Account LIMIT 10];
    }

    @AuraEnabled(Cacheable=true)
    public static List<Contact> getContacts(Id accountId){
        return [SELECT Name, Email, Phone FROM Contact WHERE AccountId = :accountId];
    }

    @AuraEnabled(Cacheable=true)
    public static List<Opportunity> getOpportunities(Id accountId){
        return [SELECT Name, StageName, CloseDate FROM Opportunity WHERE AccountId = :accountId];
    }
}