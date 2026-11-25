import { LightningElement, wire, track } from 'lwc';
import getAccounts from '@salesforce/apex/AccountDynamicController.getAccounts';
import getChildRecords from '@salesforce/apex/AccountDynamicController.getChildRecords';

export default class SmartAccountChild extends LightningElement {

    @track accountOptions = [];
    @track records = [];
    @track columns = [];

    selectedAccountId;
    selectedObject;

    // 🔥 CONFIG — yahi tera power hai
    objectConfig = {
        Contact: {
            fields: 'Id, Name, Email',
            columns: [
                { label: 'Name', fieldName: 'Name' },
                { label: 'Email', fieldName: 'Email' }
            ]
        },
        Opportunity: {
            fields: 'Id, Name, StageName, Amount',
            columns: [
                { label: 'Name', fieldName: 'Name' },
                { label: 'Stage', fieldName: 'StageName' },
                { label: 'Amount', fieldName: 'Amount' }
            ]
        },
        Case: {
            fields: 'Id, CaseNumber, Status',
            columns: [
                { label: 'Case #', fieldName: 'CaseNumber' },
                { label: 'Status', fieldName: 'Status' }
            ]
        }
    };

    get objectOptions() {
        return Object.keys(this.objectConfig).map(key => ({
            label: key,
            value: key
        }));
    }

    @wire(getAccounts)
    wiredAccounts({ data }) {
        if (data) {
            this.accountOptions = data.map(acc => ({
                label: acc.Name,
                value: acc.Id
            }));
        }
    }

    handleAccountChange(event) {
        this.selectedAccountId = event.detail.value;
    }

    handleObjectChange(event) {
        this.selectedObject = event.detail.value;

        let config = this.objectConfig[this.selectedObject];

        this.columns = config.columns;

        getChildRecords({
            accId: this.selectedAccountId,
            objectApiName: this.selectedObject,
            fields: config.fields
        })
        .then(result => {
            this.records = result;
        });
    }
}