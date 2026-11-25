public with sharing class NewwwController {
    
    @AuraEnabled(cacheable=true)
    public Static List<Account> getAccounts() {
    return [Select Name,Rating from Account];
    }

    @AuraEnabled(cacheable=true)
    public Static List<Contact> getContacts(Id accountId) {
    return [Select LastName,Email from Contact where AccountId=:accountId];
    }

    


}