public with sharing class ustinterviewwControllerr {

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        return [SELECT Id, Name FROM Account LIMIT 50];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getChildRecords(Id accountId) {
        return new Map<String, Object>{
            'contacts' => [SELECT Id,FirstName,LastName,Email FROM Contact WHERE AccountId = :accountId],
            'opportunities' => [SELECT Id,Name,StageName,Amount,CloseDate FROM Opportunity WHERE AccountId = :accountId]
        };
    }
}