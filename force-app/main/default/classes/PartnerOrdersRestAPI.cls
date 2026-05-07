@RestResource(urlMapping='/partner/v1/orders')
global with sharing class PartnerOrdersRestAPI {

    private static final Integer MAX_ROWS = 50000;
    private static final Integer MAX_DAYS = 31;
    private static final String  FORMAT_JSON = 'json';
    private static final String  FORMAT_CSV  = 'csv';

    private static final String ORDER_CSV_HEADER =
        'clientAccountNumber,partnerName,orderId,externalPartnerOrderId,labRefId,' +
        'accessionId,orderStatus,dateCreated,dateSampleCollected,dateReported,' +
        'nonRefundableDate,registrantName,registrantEmail,wholesalePrice,partnerPrice,' +
        'refundAmount,cancellationDate,cancellationReason,cancellationServiceFee,paymentTransactionId';

    private static final String TEST_CSV_HEADER =
        ORDER_CSV_HEADER +
        ',panelCode,panelName,panelPrice,panelStatus,testCode,testName,testDescription,testStatus';

    @HttpGet
    global static void getOrders() {
        Long         startMs = System.currentTimeMillis();
        RestRequest  req     = RestContext.request;
        RestResponse res     = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        // ── 1. Parse parameters ───────────────────────────────────────────────
        String  partnerId    = req.params.get('partnerId');
        String  startDateStr = req.params.get('startDate');
        String  endDateStr   = req.params.get('endDate');
        String  incTestsStr  = req.params.get('includeTests');
        String  fmt          = req.params.get('format');
        Boolean includeTests = 'true'.equalsIgnoreCase(incTestsStr);
        fmt = String.isBlank(fmt) ? FORMAT_JSON : fmt.toLowerCase();

        // ── 2. Validate format ────────────────────────────────────────────────
        if (fmt != FORMAT_JSON && fmt != FORMAT_CSV) {
            sendError(res, 400, 'INVALID_FORMAT', 'format must be json or csv');
            return;
        }

        // ── 3. Validate required parameters ──────────────────────────────────
        if (String.isBlank(partnerId)) {
            sendError(res, 400, 'MISSING_PARAMETER', 'partnerId is required');
            return;
        }
        if (String.isBlank(startDateStr)) {
            sendError(res, 400, 'MISSING_PARAMETER', 'startDate is required');
            return;
        }
        if (String.isBlank(endDateStr)) {
            sendError(res, 400, 'MISSING_PARAMETER', 'endDate is required');
            return;
        }

        // ── 4. Parse dates ────────────────────────────────────────────────────
        Date startDate;
        Date endDate;
        try {
            startDate = Date.valueOf(startDateStr);
        } catch (Exception e) {
            sendError(res, 400, 'INVALID_DATE', 'startDate must be an ISO-8601 date (yyyy-MM-dd)');
            return;
        }
        try {
            endDate = Date.valueOf(endDateStr);
        } catch (Exception e) {
            sendError(res, 400, 'INVALID_DATE', 'endDate must be an ISO-8601 date (yyyy-MM-dd)');
            return;
        }

        // ── 5. Validate date range ────────────────────────────────────────────
        if (endDate < startDate) {
            sendError(res, 400, 'INVALID_DATE_RANGE', 'endDate must be on or after startDate');
            return;
        }
        if (startDate.daysBetween(endDate) > MAX_DAYS) {
            sendError(res, 400, 'DATE_RANGE_TOO_LARGE',
                'Date range exceeds ' + MAX_DAYS + ' days. Reduce the date range.');
            return;
        }

        // ── 6. Validate partner ───────────────────────────────────────────────
        List<PartnerClientMap__c> partners = [
            SELECT Id, Partner_Name__c, Client_ID__c
            FROM PartnerClientMap__c
            WHERE Id = :partnerId
            LIMIT 1
        ];
        if (partners.isEmpty()) {
            sendError(res, 403, 'PARTNER_NOT_FOUND', 'partnerId is unknown or not authorized');
            return;
        }

        Id       partnerMapId   = partners[0].Id;
        Datetime startDt        = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
        Datetime endDtExclusive = Datetime.newInstance(endDate.addDays(1), Time.newInstance(0, 0, 0, 0));

        // ── 7. Pre-flight row count ───────────────────────────────────────────
        Integer rowCount;
        if (includeTests) {
            rowCount = Database.countQuery(
                'SELECT COUNT() FROM Lab_Panel_Test__c' +
                ' WHERE Lab_Order_Panel__r.Lab_Order__r.Partner_Client_Map__c = :partnerMapId' +
                ' AND Lab_Order_Panel__r.Lab_Order__r.CreatedDate >= :startDt' +
                ' AND Lab_Order_Panel__r.Lab_Order__r.CreatedDate < :endDtExclusive'
            );
        } else {
            rowCount = Database.countQuery(
                'SELECT COUNT() FROM Lab_Order__c' +
                ' WHERE Partner_Client_Map__c = :partnerMapId' +
                ' AND CreatedDate >= :startDt' +
                ' AND CreatedDate < :endDtExclusive'
            );
        }

        if (rowCount > MAX_ROWS) {
            writeAuditLog(partnerId, startDateStr, endDateStr, includeTests, fmt,
                rowCount, 413, System.currentTimeMillis() - startMs);
            sendError(res, 413, 'PAYLOAD_TOO_LARGE',
                'Result too large. Reduce the date range or set includeTests=false.');
            return;
        }

        // ── 8. Build response body ────────────────────────────────────────────
        String body;
        try {
            body = includeTests
                ? buildTestResponse(partnerMapId, startDt, endDtExclusive, fmt)
                : buildOrderResponse(partnerMapId, startDt, endDtExclusive, fmt);
        } catch (System.LimitException le) {
            writeAuditLog(partnerId, startDateStr, endDateStr, includeTests, fmt,
                rowCount, 413, System.currentTimeMillis() - startMs);
            sendError(res, 413, 'PAYLOAD_TOO_LARGE',
                'Result too large. Reduce the date range or set includeTests=false.');
            return;
        }

        // ── 9. Send response ──────────────────────────────────────────────────
        res.statusCode = 200;
        res.addHeader('Content-Type',
            fmt == FORMAT_CSV ? 'text/csv; charset=UTF-8' : 'application/json');
        res.responseBody = Blob.valueOf(body);

        writeAuditLog(partnerId, startDateStr, endDateStr, includeTests, fmt,
            rowCount, 200, System.currentTimeMillis() - startMs);
    }

    // ── Query + format: order-level ───────────────────────────────────────────

    private static String buildOrderResponse(
        Id partnerMapId, Datetime startDt, Datetime endDtExclusive, String fmt
    ) {
        Boolean      isCsv = (fmt == FORMAT_CSV);
        List<String> rows  = new List<String>();

        for (Lab_Order__c lo : [
            SELECT Client_ID__c,
                   Partner_Client_Map__r.Partner_Name__c,
                   Name,
                   External_Partner_Order_Id__c,
                   LabRefId__c,
                   Accession_ID__c,
                   Order_Status__c,
                   CreatedDate,
                   Date_of_Collection__c,
                   Date_Reported__c,
                   Expiration_Date__c,
                   Registrant_Name__c,
                   Registrant_Email__c,
                   Partner_Order_Total__c,
                   Refund_Amount__c,
                   Cancellation_Date__c,
                   Cancel_Reason__c,
                   Cancellation_Service_Fee__c,
                   Payment_Transaction_Id__c
            FROM Lab_Order__c
            WHERE Partner_Client_Map__c = :partnerMapId
              AND CreatedDate >= :startDt
              AND CreatedDate < :endDtExclusive
            ORDER BY CreatedDate ASC, Id ASC
        ]) {
            rows.add(isCsv ? orderToCsv(lo) : orderToJson(lo));
        }

        return isCsv
            ? '﻿' + ORDER_CSV_HEADER + '\r\n' + String.join(rows, '\r\n')
            : '[' + String.join(rows, ',') + ']';
    }

    // ── Query + format: test-level (one row per Lab_Panel_Test__c) ────────────

    private static String buildTestResponse(
        Id partnerMapId, Datetime startDt, Datetime endDtExclusive, String fmt
    ) {
        Boolean      isCsv = (fmt == FORMAT_CSV);
        List<String> rows  = new List<String>();

        for (Lab_Panel_Test__c lpt : [
            SELECT Lab_Order_Panel__r.Lab_Order__r.Client_ID__c,
                   Lab_Order_Panel__r.Lab_Order__r.Partner_Client_Map__r.Partner_Name__c,
                   Lab_Order_Panel__r.Lab_Order__r.Name,
                   Lab_Order_Panel__r.Lab_Order__r.External_Partner_Order_Id__c,
                   Lab_Order_Panel__r.Lab_Order__r.LabRefId__c,
                   Lab_Order_Panel__r.Lab_Order__r.Accession_ID__c,
                   Lab_Order_Panel__r.Lab_Order__r.Order_Status__c,
                   Lab_Order_Panel__r.Lab_Order__r.CreatedDate,
                   Lab_Order_Panel__r.Lab_Order__r.Date_of_Collection__c,
                   Lab_Order_Panel__r.Lab_Order__r.Date_Reported__c,
                   Lab_Order_Panel__r.Lab_Order__r.Expiration_Date__c,
                   Lab_Order_Panel__r.Lab_Order__r.Registrant_Name__c,
                   Lab_Order_Panel__r.Lab_Order__r.Registrant_Email__c,
                   Lab_Order_Panel__r.Lab_Order__r.Partner_Order_Total__c,
                   Lab_Order_Panel__r.Lab_Order__r.Refund_Amount__c,
                   Lab_Order_Panel__r.Lab_Order__r.Cancellation_Date__c,
                   Lab_Order_Panel__r.Lab_Order__r.Cancel_Reason__c,
                   Lab_Order_Panel__r.Lab_Order__r.Cancellation_Service_Fee__c,
                   Lab_Order_Panel__r.Lab_Order__r.Payment_Transaction_Id__c,
                   Lab_Order_Panel__r.Panel_Code__c,
                   Lab_Order_Panel__r.Panel__r.Name,
                   Lab_Order_Panel__r.Panel_Price__c,
                   Lab_Order_Panel__r.Panel_Status__c,
                   Test_Code__c,
                   Test_Name__c,
                   Test_Description__c,
                   Status__c
            FROM Lab_Panel_Test__c
            WHERE Lab_Order_Panel__r.Lab_Order__r.Partner_Client_Map__c = :partnerMapId
              AND Lab_Order_Panel__r.Lab_Order__r.CreatedDate >= :startDt
              AND Lab_Order_Panel__r.Lab_Order__r.CreatedDate < :endDtExclusive
            ORDER BY Lab_Order_Panel__r.Lab_Order__r.CreatedDate ASC,
                     Lab_Order_Panel__r.Lab_Order__r.Id ASC
        ]) {
            rows.add(isCsv ? testToCsv(lpt) : testToJson(lpt));
        }

        return isCsv
            ? '﻿' + TEST_CSV_HEADER + '\r\n' + String.join(rows, '\r\n')
            : '[' + String.join(rows, ',') + ']';
    }

    // ── Row formatters ────────────────────────────────────────────────────────

    private static String orderToJson(Lab_Order__c lo) {
        String partnerName = lo.Partner_Client_Map__r != null
            ? lo.Partner_Client_Map__r.Partner_Name__c : null;
        return '{'
            + kv('clientAccountNumber',    lo.Client_ID__c)
            + kv('partnerName',            partnerName)
            + kv('orderId',                lo.Name)
            + kv('externalPartnerOrderId', lo.External_Partner_Order_Id__c)
            + kv('labRefId',               lo.LabRefId__c)
            + kv('accessionId',            lo.Accession_ID__c)
            + kv('orderStatus',            lo.Order_Status__c)
            + kv('dateCreated',            fmtDt(lo.CreatedDate))
            + kv('dateSampleCollected',    fmtD(lo.Date_of_Collection__c))
            + kv('dateReported',           fmtD(lo.Date_Reported__c))
            + kv('nonRefundableDate',      fmtD(lo.Expiration_Date__c))
            + kv('registrantName',         lo.Registrant_Name__c)
            + kv('registrantEmail',        lo.Registrant_Email__c)
            + kv('wholesalePrice',         fmtDec(lo.Partner_Order_Total__c))
            + kv('partnerPrice',           fmtDec(lo.Partner_Order_Total__c))
            + kv('refundAmount',           fmtDec(lo.Refund_Amount__c))
            + kv('cancellationDate',       fmtD(lo.Cancellation_Date__c))
            + kv('cancellationReason',     lo.Cancel_Reason__c)
            + kv('cancellationServiceFee', fmtDec(lo.Cancellation_Service_Fee__c))
            + kvLast('paymentTransactionId', lo.Payment_Transaction_Id__c)
            + '}';
    }

    private static String testToJson(Lab_Panel_Test__c lpt) {
        Lab_Order_Panel__c panel = lpt.Lab_Order_Panel__r;
        Lab_Order__c       lo    = panel != null ? panel.Lab_Order__r          : null;
        PartnerClientMap__c pcm  = lo    != null ? lo.Partner_Client_Map__r    : null;
        String panelName = (panel != null && panel.Panel__r != null) ? panel.Panel__r.Name : null;

        return '{'
            + kv('clientAccountNumber',    lo    != null ? lo.Client_ID__c                          : null)
            + kv('partnerName',            pcm   != null ? pcm.Partner_Name__c                      : null)
            + kv('orderId',                lo    != null ? lo.Name                                  : null)
            + kv('externalPartnerOrderId', lo    != null ? lo.External_Partner_Order_Id__c          : null)
            + kv('labRefId',               lo    != null ? lo.LabRefId__c                           : null)
            + kv('accessionId',            lo    != null ? lo.Accession_ID__c                       : null)
            + kv('orderStatus',            lo    != null ? lo.Order_Status__c                       : null)
            + kv('dateCreated',            lo    != null ? fmtDt(lo.CreatedDate)                    : null)
            + kv('dateSampleCollected',    lo    != null ? fmtD(lo.Date_of_Collection__c)            : null)
            + kv('dateReported',           lo    != null ? fmtD(lo.Date_Reported__c)                : null)
            + kv('nonRefundableDate',      lo    != null ? fmtD(lo.Expiration_Date__c)              : null)
            + kv('registrantName',         lo    != null ? lo.Registrant_Name__c                    : null)
            + kv('registrantEmail',        lo    != null ? lo.Registrant_Email__c                   : null)
            + kv('wholesalePrice',         lo    != null ? fmtDec(lo.Partner_Order_Total__c)        : null)
            + kv('partnerPrice',           lo    != null ? fmtDec(lo.Partner_Order_Total__c)        : null)
            + kv('refundAmount',           lo    != null ? fmtDec(lo.Refund_Amount__c)              : null)
            + kv('cancellationDate',       lo    != null ? fmtD(lo.Cancellation_Date__c)            : null)
            + kv('cancellationReason',     lo    != null ? lo.Cancel_Reason__c                      : null)
            + kv('cancellationServiceFee', lo    != null ? fmtDec(lo.Cancellation_Service_Fee__c)   : null)
            + kv('paymentTransactionId',   lo    != null ? lo.Payment_Transaction_Id__c             : null)
            + kv('panelCode',              panel != null ? panel.Panel_Code__c                      : null)
            + kv('panelName',              panelName)
            + kv('panelPrice',             panel != null ? fmtDec(panel.Panel_Price__c)             : null)
            + kv('panelStatus',            panel != null ? panel.Panel_Status__c                    : null)
            + kv('testCode',               lpt.Test_Code__c)
            + kv('testName',               lpt.Test_Name__c)
            + kv('testDescription',        lpt.Test_Description__c)
            + kvLast('testStatus',         lpt.Status__c)
            + '}';
    }

    private static String orderToCsv(Lab_Order__c lo) {
        String partnerName = lo.Partner_Client_Map__r != null
            ? lo.Partner_Client_Map__r.Partner_Name__c : null;
        return String.join(new List<String>{
            esc(lo.Client_ID__c),
            esc(partnerName),
            esc(lo.Name),
            esc(lo.External_Partner_Order_Id__c),
            esc(lo.LabRefId__c),
            esc(lo.Accession_ID__c),
            esc(lo.Order_Status__c),
            esc(fmtDt(lo.CreatedDate)),
            esc(fmtD(lo.Date_of_Collection__c)),
            esc(fmtD(lo.Date_Reported__c)),
            esc(fmtD(lo.Expiration_Date__c)),
            esc(lo.Registrant_Name__c),
            esc(lo.Registrant_Email__c),
            esc(fmtDec(lo.Partner_Order_Total__c)),
            esc(fmtDec(lo.Partner_Order_Total__c)),
            esc(fmtDec(lo.Refund_Amount__c)),
            esc(fmtD(lo.Cancellation_Date__c)),
            esc(lo.Cancel_Reason__c),
            esc(fmtDec(lo.Cancellation_Service_Fee__c)),
            esc(lo.Payment_Transaction_Id__c)
        }, ',');
    }

    private static String testToCsv(Lab_Panel_Test__c lpt) {
        Lab_Order_Panel__c panel = lpt.Lab_Order_Panel__r;
        Lab_Order__c       lo    = panel != null ? panel.Lab_Order__r          : null;
        PartnerClientMap__c pcm  = lo    != null ? lo.Partner_Client_Map__r    : null;
        String panelName = (panel != null && panel.Panel__r != null) ? panel.Panel__r.Name : null;

        return String.join(new List<String>{
            esc(lo    != null ? lo.Client_ID__c                        : null),
            esc(pcm   != null ? pcm.Partner_Name__c                    : null),
            esc(lo    != null ? lo.Name                                : null),
            esc(lo    != null ? lo.External_Partner_Order_Id__c        : null),
            esc(lo    != null ? lo.LabRefId__c                         : null),
            esc(lo    != null ? lo.Accession_ID__c                     : null),
            esc(lo    != null ? lo.Order_Status__c                     : null),
            esc(lo    != null ? fmtDt(lo.CreatedDate)                  : null),
            esc(lo    != null ? fmtD(lo.Date_of_Collection__c)          : null),
            esc(lo    != null ? fmtD(lo.Date_Reported__c)              : null),
            esc(lo    != null ? fmtD(lo.Expiration_Date__c)            : null),
            esc(lo    != null ? lo.Registrant_Name__c                  : null),
            esc(lo    != null ? lo.Registrant_Email__c                 : null),
            esc(lo    != null ? fmtDec(lo.Partner_Order_Total__c)      : null),
            esc(lo    != null ? fmtDec(lo.Partner_Order_Total__c)      : null),
            esc(lo    != null ? fmtDec(lo.Refund_Amount__c)            : null),
            esc(lo    != null ? fmtD(lo.Cancellation_Date__c)          : null),
            esc(lo    != null ? lo.Cancel_Reason__c                    : null),
            esc(lo    != null ? fmtDec(lo.Cancellation_Service_Fee__c) : null),
            esc(lo    != null ? lo.Payment_Transaction_Id__c           : null),
            esc(panel != null ? panel.Panel_Code__c                    : null),
            esc(panelName),
            esc(panel != null ? fmtDec(panel.Panel_Price__c)           : null),
            esc(panel != null ? panel.Panel_Status__c                  : null),
            esc(lpt.Test_Code__c),
            esc(lpt.Test_Name__c),
            esc(lpt.Test_Description__c),
            esc(lpt.Status__c)
        }, ',');
    }

    // ── Utility helpers ───────────────────────────────────────────────────────

    private static String fmtDt(Datetime dt) {
        return dt != null ? dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') : null;
    }

    private static String fmtD(Date d) {
        return d != null ? String.valueOf(d) : null;
    }

    private static String fmtDec(Decimal d) {
        return d != null ? String.valueOf(d) : null;
    }

    // Adds a key-value pair with trailing comma (all fields except the last)
    private static String kv(String key, String val) {
        String encoded = val != null
            ? '"' + val.replace('\\', '\\\\').replace('"', '\\"') + '"'
            : 'null';
        return '"' + key + '":' + encoded + ',';
    }

    // Last key-value pair in a JSON object — no trailing comma
    private static String kvLast(String key, String val) {
        String encoded = val != null
            ? '"' + val.replace('\\', '\\\\').replace('"', '\\"') + '"'
            : 'null';
        return '"' + key + '":' + encoded;
    }

    // RFC-4180 CSV cell escaping
    private static String esc(String val) {
        if (val == null) return '';
        if (val.contains(',') || val.contains('"') || val.contains('\n') || val.contains('\r')) {
            return '"' + val.replace('"', '""') + '"';
        }
        return val;
    }

    private static void sendError(
        RestResponse res, Integer status, String errorCode, String message
    ) {
        res.statusCode = status;
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf(
            '{"errorCode":"' + errorCode + '","message":"' + message.replace('"', '\\"') + '"}'
        );
    }

    // Audit every call — principal, params, row count, latency; never result data.
    // Replace System.debug with a durable store (custom object / platform event)
    // once Partner_API_Audit_Log__c is deployed per HIPAA retention requirements.
    private static void writeAuditLog(
        String  partnerId,    String startDate, String endDate,
        Boolean includeTests, String fmt,
        Integer rowCount,     Integer statusCode, Long responseTimeMs
    ) {
        try {
            System.debug(LoggingLevel.INFO,
                'PARTNER_API_AUDIT'
                + ' | principal='     + UserInfo.getUserName()
                + ' | partnerId='     + partnerId
                + ' | startDate='     + startDate
                + ' | endDate='       + endDate
                + ' | includeTests='  + includeTests
                + ' | format='        + fmt
                + ' | rowCount='      + rowCount
                + ' | statusCode='    + statusCode
                + ' | responseTimeMs=' + responseTimeMs
            );
        } catch (Exception e) {
            // Audit failure must never break the API response
        }
    }
}
