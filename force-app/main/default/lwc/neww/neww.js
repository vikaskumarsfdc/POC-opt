import { LightningElement,wire } from 'lwc';
import getAccount from '@salesforce/apex/NewwController.getAccount';
import getContact from '@salesforce/apex/NewwController.getContact';

const colls=[
    {label:"LastName",fieldName:"LastName",type:"text"},
    {label:"Email",fieldName:"Email",type:"Email"}

];

export default class Neww extends LightningElement {
contacts;
_contacts=colls;

@wire(getAccount) accs;

get accountOptions(){
    return this.accs.data?
           this.accs.data.map(a=>({
            label:a.Name,
            value:a.Id}))
           :[];
}

accountChange(event){
    const accId=event.target.value;
    getContact({accountId:accId}).then(data=>this.contacts=data);   
}

}