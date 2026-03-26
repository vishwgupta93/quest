import { LightningElement } from 'lwc';
import questLogo from '@salesforce/resourceUrl/QuestLogo';

export default class PartnerDashboardThemeLayout extends LightningElement {

    isSidebarOpen = false;
    isAuthPage = false;
    logoUrl = questLogo;
    currentPage = 'overview';
    selectedDateRange = 'LAST_30_DAYS';
    selectedPartnerId = null;
    selectedCustomStartDate = null;
    selectedCustomEndDate = null;

    connectedCallback() {
        const path = window.location.pathname.toLowerCase();
        this.isAuthPage = [
            '/login',
            '/forgotpassword',
            '/forgot-password',
            '/selfregister',
            '/self-registration'
        ].some(segment => path.includes(segment));

        this.currentPage = this.resolveCurrentPage(path);

        const searchParams = new URLSearchParams(window.location.search);
        this.selectedDateRange = searchParams.get('dateRange') || 'LAST_30_DAYS';
        this.selectedPartnerId = searchParams.get('partnerId') || searchParams.get('partnerMapId');
        this.selectedCustomStartDate = searchParams.get('customStart') || null;
        this.selectedCustomEndDate = searchParams.get('customEnd') || null;

        this.handleFilterChange = this.handleFilterChange.bind(this);
        this.handlePartnerSelect = this.handlePartnerSelect.bind(this);

        window.addEventListener('partnerdashboardfilterschange', this.handleFilterChange);
        window.addEventListener('partnerdashboardpartnerselect', this.handlePartnerSelect);
    }

    disconnectedCallback() {
        window.removeEventListener('partnerdashboardfilterschange', this.handleFilterChange);
        window.removeEventListener('partnerdashboardpartnerselect', this.handlePartnerSelect);
    }

    toggleSidebar() {

        this.isSidebarOpen = !this.isSidebarOpen;

    }

    get sidebarClass() {

        return this.isSidebarOpen
            ? 'sidebar-wrapper open'
            : 'sidebar-wrapper';

    }

    get overlayClass() {

        return this.isSidebarOpen
            ? 'overlay show'
            : 'overlay';

    }

    get showPageHeader() {
        return !this.isAuthPage && this.headerConfig !== null;
    }

    get headerConfig() {
        const headerByPage = {
            overview: {
                title: 'Partner Portal Overview',
                subtitle: 'Monitor partner performance and identify operational opportunities',
                showActions: false,
                showPartnerSearch: true,
                showDateRange: true,
                showCategoryFilter: false,
                searchPlaceholder: 'Search partners...'
            },
            'partner-directory': {
                title: 'Partner Directory',
                subtitle: 'Complete directory of all partner organizations',
                showActions: false,
                showPartnerSearch: true,
                showDateRange: true,
                showCategoryFilter: false,
                searchPlaceholder: 'Search partners...'
            },
            'revenue-analytics': {
                title: 'Revenue Analytics',
                subtitle: 'Detailed revenue trends and financial performance metrics',
                showActions: false,
                showPartnerSearch: true,
                showDateRange: true,
                showCategoryFilter: false,
                searchPlaceholder: 'Search partners...'
            },
            'lab-map': {
                title: 'PSC Locations',
                subtitle: 'Patient Service Center locations and customer coverage analysis',
                showActions: false,
                showPartnerSearch: false,
                showDateRange: true,
                showCategoryFilter: false,
                searchPlaceholder: ''
            },
            'completion-analytics': {
                title: 'Post-Purchase Funnel Analysis',
                subtitle: 'Track test completion rates from purchase to final results',
                showActions: false,
                showPartnerSearch: true,
                showDateRange: true,
                showCategoryFilter: false,
                searchPlaceholder: 'Search partners...'
            },
            'product-performance': {
                title: 'Product Performance',
                subtitle: 'Analyze order and revenue metrics by SKU',
                showActions: false,
                showPartnerSearch: true,
                showDateRange: true,
                showCategoryFilter: false,
                searchPlaceholder: 'Search partners...'
            },
            'add-partner': {
                title: 'Add New Partner',
                subtitle: 'Create a new partner configuration',
                showActions: false,
                showPartnerSearch: false,
                showDateRange: false,
                showCategoryFilter: false,
                searchPlaceholder: ''
            },
            glossary: {
                title: 'Metrics Glossary',
                subtitle: 'Definitions and formulas for key business metrics',
                showActions: false,
                showPartnerSearch: false,
                showDateRange: false,
                showCategoryFilter: false,
                searchPlaceholder: ''
            }
        };

        return headerByPage[this.currentPage] || null;
    }

    resolveCurrentPage(path) {
        if (path === '/partnerdashboard/' || path === '/partnerdashboard') {
            return 'overview';
        }

        return path.split('/').pop();
    }

    handleFilterChange(event) {
        this.selectedDateRange = event.detail?.dateRange || 'LAST_30_DAYS';
        this.selectedCustomStartDate = event.detail?.customStartDate || null;
        this.selectedCustomEndDate = event.detail?.customEndDate || null;
        const url = new URL(window.location.href);
        const currentPartnerId = url.searchParams.get('partnerId') || url.searchParams.get('partnerMapId');

        if (this.selectedDateRange === 'LAST_30_DAYS') {
            url.searchParams.delete('dateRange');
            url.searchParams.delete('customStart');
            url.searchParams.delete('customEnd');
        } else {
            url.searchParams.set('dateRange', this.selectedDateRange);
            if (this.selectedDateRange === 'CUSTOM' && this.selectedCustomStartDate && this.selectedCustomEndDate) {
                url.searchParams.set('customStart', this.selectedCustomStartDate);
                url.searchParams.set('customEnd', this.selectedCustomEndDate);
            } else {
                url.searchParams.delete('customStart');
                url.searchParams.delete('customEnd');
            }
        }

        if (currentPartnerId) {
            url.searchParams.set('partnerId', currentPartnerId);
            url.searchParams.delete('partnerMapId');
        }

        this.selectedPartnerId = currentPartnerId;

        window.history.replaceState({}, '', `${url.pathname}${url.search}`);
    }

    handlePartnerSelect(event) {
        const partnerId = event.detail?.partnerId ?? event.detail?.partnerMapId;

        if (!partnerId) {
            return;
        }

        this.selectedPartnerId = partnerId;

        const query = new URLSearchParams({
            partnerId,
            dateRange: this.selectedDateRange
        });
        if (this.selectedDateRange === 'CUSTOM' && this.selectedCustomStartDate && this.selectedCustomEndDate) {
            query.set('customStart', this.selectedCustomStartDate);
            query.set('customEnd', this.selectedCustomEndDate);
        }

        window.location.href = `/partnerdashboard/partner-directory?${query.toString()}`;
    }

}