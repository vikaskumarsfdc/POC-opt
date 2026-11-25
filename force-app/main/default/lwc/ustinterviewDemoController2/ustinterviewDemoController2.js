import { LightningElement, wire } from 'lwc';
import getAcc from '@salesforce/apex/UstinterviewDemoController.getAcc';
import getContacts from '@salesforce/apex/UstinterviewDemoController.getContacts';

const ACCSDATA = [
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Rating', fieldName: 'Rating', type: 'text' },
    { label: 'Phone', fieldName: 'Phone', type: 'phone' }
];
const CONDATA = [
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Email', fieldName: 'Email', type: 'email' },
    { label: 'Phone', fieldName: 'Phone', type: 'phone' }
];

export default class UstinterviewDemoController2 extends LightningElement {
    accCols = ACCSDATA;
    conCols = CONDATA;
    selectedAccId;
    contacts;

    @wire(getAcc) accs;

    get accOptions() {
        return this.accs.data
            ? this.accs.data.map(a => ({ label: a.Name, value: a.Id }))
            : [];
    }

    handleAccChange(event) {
        this.selectedAccId = event.detail.value;
        getContacts({ accountId: this.selectedAccId })
            .then(data => this.contacts = data);
    }
}