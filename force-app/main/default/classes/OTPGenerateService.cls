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


public with sharing class OTPGenerateService {
    /**
     * Input payload for generating an OTP.
     */
    public class GenRequest {
        @InvocableVariable(required=true)
        public Id contactId;
    }

    /**
     * Output payload for OTP generation.
     */
    public class GenResult {
        @InvocableVariable
        public String message;
    }

    private class OTPGenerationContext {
        Map<Id, Contact> contacts;
        List<Contact> toUpdate = new List<Contact>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<GenResult> results;
    }

    /**
     * Generates an OTP for the provided contacts and emails it.
     * @param reqs List of contact requests.
     * @return List of generation results.
     */
    @InvocableMethod(label='Generate OTP')
    public static List<GenResult> generateOTP(List<GenRequest> reqs) {
        List<GenResult> out = new List<GenResult>();
        if (reqs == null || reqs.isEmpty()) {
            return out;
        }

        Set<Id> ids = collectContactIds(reqs);
        if (ids.isEmpty()) {
            return out;
        }

        if (!canReadContactEmail()) {
            return out;
        }

        Map<Id, Contact> cons = getContacts(ids);
        OTPGenerationContext context = new OTPGenerationContext();
        context.contacts = cons;
        context.results = out;
        addOTPUpdatesAndEmails(reqs, context);

        if (!context.toUpdate.isEmpty()) {
            if (!canUpdateContactOTP()) {
                return out;
            }
            update as user context.toUpdate;
        }

        if (!context.mails.isEmpty()) {
            Messaging.sendEmail(context.mails);
        }

        return out;
    }

    private static Set<Id> collectContactIds(List<GenRequest> reqs) {
        Set<Id> ids = new Set<Id>();
        for (GenRequest r : reqs) {
            if (r != null && r.contactId != null) {
                ids.add(r.contactId);
            }
        }
        return ids;
    }

    private static Boolean canReadContactEmail() {
        return Schema.sObjectType.Contact.isAccessible()
            && Schema.sObjectType.Contact.fields.Email.isAccessible();
    }

    private static Map<Id, Contact> getContacts(Set<Id> ids) {
        return new Map<Id, Contact>([
            SELECT Email
            FROM Contact
            WHERE Id IN :ids
            WITH USER_MODE
        ]);
    }

    private static void addOTPUpdatesAndEmails(
        List<GenRequest> reqs,
        OTPGenerationContext context
    ) {
        for (GenRequest r : reqs) {
            if (r == null || r.contactId == null || !context.contacts.containsKey(r.contactId)) {
                continue;
            }

            String otp = String.valueOf(100000 + Math.round(Math.random() * 899999));
            context.toUpdate.add(new Contact(
                Id = r.contactId,
                OTP__c = otp,
                OTP_Generated_Time__c = System.now()
            ));

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { context.contacts.get(r.contactId).Email });
            mail.setSubject('Your Verification OTP');
            mail.setPlainTextBody('Your OTP is ' + otp + '. Valid 5 minutes.');
            context.mails.add(mail);

            GenResult res = new GenResult();
            res.message = 'OTP sent';
            context.results.add(res);
        }
    }

    private static Boolean canUpdateContactOTP() {
        return Schema.sObjectType.Contact.isUpdateable()
            && Schema.sObjectType.Contact.fields.OTP__c.isUpdateable()
            && Schema.sObjectType.Contact.fields.OTP_Generated_Time__c.isUpdateable();
    }
}