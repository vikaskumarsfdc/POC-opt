public with sharing class NewwController {
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccount(){
      try {
        return [Select Name,Rating from Account];
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> getContact(Id accountId){
      try {
        return [Select LastName,Email from Contact where AccountId=:accountId];
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
    }
}