import { LightningElement, api } from 'lwc';

export default class PartnerDashboardPartnerDirectoryTile extends LightningElement {

    @api partner;

    naLabel = 'NA';
    hasLoggedRisk = false;

    renderedCallback() {
        if (this.hasLoggedRisk || !this.partner) return;

        // Helps confirm that the updated conditional rendering logic is executing.
        // Remove once validated.
        // eslint-disable-next-line no-console
        console.log('Partner risk debug', {
            partnerId: this.partner.partnerId,
            cancellationRiskOrders: this.partner.cancellationRiskOrders,
            showCancellationRisk: this.showCancellationRisk
        });

        this.hasLoggedRisk = true;
    }

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

    formatMillions(value) {

        const numericValue = Number(value || 0);

        if (numericValue >= 1000000000) {
            return `$${(numericValue / 1000000000).toFixed(1)}B`;
        }

        if (numericValue >= 1000000) {
            return `$${(numericValue / 1000000).toFixed(1)}M`;
        }

        return `$${numericValue.toLocaleString(undefined, {
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        })}`;
    }

    formatText(value) {
        return value ? value : this.naLabel;
    }
}