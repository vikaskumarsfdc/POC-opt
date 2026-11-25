public with sharing class accController {
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getaccounts(){
        return [select Name,Rating from Account];
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> getcontacts(Id accountId){
        return [select LastName,Email from Contact where AccountId=:accountId];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getopportunities(Id accountId){
        //return [select Name,StageName from Opportunity where AccountId=:accountId];
         return [SELECT Name, StageName, CloseDate FROM Opportunity WHERE AccountId = :accountId];
    }
}