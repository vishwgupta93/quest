import { LightningElement, api} from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import getLineItems from '@salesforce/apex/OrderLookupCtrl.getLineItemsByOrderNumber';
import CUSTOMER_SERVICE_NUMBER from '@salesforce/label/c.quest_CS_phone_number';
import ERRORMSG_ORDER_NOTFOUND from '@salesforce/label/c.ErrorMsgOrderNumberNotFound';
import ORDERLOOKUP_PLACEHOLDER_TEXT from '@salesforce/label/c.OrderLookupPlaceHolderText';
import ERRORMSG_ORDERCANNOT_REG from '@salesforce/label/c.ErrorMsgWhenOrderCantReg';
import ERRORMSG_CANCELORDER from '@salesforce/label/c.ErrorMsg_Cancelled_Order';
import ERRORMSG_EXPIREDORDER from '@salesforce/label/c.ErrorMg_Expired_Order';
import ERRORMSG_HOMEKITORDER from '@salesforce/label/c.ErrorMsg_HomeKit_Order';
import ERRORMSG_PACKHEALTHORDER from '@salesforce/label/c.Errormsg_PackHealth';
import CustomerCareNumber from '@salesforce/label/c.Customer_Care_Number';

export default class OrderLookup extends NavigationMixin(LightningElement) {
    errorMsgOrderCantReg = ERRORMSG_ORDERCANNOT_REG;
    errorMsgCanceledOrder = ERRORMSG_CANCELORDER;
    errorMsgExpireOrder = ERRORMSG_EXPIREDORDER;
    errorMsgHomeKitOrder = ERRORMSG_HOMEKITORDER;
    errorMsgPackHealth = ERRORMSG_PACKHEALTHORDER;
    @api orderNumber = "";
    showSpinner = false;
    @api errormsg;
    @api isdirectlink;
    csNumber = CUSTOMER_SERVICE_NUMBER;
    errorMSgOrdernotFound = ERRORMSG_ORDER_NOTFOUND;
    placeHolderText = ORDERLOOKUP_PLACEHOLDER_TEXT;
    disableRegistrationBtn = false;
    label = {
        CustomerCareNumber
    };

     toPlainObject(obj) {
        return JSON.parse(JSON.stringify(obj));
    }

    handleOrderNumberChange(event) {
        this.orderNumber = event.currentTarget.value ? event.currentTarget.value.trim() : "";
        console.log('this.orderNumber',this.orderNumber);
    }
    handleKeypress(event){
        if (event.key === "Enter") {
            event.preventDefault();
            this.orderNumber = event.currentTarget.value ? event.currentTarget.value.trim() : "";
            this.searchOrder();
        }
    }
    get panelStye(){
        return this.errormsg || !this.isdirectlink ? '' : 'slds-hide';
    }
    @api searchOrder(event) {
        console.log('@16OrderLokkup---->',this.orderNumber);
        if (this.orderNumber) {
            this.errormsg = '';
            this.showSpinner = true;
            getLineItems({ orderNumber: this.orderNumber })
                .then(result => {
                    this.showSpinner = false;
                    console.log('results', JSON.stringify(result));
                    //if (result && result.length > 0) {
                    let resultObj = JSON.parse(result);
                    console.log('--52--',resultObj);
                    if (resultObj && resultObj.orderInfo.fos.length > 0) {
                        this.setResultTests(resultObj);
                    } else {
                        this.errormsg =  this.errorMSgOrdernotFound;
                    }
                })
                .catch(error => {
                    this.showSpinner = false;
                    console.log('ERROR->', JSON.stringify(error));
                    this.errormsg = 'Error while getting orders.';
                })
        } else {
            this.errormsg = 'Please enter Order Number.';
            this.showSpinner = false;
        }
    }
    setResultTests(result){
        let orderStatusPSC = "";
        const testTypeSet = new Set();
        const status = result.orderInfo.fos.status;
        



        for (let i = 0; i < result.orderInfo.fos.length; i++) {
            for(let j=0; j < result.orderInfo.fos[i].lines.length; j++){
                let line = result.orderInfo.fos[i].lines[j];
                if(line.testType == 'PSC'){
                    orderStatusPSC = line.isRegistered === false ? "Not Registered" : "Registered" ;
                }
                testTypeSet.add(line.testType);
                console.log('testTyoeSet', testTypeSet);
            }
        }

    

        const atHome = testTypeSet.has("at_home");
        const inPerson = testTypeSet.has("PSC");
        const packhealth = testTypeSet.has("PackHealth");
        const consult = testTypeSet.has("consult");

        if ((atHome && inPerson) || (inPerson && packhealth) || (inPerson && consult)) {
            console.log('::orderStatusPSC::', orderStatusPSC);
            if (orderStatusPSC === "Registered") {
                this.disableRegistrationBtn = true;
                this.errormsg = this.errorMsgOrderCantReg;
            }
        } else if (atHome) {
            this.disableRegistrationBtn = true;
            this.errormsg = this.errorMsgHomeKitOrder;
        } else if (packhealth){
            this.disableRegistrationBtn = true;
            this.errormsg = this.errorMsgPackHealth;
        }else if (consult){
            this.disableRegistrationBtn = true;
            this.errormsg = this.errorMsgPackHealth;
        } 
        else if (inPerson) {
            if (status === "Expired") {
                this.disableRegistrationBtn = true;
                this.errormsg = this.errorMsgExpireOrder;
            } else if (status === "Cancelled") {
                this.disableRegistrationBtn = true;
                this.errormsg = this.errorMsgCanceledOrder;
            } else if (orderStatusPSC === "Registered") {
                this.disableRegistrationBtn = true;
                this.errormsg = this.errorMsgOrderCantReg;
            }
        }
        
        if(!this.errormsg){
            // First dispatch a checkcontext event to allow wrapper to verify context
            // before we dispatch the actual resulttests event
            const checkContextEvent = new CustomEvent("checkcontext", {
                detail: {
                    orderData: result,
                    orderNumber: result?.orderInfo?.orderNumber,
                    shouldDispatch: true // Flag that wrapper can modify
                },
                bubbles: true,
                composed: true,
                cancelable: true
            });
            this.dispatchEvent(checkContextEvent);
            
            // Check if wrapper set shouldDispatch to false (context mismatch)
            if (checkContextEvent.detail.shouldDispatch !== false) {
                const resulttests = new CustomEvent("resulttests", { 
                    detail: result,
                    bubbles: true,
                    composed: true // Allow event to bubble through shadow DOM boundaries
                });
                // Dispatches the event.
                this.dispatchEvent(resulttests);
            }
        }
    }
}