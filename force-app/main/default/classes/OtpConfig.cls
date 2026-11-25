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
public with sharing class OtpConfig {
    public static final Integer VALIDITY_MINUTES = 5;
    public static final Integer MAX_ATTEMPTS = 5;

    /** 6-digit OTP using Crypto (fix #4). Leading zeros preserved. */
    public static String newOtp() {
        Integer n = Math.abs(Math.mod(Crypto.getRandomInteger(), 1000000));
        return String.valueOf(1000000 + n).substring(1);
    }

    /** SHA-256 hex (64 chars), salted with contactId (fix #7). */
    public static String hash(Id contactId, String otp) {
        Blob digest = Crypto.generateDigest(
            'SHA-256',
            Blob.valueOf(String.valueOf(contactId) + ':' + otp)
        );
        return EncodingUtil.convertToHex(digest);
    }
}
