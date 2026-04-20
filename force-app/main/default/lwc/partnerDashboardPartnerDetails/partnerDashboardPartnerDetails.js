import { LightningElement, api } from 'lwc';
import PartnerDashboardPartnerProductsModal from 'c/partnerDashboardPartnerProductsModal';

const ORDERS_LIST_RETURN_STORAGE_KEY = 'quest.partnerDashboard.ordersReturnContext';

export default class PartnerDashboardPartnerDetails extends LightningElement {

    /** Set true to show the tile again on the partner detail layout. */
    showPostPurchaseFunnelTile = false;
    showRevenueBreakdownTile = false;

    naLabel = 'NA';
    metricPendingLabel = 'NA (metrics in progress)';

    _restoreOrdersListSessionDone = false;
    _lastPartnerIdForSessionRestore;

    @api partner;
    @api dateRange = 'LAST_30_DAYS';
    @api customStartDate;
    @api customEndDate;

    showOrdersView = false;
    ordersCardTitle = '';
    ordersFilterType = 'ALL';
    ordersAgeingDrillStage = null;
    ordersAgeingDrillBucket = null;

    get communityBasePath() {
        const segments = (window.location.pathname || '/').split('/').filter(Boolean);
        return segments.length ? `/${segments[0]}` : '';
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }

    handleEditPartner() {
        if (!this.partner?.partnerId) {
            return;
        }
        window.location.href = `${this.communityBasePath}/add-partner?partnerId=${this.partner.partnerId}`;
    }

    async handleViewProducts() {
        if (!this.partner?.partnerId) {
            return;
        }

        await PartnerDashboardPartnerProductsModal.open({
            size: 'large',
            partnerId: this.partner.partnerId,
            partnerName: this.partner.partnerName
        });
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
        this.ordersAgeingDrillStage = null;
        this.ordersAgeingDrillBucket = null;
        this.ordersFilterType = filter;
        this.ordersCardTitle = title;
        this.showOrdersView = true;
    }

    handleOpenAgeingDrill(event) {
        const detail = event.detail || {};
        const stage = detail.stage;
        const bucket = detail.bucket;
        const title = detail.title;
        if (!stage || !bucket || !title) {
            return;
        }
        this.ordersAgeingDrillStage = stage;
        this.ordersAgeingDrillBucket = bucket;
        this.ordersFilterType = 'ALL';
        this.ordersCardTitle = title;
        this.showOrdersView = true;
    }

    handleOrdersBack() {
        this.showOrdersView = false;
        this.ordersCardTitle = '';
        this.ordersFilterType = 'ALL';
        this.ordersAgeingDrillStage = null;
        this.ordersAgeingDrillBucket = null;
    }

    renderedCallback() {
        this.maybeRestoreOrdersListFromSession();
    }

    maybeRestoreOrdersListFromSession() {
        if (!this.partner?.partnerId) {
            return;
        }
        if (this.partner.partnerId !== this._lastPartnerIdForSessionRestore) {
            this._lastPartnerIdForSessionRestore = this.partner.partnerId;
            this._restoreOrdersListSessionDone = false;
        }
        if (this._restoreOrdersListSessionDone) {
            return;
        }

        let raw;
        try {
            raw = sessionStorage.getItem(ORDERS_LIST_RETURN_STORAGE_KEY);
        } catch (e) {
            this._restoreOrdersListSessionDone = true;
            return;
        }
        if (!raw) {
            this._restoreOrdersListSessionDone = true;
            return;
        }

        let ctx;
        try {
            ctx = JSON.parse(raw);
        } catch (e) {
            try {
                sessionStorage.removeItem(ORDERS_LIST_RETURN_STORAGE_KEY);
            } catch (e2) {}
            this._restoreOrdersListSessionDone = true;
            return;
        }

        if (ctx.partnerId !== this.partner.partnerId) {
            this._restoreOrdersListSessionDone = true;
            return;
        }

        this._restoreOrdersListSessionDone = true;
        try {
            sessionStorage.removeItem(ORDERS_LIST_RETURN_STORAGE_KEY);
        } catch (e) {}

        this.ordersFilterType = ctx.filterType || 'ALL';
        this.ordersCardTitle = ctx.cardTitle || '';
        this.ordersAgeingDrillStage = ctx.ageingDrillStage != null ? ctx.ageingDrillStage : null;
        this.ordersAgeingDrillBucket = ctx.ageingDrillBucket != null ? ctx.ageingDrillBucket : null;
        this.showOrdersView = true;
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

    get realizedRevenueLabel() {
        return this.formatMillions(this.partner?.realizedRevenue);
    }

    get realizedPercentLabel() {
        return `${this.formatPercent(this.partner?.realizedPercentOfGross)} of gross`;
    }

    get revenueAtRiskLabel() {
        return this.formatMillions(this.partner?.revenueAtRisk);
    }

    get newOrdersLabel() {
        return `${this.formatWholeNumber(this.partner?.purchases)} Orders`;
    }

    get newOrdersRevenueLabel() {
        return this.formatMillions(this.partner?.grossRevenue);
    }

    get resultedOrdersLabel() {
        return `${this.formatWholeNumber(this.partner?.completedOrders)} Orders`;
    }

    get resultedRevenueLabel() {
        return this.formatMillions(this.partner?.realizedRevenue);
    }

    get cancelledOrdersLabel() {
        return `${this.formatWholeNumber(this.partner?.cancelledOrders)} Orders`;
    }

    get cancelledRevenueLabel() {
        return this.formatMillions(this.partner?.cancelledRevenue);
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

    get qmorProgressValue() {
        return this.clampPercentage(this.partner?.qmorPercentOfGross);
    }

    get pmorProgressValue() {
        return this.clampPercentage(this.partner?.pmorPercentOfGross);
    }

    get showMorRevenueSplit() {
        if (!this.partner) {
            return false;
        }
        const qmor = Number(this.partner.qmorRevenue ?? 0);
        const pmor = Number(this.partner.pmorRevenue ?? 0);
        return qmor > 0 && pmor > 0;
    }

    get purchasesProgressValue() {
        return 100;
    }

    get completedProgressValue() {
        return this.clampPercentage(this.partner?.completedPercent);
    }

    get realizedProgressValue() {
        return this.clampPercentage(this.partner?.realizedPercentOfGross);
    }

    get lostRevenueProgressValue() {
        return this.calculateGrossRatio(this.partner?.lostRevenue);
    }

    get riskRevenueProgressValue() {
        return this.clampPercentage(this.partner?.revenueAtRiskPercentOfGross);
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
