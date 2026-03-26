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
                Status__c = 'Registered',
                Person_Record__c = person.Id,
                Account__c = account.Id
            )
        };
        insert labOrders;

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
}