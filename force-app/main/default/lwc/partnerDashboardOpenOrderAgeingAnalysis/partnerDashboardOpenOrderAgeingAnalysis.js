import { LightningElement, api } from 'lwc';
import getPartnerOpenOrderAgeingAnalysis from '@salesforce/apex/PartnerDashboardController.getPartnerOpenOrderAgeingAnalysis';

const STAGE_PRE = 'PRE';
const STAGE_POST = 'POST';
const STAGE_TOTAL = 'TOTAL';

const BUCKET_ALL_OPEN = 'ALL_OPEN';
const BUCKET_AT_RISK_GT6 = 'AT_RISK_GT6';
const BUCKET_STAGE_TOTAL = 'STAGE_TOTAL';
const BUCKET_LT3 = 'lt3';
const BUCKET_D3TO6 = 'd3to6';
const BUCKET_D7TO15 = 'd7to15';
const BUCKET_D15TO30 = 'd15to30';
const BUCKET_GT30 = 'gt30';

const COLUMN_DEFS = [
    { label: 'TOTAL', bucketKey: BUCKET_STAGE_TOTAL },
    { label: '<3 days', bucketKey: BUCKET_LT3 },
    { label: '3-6 days', bucketKey: BUCKET_D3TO6 },
    { label: '7-15 days', bucketKey: BUCKET_D7TO15 },
    { label: '15-30 days', bucketKey: BUCKET_D15TO30 },
    { label: '>30 days', bucketKey: BUCKET_GT30 }
];

export default class PartnerDashboardOpenOrderAgeingAnalysis extends LightningElement {

    _partnerId;
    _hasConnected = false;

    isLoading = false;
    analysis;

    columnHeaders = COLUMN_DEFS;

    @api
    get partnerId() {
        return this._partnerId;
    }

    set partnerId(value) {
        this._partnerId = value || null;
        this.reloadIfReady();
    }

    @api
    get dateRange() {
        return null;
    }

    set dateRange(_value) {}

    @api
    get customStartDate() {
        return null;
    }

    set customStartDate(_value) {}

    @api
    get customEndDate() {
        return null;
    }

    set customEndDate(_value) {}

    connectedCallback() {
        this._hasConnected = true;
        this.loadAnalysis();
    }

    reloadIfReady() {
        if (this._hasConnected) {
            this.loadAnalysis();
        }
    }

    loadAnalysis() {
        if (!this._partnerId) {
            this.analysis = null;
            return;
        }

        this.isLoading = true;

        getPartnerOpenOrderAgeingAnalysis({
            partnerId: this._partnerId,
            dateRange: null,
            customStartDate: null,
            customEndDate: null
        })
            .then((result) => {
                this.analysis = result || null;
            })
            .catch((error) => {
                this.analysis = null;
                // eslint-disable-next-line no-console
                console.error('Open order ageing analysis load error', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    get analysisTableRows() {
        if (!this.analysis) {
            return [];
        }

        const out = [];
        const sourceRows = this.analysis.rows || [];

        sourceRows.forEach((row, index) => {
            const stageKey = index === 0 ? STAGE_PRE : STAGE_POST;
            out.push(this.buildRow(`row-${stageKey}`, row.status, stageKey, row, false));
        });

        const totalRow = this.analysis.totalRow;
        if (totalRow) {
            out.push(this.buildRow('row-total', totalRow.status || 'TOTAL', STAGE_TOTAL, totalRow, true));
        }

        return out;
    }

    get openOrdersSummary() {
        return this.formatBucket(
            this.analysis?.totalOpenOrders,
            this.analysis?.totalOpenRevenue
        );
    }

    get atRiskOrdersSummary() {
        return this.formatBucket(
            this.analysis?.atRiskOrdersCount,
            this.analysis?.atRiskOrdersRevenue
        );
    }

    buildRow(domId, statusLabel, stageKey, rowData, isTotalRow = false) {
        const cells = COLUMN_DEFS.map((col) =>
            this.buildCell(domId, stageKey, col.bucketKey, rowData, statusLabel));

        return {
            id: domId,
            statusLabel,
            stageKey,
            rowClass: isTotalRow ? 'slds-text-title_bold' : '',
            cells
        };
    }

    buildCell(rowDomId, stageKey, bucketKey, rowData, statusLabel) {
        let count;
        let revenue;

        if (bucketKey === BUCKET_STAGE_TOTAL) {
            count = rowData.totalCount;
            revenue = rowData.totalRevenue;
        } else if (bucketKey === BUCKET_LT3) {
            count = rowData.lt3Count;
            revenue = rowData.lt3Revenue;
        } else if (bucketKey === BUCKET_D3TO6) {
            count = rowData.d3to6Count;
            revenue = rowData.d3to6Revenue;
        } else if (bucketKey === BUCKET_D7TO15) {
            count = rowData.d7to15Count;
            revenue = rowData.d7to15Revenue;
        } else if (bucketKey === BUCKET_D15TO30) {
            count = rowData.d15to30Count;
            revenue = rowData.d15to30Revenue;
        } else if (bucketKey === BUCKET_GT30) {
            count = rowData.gt30Count;
            revenue = rowData.gt30Revenue;
        } else {
            count = 0;
            revenue = 0;
        }

        const bucket = this.formatBucket(count, revenue);
        const title = this.buildDrillTitle(statusLabel, bucketKey);

        return {
            cellDomKey: `${rowDomId}-${bucketKey}`,
            bucketKey,
            drillStage: stageKey,
            drillTitle: title,
            line1: bucket.countLabel,
            line2: bucket.revenueLabel,
            line3: bucket.percentLabel
        };
    }

    formatBucket(count, revenue) {
        const totalOpenOrders = Number(this.analysis?.totalOpenOrders || 0);
        const countValue = Number(count || 0);
        const revenueValue = Number(revenue || 0);
        const percentValue = totalOpenOrders > 0
            ? (countValue / totalOpenOrders) * 100
            : 0;

        return {
            countValue,
            revenueValue,
            percentValue,
            countLabel: countValue.toLocaleString(),
            revenueLabel: this.formatRevenue(revenueValue),
            percentLabel: `${percentValue.toFixed(1)}%`
        };
    }

    formatRevenue(value) {
        const numericValue = Number(value || 0);
        return `$${numericValue.toLocaleString(undefined, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        })}`;
    }

    buildDrillTitle(statusLabel, bucketKey) {
        const displayStatus = statusLabel === 'TOTAL' ? 'All stages' : statusLabel;
        const col = COLUMN_DEFS.find((c) => c.bucketKey === bucketKey);
        const bucketLabel = col ? col.label : bucketKey;

        if (bucketKey === BUCKET_STAGE_TOTAL) {
            return `Open Orders — ${displayStatus} (all ages)`;
        }
        return `Open Orders — ${displayStatus} (${bucketLabel})`;
    }

    handleCellDrill(event) {
        const stage = event.currentTarget.dataset.stage;
        const bucket = event.currentTarget.dataset.bucket;
        const title = event.currentTarget.dataset.title;
        if (!stage || !bucket || !title) {
            return;
        }
        this.dispatchEvent(
            new CustomEvent('openageingdrill', {
                bubbles: true,
                composed: true,
                detail: { stage, bucket, title }
            })
        );
    }

    handleCellKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            event.currentTarget.click();
        }
    }

    handleOpenOrdersSummaryDrill() {
        this.dispatchEvent(
            new CustomEvent('openageingdrill', {
                bubbles: true,
                composed: true,
                detail: {
                    stage: STAGE_TOTAL,
                    bucket: BUCKET_ALL_OPEN,
                    title: 'Open Orders (all)'
                }
            })
        );
    }

    handleAtRiskSummaryDrill() {
        this.dispatchEvent(
            new CustomEvent('openageingdrill', {
                bubbles: true,
                composed: true,
                detail: {
                    stage: STAGE_TOTAL,
                    bucket: BUCKET_AT_RISK_GT6,
                    title: 'At Risk Orders (>6 days)'
                }
            })
        );
    }

    handleOpenSummaryTileKeydown(event) {
        if (event.key !== 'Enter' && event.key !== ' ') {
            return;
        }
        event.preventDefault();
        const kind = event.currentTarget.dataset.summaryKind
            || event.currentTarget.getAttribute('data-summary-kind');
        if (kind === 'atrisk') {
            this.handleAtRiskSummaryDrill();
        } else {
            this.handleOpenOrdersSummaryDrill();
        }
    }
}

