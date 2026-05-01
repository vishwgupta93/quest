import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class ScheduleAppointment extends NavigationMixin(LightningElement) {

    isServiceValue = false;
    labOrderNumber;
    _labOrderPanelList;

    @api
    get labOrderPanelList() {
        return this._labOrderPanelList;
    }

    set labOrderPanelList(value) {
        this._labOrderPanelList = value;
        this.labOrderNumber = this._labOrderPanelList.labOrderId;
        this.isServiceValue = this._labOrderPanelList.isService ? true : false;
    }

    redirectToScheduleAppointment() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'schedule-appointment'
            },
            state: {
                orderId: this.labOrderNumber
            }
        });
    }
}