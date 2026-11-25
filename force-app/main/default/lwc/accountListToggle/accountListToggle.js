import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';            // navigate to record pages
import { updateRecord } from 'lightning/uiRecordApi';              // LDS update: respects FLS/sharing, no Apex needed
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; // success/error popups
import getAccounts from '@salesforce/apex/AccountPagingController.getAccounts'; // Apex: paged SOQL

const PAGE_SIZE = 5; // rows per page
const DEBUG = true;  // set false to silence all debug logs

// Central logger. Browser DevTools (F12) > Console > filter by "ACC-LWC".
// JSON.stringify avoids unreadable Proxy objects from LWC reactive data.
const log = (msg, data) => DEBUG && console.log(`[ACC-LWC] ${msg}`, data === undefined ? '' : JSON.stringify(data));

export default class AccountListToggle extends NavigationMixin(LightningElement) {
    // @track = deep reactivity: changing rec.draft / rec.isOpen re-renders the table,
    // so we can mutate a row directly (no need to rebuild the whole array on every keystroke).
    // Row shape: { Id, Name, saved (last saved text), draft (text in textarea), isOpen (toggle) }
    @track records = [];
    pageNumber = 1;      // current page (1-based)
    totalRecords = 0;    // total Accounts, used for "Page X of Y"
    openIds = new Set(); // Ids with toggle ON, remembered while moving between pages

    connectedCallback() {
        log('connectedCallback: loading first page');
        this.loadPage();
    }

    // ---------- Data load ----------
    async loadPage() {
        const page = this.pageNumber; // snapshot, used to detect stale responses
        log('loadPage: requesting', { page, PAGE_SIZE });
        try {
            const { records, totalRecords } = await getAccounts({ pageSize: PAGE_SIZE, pageNumber: page });

            // Guard: if user clicked Next/Prev quickly, an older response must not overwrite the newer page
            if (page !== this.pageNumber) {
                log('loadPage: stale response ignored', { page, current: this.pageNumber });
                return;
            }
            log('loadPage: Apex returned', { count: records.length, totalRecords });

            this.totalRecords = totalRecords;
            this.records = records.map(({ Id, Name, Description }) => ({
                Id,
                Name,
                saved: Description || '', // null-safe
                draft: Description || '',
                isOpen: this.openIds.has(Id) // restore toggle state after paging
            }));
        } catch (error) {
            this.showError(error, 'Unable to load accounts');
        }
    }

    // ---------- Getters used by the HTML ----------
    // isDirty is DERIVED (draft !== saved), so no handler has to maintain it manually
    get rows() {
        return this.records.map((r) => ({ ...r, isDirty: r.draft !== r.saved }));
    }
    get totalPages() {
        return Math.max(1, Math.ceil(this.totalRecords / PAGE_SIZE));
    }
    get disablePrev() {
        return this.pageNumber <= 1;
    }
    get disableNext() {
        return this.pageNumber >= this.totalPages;
    }
    get isEmpty() {
        return !this.records.length;
    }

    // ---------- Helper: find the row for the element that fired the event (via data-id) ----------
    getRecord(event) {
        return this.records.find((r) => r.Id === event.currentTarget.dataset.id);
    }

    // ---------- Pagination: one handler for Previous (-1) and Next (+1) ----------
    handlePage(event) {
        this.pageNumber += Number(event.currentTarget.dataset.step);
        log('handlePage: moving to page', this.pageNumber);
        this.loadPage();
    }

    // ---------- Record Id link: open Account detail page ----------
    handleNavigate(event) {
        event.preventDefault(); // stop "#" link from reloading the page
        const recordId = event.currentTarget.dataset.id;
        log('handleNavigate: opening record', recordId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId, objectApiName: 'Account', actionName: 'view' }
        });
    }

    // ---------- Toggle: show/hide textarea ----------
    handleToggle(event) {
        const rec = this.getRecord(event);
        rec.isOpen = event.target.checked; // true = ON, false = OFF
        rec.draft = rec.saved;             // switching either way discards unsaved typing
        if (rec.isOpen) {
            this.openIds.add(rec.Id);
        } else {
            this.openIds.delete(rec.Id);
        }
        log('handleToggle', { id: rec.Id, isOpen: rec.isOpen });
    }

    // ---------- Typing: only store the draft; Save/Cancel visibility comes from the isDirty getter ----------
    handleDraft(event) {
        const rec = this.getRecord(event);
        rec.draft = event.target.value || '';
        log('handleDraft', { id: rec.Id, length: rec.draft.length });
    }

    // ---------- Cancel: restore last saved text ----------
    handleCancel(event) {
        const rec = this.getRecord(event);
        rec.draft = rec.saved;
        log('handleCancel: reverted', { id: rec.Id });
    }

    // ---------- Save: write Description to the Account ----------
    async handleSave(event) {
        const rec = this.getRecord(event);
        const value = rec.draft; // snapshot: user may keep typing while the save is in flight
        log('handleSave: saving', { id: rec.Id, length: value.length });
        try {
            await updateRecord({ fields: { Id: rec.Id, Description: value } }); // LDS: FLS + sharing enforced
            rec.saved = value; // no full reload, so other rows with unsaved typing stay untouched
            log('handleSave: success', { id: rec.Id });
            this.toast('Saved', 'Description updated', 'success');
        } catch (error) {
            this.showError(error, 'Update failed');
        }
    }

    // ---------- Toast helpers ----------
    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    showError(error, fallback) {
        const message = error?.body?.message || fallback;
        log('ERROR', message);
        this.toast('Error', message, 'error');
    }
}
