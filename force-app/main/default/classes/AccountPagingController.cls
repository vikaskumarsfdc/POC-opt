public with sharing class AccountPagingController {

    public class PageResult {
        @AuraEnabled public List<Account> records;
        @AuraEnabled public Integer totalRecords;
    }

    @AuraEnabled
    public static PageResult getAccounts(Integer pageSize, Integer pageNumber) {
        Integer size = Math.min(Math.max(pageSize == null ? 5 : pageSize, 1), 50);
        Integer page = Math.max(pageNumber == null ? 1 : pageNumber, 1);
        Integer offsetRows = (page - 1) * size;

        PageResult result = new PageResult();
        result.records = [
            SELECT Id, Name, Description
            FROM Account
            WITH USER_MODE
            ORDER BY Name, Id
            LIMIT :size OFFSET :offsetRows
        ];
        result.totalRecords = [SELECT COUNT() FROM Account WITH USER_MODE];
        return result;
    }
}