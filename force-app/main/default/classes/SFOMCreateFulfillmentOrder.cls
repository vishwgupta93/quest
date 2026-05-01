/**
 Class:: SFOMCreateFulfillmentOrder
 Description:: This class is to generate Fulfillment orders based on the attributes(Test type, Customer ID, OTC Cleared, Fulfillment Vendor and shipping address)
 The possilble splitting attributes are defined in on the field FO_Segment__c on Order Item summary. All the line items with common FO_Segment__c
 would be grouped under one Fulfillment order.
 **/
public class SFOMCreateFulfillmentOrder{
    @InvocableMethod(label = 'Create FO'description = 'Create FulfillmentOrder.')
    public static void createTransaction(List<InputParameters> inputLst){

        List<OutputParameters> outputLst = new List<OutputParameters>();

        List<OrderItemSummary> orderItemSummaryLst;
        List<OrderDeliveryGroupSummary> orderDeliveryGroupSummaryLst;
        Map<String, List<OrderItemSummary>> FulfillmentGrpMap = new Map<String, List<OrderItemSummary>>();
        List<String> locationIdLst = new List<String>();
        List<Id> orderSummaryIdLst = new List<Id>();
        List<Schema.Location> locationLst;
        Map<String, Schema.Location> LocationMap = new Map<String, Schema.Location>();
        Map<String, String> orderSumIdNdShippingRecIdMap = new Map<String, String>();
        Map<String, Set<String>> orderSumIdNdPWNRecIdMap = new Map<String, Set<String>>();
        Set<String> pwnOrderSummaryIds = new Set<String>();
        Set<String> orderSummaryIds = new Set<String>();
        for (InputParameters inputparams : inputLst){
            orderSummaryIdLst.add(inputparams.orderSummaryId);
        }
        
        // Get the Order Item Summaries wich are not yet fulfilled.
        orderItemSummaryLst = [SELECT Id, Type, TestType__c, quantity, QuantityAvailableToFulfill, FO_Segment__c, OrderSummaryId, OrderDeliveryGroupSummaryId, fulfillmentPartner__c
                               FROM OrderItemSummary
                               WHERE OrderSummaryId in:orderSummaryIdLst and QuantityAvailableToFulfill > 0];


        for (OrderItemSummary ois : orderItemSummaryLst){

            if (ois.Type == 'Delivery Charge'){
                orderSumIdNdShippingRecIdMap.put(ois.OrderSummaryId, ois.Id);
            } else{
                if (ois.fulfillmentPartner__c != null)
                    locationIdLst.add(ois.fulfillmentPartner__c);
                String key = ois.OrderDeliveryGroupSummaryId + '-' + ois.FO_Segment__c;
                if (FulfillmentGrpMap.containsKey(key)){
                    FulfillmentGrpMap.get(key).add(ois);
                } else{

                    List<OrderItemSummary> orderItemLst = new List<OrderItemSummary>();
                    orderItemLst.add(ois);
                    FulfillmentGrpMap.put(key, orderItemLst);
                }
            }
        }
        // get the location based on the external ref Id.
        if (locationIdLst != null && locationIdLst.size() > 0){
            locationLst = [SELECT Id, Name, ExternalReference, LocationType
                           FROM Location
                           where Name in:locationIdLst and LocationType != null];
            for (Schema.Location loc : locationLst){
                LocationMap.put(loc.Name, loc);
            }
        }

        System.debug('::::::::::::::::::::' + FulfillmentGrpMap);

        for (String key : FulfillmentGrpMap.keySet()){

            List<OrderItemSummary> oisLst = FulfillmentGrpMap.get(key);
            ConnectApi.FulfillmentOrderInputRepresentation foInputRep = new ConnectApi.FulfillmentOrderInputRepresentation();
            List<ConnectApi.OrderItemSummaryInputRepresentation> orderItemSummaries = new List<ConnectApi.OrderItemSummaryInputRepresentation>();
            ConnectApi.FulfillmentGroupInputRepresentation fGrpRep = new ConnectApi.FulfillmentGroupInputRepresentation();
            List<ConnectApi.FulfillmentGroupInputRepresentation> fulfillmentGroups = new List<ConnectApi.FulfillmentGroupInputRepresentation>();

            String odgsId;
            String orderSummaryId;
            String fulfillmentpartner;
            boolean isPWNItem = false;
            for (OrderItemSummary orderItem : oisLst){
                ConnectApi.OrderItemSummaryInputRepresentation oisInputRep = new ConnectApi.OrderItemSummaryInputRepresentation();
                oisInputRep.orderItemSummaryId = orderItem.id;
                oisInputRep.quantity = orderItem.QuantityAvailableToFulfill;
                orderItemSummaries.add(oisInputRep);
                odgsId = orderItem.OrderDeliveryGroupSummaryId;
                orderSummaryId = orderItem.OrderSummaryId;
                if (orderItem.fulfillmentPartner__c != null)
                    fulfillmentpartner = orderItem.fulfillmentPartner__c;
                if (orderItem.TestType__c == 'PA')
                    isPWNItem = true;
            }

            // Add shipping rec to FO.
            if (isPWNItem && orderSummaryIds != null && !orderSummaryIds.contains(orderSummaryId) && orderSumIdNdShippingRecIdMap != null && orderSumIdNdShippingRecIdMap.get(orderSummaryId) != null){
                ConnectApi.OrderItemSummaryInputRepresentation oisInputRep = new ConnectApi.OrderItemSummaryInputRepresentation();
                oisInputRep.orderItemSummaryId = orderSumIdNdShippingRecIdMap.get(orderSummaryId);
                oisInputRep.quantity = 1;
                orderItemSummaries.add(oisInputRep);
                orderSummaryIds.add(orderSummaryId);
            }

            fGrpRep.fulfilledFromLocationId = label.SFOM_Default_Location_Id;
            fGrpRep.fulfillmentType = 'Warehouse';

            if (fulfillmentpartner != null && LocationMap != null && LocationMap.containsKey(fulfillmentpartner)){
                Schema.Location location = LocationMap.get(fulfillmentpartner);
                if (location != null){
                    fGrpRep.fulfilledFromLocationId = location.Id;
                }
            }

            fGrpRep.orderItemSummaries = orderItemSummaries;
            fulfillmentGroups.add(fGrpRep);
            foInputRep.fulfillmentGroups = fulfillmentGroups;

            OutputParameters outputParam = new OutputParameters();
            foInputRep.orderDeliveryGroupSummaryId = odgsId;
            foInputRep.orderSummaryId = orderSummaryId;
            ConnectApi.FulfillmentOrderOutputRepresentation result = ConnectAPI.FulfillmentOrder.createFulfillmentOrders(foInputRep);
            List<String> foIds = result.fulfillmentOrderIds;
            System.debug('**************************' + result.fulfillmentOrderIds);
            /** if(result.success) {
             outputParam.statusMsg='success';
             outputParam.fulfillmentOrderIdLst=result.fulfillmentOrderIds;
             outputLst.add(outputParam);
             }
             **/
        }

        //return outputLst;
    }

    public class OutputParameters{
        @InvocableVariable
        public String statusMsg;
        @InvocableVariable
        public List<String> fulfillmentOrderIdLst;
    }

    public class InputParameters{
        @InvocableVariable
        public String orderSummaryId;

    }

}