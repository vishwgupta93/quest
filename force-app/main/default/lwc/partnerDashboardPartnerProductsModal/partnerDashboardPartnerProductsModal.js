import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import getPartnerProductEditorData from '@salesforce/apex/PartnerDashboardController.getPartnerProductEditorData';

const COLUMNS = [
    {
        label: 'Product',
        fieldName: 'productName',
        type: 'text',
        wrapText: true
    },
    {
        label: 'Code / SKU / Ecomm ID',
        fieldName: 'productSubtitle',
        type: 'text',
        wrapText: true
    },
    {
        label: 'Product Price',
        fieldName: 'productPriceDisplay',
        type: 'text'
    },
    {
        label: 'Cancellation Fee',
        fieldName: 'cancellationFeeDisplay',
        type: 'text'
    }
];

export default class PartnerDashboardPartnerProductsModal extends LightningModal {
    @api partnerId;
    @api partnerName;

    columns = COLUMNS;
    rows = [];
    isLoading = false;
    errorMessage = '';

    connectedCallback() {
        this.loadProducts();
    }

    get hasRows() {
        return this.rows.length > 0;
    }

    get headerLabel() {
        return this.partnerName ? `${this.partnerName} Products` : 'Partner Products';
    }

    async loadProducts() {
        if (!this.partnerId) {
            this.errorMessage = 'No partner was provided.';
            return;
        }

        this.isLoading = true;
        this.errorMessage = '';

        try {
            const result = await getPartnerProductEditorData({ partnerId: this.partnerId });
            this.partnerName = result?.partnerName || this.partnerName;
            this.rows = (result?.productMaps || []).map((item) => ({
                id: item.mapId,
                productName: item.productName || '',
                productSubtitle: item.productSubtitle || 'NA',
                productPriceDisplay: this.formatCurrency(item.productPrice),
                cancellationFeeDisplay: this.formatCurrency(item.cancellationFee)
            }));
        } catch (error) {
            this.errorMessage = this.reduceError(error);
            this.rows = [];
        } finally {
            this.isLoading = false;
        }
    }

    handleClose() {
        this.close();
    }

    formatCurrency(value) {
        const numericValue = Number(value || 0);
        return `$${numericValue.toLocaleString(undefined, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        })}`;
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(', ');
        }

        if (typeof error?.body?.message === 'string') {
            return error.body.message;
        }

        if (typeof error?.message === 'string') {
            return error.message;
        }

        return 'Unable to load partner products.';
    }
}
