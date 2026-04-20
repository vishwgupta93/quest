public with sharing class PartnerDashboardController {

    private static final Set<String> COMPLETED_STATUSES = new Set<String>{
        'Results Ready'
    };

    private static final Set<String> REVENUE_STATUSES = new Set<String>{
        'Results Ready',
        'Expired'
    };

    private static final Set<String> LOST_STATUSES = new Set<String>{
        'Cancelled',
        'PA Rejected'
    };
    private static final Set<String> PRE_SAMPLE_COLLECTION_STATUSES = new Set<String>{
        'Registered',
        'Confirmed',
        'PA Approved'
    };
    private static final Set<String> POST_SAMPLE_COLLECTION_STATUSES = new Set<String>{
        'In Progress',
        'Partial Results',
        'Partial Results Ready'
    };

    private static final Integer FAST_COMPLETION_DAYS = 5;
    private static final Integer REVENUE_AT_RISK_START_DAYS = 45;
    private static final Integer REVENUE_AT_RISK_END_DAYS = 60;
    private static final String DATE_RANGE_LAST_30_DAYS = 'LAST_30_DAYS';
    private static final String DATE_RANGE_LAST_60_DAYS = 'LAST_60_DAYS';
    private static final String DATE_RANGE_LAST_90_DAYS = 'LAST_90_DAYS';
    private static final String DATE_RANGE_YEAR_TO_DATE = 'YEAR_TO_DATE';
    private static final String DATE_RANGE_CUSTOM = 'CUSTOM';

    public static final String ORDER_FILTER_ALL = 'ALL';
    public static final String ORDER_FILTER_REALIZED = 'REALIZED';
    public static final String ORDER_FILTER_LOST = 'LOST';
    public static final String ORDER_FILTER_CANCELLED = 'CANCELLED';
    public static final String ORDER_FILTER_AT_RISK = 'AT_RISK';

    /** Open-order ageing analysis drill: stage and bucket keys (match LWC). */
    public static final String OPEN_AGEING_STAGE_TOTAL = 'TOTAL';
    public static final String OPEN_AGEING_STAGE_PRE = 'PRE';
    public static final String OPEN_AGEING_STAGE_POST = 'POST';
    public static final String OPEN_AGEING_BUCKET_ALL_OPEN = 'ALL_OPEN';
    public static final String OPEN_AGEING_BUCKET_AT_RISK_GT6 = 'AT_RISK_GT6';
    public static final String OPEN_AGEING_BUCKET_STAGE_TOTAL = 'STAGE_TOTAL';
    public static final String OPEN_AGEING_BUCKET_LT3 = 'lt3';
    public static final String OPEN_AGEING_BUCKET_D3TO6 = 'd3to6';
    public static final String OPEN_AGEING_BUCKET_D7TO15 = 'd7to15';
    public static final String OPEN_AGEING_BUCKET_D15TO30 = 'd15to30';
    public static final String OPEN_AGEING_BUCKET_GT30 = 'gt30';

    private static final Integer DEFAULT_PAGE_SIZE = 25;
    private static final Integer MAX_PAGE_SIZE = 100;
    /** Large page size used only by export helpers so the full in-scope list is returned. */
    private static final Integer EXPORT_LIST_PAGE_SIZE = 200000;
    private static final String CREATED_DATE_FIELD = 'CreatedDate';
    private static final String RESULTED_DATE_FIELD = 'Date_Reported__c';
    private static final String CANCELLED_DATE_FIELD = 'Cancellation_Date__c';

    /**
     * Org My Domain URL (no trailing slash) for internal Lightning record links from Experience Cloud.
     * Null for non-internal users (e.g. Experience Cloud partner/member types) so they stay on community routes.
     */
    @AuraEnabled(cacheable=true)
    public static String getInternalLightningBaseUrlForCurrentUser() {
        if (!'Standard'.equalsIgnoreCase(UserInfo.getUserType())) {
            return null;
        }
        String base = Url.getOrgDomainUrl().toExternalForm();
        if (String.isBlank(base)) {
            return null;
        }
        while (base.endsWith('/')) {
            base = base.substring(0, base.length() - 1);
        }
        return base;
    }

    @AuraEnabled(cacheable=true)
    public static OverviewSummaryWrapper getOverviewSummary(String dateRange, Date customStartDate, Date customEndDate) {
        DateWindow window = resolveDateWindow(dateRange, customStartDate, customEndDate);

        Map<Id, PartnerReference> partnerReferences = getPartnerReferences();
        Map<Id, PartnerMetrics> metricsByPartnerMapId = buildMetricsByPartnerMapId(
            partnerReferences.keySet(),
            window.startDate,
            window.endDate
        );

        PartnerMetrics aggregate = new PartnerMetrics();
        for (PartnerMetrics pm : metricsByPartnerMapId.values()) {
            aggregate.totalOrders              += pm.totalOrders;
            aggregate.completedOrders          += pm.completedOrders;
            aggregate.cancelledOrders          += pm.cancelledOrders;
            aggregate.openOrders               += pm.openOrders;
            aggregate.completedWithinFiveDays  += pm.completedWithinFiveDays;
            aggregate.cancellationRiskOrders   += pm.cancellationRiskOrders;
            aggregate.grossRevenue             += pm.grossRevenue;
            aggregate.qmorRevenue              += pm.qmorRevenue;
            aggregate.pmorRevenue              += pm.pmorRevenue;
            aggregate.realizedRevenue          += pm.realizedRevenue;
            aggregate.realizedRevenueSameMonth += pm.realizedRevenueSameMonth;
            aggregate.lostRevenue              += pm.lostRevenue;
            aggregate.cancelledRevenue         += pm.cancelledRevenue;
            aggregate.revenueAtRisk            += pm.revenueAtRisk;
            aggregate.cancellationRiskRevenue  += pm.cancellationRiskRevenue;
        }

        return new OverviewSummaryWrapper(aggregate);
    }

    @AuraEnabled(cacheable=true)
    public static List<PartnerPerformanceWrapper> getPartnerPerformance(String dateRange, Date customStartDate, Date customEndDate) {
        DateWindow window = resolveDateWindow(dateRange, customStartDate, customEndDate);

        Map<Id, PartnerReference> partnerReferences = getPartnerReferences();
        Map<Id, PartnerMetrics> metricsByPartnerMapId = buildMetricsByPartnerMapId(
            partnerReferences.keySet(),
            window.startDate,
            window.endDate
        );

        List<PartnerPerformanceWrapper> results = new List<PartnerPerformanceWrapper>();

        for (Id partnerMapId : partnerReferences.keySet()) {
            PartnerReference partnerReference = partnerReferences.get(partnerMapId);
            PartnerMetrics metrics = metricsByPartnerMapId.containsKey(partnerMapId)
                ? metricsByPartnerMapId.get(partnerMapId)
                : new PartnerMetrics();

            results.add(new PartnerPerformanceWrapper(partnerReference, metrics));
        }

        return results;
    }

    @AuraEnabled(cacheable=true)
    public static PartnerDetailWrapper getPartnerDetails(Id partnerId, String dateRange, Date customStartDate, Date customEndDate) {

        if (partnerId == null) {
            return null;
        }

        Map<Id, PartnerReference> partnerReferences = getPartnerReferences();

        if (!partnerReferences.containsKey(partnerId)) {
            return null;
        }

        PartnerReference partnerReference = partnerReferences.get(partnerId);
        DateWindow window = resolveDateWindow(dateRange, customStartDate, customEndDate);
        Map<Id, PartnerMetrics> metricsByPartnerMapId = buildMetricsByPartnerMapId(
            new Set<Id>{ partnerId },
            window.startDate,
            window.endDate
        );
        PartnerMetrics metrics = metricsByPartnerMapId.containsKey(partnerId)
            ? metricsByPartnerMapId.get(partnerId)
            : new PartnerMetrics();

        return new PartnerDetailWrapper(partnerReference, metrics);
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductSearchResultWrapper> searchPartnerProducts(String searchTerm) {
        String normalizedTerm = String.isBlank(searchTerm) ? '' : searchTerm.trim();

        if (normalizedTerm.length() < 2) {
            return new List<ProductSearchResultWrapper>();
        }

        String likeTerm = '%' + String.escapeSingleQuotes(normalizedTerm) + '%';
        List<ProductSearchResultWrapper> results = new List<ProductSearchResultWrapper>();

        for (Product2 productRecord : [
            SELECT Id, Name, ProductCode, StockKeepingUnit, productId_Ecom__c, IsActive
            FROM Product2
            WHERE IsActive = true
              AND (
                    Name LIKE :likeTerm
                 OR ProductCode LIKE :likeTerm
                 OR StockKeepingUnit LIKE :likeTerm
                 OR productId_Ecom__c LIKE :likeTerm
              )
            ORDER BY Name
            LIMIT 15
        ]) {
            results.add(new ProductSearchResultWrapper(productRecord));
        }

        return results;
    }

    @AuraEnabled(cacheable=true)
    public static PartnerProductEditorWrapper getPartnerProductEditorData(Id partnerId) {
        if (partnerId == null) {
            return null;
        }

        PartnerClientMap__c partnerRecord = [
            SELECT Id, Name
            FROM PartnerClientMap__c
            WHERE Id = :partnerId
            LIMIT 1
        ];

        PartnerProductEditorWrapper wrapper = new PartnerProductEditorWrapper();
        wrapper.partnerId = partnerRecord.Id;
        wrapper.partnerName = partnerRecord.Name;

        for (Product_Partner_Map__c mapRecord : [
            SELECT Id,
                   Product__c,
                   Product__r.Name,
                   Product__r.ProductCode,
                   Product__r.StockKeepingUnit,
                   Product__r.productId_Ecom__c,
                   Product_Price__c,
                   Cancellation_Fee__c
            FROM Product_Partner_Map__c
            WHERE Partner_ID__c = :partnerId
            ORDER BY CreatedDate
        ]) {
            wrapper.productMaps.add(new ExistingProductPartnerMapWrapper(mapRecord));
        }

        return wrapper;
    }

    @AuraEnabled
    public static Integer savePartnerProducts(Id partnerId, String productMapsJson, String deletedProductMapIdsJson) {
        if (partnerId == null) {
            throw new AuraHandledException('Partner must be created before saving partner products.');
        }
        List<Id> deletedIds = new List<Id>();
        if (!String.isBlank(deletedProductMapIdsJson)) {
            Object parsedDeletedIds = JSON.deserializeUntyped(deletedProductMapIdsJson);
            if (parsedDeletedIds instanceof List<Object>) {
                for (Object deletedValue : (List<Object>) parsedDeletedIds) {
                    if (deletedValue == null) {
                        continue;
                    }
                    try {
                        deletedIds.add((Id) String.valueOf(deletedValue));
                    } catch (Exception ignored) {
                        // Skip malformed ids
                    }
                }
            }
        }

        List<Product_Partner_Map__c> recordsToUpsert = new List<Product_Partner_Map__c>();
        Set<Id> seenProductIds = new Set<Id>();
        if (!String.isBlank(productMapsJson)) {
            Object parsedPayload = JSON.deserializeUntyped(productMapsJson);
            if (!(parsedPayload instanceof List<Object>)) {
                throw new AuraHandledException('Partner product payload is invalid.');
            }

            for (Object rowValue : (List<Object>) parsedPayload) {
                if (!(rowValue instanceof Map<String, Object>)) {
                    continue;
                }

                Map<String, Object> row = (Map<String, Object>) rowValue;
                String productIdValue = (String) row.get('productId');
                String mapIdValue = (String) row.get('mapId');
                Decimal productPriceValue = toDecimal(row.get('productPrice'));
                Decimal cancellationFeeValue = toDecimal(row.get('cancellationFee'));

                if (String.isBlank(productIdValue) || productPriceValue == null) {
                    continue;
                }

                Id productId;
                try {
                    productId = (Id) productIdValue;
                } catch (Exception ignored) {
                    continue;
                }

                if (seenProductIds.contains(productId)) {
                    continue;
                }

                seenProductIds.add(productId);

                Product_Partner_Map__c mapRecord = new Product_Partner_Map__c();
                Boolean isExistingMap = false;
                if (!String.isBlank(mapIdValue)) {
                    try {
                        mapRecord.Id = (Id) mapIdValue;
                        isExistingMap = true;
                    } catch (Exception ignored) {
                        // Keep as insert if malformed
                    }
                }
                if (!isExistingMap) {
                    mapRecord.Partner_ID__c = partnerId;
                }
                mapRecord.Product__c = productId;
                mapRecord.Product_Price__c = productPriceValue;
                mapRecord.Cancellation_Fee__c = cancellationFeeValue;
                recordsToUpsert.add(mapRecord);
            }
        }

        if (recordsToUpsert.isEmpty() && deletedIds.isEmpty()) {
            throw new AuraHandledException('No valid partner products were found to save.');
        }

        if (!deletedIds.isEmpty()) {
            delete [
                SELECT Id
                FROM Product_Partner_Map__c
                WHERE Id IN :deletedIds
                  AND Partner_ID__c = :partnerId
            ];
        }

        if (!recordsToUpsert.isEmpty()) {
            upsert recordsToUpsert;
        }

        return recordsToUpsert.size();
    }

    private static Decimal toDecimal(Object value) {
        if (value == null) {
            return null;
        }

        if (value instanceof Decimal) {
            return (Decimal) value;
        }

        String textValue = String.valueOf(value);
        if (String.isBlank(textValue)) {
            return null;
        }

        try {
            return Decimal.valueOf(textValue);
        } catch (Exception ex) {
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static OpenOrderAgeingAnalysisWrapper getPartnerOpenOrderAgeingAnalysis(Id partnerId, String dateRange, Date customStartDate, Date customEndDate) {
        if (partnerId == null) {
            return new OpenOrderAgeingAnalysisWrapper();
        }

        Set<String> completedStatuses = COMPLETED_STATUSES;
        Set<String> lostStatuses = LOST_STATUSES;

        List<Lab_Order__c> openOrders = [
            SELECT Id,
                   Status__c,
                   Partner_Order_total__c,
                   CreatedDate
            FROM Lab_Order__c
            WHERE Partner_Client_Map__c = :partnerId
              AND (Status__c = null OR (Status__c NOT IN :completedStatuses AND Status__c NOT IN :lostStatuses))
        ];

        return buildOpenOrderAgeingAnalysis(openOrders);
    }

    /**
     * Paginated open lab orders for ageing analysis drill-through (same scope as getPartnerOpenOrderAgeingAnalysis).
     */
    @AuraEnabled(cacheable=false)
    public static PartnerLabOrdersResult getPartnerOpenOrdersAgeingDrill(
        Id partnerId,
        String dateRange,
        Date customStartDate,
        Date customEndDate,
        String stageKey,
        String bucketKey,
        String sortBy,
        String sortDirection,
        Integer pageSize,
        Integer pageOffset
    ) {
        PartnerLabOrdersResult result = new PartnerLabOrdersResult();
        result.orders = new List<LabOrderRowWrapper>();
        result.totalCount = 0;

        if (partnerId == null || String.isBlank(bucketKey) || String.isBlank(stageKey)) {
            return result;
        }

        Set<String> completedStatuses = COMPLETED_STATUSES;
        Set<String> lostStatuses = LOST_STATUSES;

        List<Lab_Order__c> openOrders = [
            SELECT Id,
                   Name,
                   Status__c,
                   Partner_Order_total__c,
                   Refund_Amount__c,
                   Payment_Transaction_Id__c,
                   CreatedDate,
                   Date_Reported__c,
                   Cancellation_Date__c,
                   Cancellation_Service_Fee__c
            FROM Lab_Order__c
            WHERE Partner_Client_Map__c = :partnerId
              AND (Status__c = null OR (Status__c NOT IN :completedStatuses AND Status__c NOT IN :lostStatuses))
        ];

        List<Lab_Order__c> filtered = new List<Lab_Order__c>();
        for (Lab_Order__c lo : openOrders) {
            if (matchesOpenAgeingDrill(lo, stageKey, bucketKey)) {
                filtered.add(lo);
            }
        }

        sortLabOrdersForAgeingDrill(filtered, sortBy, sortDirection);

        Integer limitRows = (pageSize != null && pageSize > 0)
            ? Math.min(pageSize, MAX_PAGE_SIZE)
            : DEFAULT_PAGE_SIZE;
        Integer offsetRows = (pageOffset != null && pageOffset >= 0) ? pageOffset : 0;

        result.totalCount = filtered.size();
        Integer fromIdx = Math.min(offsetRows, filtered.size());
        Integer toIdx = Math.min(offsetRows + limitRows, filtered.size());
        for (Integer i = fromIdx; i < toIdx; i++) {
            result.orders.add(new LabOrderRowWrapper(filtered[i]));
        }
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static List<LabOrderRowWrapper> getPartnerOpenOrdersAgeingDrillForExport(
        Id partnerId,
        String dateRange,
        Date customStartDate,
        Date customEndDate,
        String stageKey,
        String bucketKey,
        String sortBy,
        String sortDirection
    ) {
        List<LabOrderRowWrapper> rows = new List<LabOrderRowWrapper>();

        if (partnerId == null || String.isBlank(bucketKey) || String.isBlank(stageKey)) {
            return rows;
        }

        Set<String> completedStatuses = COMPLETED_STATUSES;
        Set<String> lostStatuses = LOST_STATUSES;

        List<Lab_Order__c> openOrders = [
            SELECT Id,
                   Name,
                   Status__c,
                   Partner_Order_total__c,
                   Refund_Amount__c,
                   Payment_Transaction_Id__c,
                   CreatedDate,
                   Date_Reported__c,
                   Cancellation_Date__c,
                   Cancellation_Service_Fee__c
            FROM Lab_Order__c
            WHERE Partner_Client_Map__c = :partnerId
              AND (Status__c = null OR (Status__c NOT IN :completedStatuses AND Status__c NOT IN :lostStatuses))
        ];

        List<Lab_Order__c> filtered = new List<Lab_Order__c>();
        for (Lab_Order__c lo : openOrders) {
            if (matchesOpenAgeingDrill(lo, stageKey, bucketKey)) {
                filtered.add(lo);
            }
        }

        sortLabOrdersForAgeingDrill(filtered, sortBy, sortDirection);

        for (Lab_Order__c lo : filtered) {
            rows.add(new LabOrderRowWrapper(lo));
        }
        return rows;
    }

    @AuraEnabled(cacheable=false)
    public static PartnerLabOrdersResult getPartnerLabOrders(
        Id partnerId,
        String dateRange,
        Date customStartDate,
        Date customEndDate,
        String filterType,
        String sortBy,
        String sortDirection,
        Integer pageSize,
        Integer pageOffset
    ) {
        PartnerLabOrdersResult result = new PartnerLabOrdersResult();
        result.orders = new List<LabOrderRowWrapper>();
        result.totalCount = 0;

        if (partnerId == null) {
            return result;
        }

        DateWindow window = resolveDateWindow(dateRange, customStartDate, customEndDate);
        Date startDateValue = window.startDate;
        Date endDateValue = window.endDate;
        Datetime startDateTime = Datetime.newInstance(window.startDate, Time.newInstance(0, 0, 0, 0));
        Datetime endDateExclusive = Datetime.newInstance(window.endDate.addDays(1), Time.newInstance(0, 0, 0, 0));
        Integer limitRows = (pageSize != null && pageSize > 0)
            ? Math.min(pageSize, MAX_PAGE_SIZE)
            : DEFAULT_PAGE_SIZE;
        Integer offsetRows = (pageOffset != null && pageOffset >= 0) ? pageOffset : 0;
        String filter = (String.isNotBlank(filterType)) ? filterType : ORDER_FILTER_ALL;
        String orderByField = resolveOrderByField(sortBy, filter);
        String orderByDirection = resolveSortDirection(sortDirection);
        String orderClause;
        if (sortBy == 'mor') {
            // Explicitly control null placement so PMoR/QMoR grouping is stable
            // across the full result set and pagination.
            String nullsPlacement = (orderByDirection == 'ASC') ? ' NULLS FIRST' : ' NULLS LAST';
            orderClause = ' ORDER BY ' + orderByField + ' ' + orderByDirection + nullsPlacement + ', Id DESC';
        } else {
            orderClause = ' ORDER BY ' + orderByField + ' ' + orderByDirection + ', Id DESC';
        }

        if (filter == ORDER_FILTER_AT_RISK) {
            return getPartnerLabOrdersAtRisk(partnerId, startDateTime, endDateExclusive, limitRows, offsetRows, orderClause);
        }

        // Assign static sets to local variables for reliable dynamic SOQL binding
        Set<String> revenueStatuses = REVENUE_STATUSES;
        Set<String> lostStatuses    = LOST_STATUSES;

        String dateField = getDateFieldForFilter(filter);
        String dateCondition = (filter == ORDER_FILTER_REALIZED || filter == ORDER_FILTER_CANCELLED)
            ? dateField + ' >= :startDateValue AND ' + dateField + ' <= :endDateValue'
            : dateField + ' >= :startDateTime AND ' + dateField + ' < :endDateExclusive';
        String selectFieldsList = 'SELECT Id, Name, Status__c, Partner_Order_total__c, Refund_Amount__c, Payment_Transaction_Id__c, '
            + 'CreatedDate, Date_Reported__c, Cancellation_Date__c, Cancellation_Service_Fee__c, Cancel_Reason__c';
        if (filter == ORDER_FILTER_REALIZED) {
            selectFieldsList += ', External_Partner_Order_Id__c, LabRefId__c, Accession_ID__c, Date_of_Collection__c, '
                + 'Expiration_Date__c, Registrant_Name__c, PerformingSite__c, FHIR_External_ID__c, '
                + 'Partner_Client_Map__r.Client_ID__c, Partner_Client_Map__r.Name';
        }
        String soql = selectFieldsList
            + ' FROM Lab_Order__c WHERE Partner_Client_Map__c = :partnerId'
            + ' AND ' + dateCondition;
        if (filter == ORDER_FILTER_REALIZED) soql += ' AND Status__c IN :revenueStatuses';
        else if (filter == ORDER_FILTER_LOST) soql += ' AND Status__c IN :lostStatuses';
        else if (filter == ORDER_FILTER_CANCELLED) soql += ' AND Status__c = \'Cancelled\'';
        soql += orderClause;

        List<Lab_Order__c> scopedOrders = (List<Lab_Order__c>) Database.query(soql);
        result.totalCount = scopedOrders.size();
        Integer fromIdx = Math.min(offsetRows, scopedOrders.size());
        Integer toIdx = Math.min(offsetRows + limitRows, scopedOrders.size());
        for (Integer i = fromIdx; i < toIdx; i++) {
            result.orders.add(new LabOrderRowWrapper(scopedOrders[i], filter));
        }
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static List<LabOrderRowWrapper> getPartnerLabOrdersForExport(
        Id partnerId,
        String dateRange,
        Date customStartDate,
        Date customEndDate,
        String filterType,
        String sortBy,
        String sortDirection
    ) {
        List<LabOrderRowWrapper> rows = new List<LabOrderRowWrapper>();

        if (partnerId == null) {
            return rows;
        }

        DateWindow window = resolveDateWindow(dateRange, customStartDate, customEndDate);
        Date startDateValue = window.startDate;
        Date endDateValue = window.endDate;
        Datetime startDateTime = Datetime.newInstance(window.startDate, Time.newInstance(0, 0, 0, 0));
        Datetime endDateExclusive = Datetime.newInstance(window.endDate.addDays(1), Time.newInstance(0, 0, 0, 0));
        String filter = (String.isNotBlank(filterType)) ? filterType : ORDER_FILTER_ALL;
        String orderByField = resolveOrderByField(sortBy, filter);
        String orderByDirection = resolveSortDirection(sortDirection);
        String orderClause;
        if (sortBy == 'mor') {
            String nullsPlacement = (orderByDirection == 'ASC') ? ' NULLS FIRST' : ' NULLS LAST';
            orderClause = ' ORDER BY ' + orderByField + ' ' + orderByDirection + nullsPlacement + ', Id DESC';
        } else {
            orderClause = ' ORDER BY ' + orderByField + ' ' + orderByDirection + ', Id DESC';
        }

        if (filter == ORDER_FILTER_AT_RISK) {
            return getPartnerLabOrdersAtRiskForExport(partnerId, startDateTime, endDateExclusive, orderClause);
        }

        Set<String> revenueStatuses = REVENUE_STATUSES;
        Set<String> lostStatuses = LOST_STATUSES;
        String dateField = getDateFieldForFilter(filter);
        String dateCondition = (filter == ORDER_FILTER_REALIZED || filter == ORDER_FILTER_CANCELLED)
            ? dateField + ' >= :startDateValue AND ' + dateField + ' <= :endDateValue'
            : dateField + ' >= :startDateTime AND ' + dateField + ' < :endDateExclusive';
        String selectFieldsExport = 'SELECT Id, Name, Status__c, Partner_Order_total__c, Refund_Amount__c, Payment_Transaction_Id__c, '
            + 'CreatedDate, Date_Reported__c, Cancellation_Date__c, Cancellation_Service_Fee__c, Cancel_Reason__c';
        if (filter == ORDER_FILTER_REALIZED) {
            selectFieldsExport += ', External_Partner_Order_Id__c, LabRefId__c, Accession_ID__c, Date_of_Collection__c, '
                + 'Expiration_Date__c, Registrant_Name__c, PerformingSite__c, FHIR_External_ID__c, '
                + 'Partner_Client_Map__r.Client_ID__c, Partner_Client_Map__r.Name';
        }
        String soql = selectFieldsExport
            + ' FROM Lab_Order__c WHERE Partner_Client_Map__c = :partnerId'
            + ' AND ' + dateCondition;
        if (filter == ORDER_FILTER_REALIZED) soql += ' AND Status__c IN :revenueStatuses';
        else if (filter == ORDER_FILTER_LOST) soql += ' AND Status__c IN :lostStatuses';
        else if (filter == ORDER_FILTER_CANCELLED) soql += ' AND Status__c = \'Cancelled\'';
        soql += orderClause;

        for (Lab_Order__c lo : (List<Lab_Order__c>) Database.query(soql)) {
            rows.add(new LabOrderRowWrapper(lo, filter));
        }
        return rows;
    }

    @AuraEnabled(cacheable=false)
    public static PartnerRealizedPanelRowsResult getPartnerRealizedLabOrderPanels(
        Id partnerId,
        String dateRange,
        Date customStartDate,
        Date customEndDate,
        String sortBy,
        String sortDirection,
        Integer pageSize,
        Integer pageOffset
    ) {
        PartnerRealizedPanelRowsResult result = new PartnerRealizedPanelRowsResult();
        result.rows = new List<RealizedPanelRowWrapper>();
        result.totalCount = 0;

        if (partnerId == null) {
            return result;
        }

        DateWindow window = resolveDateWindow(dateRange, customStartDate, customEndDate);
        Date startDateValue = window.startDate;
        Date endDateValue = window.endDate;
        Set<String> revenueStatuses = REVENUE_STATUSES;
        Integer limitRows;
        if (pageSize != null && pageSize >= EXPORT_LIST_PAGE_SIZE) {
            limitRows = pageSize;
        } else if (pageSize != null && pageSize > 0) {
            limitRows = Math.min(pageSize, MAX_PAGE_SIZE);
        } else {
            limitRows = DEFAULT_PAGE_SIZE;
        }
        Integer offsetRows = (pageOffset != null && pageOffset >= 0) ? pageOffset : 0;
        String orderClause = buildRealizedPanelOrderClause(sortBy, sortDirection);

        List<Lab_Order_Panel__c> scoped = new RealizedPartnerPanelAccess().queryPanels(
            partnerId,
            startDateValue,
            endDateValue,
            revenueStatuses,
            orderClause
        );
        result.totalCount = scoped.size();
        Integer fromIdx = Math.min(offsetRows, scoped.size());
        Integer toIdx = Math.min(offsetRows + limitRows, scoped.size());
        for (Integer i = fromIdx; i < toIdx; i++) {
            result.rows.add(new RealizedPanelRowWrapper(scoped[i]));
        }
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static List<RealizedPanelRowWrapper> getPartnerRealizedLabOrderPanelsForExport(
        Id partnerId,
        String dateRange,
        Date customStartDate,
        Date customEndDate,
        String sortBy,
        String sortDirection
    ) {
        PartnerRealizedPanelRowsResult page = getPartnerRealizedLabOrderPanels(
            partnerId,
            dateRange,
            customStartDate,
            customEndDate,
            sortBy,
            sortDirection,
            EXPORT_LIST_PAGE_SIZE,
            0
        );
        return page.rows != null ? page.rows : new List<RealizedPanelRowWrapper>();
    }

    @AuraEnabled(cacheable=false)
    public static PartnerRealizedSummaryResult getPartnerRealizedTestSummary(
        Id partnerId,
        String dateRange,
        Date customStartDate,
        Date customEndDate,
        String sortBy,
        String sortDirection,
        Integer pageSize,
        Integer pageOffset
    ) {
        PartnerRealizedSummaryResult result = new PartnerRealizedSummaryResult();
        result.rows = new List<RealizedSummaryRowWrapper>();
        result.totalCount = 0;
        result.grandTotalQuantity = 0;
        result.grandTotalAmount = 0;

        if (partnerId == null) {
            return result;
        }

        DateWindow window = resolveDateWindow(dateRange, customStartDate, customEndDate);
        Date startDateValue = window.startDate;
        Date endDateValue = window.endDate;
        Set<String> revenueStatuses = REVENUE_STATUSES;
        Integer limitRows;
        if (pageSize != null && pageSize >= EXPORT_LIST_PAGE_SIZE) {
            limitRows = pageSize;
        } else if (pageSize != null && pageSize > 0) {
            limitRows = Math.min(pageSize, MAX_PAGE_SIZE);
        } else {
            limitRows = DEFAULT_PAGE_SIZE;
        }
        Integer offsetRows = (pageOffset != null && pageOffset >= 0) ? pageOffset : 0;

        List<Lab_Order_Panel__c> lines = new RealizedPartnerPanelAccess().queryPanelSummaryLines(
            partnerId,
            startDateValue,
            endDateValue,
            revenueStatuses
        );

        Map<String, RealizedSummaryAccumulator> byCode = new Map<String, RealizedSummaryAccumulator>();
        for (Lab_Order_Panel__c line : lines) {
            String codeKey = line.Panel_Code__c == null ? '' : String.valueOf(line.Panel_Code__c);
            if (!byCode.containsKey(codeKey)) {
                byCode.put(codeKey, new RealizedSummaryAccumulator(codeKey, line.Product_Name__c));
            }
            RealizedSummaryAccumulator acc = byCode.get(codeKey);
            Decimal qty = line.Quantity__c == null ? 0 : line.Quantity__c;
            Decimal price = line.Panel_Price__c == null ? 0 : line.Panel_Price__c;
            acc.quantity += qty;
            acc.totalAmount += price * qty;
            if (String.isBlank(acc.panelName) && String.isNotBlank(line.Product_Name__c)) {
                acc.panelName = line.Product_Name__c;
            }
        }

        List<RealizedSummaryRowWrapper> allRows = new List<RealizedSummaryRowWrapper>();
        for (RealizedSummaryAccumulator acc : byCode.values()) {
            RealizedSummaryRowWrapper row = new RealizedSummaryRowWrapper();
            row.id = 'SUMMARY-' + (String.isBlank(acc.panelCodeKey) ? 'UNKNOWN' : acc.panelCodeKey);
            row.panelCode = acc.panelCodeKey;
            row.panelName = acc.panelName;
            row.quantity = acc.quantity;
            row.panelPrice = acc.quantity > 0 ? (acc.totalAmount / acc.quantity) : 0;
            row.totalAmount = acc.totalAmount;
            result.grandTotalQuantity += acc.quantity;
            result.grandTotalAmount += acc.totalAmount;
            allRows.add(row);
        }

        sortRealizedSummaryRows(allRows, sortBy, sortDirection);
        result.totalCount = allRows.size();
        Integer fromIdx = Math.min(offsetRows, allRows.size());
        Integer toIdx = Math.min(offsetRows + limitRows, allRows.size());
        for (Integer i = fromIdx; i < toIdx; i++) {
            result.rows.add(allRows[i]);
        }
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static PartnerRealizedSummaryResult getPartnerRealizedTestSummaryForExport(
        Id partnerId,
        String dateRange,
        Date customStartDate,
        Date customEndDate,
        String sortBy,
        String sortDirection
    ) {
        return getPartnerRealizedTestSummary(
            partnerId,
            dateRange,
            customStartDate,
            customEndDate,
            sortBy,
            sortDirection,
            EXPORT_LIST_PAGE_SIZE,
            0
        );
    }

    @AuraEnabled(cacheable=false)
    public static String createPartnerLabOrdersExportFile(String fileName, String documentContent) {
        if (String.isBlank(documentContent)) {
            return null;
        }

        String safeFileName = String.isNotBlank(fileName) ? fileName.trim() : 'Partner_Orders_Export.xls';
        String lowerName = safeFileName.toLowerCase();
        if (!lowerName.endsWith('.xls') && !lowerName.endsWith('.xml')) {
            safeFileName += '.xml';
            lowerName = safeFileName.toLowerCase();
        }

        String title = (lowerName.endsWith('.xls') || lowerName.endsWith('.xml'))
            ? safeFileName.substring(0, safeFileName.length() - 4)
            : safeFileName;

        ContentVersion cv = new ContentVersion();
        cv.Title = title;
        cv.PathOnClient = '/' + safeFileName;
        cv.VersionData = Blob.valueOf(documentContent);
        cv.IsMajorVersion = true;
        insert cv;

        return cv.Id;
    }

    private static PartnerLabOrdersResult getPartnerLabOrdersAtRisk(
        Id partnerId,
        Datetime startDateTime,
        Datetime endDateExclusive,
        Integer pageSize,
        Integer pageOffset,
        String orderClause
    ) {
        PartnerLabOrdersResult result = new PartnerLabOrdersResult();
        result.orders = new List<LabOrderRowWrapper>();
        result.totalCount = 0;

        // Build an explicit 45-60 day creation window to avoid scanning + in-memory
        // truncation issues for high-volume partners. This keeps card/list aligned.
        Date today = Date.today();
        Date riskStartDate = today.addDays(-REVENUE_AT_RISK_END_DAYS);    // 60 days ago
        Date riskEndDate = today.addDays(-REVENUE_AT_RISK_START_DAYS);    // 45 days ago
        Datetime riskStartDateTime = Datetime.newInstance(riskStartDate, Time.newInstance(0, 0, 0, 0));
        Datetime riskEndExclusive = Datetime.newInstance(riskEndDate.addDays(1), Time.newInstance(0, 0, 0, 0));

        Datetime lowerBound = (startDateTime != null && startDateTime > riskStartDateTime)
            ? startDateTime
            : riskStartDateTime;
        Datetime upperBound = (endDateExclusive != null && endDateExclusive < riskEndExclusive)
            ? endDateExclusive
            : riskEndExclusive;

        // No overlap between selected date range and at-risk window
        if (lowerBound >= upperBound) {
            return result;
        }

        Set<String> completedStatuses = COMPLETED_STATUSES;
        Set<String> lostStatuses = LOST_STATUSES;

        String baseWhere = ' FROM Lab_Order__c'
            + ' WHERE Partner_Client_Map__c = :partnerId'
            + ' AND ' + CREATED_DATE_FIELD + ' >= :lowerBound'
            + ' AND ' + CREATED_DATE_FIELD + ' < :upperBound'
            + ' AND (Status__c = null OR (Status__c NOT IN :completedStatuses AND Status__c NOT IN :lostStatuses))';

        String rowsSoql = 'SELECT Id, Name, Status__c, Partner_Order_total__c, Refund_Amount__c, Payment_Transaction_Id__c, '
            + 'CreatedDate'
            + baseWhere
            + orderClause;

        List<Lab_Order__c> atRiskOrders = (List<Lab_Order__c>) Database.query(rowsSoql);
        result.totalCount = atRiskOrders.size();
        Integer fromIdx = Math.min(pageOffset, atRiskOrders.size());
        Integer toIdx = Math.min(pageOffset + pageSize, atRiskOrders.size());
        for (Integer i = fromIdx; i < toIdx; i++) {
            result.orders.add(new LabOrderRowWrapper(atRiskOrders[i]));
        }
        return result;
    }

    private static List<LabOrderRowWrapper> getPartnerLabOrdersAtRiskForExport(
        Id partnerId,
        Datetime startDateTime,
        Datetime endDateExclusive,
        String orderClause
    ) {
        List<LabOrderRowWrapper> rows = new List<LabOrderRowWrapper>();

        Date today = Date.today();
        Date riskStartDate = today.addDays(-REVENUE_AT_RISK_END_DAYS);
        Date riskEndDate = today.addDays(-REVENUE_AT_RISK_START_DAYS);
        Datetime riskStartDateTime = Datetime.newInstance(riskStartDate, Time.newInstance(0, 0, 0, 0));
        Datetime riskEndExclusive = Datetime.newInstance(riskEndDate.addDays(1), Time.newInstance(0, 0, 0, 0));

        Datetime lowerBound = (startDateTime != null && startDateTime > riskStartDateTime)
            ? startDateTime
            : riskStartDateTime;
        Datetime upperBound = (endDateExclusive != null && endDateExclusive < riskEndExclusive)
            ? endDateExclusive
            : riskEndExclusive;

        if (lowerBound >= upperBound) {
            return rows;
        }

        Set<String> completedStatuses = COMPLETED_STATUSES;
        Set<String> lostStatuses = LOST_STATUSES;
        String rowsSoql = 'SELECT Id, Name, Status__c, Partner_Order_total__c, Refund_Amount__c, Payment_Transaction_Id__c, '
            + 'CreatedDate'
            + ' FROM Lab_Order__c'
            + ' WHERE Partner_Client_Map__c = :partnerId'
            + ' AND ' + CREATED_DATE_FIELD + ' >= :lowerBound'
            + ' AND ' + CREATED_DATE_FIELD + ' < :upperBound'
            + ' AND (Status__c = null OR (Status__c NOT IN :completedStatuses AND Status__c NOT IN :lostStatuses))'
            + orderClause;

        for (Lab_Order__c lo : (List<Lab_Order__c>) Database.query(rowsSoql)) {
            rows.add(new LabOrderRowWrapper(lo));
        }
        return rows;
    }

    private static String getDateFieldForFilter(String filterType) {
        if (filterType == ORDER_FILTER_REALIZED) {
            return RESULTED_DATE_FIELD;
        }
        if (filterType == ORDER_FILTER_CANCELLED) {
            return CANCELLED_DATE_FIELD;
        }
        return CREATED_DATE_FIELD;
    }

    private static String resolveOrderByField(String sortBy, String filterType) {
        if (sortBy == 'name') {
            return 'Name';
        }
        if (sortBy == 'amount') {
            return filterType == ORDER_FILTER_CANCELLED
                ? 'Cancellation_Service_Fee__c'
                : 'Partner_Order_total__c';
        }
        if (sortBy == 'status') {
            return 'Status__c';
        }
        if (sortBy == 'mor') {
            return 'Payment_Transaction_Id__c';
        }
        if (sortBy == 'cancellationReason' && filterType == ORDER_FILTER_CANCELLED) {
            return 'Cancel_Reason__c';
        }
        if (filterType == ORDER_FILTER_REALIZED) {
            if (sortBy == 'orderCreatedDate') {
                return 'CreatedDate';
            }
            if (sortBy == 'dateSampleCollected') {
                return 'Date_of_Collection__c';
            }
            if (sortBy == 'dateResulted') {
                return 'Date_Reported__c';
            }
            if (sortBy == 'nonRefundableDate') {
                return 'Expiration_Date__c';
            }
            if (sortBy == 'clientAccountNumber') {
                return 'Partner_Client_Map__r.Client_ID__c';
            }
            if (sortBy == 'partnerName') {
                return 'Partner_Client_Map__r.Name';
            }
            if (sortBy == 'labOrderId') {
                return 'FHIR_External_ID__c';
            }
            if (sortBy == 'externalPartnerOrderId') {
                return 'External_Partner_Order_Id__c';
            }
            if (sortBy == 'labRefId') {
                return 'LabRefId__c';
            }
            if (sortBy == 'accessionId') {
                return 'Accession_ID__c';
            }
            if (sortBy == 'registrantName') {
                return 'Registrant_Name__c';
            }
            if (sortBy == 'performingSite') {
                return 'PerformingSite__c';
            }
        }
        return getDateFieldForFilter(filterType);
    }

    private static String buildRealizedPanelOrderClause(String sortBy, String sortDirection) {
        String orderByField = resolveRealizedPanelOrderByField(sortBy);
        String orderByDirection = resolveSortDirection(sortDirection);
        if (sortBy == 'mor') {
            String nullsPlacement = (orderByDirection == 'ASC') ? ' NULLS FIRST' : ' NULLS LAST';
            return ' ORDER BY ' + orderByField + ' ' + orderByDirection + nullsPlacement + ', Id DESC';
        }
        return ' ORDER BY ' + orderByField + ' ' + orderByDirection + ', Id DESC';
    }

    private static String resolveRealizedPanelOrderByField(String sortBy) {
        if (sortBy == 'labOrderName') {
            return 'Lab_Order__r.Name';
        }
        if (sortBy == 'externalPartnerOrderId') {
            return 'Lab_Order__r.External_Partner_Order_Id__c';
        }
        if (sortBy == 'labRefId') {
            return 'Lab_Order__r.LabRefId__c';
        }
        if (sortBy == 'accessionId') {
            return 'Lab_Order__r.Accession_ID__c';
        }
        if (sortBy == 'orderCreatedDate') {
            return 'Lab_Order__r.CreatedDate';
        }
        if (sortBy == 'dateSampleCollected') {
            return 'Lab_Order__r.Date_of_Collection__c';
        }
        if (sortBy == 'dateResulted' || sortBy == 'createdDate') {
            return 'Lab_Order__r.Date_Reported__c';
        }
        if (sortBy == 'nonRefundableDate') {
            return 'Lab_Order__r.Expiration_Date__c';
        }
        if (sortBy == 'registrantName') {
            return 'Lab_Order__r.Registrant_Name__c';
        }
        if (sortBy == 'performingSite') {
            return 'Performing_Site__c';
        }
        if (sortBy == 'labOrderId') {
            return 'Lab_Order__r.FHIR_External_ID__c';
        }
        if (sortBy == 'amount') {
            return 'Panel_Price__c';
        }
        if (sortBy == 'panelCode') {
            return 'Panel_Code__c';
        }
        if (sortBy == 'panelName') {
            return 'Product_Name__c';
        }
        if (sortBy == 'panelPrice') {
            return 'Panel_Price__c';
        }
        if (sortBy == 'panelStatus') {
            return 'Status__c';
        }
        if (sortBy == 'mor') {
            return 'Lab_Order__r.Payment_Transaction_Id__c';
        }
        return 'Lab_Order__r.Date_Reported__c';
    }

    private static void sortRealizedSummaryRows(List<RealizedSummaryRowWrapper> rows, String sortBy, String sortDirection) {
        if (rows == null || rows.isEmpty()) {
            return;
        }
        Boolean sortAscending = resolveSortDirection(sortDirection) == 'ASC';
        rows.sort(new RealizedSummaryRowComparator(sortBy, sortAscending));
    }

    private static OpenOrderAgeingAnalysisWrapper buildOpenOrderAgeingAnalysis(List<Lab_Order__c> openOrders) {
        OpenOrderAgeingAnalysisWrapper analysis = new OpenOrderAgeingAnalysisWrapper();
        Map<String, OpenOrderAgeingAnalysisRowWrapper> rowsByStage = new Map<String, OpenOrderAgeingAnalysisRowWrapper>{
            'Pre sample collection' => new OpenOrderAgeingAnalysisRowWrapper('Pre sample collection'),
            'Post sample collection' => new OpenOrderAgeingAnalysisRowWrapper('Post sample collection')
        };

        for (Lab_Order__c orderRecord : openOrders) {
            String stageLabel = normalizeOpenOrderStage(orderRecord.Status__c);
            if (String.isBlank(stageLabel)) {
                continue;
            }

            OpenOrderAgeingAnalysisBucketWrapper bucket = createAnalysisAgeBucket(
                orderRecord.CreatedDate,
                orderRecord.Partner_Order_total__c
            );

            OpenOrderAgeingAnalysisRowWrapper row = rowsByStage.get(stageLabel);
            row.addToBucket(bucket.key, bucket.revenue);

            analysis.totalOpenOrders += 1;
            analysis.totalOpenRevenue += bucket.revenue;

            // At-risk for analysis: older than 6 days (aligns with "At Risk Orders (>6 days)" in UI).
            if (bucket.ageInDays > 6) {
                analysis.atRiskOrdersCount += 1;
                analysis.atRiskOrdersRevenue += bucket.revenue;
            }
        }

        analysis.rows.add(rowsByStage.get('Pre sample collection'));
        analysis.rows.add(rowsByStage.get('Post sample collection'));

        for (OpenOrderAgeingAnalysisRowWrapper row : analysis.rows) {
            analysis.totalRow.totalCount += row.totalCount;
            analysis.totalRow.totalRevenue += row.totalRevenue;
            analysis.totalRow.lt3Count += row.lt3Count;
            analysis.totalRow.lt3Revenue += row.lt3Revenue;
            analysis.totalRow.d3to6Count += row.d3to6Count;
            analysis.totalRow.d3to6Revenue += row.d3to6Revenue;
            analysis.totalRow.d7to15Count += row.d7to15Count;
            analysis.totalRow.d7to15Revenue += row.d7to15Revenue;
            analysis.totalRow.d15to30Count += row.d15to30Count;
            analysis.totalRow.d15to30Revenue += row.d15to30Revenue;
            analysis.totalRow.gt30Count += row.gt30Count;
            analysis.totalRow.gt30Revenue += row.gt30Revenue;
        }

        return analysis;
    }

    private static Boolean matchesOpenAgeingDrill(Lab_Order__c orderRecord, String stageKey, String bucketKey) {
        String stageLabel = normalizeOpenOrderStage(orderRecord.Status__c);
        if (String.isBlank(stageLabel)) {
            return false;
        }

        if (stageKey == OPEN_AGEING_STAGE_PRE && stageLabel != 'Pre sample collection') {
            return false;
        }
        if (stageKey == OPEN_AGEING_STAGE_POST && stageLabel != 'Post sample collection') {
            return false;
        }

        Integer ageInDays = analysisAgeInDays(orderRecord.CreatedDate);

        if (bucketKey == OPEN_AGEING_BUCKET_ALL_OPEN) {
            return stageKey == OPEN_AGEING_STAGE_TOTAL;
        }

        if (bucketKey == OPEN_AGEING_BUCKET_AT_RISK_GT6) {
            return stageKey == OPEN_AGEING_STAGE_TOTAL && ageInDays > 6;
        }

        if (bucketKey == OPEN_AGEING_BUCKET_STAGE_TOTAL) {
            return true;
        }

        return matchesAnalysisAgeBucketKey(ageInDays, bucketKey);
    }

    private static Integer analysisAgeInDays(Datetime createdDateTime) {
        return createdDateTime == null ? 0 : createdDateTime.date().daysBetween(Date.today());
    }

    private static Boolean matchesAnalysisAgeBucketKey(Integer ageInDays, String bucketKey) {
        if (bucketKey == OPEN_AGEING_BUCKET_LT3) {
            return ageInDays < 3;
        }
        if (bucketKey == OPEN_AGEING_BUCKET_D3TO6) {
            return ageInDays >= 3 && ageInDays <= 6;
        }
        if (bucketKey == OPEN_AGEING_BUCKET_D7TO15) {
            return ageInDays >= 7 && ageInDays <= 15;
        }
        if (bucketKey == OPEN_AGEING_BUCKET_D15TO30) {
            return ageInDays >= 16 && ageInDays <= 30;
        }
        if (bucketKey == OPEN_AGEING_BUCKET_GT30) {
            return ageInDays > 30;
        }
        return false;
    }

    private static void sortLabOrdersForAgeingDrill(List<Lab_Order__c> rows, String sortBy, String sortDirection) {
        final String direction = resolveSortDirection(sortDirection);
        final Boolean ascending = direction == 'ASC';

        rows.sort(new LabOrderAgeingDrillComparator(sortBy, ascending));
    }

    private class LabOrderAgeingDrillComparator implements Comparator<Lab_Order__c> {
        private String sortBy;
        private Boolean ascending;

        LabOrderAgeingDrillComparator(String sortByValue, Boolean ascendingValue) {
            this.sortBy = String.isBlank(sortByValue) ? 'createdDate' : sortByValue;
            this.ascending = ascendingValue != null && ascendingValue;
        }

        public Integer compare(Lab_Order__c a, Lab_Order__c b) {
            Integer result = innerCompare(a, b);
            if (!ascending) {
                result = -result;
            }
            return result;
        }

        private Integer innerCompare(Lab_Order__c a, Lab_Order__c b) {
            if (sortBy == 'name') {
                return compareStrings(a.Name, b.Name);
            }
            if (sortBy == 'amount') {
                return compareDecimals(nvlAmount(a.Partner_Order_total__c), nvlAmount(b.Partner_Order_total__c));
            }
            if (sortBy == 'status') {
                return compareStrings(a.Status__c, b.Status__c);
            }
            if (sortBy == 'mor') {
                return compareStrings(a.Payment_Transaction_Id__c, b.Payment_Transaction_Id__c);
            }
            Datetime ad = a.CreatedDate;
            Datetime bd = b.CreatedDate;
            if (ad == null && bd == null) {
                return compareIds(a.Id, b.Id);
            }
            if (ad == null) {
                return -1;
            }
            if (bd == null) {
                return 1;
            }
            if (ad.getTime() == bd.getTime()) {
                return compareIds(a.Id, b.Id);
            }
            return ad.getTime() < bd.getTime() ? -1 : 1;
        }

        private Decimal nvlAmount(Decimal v) {
            return v == null ? 0 : v;
        }

        private Integer compareStrings(String x, String y) {
            String xs = x == null ? '' : x;
            String ys = y == null ? '' : y;
            return xs.compareTo(ys);
        }

        private Integer compareDecimals(Decimal x, Decimal y) {
            if (x == y) {
                return 0;
            }
            return x < y ? -1 : 1;
        }

        private Integer compareIds(Id a, Id b) {
            if (a == null && b == null) {
                return 0;
            }
            if (a == null) {
                return -1;
            }
            if (b == null) {
                return 1;
            }
            return String.valueOf(a).compareTo(String.valueOf(b));
        }
    }

    private static OpenOrderAgeingAnalysisBucketWrapper createAnalysisAgeBucket(Datetime createdDateTime, Decimal revenue) {
        Integer ageInDays = createdDateTime == null ? 0 : createdDateTime.date().daysBetween(Date.today());
        String key;

        if (ageInDays < 3) {
            key = 'lt3';
        } else if (ageInDays <= 6) {
            key = 'd3to6';
        } else if (ageInDays <= 15) {
            key = 'd7to15';
        } else if (ageInDays <= 30) {
            key = 'd15to30';
        } else {
            key = 'gt30';
        }

        return new OpenOrderAgeingAnalysisBucketWrapper(key, Math.max(0, revenue == null ? 0 : revenue), ageInDays);
    }

    private static String normalizeOpenOrderStage(String status) {
        if (String.isBlank(status) || PRE_SAMPLE_COLLECTION_STATUSES.contains(status)) {
            return 'Pre sample collection';
        }

        if (POST_SAMPLE_COLLECTION_STATUSES.contains(status)) {
            return 'Post sample collection';
        }

        return null;
    }

    private static String resolveSortDirection(String sortDirection) {
        if (String.isNotBlank(sortDirection) && sortDirection.toUpperCase() == 'ASC') {
            return 'ASC';
        }
        return 'DESC';
    }

    private static Map<Id, PartnerReference> getPartnerReferences() {

        Map<Id, PartnerReference> partnerReferences = new Map<Id, PartnerReference>();

        for (PartnerClientMap__c pcm : [
            SELECT Id, Client_ID__c, Name, Partner_Name__c
            FROM PartnerClientMap__c
        ]) {
            partnerReferences.put(
                pcm.Id,
                new PartnerReference(pcm.Id, pcm.Client_ID__c, pcm.Name, pcm.Partner_Name__c)
            );
        }

        return partnerReferences;
    }

    private static Map<Id, PartnerMetrics> buildMetricsByPartnerMapId(Set<Id> partnerMapIds, Date startDate, Date endDate) {

        Map<Id, PartnerMetrics> metricsByPartnerMapId = new Map<Id, PartnerMetrics>();

        if (partnerMapIds == null || partnerMapIds.isEmpty()) {
            return metricsByPartnerMapId;
        }

        Datetime startDateTime = startDate == null
            ? null
            : Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
        Datetime endDateExclusive = endDate == null
            ? null
            : Datetime.newInstance(endDate.addDays(1), Time.newInstance(0, 0, 0, 0));

        List<Lab_Order__c> labOrders;

        if (startDateTime == null || endDateExclusive == null) {
            labOrders = [
                SELECT Id,
                       Status__c,
                       Partner_Order_total__c,
                       Refund_Amount__c,
                       Payment_Transaction_Id__c,
                       Partner_Client_Map__c,
                       CreatedDate,
                       Date_Reported__c,
                       Cancellation_Date__c,
                       Cancellation_Service_Fee__c
                FROM Lab_Order__c
                WHERE Partner_Client_Map__c IN :partnerMapIds
            ];
        } else {
            labOrders = [
                SELECT Id,
                       Status__c,
                       Partner_Order_total__c,
                       Refund_Amount__c,
                       Payment_Transaction_Id__c,
                       Partner_Client_Map__c,
                       CreatedDate,
                       Date_Reported__c,
                       Cancellation_Date__c,
                       Cancellation_Service_Fee__c
                FROM Lab_Order__c
                WHERE Partner_Client_Map__c IN :partnerMapIds
                  AND (
                       (CreatedDate >= :startDateTime
                        AND CreatedDate < :endDateExclusive)
                       OR (Date_Reported__c >= :startDate AND Date_Reported__c <= :endDate)
                       OR (Cancellation_Date__c >= :startDate AND Cancellation_Date__c <= :endDate)
                  )
            ];
        }

        for (Lab_Order__c labOrder : labOrders) {
            Id labOrderPartnerMapId = labOrder.Partner_Client_Map__c;

            if (labOrderPartnerMapId == null) {
                continue;
            }

            if (!metricsByPartnerMapId.containsKey(labOrderPartnerMapId)) {
                metricsByPartnerMapId.put(labOrderPartnerMapId, new PartnerMetrics());
            }

            PartnerMetrics metrics = metricsByPartnerMapId.get(labOrderPartnerMapId);
            Decimal grossOrderRevenue = labOrder.Partner_Order_total__c == null ? 0 : labOrder.Partner_Order_total__c;
            Decimal orderRevenue = Math.max(0, grossOrderRevenue);
            Decimal cancellationFee = labOrder.Partner_Order_total__c == null ? 0 : labOrder.Partner_Order_total__c;
            Boolean isQmor = String.isNotBlank(labOrder.Payment_Transaction_Id__c);
            Integer orderAgeInDays = labOrder.CreatedDate == null
                ? 0
                : labOrder.CreatedDate.date().daysBetween(Date.today());
            Date purchaseDate = labOrder.CreatedDate == null
                ? null
                : labOrder.CreatedDate.date();
            Date completionDate = labOrder.Date_Reported__c;
            Date cancellationDate = labOrder.Cancellation_Date__c;
            Boolean isPurchaseInWindow = isWithinDateWindow(purchaseDate, startDate, endDate);
            Boolean isCompletionInWindow = isWithinDateWindow(completionDate, startDate, endDate);
            Boolean isCancellationInWindow = isWithinDateWindow(cancellationDate, startDate, endDate);

            if (isPurchaseInWindow) {
                metrics.totalOrders += 1;
                metrics.grossRevenue += orderRevenue;

                if (isQmor) {
                    metrics.qmorRevenue += orderRevenue;
                } else {
                    metrics.pmorRevenue += orderRevenue;
                }
            }

            if (isRevenueStatus(labOrder.Status__c) && isCompletionInWindow) {
                metrics.realizedRevenue += orderRevenue;
            }

            if (isCompletionInWindow && isSameMonthPurchaseAndCompletion(labOrder)) {
                metrics.realizedRevenueSameMonth += orderRevenue;
            }

            if (isCompletedStatus(labOrder.Status__c) && isCompletionInWindow) {
                metrics.completedOrders += 1;

                Integer completionDays = (purchaseDate != null && completionDate != null)
                    ? purchaseDate.daysBetween(completionDate)
                    : null;

                if (completionDays != null && completionDays <= FAST_COMPLETION_DAYS) {
                    metrics.completedWithinFiveDays += 1;
                }
            }

            if (labOrder.Status__c == 'Cancelled' && isCancellationInWindow) {
                metrics.cancelledOrders += 1;
                metrics.cancelledRevenue += Math.max(0, cancellationFee);
            }

            if (isPurchaseInWindow && isLostStatus(labOrder.Status__c)) {
                // If a status is also considered realized revenue (e.g. Expired),
                // avoid double-counting in both realized and lost buckets.
                if (!isRevenueStatus(labOrder.Status__c)) {
                    metrics.lostRevenue += orderRevenue;
                }
            } else if (isPurchaseInWindow) {
                metrics.openOrders += 1;

                if (orderAgeInDays >= REVENUE_AT_RISK_START_DAYS && orderAgeInDays <= REVENUE_AT_RISK_END_DAYS) {
                    metrics.revenueAtRisk += orderRevenue;
                    metrics.cancellationRiskOrders += 1;
                    metrics.cancellationRiskRevenue += orderRevenue;
                }
            }
        }

        return metricsByPartnerMapId;
    }

    private static DateWindow resolveDateWindow(String dateRange, Date customStartDate, Date customEndDate) {
        Date today = Date.today();

        if (dateRange == DATE_RANGE_CUSTOM && customStartDate != null && customEndDate != null) {
            Date start = customStartDate <= customEndDate ? customStartDate : customEndDate;
            Date endDateValue = customStartDate <= customEndDate ? customEndDate : customStartDate;
            return new DateWindow(start, endDateValue);
        }

        if (String.isBlank(dateRange) || dateRange == DATE_RANGE_LAST_30_DAYS) {
            return new DateWindow(today.addDays(-30), today);
        }

        if (dateRange == DATE_RANGE_LAST_60_DAYS) {
            return new DateWindow(today.addDays(-60), today);
        }

        if (dateRange == DATE_RANGE_LAST_90_DAYS) {
            return new DateWindow(today.addDays(-90), today);
        }

        if (dateRange == DATE_RANGE_YEAR_TO_DATE) {
            return new DateWindow(Date.newInstance(today.year(), 1, 1), today);
        }

        return new DateWindow(today.addDays(-30), today);
    }

    private static Boolean isCompletedStatus(String status) {
        return COMPLETED_STATUSES.contains(status);
    }

    private static Boolean isRevenueStatus(String status) {
        return REVENUE_STATUSES.contains(status);
    }

    private static Boolean isLostStatus(String status) {
        return LOST_STATUSES.contains(status);
    }

    private static Boolean isWithinDateWindow(Date value, Date startDate, Date endDate) {
        if (value == null) {
            return false;
        }
        if (startDate == null || endDate == null) {
            return true;
        }
        return value >= startDate && value <= endDate;
    }

    /**
     * Net revenue from tests purchased and completed (Results Ready) in the same calendar month.
     * Completion month is taken from Date_Reported__c; orders without that date are excluded.
     */
    private static Boolean isSameMonthPurchaseAndCompletion(Lab_Order__c labOrder) {
        if (!isCompletedStatus(labOrder.Status__c) || labOrder.CreatedDate == null) {
            return false;
        }
        Date purchaseDate = labOrder.CreatedDate.date();
        Date reportedDate = labOrder.Date_Reported__c;
        if (reportedDate == null) {
            return false;
        }
        return purchaseDate.year() == reportedDate.year() && purchaseDate.month() == reportedDate.month();
    }

    public class PartnerReference {

        public Id partnerId;
        public String clientId;
        public String displayName;
        public String partnerName;

        public PartnerReference(Id partnerId, String clientId, String displayName, String partnerName) {
            this.partnerId = partnerId;
            this.clientId = clientId;
            this.displayName = displayName;
            this.partnerName = partnerName;
        }
    }

    public class PartnerMetrics {

        public Integer totalOrders = 0;
        public Integer completedOrders = 0;
        public Integer cancelledOrders = 0;
        public Integer openOrders = 0;
        public Integer completedWithinFiveDays = 0;
        public Integer cancellationRiskOrders = 0;
        public Decimal grossRevenue = 0;
        public Decimal qmorRevenue = 0;
        public Decimal pmorRevenue = 0;
        public Decimal realizedRevenue = 0;
        public Decimal realizedRevenueSameMonth = 0;
        public Decimal lostRevenue = 0;
        public Decimal cancelledRevenue = 0;
        public Decimal revenueAtRisk = 0;
        public Decimal cancellationRiskRevenue = 0;

        public Decimal getAov() {
            return totalOrders > 0
                ? grossRevenue / totalOrders
                : 0;
        }

        public Decimal getCompletionRate() {
            return totalOrders > 0
                ? (Decimal.valueOf(completedOrders) / totalOrders) * 100
                : 0;
        }

        public Decimal getRealizedPercentOfGross() {
            return grossRevenue > 0
                ? (realizedRevenue / grossRevenue) * 100
                : 0;
        }

        public Decimal getRealizedSameMonthPercentOfRealized() {
            return realizedRevenue > 0
                ? (realizedRevenueSameMonth / realizedRevenue) * 100
                : 0;
        }

        public Decimal getRiskPercentOfGross() {
            return grossRevenue > 0
                ? (revenueAtRisk / grossRevenue) * 100
                : 0;
        }

        public Decimal getCompletionWithinFiveDaysRate() {
            return completedOrders > 0
                ? (Decimal.valueOf(completedWithinFiveDays) / completedOrders) * 100
                : 0;
        }

        public Decimal getCancellationRiskPercentOfOrders() {
            return totalOrders > 0
                ? (Decimal.valueOf(cancellationRiskOrders) / totalOrders) * 100
                : 0;
        }

        public Decimal getQmorPercentOfGross() {
            return grossRevenue > 0
                ? (qmorRevenue / grossRevenue) * 100
                : 0;
        }

        public Decimal getPmorPercentOfGross() {
            return grossRevenue > 0
                ? (pmorRevenue / grossRevenue) * 100
                : 0;
        }
    }

    public class PartnerPerformanceWrapper {

        @AuraEnabled public String partnerName;
        @AuraEnabled public Id partnerId;
        @AuraEnabled public String clientId;
        @AuraEnabled public String region;
        @AuraEnabled public String category;
        @AuraEnabled public Integer totalOrders;
        @AuraEnabled public Integer completedOrders;
        @AuraEnabled public Integer cancelledOrders;
        @AuraEnabled public Integer cancellationRiskOrders;
        @AuraEnabled public Decimal completionRate;
        @AuraEnabled public Decimal grossRevenue;
        @AuraEnabled public Decimal aov;
        @AuraEnabled public Decimal realizedRevenue;
        @AuraEnabled public Decimal lostRevenue;
        @AuraEnabled public Decimal cancelledRevenue;
        @AuraEnabled public Decimal revenueAtRisk;
        @AuraEnabled public Decimal cancellationRiskRevenue;
        @AuraEnabled public Decimal qmorRevenue;
        @AuraEnabled public Decimal pmorRevenue;

        public PartnerPerformanceWrapper(PartnerReference partnerReference, PartnerMetrics metrics) {

            this.partnerName = partnerReference.displayName;
            this.partnerId = partnerReference.partnerId;
            this.clientId = partnerReference.clientId;
            this.region = null;
            this.category = null;
            this.totalOrders = metrics.totalOrders;
            this.completedOrders = metrics.completedOrders;
            this.cancelledOrders = metrics.cancelledOrders;
            this.cancellationRiskOrders = metrics.cancellationRiskOrders;
            this.completionRate = metrics.getCompletionRate();
            this.grossRevenue = metrics.grossRevenue;
            this.aov = metrics.getAov();
            this.realizedRevenue = metrics.realizedRevenue;
            this.lostRevenue = metrics.lostRevenue;
            this.cancelledRevenue = metrics.cancelledRevenue;
            this.revenueAtRisk = metrics.revenueAtRisk;
            this.cancellationRiskRevenue = metrics.cancellationRiskRevenue;
            this.qmorRevenue = metrics.qmorRevenue;
            this.pmorRevenue = metrics.pmorRevenue;
        }
    }

    public class PartnerDetailWrapper {

        @AuraEnabled public String partnerName;
        @AuraEnabled public Id partnerId;
        @AuraEnabled public String clientId;
        @AuraEnabled public String region;
        @AuraEnabled public String category;
        @AuraEnabled public Integer totalOrders;
        @AuraEnabled public Decimal completionRate;
        @AuraEnabled public Decimal grossRevenue;
        @AuraEnabled public Decimal aov;
        @AuraEnabled public Decimal realizedRevenue;
        @AuraEnabled public Decimal realizedPercentOfGross;
        @AuraEnabled public Decimal revenueAtRisk;
        @AuraEnabled public Decimal revenueAtRiskPercentOfGross;
        @AuraEnabled public Integer purchases;
        @AuraEnabled public Integer completedOrders;
        @AuraEnabled public Integer cancelledOrders;
        @AuraEnabled public Decimal completedPercent;
        @AuraEnabled public Decimal completionWithinFiveDaysRate;
        @AuraEnabled public Integer cancellationRiskOrders;
        @AuraEnabled public Decimal cancellationRiskPercentOfOrders;
        @AuraEnabled public Decimal cancellationRiskRevenue;
        @AuraEnabled public Decimal averageDistanceToPsc;
        @AuraEnabled public Decimal labCompletionRate;
        @AuraEnabled public Decimal lostRevenue;
        @AuraEnabled public Decimal cancelledRevenue;
        @AuraEnabled public Decimal qmorRevenue;
        @AuraEnabled public Decimal qmorPercentOfGross;
        @AuraEnabled public Decimal pmorRevenue;
        @AuraEnabled public Decimal pmorPercentOfGross;

        public PartnerDetailWrapper(PartnerReference partnerReference, PartnerMetrics metrics) {

            this.partnerName = partnerReference.displayName;
            this.partnerId = partnerReference.partnerId;
            this.clientId = partnerReference.clientId;
            this.region = null;
            this.category = null;
            this.totalOrders = metrics.totalOrders;
            this.completionRate = metrics.getCompletionRate();
            this.grossRevenue = metrics.grossRevenue;
            this.aov = metrics.getAov();
            this.realizedRevenue = metrics.realizedRevenue;
            this.realizedPercentOfGross = metrics.getRealizedPercentOfGross();
            this.revenueAtRisk = metrics.revenueAtRisk;
            this.revenueAtRiskPercentOfGross = metrics.getRiskPercentOfGross();
            this.purchases = metrics.totalOrders;
            this.completedOrders = metrics.completedOrders;
            this.cancelledOrders = metrics.cancelledOrders;
            this.completedPercent = metrics.getCompletionRate();
            this.completionWithinFiveDaysRate = metrics.getCompletionWithinFiveDaysRate();
            this.cancellationRiskOrders = metrics.cancellationRiskOrders;
            this.cancellationRiskPercentOfOrders = metrics.getCancellationRiskPercentOfOrders();
            this.cancellationRiskRevenue = metrics.cancellationRiskRevenue;
            this.averageDistanceToPsc = null;
            this.labCompletionRate = null;
            this.lostRevenue = metrics.lostRevenue;
            this.cancelledRevenue = metrics.cancelledRevenue;
            this.qmorRevenue = metrics.qmorRevenue;
            this.qmorPercentOfGross = metrics.getQmorPercentOfGross();
            this.pmorRevenue = metrics.pmorRevenue;
            this.pmorPercentOfGross = metrics.getPmorPercentOfGross();
        }
    }

    public class LabOrderRowWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String createdDate;
        @AuraEnabled public String mor;
        @AuraEnabled public String cancellationReason;

        @AuraEnabled public String clientAccountNumber;
        @AuraEnabled public String partnerName;
        @AuraEnabled public String labOrderId;
        @AuraEnabled public String externalPartnerOrderId;
        @AuraEnabled public String labRefId;
        @AuraEnabled public String accessionId;
        @AuraEnabled public String orderCreatedDate;
        @AuraEnabled public String dateSampleCollected;
        @AuraEnabled public String dateResulted;
        @AuraEnabled public String nonRefundableDate;
        @AuraEnabled public String registrantName;
        @AuraEnabled public String performingSite;

        public LabOrderRowWrapper(Lab_Order__c lo) {
            Decimal gross = lo.Partner_Order_total__c != null ? lo.Partner_Order_total__c : 0;
            Decimal refund = lo.Refund_Amount__c != null ? lo.Refund_Amount__c : 0;
            this.id = lo.Id;
            this.name = lo.Name != null ? lo.Name : '';
            this.status = lo.Status__c != null ? lo.Status__c : '';
            this.amount = Math.max(0, gross - refund);
            this.createdDate = lo.CreatedDate != null
                ? lo.CreatedDate.format('yyyy-MM-dd')
                : '';
            this.mor = String.isNotBlank(lo.Payment_Transaction_Id__c) ? 'QMoR' : 'PMoR';
            this.cancellationReason = '';
            clearRealizedDetailFields();
        }

        public LabOrderRowWrapper(Lab_Order__c lo, String filterType) {
            this.id = lo.Id;
            this.name = lo.Name != null ? lo.Name : '';
            this.status = lo.Status__c != null ? lo.Status__c : '';
            this.mor = String.isNotBlank(lo.Payment_Transaction_Id__c) ? 'QMoR' : 'PMoR';
            this.cancellationReason = '';
            clearRealizedDetailFields();

            if (filterType == ORDER_FILTER_CANCELLED) {
                this.amount = Math.max(0, lo.Cancellation_Service_Fee__c == null ? 0 : lo.Cancellation_Service_Fee__c);
                this.createdDate = lo.Cancellation_Date__c != null
                    ? String.valueOf(lo.Cancellation_Date__c)
                    : '';
                this.cancellationReason = lo.Cancel_Reason__c != null ? String.valueOf(lo.Cancel_Reason__c) : '';
            } else if (filterType == ORDER_FILTER_REALIZED) {
                this.amount = Math.max(0, lo.Partner_Order_total__c == null ? 0 : lo.Partner_Order_total__c);
                this.createdDate = lo.Date_Reported__c != null
                    ? String.valueOf(lo.Date_Reported__c)
                    : '';
                populateRealizedSnapshot(lo);
            } else {
                Decimal gross = lo.Partner_Order_total__c != null ? lo.Partner_Order_total__c : 0;
                Decimal refund = lo.Refund_Amount__c != null ? lo.Refund_Amount__c : 0;
                this.amount = Math.max(0, gross - refund);
                this.createdDate = lo.CreatedDate != null
                    ? lo.CreatedDate.format('yyyy-MM-dd')
                    : '';
            }
        }

        private void clearRealizedDetailFields() {
            this.clientAccountNumber = '';
            this.partnerName = '';
            this.labOrderId = '';
            this.externalPartnerOrderId = '';
            this.labRefId = '';
            this.accessionId = '';
            this.orderCreatedDate = '';
            this.dateSampleCollected = '';
            this.dateResulted = '';
            this.nonRefundableDate = '';
            this.registrantName = '';
            this.performingSite = '';
        }

        private void populateRealizedSnapshot(Lab_Order__c lo) {
            this.orderCreatedDate = lo.CreatedDate != null ? lo.CreatedDate.format('yyyy-MM-dd') : '';
            this.dateSampleCollected = lo.Date_of_Collection__c != null ? String.valueOf(lo.Date_of_Collection__c) : '';
            this.dateResulted = lo.Date_Reported__c != null ? String.valueOf(lo.Date_Reported__c) : '';
            this.nonRefundableDate = lo.Expiration_Date__c != null ? String.valueOf(lo.Expiration_Date__c) : '';
            this.labOrderId = String.isNotBlank(lo.FHIR_External_ID__c) ? lo.FHIR_External_ID__c : String.valueOf(lo.Id);
            this.externalPartnerOrderId = lo.External_Partner_Order_Id__c != null
                ? String.valueOf(lo.External_Partner_Order_Id__c)
                : '';
            this.labRefId = lo.LabRefId__c != null ? String.valueOf(lo.LabRefId__c) : '';
            this.accessionId = lo.Accession_ID__c != null ? String.valueOf(lo.Accession_ID__c) : '';
            this.registrantName = lo.Registrant_Name__c != null ? lo.Registrant_Name__c : '';
            this.performingSite = lo.PerformingSite__c != null ? lo.PerformingSite__c : '';
            if (lo.Partner_Client_Map__r != null) {
                this.clientAccountNumber = lo.Partner_Client_Map__r.Client_ID__c != null
                    ? String.valueOf(lo.Partner_Client_Map__r.Client_ID__c)
                    : '';
                this.partnerName = lo.Partner_Client_Map__r.Name != null
                    ? String.valueOf(lo.Partner_Client_Map__r.Name)
                    : '';
            }
        }
    }

    public class PartnerLabOrdersResult {
        @AuraEnabled public List<LabOrderRowWrapper> orders;
        @AuraEnabled public Integer totalCount;
    }

    public class PartnerRealizedPanelRowsResult {
        @AuraEnabled public List<RealizedPanelRowWrapper> rows;
        @AuraEnabled public Integer totalCount;
    }

    public class RealizedPanelRowWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public Id labOrderRecordId;
        @AuraEnabled public String labOrderName;
        @AuraEnabled public String labOrderId;
        @AuraEnabled public String externalPartnerOrderId;
        @AuraEnabled public String labRefId;
        @AuraEnabled public String accessionId;
        @AuraEnabled public String orderCreatedDate;
        @AuraEnabled public String dateSampleCollected;
        @AuraEnabled public String dateResulted;
        @AuraEnabled public String nonRefundableDate;
        @AuraEnabled public String registrantName;
        @AuraEnabled public String performingSite;
        @AuraEnabled public String panelCode;
        @AuraEnabled public String panelName;
        @AuraEnabled public Decimal panelPrice;
        @AuraEnabled public String panelStatus;
        @AuraEnabled public String mor;

        public RealizedPanelRowWrapper(Lab_Order_Panel__c panel) {
            this.id = panel.Id;
            Lab_Order__c lo = panel.Lab_Order__r;
            this.labOrderRecordId = lo != null ? lo.Id : null;
            this.labOrderName = lo != null && lo.Name != null ? lo.Name : '';
            this.labOrderId = lo != null && String.isNotBlank(lo.FHIR_External_ID__c)
                ? lo.FHIR_External_ID__c
                : (lo != null ? String.valueOf(lo.Id) : '');
            this.externalPartnerOrderId = lo != null && lo.External_Partner_Order_Id__c != null
                ? String.valueOf(lo.External_Partner_Order_Id__c)
                : '';
            this.labRefId = lo != null && lo.LabRefId__c != null ? String.valueOf(lo.LabRefId__c) : '';
            this.accessionId = lo != null && lo.Accession_ID__c != null ? String.valueOf(lo.Accession_ID__c) : '';
            this.orderCreatedDate = lo != null && lo.CreatedDate != null ? lo.CreatedDate.format('yyyy-MM-dd') : '';
            this.dateSampleCollected = lo != null && lo.Date_of_Collection__c != null
                ? String.valueOf(lo.Date_of_Collection__c)
                : '';
            this.dateResulted = lo != null && lo.Date_Reported__c != null ? String.valueOf(lo.Date_Reported__c) : '';
            this.nonRefundableDate = lo != null && lo.Expiration_Date__c != null
                ? String.valueOf(lo.Expiration_Date__c)
                : '';
            this.registrantName = lo != null && lo.Registrant_Name__c != null ? lo.Registrant_Name__c : '';
            String site = panel.Performing_Site__c != null ? String.valueOf(panel.Performing_Site__c) : '';
            if (String.isBlank(site) && lo != null && lo.PerformingSite__c != null) {
                site = lo.PerformingSite__c;
            }
            this.performingSite = site;
            this.panelCode = panel.Panel_Code__c != null ? String.valueOf(panel.Panel_Code__c) : '';
            this.panelName = panel.Product_Name__c != null ? panel.Product_Name__c : '';
            this.panelPrice = panel.Panel_Price__c == null ? 0 : panel.Panel_Price__c;
            this.panelStatus = String.isNotBlank(panel.Panel_Status__c)
                ? panel.Panel_Status__c
                : (panel.Status__c != null ? String.valueOf(panel.Status__c) : '');
            this.mor = lo != null && String.isNotBlank(lo.Payment_Transaction_Id__c) ? 'QMoR' : 'PMoR';
        }
    }

    public class PartnerRealizedSummaryResult {
        @AuraEnabled public List<RealizedSummaryRowWrapper> rows;
        @AuraEnabled public Integer totalCount;
        @AuraEnabled public Decimal grandTotalQuantity;
        @AuraEnabled public Decimal grandTotalAmount;
    }

    public class RealizedSummaryRowWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String panelCode;
        @AuraEnabled public String panelName;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal panelPrice;
        @AuraEnabled public Decimal totalAmount;
    }

    public class ProductSearchResultWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String productCode;
        @AuraEnabled public String sku;
        @AuraEnabled public String ecommProductId;
        @AuraEnabled public String subtitle;

        public ProductSearchResultWrapper(Product2 productRecord) {
            this.id = productRecord.Id;
            this.name = productRecord.Name;
            this.productCode = productRecord.ProductCode;
            this.sku = productRecord.StockKeepingUnit;
            this.ecommProductId = (String) productRecord.get('productId_Ecom__c');

            List<String> parts = new List<String>();
            if (String.isNotBlank(this.productCode)) {
                parts.add('Code: ' + this.productCode);
            }
            if (String.isNotBlank(this.sku)) {
                parts.add('SKU: ' + this.sku);
            }
            if (String.isNotBlank(this.ecommProductId)) {
                parts.add('Ecomm ID: ' + this.ecommProductId);
            }
            this.subtitle = String.join(parts, ' | ');
        }
    }

    public class PartnerProductEditorWrapper {
        @AuraEnabled public Id partnerId;
        @AuraEnabled public String partnerName;
        @AuraEnabled public List<ExistingProductPartnerMapWrapper> productMaps = new List<ExistingProductPartnerMapWrapper>();
    }

    public class ExistingProductPartnerMapWrapper {
        @AuraEnabled public Id mapId;
        @AuraEnabled public Id productId;
        @AuraEnabled public String productName;
        @AuraEnabled public String productSubtitle;
        @AuraEnabled public Decimal productPrice;
        @AuraEnabled public Decimal cancellationFee;

        public ExistingProductPartnerMapWrapper(Product_Partner_Map__c mapRecord) {
            this.mapId = mapRecord.Id;
            this.productId = mapRecord.Product__c;
            this.productName = mapRecord.Product__r != null ? mapRecord.Product__r.Name : null;

            List<String> parts = new List<String>();
            if (mapRecord.Product__r != null && String.isNotBlank(mapRecord.Product__r.ProductCode)) {
                parts.add('Code: ' + mapRecord.Product__r.ProductCode);
            }
            if (mapRecord.Product__r != null && String.isNotBlank(mapRecord.Product__r.StockKeepingUnit)) {
                parts.add('SKU: ' + mapRecord.Product__r.StockKeepingUnit);
            }
            if (mapRecord.Product__r != null && String.isNotBlank((String) mapRecord.Product__r.get('productId_Ecom__c'))) {
                parts.add('Ecomm ID: ' + (String) mapRecord.Product__r.get('productId_Ecom__c'));
            }

            this.productSubtitle = String.join(parts, ' | ');
            this.productPrice = mapRecord.Product_Price__c;
            this.cancellationFee = mapRecord.Cancellation_Fee__c;
        }
    }

    public class OverviewSummaryWrapper {
        @AuraEnabled public Integer totalOrders;
        @AuraEnabled public Integer cancelledOrders;
        @AuraEnabled public Integer cancellationRiskOrders;
        @AuraEnabled public Decimal grossRevenue;
        @AuraEnabled public Decimal realizedRevenue;
        @AuraEnabled public Decimal realizedRevenueSameMonth;
        @AuraEnabled public Decimal realizedSameMonthPercentOfRealized;
        @AuraEnabled public Decimal lostRevenue;
        @AuraEnabled public Decimal cancelledRevenue;
        @AuraEnabled public Decimal revenueAtRisk;
        @AuraEnabled public Decimal cancellationRiskRevenue;
        @AuraEnabled public Decimal qmorRevenue;
        @AuraEnabled public Decimal qmorPercentOfGross;
        @AuraEnabled public Decimal pmorRevenue;
        @AuraEnabled public Decimal pmorPercentOfGross;
        @AuraEnabled public Decimal aov;

        public OverviewSummaryWrapper(PartnerMetrics metrics) {
            this.totalOrders             = metrics.totalOrders;
            this.cancelledOrders         = metrics.cancelledOrders;
            this.cancellationRiskOrders  = metrics.cancellationRiskOrders;
            this.grossRevenue            = metrics.grossRevenue;
            this.realizedRevenue         = metrics.realizedRevenue;
            this.realizedRevenueSameMonth = metrics.realizedRevenueSameMonth;
            this.realizedSameMonthPercentOfRealized = metrics.getRealizedSameMonthPercentOfRealized();
            this.lostRevenue             = metrics.lostRevenue;
            this.cancelledRevenue        = metrics.cancelledRevenue;
            this.revenueAtRisk           = metrics.revenueAtRisk;
            this.cancellationRiskRevenue = metrics.cancellationRiskRevenue;
            this.qmorRevenue             = metrics.qmorRevenue;
            this.qmorPercentOfGross      = metrics.getQmorPercentOfGross();
            this.pmorRevenue             = metrics.pmorRevenue;
            this.pmorPercentOfGross      = metrics.getPmorPercentOfGross();
            this.aov                     = metrics.getAov();
        }
    }

    public class OpenOrderAgeingAnalysisWrapper {
        @AuraEnabled public List<OpenOrderAgeingAnalysisRowWrapper> rows = new List<OpenOrderAgeingAnalysisRowWrapper>();
        @AuraEnabled public OpenOrderAgeingAnalysisRowWrapper totalRow = new OpenOrderAgeingAnalysisRowWrapper('TOTAL');
        @AuraEnabled public Integer totalOpenOrders = 0;
        @AuraEnabled public Decimal totalOpenRevenue = 0;
        @AuraEnabled public Integer atRiskOrdersCount = 0;
        @AuraEnabled public Decimal atRiskOrdersRevenue = 0;
    }

    public class OpenOrderAgeingAnalysisRowWrapper {
        @AuraEnabled public String status;
        @AuraEnabled public Integer totalCount = 0;
        @AuraEnabled public Decimal totalRevenue = 0;
        @AuraEnabled public Integer lt3Count = 0;
        @AuraEnabled public Decimal lt3Revenue = 0;
        @AuraEnabled public Integer d3to6Count = 0;
        @AuraEnabled public Decimal d3to6Revenue = 0;
        @AuraEnabled public Integer d7to15Count = 0;
        @AuraEnabled public Decimal d7to15Revenue = 0;
        @AuraEnabled public Integer d15to30Count = 0;
        @AuraEnabled public Decimal d15to30Revenue = 0;
        @AuraEnabled public Integer gt30Count = 0;
        @AuraEnabled public Decimal gt30Revenue = 0;

        public OpenOrderAgeingAnalysisRowWrapper(String statusLabel) {
            this.status = statusLabel;
        }

        public void addToBucket(String bucketKey, Decimal revenue) {
            totalCount += 1;
            totalRevenue += revenue;

            if (bucketKey == 'lt3') {
                lt3Count += 1;
                lt3Revenue += revenue;
            } else if (bucketKey == 'd3to6') {
                d3to6Count += 1;
                d3to6Revenue += revenue;
            } else if (bucketKey == 'd7to15') {
                d7to15Count += 1;
                d7to15Revenue += revenue;
            } else if (bucketKey == 'd15to30') {
                d15to30Count += 1;
                d15to30Revenue += revenue;
            } else if (bucketKey == 'gt30') {
                gt30Count += 1;
                gt30Revenue += revenue;
            }
        }
    }

    private class OpenOrderAgeingAnalysisBucketWrapper {
        String key;
        Decimal revenue;
        Integer ageInDays;

        OpenOrderAgeingAnalysisBucketWrapper(String bucketKey, Decimal bucketRevenue, Integer bucketAgeInDays) {
            this.key = bucketKey;
            this.revenue = bucketRevenue;
            this.ageInDays = bucketAgeInDays;
        }
    }

    private class RealizedSummaryAccumulator {
        final String panelCodeKey;
        String panelName;
        Decimal quantity = 0;
        Decimal totalAmount = 0;

        RealizedSummaryAccumulator(String codeKey, String nameSeed) {
            this.panelCodeKey = codeKey;
            this.panelName = nameSeed;
        }
    }

    private class RealizedSummaryRowComparator implements Comparator<RealizedSummaryRowWrapper> {
        private final String sortBy;
        private final Boolean ascending;

        RealizedSummaryRowComparator(String sortByValue, Boolean ascendingFlag) {
            this.sortBy = String.isBlank(sortByValue) ? 'panelCode' : sortByValue;
            this.ascending = ascendingFlag != null && ascendingFlag;
        }

        public Integer compare(RealizedSummaryRowWrapper a, RealizedSummaryRowWrapper b) {
            Integer cmp = 0;
            if (sortBy == 'panelName') {
                cmp = compareStringsSafe(a.panelName, b.panelName);
            } else if (sortBy == 'quantity') {
                cmp = compareDecimalsSafe(a.quantity, b.quantity);
            } else if (sortBy == 'panelPrice') {
                cmp = compareDecimalsSafe(a.panelPrice, b.panelPrice);
            } else if (sortBy == 'totalAmount') {
                cmp = compareDecimalsSafe(a.totalAmount, b.totalAmount);
            } else {
                cmp = compareStringsSafe(a.panelCode, b.panelCode);
            }
            if (cmp == 0) {
                cmp = compareStringsSafe(a.id, b.id);
            }
            return ascending ? cmp : -cmp;
        }

        private Integer compareStringsSafe(String x, String y) {
            String xs = x == null ? '' : x;
            String ys = y == null ? '' : y;
            if (xs < ys) {
                return -1;
            }
            if (xs > ys) {
                return 1;
            }
            return 0;
        }

        private Integer compareDecimalsSafe(Decimal x, Decimal y) {
            Decimal xd = x == null ? 0 : x;
            Decimal yd = y == null ? 0 : y;
            if (xd < yd) {
                return -1;
            }
            if (xd > yd) {
                return 1;
            }
            return 0;
        }
    }

    /**
     * Partner-scoped panel reads for the realized drill-down tabs. Uses without sharing so Experience Cloud
     * users still receive rows for lab orders they can already see (master-detail does not always grant
     * child read in portal sharing).
     */
    private without sharing class RealizedPartnerPanelAccess {
        List<Lab_Order_Panel__c> queryPanels(
            Id partnerId,
            Date startDateValue,
            Date endDateValue,
            Set<String> revenueStatuses,
            String orderClause
        ) {
            String rowsSoql =
                'SELECT Id, Panel_Code__c, Product_Name__c, Panel_Price__c, Panel_Status__c, Status__c, '
                    + 'Performing_Site__c, Quantity__c, '
                    + 'Lab_Order__r.Id, Lab_Order__r.Name, Lab_Order__r.External_Partner_Order_Id__c, Lab_Order__r.LabRefId__c, '
                    + 'Lab_Order__r.Accession_ID__c, Lab_Order__r.CreatedDate, Lab_Order__r.Date_Reported__c, '
                    + 'Lab_Order__r.Expiration_Date__c, Lab_Order__r.Registrant_Name__c, Lab_Order__r.PerformingSite__c, '
                    + 'Lab_Order__r.Date_of_Collection__c, Lab_Order__r.FHIR_External_ID__c, Lab_Order__r.Payment_Transaction_Id__c '
                    + 'FROM Lab_Order_Panel__c '
                    + 'WHERE Lab_Order__r.Partner_Client_Map__c = :partnerId '
                    + 'AND Lab_Order__r.Status__c IN :revenueStatuses '
                    + 'AND Lab_Order__r.Date_Reported__c >= :startDateValue AND Lab_Order__r.Date_Reported__c <= :endDateValue'
                    + orderClause;
            return (List<Lab_Order_Panel__c>) Database.query(rowsSoql);
        }

        List<Lab_Order_Panel__c> queryPanelSummaryLines(
            Id partnerId,
            Date startDateValue,
            Date endDateValue,
            Set<String> revenueStatuses
        ) {
            String linesSoql =
                'SELECT Panel_Code__c, Product_Name__c, Panel_Price__c, Quantity__c '
                    + 'FROM Lab_Order_Panel__c '
                    + 'WHERE Lab_Order__r.Partner_Client_Map__c = :partnerId '
                    + 'AND Lab_Order__r.Status__c IN :revenueStatuses '
                    + 'AND Lab_Order__r.Date_Reported__c >= :startDateValue AND Lab_Order__r.Date_Reported__c <= :endDateValue';
            return (List<Lab_Order_Panel__c>) Database.query(linesSoql);
        }
    }

    private class DateWindow {
        Date startDate;
        Date endDate;

        DateWindow(Date startDate, Date endDate) {
            this.startDate = startDate;
            this.endDate = endDate;
        }
    }
}
