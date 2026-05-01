import { LightningElement, track } from "lwc";
import isMinorOrder from "@salesforce/apex/OrderController.isMinorOrder";
import decryptedData from "@salesforce/apex/OrderLookupCtrl.decryptData";

export default class QRegisterTestsWrapper extends LightningElement {
  @track isMinor = false;
  @track showSpinner = false;
  @track orderNumber;
  @track isDirectLink = false;
  navigationType = null; // 'fresh' or 'back'
  pageShowHandler = null;
  cachedOrderNumber = null; // Store order number to preserve isMinor context
  cachedIsMinor = false; // Cache minor status per order number
  pendingOrderData = null; // Store order data when context switch is needed

  get hasOrderNumber() {
    return Boolean(this.orderNumber);
  }

  connectedCallback() {
    // Detect navigation type using pageshow event
    this.pageShowHandler = this.handlePageShow.bind(this);
    window.addEventListener('pageshow', this.pageShowHandler);
    
    // Listen for checkcontext events from order lookup components
    // This allows us to check minor status BEFORE resulttests is dispatched
    this.checkContextHandler = this.handleCheckContext.bind(this);
    this.addEventListener('checkcontext', this.checkContextHandler);
    
    this.checkUrlParams();
  }

  disconnectedCallback() {
    if (this.pageShowHandler) {
      window.removeEventListener('pageshow', this.pageShowHandler);
    }
    if (this.checkContextHandler) {
      this.removeEventListener('checkcontext', this.checkContextHandler);
    }
  }

  handlePageShow(event) {
    // If persisted is true, it means page was loaded from cache (back/forward button)
    if (event.persisted) {
      this.navigationType = 'back';
      console.log("[qRegisterTestsWrapper] Back/forward navigation detected");
      this.checkUrlParams();
    } else {
      // Fresh navigation
      this.navigationType = 'fresh';
    }
  }

  checkUrlParams() {
    const urlParams = new URLSearchParams(window.location.search);
    const urlOrderNumber = urlParams.get('ordernumber');
    
    if (urlOrderNumber) {
      // Each order number gets its own unique storage key to prevent interference
      // between different orders (e.g., order 1234 vs order 5678)
      const storageKey = `registration_auto_advance_${urlOrderNumber}`;
      const hasFlag = sessionStorage.getItem(storageKey);
      
      // Determine navigation type:
      // - If navigationType is explicitly 'back', it's back navigation
      // - If flag exists in sessionStorage, it's back navigation (we've seen this order before)
      // - Otherwise, it's fresh navigation (first time seeing this order number)
      if (this.navigationType === 'back' || hasFlag) {
        // Back navigation - clear flag and don't auto-advance
        sessionStorage.removeItem(storageKey);
        this.isDirectLink = false;
        console.log("[qRegisterTestsWrapper] Back navigation detected - auto-advance disabled");
      } else {
        // Fresh navigation - set flag and auto-advance
        sessionStorage.setItem(storageKey, 'true');
        this.isDirectLink = true;
        if (!this.navigationType) {
          this.navigationType = 'fresh';
        }
        console.log("[qRegisterTestsWrapper] Fresh navigation detected - auto-advance enabled");
      }
      
      // Decrypt and process order number
      this.processOrderNumber(urlOrderNumber);
    }
  }

  async processOrderNumber(encryptedOrderNumber) {
    if (!encryptedOrderNumber) return;
    
    this.showSpinner = true;
    console.log("[qRegisterTestsWrapper] Processing order number from URL");
    
    try {
      // Decrypt order number first
      const decryptedOrderNumber = await decryptedData({ orderNumber: encryptedOrderNumber });
      
      if (decryptedOrderNumber) {
        // Check if minor order using decrypted number
        const isMinorResult = await isMinorOrder({
          orderNumber: decryptedOrderNumber,
        });
        
        this.isMinor = isMinorResult;
        // Store decrypted order number for child components
        this.orderNumber = decryptedOrderNumber;
        // Cache order number and minor status for back navigation context
        this.cachedOrderNumber = decryptedOrderNumber;
        this.cachedIsMinor = isMinorResult;
        console.log("[qRegisterTestsWrapper] Order processed - isMinor:", this.isMinor, "isDirectLink:", this.isDirectLink, "orderNumber:", this.orderNumber);
      } else {
        console.error("[qRegisterTestsWrapper] Failed to decrypt order number");
        this.isDirectLink = false;
      }
    } catch (error) {
      console.error("[qRegisterTestsWrapper] Error processing order:", error);
      this.isDirectLink = false; // Disable auto-advance on error
    } finally {
      this.showSpinner = false;
    }
  }

  handleBack() {
    // Reset state when going back to lookup, but preserve isMinor context
    console.log("[qRegisterTestsWrapper] handleBack called - resetting state but preserving isMinor context");
    
    // Clear sessionStorage flag if orderNumber exists
    if (this.orderNumber) {
      const urlParams = new URLSearchParams(window.location.search);
      const urlOrderNumber = urlParams.get('ordernumber');
      if (urlOrderNumber) {
        const storageKey = `registration_auto_advance_${urlOrderNumber}`;
        sessionStorage.removeItem(storageKey);
      }
    }
    
    // Clear orderNumber prop so child shows lookup form, but preserve isMinor for component selection
    // isMinor is preserved so we know which component (registerTests vs registerTestsMinor) to render
    this.orderNumber = undefined;
    this.isDirectLink = false;
    this.navigationType = null;
    // Note: isMinor is NOT cleared - it's preserved so we render the correct component
    console.log("[qRegisterTestsWrapper] State reset - orderNumber:", this.orderNumber, "isMinor preserved:", this.isMinor, "cachedOrderNumber:", this.cachedOrderNumber);
  }

  /**
   * Handles checkcontext events from order lookup components
   * Checks minor status BEFORE resulttests event is dispatched
   * If context doesn't match, prevents resulttests and swaps components
   */
  async handleCheckContext(event) {
    const { orderData, orderNumber: orderNumberFromData } = event.detail;
    
    console.log("[qRegisterTestsWrapper] handleCheckContext intercepted - orderNumber:", orderNumberFromData);
    
    if (!orderNumberFromData) {
      console.warn("[qRegisterTestsWrapper] No order number in checkcontext event");
      return;
    }
    
    // Check if this is the same order we've seen before (from cache)
    let targetIsMinor;
    if (this.cachedOrderNumber === orderNumberFromData) {
      console.log("[qRegisterTestsWrapper] Using cached isMinor status for order:", orderNumberFromData);
      targetIsMinor = this.cachedIsMinor;
    } else {
      // New order number - check minor status BEFORE allowing navigation
      console.log("[qRegisterTestsWrapper] Checking minor status for order:", orderNumberFromData);
      this.showSpinner = true;
      
      try {
        targetIsMinor = await isMinorOrder({
          orderNumber: orderNumberFromData,
        });
        
        // Cache for future use
        this.cachedOrderNumber = orderNumberFromData;
        this.cachedIsMinor = targetIsMinor;
        
        console.log("[qRegisterTestsWrapper] Minor status determined - isMinor:", targetIsMinor);
      } catch (error) {
        console.error("[qRegisterTestsWrapper] Error checking minor order:", error);
        this.showSpinner = false;
        // On error, let the event continue (don't prevent resulttests)
        return;
      }
    }
    
    // Check if we need to swap components
    if (this.isMinor !== targetIsMinor) {
      console.log("[qRegisterTestsWrapper] Context mismatch detected - swapping components");
      console.log("[qRegisterTestsWrapper] Current isMinor:", this.isMinor, "Target isMinor:", targetIsMinor);
      
      // Set flag to prevent resulttests event from being dispatched
      event.detail.shouldDispatch = false;
      
      // Store order data and update context
      // Preserve isDirectLink and navigationType - these are important for navigation context awareness
      const preservedIsDirectLink = this.isDirectLink;
      const preservedNavigationType = this.navigationType;
      
      this.pendingOrderData = orderData;
      this.orderNumber = orderNumberFromData;
      this.isMinor = targetIsMinor;
      this.showSpinner = false;
      
      // Restore navigation context after component swap
      // Use requestAnimationFrame to ensure component swap completes
      requestAnimationFrame(() => {
        // Restore navigation context
        this.isDirectLink = preservedIsDirectLink;
        this.navigationType = preservedNavigationType;
        
        // Dispatch order data to new component
        this.dispatchOrderDataToChild();
      });
    } else {
      // Context matches - let resulttests event be dispatched normally
      console.log("[qRegisterTestsWrapper] Context matches - allowing resulttests to dispatch");
      this.orderNumber = orderNumberFromData;
      this.showSpinner = false;
      // Preserve navigation context - don't modify isDirectLink or navigationType
    }
  }
  
  /**
   * Dispatches pending order data to the newly swapped child component
   */
  dispatchOrderDataToChild() {
    if (!this.pendingOrderData) {
      console.warn("[qRegisterTestsWrapper] No pending order data to dispatch");
      return;
    }
    
    console.log("[qRegisterTestsWrapper] Dispatching order data to new component");
    
    // Use requestAnimationFrame to ensure component swap and DOM update complete
    requestAnimationFrame(() => {
      const childComponent = this.template.querySelector(
        this.isMinor ? 'c-register-tests-minor' : 'c-register-tests'
      );
      
      if (childComponent && typeof childComponent.handleOrderData === 'function') {
        // Call the public method directly
        childComponent.handleOrderData(this.pendingOrderData);
        this.pendingOrderData = null;
        console.log("[qRegisterTestsWrapper] Order data dispatched successfully via handleOrderData");
      } else {
        console.error("[qRegisterTestsWrapper] Child component not found or handleOrderData not available");
        console.error("[qRegisterTestsWrapper] Child:", childComponent, "isMinor:", this.isMinor);
        this.pendingOrderData = null;
      }
    });
  }

  async handleSearch(event) {
    const orderNumber = event.detail;
    console.log("[qRegisterTestsWrapper] handleSearch called with orderNumber:", orderNumber);
    
    if (orderNumber) {
      // This is called AFTER the child component has already navigated
      // Just update the cached context, don't swap components here
      // Component swapping is handled in handleResultTests
      
      // Check if this is the same order we've seen before (from cache)
      if (this.cachedOrderNumber === orderNumber) {
        console.log("[qRegisterTestsWrapper] Using cached isMinor status for order:", orderNumber);
        this.orderNumber = orderNumber;
        this.isMinor = this.cachedIsMinor;
        console.log("[qRegisterTestsWrapper] State updated from cache - orderNumber:", this.orderNumber, "isMinor:", this.isMinor);
        return;
      }
      
      // If we don't have cached data, check minor status
      // But don't swap components here - that's handled in handleResultTests
      console.log("[qRegisterTestsWrapper] Updating context for order:", orderNumber);
      
      try {
        const isMinorResult = await isMinorOrder({
          orderNumber: orderNumber,
        });

        // Update context
        this.orderNumber = orderNumber;
        this.isMinor = isMinorResult;
        // Cache for future use
        this.cachedOrderNumber = orderNumber;
        this.cachedIsMinor = isMinorResult;
        
        console.log("[qRegisterTestsWrapper] Context updated - orderNumber:", this.orderNumber, "isMinor:", this.isMinor);
      } catch (error) {
        console.error("[qRegisterTestsWrapper] Error checking minor order:", error);
        console.error("[qRegisterTestsWrapper] Error details:", {
          message: error?.body?.message || error?.message,
          statusCode: error?.statusCode,
          statusText: error?.statusText,
          body: error?.body,
          stack: error?.stack
        });
      }
    } else {
      console.warn("[qRegisterTestsWrapper] handleSearch called with empty/null orderNumber");
    }
  }
}