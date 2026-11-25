import { LightningElement,wire } from 'lwc';
import getcon from '@salesforce/apex/ustinterviewwController.getcon';

const COLLLM=[

    {label:'First Name' , fieldName:'FirstName'},
    {label:'Last Name' , fieldName:'LastName' , type:'text'},
    {label:'Email' , fieldName:'Email' , type: 'email'}
];

export default class Ustintervieww extends LightningElement {

    columnnn=COLLLM;


 @wire(getcon)vicky;
    
}