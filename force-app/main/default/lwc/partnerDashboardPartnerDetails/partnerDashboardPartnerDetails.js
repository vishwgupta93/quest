import { LightningElement, api } from 'lwc';

export default class PartnerDashboardPartnerDetails extends LightningElement {

    naLabel = 'NA';
    metricPendingLabel = 'NA (metrics in progress)';

    @api partner;
    @api dateRange = 'LAST_30_DAYS';
    @api customStartDate;
    @api customEndDate;

    showOrdersView = false;
    ordersCardTitle = '';
    ordersFilterType = 'ALL';

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }

    get showDetailContent() {
        return this.partner && !this.showOrdersView;
    }

    get showOrdersList() {
        return this.partner && this.showOrdersView;
    }

    get showCancellationRiskCard() {
        const riskOrders = Number(this.partner?.cancellationRiskOrders ?? 0);
        return riskOrders > 0;
    }

    handleStatCardClick(event) {
        const filter = event.currentTarget.dataset.filter;
        const title = event.currentTarget.dataset.title;
        if (!filter || !title) return;
        this.ordersFilterType = filter;
        this.ordersCardTitle = title;
        this.showOrdersView = true;
    }

    handleOrdersBack() {
        this.showOrdersView = false;
        this.ordersCardTitle = '';
        this.ordersFilterType = 'ALL';
    }

    handleStatCardKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            event.currentTarget.click();
        }
    }

    get completionRateLabel() {
        return this.formatPercent(this.partner?.completionRate);
    }

    get grossRevenueLabel() {
        return this.formatMillions(this.partner?.grossRevenue);
    }

    get aovLabel() {
        return this.formatCurrency(this.partner?.aov);
    }

    get realizedRevenueLabel() {
        return this.formatMillions(this.partner?.realizedRevenue);
    }

    get realizedPercentLabel() {
        return `${this.formatPercent(this.partner?.realizedPercentOfGross)} of gross`;
    }

    get revenueAtRiskLabel() {
        return this.formatMillions(this.partner?.revenueAtRisk);
    }

    get revenueAtRiskPercentLabel() {
        return `${this.formatPercent(this.partner?.revenueAtRiskPercentOfGross)} of gross`;
    }

    get purchasesLabel() {
        return this.formatWholeNumber(this.partner?.purchases);
    }

    get completedOrdersLabel() {
        return this.formatWholeNumber(this.partner?.completedOrders);
    }

    get completedPercentLabel() {
        return this.formatPercent(this.partner?.completedPercent);
    }

    get completionWithinFiveDaysLabel() {
        return this.formatPercent(this.partner?.completionWithinFiveDaysRate);
    }

    get cancellationRiskOrdersLabel() {
        return this.formatWholeNumber(this.partner?.cancellationRiskOrders);
    }

    get cancellationRiskPercentLabel() {
        return `${this.formatPercent(this.partner?.cancellationRiskPercentOfOrders)} of total orders`;
    }

    get cancellationRiskRevenueLabel() {
        return this.formatMillions(this.partner?.cancellationRiskRevenue);
    }

    get regionLabel() {
        return this.formatPendingText(this.partner?.region);
    }

    get categoryLabel() {
        return this.formatPendingText(this.partner?.category);
    }

    get avgDistanceLabel() {
        return this.partner?.averageDistanceToPsc === null || this.partner?.averageDistanceToPsc === undefined
            ? this.metricPendingLabel
            : `${this.formatDecimal(this.partner?.averageDistanceToPsc)} miles`;
    }

    get labCompletionRateLabel() {
        return this.partner?.labCompletionRate === null || this.partner?.labCompletionRate === undefined
            ? this.metricPendingLabel
            : this.formatPercent(this.partner?.labCompletionRate);
    }

    get lostRevenueLabel() {
        return this.formatMillions(this.partner?.lostRevenue);
    }

    get qmorRevenueLabel() {
        return this.formatMillions(this.partner?.qmorRevenue);
    }

    get pmorRevenueLabel() {
        return this.formatMillions(this.partner?.pmorRevenue);
    }

    get qmorPercentLabel() {
        return this.formatPercent(this.partner?.qmorPercentOfGross);
    }

    get pmorPercentLabel() {
        return this.formatPercent(this.partner?.pmorPercentOfGross);
    }

    get qmorProgressWidth() {
        return `width: ${this.clampPercentage(this.partner?.qmorPercentOfGross)}%`;
    }

    get pmorProgressWidth() {
        return `width: ${this.clampPercentage(this.partner?.pmorPercentOfGross)}%`;
    }

    get purchasesWidth() {
        return 'width: 100%';
    }

    get completedWidth() {
        return `width: ${this.clampPercentage(this.partner?.completedPercent)}%`;
    }

    get realizedWidth() {
        return `width: ${this.clampPercentage(this.partner?.realizedPercentOfGross)}%`;
    }

    get lostRevenueWidth() {
        return `width: ${this.calculateGrossRatio(this.partner?.lostRevenue)}%`;
    }

    get riskRevenueWidth() {
        return `width: ${this.clampPercentage(this.partner?.revenueAtRiskPercentOfGross)}%`;
    }

    clampPercentage(value) {

        const numericValue = Number(value || 0);

        return Math.max(0, Math.min(100, numericValue));
    }

    calculateGrossRatio(value) {

        const grossRevenue = Number(this.partner?.grossRevenue || 0);
        const numericValue = Number(value || 0);

        if (!grossRevenue) {
            return 0;
        }

        return this.clampPercentage((numericValue / grossRevenue) * 100);
    }

    formatMillions(value) {

        const numericValue = Number(value || 0);

        if (numericValue >= 1000000000) {
            return `$${(numericValue / 1000000000).toFixed(1)}B`;
        }

        if (numericValue >= 1000000) {
            return `$${(numericValue / 1000000).toFixed(1)}M`;
        }

        if (numericValue >= 1000) {
            return `$${(numericValue / 1000).toFixed(1)}K`;
        }

        return `$${numericValue.toLocaleString(undefined, {
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        })}`;
    }

    formatCurrency(value) {

        const numericValue = Number(value || 0);

        return `$${numericValue.toLocaleString(undefined, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        })}`;
    }

    formatPercent(value) {

        const numericValue = Number(value || 0);

        return `${numericValue.toFixed(1)}%`;
    }

    formatWholeNumber(value) {

        const numericValue = Number(value || 0);

        return numericValue.toLocaleString();
    }

    formatDecimal(value) {

        const numericValue = Number(value || 0);

        return numericValue.toFixed(1);
    }

    formatPendingText(value) {
        return value ? value : this.naLabel;
    }
}