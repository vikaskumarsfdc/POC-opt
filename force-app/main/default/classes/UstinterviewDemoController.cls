public with sharing class UstinterviewDemoController {
    
    @AuraEnabled(Cacheable=true)
    public static List<Account> getAcc(){
    return [Select Name,Rating,Phone from Account];
 } 

   @AuraEnabled(Cacheable=true)
public static List<Contact> getContacts(Id accountId){
    return [SELECT Name, Email, Phone FROM Contact WHERE AccountId = :accountId];
}


}