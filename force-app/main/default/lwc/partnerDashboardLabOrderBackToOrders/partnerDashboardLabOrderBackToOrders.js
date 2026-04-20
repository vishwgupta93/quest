import { LightningElement } from 'lwc';

const ORDERS_LIST_RETURN_STORAGE_KEY = 'quest.partnerDashboard.ordersReturnContext';

export default class PartnerDashboardLabOrderBackToOrders extends LightningElement {
    _ctx;

    connectedCallback() {
        try {
            const raw = sessionStorage.getItem(ORDERS_LIST_RETURN_STORAGE_KEY);
            if (raw) {
                this._ctx = JSON.parse(raw);
            }
        } catch (e) {
            this._ctx = undefined;
        }
    }

    get showButton() {
        return Boolean(this._ctx?.returnHref);
    }

    handleBack() {
        if (!this._ctx?.returnHref) {
            return;
        }
        window.location.assign(this._ctx.returnHref);
    }
}
