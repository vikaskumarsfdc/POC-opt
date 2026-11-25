public class AccountSearchController {

    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String searchTerm) {
        String query = '%' + searchTerm + '%';
        return [SELECT Id, Name FROM Account 
                WHERE Name LIKE :query 
                LIMIT 10];
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> getRelatedContacts(String accountId) {
        return [SELECT Id, Name, Email, Phone 
                FROM Contact 
                WHERE AccountId = :accountId];
    }
}