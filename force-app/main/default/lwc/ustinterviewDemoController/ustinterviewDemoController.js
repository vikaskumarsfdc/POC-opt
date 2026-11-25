import { LightningElement, wire } from 'lwc';
import getAcc from '@salesforce/apex/UstinterviewDemoController.getAcc';

const ACCSDATA = [
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Rating', fieldName: 'Rating', type: 'text' },
    { label: 'Phone', fieldName: 'Phone', type: 'Phone' }
];

export default class UstinterviewDemoController extends LightningElement {
    accCols = ACCSDATA;
   @wire(getAcc)accs;
}