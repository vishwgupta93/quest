import { LightningElement, api } from 'lwc';

const DEFAULT_DATE_RANGE = 'LAST_30_DAYS';
const CUSTOM_DATE_RANGE = 'CUSTOM';

export default class PartnerDashboardPageFilters extends LightningElement {

    @api title;
    @api subtitle;
    @api embedded = false;
    @api showActions = false;
    @api showCategoryFilter = false;
    @api searchPlaceholder = 'Search partners...';
    @api selectedPartnerId;

    selectedDateRange = DEFAULT_DATE_RANGE;
    selectedCustomStartDate;
    selectedCustomEndDate;
    _showPartnerSearch = true;
    _showDateRange = true;

    @api
    get showPartnerSearch() {
        return this._showPartnerSearch;
    }

    set showPartnerSearch(value) {
        this._showPartnerSearch = value !== false && value !== 'false';
    }

    @api
    get showDateRange() {
        return this._showDateRange;
    }

    set showDateRange(value) {
        this._showDateRange = value !== false && value !== 'false';
    }

    @api
    get dateRange() {
        return this.selectedDateRange;
    }

    set dateRange(value) {
        this.selectedDateRange = value || DEFAULT_DATE_RANGE;
    }

    @api
    get customStartDate() {
        return this.selectedCustomStartDate;
    }

    set customStartDate(value) {
        this.selectedCustomStartDate = value || null;
    }

    @api
    get customEndDate() {
        return this.selectedCustomEndDate;
    }

    set customEndDate(value) {
        this.selectedCustomEndDate = value || null;
    }

    get dateRangeOptions() {
        return [
            { label: 'Last 30 days', value: 'LAST_30_DAYS' },
            { label: 'Last 60 days', value: 'LAST_60_DAYS' },
            { label: 'Last 90 days', value: 'LAST_90_DAYS' },
            { label: 'Year to Date', value: 'YEAR_TO_DATE' },
            { label: 'Custom', value: CUSTOM_DATE_RANGE }
        ];
    }

    get categoryOptions() {
        return [
            { label: 'All Categories', value: 'ALL' }
        ];
    }

    get containerClass() {
        return this.embedded
            ? 'filters-card embedded'
            : 'filters-card';
    }

    get filtersGridClass() {
        const filterCount = [this.showPartnerSearch, this.showDateRange, this.showCategoryFilter]
            .filter(Boolean)
            .length;

        if (filterCount <= 1) {
            return 'filters-grid single-filter';
        }

        if (filterCount === 2) {
            return 'filters-grid two-filters';
        }

        return 'filters-grid';
    }

    get dateRangeColumnSize() {
        return this.showCategoryFilter ? '2' : '3';
    }

    get categoryColumnSize() {
        return this.showPartnerSearch ? '2' : '3';
    }

    get showCustomDateSection() {
        return this.selectedDateRange === CUSTOM_DATE_RANGE;
    }

    get disableApplyCustomDates() {
        return !this.selectedCustomStartDate
            || !this.selectedCustomEndDate
            || this.selectedCustomStartDate > this.selectedCustomEndDate;
    }

    handlePartnerChange(event) {
        const partnerId = event.detail.recordId;

        if (!partnerId) {
            return;
        }

        this.dispatchEvent(
            new CustomEvent('partnerselect', {
                detail: {
                    partnerId,
                    dateRange: this.selectedDateRange,
                    customStartDate: this.selectedCustomStartDate || null,
                    customEndDate: this.selectedCustomEndDate || null
                }
            })
        );

        window.dispatchEvent(
            new CustomEvent('partnerdashboardpartnerselect', {
                detail: {
                    partnerId,
                    dateRange: this.selectedDateRange,
                    customStartDate: this.selectedCustomStartDate || null,
                    customEndDate: this.selectedCustomEndDate || null
                }
            })
        );
    }

    handleDateRangeChange(event) {
        this.selectedDateRange = event.detail.value;

        if (this.selectedDateRange !== CUSTOM_DATE_RANGE) {
            this.selectedCustomStartDate = null;
            this.selectedCustomEndDate = null;
            this.dispatchDateRangeChange();
        }
    }

    handleCustomStartDateChange(event) {
        this.selectedCustomStartDate = event.target.value;
    }

    handleCustomEndDateChange(event) {
        this.selectedCustomEndDate = event.target.value;
    }

    handleApplyCustomDates() {
        if (this.disableApplyCustomDates) {
            return;
        }
        this.dispatchDateRangeChange();
    }

    handleClearCustomDates() {
        this.selectedCustomStartDate = null;
        this.selectedCustomEndDate = null;
        this.selectedDateRange = DEFAULT_DATE_RANGE;
        this.dispatchDateRangeChange();
    }

    dispatchDateRangeChange() {
        this.dispatchEvent(
            new CustomEvent('datechange', {
                detail: {
                    dateRange: this.selectedDateRange,
                    customStartDate: this.selectedCustomStartDate || null,
                    customEndDate: this.selectedCustomEndDate || null
                }
            })
        );

        window.dispatchEvent(
            new CustomEvent('partnerdashboardfilterschange', {
                detail: {
                    dateRange: this.selectedDateRange,
                    customStartDate: this.selectedCustomStartDate || null,
                    customEndDate: this.selectedCustomEndDate || null
                }
            })
        );
    }

    handleExportData() {
        this.dispatchEvent(new CustomEvent('export'));
    }

    handleGenerateReport() {
        this.dispatchEvent(new CustomEvent('generatereport'));
    }
}