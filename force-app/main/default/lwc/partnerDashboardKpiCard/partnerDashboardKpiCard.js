import { LightningElement, api } from 'lwc';

export default class PartnerDashboardKpiCard extends LightningElement {

    @api title
    @api value
    @api subtitle
    @api icon
    @api trendValue
    @api trendDirection
    /** When unset, footer shows "vs last month". Pass "" to hide the compare line. */
    @api trendCompareText
    @api progress
    @api progressLabel;
    @api progressValue;
    @api highlightText

    get progressStyle(){

    return `width:${this.progress}%`;

    }

    get trendCompareLine() {
        if (this.trendCompareText === '') {
            return null;
        }
        return this.trendCompareText != null ? this.trendCompareText : 'vs last month';
    }

    get trendColorClass() {
        // SLDS-only coloring (no custom CSS).
        return this.trendDirection === 'down'
            ? 'slds-text-color_error'
            : 'slds-text-color_success';
    }

}