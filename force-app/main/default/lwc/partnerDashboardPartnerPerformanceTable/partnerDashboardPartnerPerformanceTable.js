import { LightningElement, track, api } from 'lwc';
import getPartnerPerformance from '@salesforce/apex/PartnerDashboardController.getPartnerPerformance';

const DEFAULT_DATE_RANGE = 'LAST_30_DAYS';
const RISK_THRESHOLD = 500000;
const DEFAULT_SORT_BY = 'partnerName';
const DEFAULT_SORT_DIRECTION = 'asc';
const SORT_FIELD_MAP = {
    partnerName: 'partnerName',
    totalOrders: 'totalOrders',
    grossRevenue: 'grossRevenueValue',
    aov: 'aovValue',
    realizedRevenue: 'realizedRevenueValue',
    lostRevenue: 'lostRevenueValue',
    revenueAtRisk: 'revenueAtRiskValue'
};

const COLUMNS = [
    {
        label: 'Partner Name',
        fieldName: 'partnerName',
        type: 'button',
        sortable: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' },
        typeAttributes: {
            label: { fieldName: 'partnerName' },
            name: 'openPartner',
            variant: 'base'
        }
    },
    {
        label: 'Total Orders',
        fieldName: 'totalOrders',
        type: 'number',
        sortable: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Sales',
        fieldName: 'grossRevenue',
        sortable: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'AOV',
        fieldName: 'aov',
        sortable: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Realized Revenue',
        fieldName: 'realizedRevenue',
        sortable: true,
        hideDefaultActions: true,
        cellAttributes: {
            alignment: 'left',
            class: 'slds-text-color_success'
        }
    },
    {
        label: 'Lost Revenue',
        fieldName: 'lostRevenue',
        sortable: true,
        hideDefaultActions: true,
        cellAttributes: {
            alignment: 'left',
            class: 'slds-text-color_error'
        }
    },
    {
        label: 'Revenue at Risk',
        fieldName: 'revenueAtRisk',
        sortable: true,
        hideDefaultActions: true,
        cellAttributes: {
            alignment: 'left',
            class: { fieldName: 'riskClass' }
        }
    }
];

export default class PartnerDashboardPartnerPerformanceTable extends LightningElement {

    @track rows = [];
    isLoading = true;
    _dateRange = DEFAULT_DATE_RANGE;
    _customStartDate = null;
    _customEndDate = null;
    hasConnected = false;
    handleGlobalDateChange;
    columns = COLUMNS;
    sortedBy = DEFAULT_SORT_BY;
    sortDirection = DEFAULT_SORT_DIRECTION;

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

    loadData() {
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
                    grossRevenueValue: Number(row.grossRevenue || 0),
                    grossRevenue: this.formatMillions(row.grossRevenue),
                    aovValue: Number(row.aov || 0),
                    aov: this.formatCurrency(row.aov),
                    realizedRevenueValue: Number(row.realizedRevenue || 0),
                    realizedRevenue: this.formatMillions(row.realizedRevenue),
                    lostRevenueValue: Number(row.lostRevenue || 0),
                    lostRevenue: this.formatMillions(row.lostRevenue),
                    revenueAtRiskValue: Number(row.revenueAtRisk || 0),
                    revenueAtRisk: this.formatMillions(row.revenueAtRisk),
                    riskClass: this.getRiskClass(row.revenueAtRisk)
                }));

                this.sortRows(this.sortedBy, this.sortDirection);
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

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortedBy = fieldName;
        this.sortDirection = sortDirection;
        this.sortRows(fieldName, sortDirection);
    }

    handleRowAction(event) {
        if (event.detail.action?.name !== 'openPartner') {
            return;
        }

        const partnerId = event.detail.row?.partnerId;
        if (!partnerId) {
            return;
        }

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

    sortRows(fieldName, sortDirection) {
        const sortField = SORT_FIELD_MAP[fieldName] || fieldName;
        const direction = sortDirection === 'desc' ? -1 : 1;

        this.rows = [...this.rows].sort((a, b) => {
            const first = a[sortField] ?? '';
            const second = b[sortField] ?? '';

            if (typeof first === 'number' && typeof second === 'number') {
                return (first - second) * direction;
            }

            return String(first).localeCompare(String(second), undefined, {
                numeric: true,
                sensitivity: 'base'
            }) * direction;
        });
    }

    formatCurrency(value) {
        if (!value) return '$0.00';

        const numericValue = Number(value || 0);

        return '$' + numericValue.toLocaleString(undefined, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }

    formatMillions(value) {
        if (!value) return '$0.00';

        const numericValue = Number(value || 0);

        return '$' + numericValue.toLocaleString(undefined, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }

    getRiskClass(value) {
        return value > RISK_THRESHOLD ? 'slds-text-color_weak' : '';
    }
}
