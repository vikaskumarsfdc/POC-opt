import { LightningElement,wire } from 'lwc';
import getaccounts from '@salesforce/apex/accController.getaccounts';
import getcontacts from '@salesforce/apex/accController.getcontacts';
import getopportunities from '@salesforce/apex/accController.getopportunities';

const CONTCS=[
    {label:'LastName', fieldName:'LastName',type:'text'},
    {label:'Email', fieldName:'Email',type:'Email'}
];



const OPPS = [
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Stage', fieldName: 'StageName', type: 'text' },
    { label: 'Close Date', fieldName: 'CloseDate', type: 'date' }
];


export default class Acc extends LightningElement {

    _contacts=CONTCS;
    _opportunities=OPPS;

    contacts; opportunities;

    @wire(getaccounts) accs ; 
   
    get accOption(){
       return this.accs.data?
            this.accs.data.map(a=>({label:a.Name,Value:a.Id})) : [];
    }

    accountevent(event){
        const accId=event.detail.value;
        getcontacts({accountId:accId})
        .then(data => this.contacts = data);

        getopportunities({accountId:accId})
        .then(data=>this.opportunities=data);
        
    }

}