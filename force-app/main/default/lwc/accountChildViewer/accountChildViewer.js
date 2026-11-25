import { LightningElement, wire, track } from 'lwc';
import getAccounts from '@salesforce/apex/AccountChildService.getAccounts';
import getAccountWithChildren from '@salesforce/apex/AccountChildService.getAccountWithChildren';

export default class AccountChildViewer extends LightningElement {

    @track accounts = [];
    @track childData = [];
    selectedAccountId;

    // Load Accounts
    @wire(getAccounts)
    wiredAccounts({ data, error }) {
        if (data) {
            this.accounts = data.map(acc => ({
                label: acc.Name,
                value: acc.Id
            }));
        }
    }

    // Handle Dropdown Change
    handleChange(event) {
        this.selectedAccountId = event.detail.value;

        getAccountWithChildren({ accountId: this.selectedAccountId })
            .then(result => {

                // 🔥 IMPORTANT: Convert Map → Array (LWC friendly)
                this.childData = Object.keys(result).map(key => ({
                    objectName: key,
                    records: result[key]
                }));

            })
            .catch(error => {
                console.error('Error:', error);
            });
    }
}