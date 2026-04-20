[CmdletBinding()]
param(
    [ValidateSet("create", "enrich-existing", "create-and-enrich")]
    [string]$Mode = "create-and-enrich",
    [string]$BaseUrl = "https://questdiagnosticscitorg1--preprod.sandbox.my.salesforce.com",
    [int]$Count = 100,
    [string[]]$ClientNames = @("WEIGHT_WATCHERS", "APPLE_HEALTH", "GOOGLE_HEALTH_STUDY", "saturn"),
    [ValidateSet("Registered", "PA Approved", "In Progress", "Partial Results Ready", "Results Ready", "Cancelled")]
    [string]$ForcedStatus,
    [string]$AccessToken,
    [string]$ClientId,
    [string]$ClientSecret,
    [int]$DelayMs = 0,
    [int]$RecentHours = 24
)

$ErrorActionPreference = "Stop"
$ApiVersion = "v65.0"

function Assert-PreprodTarget {
    param([string]$Url)

    if ($Url -notmatch "preprod") {
        throw "Safety check failed. This script only runs against preprod URLs."
    }
}

function Get-PreprodAccessToken {
    param(
        [string]$Url,
        [string]$Id,
        [string]$Secret
    )

    if ([string]::IsNullOrWhiteSpace($Id) -or [string]::IsNullOrWhiteSpace($Secret)) {
        throw "Either provide -AccessToken or both -ClientId and -ClientSecret."
    }

    $tokenResponse = Invoke-RestMethod `
        -Method Post `
        -Uri "$Url/services/oauth2/token" `
        -ContentType "application/x-www-form-urlencoded" `
        -Body @{
            grant_type = "client_credentials"
            client_id = $Id
            client_secret = $Secret
        }

    if (-not $tokenResponse.access_token) {
        throw "Failed to retrieve an access token."
    }

    return $tokenResponse.access_token
}

function Invoke-SfRestJson {
    param(
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers,
        [object]$Body
    )

    $params = @{
        Method = $Method
        Uri = $Url
        Headers = $Headers
    }

    if ($PSBoundParameters.ContainsKey("Body") -and $null -ne $Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 15)
    }

    return Invoke-RestMethod @params
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

function New-RandomPhone {
    return "8615{0:000000}" -f (Get-Random -Minimum 0 -Maximum 999999)
}

function New-RandomPid {
    $chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".ToCharArray()
    return -join (1..10 | ForEach-Object { $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)] })
}

function New-RandomDateOfBirth {
    $start = Get-Date "1940-01-01"
    $end = Get-Date "2000-12-31"
    $range = ($end - $start).Days
    return $start.AddDays((Get-Random -Minimum 0 -Maximum $range)).ToString("yyyy-MM-dd")
}

function Get-PartnerMapByName {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string[]]$Names
    )

    $quoted = $Names | ForEach-Object { "'{0}'" -f $_.Replace("'", "\'") }
    $query = @"
SELECT Id, Name, Partner_Name__c, Client_ID__c
FROM PartnerClientMap__c
WHERE Name IN ($($quoted -join ','))
"@

    $result = Invoke-SoqlQuery -Base $Base -Headers $Headers -Query $query
    $map = @{}

    foreach ($record in ($result.records | Where-Object { $_ })) {
        $map[$record.Name] = $record
    }

    return $map
}

function New-SeedPayload {
    param(
        [int]$Index,
        [string]$ClientName
    )

    $firstNames = @("Roland", "Ava", "Mason", "Liam", "Noah", "Emma", "Olivia", "Lucas", "Mia", "Ella")
    $lastNames = @("Patton", "Carter", "Brooks", "Foster", "Perry", "Hayes", "Reed", "Watson", "Price", "Cole")
    $cities = @(
        @{ city = "Silverlake"; state = "WA"; zip = "98645" },
        @{ city = "Tampa"; state = "FL"; zip = "33602" },
        @{ city = "Austin"; state = "TX"; zip = "78701" },
        @{ city = "Denver"; state = "CO"; zip = "80202" },
        @{ city = "Phoenix"; state = "AZ"; zip = "85004" }
    )
    $testBundles = @(
        @(
            @{ finalPrice = "120"; testCode = "10231"; quantity = 1 },
            @{ finalPrice = "100"; testCode = "17306"; quantity = 1 }
        ),
        @(
            @{ finalPrice = "85"; testCode = "17306"; quantity = 1 }
        ),
        @(
            @{ finalPrice = "160"; testCode = "10231"; quantity = 1 },
            @{ finalPrice = "95"; testCode = "17306"; quantity = 1 }
        )
    )

    $firstName = $firstNames[(Get-Random -Minimum 0 -Maximum $firstNames.Length)]
    $lastName = $lastNames[(Get-Random -Minimum 0 -Maximum $lastNames.Length)]
    $location = $cities[(Get-Random -Minimum 0 -Maximum $cities.Length)]
    $items = $testBundles[(Get-Random -Minimum 0 -Maximum $testBundles.Length)]
    $suffix = "{0:0000}" -f $Index
    $externalOrderId = [guid]::NewGuid().Guid
    $labOrderNumber = [guid]::NewGuid().Guid

    return @{
        request = @{
            orderSummaries = @{
                orderItems = $items
            }
            externalOrderId = $externalOrderId
            address = @{
                zip = $location.zip
                addressLine1 = "68 E James St Apt $suffix"
                country = "US"
                state = $location.state
                city = $location.city
            }
            locationId = "PHP"
            customer = @{
                firstName = $firstName
                lastName = $lastName
                gender = @("Male", "Female")[(Get-Random -Minimum 0 -Maximum 2)]
                phone = New-RandomPhone
                shippingAddress = @{
                    zip = $location.zip
                    addressLine1 = "68 E James St Apt $suffix"
                    country = "US"
                    state = $location.state
                    city = $location.city
                }
                dateOfBirth = New-RandomDateOfBirth
                pid = New-RandomPid
                email = ("{0}.{1}.{2}@quest.msdc.co" -f $firstName.ToLower(), $lastName.ToLower(), $suffix)
            }
            labOrderNumber = $labOrderNumber
            clientName = $ClientName
        }
        externalOrderId = $externalOrderId
        labOrderNumber = $labOrderNumber
    }
}

function Get-LabOrderByExternalId {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string]$ExternalOrderId
    )

    $safeId = $ExternalOrderId.Replace("'", "\'")
    $query = @"
SELECT Id, Name, Status__c, Date_Reported__c, External_Partner_Order_Id__c, Partner_Client_Map__c, Client_Name__c
FROM Lab_Order__c
WHERE External_Partner_Order_Id__c = '$safeId'
ORDER BY CreatedDate DESC
LIMIT 1
"@

    $result = Invoke-SoqlQuery -Base $Base -Headers $Headers -Query $query
    return ($result.records | Select-Object -First 1)
}

function Get-RecentLabOrders {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [int]$Hours,
        [string[]]$Names
    )

    $daysBack = [Math]::Max(1, [Math]::Ceiling($Hours / 24))
    $quoted = $Names | ForEach-Object { "'{0}'" -f $_.Replace("'", "\'") }
    $query = @"
SELECT Id, Name, Status__c, Date_Reported__c, External_Partner_Order_Id__c, Partner_Client_Map__c, Client_Name__c, CreatedDate
FROM Lab_Order__c
WHERE Client_Name__c IN ($($quoted -join ','))
AND CreatedDate = LAST_N_DAYS:$daysBack
ORDER BY CreatedDate DESC
LIMIT 500
"@

    $result = Invoke-SoqlQuery -Base $Base -Headers $Headers -Query $query
    return @($result.records)
}

function Get-PanelCountByOrderId {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string[]]$OrderIds
    )

    if (-not $OrderIds -or $OrderIds.Count -eq 0) {
        return @{}
    }

    $quoted = $OrderIds | ForEach-Object { "'$_'" }
    $query = @"
SELECT Lab_Order__c orderId, COUNT(Id) panelCount
FROM Lab_Order_Panel__c
WHERE Lab_Order__c IN ($($quoted -join ','))
GROUP BY Lab_Order__c
"@

    $result = Invoke-SoqlQuery -Base $Base -Headers $Headers -Query $query
    $counts = @{}

    foreach ($row in ($result.records | Where-Object { $_ })) {
        $counts[$row.orderId] = [int]$row.panelCount
    }

    return $counts
}

function Get-StatusForIndex {
    param([int]$Index)

    switch ($Index % 12) {
        0 { return "Results Ready" }
        1 { return "PA Approved" }
        2 { return "In Progress" }
        3 { return "Partial Results Ready" }
        4 { return "Cancelled" }
        default { return "Registered" }
    }
}

function Get-PanelDefinitions {
    param([string]$TargetStatus)

    switch ($TargetStatus) {
        "Results Ready" {
            return @(
                @{ Status__c = "Results Ready"; Panel_Price__c = 122.00; Quantity__c = 1 },
                @{ Status__c = "Results Ready"; Panel_Price__c = 98.00; Quantity__c = 1 }
            )
        }
        "Partial Results Ready" {
            return @(
                @{ Status__c = "Results Ready"; Panel_Price__c = 122.00; Quantity__c = 1 },
                @{ Status__c = "In Progress"; Panel_Price__c = 78.00; Quantity__c = 1 }
            )
        }
        "In Progress" {
            return @(
                @{ Status__c = "In Progress"; Panel_Price__c = 110.00; Quantity__c = 1 },
                @{ Status__c = "In Progress"; Panel_Price__c = 90.00; Quantity__c = 1 }
            )
        }
        "PA Approved" {
            return @(
                @{ Status__c = "Registered"; Panel_Price__c = 115.00; Quantity__c = 1 },
                @{ Status__c = "Registered"; Panel_Price__c = 85.00; Quantity__c = 1 }
            )
        }
        "Cancelled" {
            return @(
                @{ Status__c = "Registered"; Panel_Price__c = 120.00; Quantity__c = 1 },
                @{ Status__c = "Registered"; Panel_Price__c = 95.00; Quantity__c = 1 }
            )
        }
        default {
            return @(
                @{ Status__c = "Registered"; Panel_Price__c = 120.00; Quantity__c = 1 },
                @{ Status__c = "Registered"; Panel_Price__c = 100.00; Quantity__c = 1 }
            )
        }
    }
}

function Add-PanelsToOrder {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string]$OrderId,
        [string]$TargetStatus
    )

    $panels = Get-PanelDefinitions -TargetStatus $TargetStatus

    foreach ($panel in $panels) {
        $body = @{
            Lab_Order__c = $OrderId
            Status__c = $panel.Status__c
            Quantity__c = $panel.Quantity__c
            Panel_Price__c = $panel.Panel_Price__c
        }

        Invoke-SfRestJson `
            -Method Post `
            -Url "$Base/services/data/$ApiVersion/sobjects/Lab_Order_Panel__c" `
            -Headers $Headers `
            -Body $body | Out-Null
    }
}

function Update-LabOrderStatus {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [string]$OrderId,
        [string]$TargetStatus
    )

    $body = @{
        Status__c = $TargetStatus
    }

    if ($TargetStatus -in @("Results Ready", "Partial Results Ready")) {
        $body.Date_Reported__c = (Get-Date).ToString("yyyy-MM-dd")
    }

    if ($TargetStatus -eq "Cancelled") {
        $body.Cancellation_Date__c = (Get-Date).ToString("yyyy-MM-dd")
        $body.Cancellation_Service_Fee__c = [decimal](Get-Random -Minimum 15 -Maximum 75)
    }

    Invoke-RestMethod `
        -Method Patch `
        -Uri "$Base/services/data/$ApiVersion/sobjects/Lab_Order__c/$OrderId" `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
}

function Create-Orders {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [int]$TotalCount,
        [string[]]$Names,
        [int]$ThrottleMs
    )

    $createdOrders = New-Object System.Collections.Generic.List[object]

    for ($i = 1; $i -le $TotalCount; $i++) {
        $clientName = $Names[($i - 1) % $Names.Length]
        $seed = New-SeedPayload -Index $i -ClientName $clientName

        try {
            Invoke-SfRestJson `
                -Method Post `
                -Url "$Base/services/apexrest/order" `
                -Headers $Headers `
                -Body $seed.request | Out-Null

            $labOrder = Get-LabOrderByExternalId -Base $Base -Headers $Headers -ExternalOrderId $seed.externalOrderId

            if ($labOrder) {
                $createdOrders.Add($labOrder) | Out-Null
            }

            Write-Host ("[{0}/{1}] Created order for {2}" -f $i, $TotalCount, $clientName)
        }
        catch {
            Write-Warning ("[{0}/{1}] Failed order for {2}: {3}" -f $i, $TotalCount, $clientName, $_.Exception.Message)
        }

        if ($ThrottleMs -gt 0) {
            Start-Sleep -Milliseconds $ThrottleMs
        }
    }

    return @($createdOrders.ToArray())
}

function Enrich-Orders {
    param(
        [string]$Base,
        [hashtable]$Headers,
        [object[]]$Orders,
        [string]$StatusOverride
    )

    if (-not $Orders -or $Orders.Count -eq 0) {
        Write-Host "No lab orders available to enrich."
        return
    }

    $orderIds = @($Orders | ForEach-Object { $_.Id })
    $existingPanelCounts = Get-PanelCountByOrderId -Base $Base -Headers $Headers -OrderIds $orderIds

    $index = 0
    foreach ($order in $Orders) {
        $index++
        $targetStatus = if ([string]::IsNullOrWhiteSpace($StatusOverride)) {
            Get-StatusForIndex -Index $index
        } else {
            $StatusOverride
        }
        $panelCount = 0

        if ($existingPanelCounts.ContainsKey($order.Id)) {
            $panelCount = $existingPanelCounts[$order.Id]
        }

        try {
            if ($panelCount -eq 0) {
                Add-PanelsToOrder -Base $Base -Headers $Headers -OrderId $order.Id -TargetStatus $targetStatus
            }

            Update-LabOrderStatus -Base $Base -Headers $Headers -OrderId $order.Id -TargetStatus $targetStatus
            Write-Host ("Enriched order {0} with status {1}" -f $order.Id, $targetStatus)
        }
        catch {
            Write-Warning ("Failed to enrich order {0}: {1}" -f $order.Id, $_.Exception.Message)
        }
    }
}

Assert-PreprodTarget -Url $BaseUrl

if ([string]::IsNullOrWhiteSpace($AccessToken)) {
    $AccessToken = Get-PreprodAccessToken -Url $BaseUrl -Id $ClientId -Secret $ClientSecret
}

$headers = @{
    Authorization = "Bearer $AccessToken"
    "Content-Type" = "application/json"
}

$ordersToEnrich = @()

if ($Mode -in @("create", "create-and-enrich")) {
    $ordersToEnrich = Create-Orders -Base $BaseUrl -Headers $headers -TotalCount $Count -Names $ClientNames -ThrottleMs $DelayMs
    Write-Host ""
    Write-Host ("Created {0} orders in this run." -f $ordersToEnrich.Count)
}

if ($Mode -eq "enrich-existing") {
    $ordersToEnrich = Get-RecentLabOrders -Base $BaseUrl -Headers $headers -Hours $RecentHours -Names $ClientNames
    Write-Host ("Found {0} recent orders to enrich." -f $ordersToEnrich.Count)
}

if ($Mode -eq "create-and-enrich") {
    Enrich-Orders -Base $BaseUrl -Headers $headers -Orders $ordersToEnrich -StatusOverride $ForcedStatus
}
elseif ($Mode -eq "enrich-existing") {
    Enrich-Orders -Base $BaseUrl -Headers $headers -Orders $ordersToEnrich -StatusOverride $ForcedStatus
}
