import { LightningElement, wire, track } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import getAccounts from '@salesforce/apex/AccountContactController.getAccounts';

export default class AccountChildLDS extends LightningElement {

    @track accountOptions = [];
    @track selectedId;
    @track contacts = [];
    @track opportunities = [];

    contactCols = [
        { label: 'First Name', fieldName: 'Fields.FirstName.value' },
        { label: 'Last Name',  fieldName: 'Fields.LastName.value'  },
        { label: 'Email',      fieldName: 'Fields.Email.value'     }
    ];

    oppCols = [
        { label: 'Name',   fieldName: 'Fields.Name.value'      },
        { label: 'Stage',  fieldName: 'Fields.StageName.value' },
        { label: 'Amount', fieldName: 'Fields.Amount.value'    }
    ];

    // Sirf accounts ke liye ek chota apex method chahiye dropdown ke liye
    @wire(getAccounts)
    wired({ data }) {
        if (data) this.accountOptions = data.map(a => ({ label: a.Name, value: a.Id }));
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$selectedId',
        relatedListId: 'Contacts',
        fields: ['Contact.FirstName', 'Contact.LastName', 'Contact.Email']
    })
    wiredContacts({ data }) {
        if (data) this.contacts = data.records.map(r => ({
            Id:        r.id,
            FirstName: r.fields.FirstName.value,
            LastName:  r.fields.LastName.value,
            Email:     r.fields.Email.value
        }));
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$selectedId',
        relatedListId: 'Opportunities',
        fields: ['Opportunity.Name', 'Opportunity.StageName', 'Opportunity.Amount']
    })
    wiredOpps({ data }) {
        if (data) this.opportunities = data.records.map(r => ({
            Id:        r.id,
            Name:      r.fields.Name.value,
            StageName: r.fields.StageName.value,
            Amount:    r.fields.Amount.value
        }));
    }

    handleChange({ detail: { value } }) {
        this.selectedId = value;
    }
}