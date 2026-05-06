import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getAccessToken from '@salesforce/apex/QuestSchedulingController.getAccessToken';
import getConfig from '@salesforce/apex/QuestSchedulingController.getConfig';
import decryptOrderId from '@salesforce/apex/QuestSchedulingController.decryptOrderId';

const VF_PAGE_PATH = '/scheduleappointment/apex/QuestSchedulingPage';

export default class QuestSchedulingWidget extends LightningElement {
    @api orderId;

    @track isLoading     = false;
    @track isInitialized = false;
    @track errorMessage;
    @track iframeUrl;

    _vfOrigin;
    _messageHandler;

    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        this.pageRef = pageRef;
        if (pageRef?.state?.orderId && !this.isInitialized && !this.isLoading) {
            this.handleScheduleClick();
        }
    }

    get effectiveOrderId() {
        return this.pageRef?.state?.orderId || this.orderId;
    }

    get effectiveAppointmentId() {
        return this.pageRef?.state?.appointmentId || null;
    }

    get showScheduleButton() {
        return !this.isInitialized && !this.isLoading;
    }

    connectedCallback() {
        this._messageHandler = this.handlePostMessage.bind(this);
        window.addEventListener('message', this._messageHandler);
        if (this.orderId) {
            this.handleScheduleClick();
        }
    }

    disconnectedCallback() {
        window.removeEventListener('message', this._messageHandler);
    }

    async handleScheduleClick() {
        if (!this.effectiveOrderId) {
            this.errorMessage = 'No order ID provided.';
            return;
        }

        this.isLoading    = true;
        this.errorMessage = null;

        try {
            const [plainOrderId, token, config] = await Promise.all([
                decryptOrderId({ encryptedId: this.effectiveOrderId }),
                getAccessToken(),
                getConfig()
            ]);

            this._vfOrigin = config.vfOrigin;
            const vfPage   = this._vfOrigin + VF_PAGE_PATH;

            const params = new URLSearchParams({
                token,
                orderId: plainOrderId,
                baseUrl: config.apiBaseUrl,
                ...(this.effectiveAppointmentId && { appointmentId: this.effectiveAppointmentId })
            });
            this.iframeUrl     = `${vfPage}?${params.toString()}`;
            this.isInitialized = true;
        } catch (error) {
            this.errorMessage = error.body?.message ?? error.message ?? 'An unexpected error occurred.';
        } finally {
            this.isLoading = false;
        }
    }

    handleBack() {
        window.history.back();
    }

    async handlePostMessage(event) {
        if (event.origin !== this._vfOrigin || !event.data?.type) return;

        const { type, result, error } = event.data;

        if (type === 'QUEST_RESIZE') {
            const iframe = this.template.querySelector('.scheduling-frame');
            if (iframe && event.data.height > 0) {
                iframe.style.height = event.data.height + 'px';
            }

        } else if (type === 'QUEST_COMPLETE') {
            console.log('Quest scheduling complete:', JSON.stringify(result));

        } else if (type === 'QUEST_ERROR') {
            console.error('Quest SDK error:', JSON.stringify(error));
            this.errorMessage  = 'Scheduling error. Please try again.';
            this.isInitialized = false;
            this.iframeUrl     = null;

        } else if (type === 'QUEST_TOKEN_EXPIRED') {
            try {
                const newToken = await getAccessToken();
                const iframe   = this.template.querySelector('.scheduling-frame');
                if (iframe) {
                    iframe.contentWindow.postMessage(
                        { type: 'QUEST_NEW_TOKEN', token: newToken },
                        this._vfOrigin
                    );
                }
            } catch (e) {
                this.errorMessage  = 'Session expired. Please try again.';
                this.isInitialized = false;
                this.iframeUrl     = null;
            }
        }
    }
}
