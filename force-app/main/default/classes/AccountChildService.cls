public with sharing class AccountChildService {

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        return [SELECT Id, Name FROM Account LIMIT 50];
    }

    @AuraEnabled
    public static Map<String, List<Map<String, Object>>> getAccountWithChildren(Id accountId) {

        Map<String, List<Map<String, Object>>> result = new Map<String, List<Map<String, Object>>>();

        Schema.DescribeSObjectResult describe = Account.SObjectType.getDescribe();
        List<Schema.ChildRelationship> childRels = describe.getChildRelationships();

        for (Schema.ChildRelationship rel : childRels) {

            if (rel.getField() == null) continue;

            String childObject = rel.getChildSObject().getDescribe().getName();
            String fieldName = rel.getField().getDescribe().getName();

            try {
                String query = 'SELECT Id, Name FROM ' + childObject +
                               ' WHERE ' + fieldName + ' = :accountId LIMIT 50';

                List<SObject> records = Database.query(query);

                if (!records.isEmpty()) {
                    List<Map<String, Object>> formatted = new List<Map<String, Object>>();

                    for (SObject rec : records) {
                        Map<String, Object> row = new Map<String, Object>();
                        row.put('Id', rec.get('Id'));
                        row.put('Name', rec.get('Name'));
                        formatted.add(row);
                    }

                    result.put(childObject, formatted);
                }

            } catch (Exception e) {
                // skip objects without access or Name field
            }
        }

        return result;
    }
}