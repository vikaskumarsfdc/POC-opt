import { LightningElement, wire, track } from 'lwc';
import getAccounts from '@salesforce/apex/ustinterviewwControllerr.getAccounts';
import getChildRecords from '@salesforce/apex/ustinterviewwControllerr.getChildRecords';

export default class Ustinterviewww extends LightningElement {

    @track selectedAccountId; contacts = []; opportunities = [];
    @track accountOptions = [];

    contactColumns = [
        { label: 'First Name', fieldName: 'FirstName' },
        { label: 'Last Name',  fieldName: 'LastName'  },
        { label: 'Email',      fieldName: 'Email', type: 'email' }
    ];
    oppColumns = [
        { label: 'Name',       fieldName: 'Name'      },
        { label: 'Stage',      fieldName: 'StageName' },
        { label: 'Amount',     fieldName: 'Amount',    type: 'currency' },
        { label: 'Close Date', fieldName: 'CloseDate', type: 'date'     }
    ];

    @wire(getAccounts)
    wiredAccounts({ data }) {
        if (data) this.accountOptions = data.map(a => ({ label: a.Name, value: a.Id }));
    }

    handleAccountChange({ detail: { value } }) {
        this.selectedAccountId = value;
        getChildRecords({ accountId: value })
            .then(r => { this.contacts = r.contacts || []; this.opportunities = r.opportunities || []; })
            .catch(e => console.error(e));
    }

    get noRecords() {
        return this.selectedAccountId && !this.contacts.length && !this.opportunities.length;
    }
}