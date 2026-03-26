import { LightningElement } from 'lwc';
import questLogo from '@salesforce/resourceUrl/QuestLogo';

export default class PartnerDashboardSidebarNavigation extends LightningElement {

    currentPage = '';
    logoUrl = questLogo;
    communityBasePath = '/partnerdashboard';

    get menuItems(){

        const items = [
            { label:'Overview', page:'overview', icon:'utility:apps' },
            { label:'Partner Directory', page:'partner-directory', icon:'utility:user' },
            { label:'Revenue Analytics', page:'revenue-analytics', icon:'utility:trending' },
            { label:'Lab Map', page:'lab-map', icon:'utility:location' },
            { label:'Completion Analytics', page:'completion-analytics', icon:'utility:task' },
            { label:'Product Performance', page:'product-performance', icon:'utility:package' },
            { label:'Glossary', page:'glossary', icon:'utility:knowledge_base' },
            { label:'Settings', page:'settings', icon:'utility:settings' },
            { label:'Logout', page:'logout', icon:'utility:logout' }
        ];

        return items.map(item => {

            return {
                ...item,
                class: item.page === this.currentPage
                    ? 'nav-item active'
                    : 'nav-item'
            };

        });

    }

    get menuItemsComputed(){

        return this.menuItems.map(item => {

            return {
                ...item,
                class: item.page === this.currentPage
                    ? 'nav-item active'
                    : 'nav-item'
            }

        });

    }

    connectedCallback(){

        const path = window.location.pathname;
        this.communityBasePath = this.resolveCommunityBasePath(path);

        if(path === `${this.communityBasePath}/` || path === this.communityBasePath){
            this.currentPage = 'overview';
        }else{
            this.currentPage = path.split('/').pop();
        }

    }

    navigate(event){

        const page = event.currentTarget.dataset.page;

        let url;

        if(page === 'logout'){
            url = `${this.communityBasePath}/login`;
        } else if(page === 'overview'){
            url = `${this.communityBasePath}/`;
        }else{
            url = `${this.communityBasePath}/${page}`;
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