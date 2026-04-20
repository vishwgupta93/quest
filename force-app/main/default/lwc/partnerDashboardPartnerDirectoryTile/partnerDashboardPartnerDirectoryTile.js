import { LightningElement, api } from 'lwc';

export default class PartnerDashboardPartnerDirectoryTile extends LightningElement {

    @api partner;

    naLabel = 'NA';

    get categoryLabel() {
        return this.formatText(this.partner?.category);
    }

    get regionLabel() {
        return this.formatText(this.partner?.region);
    }

    get phoneLabel() {
        return this.formatText(this.partner?.phone);
    }

    get emailLabel() {
        return this.formatText(this.partner?.email);
    }

    get grossRevenueLabel() {
        return this.formatMillions(this.partner?.grossRevenue);
    }

    get riskRevenueLabel() {
        return this.formatMillions(this.partner?.revenueAtRisk);
    }

    get riskOrdersLabel() {
        return this.partner?.cancellationRiskOrders ?? 0;
    }

    get showCancellationRisk() {
        return Number(this.partner?.cancellationRiskOrders ?? 0) > 0;
    }

    handleClick() {

        this.dispatchEvent(
            new CustomEvent('partnerselect', {
                detail: this.partner
            })
        );
    }

    handleEditClick(event) {
        event.stopPropagation();
        this.dispatchEvent(
            new CustomEvent('partneredit', {
                detail: this.partner
            })
        );
    }

    handleKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleClick();
        }
    }

    formatMillions(value) {

        const numericValue = Number(value || 0);

        return `$${numericValue.toLocaleString(undefined, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        })}`;
    }

    formatText(value) {
        return value ? value : this.naLabel;
    }
}
