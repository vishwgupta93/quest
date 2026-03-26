import { LightningElement } from 'lwc';
import getPartnerPerformance from '@salesforce/apex/PartnerDashboardController.getPartnerPerformance';
import getPartnerDetails from '@salesforce/apex/PartnerDashboardController.getPartnerDetails';

const DEFAULT_DATE_RANGE = 'LAST_30_DAYS';

export default class PartnerDashboardPartnerDirectory extends LightningElement {

    partners = [];
    selectedPartner = null;
    selectedPartnerId = null;
    selectedDateRange = DEFAULT_DATE_RANGE;
    selectedCustomStartDate = null;
    selectedCustomEndDate = null;
    isLoadingPartners = true;
    isLoadingDetails = false;
    loadError;
    handleGlobalDateChange;

    connectedCallback() {
        this.initializeFromUrl();
        this.handleGlobalDateChange = this.handleGlobalDateChangeEvent.bind(this);
        window.addEventListener('partnerdashboardfilterschange', this.handleGlobalDateChange);
        this.loadPartners();
    }

    disconnectedCallback() {
        window.removeEventListener('partnerdashboardfilterschange', this.handleGlobalDateChange);
    }

    get showPartnerDetails() {
        return this.selectedPartner !== null;
    }

    get isDetailContext() {
        return !!this.selectedPartnerId;
    }

    get showDirectoryGrid() {
        return !this.showPartnerDetails && !this.isLoadingPartners;
    }

    initializeFromUrl() {
        const searchParams = new URLSearchParams(window.location.search);
        this.selectedPartnerId = searchParams.get('partnerId') || searchParams.get('partnerMapId');
        this.selectedDateRange = searchParams.get('dateRange') || DEFAULT_DATE_RANGE;
        this.selectedCustomStartDate = searchParams.get('customStart') || null;
        this.selectedCustomEndDate = searchParams.get('customEnd') || null;
    }

    async loadPartners() {
        this.isLoadingPartners = true;

        try {
            this.partners = await getPartnerPerformance({
                dateRange: this.selectedDateRange,
                customStartDate: this.selectedCustomStartDate,
                customEndDate: this.selectedCustomEndDate
            });
            this.loadError = undefined;

            if (this.selectedPartnerId && !this.selectedPartner) {
                await this.loadPartnerDetails(this.selectedPartnerId);
            }
        } catch (error) {
            this.loadError = error;
            this.partners = [];
            // eslint-disable-next-line no-console
            console.error('Partner directory load error', error);
        } finally {
            this.isLoadingPartners = false;
        }
    }

    async loadPartnerDetails(partnerId) {
        if (!partnerId) {
            return;
        }

        this.isLoadingDetails = true;
        this.selectedPartnerId = partnerId;
        this.loadError = undefined;

        try {
            this.selectedPartner = await getPartnerDetails({
                partnerId,
                dateRange: this.selectedDateRange,
                customStartDate: this.selectedCustomStartDate,
                customEndDate: this.selectedCustomEndDate
            });
            this.syncUrlState();
        } catch (error) {
            this.loadError = error;
            this.selectedPartner = null;
            // eslint-disable-next-line no-console
            console.error('Partner detail load error', error);
        } finally {
            this.isLoadingDetails = false;
        }
    }

    async handlePartnerSelect(event) {
        const detail = event.detail;
        const partnerId = detail?.partnerId ?? detail?.partnerMapId;
        await this.loadPartnerDetails(partnerId);
    }

    async handleGlobalDateChangeEvent(event) {
        const nextDateRange = event.detail.dateRange || DEFAULT_DATE_RANGE;
        const nextCustomStartDate = event.detail.customStartDate || null;
        const nextCustomEndDate = event.detail.customEndDate || null;

        if (
            this.selectedDateRange === nextDateRange
            && this.selectedCustomStartDate === nextCustomStartDate
            && this.selectedCustomEndDate === nextCustomEndDate
        ) {
            return;
        }

        this.selectedDateRange = nextDateRange;
        this.selectedCustomStartDate = nextCustomStartDate;
        this.selectedCustomEndDate = nextCustomEndDate;
        const activePartnerId = this.selectedPartnerId;

        if (activePartnerId) {
            this.syncUrlState();
            await this.loadPartners();
            await this.loadPartnerDetails(activePartnerId);
            return;
        }

        this.syncUrlState();
        await this.loadPartners();
    }

    handleBackToDirectory() {
        this.selectedPartner = null;
        this.selectedPartnerId = null;
        this.loadError = undefined;
        this.syncUrlState();
    }

    handleAddPartner() {
        // Placeholder until add-partner workflow is designed.
    }

    syncUrlState() {
        const url = new URL(window.location.href);

        if (this.selectedPartnerId) {
            url.searchParams.set('partnerId', this.selectedPartnerId);
            url.searchParams.delete('partnerMapId');
        } else {
            url.searchParams.delete('partnerId');
            url.searchParams.delete('partnerMapId');
        }

        if (this.selectedDateRange && this.selectedDateRange !== DEFAULT_DATE_RANGE) {
            url.searchParams.set('dateRange', this.selectedDateRange);
            if (this.selectedDateRange === 'CUSTOM' && this.selectedCustomStartDate && this.selectedCustomEndDate) {
                url.searchParams.set('customStart', this.selectedCustomStartDate);
                url.searchParams.set('customEnd', this.selectedCustomEndDate);
            } else {
                url.searchParams.delete('customStart');
                url.searchParams.delete('customEnd');
            }
        } else {
            url.searchParams.delete('dateRange');
            url.searchParams.delete('customStart');
            url.searchParams.delete('customEnd');
        }

        window.history.replaceState({}, '', `${url.pathname}${url.search}`);
    }
}