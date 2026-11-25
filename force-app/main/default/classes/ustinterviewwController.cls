public with sharing class ustinterviewwController {
   @AuraEnabled(cacheable=true)
    public static List<contact> getcon(){
      List<Contact> MCON=[Select Id,firstname,lastname,email from Contact limit 10];
      return MCON;
    }
}