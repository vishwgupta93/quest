import { LightningElement, track } from 'lwc';
import searchPartnerProducts from '@salesforce/apex/PartnerDashboardController.searchPartnerProducts';
import savePartnerProducts from '@salesforce/apex/PartnerDashboardController.savePartnerProducts';
import getPartnerProductEditorData from '@salesforce/apex/PartnerDashboardController.getPartnerProductEditorData';

export default class PartnerDashboardAddPartner extends LightningElement {

    @track productRows = [];
    createdPartnerId;
    createdPartnerName = '';
    successMessage = '';
    errorMessage = '';
    isSavingProducts = false;
    rowSequence = 0;
    deletedProductMapIds = [];
    editingPartnerId = null;
    showProductsStep = false;

    connectedCallback() {
        const searchParams = new URLSearchParams(window.location.search);
        this.editingPartnerId = searchParams.get('partnerId') || null;
    }

    get communityBasePath() {
        const segments = (window.location.pathname || '/').split('/').filter(Boolean);
        return segments.length ? `/${segments[0]}` : '';
    }

    get isEditMode() {
        return Boolean(this.editingPartnerId);
    }

    get cardTitle() {
        return this.isEditMode ? 'Edit Partner' : 'Add New Partner';
    }

    get introText() {
        return this.isEditMode
            ? 'Update the partner record and manage partner products.'
            : 'Create a new partner record for the portal directory.';
    }

    get showPartnerProductsStep() {
        return this.showProductsStep;
    }

    get partnerFormRecordId() {
        return this.isEditMode ? this.editingPartnerId : null;
    }

    get partnerSubmitLabel() {
        return this.isEditMode ? 'Save and Continue' : 'Save and Continue';
    }

    get hasProductRows() {
        return this.productRows.length > 0;
    }

    get hasPendingDeletes() {
        return this.deletedProductMapIds.length > 0;
    }

    get disableSaveProducts() {
        return this.isSavingProducts || (!this.hasValidProductRows && !this.hasPendingDeletes);
    }

    get saveProductsLabel() {
        return this.isSavingProducts ? 'Saving...' : 'Save Partner Products';
    }

    get finishLabel() {
        return this.isEditMode ? 'Cancel' : 'Finish Without Products';
    }

    get hasValidProductRows() {
        return this.productRows.some((row) => row.selectedProductId && row.productPrice !== '');
    }

    handlePartnerSubmit() {
        this.errorMessage = '';
        this.successMessage = '';
    }

    async handlePartnerSuccess(event) {
        this.createdPartnerId = event.detail?.id;
        this.createdPartnerName = this.resolveCreatedPartnerName();
        this.errorMessage = '';
        await this.loadPartnerProductEditorData();
        this.showProductsStep = true;
        this.successMessage = this.isEditMode
            ? 'Partner updated. Review partner products below and save any changes.'
            : 'Partner created. Add partner products below or finish without products.';
    }

    handlePartnerError() {
        this.successMessage = '';
        this.errorMessage = this.isEditMode
            ? 'We could not update the partner. Please review the form and try again.'
            : 'We could not create the partner. Please review the form and try again.';
    }

    async loadPartnerProductEditorData() {
        if (!this.createdPartnerId) {
            return;
        }

        try {
            const editorData = await getPartnerProductEditorData({ partnerId: this.createdPartnerId });
            this.createdPartnerName = editorData?.partnerName || this.createdPartnerName;
            this.deletedProductMapIds = [];
            this.productRows = (editorData?.productMaps || []).map((item) => this.createRowFromExistingMap(item));

            if (!this.productRows.length) {
                this.handleAddProductRow();
            }
        } catch (error) {
            this.errorMessage = this.reduceError(error);
        }
    }

    handleAddProductRow() {
        this.rowSequence += 1;
        this.productRows = [
            ...this.productRows,
            this.createEmptyRow(this.rowSequence)
        ];
    }

    handleFinishWithoutProducts() {
        this.navigateToPartnerDetail(this.createdPartnerId || this.editingPartnerId);
    }

    handleBackToPartnerForm() {
        this.errorMessage = '';
        this.successMessage = '';
        this.showProductsStep = false;
    }

    async handleSaveProducts() {
        const rowsToSave = this.productRows
            .filter((row) => row.selectedProductId && row.productPrice !== '')
            .map((row) => ({
                mapId: row.mapId || null,
                productId: row.selectedProductId,
                productPrice: Number(row.productPrice),
                cancellationFee: row.cancellationFee === '' ? null : Number(row.cancellationFee)
            }));

        if (!rowsToSave.length && !this.deletedProductMapIds.length) {
            this.errorMessage = 'Add at least one product with a product price before saving.';
            return;
        }

        this.isSavingProducts = true;
        this.errorMessage = '';

        try {
            await savePartnerProducts({
                partnerId: this.createdPartnerId || this.editingPartnerId,
                productMapsJson: JSON.stringify(rowsToSave),
                deletedProductMapIdsJson: JSON.stringify(this.deletedProductMapIds)
            });
            this.successMessage = this.isEditMode
                ? 'Partner products updated successfully. Redirecting to Partner Detail...'
                : 'Partner and partner products saved successfully. Redirecting to Partner Detail...';
            this.navigateToPartnerDetail(this.createdPartnerId || this.editingPartnerId, 600);
        } catch (error) {
            this.errorMessage = this.reduceError(error);
        } finally {
            this.isSavingProducts = false;
        }
    }

    async handleProductSearchChange(event) {
        const rowId = event.target.dataset.rowId;
        const searchTerm = event.target.value;
        const existingRow = this.productRows.find((item) => item.rowId === rowId);
        const shouldClearSelection = !searchTerm || (
            existingRow?.selectedProductId &&
            searchTerm !== existingRow.selectedProductName
        );

        this.updateRow(rowId, {
            searchTerm,
            selectedProductId: shouldClearSelection ? null : existingRow?.selectedProductId,
            selectedProductName: shouldClearSelection ? '' : existingRow?.selectedProductName,
            selectedProductSubtitle: shouldClearSelection ? '' : existingRow?.selectedProductSubtitle,
            mapId: existingRow?.mapId || null,
            showResults: false,
            results: []
        });

        if (!searchTerm || searchTerm.trim().length < 2) {
            return;
        }

        try {
            const results = await searchPartnerProducts({ searchTerm });
            this.updateRow(rowId, {
                results,
                showResults: results.length > 0
            });
        } catch (error) {
            this.errorMessage = this.reduceError(error);
        }
    }

    handleSelectProduct(event) {
        const rowId = event.currentTarget.dataset.rowId;
        const productId = event.currentTarget.dataset.productId;
        const row = this.productRows.find((item) => item.rowId === rowId);
        const selectedProduct = row?.results?.find((item) => item.id === productId);

        if (!selectedProduct) {
            return;
        }

        this.updateRow(rowId, {
            selectedProductId: selectedProduct.id,
            selectedProductName: selectedProduct.name,
            selectedProductSubtitle: selectedProduct.subtitle,
            searchTerm: selectedProduct.name,
            results: [],
            showResults: false
        });
    }

    handleRowValueChange(event) {
        const rowId = event.target.dataset.rowId;
        const field = event.target.dataset.field;
        this.updateRow(rowId, {
            [field]: event.target.value
        });
    }

    handleRemoveProductRow(event) {
        const rowId = event.currentTarget.dataset.rowId;
        const row = this.productRows.find((item) => item.rowId === rowId);
        if (row?.mapId) {
            this.deletedProductMapIds = [...this.deletedProductMapIds, row.mapId];
        }
        this.productRows = this.productRows.filter((item) => item.rowId !== rowId);
    }

    handleCancel() {
        this.navigateToPartnerDirectory(this.editingPartnerId);
    }

    createEmptyRow(sequence) {
        return {
            rowId: `row-${sequence}`,
            mapId: null,
            searchInputId: `product-search-${sequence}`,
            searchTerm: '',
            selectedProductId: null,
            selectedProductName: '',
            selectedProductSubtitle: '',
            productPrice: '',
            cancellationFee: '',
            results: [],
            showResults: false
        };
    }

    createRowFromExistingMap(item) {
        this.rowSequence += 1;
        return {
            rowId: `row-${this.rowSequence}`,
            mapId: item.mapId,
            searchInputId: `product-search-${this.rowSequence}`,
            searchTerm: item.productName || '',
            selectedProductId: item.productId || null,
            selectedProductName: item.productName || '',
            selectedProductSubtitle: item.productSubtitle || '',
            productPrice: item.productPrice ?? '',
            cancellationFee: item.cancellationFee ?? '',
            results: [],
            showResults: false
        };
    }

    updateRow(rowId, changes) {
        this.productRows = this.productRows.map((row) =>
            row.rowId === rowId
                ? { ...row, ...changes }
                : row
        );
    }

    resolveCreatedPartnerName() {
        const nameField = this.template.querySelector('lightning-input-field[field-name="Name"]');
        return nameField?.value || this.createdPartnerName || 'the partner';
    }

    navigateToPartnerDirectory(partnerId, delayMs = 0) {
        const query = new URLSearchParams();
        if (partnerId) {
            query.set('partnerId', partnerId);
        }

        const targetUrl = `${this.communityBasePath}/partner-directory${query.toString() ? `?${query.toString()}` : ''}`;

        window.setTimeout(() => {
            window.location.href = targetUrl;
        }, delayMs);
    }

    navigateToPartnerDetail(partnerId, delayMs = 0) {
        this.navigateToPartnerDirectory(partnerId, delayMs);
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

        return 'Something went wrong while saving partner products.';
    }
}
