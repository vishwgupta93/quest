/**
 * handles creating lab order object/ table
 */
import { LightningElement, track, api } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import TIME_OUT from "@salesforce/label/c.ErrorMsg_TimeOut";
import ERRORMSG_ORDER_NOTFOUND from "@salesforce/label/c.ErrorMsgOrderNumberNotFound";
import decryptedData from "@salesforce/apex/OrderLookupCtrl.decryptData";
import createLabOrder from "@salesforce/apex/OrderLookupCtrl.createLabOrder";

export default class RegisterTests extends LightningElement {
  @api ordernumber;
  @api isdirectlink;
  deviceType = FORM_FACTOR;
  timeOut = TIME_OUT;
  errorMSgOrdernotFound = ERRORMSG_ORDER_NOTFOUND;
  errormsg;
  showOrderLookup = false;
  showSelectTests = false;
  showTesterDetails = false;
  showConfirmRegistration = false;
  showScheduleAppointment = false;
  showSpinner = false;
  orderNumber;
  decryptOrderNumber;
  registerTimeOutID;
  isDirectLink = false;
  @track labOrderPanelList;
  @track testResults = [];
  @track testerDetails = {};
  @track progressIndicatorSteps = [
    { StepNum: 1, StepName: "Find order", StepDescription: "" },
    { StepNum: 2, StepName: "Who's testing?", StepDescription: "" },
    { StepNum: 3, StepName: "Schedule appointment", StepDescription: "" },
  ];
  activeStep = 1;

  get main_panel_cls() {
    switch (this.deviceType) {
      case "Large":
        return "slds-grid screen_large";
        break;
      case "Medium":
        return "screen_medium";
        break;
      case "Small":
        return "screen_small";
        break;
      default:
        return "";
    }
  }
  get steps_col_css_cls() {
    return this.deviceType == "Large" ? "slds-col slds-size_2-of-6" : "";
  }
  get detail_col_css_cls() {
    return this.deviceType == "Large" ? "slds-col slds-size_4-of-6" : "";
  }
  get showCollapseBtn() {
    return this.deviceType != "Large";
  }

  connectedCallback() {
    this.orderNumber = "";
    
    // Check if ordernumber prop is passed from parent (wrapper)
    // If prop exists, use it and skip URL param check to prevent auto-advance after back navigation
    if (this.ordernumber) {
      this.orderNumber = this.ordernumber;
      // Use isdirectlink prop if provided, otherwise default to false to prevent auto-advance
      this.isDirectLink = this.isdirectlink || false;
      this.showOrderLookup = true;
      return;
    }
    
    // Only check URL params if no prop provided (standalone usage)
    const param = "ordernumber";
    const urlOrderNumber = this.getUrlParamValue(window.location.href, param);
    if (urlOrderNumber) {
      this.showSpinner = true;
      console.log("this.ordernumber:", urlOrderNumber);
      this.decryptedOrderNumber(urlOrderNumber).then((ordernumberD) => {
        if (ordernumberD) {
          this.isDirectLink = true;
          this.orderNumber = ordernumberD;
          this.showOrderLookup = true;
          console.log("@55 decryptOrderNumber", ordernumberD);
        } else {
          this.showSpinner = false;
        }
      });
    } else {
      this.showOrderLookup = true;
    }
  }

  async decryptedOrderNumber(encryptedOrderNumber) {
    try {
      const result = await decryptedData({ orderNumber: encryptedOrderNumber });
      this.showSpinner = false;
      this.decryptOrderNumber = result;
      console.log("results", result);
      return this.decryptOrderNumber;
    } catch (error) {
      this.showSpinner = false;
      this.isDirectLink = true;
      this.errormsg = this.errorMSgOrdernotFound;
      this.showOrderLookup = true;
      console.log("Error-->", error.body?.message || error.message);
      return null;
    }
  }
  hasRendered = false;
  renderedCallback() {
    // Only auto-advance if isDirectLink is true AND we haven't rendered yet AND orderNumber exists
    // Also respect the isdirectlink prop from parent to prevent auto-advance after back navigation
    const shouldAutoAdvance = this.isDirectLink && 
                              !this.hasRendered && 
                              this.orderNumber &&
                              (this.isdirectlink !== false); // Explicitly check prop to prevent auto-advance when false
    
    if (shouldAutoAdvance) {
      console.log("@90Check here::");
      this.hasRendered = true;
      this.searchOrder();
    }
  }

  getUrlParamValue(url, key) {
    return new URL(url).searchParams.get(key);
  }

  searchOrder() {
    this.template.querySelector("c-order-lookup").searchOrder();
    console.log("@103 Check here::");
    this.showSpinner = false;
  }

  backToOrderLookup(event) {
    this.showOrderLookup = true;
    this.showSelectTests = false;
    
    // Prepopulate orderNumber but prevent auto-advance
    // Keep the previous order number in the input field for convenience
    if (this.testResults?.orderInfo?.orderNumber) {
      this.orderNumber = this.testResults.orderInfo.orderNumber;
    }
    
    // Reset flags to prevent auto-search while keeping orderNumber prepopulated
    this.isDirectLink = false;
    this.hasRendered = false;
    
    // Clear test results to fully reset state
    this.testResults = [];

    this.progressIndicatorSteps[0].StepDescription = "";
    this.progressIndicatorSteps[2].StepDescription = "";
    this.progressIndicatorSteps = [...this.progressIndicatorSteps];
    this.activeStep = 1;
    this.clearTimout();

    // Notify parent to reset state
    this.dispatchEvent(new CustomEvent("back"));
  }
  navigateToRegister(event) {
    // Handle both event objects and direct data
    const orderData = event?.detail || event;
    this.testResults = orderData;
    this.showOrderLookup = false;
    this.showTesterDetails = true;
    this.progressIndicatorSteps[0].StepDescription =
      "Order #" + this.testResults.orderInfo.orderNumber;
    this.progressIndicatorSteps = [...this.progressIndicatorSteps];
    this.activeStep = 2;
    this.startTimer();

    // Emit search event with order number
    this.dispatchEvent(
      new CustomEvent("search", {
        detail: this.testResults.orderInfo.orderNumber,
      })
    );
  }

  /**
   * Public method to allow wrapper to trigger navigation with order data
   * @param {Object} orderData - Order data object
   */
  @api
  handleOrderData(orderData) {
    if (orderData) {
      this.navigateToRegister({ detail: orderData });
    }
  }

  startTimer() {
    this.clearTimout();
    this.registerTimeOutID = setTimeout(() => {
      if (this.activeStep == 2) {
        this.redirectToOrderLookup();
      }
    }, 1000 * 60 * 30);
  }
  clearTimout() {
    if (this.registerTimeOutID) {
      clearTimeout(this.registerTimeOutID);
    }
  }
  redirectToOrderLookup() {
    this.errormsg = this.timeOut;
    this.showOrderLookup = true;
    this.showTesterDetails = false;
    this.progressIndicatorSteps[0].StepDescription = "";
    this.progressIndicatorSteps[1].StepDescription = "";
    this.progressIndicatorSteps = [...this.progressIndicatorSteps];
    this.activeStep = 1;
  }

  navigateToConfirmRegistration(event) {
    this.testerDetails = event.detail;
    let testsWithAOE = false;
    for (
      let i = 0;
      i < this.testResults.orderInfo.fos.length && !testsWithAOE;
      i++
    ) {
      for (
        let j = 0;
        j < this.testResults.orderInfo.fos[i].lines.length && !testsWithAOE;
        j++
      ) {
        let line = this.testResults.orderInfo.fos[i].lines[j];
        if (line.testType == "PSC" && line.aoeRequired == true) {
          testsWithAOE = true;
        }
      }
    }
    if (testsWithAOE == true) {
      this.showTesterDetails = false;
      this.showConfirmRegistration = true;
      this.progressIndicatorSteps[1].StepDescription =
        this.testerDetails.Email__c;
      this.progressIndicatorSteps = [...this.progressIndicatorSteps];
      this.activeStep = 3;
    } else {
      this.callCreateLabOrder();
    }
  }
  async callCreateLabOrder() {
    this.showSpinner = true;
    let isServiceCheck = false;
    let orderItemIds = [];

    console.log("--183--", JSON.stringify(this.testResults));
    for (let i = 0; i < this.testResults.orderInfo.fos.length; i++) {
      for (let j = 0; j < this.testResults.orderInfo.fos[i].lines.length; j++) {
        let line = this.testResults.orderInfo.fos[i].lines[j];
        if (line.testType == "PSC") {
          orderItemIds.push(line.id);
          if (line.isService) {
            isServiceCheck = true;
          }
        }
      }
    }
    console.log("--192--", JSON.stringify(orderItemIds));
    createLabOrder({
      testerDetailId: this.testerDetails.Id,
      foLineIds: orderItemIds,
      isService: isServiceCheck,
    })
      .then((result) => {
        this.showSpinner = false;
        console.log("SUCCESS...!!! FLOW");
        this.successmsg = "Lab Order has been created succesfully";
        console.log("--205--", result);
        console.log("--198--", JSON.stringify(result));
        if (result && result.length > 0) {
          let resultObj = JSON.parse(result);
          this.labOrderPanelList = resultObj;
          this.showConfirmRegistration = false;
          this.showTesterDetails = false;
          this.showScheduleAppointment = true;
          this.progressIndicatorSteps[1].StepDescription =
            this.testerDetails.Email__c;
          this.progressIndicatorSteps = [...this.progressIndicatorSteps];
          this.activeStep = 4;
        }
      })
      .catch((error) => {
        this.showSpinner = false;
        console.log("Error...!!! FLOW ERROR");
        this.errormsg = "An Error Occurred.";
      });
  }
  backToMyDetails(event) {
    this.showTesterDetails = true;
    this.showConfirmRegistration = false;

    this.progressIndicatorSteps = [...this.progressIndicatorSteps];
    this.activeStep = 2;
  }
  navigateToScheduleAppointment(event) {
    this.labOrderPanelList = event.detail;
    this.activeStep = 4; //all  completed
    this.showConfirmRegistration = false;
    this.showScheduleAppointment = true;
  }
}