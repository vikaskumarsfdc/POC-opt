import { LightningElement, track } from 'lwc';
import searchAccounts from '@salesforce/apex/AccountSearchController.searchAccounts';
import getRelatedContacts from '@salesforce/apex/AccountSearchController.getRelatedContacts';

export default class AccountSearch extends LightningElement {

    @track searchTerm = '';
    @track accounts = [];
    @track contacts = [];
    @track selectedAccount = '';

    columns = [
        { label: 'Name',  fieldName: 'Name' },
        { label: 'Email', fieldName: 'Email' },
        { label: 'Phone', fieldName: 'Phone' }
    ];

    // Debounce timer
    timer;

    handleSearch(event) {
        this.searchTerm = event.target.value;

        // Debounce — don't fire on every keystroke
        clearTimeout(this.timer);
        this.timer = setTimeout(() => {
            if (this.searchTerm.length >= 2) {
                searchAccounts({ searchTerm: this.searchTerm })
                    .then(result => { this.accounts = result; })
                    .catch(error => { console.error(error); });
            } else {
                this.accounts = [];
            }
        }, 300);
    }

    handleAccountSelect(event) {
        const accountId   = event.currentTarget.dataset.id;
        const accountName = event.currentTarget.dataset.name;

        this.selectedAccount = accountName;
        this.accounts = []; // close dropdown

        getRelatedContacts({ accountId: accountId })
            .then(result => { this.contacts = result; })
            .catch(error => { console.error(error); });
    }
}