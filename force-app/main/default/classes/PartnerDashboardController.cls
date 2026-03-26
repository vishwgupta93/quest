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
    public static final String ORDER_FILTER_AT_RISK = 'AT_RISK';
    private static final Integer DEFAULT_PAGE_SIZE = 25;
    private static final Integer MAX_PAGE_SIZE = 100;

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
            aggregate.openOrders               += pm.openOrders;
            aggregate.completedWithinFiveDays  += pm.completedWithinFiveDays;
            aggregate.cancellationRiskOrders   += pm.cancellationRiskOrders;
            aggregate.grossRevenue             += pm.grossRevenue;
            aggregate.qmorRevenue              += pm.qmorRevenue;
            aggregate.pmorRevenue              += pm.pmorRevenue;
            aggregate.realizedRevenue          += pm.realizedRevenue;
            aggregate.realizedRevenueSameMonth += pm.realizedRevenueSameMonth;
            aggregate.lostRevenue              += pm.lostRevenue;
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

            if (metrics.totalOrders == 0) {
                continue;
            }

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
        Datetime startDateTime = Datetime.newInstance(window.startDate, Time.newInstance(0, 0, 0, 0));
        Datetime endDateExclusive = Datetime.newInstance(window.endDate.addDays(1), Time.newInstance(0, 0, 0, 0));
        Integer limitRows = (pageSize != null && pageSize > 0)
            ? Math.min(pageSize, MAX_PAGE_SIZE)
            : DEFAULT_PAGE_SIZE;
        Integer offsetRows = (pageOffset != null && pageOffset >= 0) ? pageOffset : 0;
        String filter = (String.isNotBlank(filterType)) ? filterType : ORDER_FILTER_ALL;
        String orderByField = resolveOrderByField(sortBy);
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

        String soql = 'SELECT Id, Name, Status__c, Partner_Order_total__c, Refund_Amount__c, Payment_Transaction_Id__c, CreatedDate FROM Lab_Order__c'
            + ' WHERE Partner_Client_Map__c = :partnerId AND CreatedDate >= :startDateTime AND CreatedDate < :endDateExclusive';
        if (filter == ORDER_FILTER_REALIZED) soql += ' AND Status__c IN :revenueStatuses';
        else if (filter == ORDER_FILTER_LOST) soql += ' AND Status__c IN :lostStatuses';
        soql += orderClause;

        List<Lab_Order__c> scopedOrders = (List<Lab_Order__c>) Database.query(soql);
        result.totalCount = scopedOrders.size();
        Integer fromIdx = Math.min(offsetRows, scopedOrders.size());
        Integer toIdx = Math.min(offsetRows + limitRows, scopedOrders.size());
        for (Integer i = fromIdx; i < toIdx; i++) {
            result.orders.add(new LabOrderRowWrapper(scopedOrders[i]));
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
        Datetime startDateTime = Datetime.newInstance(window.startDate, Time.newInstance(0, 0, 0, 0));
        Datetime endDateExclusive = Datetime.newInstance(window.endDate.addDays(1), Time.newInstance(0, 0, 0, 0));
        String filter = (String.isNotBlank(filterType)) ? filterType : ORDER_FILTER_ALL;
        String orderByField = resolveOrderByField(sortBy);
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
        String soql = 'SELECT Id, Name, Status__c, Partner_Order_total__c, Refund_Amount__c, Payment_Transaction_Id__c, CreatedDate FROM Lab_Order__c'
            + ' WHERE Partner_Client_Map__c = :partnerId AND CreatedDate >= :startDateTime AND CreatedDate < :endDateExclusive';
        if (filter == ORDER_FILTER_REALIZED) soql += ' AND Status__c IN :revenueStatuses';
        else if (filter == ORDER_FILTER_LOST) soql += ' AND Status__c IN :lostStatuses';
        soql += orderClause;

        for (Lab_Order__c lo : (List<Lab_Order__c>) Database.query(soql)) {
            rows.add(new LabOrderRowWrapper(lo));
        }
        return rows;
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
            + ' AND CreatedDate >= :lowerBound'
            + ' AND CreatedDate < :upperBound'
            + ' AND (Status__c = null OR (Status__c NOT IN :completedStatuses AND Status__c NOT IN :lostStatuses))';

        String rowsSoql = 'SELECT Id, Name, Status__c, Partner_Order_total__c, Refund_Amount__c, Payment_Transaction_Id__c, CreatedDate'
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
        String rowsSoql = 'SELECT Id, Name, Status__c, Partner_Order_total__c, Refund_Amount__c, Payment_Transaction_Id__c, CreatedDate'
            + ' FROM Lab_Order__c'
            + ' WHERE Partner_Client_Map__c = :partnerId'
            + ' AND CreatedDate >= :lowerBound'
            + ' AND CreatedDate < :upperBound'
            + ' AND (Status__c = null OR (Status__c NOT IN :completedStatuses AND Status__c NOT IN :lostStatuses))'
            + orderClause;

        for (Lab_Order__c lo : (List<Lab_Order__c>) Database.query(rowsSoql)) {
            rows.add(new LabOrderRowWrapper(lo));
        }
        return rows;
    }

    private static String resolveOrderByField(String sortBy) {
        if (sortBy == 'name') {
            return 'Name';
        }
        if (sortBy == 'amount') {
            return 'Partner_Order_total__c';
        }
        if (sortBy == 'status') {
            return 'Status__c';
        }
        if (sortBy == 'mor') {
            return 'Payment_Transaction_Id__c';
        }
        return 'CreatedDate';
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
                       Date_Reported__c
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
                       Date_Reported__c
                FROM Lab_Order__c
                WHERE Partner_Client_Map__c IN :partnerMapIds
                  AND CreatedDate >= :startDateTime
                  AND CreatedDate < :endDateExclusive
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
            Decimal refundAmount = labOrder.Refund_Amount__c == null ? 0 : labOrder.Refund_Amount__c;
            Decimal orderRevenue = Math.max(0, grossOrderRevenue);
            Boolean isQmor = String.isNotBlank(labOrder.Payment_Transaction_Id__c);
            Integer orderAgeInDays = labOrder.CreatedDate == null
                ? 0
                : labOrder.CreatedDate.date().daysBetween(Date.today());

            metrics.totalOrders += 1;
            metrics.grossRevenue += orderRevenue;

            if (isQmor) {
                metrics.qmorRevenue += orderRevenue;
            } else {
                metrics.pmorRevenue += orderRevenue;
            }

            if (isRevenueStatus(labOrder.Status__c)) {
                metrics.realizedRevenue += orderRevenue;
            }

            if (isSameMonthPurchaseAndCompletion(labOrder)) {
                metrics.realizedRevenueSameMonth += orderRevenue;
            }

            if (isCompletedStatus(labOrder.Status__c)) {
                metrics.completedOrders += 1;

                if (orderAgeInDays <= FAST_COMPLETION_DAYS) {
                    metrics.completedWithinFiveDays += 1;
                }
            } else if (isLostStatus(labOrder.Status__c)) {
                // If a status is also considered realized revenue (e.g. Expired),
                // avoid double-counting in both realized and lost buckets.
                if (!isRevenueStatus(labOrder.Status__c)) {
                    metrics.lostRevenue += orderRevenue;
                }
            } else {
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
        public Integer openOrders = 0;
        public Integer completedWithinFiveDays = 0;
        public Integer cancellationRiskOrders = 0;
        public Decimal grossRevenue = 0;
        public Decimal qmorRevenue = 0;
        public Decimal pmorRevenue = 0;
        public Decimal realizedRevenue = 0;
        public Decimal realizedRevenueSameMonth = 0;
        public Decimal lostRevenue = 0;
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
        @AuraEnabled public Integer cancellationRiskOrders;
        @AuraEnabled public Decimal completionRate;
        @AuraEnabled public Decimal grossRevenue;
        @AuraEnabled public Decimal aov;
        @AuraEnabled public Decimal realizedRevenue;
        @AuraEnabled public Decimal lostRevenue;
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
            this.cancellationRiskOrders = metrics.cancellationRiskOrders;
            this.completionRate = metrics.getCompletionRate();
            this.grossRevenue = metrics.grossRevenue;
            this.aov = metrics.getAov();
            this.realizedRevenue = metrics.realizedRevenue;
            this.lostRevenue = metrics.lostRevenue;
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
        @AuraEnabled public Decimal completedPercent;
        @AuraEnabled public Decimal completionWithinFiveDaysRate;
        @AuraEnabled public Integer cancellationRiskOrders;
        @AuraEnabled public Decimal cancellationRiskPercentOfOrders;
        @AuraEnabled public Decimal cancellationRiskRevenue;
        @AuraEnabled public Decimal averageDistanceToPsc;
        @AuraEnabled public Decimal labCompletionRate;
        @AuraEnabled public Decimal lostRevenue;
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
            this.completedPercent = metrics.getCompletionRate();
            this.completionWithinFiveDaysRate = metrics.getCompletionWithinFiveDaysRate();
            this.cancellationRiskOrders = metrics.cancellationRiskOrders;
            this.cancellationRiskPercentOfOrders = metrics.getCancellationRiskPercentOfOrders();
            this.cancellationRiskRevenue = metrics.cancellationRiskRevenue;
            this.averageDistanceToPsc = null;
            this.labCompletionRate = null;
            this.lostRevenue = metrics.lostRevenue;
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

        public LabOrderRowWrapper(Lab_Order__c lo) {
            Decimal gross = lo.Partner_Order_total__c != null ? lo.Partner_Order_total__c : 0;
            Decimal refund = lo.Refund_Amount__c != null ? lo.Refund_Amount__c : 0;
            this.id = lo.Id;
            this.name = lo.Name != null ? lo.Name : '';
            this.status = lo.Status__c != null ? lo.Status__c : '';
            this.amount = Math.max(0, gross - refund);
            this.createdDate = lo.CreatedDate != null ? lo.CreatedDate.format('yyyy-MM-dd') : '';
            this.mor = String.isNotBlank(lo.Payment_Transaction_Id__c) ? 'QMoR' : 'PMoR';
        }
    }

    public class PartnerLabOrdersResult {
        @AuraEnabled public List<LabOrderRowWrapper> orders;
        @AuraEnabled public Integer totalCount;
    }

    public class OverviewSummaryWrapper {
        @AuraEnabled public Integer totalOrders;
        @AuraEnabled public Integer cancellationRiskOrders;
        @AuraEnabled public Decimal grossRevenue;
        @AuraEnabled public Decimal realizedRevenue;
        @AuraEnabled public Decimal realizedRevenueSameMonth;
        @AuraEnabled public Decimal realizedSameMonthPercentOfRealized;
        @AuraEnabled public Decimal lostRevenue;
        @AuraEnabled public Decimal revenueAtRisk;
        @AuraEnabled public Decimal cancellationRiskRevenue;
        @AuraEnabled public Decimal qmorRevenue;
        @AuraEnabled public Decimal qmorPercentOfGross;
        @AuraEnabled public Decimal pmorRevenue;
        @AuraEnabled public Decimal pmorPercentOfGross;
        @AuraEnabled public Decimal aov;

        public OverviewSummaryWrapper(PartnerMetrics metrics) {
            this.totalOrders             = metrics.totalOrders;
            this.cancellationRiskOrders  = metrics.cancellationRiskOrders;
            this.grossRevenue            = metrics.grossRevenue;
            this.realizedRevenue         = metrics.realizedRevenue;
            this.realizedRevenueSameMonth = metrics.realizedRevenueSameMonth;
            this.realizedSameMonthPercentOfRealized = metrics.getRealizedSameMonthPercentOfRealized();
            this.lostRevenue             = metrics.lostRevenue;
            this.revenueAtRisk           = metrics.revenueAtRisk;
            this.cancellationRiskRevenue = metrics.cancellationRiskRevenue;
            this.qmorRevenue             = metrics.qmorRevenue;
            this.qmorPercentOfGross      = metrics.getQmorPercentOfGross();
            this.pmorRevenue             = metrics.pmorRevenue;
            this.pmorPercentOfGross      = metrics.getPmorPercentOfGross();
            this.aov                     = metrics.getAov();
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