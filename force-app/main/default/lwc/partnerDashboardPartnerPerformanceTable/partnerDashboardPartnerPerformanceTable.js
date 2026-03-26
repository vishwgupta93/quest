import { LightningElement, track, api } from 'lwc';
import getPartnerPerformance from '@salesforce/apex/PartnerDashboardController.getPartnerPerformance';

const DEFAULT_DATE_RANGE = 'LAST_30_DAYS';

export default class PartnerDashboardPartnerPerformanceTable extends LightningElement {

    @track rows = [];
    isLoading = true;
    _dateRange = DEFAULT_DATE_RANGE;
    _customStartDate = null;
    _customEndDate = null;
    hasConnected = false;
    handleGlobalDateChange;

    @api
    get dateRange() {
        return this._dateRange;
    }

    set dateRange(value) {
        const nextValue = value || DEFAULT_DATE_RANGE;

        if (this._dateRange === nextValue) {
            return;
        }

        this._dateRange = nextValue;

        if (this.hasConnected) {
            this.loadData();
        }
    }

    connectedCallback() {
        this.hasConnected = true;
        this.handleGlobalDateChange = this.handleGlobalDateChangeEvent.bind(this);
        window.addEventListener('partnerdashboardfilterschange', this.handleGlobalDateChange);
        this.loadData();
    }

    disconnectedCallback() {
        window.removeEventListener('partnerdashboardfilterschange', this.handleGlobalDateChange);
    }

    loadData(){
        this.isLoading = true;

        getPartnerPerformance({
            dateRange: this._dateRange,
            customStartDate: this._customStartDate,
            customEndDate: this._customEndDate
        })
        .then(result => {

            this.rows = result.map(row => ({

                partnerId: row.partnerId,
                partnerName: row.partnerName,
                totalOrders: row.totalOrders,
                grossRevenue: this.formatMillions(row.grossRevenue),
                aov: this.formatCurrency(row.aov),
                realizedRevenue: this.formatMillions(row.realizedRevenue),
                lostRevenue: this.formatMillions(row.lostRevenue),
                revenueAtRisk: this.formatMillions(row.revenueAtRisk),
                riskClass: this.getRiskClass(row.revenueAtRisk)

            }));

            this.isLoading = false;

        })
        .catch(error => {
            this.isLoading = false;
            this.rows = [];
            console.error('Partner Performance Load Error', error);
        });

    }

    get hasRows() {
        return this.rows.length > 0;
    }

    handlePartnerClick(event) {
        const partnerId = event.currentTarget.dataset.id;
        if (!partnerId) return;
        window.dispatchEvent(
            new CustomEvent('partnerdashboardpartnerselect', {
                detail: { partnerId }
            })
        );
    }

    handleGlobalDateChangeEvent(event) {
        this._dateRange = event.detail?.dateRange || DEFAULT_DATE_RANGE;
        this._customStartDate = event.detail?.customStartDate || null;
        this._customEndDate = event.detail?.customEndDate || null;
        this.loadData();
    }

    formatCurrency(value){

        if(!value) return '$0';

        const numericValue = Number(value || 0);

        if (numericValue >= 1000000000) {
            return '$' + (numericValue / 1000000000).toFixed(1) + 'B';
        }

        if (numericValue >= 1000000) {
            return '$' + (numericValue / 1000000).toFixed(1) + 'M';
        }

        if (numericValue >= 1000) {
            return '$' + (numericValue / 1000).toFixed(1) + 'K';
        }

        return '$' + numericValue.toLocaleString(undefined,{
            minimumFractionDigits:2,
            maximumFractionDigits:2
        });

    }

    formatMillions(value){

        if(!value) return '$0';

        const numericValue = Number(value || 0);

        if (numericValue >= 1000000000) {
            return '$' + (numericValue / 1000000000).toFixed(1) + 'B';
        }

        if (numericValue >= 1000000) {
            return '$' + (numericValue / 1000000).toFixed(1) + 'M';
        }

        if (numericValue >= 1000) {
            return '$' + (numericValue / 1000).toFixed(1) + 'K';
        }

        return '$' + numericValue.toLocaleString(undefined, {
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        });

    }

    getRiskClass(value){

        if(value > 500000){
            return 'warning';
        }

        return '';

    }

}