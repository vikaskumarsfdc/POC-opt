public with sharing class CaseController {
    @AuraEnabled(cacheable=true)
    public static List<Case> getCases() {
        return [SELECT Id, Subject FROM Case WHERE Status != 'Closed' LIMIT 50];
    }

    @AuraEnabled
    public static void closeCase(Id caseId) {
        update new Case(Id=caseId, Status='Closed');
    }
}