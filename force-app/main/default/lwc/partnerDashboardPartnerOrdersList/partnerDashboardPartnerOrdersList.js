import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getPartnerLabOrders from '@salesforce/apex/PartnerDashboardController.getPartnerLabOrders';
import getPartnerLabOrdersForExport from '@salesforce/apex/PartnerDashboardController.getPartnerLabOrdersForExport';
import createPartnerLabOrdersExportFile from '@salesforce/apex/PartnerDashboardController.createPartnerLabOrdersExportFile';

const PAGE_SIZE = 25;
const COLUMNS = [
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
    { label: 'Created Date', fieldName: 'createdDate', type: 'text', sortable: true, hideDefaultActions: true, cellAttributes: { alignment: 'left' } },
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

export default class PartnerDashboardPartnerOrdersList extends NavigationMixin(LightningElement) {

    @api cardTitle = 'Lab Orders';
    @api partnerName = '';
    @api partnerMetrics;

    columns = COLUMNS;
    data = [];
    totalCount = 0;
    currentPage = 1;
    pageSize = PAGE_SIZE;
    isLoading = false;
    sortedBy = 'createdDate';
    sortedDirection = 'desc';
    pageInput = '1';
    isExporting = false;

    _filterType = 'ALL';
    _partnerId;
    _dateRange = 'LAST_30_DAYS';
    _customStartDate = null;
    _customEndDate = null;
    _hasConnected = false;

    @api
    get filterType() {
        return this._filterType;
    }

    set filterType(value) {
        this._filterType = value || 'ALL';
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

    get totalPages() {
        if (this.pageSize <= 0) return 0;
        return Math.max(1, Math.ceil(this.totalCount / this.pageSize));
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
        return this.data && this.data.length > 0;
    }

    get ordersCountLabel() {
        return `${this.totalCount.toLocaleString()} orders`;
    }

    get partnerLabel() {
        return this.partnerName || '';
    }

    get pageInfoLabel() {
        const start = this.totalCount === 0 ? 0 : (this.currentPage - 1) * this.pageSize + 1;
        const end = Math.min(this.currentPage * this.pageSize, this.totalCount);
        return `Showing ${start}-${end} of ${this.totalCount.toLocaleString()}`;
    }

    get exportButtonLabel() {
        return this.isExporting ? 'Exporting...' : 'Export Data';
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
            return;
        }

        this.isLoading = true;

        const fetchAndApply = () => {
            const offset = (this.currentPage - 1) * this.pageSize;
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
                const maxPage = this.totalPages;
                if (this.totalCount > 0 && this.currentPage > maxPage) {
                    this.currentPage = maxPage;
                    this.pageInput = String(this.currentPage);
                    return fetchAndApply();
                }

                this.data = (result.orders || []).map((o) => ({
                    id: o.id,
                    name: o.name,
                    status: o.status,
                    amount: Number(o.amount || 0),
                    createdDate: o.createdDate,
                    mor: o.mor,
                    morClass: o.mor === 'QMoR' ? 'mor-qmor' : 'mor-pmor'
                }));
                this.pageInput = String(this.currentPage);
            });
        };

        fetchAndApply()
            .catch((err) => {
                this.data = [];
                this.totalCount = 0;
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
        if (actionName !== 'openOrder' || !row?.id) {
            return;
        }

        // In Experience Cloud, `standard__recordPage` will use the configured
        // object detail page for Lab_Order__c (your community page), if present.
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.id,
                objectApiName: 'Lab_Order__c',
                actionName: 'view'
            }
        });
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
            const allRows = await this.fetchAllRowsForExport();
            const workbookXml = this.buildExportWorkbookXml(allRows);
            const fileName = this.buildExportFilename();
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

    async fetchAllRowsForExport() {
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
        addRow([
            textCell('Order Name', 'TableHeader'),
            textCell('Amount (USD)', 'TableHeader'),
            textCell('Created Date', 'TableHeader'),
            textCell('Status', 'TableHeader'),
            textCell('MoR Type', 'TableHeader')
        ]);

        rows.forEach((row) => {
            addRow([
                textCell(row.name || ''),
                textCell(this.formatCurrencyFull(row.amount), 'ValueCell'),
                textCell(row.createdDate || ''),
                textCell(row.status || ''),
                textCell(row.mor || '')
            ]);
        });

        return `<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
  <Styles>
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
  </Styles>
  <Worksheet ss:Name="${this.escapeXml((this.cardTitle || 'Orders').slice(0, 30))}">
    <Table>
      <Column ss:AutoFitWidth="0" ss:Width="310"/>
      <Column ss:AutoFitWidth="0" ss:Width="150"/>
      <Column ss:AutoFitWidth="0" ss:Width="140"/>
      <Column ss:AutoFitWidth="0" ss:Width="220"/>
      <Column ss:AutoFitWidth="0" ss:Width="100"/>
      ${xmlRows.join('')}
    </Table>
  </Worksheet>
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
            summary.push(['Realized % of Gross', this.formatPercent(partner.realizedPercentOfGross)]);
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

    buildExportFilename() {
        const safePartner = (this.partnerName || 'Partner').replace(/[^a-zA-Z0-9-_ ]/g, '').trim().replace(/\s+/g, '_');
        const safeCard = (this.cardTitle || 'Orders').replace(/[^a-zA-Z0-9-_ ]/g, '').trim().replace(/\s+/g, '_');
        const stamp = new Date().toISOString().slice(0, 10);
        return `${safePartner || 'Partner'}_${safeCard || 'Orders'}_${stamp}.xls`;
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