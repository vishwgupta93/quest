import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getInternalLightningBaseUrlForCurrentUser from '@salesforce/apex/PartnerDashboardController.getInternalLightningBaseUrlForCurrentUser';
import getPartnerLabOrders from '@salesforce/apex/PartnerDashboardController.getPartnerLabOrders';
import getPartnerLabOrdersForExport from '@salesforce/apex/PartnerDashboardController.getPartnerLabOrdersForExport';
import getPartnerRealizedLabOrderPanels from '@salesforce/apex/PartnerDashboardController.getPartnerRealizedLabOrderPanels';
import getPartnerRealizedLabOrderPanelsForExport from '@salesforce/apex/PartnerDashboardController.getPartnerRealizedLabOrderPanelsForExport';
import getPartnerRealizedTestSummary from '@salesforce/apex/PartnerDashboardController.getPartnerRealizedTestSummary';
import getPartnerRealizedTestSummaryForExport from '@salesforce/apex/PartnerDashboardController.getPartnerRealizedTestSummaryForExport';
import getPartnerOpenOrdersAgeingDrill from '@salesforce/apex/PartnerDashboardController.getPartnerOpenOrdersAgeingDrill';
import getPartnerOpenOrdersAgeingDrillForExport from '@salesforce/apex/PartnerDashboardController.getPartnerOpenOrdersAgeingDrillForExport';
import createPartnerLabOrdersExportFile from '@salesforce/apex/PartnerDashboardController.createPartnerLabOrdersExportFile';

const PAGE_SIZE = 25;
const REALIZED_TAB_ORDERS = 'orders';
const REALIZED_TAB_TESTS = 'tests';
const REALIZED_TAB_SUMMARY = 'summary';
/** Session key shared with partner details + Lab Order back button (must stay in sync). */
const ORDERS_LIST_RETURN_STORAGE_KEY = 'quest.partnerDashboard.ordersReturnContext';
const BASE_COLUMNS = [
    {
        label: 'Order Name',
        fieldName: 'name',
        type: 'button',
        sortable: true,
        initialWidth: 400,
        hideDefaultActions: true,
        cellAttributes: { class: 'order-name-cell' },
        typeAttributes: {
            label: { fieldName: 'name' },
            name: 'openOrder',
            variant: 'base'
        }
    },
    {
        label: 'Amount',
        fieldName: 'amount',
        type: 'currency',
        sortable: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' },
        typeAttributes: { currencyCode: 'USD' }
    },
    { label: 'Order Date', fieldName: 'createdDate', type: 'text', sortable: true, hideDefaultActions: true, cellAttributes: { alignment: 'left' } },
    { label: 'Status', fieldName: 'status', type: 'text', sortable: true, hideDefaultActions: true, cellAttributes: { alignment: 'left' } },
    {
        label: 'MoR Type',
        fieldName: 'mor',
        type: 'text',
        sortable: true,
        hideDefaultActions: true,
        cellAttributes: {
            alignment: 'left',
            class: { fieldName: 'morClass' }
        }
    }
];

const REALIZED_ORDER_COLUMNS = [
    {
        label: 'Order',
        fieldName: 'name',
        type: 'button',
        sortable: true,
        initialWidth: 200,
        hideDefaultActions: true,
        typeAttributes: {
            label: { fieldName: 'name' },
            name: 'openOrder',
            variant: 'base'
        }
    },
    {
        label: 'Client Account Number',
        fieldName: 'clientAccountNumber',
        type: 'text',
        sortable: true,
        initialWidth: 200,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Partner Name',
        fieldName: 'partnerName',
        type: 'text',
        sortable: true,
        initialWidth: 220,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Lab Order ID',
        fieldName: 'labOrderId',
        type: 'text',
        sortable: true,
        initialWidth: 340,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'External Partner Order ID',
        fieldName: 'externalPartnerOrderId',
        type: 'text',
        sortable: true,
        initialWidth: 340,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Lab Ref ID',
        fieldName: 'labRefId',
        type: 'text',
        sortable: true,
        initialWidth: 280,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Accession ID',
        fieldName: 'accessionId',
        type: 'text',
        sortable: true,
        initialWidth: 200,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Order Status',
        fieldName: 'status',
        type: 'text',
        sortable: true,
        initialWidth: 180,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Date Created',
        fieldName: 'orderCreatedDate',
        type: 'text',
        sortable: true,
        initialWidth: 160,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Date Sample Collected',
        fieldName: 'dateSampleCollected',
        type: 'text',
        sortable: true,
        initialWidth: 200,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Date Resulted (Date reported)',
        fieldName: 'dateResulted',
        type: 'text',
        sortable: true,
        initialWidth: 220,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Non-Refundable Date',
        fieldName: 'nonRefundableDate',
        type: 'text',
        sortable: true,
        initialWidth: 200,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Registrant Name',
        fieldName: 'registrantName',
        type: 'text',
        sortable: true,
        initialWidth: 220,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Performing Site',
        fieldName: 'performingSite',
        type: 'text',
        sortable: true,
        initialWidth: 180,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Order Total Sales Price',
        fieldName: 'amount',
        type: 'currency',
        sortable: true,
        initialWidth: 200,
        hideDefaultActions: true,
        typeAttributes: { currencyCode: 'USD' }
    },
    {
        label: 'MoR Type',
        fieldName: 'mor',
        type: 'text',
        sortable: true,
        initialWidth: 120,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    }
];

const REALIZED_TESTS_COLUMNS = [
    {
        label: 'Order',
        fieldName: 'labOrderName',
        type: 'button',
        sortable: true,
        initialWidth: 200,
        hideDefaultActions: true,
        typeAttributes: {
            label: { fieldName: 'labOrderName' },
            name: 'openOrder',
            variant: 'base'
        }
    },
    {
        label: 'Lab Order ID',
        fieldName: 'labOrderId',
        type: 'text',
        sortable: true,
        initialWidth: 340,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'External Partner Order ID',
        fieldName: 'externalPartnerOrderId',
        type: 'text',
        sortable: true,
        initialWidth: 340,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Lab Ref ID',
        fieldName: 'labRefId',
        type: 'text',
        sortable: true,
        initialWidth: 280,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Accession ID',
        fieldName: 'accessionId',
        type: 'text',
        sortable: true,
        initialWidth: 200,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Date Created',
        fieldName: 'orderCreatedDate',
        type: 'text',
        sortable: true,
        initialWidth: 160,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Date Resulted (Date reported)',
        fieldName: 'dateResulted',
        type: 'text',
        sortable: true,
        initialWidth: 220,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Non-Refundable Date',
        fieldName: 'nonRefundableDate',
        type: 'text',
        sortable: true,
        initialWidth: 200,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Registrant Name',
        fieldName: 'registrantName',
        type: 'text',
        sortable: true,
        initialWidth: 220,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Performing Site',
        fieldName: 'performingSite',
        type: 'text',
        sortable: true,
        initialWidth: 180,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Panel Code',
        fieldName: 'panelCode',
        type: 'text',
        sortable: true,
        initialWidth: 160,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Panel Name',
        fieldName: 'panelName',
        type: 'text',
        sortable: true,
        initialWidth: 280,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Panel Price',
        fieldName: 'panelPrice',
        type: 'currency',
        sortable: true,
        initialWidth: 160,
        hideDefaultActions: true,
        typeAttributes: { currencyCode: 'USD' }
    },
    {
        label: 'Panel Status',
        fieldName: 'panelStatus',
        type: 'text',
        sortable: true,
        initialWidth: 200,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'MoR Type',
        fieldName: 'mor',
        type: 'text',
        sortable: true,
        initialWidth: 120,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    }
];

const REALIZED_SUMMARY_COLUMNS = [
    {
        label: 'Panel Code',
        fieldName: 'panelCode',
        type: 'text',
        sortable: true,
        initialWidth: 200,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Panel Name',
        fieldName: 'panelName',
        type: 'text',
        sortable: true,
        initialWidth: 320,
        wrapText: true,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Quantity',
        fieldName: 'quantity',
        type: 'number',
        sortable: true,
        initialWidth: 140,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Panel Price',
        fieldName: 'panelPrice',
        type: 'currency',
        sortable: true,
        initialWidth: 180,
        hideDefaultActions: true,
        typeAttributes: { currencyCode: 'USD' }
    },
    {
        label: 'Total Amount',
        fieldName: 'totalAmount',
        type: 'currency',
        sortable: true,
        initialWidth: 200,
        hideDefaultActions: true,
        typeAttributes: { currencyCode: 'USD' }
    }
];

export default class PartnerDashboardPartnerOrdersList extends NavigationMixin(LightningElement) {

    @api cardTitle = 'Lab Orders';
    @api partnerName = '';
    @api partnerMetrics;

    data = [];
    totalCount = 0;
    currentPage = 1;
    pageSize = PAGE_SIZE;
    isLoading = false;
    sortedBy = 'createdDate';
    sortedDirection = 'desc';
    pageInput = '1';
    isExporting = false;

    realizedActiveTab = REALIZED_TAB_ORDERS;
    testsData = [];
    testsTotalCount = 0;
    testsSortedBy = 'dateResulted';
    testsSortedDirection = 'desc';
    summaryData = [];
    summaryTotalCount = 0;
    summaryGrandTotalQuantity = 0;
    summaryGrandTotalAmount = 0;
    summarySortedBy = 'panelCode';
    summarySortedDirection = 'asc';

    _filterType = 'ALL';
    _partnerId;
    _dateRange = 'LAST_30_DAYS';
    _customStartDate = null;
    _customEndDate = null;
    _hasConnected = false;
    _ageingDrillStage = null;
    _ageingDrillBucket = null;
    _internalLightningBase = null;

    @wire(getInternalLightningBaseUrlForCurrentUser)
    wiredInternalLightningBase({ data }) {
        this._internalLightningBase = data || null;
    }

    @api
    get filterType() {
        return this._filterType;
    }

    set filterType(value) {
        const next = value || 'ALL';
        this._filterType = next;
        if (next === 'REALIZED') {
            this.realizedActiveTab = REALIZED_TAB_ORDERS;
            this.sortedBy = 'dateResulted';
            this.sortedDirection = 'desc';
            this.testsSortedBy = 'dateResulted';
            this.testsSortedDirection = 'desc';
            this.summarySortedBy = 'panelCode';
            this.summarySortedDirection = 'asc';
        }
        this.currentPage = 1;
        this.pageInput = '1';
        this.reloadIfReady();
    }

    @api
    get partnerId() {
        return this._partnerId;
    }

    set partnerId(value) {
        this._partnerId = value;
        this.currentPage = 1;
        this.pageInput = '1';
        this.reloadIfReady();
    }

    @api
    get dateRange() {
        return this._dateRange;
    }

    set dateRange(value) {
        this._dateRange = value || 'LAST_30_DAYS';
        this.currentPage = 1;
        this.pageInput = '1';
        this.reloadIfReady();
    }

    @api
    get customStartDate() {
        return this._customStartDate;
    }

    set customStartDate(value) {
        this._customStartDate = value || null;
        this.currentPage = 1;
        this.pageInput = '1';
        this.reloadIfReady();
    }

    @api
    get customEndDate() {
        return this._customEndDate;
    }

    set customEndDate(value) {
        this._customEndDate = value || null;
        this.currentPage = 1;
        this.pageInput = '1';
        this.reloadIfReady();
    }

    @api
    get ageingDrillStage() {
        return this._ageingDrillStage;
    }

    set ageingDrillStage(value) {
        this._ageingDrillStage = value != null && value !== '' ? value : null;
        this.currentPage = 1;
        this.pageInput = '1';
        this.reloadIfReady();
    }

    @api
    get ageingDrillBucket() {
        return this._ageingDrillBucket;
    }

    set ageingDrillBucket(value) {
        this._ageingDrillBucket = value != null && value !== '' ? value : null;
        this.currentPage = 1;
        this.pageInput = '1';
        this.reloadIfReady();
    }

    get isOpenAgeingDrillMode() {
        return Boolean(this._ageingDrillStage && this._ageingDrillBucket);
    }

    get showRealizedTabs() {
        return this._filterType === 'REALIZED' && !this.isOpenAgeingDrillMode;
    }

    get activeTotalCount() {
        if (!this.showRealizedTabs) {
            return this.totalCount;
        }
        if (this.realizedActiveTab === REALIZED_TAB_TESTS) {
            return this.testsTotalCount;
        }
        if (this.realizedActiveTab === REALIZED_TAB_SUMMARY) {
            return this.summaryTotalCount;
        }
        return this.totalCount;
    }

    get realizedOrderColumns() {
        return REALIZED_ORDER_COLUMNS;
    }

    get realizedTestsColumns() {
        return REALIZED_TESTS_COLUMNS;
    }

    get realizedSummaryColumns() {
        return REALIZED_SUMMARY_COLUMNS;
    }

    get summaryTotalsLabel() {
        const qty = Number(this.summaryGrandTotalQuantity || 0);
        const amt = this.formatCurrencyFull(this.summaryGrandTotalAmount);
        return `TOTAL — Quantity: ${qty.toLocaleString()} | Total Amount: ${amt}`;
    }

    get totalPages() {
        if (this.pageSize <= 0) return 0;
        return Math.max(1, Math.ceil(this.activeTotalCount / this.pageSize));
    }

    get columns() {
        const dateLabel = this.isOpenAgeingDrillMode
            ? 'Created Date'
            : this._filterType === 'REALIZED'
                ? 'Date Reported'
                : this._filterType === 'CANCELLED'
                    ? 'Cancellation Date'
                    : 'Created Date';

        const mapped = BASE_COLUMNS.map((column) =>
            column.fieldName === 'createdDate'
                ? { ...column, label: dateLabel }
                : column
        );

        if (this._filterType !== 'CANCELLED' || this.isOpenAgeingDrillMode) {
            return mapped;
        }

        const reasonColumn = {
            label: 'Cancellation Reason',
            fieldName: 'cancellationReason',
            type: 'text',
            sortable: true,
            hideDefaultActions: true,
            initialWidth: 220,
            cellAttributes: { alignment: 'left' }
        };
        const morIndex = mapped.findIndex((c) => c.fieldName === 'mor');
        if (morIndex < 0) {
            return [...mapped, reasonColumn];
        }
        const withReason = [...mapped];
        withReason.splice(morIndex, 0, reasonColumn);
        return withReason;
    }

    get canGoFirstOrPrevious() {
        return this.currentPage > 1;
    }

    get canGoNextOrLast() {
        return this.currentPage < this.totalPages;
    }

    get disableFirstOrPrevious() {
        return this.isLoading || !this.canGoFirstOrPrevious;
    }

    get disableNextOrLast() {
        return this.isLoading || !this.canGoNextOrLast;
    }

    get hasData() {
        if (this.showRealizedTabs) {
            return false;
        }
        return this.data && this.data.length > 0;
    }

    get showPaginationBar() {
        if (this.isLoading) {
            return false;
        }
        if (this.showRealizedTabs) {
            if (this.realizedActiveTab === REALIZED_TAB_TESTS) {
                return this.testsTotalCount > 0;
            }
            if (this.realizedActiveTab === REALIZED_TAB_SUMMARY) {
                return this.summaryTotalCount > 0;
            }
            return this.totalCount > 0;
        }
        return this.totalCount > 0;
    }

    get hasRealizedOrdersRows() {
        return Boolean(this.data && this.data.length > 0);
    }

    get showRealizedOrdersEmpty() {
        return (
            !this.isLoading &&
            this.showRealizedTabs &&
            this.realizedActiveTab === REALIZED_TAB_ORDERS &&
            this.totalCount === 0
        );
    }

    get hasRealizedTestsRows() {
        return Boolean(this.testsData && this.testsData.length > 0);
    }

    get showRealizedTestsEmpty() {
        return (
            !this.isLoading &&
            this.showRealizedTabs &&
            this.realizedActiveTab === REALIZED_TAB_TESTS &&
            this.testsTotalCount === 0
        );
    }

    get hasRealizedSummaryRows() {
        return Boolean(this.summaryData && this.summaryData.length > 0);
    }

    get showRealizedSummaryEmpty() {
        return (
            !this.isLoading &&
            this.showRealizedTabs &&
            this.realizedActiveTab === REALIZED_TAB_SUMMARY &&
            this.summaryTotalCount === 0
        );
    }

    get ordersCountLabel() {
        if (this.showRealizedTabs) {
            if (this.realizedActiveTab === REALIZED_TAB_TESTS) {
                return `${this.testsTotalCount.toLocaleString()} test lines`;
            }
            if (this.realizedActiveTab === REALIZED_TAB_SUMMARY) {
                return `${this.summaryTotalCount.toLocaleString()} panel summaries`;
            }
        }
        return `${this.totalCount.toLocaleString()} orders`;
    }

    get partnerLabel() {
        return this.partnerName || '';
    }

    get pageInfoLabel() {
        const total = this.activeTotalCount;
        const start = total === 0 ? 0 : (this.currentPage - 1) * this.pageSize + 1;
        const end = Math.min(this.currentPage * this.pageSize, total);
        return `Showing ${start}-${end} of ${total.toLocaleString()}`;
    }

    get exportButtonLabel() {
        return this.isExporting ? 'Exporting...' : 'Export Report';
    }

    get showConsolidatedExportButton() {
        return this.showRealizedTabs;
    }

    get consolidatedExportButtonLabel() {
        return this.isExporting ? 'Exporting...' : 'Export Consolidated Report';
    }

    get disableExport() {
        return this.isLoading || this.isExporting || !this._partnerId;
    }

    connectedCallback() {
        this._hasConnected = true;
        this.loadOrders();
    }

    @api
    refresh() {
        this.loadOrders();
    }

    reloadIfReady() {
        if (this._hasConnected) {
            this.loadOrders();
        }
    }

    loadOrders() {
        if (!this._partnerId) {
            this.data = [];
            this.totalCount = 0;
            this.testsData = [];
            this.testsTotalCount = 0;
            this.summaryData = [];
            this.summaryTotalCount = 0;
            this.summaryGrandTotalQuantity = 0;
            this.summaryGrandTotalAmount = 0;
            return;
        }

        this.isLoading = true;

        const reconcilePage = () => {
            const maxPage = this.totalPages;
            if (this.activeTotalCount > 0 && this.currentPage > maxPage) {
                this.currentPage = maxPage;
                this.pageInput = String(this.currentPage);
                return true;
            }
            return false;
        };

        const mapStandardOrderRow = (o) => ({
            id: o.id,
            name: o.name,
            status: o.status,
            amount: Number(o.amount || 0),
            createdDate: o.createdDate,
            mor: o.mor,
            morClass: o.mor === 'QMoR' ? 'slds-text-color_success slds-text-title_bold' : 'slds-text-title_bold',
            cancellationReason: o.cancellationReason || '',
            clientAccountNumber: o.clientAccountNumber || '',
            partnerName: o.partnerName || '',
            labOrderId: o.labOrderId || '',
            externalPartnerOrderId: o.externalPartnerOrderId || '',
            labRefId: o.labRefId || '',
            accessionId: o.accessionId || '',
            orderCreatedDate: o.orderCreatedDate || '',
            dateSampleCollected: o.dateSampleCollected || '',
            dateResulted: o.dateResulted || '',
            nonRefundableDate: o.nonRefundableDate || '',
            registrantName: o.registrantName || '',
            performingSite: o.performingSite || ''
        });

        const fetchAndApply = () => {
            const offset = (this.currentPage - 1) * this.pageSize;

            if (this.isOpenAgeingDrillMode) {
                return getPartnerOpenOrdersAgeingDrill({
                    partnerId: this._partnerId,
                    dateRange: this._dateRange,
                    customStartDate: this._customStartDate,
                    customEndDate: this._customEndDate,
                    stageKey: this._ageingDrillStage,
                    bucketKey: this._ageingDrillBucket,
                    sortBy: this.sortedBy,
                    sortDirection: this.sortedDirection,
                    pageSize: this.pageSize,
                    pageOffset: offset
                }).then((result) => {
                    this.totalCount = result.totalCount || 0;
                    if (reconcilePage()) {
                        return fetchAndApply();
                    }
                    this.data = (result.orders || []).map((o) => mapStandardOrderRow(o));
                    this.pageInput = String(this.currentPage);
                });
            }

            if (this.showRealizedTabs && this.realizedActiveTab === REALIZED_TAB_TESTS) {
                return getPartnerRealizedLabOrderPanels({
                    partnerId: this._partnerId,
                    dateRange: this._dateRange,
                    customStartDate: this._customStartDate,
                    customEndDate: this._customEndDate,
                    sortBy: this.testsSortedBy,
                    sortDirection: this.testsSortedDirection,
                    pageSize: this.pageSize,
                    pageOffset: offset
                }).then((result) => {
                    this.testsTotalCount = result.totalCount || 0;
                    if (reconcilePage()) {
                        return fetchAndApply();
                    }
                    this.testsData = (result.rows || []).map((r) => ({
                        id: r.id,
                        labOrderRecordId: r.labOrderRecordId,
                        labOrderName: r.labOrderName || '',
                        labOrderId: r.labOrderId || '',
                        externalPartnerOrderId: r.externalPartnerOrderId || '',
                        labRefId: r.labRefId || '',
                        accessionId: r.accessionId || '',
                        orderCreatedDate: r.orderCreatedDate || '',
                        dateSampleCollected: r.dateSampleCollected || '',
                        dateResulted: r.dateResulted || '',
                        nonRefundableDate: r.nonRefundableDate || '',
                        registrantName: r.registrantName || '',
                        performingSite: r.performingSite || '',
                        panelCode: r.panelCode || '',
                        panelName: r.panelName || '',
                        panelPrice: Number(r.panelPrice || 0),
                        panelStatus: r.panelStatus || '',
                        mor: r.mor || ''
                    }));
                    this.pageInput = String(this.currentPage);
                });
            }

            if (this.showRealizedTabs && this.realizedActiveTab === REALIZED_TAB_SUMMARY) {
                return getPartnerRealizedTestSummary({
                    partnerId: this._partnerId,
                    dateRange: this._dateRange,
                    customStartDate: this._customStartDate,
                    customEndDate: this._customEndDate,
                    sortBy: this.summarySortedBy,
                    sortDirection: this.summarySortedDirection,
                    pageSize: this.pageSize,
                    pageOffset: offset
                }).then((result) => {
                    this.summaryTotalCount = result.totalCount || 0;
                    this.summaryGrandTotalQuantity = result.grandTotalQuantity ?? 0;
                    this.summaryGrandTotalAmount = result.grandTotalAmount ?? 0;
                    if (reconcilePage()) {
                        return fetchAndApply();
                    }
                    this.summaryData = (result.rows || []).map((r) => ({
                        id: r.id,
                        panelCode: r.panelCode || '',
                        panelName: r.panelName || '',
                        quantity: Number(r.quantity || 0),
                        panelPrice: Number(r.panelPrice || 0),
                        totalAmount: Number(r.totalAmount || 0)
                    }));
                    this.pageInput = String(this.currentPage);
                });
            }

            return getPartnerLabOrders({
                partnerId: this._partnerId,
                dateRange: this._dateRange,
                customStartDate: this._customStartDate,
                customEndDate: this._customEndDate,
                filterType: this._filterType,
                sortBy: this.sortedBy,
                sortDirection: this.sortedDirection,
                pageSize: this.pageSize,
                pageOffset: offset
            }).then((result) => {
                this.totalCount = result.totalCount || 0;
                if (reconcilePage()) {
                    return fetchAndApply();
                }
                this.data = (result.orders || []).map((o) => mapStandardOrderRow(o));
                this.pageInput = String(this.currentPage);
                if (
                    this.showRealizedTabs &&
                    this.realizedActiveTab === REALIZED_TAB_ORDERS &&
                    this.totalCount > 0
                ) {
                    this.prefetchRealizedSecondaryData();
                }
            });
        };

        fetchAndApply()
            .catch((err) => {
                this.data = [];
                this.totalCount = 0;
                this.testsData = [];
                this.testsTotalCount = 0;
                this.summaryData = [];
                this.summaryTotalCount = 0;
                this.summaryGrandTotalQuantity = 0;
                this.summaryGrandTotalAmount = 0;
                // eslint-disable-next-line no-console
                console.error('Partner lab orders load error', err);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.currentPage = 1;
        this.pageInput = '1';
        this.loadOrders();
    }

    handleRowAction(event) {
        const actionName = event.detail.action?.name;
        const row = event.detail.row;
        if (actionName !== 'openOrder') {
            return;
        }
        const recordId = row?.labOrderRecordId || row?.id;
        if (!recordId) {
            return;
        }

        const internalUrl = this.buildInternalLabOrderViewUrl(recordId);
        if (internalUrl) {
            // Internal Lightning: always a new tab so the partner dashboard (and order list) stay open.
            window.open(internalUrl, '_blank', 'noopener,noreferrer');
            return;
        }

        this.persistOrdersListReturnContext();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName: 'Lab_Order__c',
                actionName: 'view'
            }
        });
    }

    /**
     * Resolves the selected tab value. `onactive` on lightning-tabset bubbles from lightning-tab, so
     * event.target is often the tab (use .value), not the tabset — reading only event.target as tabset
     * left realizedActiveTab stuck on "orders" and broke tab-scoped export.
     */
    resolveRealizedTabsetActiveValue(event) {
        if (event?.detail != null && typeof event.detail === 'string') {
            return event.detail;
        }
        const fromDetail = event?.detail?.value;
        if (fromDetail) {
            return fromDetail;
        }
        if (event?.target?.localName === 'lightning-tab' && event.target.value != null) {
            return event.target.value;
        }
        const tabset = event?.currentTarget;
        if (tabset?.activeTabValue != null) {
            return tabset.activeTabValue;
        }
        return null;
    }

    getActiveRealizedTabForExport() {
        const ts = this.template.querySelector('lightning-tabset');
        const fromDom = ts?.activeTabValue;
        if (
            fromDom === REALIZED_TAB_ORDERS ||
            fromDom === REALIZED_TAB_TESTS ||
            fromDom === REALIZED_TAB_SUMMARY
        ) {
            return fromDom;
        }
        return this.realizedActiveTab;
    }

    handleRealizedTabsetActive(event) {
        const next = this.resolveRealizedTabsetActiveValue(event);
        if (!next || next === this.realizedActiveTab) {
            return;
        }
        this.realizedActiveTab = next;
        this.currentPage = 1;
        this.pageInput = '1';
        this.loadOrders();
    }

    handleTestsSort(event) {
        this.testsSortedBy = event.detail.fieldName;
        this.testsSortedDirection = event.detail.sortDirection;
        this.currentPage = 1;
        this.pageInput = '1';
        this.loadOrders();
    }

    handleSummarySort(event) {
        this.summarySortedBy = event.detail.fieldName;
        this.summarySortedDirection = event.detail.sortDirection;
        this.currentPage = 1;
        this.pageInput = '1';
        this.loadOrders();
    }

    prefetchRealizedSecondaryData() {
        if (!this._partnerId || this._filterType !== 'REALIZED' || this.isOpenAgeingDrillMode) {
            return;
        }
        const base = {
            partnerId: this._partnerId,
            dateRange: this._dateRange,
            customStartDate: this._customStartDate,
            customEndDate: this._customEndDate
        };
        Promise.all([
            getPartnerRealizedLabOrderPanels({
                ...base,
                sortBy: this.testsSortedBy,
                sortDirection: this.testsSortedDirection,
                pageSize: this.pageSize,
                pageOffset: 0
            }),
            getPartnerRealizedTestSummary({
                ...base,
                sortBy: this.summarySortedBy,
                sortDirection: this.summarySortedDirection,
                pageSize: this.pageSize,
                pageOffset: 0
            })
        ])
            .then(([panelResult, summaryResult]) => {
                if (
                    this._filterType !== 'REALIZED' ||
                    this.isOpenAgeingDrillMode ||
                    !this._partnerId ||
                    this.realizedActiveTab !== REALIZED_TAB_ORDERS
                ) {
                    return;
                }
                this.testsTotalCount = panelResult.totalCount || 0;
                this.testsData = (panelResult.rows || []).map((r) => ({
                    id: r.id,
                    labOrderRecordId: r.labOrderRecordId,
                    labOrderName: r.labOrderName || '',
                    labOrderId: r.labOrderId || '',
                    externalPartnerOrderId: r.externalPartnerOrderId || '',
                    labRefId: r.labRefId || '',
                    accessionId: r.accessionId || '',
                    orderCreatedDate: r.orderCreatedDate || '',
                    dateSampleCollected: r.dateSampleCollected || '',
                    dateResulted: r.dateResulted || '',
                    nonRefundableDate: r.nonRefundableDate || '',
                    registrantName: r.registrantName || '',
                    performingSite: r.performingSite || '',
                    panelCode: r.panelCode || '',
                    panelName: r.panelName || '',
                    panelPrice: Number(r.panelPrice || 0),
                    panelStatus: r.panelStatus || '',
                    mor: r.mor || ''
                }));
                this.summaryTotalCount = summaryResult.totalCount || 0;
                this.summaryGrandTotalQuantity = summaryResult.grandTotalQuantity ?? 0;
                this.summaryGrandTotalAmount = summaryResult.grandTotalAmount ?? 0;
                this.summaryData = (summaryResult.rows || []).map((r) => ({
                    id: r.id,
                    panelCode: r.panelCode || '',
                    panelName: r.panelName || '',
                    quantity: Number(r.quantity || 0),
                    panelPrice: Number(r.panelPrice || 0),
                    totalAmount: Number(r.totalAmount || 0)
                }));
            })
            .catch((err) => {
                // eslint-disable-next-line no-console
                console.error('Partner realized secondary prefetch error', err);
            });
    }

    buildInternalLabOrderViewUrl(recordId) {
        const base = (this._internalLightningBase || '').trim();
        if (!base || !recordId) {
            return null;
        }
        const normalized = base.replace(/\/+$/, '');
        return `${normalized}/lightning/r/Lab_Order__c/${recordId}/view`;
    }

    persistOrdersListReturnContext() {
        if (!this._partnerId) {
            return;
        }
        try {
            sessionStorage.setItem(
                ORDERS_LIST_RETURN_STORAGE_KEY,
                JSON.stringify({
                    partnerId: this._partnerId,
                    returnHref: window.location.href,
                    filterType: this._filterType,
                    cardTitle: this.cardTitle || '',
                    ageingDrillStage: this._ageingDrillStage,
                    ageingDrillBucket: this._ageingDrillBucket
                })
            );
        } catch (e) {
            // Private mode / storage blocked — navigation still works without restore.
        }
    }

    handleFirst() {
        if (!this.canGoFirstOrPrevious) return;
        this.currentPage = 1;
        this.pageInput = '1';
        this.loadOrders();
    }

    handlePrevious() {
        if (!this.canGoFirstOrPrevious) return;
        this.currentPage -= 1;
        this.pageInput = String(this.currentPage);
        this.loadOrders();
    }

    handleNext() {
        if (!this.canGoNextOrLast) return;
        this.currentPage += 1;
        this.pageInput = String(this.currentPage);
        this.loadOrders();
    }

    handleLast() {
        if (!this.canGoNextOrLast) return;
        this.currentPage = this.totalPages;
        this.pageInput = String(this.currentPage);
        this.loadOrders();
    }

    handlePageInputChange(event) {
        this.pageInput = event.target.value;
    }

    handlePageInputBlur() {
        this.jumpToInputPage();
    }

    handlePageInputKeydown(event) {
        if (event.key === 'Enter') {
            this.jumpToInputPage();
        }
    }

    jumpToInputPage() {
        const parsed = parseInt(this.pageInput, 10);
        if (Number.isNaN(parsed)) {
            this.pageInput = String(this.currentPage);
            return;
        }

        const nextPage = Math.min(Math.max(parsed, 1), this.totalPages);
        if (nextPage === this.currentPage) {
            this.pageInput = String(this.currentPage);
            return;
        }

        this.currentPage = nextPage;
        this.pageInput = String(this.currentPage);
        this.loadOrders();
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }

    async handleExport() {
        if (this.disableExport) return;

        this.isExporting = true;
        try {
            let workbookXml;
            let fileNameOpts = {};

            if (this.showRealizedTabs) {
                const activeTab = this.getActiveRealizedTabForExport();
                const tabRows = await this.fetchActiveRealizedTabExport(activeTab);
                fileNameOpts = { realizedTab: activeTab };
                if (activeTab === REALIZED_TAB_ORDERS) {
                    workbookXml = this.buildRealizedOrdersTabExportXml(tabRows);
                } else if (activeTab === REALIZED_TAB_TESTS) {
                    workbookXml = this.buildRealizedTestsTabExportXml(tabRows);
                } else {
                    workbookXml = this.buildRealizedSummaryTabExportXml(tabRows);
                }
            } else {
                const exportPayload = await this.fetchAllRowsForExport();
                workbookXml = this.buildExportWorkbookXml(exportPayload);
            }

            const fileName = this.buildExportFilename(fileNameOpts);
            const versionId = await createPartnerLabOrdersExportFile({
                fileName,
                documentContent: workbookXml
            });
            this.downloadExportByVersionId(versionId, fileName);
        } catch (err) {
            // eslint-disable-next-line no-console
            console.error('Partner lab orders export error', err);
        } finally {
            this.isExporting = false;
        }
    }

    async handleExportConsolidated() {
        if (this.disableExport || !this.showRealizedTabs) return;

        this.isExporting = true;
        try {
            const exportPayload = await this.fetchConsolidatedRealizedExport();
            const workbookXml = this.buildRealizedMultiSheetExportXml(
                exportPayload.orderRows,
                exportPayload.testRows,
                exportPayload.summaryResult
            );
            const fileName = this.buildExportFilename({ consolidated: true });
            const versionId = await createPartnerLabOrdersExportFile({
                fileName,
                documentContent: workbookXml
            });
            this.downloadExportByVersionId(versionId, fileName);
        } catch (err) {
            // eslint-disable-next-line no-console
            console.error('Partner lab orders consolidated export error', err);
        } finally {
            this.isExporting = false;
        }
    }

    async fetchConsolidatedRealizedExport() {
        const base = {
            partnerId: this._partnerId,
            dateRange: this._dateRange,
            customStartDate: this._customStartDate,
            customEndDate: this._customEndDate
        };
        const [orderRows, testRows, summaryResult] = await Promise.all([
            getPartnerLabOrdersForExport({
                ...base,
                filterType: 'REALIZED',
                sortBy: this.sortedBy,
                sortDirection: this.sortedDirection
            }),
            getPartnerRealizedLabOrderPanelsForExport({
                ...base,
                sortBy: this.testsSortedBy,
                sortDirection: this.testsSortedDirection
            }),
            getPartnerRealizedTestSummaryForExport({
                ...base,
                sortBy: this.summarySortedBy,
                sortDirection: this.summarySortedDirection
            })
        ]);
        return { orderRows, testRows, summaryResult };
    }

    async fetchActiveRealizedTabExport(activeTab) {
        const tab = activeTab || this.realizedActiveTab;
        const base = {
            partnerId: this._partnerId,
            dateRange: this._dateRange,
            customStartDate: this._customStartDate,
            customEndDate: this._customEndDate
        };
        if (tab === REALIZED_TAB_ORDERS) {
            return getPartnerLabOrdersForExport({
                ...base,
                filterType: 'REALIZED',
                sortBy: this.sortedBy,
                sortDirection: this.sortedDirection
            });
        }
        if (tab === REALIZED_TAB_TESTS) {
            return getPartnerRealizedLabOrderPanelsForExport({
                ...base,
                sortBy: this.testsSortedBy,
                sortDirection: this.testsSortedDirection
            });
        }
        return getPartnerRealizedTestSummaryForExport({
            ...base,
            sortBy: this.summarySortedBy,
            sortDirection: this.summarySortedDirection
        });
    }

    async fetchAllRowsForExport() {
        if (this.isOpenAgeingDrillMode) {
            return getPartnerOpenOrdersAgeingDrillForExport({
                partnerId: this._partnerId,
                dateRange: this._dateRange,
                customStartDate: this._customStartDate,
                customEndDate: this._customEndDate,
                stageKey: this._ageingDrillStage,
                bucketKey: this._ageingDrillBucket,
                sortBy: this.sortedBy,
                sortDirection: this.sortedDirection
            });
        }
        return getPartnerLabOrdersForExport({
            partnerId: this._partnerId,
            dateRange: this._dateRange,
            customStartDate: this._customStartDate,
            customEndDate: this._customEndDate,
            filterType: this._filterType,
            sortBy: this.sortedBy,
            sortDirection: this.sortedDirection
        });
    }

    buildSpreadsheetStylesXml() {
        return `  <Styles>
    <Style ss:ID="Default" ss:Name="Normal">
      <Alignment ss:Vertical="Center"/>
      <Font ss:FontName="Calibri" ss:Size="11"/>
    </Style>
    <Style ss:ID="MetaHeader">
      <Font ss:FontName="Calibri" ss:Size="12" ss:Bold="1"/>
      <Interior ss:Color="#EAF0FF" ss:Pattern="Solid"/>
      <Borders>
        <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
      </Borders>
    </Style>
    <Style ss:ID="MetaValue">
      <Font ss:FontName="Calibri" ss:Size="12"/>
      <Borders>
        <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
      </Borders>
    </Style>
    <Style ss:ID="MetaValueNumber">
      <Font ss:FontName="Calibri" ss:Size="12"/>
      <Alignment ss:Horizontal="Right"/>
      <Borders>
        <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
      </Borders>
    </Style>
    <Style ss:ID="SectionTitle">
      <Font ss:FontName="Calibri" ss:Size="14" ss:Bold="1"/>
    </Style>
    <Style ss:ID="TableHeader">
      <Font ss:FontName="Calibri" ss:Size="12" ss:Bold="1"/>
      <Interior ss:Color="#E2E8F0" ss:Pattern="Solid"/>
      <Borders>
        <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
      </Borders>
    </Style>
    <Style ss:ID="DataCell">
      <Font ss:FontName="Calibri" ss:Size="11"/>
      <Borders>
        <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
      </Borders>
    </Style>
    <Style ss:ID="ValueCell">
      <Font ss:FontName="Calibri" ss:Size="11"/>
      <Alignment ss:Horizontal="Right"/>
      <Borders>
        <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
      </Borders>
    </Style>
    <Style ss:ID="NumberCell">
      <Font ss:FontName="Calibri" ss:Size="11"/>
      <Alignment ss:Horizontal="Right"/>
      <Borders>
        <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
        <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
      </Borders>
    </Style>
    <Style ss:ID="Spacer">
      <Font ss:FontName="Calibri" ss:Size="2"/>
    </Style>
  </Styles>`;
    }

    buildExportWorkbookXml(rows) {
        const metadataRows = [
            ['Generated At', new Date().toLocaleString()],
            ['Partner Name', this.partnerName || ''],
            ['Selected Card', this.cardTitle || ''],
            ['Date Range', this.getDateRangeLabel(this._dateRange)],
            ['Total Records', String(rows.length)]
        ];

        const summaryRows = this.getCardSummaryRows();

        const xmlRows = [];
        const addRow = (cells) => {
            xmlRows.push(`<Row>${cells.join('')}</Row>`);
        };
        const textCell = (value, style = 'DataCell') =>
            `<Cell ss:StyleID="${style}"><Data ss:Type="String">${this.escapeXml(value)}</Data></Cell>`;
        const numberCell = (value, style = 'NumberCell') =>
            `<Cell ss:StyleID="${style}"><Data ss:Type="Number">${Number(value || 0)}</Data></Cell>`;

        metadataRows.forEach(([label, value]) => {
            const isNumeric = label === 'Total Records';
            addRow([
                textCell(label, 'MetaHeader'),
                isNumeric ? numberCell(value, 'MetaValueNumber') : textCell(value, 'MetaValue')
            ]);
        });

        addRow([textCell('', 'Spacer')]);
        addRow([textCell('Card Summary', 'SectionTitle')]);
        addRow([textCell('Metric', 'TableHeader'), textCell('Value', 'TableHeader')]);
        summaryRows.forEach(([metric, value]) => {
            addRow([textCell(metric), textCell(value, 'ValueCell')]);
        });

        addRow([textCell('', 'Spacer')]);
        addRow([textCell('Lab Orders', 'SectionTitle')]);

        const exportDateHeader = this.isOpenAgeingDrillMode
            ? 'Created Date'
            : this._filterType === 'REALIZED'
                ? 'Date Reported'
                : this._filterType === 'CANCELLED'
                    ? 'Cancellation Date'
                    : 'Created Date';
        const includeCancellationReason =
            this._filterType === 'CANCELLED' && !this.isOpenAgeingDrillMode;

        const headerCells = [
            textCell('Order Name', 'TableHeader'),
            textCell('Amount (USD)', 'TableHeader'),
            textCell(exportDateHeader, 'TableHeader'),
            textCell('Status', 'TableHeader')
        ];
        if (includeCancellationReason) {
            headerCells.push(textCell('Cancellation Reason', 'TableHeader'));
        }
        headerCells.push(textCell('MoR Type', 'TableHeader'));
        addRow(headerCells);

        rows.forEach((row) => {
            const dataCells = [
                textCell(row.name || ''),
                textCell(this.formatCurrencyFull(row.amount), 'ValueCell'),
                textCell(row.createdDate || ''),
                textCell(row.status || '')
            ];
            if (includeCancellationReason) {
                dataCells.push(textCell(row.cancellationReason || ''));
            }
            dataCells.push(textCell(row.mor || ''));
            addRow(dataCells);
        });

        return `<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
${this.buildSpreadsheetStylesXml()}
    <Worksheet ss:Name="${this.escapeXml((this.cardTitle || 'Orders').slice(0, 30))}">
    <Table>
      <Column ss:AutoFitWidth="0" ss:Width="310"/>
      <Column ss:AutoFitWidth="0" ss:Width="150"/>
      <Column ss:AutoFitWidth="0" ss:Width="140"/>
      <Column ss:AutoFitWidth="0" ss:Width="220"/>
      ${
          this._filterType === 'CANCELLED' && !this.isOpenAgeingDrillMode
              ? '<Column ss:AutoFitWidth="0" ss:Width="220"/>'
              : ''
      }
      <Column ss:AutoFitWidth="0" ss:Width="100"/>
      ${xmlRows.join('')}
    </Table>
  </Worksheet>
</Workbook>`;
    }

    appendExportMetadataAndCardSummary(addRow, textCell, numberCell, totalRecordsLabel, totalRecordsValue) {
        const metadataRows = [
            ['Generated At', new Date().toLocaleString()],
            ['Partner Name', this.partnerName || ''],
            ['Selected Card', this.cardTitle || ''],
            ['Date Range', this.getDateRangeLabel(this._dateRange)],
            [totalRecordsLabel, String(totalRecordsValue)]
        ];
        metadataRows.forEach(([label, value]) => {
            const isNumeric =
                label === 'Total Records' ||
                label === 'Total Records (this tab)' ||
                label.startsWith('Total Records');
            addRow([
                textCell(label, 'MetaHeader'),
                isNumeric ? numberCell(value, 'MetaValueNumber') : textCell(value, 'MetaValue')
            ]);
        });
        addRow([textCell('', 'Spacer')]);
        addRow([textCell('Card Summary', 'SectionTitle')]);
        addRow([textCell('Metric', 'TableHeader'), textCell('Value', 'TableHeader')]);
        this.getCardSummaryRows().forEach(([metric, value]) => {
            addRow([textCell(metric), textCell(value, 'ValueCell')]);
        });
        addRow([textCell('', 'Spacer')]);
    }

    buildRealizedOrdersTabExportXml(orderRows) {
        const orders = orderRows || [];
        const xmlRows = [];
        const addRow = (cells) => {
            xmlRows.push(`<Row>${cells.join('')}</Row>`);
        };
        const textCell = (value, style = 'DataCell') =>
            `<Cell ss:StyleID="${style}"><Data ss:Type="String">${this.escapeXml(value)}</Data></Cell>`;
        const numberCell = (value, style = 'NumberCell') =>
            `<Cell ss:StyleID="${style}"><Data ss:Type="Number">${Number(value || 0)}</Data></Cell>`;

        this.appendExportMetadataAndCardSummary(
            addRow,
            textCell,
            numberCell,
            'Total Records',
            orders.length
        );
        addRow([textCell('Resulted Orders', 'SectionTitle')]);

        const orderHeader = [
            'Order Name',
            'Client Account Number',
            'Partner Name',
            'Lab Order ID',
            'External Partner Order ID',
            'Lab Ref ID',
            'Accession ID',
            'Order Status',
            'Date Created',
            'Date Sample Collected',
            'Date Resulted (Date reported)',
            'Non-Refundable Date',
            'Registrant Name',
            'Performing Site',
            'Order Total (USD)',
            'MoR Type'
        ];
        addRow(orderHeader.map((h) => textCell(h, 'TableHeader')));
        orders.forEach((row) => {
            addRow([
                textCell(row.name || ''),
                textCell(row.clientAccountNumber || ''),
                textCell(row.partnerName || ''),
                textCell(row.labOrderId || ''),
                textCell(row.externalPartnerOrderId || ''),
                textCell(row.labRefId || ''),
                textCell(row.accessionId || ''),
                textCell(row.status || ''),
                textCell(row.orderCreatedDate || ''),
                textCell(row.dateSampleCollected || ''),
                textCell(row.dateResulted || ''),
                textCell(row.nonRefundableDate || ''),
                textCell(row.registrantName || ''),
                textCell(row.performingSite || ''),
                textCell(this.formatCurrencyFull(row.amount), 'ValueCell'),
                textCell(row.mor || '')
            ]);
        });

        const wsName = 'Resulted Orders Export'.slice(0, 30);
        return `<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
${this.buildSpreadsheetStylesXml()}
    <Worksheet ss:Name="${this.escapeXml(wsName)}">
    <Table>
      ${xmlRows.join('')}
    </Table>
  </Worksheet>
</Workbook>`;
    }

    buildRealizedTestsTabExportXml(testRows) {
        const tests = testRows || [];
        const xmlRows = [];
        const addRow = (cells) => {
            xmlRows.push(`<Row>${cells.join('')}</Row>`);
        };
        const textCell = (value, style = 'DataCell') =>
            `<Cell ss:StyleID="${style}"><Data ss:Type="String">${this.escapeXml(value)}</Data></Cell>`;
        const numberCell = (value, style = 'NumberCell') =>
            `<Cell ss:StyleID="${style}"><Data ss:Type="Number">${Number(value || 0)}</Data></Cell>`;

        this.appendExportMetadataAndCardSummary(
            addRow,
            textCell,
            numberCell,
            'Total Records',
            tests.length
        );
        addRow([textCell('Resulted Tests', 'SectionTitle')]);

        const testHeader = [
            'Order Name',
            'Lab Order ID',
            'External Partner Order ID',
            'Lab Ref ID',
            'Accession ID',
            'Date Created',
            'Date Sample Collected',
            'Date Resulted (Date reported)',
            'Non-Refundable Date',
            'Registrant Name',
            'Performing Site',
            'Panel Code',
            'Panel Name',
            'Panel Price (USD)',
            'Panel Status',
            'MoR Type'
        ];
        addRow(testHeader.map((h) => textCell(h, 'TableHeader')));
        tests.forEach((row) => {
            addRow([
                textCell(row.labOrderName || ''),
                textCell(row.labOrderId || ''),
                textCell(row.externalPartnerOrderId || ''),
                textCell(row.labRefId || ''),
                textCell(row.accessionId || ''),
                textCell(row.orderCreatedDate || ''),
                textCell(row.dateSampleCollected || ''),
                textCell(row.dateResulted || ''),
                textCell(row.nonRefundableDate || ''),
                textCell(row.registrantName || ''),
                textCell(row.performingSite || ''),
                textCell(row.panelCode || ''),
                textCell(row.panelName || ''),
                textCell(this.formatCurrencyFull(row.panelPrice), 'ValueCell'),
                textCell(row.panelStatus || ''),
                textCell(row.mor || '')
            ]);
        });

        const wsName = 'Resulted Tests Export'.slice(0, 30);
        return `<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
${this.buildSpreadsheetStylesXml()}
    <Worksheet ss:Name="${this.escapeXml(wsName)}">
    <Table>
      ${xmlRows.join('')}
    </Table>
  </Worksheet>
</Workbook>`;
    }

    buildRealizedSummaryTabExportXml(summaryPayload) {
        const summaryRows = (summaryPayload && summaryPayload.rows) || [];
        const xmlRows = [];
        const addRow = (cells) => {
            xmlRows.push(`<Row>${cells.join('')}</Row>`);
        };
        const textCell = (value, style = 'DataCell') =>
            `<Cell ss:StyleID="${style}"><Data ss:Type="String">${this.escapeXml(value)}</Data></Cell>`;
        const numberCell = (value, style = 'NumberCell') =>
            `<Cell ss:StyleID="${style}"><Data ss:Type="Number">${Number(value || 0)}</Data></Cell>`;

        this.appendExportMetadataAndCardSummary(
            addRow,
            textCell,
            numberCell,
            'Total Records',
            summaryRows.length
        );
        addRow([textCell('Resulted Test Summary', 'SectionTitle')]);

        const summaryHeader = ['Panel Code', 'Panel Name', 'Quantity', 'Panel Price (USD)', 'Total Amount (USD)'];
        addRow(summaryHeader.map((h) => textCell(h, 'TableHeader')));
        summaryRows.forEach((row) => {
            addRow([
                textCell(row.panelCode || ''),
                textCell(row.panelName || ''),
                numberCell(row.quantity),
                textCell(this.formatCurrencyFull(row.panelPrice), 'ValueCell'),
                textCell(this.formatCurrencyFull(row.totalAmount), 'ValueCell')
            ]);
        });
        addRow([
            textCell('TOTAL', 'TableHeader'),
            textCell('', 'TableHeader'),
            numberCell(summaryPayload?.grandTotalQuantity),
            textCell('', 'DataCell'),
            textCell(this.formatCurrencyFull(summaryPayload?.grandTotalAmount), 'ValueCell')
        ]);

        const wsName = 'Resulted Summary Export'.slice(0, 30);
        return `<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
${this.buildSpreadsheetStylesXml()}
    <Worksheet ss:Name="${this.escapeXml(wsName)}">
    <Table>
      ${xmlRows.join('')}
    </Table>
  </Worksheet>
</Workbook>`;
    }

    buildRealizedMultiSheetExportXml(orderRows, testRows, summaryPayload) {
        const orders = orderRows || [];
        const tests = testRows || [];
        const summaryRows = (summaryPayload && summaryPayload.rows) || [];
        const totalRecords = orders.length + tests.length + summaryRows.length;

        const textCell = (value, style = 'DataCell') =>
            `<Cell ss:StyleID="${style}"><Data ss:Type="String">${this.escapeXml(value)}</Data></Cell>`;
        const numberCell = (value, style = 'NumberCell') =>
            `<Cell ss:StyleID="${style}"><Data ss:Type="Number">${Number(value || 0)}</Data></Cell>`;

        const metaBlock = [];
        const addMetaRow = (cells) => {
            metaBlock.push(`<Row>${cells.join('')}</Row>`);
        };
        const metaPairs = [
            ['Generated At', new Date().toLocaleString()],
            ['Partner Name', this.partnerName || ''],
            ['Selected Card', this.cardTitle || ''],
            ['Date Range', this.getDateRangeLabel(this._dateRange)],
            ['Total Records (all tabs)', String(totalRecords)]
        ];
        metaPairs.forEach(([label, value]) => {
            const isNumeric = label.startsWith('Total Records');
            addMetaRow([
                textCell(label, 'MetaHeader'),
                isNumeric ? numberCell(value, 'MetaValueNumber') : textCell(value, 'MetaValue')
            ]);
        });
        addMetaRow([textCell('', 'Spacer')]);
        addMetaRow([textCell('Card Summary', 'SectionTitle')]);
        addMetaRow([textCell('Metric', 'TableHeader'), textCell('Value', 'TableHeader')]);
        this.getCardSummaryRows().forEach(([metric, value]) => {
            addMetaRow([textCell(metric), textCell(value, 'ValueCell')]);
        });

        const orderHeader = [
            'Order Name',
            'Client Account Number',
            'Partner Name',
            'Lab Order ID',
            'External Partner Order ID',
            'Lab Ref ID',
            'Accession ID',
            'Order Status',
            'Date Created',
            'Date Sample Collected',
            'Date Resulted (Date reported)',
            'Non-Refundable Date',
            'Registrant Name',
            'Performing Site',
            'Order Total (USD)',
            'MoR Type'
        ];
        const orderRowsXml = [];
        const pushRow = (arr, rowXml) => arr.push(`<Row>${rowXml.join('')}</Row>`);
        pushRow(
            orderRowsXml,
            orderHeader.map((h) => textCell(h, 'TableHeader'))
        );
        orders.forEach((row) => {
            pushRow(orderRowsXml, [
                textCell(row.name || ''),
                textCell(row.clientAccountNumber || ''),
                textCell(row.partnerName || ''),
                textCell(row.labOrderId || ''),
                textCell(row.externalPartnerOrderId || ''),
                textCell(row.labRefId || ''),
                textCell(row.accessionId || ''),
                textCell(row.status || ''),
                textCell(row.orderCreatedDate || ''),
                textCell(row.dateSampleCollected || ''),
                textCell(row.dateResulted || ''),
                textCell(row.nonRefundableDate || ''),
                textCell(row.registrantName || ''),
                textCell(row.performingSite || ''),
                textCell(this.formatCurrencyFull(row.amount), 'ValueCell'),
                textCell(row.mor || '')
            ]);
        });

        const testHeader = [
            'Order Name',
            'Lab Order ID',
            'External Partner Order ID',
            'Lab Ref ID',
            'Accession ID',
            'Date Created',
            'Date Sample Collected',
            'Date Resulted (Date reported)',
            'Non-Refundable Date',
            'Registrant Name',
            'Performing Site',
            'Panel Code',
            'Panel Name',
            'Panel Price (USD)',
            'Panel Status',
            'MoR Type'
        ];
        const testRowsXml = [];
        pushRow(
            testRowsXml,
            testHeader.map((h) => textCell(h, 'TableHeader'))
        );
        tests.forEach((row) => {
            pushRow(testRowsXml, [
                textCell(row.labOrderName || ''),
                textCell(row.labOrderId || ''),
                textCell(row.externalPartnerOrderId || ''),
                textCell(row.labRefId || ''),
                textCell(row.accessionId || ''),
                textCell(row.orderCreatedDate || ''),
                textCell(row.dateSampleCollected || ''),
                textCell(row.dateResulted || ''),
                textCell(row.nonRefundableDate || ''),
                textCell(row.registrantName || ''),
                textCell(row.performingSite || ''),
                textCell(row.panelCode || ''),
                textCell(row.panelName || ''),
                textCell(this.formatCurrencyFull(row.panelPrice), 'ValueCell'),
                textCell(row.panelStatus || ''),
                textCell(row.mor || '')
            ]);
        });

        const summaryHeader = ['Panel Code', 'Panel Name', 'Quantity', 'Panel Price (USD)', 'Total Amount (USD)'];
        const summaryRowsXml = [];
        pushRow(
            summaryRowsXml,
            summaryHeader.map((h) => textCell(h, 'TableHeader'))
        );
        summaryRows.forEach((row) => {
            pushRow(summaryRowsXml, [
                textCell(row.panelCode || ''),
                textCell(row.panelName || ''),
                numberCell(row.quantity),
                textCell(this.formatCurrencyFull(row.panelPrice), 'ValueCell'),
                textCell(this.formatCurrencyFull(row.totalAmount), 'ValueCell')
            ]);
        });
        pushRow(summaryRowsXml, [
            textCell('TOTAL', 'TableHeader'),
            textCell('', 'TableHeader'),
            numberCell(summaryPayload?.grandTotalQuantity),
            textCell('', 'DataCell'),
            textCell(this.formatCurrencyFull(summaryPayload?.grandTotalAmount), 'ValueCell')
        ]);

        const ws = (title, body) =>
            `<Worksheet ss:Name="${this.escapeXml(title.slice(0, 31))}"><Table>${body}</Table></Worksheet>`;

        return `<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
${this.buildSpreadsheetStylesXml()}
${ws('Overview', metaBlock.join(''))}
${ws('Resulted Orders', orderRowsXml.join(''))}
${ws('Resulted Tests', testRowsXml.join(''))}
${ws('Resulted Test Summary', summaryRowsXml.join(''))}
</Workbook>`;
    }

    getCardSummaryRows() {
        const partner = this.partnerMetrics || {};
        const summary = [];

        if (this.cardTitle === 'Sales') {
            summary.push(['Sales', this.formatCurrencyFull(partner.grossRevenue)]);
            summary.push(['Average Order Value', this.formatCurrencyFull(partner.aov)]);
            summary.push(['QMoR Revenue', this.formatCurrencyFull(partner.qmorRevenue)]);
            summary.push(['QMoR % of Gross', this.formatPercent(partner.qmorPercentOfGross)]);
            summary.push(['PMoR Revenue', this.formatCurrencyFull(partner.pmorRevenue)]);
            summary.push(['PMoR % of Gross', this.formatPercent(partner.pmorPercentOfGross)]);
            return summary;
        }

        if (this.cardTitle === 'Total Orders') {
            summary.push(['Total Orders', partner.totalOrders ?? 0]);
            summary.push(['Completion Rate', this.formatPercent(partner.completionRate)]);
            return summary;
        }

        if (this._filterType === 'REALIZED') {
            summary.push(['Realized Revenue', this.formatCurrencyFull(partner.realizedRevenue)]);
            summary.push(['Number of Orders', partner.completedOrders ?? 0]);
            return summary;
        }

        if (this._filterType === 'AT_RISK') {
            summary.push(['Revenue at Risk', this.formatCurrencyFull(partner.revenueAtRisk)]);
            summary.push(['Revenue at Risk % of Gross', this.formatPercent(partner.revenueAtRiskPercentOfGross)]);
            summary.push(['Orders Approaching Auto-Cancel', partner.cancellationRiskOrders ?? 0]);
            summary.push(['Cancellation Risk % of Orders', this.formatPercent(partner.cancellationRiskPercentOfOrders)]);
            summary.push(['Revenue at Risk of Cancellation', this.formatCurrencyFull(partner.cancellationRiskRevenue)]);
            return summary;
        }

        summary.push(['Card', this.cardTitle || '']);
        summary.push(['Total Records', this.totalCount || 0]);
        return summary;
    }

    getDateRangeLabel(dateRange) {
        const labels = {
            LAST_30_DAYS: 'Last 30 Days',
            LAST_60_DAYS: 'Last 60 Days',
            LAST_90_DAYS: 'Last 90 Days',
            YEAR_TO_DATE: 'Year to Date'
        };
        if (dateRange === 'CUSTOM' && this._customStartDate && this._customEndDate) {
            return `${this._customStartDate} to ${this._customEndDate}`;
        }
        return labels[dateRange] || dateRange || '';
    }

    formatCurrencyFull(value) {
        const numeric = Number(value || 0);
        return numeric.toLocaleString(undefined, {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }

    formatPercent(value) {
        const numeric = Number(value || 0);
        return `${numeric.toFixed(1)}%`;
    }

    escapeXml(value) {
        const text = value === null || value === undefined ? '' : String(value);
        return text
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    buildExportFilename(opts = {}) {
        const safePartner = (this.partnerName || 'Partner').replace(/[^a-zA-Z0-9-_ ]/g, '').trim().replace(/\s+/g, '_');
        const safeCard = (this.cardTitle || 'Orders').replace(/[^a-zA-Z0-9-_ ]/g, '').trim().replace(/\s+/g, '_');
        const stamp = new Date().toISOString().slice(0, 10);
        let suffix = '';
        if (opts.consolidated) {
            suffix = '_Consolidated';
        } else if (opts.realizedTab === REALIZED_TAB_ORDERS) {
            suffix = '_Resulted_Orders';
        } else if (opts.realizedTab === REALIZED_TAB_TESTS) {
            suffix = '_Resulted_Tests';
        } else if (opts.realizedTab === REALIZED_TAB_SUMMARY) {
            suffix = '_Resulted_Test_Summary';
        }
        return `${safePartner || 'Partner'}_${safeCard || 'Orders'}_${stamp}${suffix}.xls`;
    }

    downloadExportByVersionId(versionId, fileName) {
        if (!versionId) {
            // eslint-disable-next-line no-console
            console.error(`Export file creation failed for ${fileName}`);
            return;
        }
        const url = `/sfc/servlet.shepherd/version/download/${versionId}`;
        try {
            window.location.assign(url);
        } catch (e) {
            // eslint-disable-next-line no-console
            console.error(`Unable to navigate to export file for ${fileName}`, e);
        }
    }
}
