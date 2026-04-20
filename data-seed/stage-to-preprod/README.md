# Stage to Preprod Seed Plan

This folder contains read-only exports taken from the `stage` org for seeding `preprod`.

Important guardrails:

- `stage` was used in read-only mode only.
- No deploys, inserts, updates, deletes, upserts, or anonymous Apex were run against `stage`.
- No data has been inserted into `preprod` yet from this seed set.

## Exported Files

Full extracts:

- `PartnerClientMap__c.csv` - 14 partner records from `stage`
- `Lab_Order__c.csv` - 334 lab order records from `stage`

Focused dashboard seed extracts:

- `PartnerClientMap__c.focused.csv` - 4 partner records actually referenced by lab orders with `Partner_Client_Map__c`
- `Lab_Order__c.focused.csv` - 95 lab orders with a non-null `Partner_Client_Map__c`

## Focused Partner Set

The dashboard-relevant partner records currently referenced by mapped lab orders are:

- `APPLE_HEALTH` (`Client_ID__c = 73949611`)
- `GOOGLE_HEALTH_STUDY` (`Client_ID__c = 73949616`)
- `saturn` (`Client_ID__c = 73942126`)
- `WEIGHT_WATCHERS` (`Client_ID__c = 73949620`)

## Key Findings

- `stage` counts:
  - `PartnerClientMap__c = 14`
  - `Lab_Order__c = 334`
- `preprod` counts:
  - `PartnerClientMap__c = 0`
  - `Lab_Order__c = 0`
- `239 / 334` lab orders in `stage` have `Partner_Client_Map__c = null`
- `95 / 334` lab orders in `stage` are mapped to a partner and are the best first seed set for the dashboard
- `Client_ID__c` is not unique across all partner records, so it should not be used alone as a remap key for the full extract

## Recommended Load Order

1. Load `PartnerClientMap__c.focused.csv` into `preprod`
2. Query inserted `PartnerClientMap__c` records in `preprod` and build an old-id to new-id remap using the exported source `Id`
3. Transform `Lab_Order__c.focused.csv` so `Partner_Client_Map__c` points to the new `preprod` partner ids
4. Load transformed lab orders into `preprod`

## Main Technical Risk

The dashboard logic uses `CreatedDate` for:

- overview date windows
- partner detail date windows
- ageing calculations
- at-risk windows

If `preprod` does not allow setting audit fields on insert, imported `Lab_Order__c` records will receive new `CreatedDate` values, which will distort dashboard behavior.

Before loading, verify whether `preprod` supports audit field preservation for this operation.

## Suggested Next Step

Before any insert:

1. confirm whether we want to use the focused dataset or the full dataset
2. confirm whether `CreatedDate` can be preserved in `preprod`
3. prepare the partner id remap file for `Lab_Order__c`
