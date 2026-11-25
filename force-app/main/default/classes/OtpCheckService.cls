/*
Contact c = new Contact(LastName='YOUReMAIL@gmail.com', Email='YOUReMAIL@gmail.com');
insert c;
OtpIssueService.IssueRequest req = new OtpIssueService.IssueRequest();
req.contactId = c.Id;
System.debug('CONTACT ID = ' + c.Id);
System.debug(JSON.serializePretty(OtpIssueService.issueOtp(new List<OtpIssueService.IssueRequest>{ req })));




OtpCheckService.CheckRequest v = new OtpCheckService.CheckRequest();
v.contactId = '003NS00002nvGUDYA2';
v.enteredOtp = '796968';
System.debug(JSON.serializePretty(OtpCheckService.checkOtp(new List<OtpCheckService.CheckRequest>{ v })));




Contact c = [SELECT Id FROM Contact WHERE Email = 'YOUReMAIL@gmail.com' ORDER BY CreatedDate DESC LIMIT 1];
OtpIssueService.IssueRequest req = new OtpIssueService.IssueRequest();
req.contactId = c.Id;
System.debug('CONTACT ID = ' + c.Id);
System.debug(JSON.serializePretty(OtpIssueService.issueOtp(new List<OtpIssueService.IssueRequest>{ req })));

for (Contact c : [SELECT Id, Email, OTP_Hash__c, OTP_Generated_Time__c, OTP_Attempts__c
                  FROM Contact WHERE OTP_Generated_Time__c != null
                  ORDER BY OTP_Generated_Time__c DESC LIMIT 5]) {
    System.debug(c.Id + ' | ' + c.Email + ' | hashSet=' + (c.OTP_Hash__c != null)
        + ' | ' + c.OTP_Generated_Time__c + ' | attempts=' + c.OTP_Attempts__c);
}



 */
public with sharing class OtpCheckService {

    public class CheckRequest {
        @InvocableVariable(required=true)
        public Id contactId;
        @InvocableVariable(required=true)
        public String enteredOtp;
    }

    public class CheckResult {
        @InvocableVariable
        public Boolean isValid;
        @InvocableVariable
        public String message;
    }

    /**
     * Verifies OTP. Output ALWAYS 1:1 with input.
     * Success => OTP cleared (fix #5). Wrong => attempts++ (fix #6).
     */
    @InvocableMethod(label='Check OTP')
    public static List<CheckResult> checkOtp(List<CheckRequest> reqs) {
        List<CheckResult> out = new List<CheckResult>();
        if (reqs == null || reqs.isEmpty()) {
            return out;
        }
        if (!canReadOtpFields() || !canUpdateOtpFields()) {
            return fill(reqs.size(), 'No access to Contact OTP fields');
        }

        Map<Id, Contact> cons = getContacts(collectIds(reqs));
        Map<Id, Contact> changed = new Map<Id, Contact>();

        for (CheckRequest r : reqs) {
            out.add(evaluate(r, cons, changed));
        }

        if (!changed.isEmpty()) {
            try {
                update as user changed.values();
            } catch (DmlException e) {
                // state save nahi hua => kisi ko valid mat bolo (replay risk)
                return fill(reqs.size(), 'Could not save OTP state');
            }
        }
        return out;
    }

    private static CheckResult evaluate(
        CheckRequest r, Map<Id, Contact> cons, Map<Id, Contact> changed
    ) {
        if (r == null || r.contactId == null || String.isBlank(r.enteredOtp)) {
            return res(false, 'Invalid input');
        }
        Contact c = cons.get(r.contactId);
        if (c == null) {
            return res(false, 'Contact not found');
        }
        if (String.isBlank(c.OTP_Hash__c) || c.OTP_Generated_Time__c == null) {
            return res(false, 'No active OTP');
        }
        Integer attempts = c.OTP_Attempts__c == null ? 0 : c.OTP_Attempts__c.intValue();
        if (attempts >= OtpConfig.MAX_ATTEMPTS) {
            return res(false, 'Too many attempts. Request a new OTP');
        }
        if (c.OTP_Generated_Time__c.addMinutes(OtpConfig.VALIDITY_MINUTES) <= System.now()) {
            return res(false, 'OTP expired');
        }

        String entered = r.enteredOtp.trim(); // fix #8
        if (OtpConfig.hash(c.Id, entered) == c.OTP_Hash__c) {
            c.OTP_Hash__c = null;
            c.OTP_Generated_Time__c = null;
            c.OTP_Attempts__c = 0;
            changed.put(c.Id, c);
            return res(true, 'Verified');
        }

        c.OTP_Attempts__c = attempts + 1; // in-place => same-txn duplicates bhi count honge
        changed.put(c.Id, c);
        return res(false, 'Incorrect OTP');
    }

    private static Set<Id> collectIds(List<CheckRequest> reqs) {
        Set<Id> ids = new Set<Id>();
        for (CheckRequest r : reqs) {
            if (r != null && r.contactId != null) {
                ids.add(r.contactId);
            }
        }
        return ids;
    }

    private static Map<Id, Contact> getContacts(Set<Id> ids) {
        if (ids.isEmpty()) {
            return new Map<Id, Contact>();
        }
        return new Map<Id, Contact>([
            SELECT OTP_Hash__c, OTP_Generated_Time__c, OTP_Attempts__c
            FROM Contact WHERE Id IN :ids WITH USER_MODE
        ]);
    }

    private static Boolean canReadOtpFields() {
        return Schema.sObjectType.Contact.isAccessible()
            && Schema.sObjectType.Contact.fields.OTP_Hash__c.isAccessible()
            && Schema.sObjectType.Contact.fields.OTP_Generated_Time__c.isAccessible()
            && Schema.sObjectType.Contact.fields.OTP_Attempts__c.isAccessible();
    }

    private static Boolean canUpdateOtpFields() {
        return Schema.sObjectType.Contact.isUpdateable()
            && Schema.sObjectType.Contact.fields.OTP_Hash__c.isUpdateable()
            && Schema.sObjectType.Contact.fields.OTP_Generated_Time__c.isUpdateable()
            && Schema.sObjectType.Contact.fields.OTP_Attempts__c.isUpdateable();
    }

    private static CheckResult res(Boolean ok, String msg) {
        CheckResult r = new CheckResult();
        r.isValid = ok;
        r.message = msg;
        return r;
    }

    private static List<CheckResult> fill(Integer n, String msg) {
        List<CheckResult> out = new List<CheckResult>();
        for (Integer i = 0; i < n; i++) {
            out.add(res(false, msg));
        }
        return out;
    }
}
