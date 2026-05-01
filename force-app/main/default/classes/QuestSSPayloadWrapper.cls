public with sharing class QuestSSPayloadWrapper {
        public List<Shipment> shipments;
        public Integer total;
        public Integer page;
        public Integer pages;
    
        public class Shipment {
            public Long shipmentId;
            public Long orderId;
            public String orderKey;
            public String userId;
            public String customerEmail;
            public String orderNumber;
            public String createDate;
            public String shipDate;
            public Decimal shipmentCost;
            public Decimal insuranceCost;
            public String trackingNumber;
            public Boolean isReturnLabel;
            public String batchNumber;
            public String carrierCode;
            public String serviceCode;
            public String packageCode;
            public String confirmation;
            public Long warehouseId;
            public Boolean voided;
            public String voidDate;
            public Boolean marketplaceNotified;
            public String notifyErrorMessage;
            public String labelData;
            public String formData;
        }
}