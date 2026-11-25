import { LightningElement, wire } from 'lwc';
import getCases from '@salesforce/apex/CaseController.getCases';
import closeCase from '@salesforce/apex/CaseController.closeCase';
import { refreshApex } from '@salesforce/apex';

export default class CaseCloser extends LightningElement {
    cases; selectedId; wiredData;

    @wire(getCases)
    wired(result){
        this.wiredData = result;
        this.cases = result.data;
    }

    select(e){ this.selectedId = e.target.value; }

    close(){
        if(!this.selectedId) return;
        closeCase({caseId:this.selectedId})
        .then(()=>refreshApex(this.wiredData));
    }
}