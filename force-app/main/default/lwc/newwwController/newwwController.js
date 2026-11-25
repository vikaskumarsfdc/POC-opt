import { LightningElement,wire } from 'lwc';
import getAccounts from '@salesforce/apex/NewwwController.getAccounts';
import getContacts from '@salesforce/apex/NewwwController.getContacts';


const colls=[
    {label:"LastName", fieldName:"LastName" ,type:"text"},
    {label:"Email", fieldName:"Email" ,type:"Email"}

];
export default class NewwwController extends LightningElement {
    _contacts=colls;
    contacts;

    @wire(getAccounts) accs;

    get accOptions(){
        return this.accs.data?
               this.accs.data.map(a=>({
                label:a.Name,value:a.Id
               })):[];
    }

    acconchange(event){
        const accId=event.detail.value;
        getContacts({accountId:accId}).then(data=>this.contacts=data);   
            
    }
}