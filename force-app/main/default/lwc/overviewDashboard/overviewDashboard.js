import { LightningElement, track } from 'lwc';
import getOverviewSummary from '@salesforce/apex/PartnerDashboardController.getOverviewSummary';

const DEFAULT_DATE_RANGE = 'LAST_30_DAYS';

export default class OverviewDashboard extends LightningElement {

    selectedDateRange = DEFAULT_DATE_RANGE;
    selectedCustomStartDate = null;
    selectedCustomEndDate = null;
    @track summary = {};
    isLoadingSummary = false;
    handleGlobalDateChange;

    connectedCallback() {
        const searchParams = new URLSearchParams(window.location.search);
        this.selectedDateRange = searchParams.get('dateRange') || DEFAULT_DATE_RANGE;
        this.selectedCustomStartDate = searchParams.get('customStart') || null;
        this.selectedCustomEndDate = searchParams.get('customEnd') || null;

        this.handleGlobalDateChange = this.handleGlobalDateChangeEvent.bind(this);
        window.addEventListener('partnerdashboardfilterschange', this.handleGlobalDateChange);

        this.loadSummary();
    }

    disconnectedCallback() {
        window.removeEventListener('partnerdashboardfilterschange', this.handleGlobalDateChange);
    }

    handleGlobalDateChangeEvent(event) {
        this.selectedDateRange = event.detail.dateRange || DEFAULT_DATE_RANGE;
        this.selectedCustomStartDate = event.detail.customStartDate || null;
        this.selectedCustomEndDate = event.detail.customEndDate || null;
        this.loadSummary();
    }

    loadSummary() {
        this.isLoadingSummary = true;
        getOverviewSummary({
            dateRange: this.selectedDateRange,
            customStartDate: this.selectedCustomStartDate,
            customEndDate: this.selectedCustomEndDate
        })
            .then(result => {
                this.summary = result || {};
            })
            .catch(() => {
                this.summary = {};
            })
            .finally(() => {
                this.isLoadingSummary = false;
            });
    }

    get salesLabel() {
        return this.formatMillions(this.summary.grossRevenue);
    }

    get realizedRevenueLabel() {
        return this.formatMillions(this.summary.realizedRevenue);
    }

    get realizedSameMonthLabel() {
        return this.formatMillions(this.summary.realizedRevenueSameMonth);
    }

    get realizedSameMonthTrendValue() {
        const pct = Number(this.summary.realizedSameMonthPercentOfRealized || 0);
        const pctStr = pct.toLocaleString(undefined, { maximumFractionDigits: 1, minimumFractionDigits: 0 });
        return `Up ${pctStr}% of realized`;
    }

    get cancellationRiskLabel() {
        return Number(this.summary.cancellationRiskOrders || 0).toLocaleString();
    }

    get cancellationRiskSubtitle() {
        return `${this.formatMillions(this.summary.cancellationRiskRevenue)} at risk`;
    }

    get refundLiabilityLabel() {
        return this.formatMillions(this.summary.revenueAtRisk);
    }

    formatMillions(value) {
        const n = Number(value || 0);
        return `$${n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    }
}
