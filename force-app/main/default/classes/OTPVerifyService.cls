/*
FOR TESTING:

STEP1.
Contact c = new Contact(LastName='auralwc2021@gmail.com', Email='auralwc2021@gmail.com');
insert c;
OTPGenerateService.GenRequest req = new OTPGenerateService.GenRequest();
req.contactId = c.Id;
OTPGenerateService.generateOTP(new List<OTPGenerateService.GenRequest>{req});

 STEP2. Copr Opt from email

step 3. paste contactId and OTP
OTPVerifyService.VerifyRequest v = new OTPVerifyService.VerifyRequest();
v.contactId = '003NS00002nuosvYAA';
v.enteredOTP = '495250';
System.debug(OTPVerifyService.verifyOTP(new List<OTPVerifyService.VerifyRequest>{v}));


*/ 



public with sharing class OTPVerifyService {
    /**
     * Represents an OTP verification request received from an invocable action.
     */
    public class VerifyRequest {
        @InvocableVariable(required=true)
        public Id contactId;
        @InvocableVariable(required=true)
        public String enteredOTP;
    }

    /**
     * Represents the result of an OTP verification attempt.
     */
    public class VerifyResult {
        @InvocableVariable
        public Boolean isValid;
    }

    /**
     * Verifies the entered OTP against the stored OTP for each contact.
     * @param reqs List of verification requests.
     * @return List of verification results (false for any invalid/inaccessible/not-found input).
     */
    @InvocableMethod(label='Verify OTP')
    public static List<VerifyResult> verifyOTP(List<VerifyRequest> reqs) {
        List<VerifyResult> out = new List<VerifyResult>();
        if (reqs == null || reqs.isEmpty()) {
            return out;
        }

        Set<Id> ids = collectContactIds(reqs);
        if (ids.isEmpty() || !canReadOTPFields()) {
            return defaultInvalidResults(reqs);
        }

        Map<Id, Contact> cons = getContacts(ids);

        for (VerifyRequest r : reqs) {
            VerifyResult res = new VerifyResult();
            res.isValid = isOTPValid(r, cons);
            out.add(res);
        }
        return out;
    }

    private static Set<Id> collectContactIds(List<VerifyRequest> reqs) {
        Set<Id> ids = new Set<Id>();
        for (VerifyRequest r : reqs) {
            if (r != null && r.contactId != null) {
                ids.add(r.contactId);
            }
        }
        return ids;
    }

    private static Boolean canReadOTPFields() {
        return Schema.sObjectType.Contact.isAccessible()
            && Schema.sObjectType.Contact.fields.OTP__c.isAccessible()
            && Schema.sObjectType.Contact.fields.OTP_Generated_Time__c.isAccessible();
    }

    private static Map<Id, Contact> getContacts(Set<Id> ids) {
        return new Map<Id, Contact>([
            SELECT OTP__c, OTP_Generated_Time__c
            FROM Contact
            WHERE Id IN :ids
            WITH USER_MODE
        ]);
    }

    private static Boolean isOTPValid(VerifyRequest r, Map<Id, Contact> cons) {
        if (r == null || r.contactId == null || String.isBlank(r.enteredOTP) || !cons.containsKey(r.contactId)) {
            return false;
        }
        Contact c = cons.get(r.contactId);
        Boolean notExpired = c.OTP_Generated_Time__c != null && c.OTP_Generated_Time__c.addMinutes(5) > System.now();
        return notExpired && c.OTP__c == r.enteredOTP;
    }

    private static List<VerifyResult> defaultInvalidResults(List<VerifyRequest> reqs) {
        List<VerifyResult> out = new List<VerifyResult>();
        for (VerifyRequest r : reqs) {
            VerifyResult res = new VerifyResult();
            res.isValid = false;
            out.add(res);
        }
        return out;
    }
}