public with sharing class AccountChildRecordsController {

    // ─── 1. Fetch all Accounts for dropdown ───────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        return [
            SELECT Id, Name
            FROM Account
            ORDER BY Name ASC
            LIMIT 200
        ];
    }

    // ─── 2. Dynamically fetch ALL child records for a given Account ───────────
    //  → Uses Schema.getChildRelationships() — zero hardcoding of object names.
    //  → Any child object added in future (custom or standard) auto-appears.
    //  → Returns ONLY those child objects that have ≥1 record for this Account.
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getChildRecords(Id accountId) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        // Introspect all child relationships on Account via Schema
        List<Schema.ChildRelationship> childRelationships =
            Schema.SObjectType.Account.getChildRelationships();

        for (Schema.ChildRelationship rel : childRelationships) {

            Schema.SObjectType      childSObjectType = rel.getChildSObject();
            Schema.DescribeSObjectResult childDescribe = childSObjectType.getDescribe();

            // Skip: non-queryable, inaccessible, or deprecated objects
            if (!childDescribe.isQueryable()
                || !childDescribe.isAccessible()
                || childDescribe.isDeprecatedAndHidden()) {
                continue;
            }

            String childObjectApiName = childDescribe.getName();
            String relationshipField  = String.valueOf(rel.getField());

            try {
                // Dynamically decide which fields to SELECT
                List<String> selectFields = buildFieldList(childSObjectType);

                // Dynamic SOQL — fully runtime, no compile-time dependency
                String soql = 'SELECT '  + String.join(selectFields, ', ')
                            + ' FROM '   + childObjectApiName
                            + ' WHERE '  + relationshipField + ' = :accountId'
                            + ' LIMIT 50';

                List<SObject> records = Database.query(soql);

                // ✅ Only include child objects that actually have records
                if (records.isEmpty()) continue;

                // Convert SObject list → serializable Map list for LWC
                List<Map<String, Object>> serializedRecords = new List<Map<String, Object>>();
                for (SObject rec : records) {
                    Map<String, Object> recMap = new Map<String, Object>();
                    for (String field : selectFields) {
                        recMap.put(field, rec.get(field));
                    }
                    serializedRecords.add(recMap);
                }

                // Build datatable column metadata dynamically
                List<Map<String, Object>> columns = buildColumns(childSObjectType, selectFields);

                // Package everything into one section per child object
                Map<String, Object> section = new Map<String, Object>();
                section.put('objectApiName', childObjectApiName);
                section.put('label',         childDescribe.getLabel());
                section.put('labelPlural',   childDescribe.getLabelPlural());
                section.put('records',       serializedRecords);
                section.put('columns',       columns);
                section.put('count',         serializedRecords.size());

                result.add(section);

            } catch (Exception e) {
                // Silently skip objects that throw security / query exceptions
                continue;
            }
        }

        return result;
    }

    // ─── Helper: Pick the most meaningful accessible fields for any SObject ───
    private static List<String> buildFieldList(Schema.SObjectType objType) {
        List<String> fields = new List<String>{ 'Id' };
        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();

        // Priority order — first match wins up to maxFields
        List<String> preferredFields = new List<String>{
            'Name', 'Subject', 'CaseNumber', 'Title',
            'Status', 'StageName', 'Email', 'Phone',
            'Amount', 'CloseDate', 'Priority', 'Type', 'LeadSource'
        };

        Integer maxFields = 7; // Id + up to 6 descriptive fields
        for (String preferred : preferredFields) {
            if (fields.size() >= maxFields) break;
            String fieldKey = preferred.toLowerCase();
            if (fieldMap.containsKey(fieldKey)) {
                Schema.DescribeFieldResult dfr = fieldMap.get(fieldKey).getDescribe();
                if (dfr.isAccessible() && !dfr.isEncrypted()) {
                    fields.add(preferred);
                }
            }
        }
        return fields;
    }

    // ─── Helper: Build lightning-datatable column definitions dynamically ─────
    private static List<Map<String, Object>> buildColumns(
        Schema.SObjectType objType,
        List<String> fields
    ) {
        List<Map<String, Object>> columns = new List<Map<String, Object>>();
        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();

        for (String fieldName : fields) {
            if (fieldName == 'Id') continue;
            String fieldKey = fieldName.toLowerCase();
            if (!fieldMap.containsKey(fieldKey)) continue;

            Schema.DescribeFieldResult dfr = fieldMap.get(fieldKey).getDescribe();
            Schema.DisplayType dt = dfr.getType();

            Map<String, Object> col = new Map<String, Object>();
            col.put('label',     dfr.getLabel());
            col.put('fieldName', fieldName);

            // Salesforce DisplayType → LWC datatable column type
            if      (dt == Schema.DisplayType.EMAIL)                              { col.put('type', 'email'); }
            else if (dt == Schema.DisplayType.PHONE)                              { col.put('type', 'phone'); }
            else if (dt == Schema.DisplayType.URL)                                { col.put('type', 'url'); }
            else if (dt == Schema.DisplayType.CURRENCY)                           { col.put('type', 'currency'); }
            else if (dt == Schema.DisplayType.DATE || dt == Schema.DisplayType.DATETIME) { col.put('type', 'date'); }
            else if (dt == Schema.DisplayType.BOOLEAN)                            { col.put('type', 'boolean'); }
            else if (dt == Schema.DisplayType.INTEGER
                  || dt == Schema.DisplayType.DOUBLE
                  || dt == Schema.DisplayType.LONG)                               { col.put('type', 'number'); }
            else                                                                  { col.put('type', 'text'); }

            columns.add(col);
        }
        return columns;
    }
}