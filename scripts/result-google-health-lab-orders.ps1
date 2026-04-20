<#
.SYNOPSIS
  Marks Google Health Study lab data as resulted (preprod by default) using Lab_Order_Panel__c -> Lab_Panel_Test__c.

.DESCRIPTION
  Default -BaseUrl is the Quest preprod sandbox; omit -SkipPreprodUrlCheck unless you intentionally target another org.

  Partner realized "tests" / panel rows use Panel_Status__c, which is driven by rollups on Lab_Panel_Test__c
  (not by setting Lab_Order_Panel__c.Status__c alone). This script:

  1) Finds candidate Lab_Order__c rows for the client.
  2) Ensures each order has panels (creates two default panels if none).
  3) For each panel: loads Lab_Panel_Test__c rows; PATCHes each test to Status__c = Results Ready, or if there
     are no tests, POSTs one new Lab_Panel_Test__c with Status__c = Results Ready. Required writeable fields
     on create are filled using GET .../sobjects/Lab_Panel_Test__c/describe (org-specific).
  4) Sets each panel and the parent order to Results Ready and sets Date_Reported__c on the order.

  Requires REST access (integration user) with create/update on Lab_Panel_Test__c, Lab_Order_Panel__c, Lab_Order__c.
#>
[CmdletBinding()]
param(
    [string]$BaseUrl = "https://questdiagnosticscitorg1--preprod.sandbox.my.salesforce.com",
    [string]$ClientName = "GOOGLE_HEALTH_STUDY",
    [int]$OrderLimit = 5,
    [int]$RecentDays = 90,
    [string]$AccessToken,
    [string]$ClientId,
    [string]$ClientSecret,
    [string]$DefaultTestCode = "10231",
    [hashtable]$ExtraLabPanelTestFields,
    [switch]$SkipPreprodUrlCheck,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ApiVersion = "v65.0"
$TestObjectApiName = "Lab_Panel_Test__c"
$ResultTestStatus = "Results Ready"

function Assert-PreprodTarget {
    param([string]$Url, [bool]$Skip)

    if ($Skip) { return }
    if ($Url -notmatch "preprod") {
        throw "Safety check failed. This script defaults to preprod only. Pass -SkipPreprodUrlCheck to run against another org (use with care)."
    }
}

function Get-AccessToken {
    param([string]$Url, [string]$Id, [string]$Secret, [string]$Existing)

    if (-not [string]::IsNullOrWhiteSpace($Existing)) {
        return $Existing
    }
    if ([string]::IsNullOrWhiteSpace($Id) -or [string]::IsNullOrWhiteSpace($Secret)) {
        throw "Provide -AccessToken or both -ClientId and -ClientSecret."
    }

    $tokenResponse = Invoke-RestMethod `
        -Method Post `
        -Uri "$Url/services/oauth2/token" `
        -ContentType "application/x-www-form-urlencoded" `
        -Body @{
            grant_type    = "client_credentials"
            client_id     = $Id
            client_secret = $Secret
        }

    if (-not $tokenResponse.access_token) {
        throw "Failed to retrieve an access token."
    }
    return $tokenResponse.access_token
}

function Invoke-SoqlQuery {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string]$Query
    )

    $encoded = [System.Uri]::EscapeDataString($Query)
    return Invoke-RestMethod `
        -Method Get `
        -Uri "$Base/services/data/$ApiVersion/query?q=$encoded" `
        -Headers $Headers
}

function Get-SObjectDescribe {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string]$SObjectName
    )

    return Invoke-RestMethod `
        -Method Get `
        -Uri "$Base/services/data/$ApiVersion/sobjects/$SObjectName/describe" `
        -Headers $Headers
}

function Test-FieldPropertyTrue {
    param($Field, [string]$Name)
    $p = $Field.PSObject.Properties[$Name]
    if (-not $p) { return $false }
    return [bool]$Field.$Name
}

function Get-FirstActivePicklistValue {
    param($Field, [string]$Preferred)

    $values = @($Field.picklistValues | Where-Object { $_ -and $_.active })
    if ($values.Count -eq 0) { return $null }
    foreach ($v in $values) {
        if ($v.value -eq $Preferred) { return $Preferred }
    }
    return $values[0].value
}

function Build-LabPanelTestCreateBody {
    param(
        [object]$Describe,
        [string]$PanelId,
        [string]$PreferredStatus,
        [string]$DefaultTestCode,
        [hashtable]$ExtraFields
    )

    $body = [ordered]@{
        Lab_Order_Panel__c = $PanelId
        Status__c         = $PreferredStatus
    }

    if ($null -ne $ExtraFields -and $ExtraFields.Count -gt 0) {
        foreach ($key in $ExtraFields.Keys) {
            $body[$key] = $ExtraFields[$key]
        }
    }

    foreach ($f in @($Describe.fields)) {
        if (-not $f.createable) { continue }
        if ($f.name -eq "Id") { continue }
        if (Test-FieldPropertyTrue -Field $f -Name "calculated") { continue }
        if (Test-FieldPropertyTrue -Field $f -Name "autoNumber") { continue }
        if ($f.nillable) { continue }
        if (Test-FieldPropertyTrue -Field $f -Name "defaultedOnCreate") { continue }
        if ($body.Keys -contains $f.name) { continue }

        switch ($f.type) {
            "boolean" { $body[$f.name] = $false }
            "int" { $body[$f.name] = 1 }
            "double" { $body[$f.name] = 1.0 }
            "currency" { $body[$f.name] = 1.0 }
            "percent" { $body[$f.name] = 0 }
            "date" { $body[$f.name] = (Get-Date).ToString("yyyy-MM-dd") }
            "datetime" {
                $body[$f.name] = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
            "email" { $body[$f.name] = "panel-test-seed@example.test" }
            "phone" { $body[$f.name] = "2015550100" }
            "url" { $body[$f.name] = "https://example.test" }
            "picklist" {
                $chosen = Get-FirstActivePicklistValue -Field $f -Preferred $PreferredStatus
                if (-not $chosen) {
                    throw "No active picklist values for required field $($f.name) on $TestObjectApiName."
                }
                $body[$f.name] = $chosen
            }
            "multipicklist" {
                throw "Required multipicklist $($f.name) on $TestObjectApiName is not auto-filled; pass -ExtraLabPanelTestFields."
            }
            "reference" {
                throw ("Required reference field '{0}' on {1} is not set. Add it via -ExtraLabPanelTestFields @{{ '{0}' = '<record Id>' }}." -f $f.name, $TestObjectApiName)
            }
            "string" {
                if ($f.name -match "Code|code|External_Id|external") {
                    $body[$f.name] = $DefaultTestCode
                }
                else {
                    $body[$f.name] = "SEED-{0}" -f [guid]::NewGuid().ToString("N").Substring(0, 8)
                }
            }
            "textarea" { $body[$f.name] = "seed" }
            default {
                $body[$f.name] = "SEED-{0}" -f [guid]::NewGuid().ToString("N").Substring(0, 8)
            }
        }
    }

    $statusField = $Describe.fields | Where-Object { $_.name -eq "Status__c" } | Select-Object -First 1
    if ($statusField) {
        $ok = Get-FirstActivePicklistValue -Field $statusField -Preferred $PreferredStatus
        if ($ok -ne $PreferredStatus) {
            throw ("Status value '{0}' is not an active picklist value on {1}. First active value is '{2}'." -f $PreferredStatus, $TestObjectApiName, $ok)
        }
    }

    return $body
}

function Get-CandidateOrders {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string]$Client,
        [int]$Days,
        [int]$Limit
    )

    $safe = $Client.Replace("'", "\'")
    $query = @"
SELECT Id, Name, Status__c, Date_Reported__c, CreatedDate
FROM Lab_Order__c
WHERE Client_Name__c = '$safe'
AND CreatedDate = LAST_N_DAYS:$Days
AND (Status__c = null OR Status__c != 'Results Ready')
AND (Status__c = null OR Status__c NOT IN ('Cancelled', 'PA Rejected'))
ORDER BY CreatedDate DESC
LIMIT $Limit
"@

    $result = Invoke-SoqlQuery -Base $Base -Headers $Headers -Query $query
    return @($result.records | Where-Object { $_ })
}

function Get-PanelsForOrder {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string]$OrderId
    )

    $safe = $OrderId.Replace("'", "\'")
    $query = "SELECT Id, Status__c FROM Lab_Order_Panel__c WHERE Lab_Order__c = '$safe'"
    $result = Invoke-SoqlQuery -Base $Base -Headers $Headers -Query $query
    return @($result.records | Where-Object { $_ })
}

function Get-TestsForPanel {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string]$PanelId
    )

    $safe = $PanelId.Replace("'", "\'")
    $query = "SELECT Id, Status__c FROM Lab_Panel_Test__c WHERE Lab_Order_Panel__c = '$safe'"
    $result = Invoke-SoqlQuery -Base $Base -Headers $Headers -Query $query
    return @($result.records | Where-Object { $_ })
}

function Add-DefaultResultedPanels {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string]$OrderId
    )

    $panels = @(
        @{ Status__c = "In Progress"; Panel_Price__c = 122.00; Quantity__c = 1 },
        @{ Status__c = "In Progress"; Panel_Price__c = 98.00; Quantity__c = 1 }
    )

    foreach ($panel in $panels) {
        $body = @{
            Lab_Order__c   = $OrderId
            Status__c      = $panel.Status__c
            Quantity__c    = $panel.Quantity__c
            Panel_Price__c = $panel.Panel_Price__c
        }
        Invoke-RestMethod `
            -Method Post `
            -Uri "$Base/services/data/$ApiVersion/sobjects/Lab_Order_Panel__c" `
            -Headers $Headers `
            -ContentType "application/json" `
            -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
    }
}

function Set-PanelResultsReady {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string]$PanelId
    )

    $body = @{ Status__c = $ResultTestStatus }
    Invoke-RestMethod `
        -Method Patch `
        -Uri "$Base/services/data/$ApiVersion/sobjects/Lab_Order_Panel__c/$PanelId" `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
}

function Set-PanelTestResultsReady {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string]$TestId
    )

    $body = @{ Status__c = $ResultTestStatus }
    Invoke-RestMethod `
        -Method Patch `
        -Uri "$Base/services/data/$ApiVersion/sobjects/Lab_Panel_Test__c/$TestId" `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
}

function Add-PanelTestResultsReady {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string]$PanelId,
        [object]$Describe,
        [string]$DefaultTestCode,
        [hashtable]$ExtraFields
    )

    $body = Build-LabPanelTestCreateBody `
        -Describe $Describe `
        -PanelId $PanelId `
        -PreferredStatus $ResultTestStatus `
        -DefaultTestCode $DefaultTestCode `
        -ExtraFields $ExtraFields

    Invoke-RestMethod `
        -Method Post `
        -Uri "$Base/services/data/$ApiVersion/sobjects/Lab_Panel_Test__c" `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body (($body | ConvertTo-Json -Depth 10)) | Out-Null
}

function Sync-PanelTestsToResultsReady {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string]$PanelId,
        [object]$Describe,
        [string]$DefaultTestCode,
        [hashtable]$ExtraFields,
        [bool]$IsDryRun
    )

    if ($IsDryRun) {
        Write-Host ("    [dry-run] Panel {0}: would POST or PATCH Lab_Panel_Test__c so all tests are {1}" -f $PanelId, $ResultTestStatus)
        return
    }

    $tests = Get-TestsForPanel -Base $Base -Headers $Headers -PanelId $PanelId

    if ($tests.Count -eq 0) {
        Write-Host ("    Panel {0}: no Lab_Panel_Test__c rows - creating one with {1}." -f $PanelId, $ResultTestStatus)
        Add-PanelTestResultsReady `
            -Base $Base `
            -Headers $Headers `
            -PanelId $PanelId `
            -Describe $Describe `
            -DefaultTestCode $DefaultTestCode `
            -ExtraFields $ExtraFields
        return
    }

    foreach ($t in $tests) {
        if ($t.Status__c -ne $ResultTestStatus) {
            Write-Host ("    Test {0}: {1} -> {2}" -f $t.Id, $t.Status__c, $ResultTestStatus)
            Set-PanelTestResultsReady -Base $Base -Headers $Headers -TestId $t.Id
        }
    }
}

function Set-OrderResultsReady {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string]$OrderId
    )

    $body = @{
        Status__c         = $ResultTestStatus
        Date_Reported__c = (Get-Date).ToString("yyyy-MM-dd")
    }
    Invoke-RestMethod `
        -Method Patch `
        -Uri "$Base/services/data/$ApiVersion/sobjects/Lab_Order__c/$OrderId" `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
}

Assert-PreprodTarget -Url $BaseUrl -Skip:$SkipPreprodUrlCheck

$token = Get-AccessToken -Url $BaseUrl -Id $ClientId -Secret $ClientSecret -Existing $AccessToken
$headers = @{
    Authorization  = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host "Loading metadata describe for $TestObjectApiName..."
$testDescribe = Get-SObjectDescribe -Base $BaseUrl -Headers $headers -SObjectName $TestObjectApiName

$orders = Get-CandidateOrders -Base $BaseUrl -Headers $headers -Client $ClientName -Days $RecentDays -Limit $OrderLimit

if ($orders.Count -eq 0) {
    Write-Host "No eligible lab orders found for client '$ClientName' in the last $RecentDays days (non-cancelled, not already Results Ready)."
    exit 0
}

Write-Host ("Selected {0} lab order(s) for '{1}'." -f $orders.Count, $ClientName)

foreach ($order in $orders) {
    $panels = Get-PanelsForOrder -Base $BaseUrl -Headers $headers -OrderId $order.Id

    if ($DryRun) {
        Write-Host ("[dry-run] Order {0} ({1}); status={2}; panels={3} -> would add panels if 0; for each panel sync Lab_Panel_Test__c; then set order {4}" -f `
                $order.Id, $order.Name, $order.Status__c, $panels.Count, $ResultTestStatus)
        foreach ($p in $panels) {
            Sync-PanelTestsToResultsReady `
                -Base $BaseUrl `
                -Headers $headers `
                -PanelId $p.Id `
                -Describe $testDescribe `
                -DefaultTestCode $DefaultTestCode `
                -ExtraFields $ExtraLabPanelTestFields `
                -IsDryRun $true
        }
        continue
    }

    try {
        if ($panels.Count -eq 0) {
            Write-Host ("Order {0}: no panels - adding default panels (In Progress); tests will be set to {1}." -f $order.Id, $ResultTestStatus)
            Add-DefaultResultedPanels -Base $BaseUrl -Headers $headers -OrderId $order.Id
            $panels = Get-PanelsForOrder -Base $BaseUrl -Headers $headers -OrderId $order.Id
        }

        foreach ($p in $panels) {
            Sync-PanelTestsToResultsReady `
                -Base $BaseUrl `
                -Headers $headers `
                -PanelId $p.Id `
                -Describe $testDescribe `
                -DefaultTestCode $DefaultTestCode `
                -ExtraFields $ExtraLabPanelTestFields `
                -IsDryRun $false

            if ($p.Status__c -ne $ResultTestStatus) {
                Write-Host ("  Panel {0}: panel Status__c -> {1}" -f $p.Id, $ResultTestStatus)
                Set-PanelResultsReady -Base $BaseUrl -Headers $headers -PanelId $p.Id
            }
        }

        Set-OrderResultsReady -Base $BaseUrl -Headers $headers -OrderId $order.Id
        Write-Host ("Order {0} ({1}): lab panel tests synced; order set to {2} with Date_Reported__c = today." -f $order.Id, $order.Name, $ResultTestStatus)
    }
    catch {
        Write-Warning ("Failed on order {0}: {1}" -f $order.Id, $_.Exception.Message)
    }
}

Write-Host "Done."
