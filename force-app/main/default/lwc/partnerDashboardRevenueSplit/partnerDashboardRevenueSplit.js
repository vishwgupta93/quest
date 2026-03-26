import { LightningElement, api } from 'lwc';

export default class PartnerDashboardRevenueSplit extends LightningElement {

    @api isLoading = false;
    @api qmorRevenue = 0;
    @api pmorRevenue = 0;
    @api grossRevenue = 0;

    get qmorFormatted() {
        return this.formatMillions(this.qmorRevenue);
    }

    get pmorFormatted() {
        return this.formatMillions(this.pmorRevenue);
    }

    get qmorPercent() {
        return this.calcPercent(this.qmorRevenue);
    }

    get pmorPercent() {
        return this.calcPercent(this.pmorRevenue);
    }

    get qmorPercentLabel() {
        return `${this.qmorPercent.toFixed(1)}% of Sales`;
    }

    get pmorPercentLabel() {
        return `${this.pmorPercent.toFixed(1)}% of Sales`;
    }

    get qmorProgressStyle() {
        return `width: ${this.qmorPercent}%`;
    }

    get pmorProgressStyle() {
        return `width: ${this.pmorPercent}%`;
    }

    calcPercent(value) {
        const gross = Number(this.grossRevenue || 0);
        if (!gross) return 0;
        return Math.min(100, Math.max(0, (Number(value || 0) / gross) * 100));
    }

    formatMillions(value) {
        const n = Number(value || 0);
        if (n >= 1e9) return `$${(n / 1e9).toFixed(1)}B`;
        if (n >= 1e6) return `$${(n / 1e6).toFixed(1)}M`;
        if (n >= 1e3) return `$${(n / 1e3).toFixed(1)}K`;
        return `$${n.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;
    }
}