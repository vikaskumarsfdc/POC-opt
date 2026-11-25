public with sharing class AccountDynamicController {

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        return [SELECT Id, Name FROM Account LIMIT 50];
    }

    @AuraEnabled
    public static List<SObject> getChildRecords(
        Id accId,
        String objectApiName,
        String fields
    ) {
        String query = 'SELECT ' + fields + 
                       ' FROM ' + objectApiName + 
                       ' WHERE AccountId = :accId LIMIT 200';

        return Database.query(query);
    }
}