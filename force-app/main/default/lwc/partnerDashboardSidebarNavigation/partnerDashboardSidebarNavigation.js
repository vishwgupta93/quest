import { LightningElement } from 'lwc';
import questLogo from '@salesforce/resourceUrl/QuestLogo';

const MENU_ITEMS = [
    { label: 'Overview', page: 'overview', icon: 'utility:apps' },
    { label: 'Partner Directory', page: 'partner-directory', icon: 'utility:user' },
    { label: 'Add Partner', page: 'add-partner', icon: 'utility:adduser' },
    // { label: 'Revenue Analytics', page: 'revenue-analytics', icon: 'utility:trending' },
    // { label: 'Lab Map', page: 'lab-map', icon: 'utility:location' },
    // { label: 'Completion Analytics', page: 'completion-analytics', icon: 'utility:task' },
    // { label: 'Product Performance', page: 'product-performance', icon: 'utility:package' },
    { label: 'Glossary', page: 'glossary', icon: 'utility:knowledge_base' },
    // { label: 'Settings', page: 'settings', icon: 'utility:settings' },
    { label: 'Logout', page: 'logout', icon: 'utility:logout' }
];

export default class PartnerDashboardSidebarNavigation extends LightningElement {

    currentPage = 'overview';
    logoUrl = questLogo;
    communityBasePath = '/partnerdashboard';

    get menuItems() {
        return MENU_ITEMS;
    }

    connectedCallback() {
        const path = window.location.pathname;
        this.communityBasePath = this.resolveCommunityBasePath(path);

        if (path === `${this.communityBasePath}/` || path === this.communityBasePath) {
            this.currentPage = 'overview';
        } else {
            this.currentPage = path.split('/').pop();
        }
    }

    handleSelect(event) {
        const page = event.detail.name;

        if (!page || page === this.currentPage) {
            return;
        }

        let url;

        if (page === 'logout') {
            url = `${this.communityBasePath}/login`;
        } else if (page === 'overview') {
            url = `${this.communityBasePath}/`;
        } else {
            url = `${this.communityBasePath}/${page}`;
        }

        const currentUrl = new URL(window.location.href);
        const targetUrl = new URL(url, window.location.origin);

        if (
            currentUrl.pathname === targetUrl.pathname &&
            currentUrl.search === targetUrl.search
        ) {
            return;
        }

        window.location.href = url;
    }

    resolveCommunityBasePath(path) {
        const segments = (path || '/').split('/').filter(Boolean);

        if (!segments.length) {
            return '';
        }

        return `/${segments[0]}`;
    }
}
