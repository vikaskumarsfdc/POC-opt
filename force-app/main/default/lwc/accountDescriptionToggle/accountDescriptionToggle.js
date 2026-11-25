import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import DESCRIPTION_FIELD from '@salesforce/schema/Account.Description';

export default class AccountDescriptionToggle extends LightningElement {
    @api recordId;
    showDescription = false;

    @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD, DESCRIPTION_FIELD] })
    account;

    get accountName() {
        return getFieldValue(this.account.data, NAME_FIELD);
    }

    get accountDescription() {
        return getFieldValue(this.account.data, DESCRIPTION_FIELD) || 'No description available';
    }

    handleToggle(event) {
        this.showDescription = event.target.checked;
    }
}