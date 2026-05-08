@isTest
private class PartnerOrdersRestAPITest {

    @testSetup
    static void setupData() {
        Account account = new Account(Name = 'Partner Orders Test Account');
        insert account;

        Contact contact = new Contact(AccountId = account.Id, LastName = 'Tester');
        insert contact;

        Person_Record__c person = new Person_Record__c(
            First_Name__c        = 'Partner',
            Last_Name__c         = 'Tester',
            Email__c             = 'partner.orders@example.com',
            Address_Line_1__c    = '123 Main St',
            City__c              = 'Secaucus',
            Country__c           = 'USA',
            State__c             = 'NJ',
            Postal_Code__c       = '07094',
            Phone__c             = '1234567890',
            Gender__c            = 'Male',
            Date_of_Birth__c     = Date.newInstance(1990, 1, 1),
            Contact__c           = contact.Id,
            Unique_Identifier__c = 'partner.orders@example.com:1990-01-01:test'
        );
        insert person;

        SalesChannel salesChannel = new SalesChannel(SalesChannelName = 'Partner Orders Test');
        insert salesChannel;

        PartnerClientMap__c partnerMap = new PartnerClientMap__c(
            Name             = 'Test Partner',
            Partner_Name__c  = 'Test Partner',
            Client_ID__c     = 'TP001',
            Sales_Channel__c = salesChannel.Id
        );
        insert partnerMap;

        // Order_Status__c, Partner_Order_Total__c, Registrant_Name__c, Registrant_Email__c
        // are formula / externally-managed fields — not writable via DML
        List<Lab_Order__c> labOrders = new List<Lab_Order__c>{
            new Lab_Order__c(
                Name                      = 'LO-T001',
                Client_Name__c            = 'Test Partner',
                Client_ID__c              = 'TP001',
                Partner_Client_Map__c     = partnerMap.Id,
                Status__c                 = 'Results Ready',
                Payment_Transaction_Id__c = 'TXN-001',
                Person_Record__c          = person.Id,
                Account__c                = account.Id
            ),
            new Lab_Order__c(
                Name                  = 'LO-T002',
                Client_Name__c        = 'Test Partner',
                Client_ID__c          = 'TP001',
                Partner_Client_Map__c = partnerMap.Id,
                Status__c             = 'Registered',
                Person_Record__c      = person.Id,
                Account__c            = account.Id
            )
        };
        insert labOrders;

        Test.setCreatedDate(labOrders[0].Id, DateTime.now().addDays(-5));
        Test.setCreatedDate(labOrders[1].Id, DateTime.now().addDays(-3));

        // Panel_Code__c and Panel_Status__c are not writable — set only writable fields
        Lab_Order_Panel__c panel = new Lab_Order_Panel__c(
            Lab_Order__c   = labOrders[0].Id,
            Panel_Price__c = 49.99
        );
        insert panel;

        // Test_Code__c, Test_Name__c, Test_Description__c are not writable — set only writable fields
        Lab_Panel_Test__c lpt = new Lab_Panel_Test__c(
            Lab_Order_Panel__c = panel.Id,
            Lab_Order__c       = labOrders[0].Id,
            Status__c          = 'Results Ready'
        );
        insert lpt;
    }

    // ── Validation: missing parameters ────────────────────────────────────────

    @isTest
    static void getOrders_missingPartnerId_returns400() {
        setupContext(null, '2026-01-01', '2026-01-15', null, null);
        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        assertError(RestContext.response, 400, 'MISSING_PARAMETER');
    }

    @isTest
    static void getOrders_missingStartDate_returns400() {
        setupContext('TP001', null, '2026-01-15', null, null);
        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        assertError(RestContext.response, 400, 'MISSING_PARAMETER');
    }

    @isTest
    static void getOrders_missingEndDate_returns400() {
        setupContext('TP001', '2026-01-01', null, null, null);
        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        assertError(RestContext.response, 400, 'MISSING_PARAMETER');
    }

    // ── Validation: date errors ───────────────────────────────────────────────

    @isTest
    static void getOrders_invalidStartDateFormat_returns400() {
        setupContext('TP001', 'not-a-date', '2026-01-15', null, null);
        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        assertError(RestContext.response, 400, 'INVALID_DATE');
    }

    @isTest
    static void getOrders_invalidEndDateFormat_returns400() {
        setupContext('TP001', '2026-01-01', 'bad', null, null);
        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        assertError(RestContext.response, 400, 'INVALID_DATE');
    }

    @isTest
    static void getOrders_endDateBeforeStartDate_returns400() {
        setupContext('TP001', '2026-01-15', '2026-01-01', null, null);
        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        assertError(RestContext.response, 400, 'INVALID_DATE_RANGE');
    }

    @isTest
    static void getOrders_dateRangeExceeds31Days_returns400() {
        setupContext('TP001', '2026-01-01', '2026-02-15', null, null);
        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        assertError(RestContext.response, 400, 'DATE_RANGE_TOO_LARGE');
    }

    @isTest
    static void getOrders_sameDayRange_isAllowed() {
        setupContext('TP001', '2026-01-01', '2026-01-01', null, null);
        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    // ── Validation: format and partner ────────────────────────────────────────

    @isTest
    static void getOrders_invalidFormat_returns400() {
        setupContext('TP001', '2026-01-01', '2026-01-15', null, 'xml');
        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        assertError(RestContext.response, 400, 'INVALID_FORMAT');
    }

    @isTest
    static void getOrders_unknownClientId_returns403() {
        setupContext('UNKNOWN-PARTNER-XYZ', '2026-01-01', '2026-01-15', null, null);
        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        assertError(RestContext.response, 403, 'PARTNER_NOT_FOUND');
    }

    @isTest
    static void getOrders_invalidRequestBody_returns400() {
        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/partner/v1/orders';
        req.httpMethod  = 'POST';
        req.requestBody = Blob.valueOf('this is not json');
        req.addHeader('Content-Type', 'application/json');
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        assertError(RestContext.response, 400, 'INVALID_REQUEST_BODY');
    }

    // ── Success: order-level JSON ─────────────────────────────────────────────

    @isTest
    static void getOrders_ordersJson_returns200WithCorrectStructure() {
        String startStr = String.valueOf(Date.today().addDays(-10));
        String endStr   = String.valueOf(Date.today());
        setupContext('TP001', startStr, endStr, null, 'json');

        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        RestResponse res  = RestContext.response;
        String       body = res.responseBody.toString();
        System.assertEquals(200, res.statusCode);
        System.assert(res.headers.get('Content-Type').contains('application/json'),
            'Content-Type must be application/json');
        System.assert(body.startsWith('['),                   'Response must be a JSON array');
        System.assert(body.contains('"orderId"'),             'Must include orderId key');
        System.assert(body.contains('"clientAccountNumber"'), 'Must include clientAccountNumber key');
        System.assert(body.contains('"partnerName"'),         'Must include partnerName key');
        System.assert(body.contains('"dateCreated"'),         'Must include dateCreated key');
        System.assert(body.contains('"wholesalePrice"'),      'Must include wholesalePrice key');
        System.assert(body.contains('"paymentTransactionId"'),'Must include paymentTransactionId key');
        System.assert(body.contains('TP001'),                 'Must include client ID value');
        System.assert(body.contains('LO-T001'),               'Must include order name');
        System.assert(body.contains('Test Partner'),          'Must include partner name');
        System.assert(body.contains('TXN-001'),               'Must include payment transaction ID');
    }

    @isTest
    static void getOrders_defaultFormatIsJson() {
        String startStr = String.valueOf(Date.today().addDays(-10));
        String endStr   = String.valueOf(Date.today());
        setupContext('TP001', startStr, endStr, null, null);

        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        RestResponse res = RestContext.response;
        System.assertEquals(200, res.statusCode);
        System.assert(res.responseBody.toString().startsWith('['),
            'Omitting format must default to JSON array');
    }

    @isTest
    static void getOrders_includeTestsFalse_excludesPanelKeys() {
        String startStr = String.valueOf(Date.today().addDays(-10));
        String endStr   = String.valueOf(Date.today());
        setupContext('TP001', startStr, endStr, false, 'json');

        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        System.assertEquals(200, RestContext.response.statusCode);
        System.assert(!body.contains('"panelCode"'), 'Order-level response must not include panelCode');
        System.assert(!body.contains('"testCode"'),  'Order-level response must not include testCode');
    }

    // ── Success: order-level CSV ──────────────────────────────────────────────

    @isTest
    static void getOrders_ordersCsv_returns200WithHeaderAndData() {
        String startStr = String.valueOf(Date.today().addDays(-10));
        String endStr   = String.valueOf(Date.today());
        setupContext('TP001', startStr, endStr, null, 'csv');

        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        RestResponse res  = RestContext.response;
        String       body = res.responseBody.toString();
        System.assertEquals(200, res.statusCode);
        System.assert(res.headers.get('Content-Type').contains('text/csv'),
            'Content-Type must be text/csv');
        System.assert(body.contains('clientAccountNumber'),   'Must include clientAccountNumber header');
        System.assert(body.contains('orderId'),               'Must include orderId header');
        System.assert(body.contains('paymentTransactionId'),  'Must include paymentTransactionId header');
        System.assert(body.contains('TP001'),                 'Must include client ID value in data row');
        System.assert(body.contains('LO-T001'),               'Must include order name in data row');
        System.assert(body.contains('TXN-001'),               'Must include transaction ID in data row');
    }

    // ── Success: empty results ────────────────────────────────────────────────

    @isTest
    static void getOrders_noOrdersInRange_returns200WithEmptyJsonArray() {
        setupContext('TP001', '2020-01-01', '2020-01-31', null, 'json');

        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        RestResponse res = RestContext.response;
        System.assertEquals(200, res.statusCode);
        System.assertEquals('[]', res.responseBody.toString(),
            'Empty result must return JSON empty array');
    }

    @isTest
    static void getOrders_noOrdersInRange_returns200WithCsvHeaderOnly() {
        setupContext('TP001', '2020-01-01', '2020-01-31', null, 'csv');

        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        RestResponse res  = RestContext.response;
        String       body = res.responseBody.toString();
        System.assertEquals(200, res.statusCode);
        System.assert(body.contains('clientAccountNumber'), 'Must return CSV header for empty result');
        System.assert(!body.contains('LO-T001'), 'Must not include data rows for empty result');
    }

    // ── Success: test-level JSON ──────────────────────────────────────────────

    @isTest
    static void getOrders_includeTestsJson_returns200WithPanelAndTestFields() {
        String startStr = String.valueOf(Date.today().addDays(-10));
        String endStr   = String.valueOf(Date.today());
        setupContext('TP001', startStr, endStr, true, 'json');

        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        RestResponse res  = RestContext.response;
        String       body = res.responseBody.toString();
        System.assertEquals(200, res.statusCode);
        System.assert(body.startsWith('['), 'Response must be a JSON array');
        System.assert(body.contains('"orderId"'),             'Must include orderId key');
        System.assert(body.contains('"clientAccountNumber"'), 'Must include clientAccountNumber key');
        System.assert(body.contains('LO-T001'),               'Must include order name value');
        System.assert(body.contains('"panelCode"'),   'Must include panelCode key');
        System.assert(body.contains('"panelPrice"'),  'Must include panelPrice key');
        System.assert(body.contains('"panelStatus"'), 'Must include panelStatus key');
        System.assert(body.contains('49.99'),         'Must include panel price value');
        System.assert(body.contains('"testCode"'),        'Must include testCode key');
        System.assert(body.contains('"testName"'),        'Must include testName key');
        System.assert(body.contains('"testDescription"'), 'Must include testDescription key');
        System.assert(body.contains('"testStatus"'),      'Must include testStatus key');
        System.assert(body.contains('Results Ready'),     'Must include test status value');
    }

    // ── Success: test-level CSV ───────────────────────────────────────────────

    @isTest
    static void getOrders_includeTestsCsv_returns200WithTestColumns() {
        String startStr = String.valueOf(Date.today().addDays(-10));
        String endStr   = String.valueOf(Date.today());
        setupContext('TP001', startStr, endStr, true, 'csv');

        Test.startTest();
        PartnerOrdersRestAPI.getOrders();
        Test.stopTest();

        RestResponse res  = RestContext.response;
        String       body = res.responseBody.toString();
        System.assertEquals(200, res.statusCode);
        System.assert(res.headers.get('Content-Type').contains('text/csv'),
            'Content-Type must be text/csv');
        System.assert(body.contains('panelCode'),  'Must include panelCode in CSV header');
        System.assert(body.contains('testCode'),   'Must include testCode in CSV header');
        System.assert(body.contains('testStatus'), 'Must include testStatus in CSV header');
        System.assert(body.contains('49.99'),      'Must include panel price value in CSV');
        System.assert(body.contains('Results Ready'), 'Must include test status value in CSV');
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    // Builds a POST body from the supplied params (null values are omitted)
    private static void setupContext(
        String partnerId, String startDate, String endDate,
        Object includeTests, Object format
    ) {
        Map<String, Object> bodyMap = new Map<String, Object>();
        if (partnerId    != null) bodyMap.put('partnerId',    partnerId);
        if (startDate    != null) bodyMap.put('startDate',    startDate);
        if (endDate      != null) bodyMap.put('endDate',      endDate);
        if (includeTests != null) bodyMap.put('includeTests', includeTests);
        if (format       != null) bodyMap.put('format',       format);

        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/partner/v1/orders';
        req.httpMethod  = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(bodyMap));
        req.addHeader('Content-Type', 'application/json');
        RestContext.request  = req;
        RestContext.response = new RestResponse();
    }

    private static void assertError(RestResponse res, Integer expectedStatus, String expectedCode) {
        System.assertEquals(expectedStatus, res.statusCode,
            'Expected HTTP ' + expectedStatus);
        System.assert(res.responseBody.toString().contains(expectedCode),
            'Expected errorCode ' + expectedCode + ' in: ' + res.responseBody.toString());
    }
}
