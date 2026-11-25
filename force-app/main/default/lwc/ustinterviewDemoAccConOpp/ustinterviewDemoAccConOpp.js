import { LightningElement, wire } from 'lwc';
import getAcc from '@salesforce/apex/UstinterviewDemoController.getAcc';
import getContacts from '@salesforce/apex/UstinterviewDemoAccConOppController.getContacts';
import getOpportunities from '@salesforce/apex/UstinterviewDemoAccConOppController.getOpportunities';

const CON_COLS = [
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Email', fieldName: 'Email', type: 'email' },
    { label: 'Phone', fieldName: 'Phone', type: 'phone' }
];
const OPP_COLS = [
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Stage', fieldName: 'StageName', type: 'text' },
    { label: 'Close Date', fieldName: 'CloseDate', type: 'date' }
];

export default class UstinterviewDemoAccConOpp extends LightningElement {
    conCols = CON_COLS;
    oppCols = OPP_COLS;
    contacts;
    opportunities;

    @wire(getAcc) accs;

    get accOptions() {
        return this.accs.data
            ? this.accs.data.map(a => ({ label: a.Name, value: a.Id }))
            : [];
    }

    handleAccChange(event) {
        const accId = event.detail.value;
        getContacts({ accountId: accId })
            .then(data => this.contacts = data);
        getOpportunities({ accountId: accId })
            .then(data => this.opportunities = data);
    }
}