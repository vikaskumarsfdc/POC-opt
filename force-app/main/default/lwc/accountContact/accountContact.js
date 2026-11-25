import { LightningElement, wire, track } from 'lwc';
import getAccounts from '@salesforce/apex/AccountContactController.getAccounts';
import getContacts from '@salesforce/apex/AccountContactController.getContacts';

export default class AccountContact extends LightningElement {

    @track accountOptions = [];
    @track contacts = [];
    selectedId;

    cols = [
        { label: 'First Name', fieldName: 'FirstName' },
        { label: 'Last Name',  fieldName: 'LastName'  },
        { label: 'Email',      fieldName: 'Email', type: 'email' }
    ];

    @wire(getAccounts)
    wired({ data }) {
        if (data) this.accountOptions = data.map(a => ({ label: a.Name, value: a.Id }));
    }

    handleChange({ detail: { value } }) {
        this.selectedId = value;
        getContacts({ accountId: value })
            .then(result => { this.contacts = result; })
            .catch(error => { console.error(error); });
    }
}