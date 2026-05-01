@isTest
private class PartnerDashboardControllerTest {

    @testSetup
    static void setupData() {

        Account account = new Account(Name = 'Partner Dashboard Account');
        insert account;

        Contact contact = new Contact(AccountId = account.Id, LastName = 'Tester');
        insert contact;

        Person_Record__c person = new Person_Record__c(
            First_Name__c = 'Partner',
            Last_Name__c = 'Tester',
            Email__c = 'partner.dashboard@example.com',
            Address_Line_1__c = '123 Main St',
            City__c = 'Secaucus',
            Country__c = 'USA',
            State__c = 'NJ',
            Postal_Code__c = '07094',
            Phone__c = '1234567890',
            Gender__c = 'Male',
            Date_of_Birth__c = Date.newInstance(1990, 1, 1),
            Contact__c = contact.Id,
            Unique_Identifier__c = 'partner.dashboard@example.com:1990-01-01:test'
        );
        insert person;

        SalesChannel salesChannel = new SalesChannel(SalesChannelName = 'Partner Dashboard');
        insert salesChannel;

        PartnerClientMap__c partnerMap = new PartnerClientMap__c(
            Name = 'HealthFirst Partners',
            Partner_Name__c = 'HealthFirst Partners',
            Client_ID__c = 'P001',
            Sales_Channel__c = salesChannel.Id
        );
        PartnerClientMap__c siblingPartnerMap = new PartnerClientMap__c(
            Name = 'Sibling Health',
            Partner_Name__c = 'Sibling Health',
            Client_ID__c = 'P001',
            Sales_Channel__c = salesChannel.Id
        );
        insert new List<PartnerClientMap__c>{ partnerMap, siblingPartnerMap };

        List<Lab_Order__c> labOrders = new List<Lab_Order__c>{
            new Lab_Order__c(
                Name = 'LO-001',
                Client_Name__c = 'HealthFirst Partners',
                Client_ID__c = 'P001',
                Partner_Client_Map__c = partnerMap.Id,
                Status__c = 'Results Ready',
                Date_Reported__c = Date.today().addDays(-2),
                Person_Record__c = person.Id,
                Account__c = account.Id
            ),
            new Lab_Order__c(
                Name = 'LO-002',
                Client_Name__c = 'HealthFirst Partners',
                Client_ID__c = 'P001',
                Partner_Client_Map__c = partnerMap.Id,
                Status__c = 'PA Approved',
                Person_Record__c = person.Id,
                Account__c = account.Id
            ),
            new Lab_Order__c(
                Name = 'LO-003',
                Client_Name__c = 'HealthFirst Partners',
                Client_ID__c = 'P001',
                Partner_Client_Map__c = partnerMap.Id,
                Status__c = 'Registered',
                Person_Record__c = person.Id,
                Account__c = account.Id
            ),
            new Lab_Order__c(
                Name = 'LO-004',
                Client_Name__c = 'HealthFirst Partners',
                Client_ID__c = 'P001',
                Partner_Client_Map__c = partnerMap.Id,
                Status__c = 'Cancelled',
                Person_Record__c = person.Id,
                Account__c = account.Id
            ),
            new Lab_Order__c(
                Name = 'LO-005',
                Client_Name__c = 'Sibling Health',
                Client_ID__c = 'P001',
                Partner_Client_Map__c = siblingPartnerMap.Id,
                Status__c = 'Registered',
                Person_Record__c = person.Id,
                Account__c = account.Id
            ),
            new Lab_Order__c(
                Name = 'LO-006',
                Client_Name__c = 'HealthFirst Partners',
                Client_ID__c = 'P001',
                Partner_Client_Map__c = partnerMap.Id,
                Status__c = 'Results Ready',
                Date_Reported__c = Date.today().addDays(-1),
                Person_Record__c = person.Id,
                Account__c = account.Id
            )
        };
        insert labOrders;

        insert new List<Lab_Order_Panel__c>{
            new Lab_Order_Panel__c(
                Lab_Order__c = labOrders[0].Id,
                Status__c = 'Results Ready',
                Quantity__c = 1,
                Panel_Price__c = 120
            ),
            new Lab_Order_Panel__c(
                Lab_Order__c = labOrders[5].Id,
                Status__c = 'Results Ready',
                Quantity__c = 1,
                Panel_Price__c = 80
            )
        };

        Test.setCreatedDate(labOrders[0].Id, DateTime.now().addDays(-3));
        Test.setCreatedDate(labOrders[1].Id, DateTime.now().addDays(-2));
        Test.setCreatedDate(labOrders[2].Id, DateTime.now().addDays(-65));
        Test.setCreatedDate(labOrders[3].Id, DateTime.now().addDays(-10));
        Test.setCreatedDate(labOrders[4].Id, DateTime.now().addDays(-20));
        Test.setCreatedDate(labOrders[5].Id, DateTime.now().addDays(-50));
    }

    @isTest
    static void getOverviewSummary_returnsRealizedSameMonthFields() {
        Test.startTest();
        PartnerDashboardController.OverviewSummaryWrapper summary =
            PartnerDashboardController.getOverviewSummary(null, null, null);
        Test.stopTest();

        System.assertNotEquals(null, summary, 'Expected overview aggregate');
        System.assert(summary.realizedRevenueSameMonth >= 0, 'Same-month realized should be non-negative');
        System.assert(
            summary.realizedSameMonthPercentOfRealized >= 0,
            'Same-month % of realized should be non-negative'
        );
    }

    @isTest
    static void getOverviewSummary_realizedUsesCompletionDateWindow() {
        Test.startTest();
        PartnerDashboardController.OverviewSummaryWrapper summary30 =
            PartnerDashboardController.getOverviewSummary('LAST_30_DAYS', null, null);
        PartnerDashboardController.OverviewSummaryWrapper summary90 =
            PartnerDashboardController.getOverviewSummary('LAST_90_DAYS', null, null);
        Test.stopTest();

        System.assert(
            summary30.realizedRevenue >= 0,
            'Realized revenue should remain non-negative when completion dates fall inside the selected window'
        );
        System.assertEquals(
            summary90.realizedRevenue,
            summary30.realizedRevenue,
            'Realized totals should stay stable when completion dates are already inside the smaller window'
        );
    }

    @isTest
    static void getPartnerPerformance_returnsSummaryMetrics() {

        Test.startTest();
        List<PartnerDashboardController.PartnerPerformanceWrapper> results =
            PartnerDashboardController.getPartnerPerformance(null, null, null);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Expected separate summaries for each partner-map record');

        PartnerDashboardController.PartnerPerformanceWrapper summary;
        for (PartnerDashboardController.PartnerPerformanceWrapper result : results) {
            if (result.partnerName == 'HealthFirst Partners') {
                summary = result;
                break;
            }
        }

        System.assertNotEquals(null, summary, 'Expected the primary partner summary to be present');
        System.assertEquals('HealthFirst Partners', summary.partnerName);
        System.assertNotEquals(null, summary.partnerId);
        System.assertEquals('P001', summary.clientId);
        System.assertEquals(3, summary.totalOrders, 'Default behavior should limit results to the last 30 days');
        System.assertEquals(0, summary.cancellationRiskOrders, 'No 45-60 day orders should be included by the default 30-day filter');
        System.assert(summary.completionRate >= 0, 'Completion rate should remain a non-negative derived metric');
    }

    @isTest
    static void getPartnerDetails_returnsDetailMetrics() {

        Id partnerId = [
            SELECT Id
            FROM PartnerClientMap__c
            WHERE Name = 'HealthFirst Partners'
            LIMIT 1
        ].Id;

        Test.startTest();
        PartnerDashboardController.PartnerDetailWrapper detail =
            PartnerDashboardController.getPartnerDetails(partnerId, null, null, null);
        Test.stopTest();

        System.assertNotEquals(null, detail, 'Expected a detail response');
        System.assertEquals('HealthFirst Partners', detail.partnerName);
        System.assertEquals(partnerId, detail.partnerId);
        System.assertEquals('P001', detail.clientId);
        System.assertEquals(3, detail.totalOrders);
        System.assertEquals(3, detail.purchases);
        System.assertEquals(0, detail.cancellationRiskOrders);
        System.assertEquals(0, detail.cancellationRiskPercentOfOrders);
        System.assertEquals(null, detail.averageDistanceToPsc);
        System.assertEquals(null, detail.labCompletionRate);
        System.assert(detail.completionRate >= 0, 'Completion rate should remain a non-negative derived metric');
        System.assert(detail.completedPercent >= 0, 'Completed percent should remain a non-negative derived metric');
    }

    @isTest
    static void getPartnerDetails_appliesDateRangeFilter() {

        Id partnerId = [
            SELECT Id
            FROM PartnerClientMap__c
            WHERE Name = 'HealthFirst Partners'
            LIMIT 1
        ].Id;

        Test.startTest();
        PartnerDashboardController.PartnerDetailWrapper detail =
            PartnerDashboardController.getPartnerDetails(partnerId, 'LAST_30_DAYS', null, null);
        Test.stopTest();

        System.assertEquals(3, detail.totalOrders, 'Only the last 30 days of orders should be counted');
        System.assertEquals(0, detail.cancellationRiskOrders, 'The 50-day order should be excluded by the 30-day filter');
        System.assert(detail.completionRate >= 0, 'Completion rate should remain a non-negative derived metric');
    }

    @isTest
    static void getPartnerDetails_last60DaysIncludesRiskWindowOrder() {

        Id partnerId = [
            SELECT Id
            FROM PartnerClientMap__c
            WHERE Name = 'HealthFirst Partners'
            LIMIT 1
        ].Id;

        Test.startTest();
        PartnerDashboardController.PartnerDetailWrapper detail =
            PartnerDashboardController.getPartnerDetails(partnerId, 'LAST_60_DAYS', null, null);
        Test.stopTest();

        System.assertEquals(4, detail.totalOrders, 'Expected the 50-day risk-window order to be included in the 60-day window');
        System.assertEquals(1, detail.cancellationRiskOrders, 'The 50-day order should now be counted in the shared 45-60 day risk window');
        System.assert(detail.cancellationRiskPercentOfOrders > 24 && detail.cancellationRiskPercentOfOrders < 26, 'One of four orders should fall into the 45-60 day risk bucket');
        System.assert(detail.completionRate >= 0, 'Completion rate should remain a non-negative derived metric');
    }

    @isTest
    static void getPartnerLabOrders_returnsPaginatedOrders() {
        Id partnerId = [
            SELECT Id
            FROM PartnerClientMap__c
            WHERE Name = 'HealthFirst Partners'
            LIMIT 1
        ].Id;

        Test.startTest();
        PartnerDashboardController.PartnerLabOrdersResult result = PartnerDashboardController.getPartnerLabOrders(
            partnerId,
            'LAST_30_DAYS',
            null,
            null,
            PartnerDashboardController.ORDER_FILTER_ALL,
            'createdDate',
            'desc',
            25,
            0
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.orders);
        System.assertEquals(3, result.totalCount, 'Last 30 days should include 3 HealthFirst orders');
        System.assertEquals(3, result.orders.size());
        for (PartnerDashboardController.LabOrderRowWrapper row : result.orders) {
            System.assertNotEquals(null, row.id);
            System.assertNotEquals(null, row.name);
            System.assertNotEquals(null, row.status);
        }
    }

    @isTest
    static void getPartnerLabOrders_nullPartnerReturnsEmpty() {
        Test.startTest();
        PartnerDashboardController.PartnerLabOrdersResult result = PartnerDashboardController.getPartnerLabOrders(
            null,
            'LAST_30_DAYS',
            null,
            null,
            'ALL',
            'createdDate',
            'desc',
            25,
            0
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(0, result.totalCount);
        System.assertEquals(0, result.orders.size());
    }

    @isTest
    static void getInternalLightningBaseUrlForCurrentUser_returnsUrlForStandardUser() {
        System.assertEquals('Standard', UserInfo.getUserType());
        Test.startTest();
        String base = PartnerDashboardController.getInternalLightningBaseUrlForCurrentUser();
        Test.stopTest();
        System.assertNotEquals(null, base, 'Apex test user is Standard; org domain URL should resolve');
        System.assert(!base.endsWith('/'));
    }

    @isTest
    static void searchPartnerProducts_returnsProductMatches() {
        insert new List<Product2>{
            new Product2(
                Name = 'Chickenpox Test',
                ProductCode = 'CPX-100',
                StockKeepingUnit = 'SKU-CPX',
                productId_Ecom__c = 'ECOM-CPX',
                IsActive = true
            ),
            new Product2(
                Name = 'Blood Type Test',
                ProductCode = 'BTT-200',
                StockKeepingUnit = 'SKU-BTT',
                productId_Ecom__c = 'ECOM-BTT',
                IsActive = true
            )
        };

        Test.startTest();
        List<PartnerDashboardController.ProductSearchResultWrapper> results =
            PartnerDashboardController.searchPartnerProducts('CPX');
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected one matching active product');
        System.assertEquals('Chickenpox Test', results[0].name);
        System.assert(results[0].subtitle.contains('Code: CPX-100'));
    }

    @isTest
    static void savePartnerProducts_and_getPartnerProductEditorData_workForCreateAndEdit() {
        PartnerClientMap__c partnerMap = [
            SELECT Id, Name
            FROM PartnerClientMap__c
            WHERE Name = 'HealthFirst Partners'
            LIMIT 1
        ];

        Product2 productOne = new Product2(
            Name = 'Chickenpox Test',
            ProductCode = 'CPX-100',
            StockKeepingUnit = 'SKU-CPX',
            productId_Ecom__c = 'ECOM-CPX',
            IsActive = true
        );
        Product2 productTwo = new Product2(
            Name = 'Blood Type Test',
            ProductCode = 'BTT-200',
            StockKeepingUnit = 'SKU-BTT',
            productId_Ecom__c = 'ECOM-BTT',
            IsActive = true
        );
        insert new List<Product2>{ productOne, productTwo };

        String createJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'productId' => productOne.Id,
                'productPrice' => 56,
                'cancellationFee' => 12
            },
            new Map<String, Object>{
                'productId' => productTwo.Id,
                'productPrice' => 32,
                'cancellationFee' => 6
            }
        });

        Integer insertedCount = PartnerDashboardController.savePartnerProducts(
            partnerMap.Id,
            createJson,
            null
        );

        System.assertEquals(2, insertedCount, 'Expected both partner product rows to be inserted');

        List<Product_Partner_Map__c> insertedMaps = [
            SELECT Id, Product__c, Product_Price__c, Cancellation_Fee__c
            FROM Product_Partner_Map__c
            WHERE Partner_ID__c = :partnerMap.Id
            ORDER BY CreatedDate
        ];
        System.assertEquals(2, insertedMaps.size(), 'Expected two product partner map records');

        PartnerDashboardController.PartnerProductEditorWrapper editorData =
            PartnerDashboardController.getPartnerProductEditorData(partnerMap.Id);

        System.assertNotEquals(null, editorData);
        System.assertEquals(partnerMap.Id, editorData.partnerId);
        System.assertEquals(2, editorData.productMaps.size(), 'Editor data should include both saved maps');

        String updateJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'mapId' => insertedMaps[0].Id,
                'productId' => productOne.Id,
                'productPrice' => 60,
                'cancellationFee' => 15
            }
        });

        Integer updatedCount = PartnerDashboardController.savePartnerProducts(
            partnerMap.Id,
            updateJson,
            JSON.serialize(new List<Id>{ insertedMaps[1].Id })
        );

        System.assertEquals(1, updatedCount, 'Expected one surviving map row to be upserted');

        List<Product_Partner_Map__c> finalMaps = [
            SELECT Id, Product__c, Product_Price__c, Cancellation_Fee__c
            FROM Product_Partner_Map__c
            WHERE Partner_ID__c = :partnerMap.Id
        ];
        System.assertEquals(1, finalMaps.size(), 'Expected one map after delete');
        System.assertEquals(60, finalMaps[0].Product_Price__c);
        System.assertEquals(15, finalMaps[0].Cancellation_Fee__c);
    }

    @isTest
    static void getPartnerOpenOrderAgeingAnalysis_groupsOpenOrdersByStageAndBucket() {
        Account account = new Account(Name = 'Analysis Account');
        insert account;

        Contact contact = new Contact(AccountId = account.Id, LastName = 'Analysis');
        insert contact;

        Person_Record__c person = new Person_Record__c(
            First_Name__c = 'Open',
            Last_Name__c = 'Order',
            Email__c = 'analysis@example.com',
            Address_Line_1__c = '123 Main St',
            City__c = 'Secaucus',
            Country__c = 'USA',
            State__c = 'NJ',
            Postal_Code__c = '07094',
            Phone__c = '1234567890',
            Gender__c = 'Male',
            Date_of_Birth__c = Date.newInstance(1990, 1, 1),
            Contact__c = contact.Id,
            Unique_Identifier__c = 'analysis@example.com:1990-01-01:analysis'
        );
        insert person;

        SalesChannel salesChannel = [SELECT Id FROM SalesChannel LIMIT 1];
        PartnerClientMap__c analysisPartner = new PartnerClientMap__c(
            Name = 'Age Analysis Partner',
            Partner_Name__c = 'Age Analysis Partner',
            Client_ID__c = 'P-ANALYSIS',
            Sales_Channel__c = salesChannel.Id
        );
        insert analysisPartner;

        List<Lab_Order__c> analysisOrders = new List<Lab_Order__c>{
            new Lab_Order__c(
                Name = 'AO-001',
                Client_Name__c = 'Age Analysis Partner',
                Client_ID__c = 'P-ANALYSIS',
                Partner_Client_Map__c = analysisPartner.Id,
                Status__c = 'Registered',
                Person_Record__c = person.Id,
                Account__c = account.Id
            ),
            new Lab_Order__c(
                Name = 'AO-002',
                Client_Name__c = 'Age Analysis Partner',
                Client_ID__c = 'P-ANALYSIS',
                Partner_Client_Map__c = analysisPartner.Id,
                Status__c = 'PA Approved',
                Person_Record__c = person.Id,
                Account__c = account.Id
            ),
            new Lab_Order__c(
                Name = 'AO-003',
                Client_Name__c = 'Age Analysis Partner',
                Client_ID__c = 'P-ANALYSIS',
                Partner_Client_Map__c = analysisPartner.Id,
                Status__c = 'In Progress',
                Person_Record__c = person.Id,
                Account__c = account.Id
            ),
            new Lab_Order__c(
                Name = 'AO-004',
                Client_Name__c = 'Age Analysis Partner',
                Client_ID__c = 'P-ANALYSIS',
                Partner_Client_Map__c = analysisPartner.Id,
                Status__c = 'Partial Results Ready',
                Person_Record__c = person.Id,
                Account__c = account.Id
            )
        };
        insert analysisOrders;

        insert new List<Lab_Order_Panel__c>{
            new Lab_Order_Panel__c(
                Lab_Order__c = analysisOrders[0].Id,
                Status__c = 'Registered',
                Quantity__c = 1,
                Panel_Price__c = 100
            ),
            new Lab_Order_Panel__c(
                Lab_Order__c = analysisOrders[1].Id,
                Status__c = 'Registered',
                Quantity__c = 1,
                Panel_Price__c = 200
            ),
            new Lab_Order_Panel__c(
                Lab_Order__c = analysisOrders[2].Id,
                Status__c = 'In Progress',
                Quantity__c = 1,
                Panel_Price__c = 300
            ),
            new Lab_Order_Panel__c(
                Lab_Order__c = analysisOrders[3].Id,
                Status__c = 'Results Ready',
                Quantity__c = 1,
                Panel_Price__c = 400
            )
        };

        Test.setCreatedDate(analysisOrders[0].Id, DateTime.now().addDays(-2));
        Test.setCreatedDate(analysisOrders[1].Id, DateTime.now().addDays(-5));
        Test.setCreatedDate(analysisOrders[2].Id, DateTime.now().addDays(-10));
        Test.setCreatedDate(analysisOrders[3].Id, DateTime.now().addDays(-20));

        Test.startTest();
        PartnerDashboardController.OpenOrderAgeingAnalysisWrapper analysis =
            PartnerDashboardController.getPartnerOpenOrderAgeingAnalysis(
                analysisPartner.Id,
                'LAST_30_DAYS',
                null,
                null
            );
        Test.stopTest();

        System.assertNotEquals(null, analysis);
        System.assertEquals(4, analysis.totalOpenOrders, 'Expected four open orders to be grouped into stage buckets');
        System.assertEquals(2, analysis.atRiskOrdersCount, 'Orders older than 6 days should count as at-risk for analysis');
        System.assertEquals(2, analysis.rows.size(), 'Expected pre and post sample collection rows');

        PartnerDashboardController.OpenOrderAgeingAnalysisRowWrapper preStage = analysis.rows[0];
        PartnerDashboardController.OpenOrderAgeingAnalysisRowWrapper postStage = analysis.rows[1];

        System.assertEquals('Pre sample collection', preStage.status);
        System.assertEquals('Post sample collection', postStage.status);
        System.assertEquals(4, analysis.totalRow.totalCount);
        System.assertEquals(1, analysis.totalRow.lt3Count);
        System.assertEquals(1, analysis.totalRow.d3to6Count);
        System.assertEquals(1, analysis.totalRow.d7to15Count);
        System.assertEquals(1, analysis.totalRow.d15to30Count);
        System.assertEquals(
            analysis.totalRow.totalCount,
            preStage.totalCount + postStage.totalCount,
            'Total row count should equal the sum of stage rows'
        );
    }

    @isTest
    static void getPartnerOpenOrdersAgeingDrill_returnsFilteredRows() {
        Id partnerId = [
            SELECT Id
            FROM PartnerClientMap__c
            WHERE Name = 'HealthFirst Partners'
            LIMIT 1
        ].Id;

        Test.startTest();
        PartnerDashboardController.PartnerLabOrdersResult allOpen =
            PartnerDashboardController.getPartnerOpenOrdersAgeingDrill(
                partnerId,
                'LAST_90_DAYS',
                null,
                null,
                PartnerDashboardController.OPEN_AGEING_STAGE_TOTAL,
                PartnerDashboardController.OPEN_AGEING_BUCKET_ALL_OPEN,
                'createdDate',
                'desc',
                50,
                0
            );
        PartnerDashboardController.PartnerLabOrdersResult atRisk =
            PartnerDashboardController.getPartnerOpenOrdersAgeingDrill(
                partnerId,
                'LAST_90_DAYS',
                null,
                null,
                PartnerDashboardController.OPEN_AGEING_STAGE_TOTAL,
                PartnerDashboardController.OPEN_AGEING_BUCKET_AT_RISK_GT6,
                'createdDate',
                'desc',
                50,
                0
            );
        Test.stopTest();

        System.assert(allOpen.totalCount >= atRisk.totalCount, 'All open should include at least the at-risk subset');
        System.assert(atRisk.totalCount >= 0, 'At-risk drill should return a non-negative count');
    }

    @isTest
    static void partnerLabOrders_filtersAndExports_coverAdditionalPaths() {
        Id partnerId = [
            SELECT Id
            FROM PartnerClientMap__c
            WHERE Name = 'HealthFirst Partners'
            LIMIT 1
        ].Id;

        Account account = new Account(Name = 'Order Filter Account');
        insert account;

        Contact contact = new Contact(AccountId = account.Id, LastName = 'Filters');
        insert contact;

        Person_Record__c person = new Person_Record__c(
            First_Name__c = 'Filter',
            Last_Name__c = 'Tester',
            Email__c = 'filters@example.com',
            Address_Line_1__c = '123 Main St',
            City__c = 'Secaucus',
            Country__c = 'USA',
            State__c = 'NJ',
            Postal_Code__c = '07094',
            Phone__c = '1234567890',
            Gender__c = 'Male',
            Date_of_Birth__c = Date.newInstance(1990, 1, 1),
            Contact__c = contact.Id,
            Unique_Identifier__c = 'filters@example.com:1990-01-01:filters'
        );
        insert person;

        Lab_Order__c atRiskOrder = new Lab_Order__c(
            Name = 'LO-RISK',
            Client_Name__c = 'HealthFirst Partners',
            Client_ID__c = 'P001',
            Partner_Client_Map__c = partnerId,
            Status__c = 'PA Approved',
            Person_Record__c = person.Id,
            Account__c = account.Id
        );
        insert atRiskOrder;

        Test.setCreatedDate(atRiskOrder.Id, DateTime.now().addDays(-50));

        Test.startTest();
        PartnerDashboardController.PartnerLabOrdersResult realizedResult = PartnerDashboardController.getPartnerLabOrders(
            partnerId,
            'LAST_90_DAYS',
            null,
            null,
            PartnerDashboardController.ORDER_FILTER_REALIZED,
            'createdDate',
            'desc',
            25,
            0
        );
        PartnerDashboardController.PartnerLabOrdersResult cancelledResult = PartnerDashboardController.getPartnerLabOrders(
            partnerId,
            'LAST_90_DAYS',
            null,
            null,
            PartnerDashboardController.ORDER_FILTER_CANCELLED,
            'createdDate',
            'desc',
            25,
            0
        );
        PartnerDashboardController.PartnerLabOrdersResult atRiskResult = PartnerDashboardController.getPartnerLabOrders(
            partnerId,
            'LAST_90_DAYS',
            null,
            null,
            PartnerDashboardController.ORDER_FILTER_AT_RISK,
            'mor',
            'asc',
            25,
            0
        );
        List<PartnerDashboardController.LabOrderRowWrapper> atRiskExportRows =
            PartnerDashboardController.getPartnerLabOrdersForExport(
                partnerId,
                'LAST_90_DAYS',
                null,
                null,
                PartnerDashboardController.ORDER_FILTER_AT_RISK,
                'createdDate',
                'desc'
            );
        String contentVersionId = PartnerDashboardController.createPartnerLabOrdersExportFile(
            'partner-orders-export',
            '<Workbook>test</Workbook>'
        );
        Test.stopTest();

        System.assertNotEquals(null, realizedResult, 'Expected a realized-order result payload');
        System.assertEquals(
            realizedResult.totalCount,
            realizedResult.orders.size(),
            'Realized result rows should align with the returned total for this small test dataset'
        );
        System.assertEquals(0, cancelledResult.totalCount, 'Cancelled filter should safely return zero when no cancellation date exists');
        System.assert(atRiskResult.totalCount >= 1, 'Expected at least one open order in the 45-60 day at-risk window');
        System.assertEquals(atRiskResult.totalCount, atRiskExportRows.size(), 'At-risk export should return the same scoped order set');
        System.assertNotEquals(null, contentVersionId, 'Expected an export file to be created');

        ContentVersion exportVersion = [
            SELECT Id, Title, PathOnClient
            FROM ContentVersion
            WHERE Id = :contentVersionId
            LIMIT 1
        ];
        System.assertEquals('partner-orders-export', exportVersion.Title);
        System.assertEquals('/partner-orders-export.xml', exportVersion.PathOnClient);
    }

    @isTest
    static void getPartnerRealized_sortBranches_executeWithoutError() {
        Id partnerId = [
            SELECT Id
            FROM PartnerClientMap__c
            WHERE Name = 'HealthFirst Partners'
            LIMIT 1
        ].Id;

        List<String> panelSortFields = new List<String>{
            'labOrderName',
            'labOrderId',
            'externalPartnerOrderId',
            'labRefId',
            'accessionId',
            'orderCreatedDate',
            'dateSampleCollected',
            'dateResulted',
            'createdDate',
            'nonRefundableDate',
            'registrantName',
            'performingSite',
            'panelCode',
            'panelName',
            'panelPrice',
            'panelStatus',
            'amount',
            'mor'
        };
        List<String> summarySortFields = new List<String>{
            'panelCode',
            'panelName',
            'quantity',
            'panelPrice',
            'totalAmount'
        };
        List<String> realizedOrderSortFields = new List<String>{
            'orderCreatedDate',
            'dateSampleCollected',
            'dateResulted',
            'nonRefundableDate',
            'clientAccountNumber',
            'partnerName',
            'labOrderId',
            'externalPartnerOrderId',
            'labRefId',
            'accessionId',
            'registrantName',
            'performingSite',
            'name',
            'amount',
            'status',
            'mor'
        };

        Test.startTest();
        for (String sortBy : panelSortFields) {
            PartnerDashboardController.getPartnerRealizedLabOrderPanels(
                partnerId,
                'LAST_90_DAYS',
                null,
                null,
                sortBy,
                'asc',
                5,
                0
            );
        }
        for (String sortBy : summarySortFields) {
            PartnerDashboardController.getPartnerRealizedTestSummary(
                partnerId,
                'LAST_90_DAYS',
                null,
                null,
                sortBy,
                'desc',
                5,
                0
            );
        }
        for (String sortBy : realizedOrderSortFields) {
            PartnerDashboardController.getPartnerLabOrders(
                partnerId,
                'LAST_90_DAYS',
                null,
                null,
                PartnerDashboardController.ORDER_FILTER_REALIZED,
                sortBy,
                'asc',
                5,
                0
            );
        }
        PartnerDashboardController.getPartnerLabOrdersForExport(
            partnerId,
            'LAST_90_DAYS',
            null,
            null,
            PartnerDashboardController.ORDER_FILTER_REALIZED,
            'cancellationReason',
            'asc'
        );
        PartnerDashboardController.getPartnerRealizedLabOrderPanels(
            partnerId,
            'LAST_90_DAYS',
            null,
            null,
            'dateResulted',
            'desc',
            1,
            5
        );
        PartnerDashboardController.getPartnerRealizedTestSummary(
            partnerId,
            'LAST_90_DAYS',
            null,
            null,
            'panelCode',
            'asc',
            1,
            1
        );
        Test.stopTest();
    }

    @isTest
    static void getPartnerRealizedPanelsAndSummary_nullPartnerReturnsEmpty() {
        Test.startTest();
        PartnerDashboardController.PartnerRealizedPanelRowsResult panels =
            PartnerDashboardController.getPartnerRealizedLabOrderPanels(
                null,
                'LAST_30_DAYS',
                null,
                null,
                'dateResulted',
                'desc',
                10,
                0
            );
        List<PartnerDashboardController.RealizedPanelRowWrapper> panelExport =
            PartnerDashboardController.getPartnerRealizedLabOrderPanelsForExport(
                null,
                'LAST_30_DAYS',
                null,
                null,
                'dateResulted',
                'desc'
            );
        PartnerDashboardController.PartnerRealizedSummaryResult summary =
            PartnerDashboardController.getPartnerRealizedTestSummary(
                null,
                'LAST_30_DAYS',
                null,
                null,
                'panelCode',
                'asc',
                10,
                0
            );
        PartnerDashboardController.PartnerRealizedSummaryResult summaryExport =
            PartnerDashboardController.getPartnerRealizedTestSummaryForExport(
                null,
                'LAST_30_DAYS',
                null,
                null,
                'panelCode',
                'asc'
            );
        Test.stopTest();

        System.assertEquals(0, panels.totalCount);
        System.assertEquals(0, panelExport.size());
        System.assertEquals(0, summary.totalCount);
        System.assertEquals(0, summaryExport.totalCount);
    }

    @isTest
    static void getPartnerRealized_exportsReturnConsistentPayload() {
        Id partnerId = [
            SELECT Id
            FROM PartnerClientMap__c
            WHERE Name = 'HealthFirst Partners'
            LIMIT 1
        ].Id;

        Test.startTest();
        List<PartnerDashboardController.RealizedPanelRowWrapper> panelExportRows =
            PartnerDashboardController.getPartnerRealizedLabOrderPanelsForExport(
                partnerId,
                'LAST_90_DAYS',
                null,
                null,
                'panelName',
                'asc'
            );
        PartnerDashboardController.PartnerRealizedSummaryResult summaryExport =
            PartnerDashboardController.getPartnerRealizedTestSummaryForExport(
                partnerId,
                'LAST_90_DAYS',
                null,
                null,
                'totalAmount',
                'desc'
            );
        Test.stopTest();

        System.assertNotEquals(null, panelExportRows);
        System.assertNotEquals(null, summaryExport.rows);
    }

    @isTest
    static void getPartnerRealizedPanelsAndSummary_returnDataInWindow() {
        Id partnerId = [
            SELECT Id
            FROM PartnerClientMap__c
            WHERE Name = 'HealthFirst Partners'
            LIMIT 1
        ].Id;

        Test.startTest();
        PartnerDashboardController.PartnerRealizedPanelRowsResult panels =
            PartnerDashboardController.getPartnerRealizedLabOrderPanels(
                partnerId,
                'LAST_90_DAYS',
                null,
                null,
                'dateResulted',
                'desc',
                50,
                0
            );
        PartnerDashboardController.PartnerRealizedSummaryResult summary =
            PartnerDashboardController.getPartnerRealizedTestSummary(
                partnerId,
                'LAST_90_DAYS',
                null,
                null,
                'panelCode',
                'asc',
                50,
                0
            );
        Test.stopTest();

        Date startDateValue = Date.today().addDays(-90);
        Date endDateValue = Date.today();
        Integer expectedPanelCount = [
            SELECT COUNT()
            FROM Lab_Order_Panel__c
            WHERE
                Lab_Order__r.Partner_Client_Map__c = :partnerId
                AND Lab_Order__r.Status__c IN ('Results Ready', 'Expired')
                AND Lab_Order__r.Date_Reported__c >= :startDateValue
                AND Lab_Order__r.Date_Reported__c <= :endDateValue
        ];

        System.assertNotEquals(null, panels.rows, 'Expected a panel row list');
        System.assertEquals(
            expectedPanelCount,
            panels.totalCount,
            'Panel drill query should match the same scope as a plain SOQL count'
        );
        System.assertNotEquals(null, summary.rows, 'Expected a summary row list');
        if (expectedPanelCount == 0) {
            System.assertEquals(0, summary.totalCount, 'Summary should be empty when no panel lines qualify');
            System.assertEquals(0, summary.grandTotalQuantity, 'Grand totals should be zero when no lines qualify');
        } else {
            System.assert(summary.totalCount >= 1, 'Expected at least one aggregated panel code');
            System.assert(summary.grandTotalQuantity >= 1, 'Grand total quantity should reflect panel quantities');
        }
    }

    @isTest
    static void helperMethods_returnExpectedDefaultsAndErrors() {
        System.assertEquals(
            0,
            PartnerDashboardController.searchPartnerProducts('x').size(),
            'Single-character searches should return no results'
        );
        System.assertEquals(
            null,
            PartnerDashboardController.getPartnerProductEditorData(null),
            'Null partner ids should return no editor data'
        );

        PartnerDashboardController.OpenOrderAgeingAnalysisWrapper emptyAnalysis =
            PartnerDashboardController.getPartnerOpenOrderAgeingAnalysis(null, 'LAST_30_DAYS', null, null);
        System.assertEquals(0, emptyAnalysis.totalOpenOrders);
        System.assertEquals(
            null,
            PartnerDashboardController.createPartnerLabOrdersExportFile('ignored', null),
            'Blank content should not create an export file'
        );

        try {
            PartnerDashboardController.savePartnerProducts(null, '[]', null);
            System.assert(false, 'Expected missing-partner save to throw');
        } catch (AuraHandledException ex) {
            System.assertNotEquals(null, ex, 'Expected an AuraHandledException for missing partner');
        }
    }
}