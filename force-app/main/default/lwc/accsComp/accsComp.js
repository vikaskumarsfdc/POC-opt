import { LightningElement, wire, track } from 'lwc';
import getAccounts     from '@salesforce/apex/Accs.getAccounts';
import getChildRecords from '@salesforce/apex/Accs.getChildRecords';

const CONTACT_COLS = [
    { label: 'First Name', fieldName: 'FirstName' },
    { label: 'Last Name',  fieldName: 'LastName' },
    { label: 'Email',      fieldName: 'Email', type: 'email' }
];

const OPP_COLS = [
    { label: 'Name',       fieldName: 'Name' },
    { label: 'Stage',      fieldName: 'StageName' },
    { label: 'Amount',     fieldName: 'Amount',   type: 'currency' },
    { label: 'Close Date', fieldName: 'CloseDate', type: 'date' }
];

export default class AccsComp extends LightningElement {

    @track selectedAccountId;
    @track contacts      = [];
    @track opportunities = [];
    @track accountOptions = [];

    contactColumns = CONTACT_COLS;
    oppColumns     = OPP_COLS;

    // Fetch accounts for dropdown
    @wire(getAccounts)
    wiredAccounts({ data, error }) {
        if (data) {
            this.accountOptions = data.map(acc => ({
                label: acc.Name,
                value: acc.Id
            }));
        } else if (error) {
            console.error('Error fetching accounts:', error);
        }
    }

    // On dropdown change — call imperatively (not wire, since input changes)
    handleAccountChange(event) {
        this.selectedAccountId = event.detail.value;
        this.contacts      = [];
        this.opportunities = [];

        getChildRecords({ accountId: this.selectedAccountId })
            .then(result => {
                this.contacts      = result.contacts      || [];
                this.opportunities = result.opportunities || [];
            })
            .catch(error => {
                console.error('Error fetching child records:', error);
            });
    }

    get noRecords() {
        return (
            this.selectedAccountId &&
            this.contacts.length === 0 &&
            this.opportunities.length === 0
        );
    }
}