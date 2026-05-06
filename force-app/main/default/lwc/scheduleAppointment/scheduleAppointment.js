import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import encryptOrderId from '@salesforce/apex/QuestSchedulingController.encryptOrderId';

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

    async redirectToScheduleAppointment() {
        try {
            const encrypted = await encryptOrderId({ orderId: this.labOrderNumber });
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'schedule_appointment__c'
                },
                state: {
                    orderId: encrypted
                }
            });
        } catch (error) {
            console.error('[scheduleAppointment] navigation error:', error);
        }
    }
}
