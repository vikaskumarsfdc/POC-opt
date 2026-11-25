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
public with sharing class OtpIssueService {

    public class IssueRequest {
        @InvocableVariable(required=true)
        public Id contactId;
    }

    public class IssueResult {
        @InvocableVariable
        public Boolean isSent;
        @InvocableVariable
        public String message;
    }

    /**
     * Generates + emails OTP. Output list is ALWAYS 1:1 with input (fix #3).
     */
    @InvocableMethod(label='Issue OTP')
    public static List<IssueResult> issueOtp(List<IssueRequest> reqs) {
        List<IssueResult> out = new List<IssueResult>();
        if (reqs == null || reqs.isEmpty()) {
            return out;
        }
        if (!canReadContactEmail() || !canUpdateOtpFields()) {
            return fill(reqs.size(), 'No access to Contact OTP fields');
        }

        Map<Id, Contact> cons = getContacts(collectIds(reqs));
        Map<Id, Contact> toUpdate = new Map<Id, Contact>(); // keyed by Id => no dup crash (fix #1)
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Integer> mailIdx = new List<Integer>(); // mail -> result index
        Set<Id> seen = new Set<Id>();

        for (Integer i = 0; i < reqs.size(); i++) {
            IssueRequest r = reqs[i];
            if (r == null || r.contactId == null) {
                out.add(res(false, 'contactId missing'));
                continue;
            }
            Contact c = cons.get(r.contactId);
            if (c == null) {
                out.add(res(false, 'Contact not found or no access'));
                continue;
            }
            if (!seen.add(r.contactId)) {
                out.add(res(false, 'Duplicate request ignored'));
                continue;
            }
            if (String.isBlank(c.Email)) { // fix #2
                out.add(res(false, 'Contact has no email'));
                continue;
            }

            String otp = OtpConfig.newOtp();
            toUpdate.put(c.Id, new Contact(
                Id = c.Id,
                OTP_Hash__c = OtpConfig.hash(c.Id, otp),
                OTP_Generated_Time__c = System.now(),
                OTP_Attempts__c = 0
            ));
            mails.add(buildMail(c.Email, otp));
            mailIdx.add(i);
            out.add(res(false, 'Pending'));
        }

        if (toUpdate.isEmpty()) {
            return out;
        }

        try {
            update as user toUpdate.values();
        } catch (DmlException e) {
            for (Integer i : mailIdx) {
                out[i].message = 'Could not save OTP: ' + e.getMessage();
            }
            return out;
        }

        // fix #10: status sirf real send result ke baad set hota hai
        List<Messaging.SendEmailResult> sent = Messaging.sendEmail(mails, false);
        for (Integer k = 0; k < sent.size(); k++) {
            IssueResult target = out[mailIdx[k]];
            if (sent[k].isSuccess()) {
                target.isSent = true;
                target.message = 'OTP sent';
            } else {
                target.message = 'Email failed: ' + sent[k].getErrors()[0].getMessage();
            }
        }
        return out;
    }

    private static Messaging.SingleEmailMessage buildMail(String toAddress, String otp) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { toAddress });
        mail.setSubject('Your Verification OTP');
        mail.setPlainTextBody(
            'Your OTP is ' + otp + '. Valid ' + OtpConfig.VALIDITY_MINUTES + ' minutes.'
        );
        return mail;
    }

    private static Set<Id> collectIds(List<IssueRequest> reqs) {
        Set<Id> ids = new Set<Id>();
        for (IssueRequest r : reqs) {
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
            SELECT Email FROM Contact WHERE Id IN :ids WITH USER_MODE
        ]);
    }

    private static Boolean canReadContactEmail() {
        return Schema.sObjectType.Contact.isAccessible()
            && Schema.sObjectType.Contact.fields.Email.isAccessible();
    }

    private static Boolean canUpdateOtpFields() {
        return Schema.sObjectType.Contact.isUpdateable()
            && Schema.sObjectType.Contact.fields.OTP_Hash__c.isUpdateable()
            && Schema.sObjectType.Contact.fields.OTP_Generated_Time__c.isUpdateable()
            && Schema.sObjectType.Contact.fields.OTP_Attempts__c.isUpdateable();
    }

    private static IssueResult res(Boolean ok, String msg) {
        IssueResult r = new IssueResult();
        r.isSent = ok;
        r.message = msg;
        return r;
    }

    private static List<IssueResult> fill(Integer n, String msg) {
        List<IssueResult> out = new List<IssueResult>();
        for (Integer i = 0; i < n; i++) {
            out.add(res(false, msg));
        }
        return out;
    }
}
