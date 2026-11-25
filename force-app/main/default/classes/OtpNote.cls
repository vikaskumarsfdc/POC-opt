public with sharing class OtpNote {
    public OtpNote() {
/*
        Here's the full flow, from a personal org to one GitHub link. Your classes depend on 3 custom fields on Contact, so those come first.

## Part 1: Get a personal org
1. Sign up for a free Developer Edition org at `developer.salesforce.com/signup`.
2. Log in, then go to **Setup → Deliverability** and set **Access level = All email**. Otherwise `Messaging.sendEmail` won't deliver the OTP.

## Part 2: Create the 3 custom fields on Contact
Go to **Setup → Object Manager → Contact → Fields & Relationships → New**.

| Label | API name | Type |
|---|---|---|
| OTP Hash | `OTP_Hash__c` | Text (64) |
| OTP Generated Time | `OTP_Generated_Time__c` | Date/Time |
| OTP Attempts | `OTP_Attempts__c` | Number (3, 0), default `0` |

On the field-level security step, make sure your profile (System Administrator) has **Visible** and is **not Read-Only**. Your code checks `isUpdateable()` and uses `USER_MODE`, so missing FLS gives "No access to Contact OTP fields".

## Part 3: Set up the project locally
You need [VS Code](https://code.visualstudio.com), [Node.js](https://nodejs.org), [Git](https://git-scm.com) and the Salesforce CLI.

```bash
npm install -g @salesforce/cli
sf project generate -n otp-verification-apex
cd otp-verification-apex
sf org login web -a personal-dev
```

Create these 6 files in `force-app/main/default/classes/`:
- `OtpConfig.cls`, `OtpIssueService.cls`, `OtpCheckService.cls` (paste your code)
- A `.cls-meta.xml` for each, with this identical content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

**Before you save, delete the big `/* ... */` comment block from all 3 files.** It holds your test email, a real Contact Id (`003NS00002nvGUDYA2`) and an OTP. You don't want those in a public repo. Move that testing code into a separate script file (Part 4).

## Part 4: Deploy and test

```bash
sf project deploy start --source-dir force-app -o personal-dev
```

Save the test code as `scripts/apex/otp-test.apex`. Use your own email and run it one block at a time in **Developer Console → Debug → Open Execute Anonymous Window**.

**Block 1: issue an OTP**
```apex
Contact c = new Contact(LastName='Test User', Email='YOUR_EMAIL@gmail.com');
insert c;
OtpIssueService.IssueRequest req = new OtpIssueService.IssueRequest();
req.contactId = c.Id;
System.debug('CONTACT ID = ' + c.Id);
System.debug(JSON.serializePretty(OtpIssueService.issueOtp(new List<OtpIssueService.IssueRequest>{ req })));
```
Expected: `isSent: true`, `OTP sent`. Copy the Contact Id from the debug log (tick **Debug Only** to filter) and check your inbox, including spam.

**Block 2: verify the OTP**
```apex
OtpCheckService.CheckRequest v = new OtpCheckService.CheckRequest();
v.contactId = 'PASTE_CONTACT_ID';
v.enteredOtp = 'PASTE_OTP_FROM_EMAIL';
System.debug(JSON.serializePretty(OtpCheckService.checkOtp(new List<OtpCheckService.CheckRequest>{ v })));
```

**Block 3: inspect state**
```apex
for (Contact c : [SELECT Id, Email, OTP_Hash__c, OTP_Generated_Time__c, OTP_Attempts__c
                  FROM Contact WHERE OTP_Generated_Time__c != null
                  ORDER BY OTP_Generated_Time__c DESC LIMIT 5]) {
    System.debug(c.Id + ' | hashSet=' + (c.OTP_Hash__c != null) + ' | ' + c.OTP_Generated_Time__c + ' | attempts=' + c.OTP_Attempts__c);
}
```

Cases to check:
- **Correct OTP:** `Verified`, and the hash is cleared. Running it again gives `No active OTP`, so replay is blocked.
- **Wrong OTP:** `Incorrect OTP`, and attempts goes up each time.
- **5 wrong tries:** `Too many attempts. Request a new OTP`.
- **Wait 5+ minutes:** `OTP expired`.
- **Contact without an email:** `Contact has no email`.

## Part 5: Pull the fields into the repo
So the repo is complete when someone else clones it, retrieve your 3 fields:

```bash
sf project retrieve start -m CustomField:Contact.OTP_Hash__c -m CustomField:Contact.OTP_Generated_Time__c -m CustomField:Contact.OTP_Attempts__c -o personal-dev
```

They land in `force-app/main/default/objects/Contact/fields/`.

## Part 6: Push to GitHub (one repo, one link)
1. On github.com, click **New repository** and name it `otp-verification-apex`. Leave it empty, with no README or .gitignore.
2. Add a short `README.md` listing the 3 classes, the 3 fields and the deploy command.
3. Then run:

```bash
git init
git add .
git commit -m "OTP issue and verify Apex services"
git branch -M main
git remote add origin https://github.com/<your-username>/otp-verification-apex.git
git push -u origin main
```

Your single link is `https://github.com/<your-username>/otp-verification-apex`. Anyone can then clone it and run `sf project deploy start --source-dir force-app -o <their-org>`.

## Notes
- **Production deploy:** you'll need an Apex test class with at least 75% coverage. Developer Edition doesn't enforce this, but production does. I can write one for all 3 classes if you want.
- **Email limits:** Developer orgs have low daily email limits, so don't spam-test.
- **Hash field security:** in a real org, hide `OTP_Hash__c` from regular profiles via FLS.
*/   
}
}