<#
.SYNOPSIS
  Seeds a small batch of lab orders for GOOGLE_HEALTH_STUDY only (preprod by default).

.DESCRIPTION
  Preprod only: -BaseUrl must contain "preprod" (default is the Quest preprod My Domain). The underlying
  seed-preprod-lab-orders.ps1 enforces the same rule.

  Thin wrapper around seed-preprod-lab-orders.ps1 with -ClientNames set to GOOGLE_HEALTH_STUDY
  and a low default -Count. Use -Status to force every new order to the same lab order status
  after panels are added; omit -Status for the mixed status pattern built into the seed script.

  Optional env vars (if -ClientId / -ClientSecret / -AccessToken are not passed):
    QUEST_PREPROD_SF_CLIENT_ID, QUEST_PREPROD_SF_CLIENT_SECRET, or QUEST_PREPROD_SF_ACCESS_TOKEN.

.EXAMPLE
  .\scripts\seed-google-health-study-lab-orders.ps1 -ClientId "..." -ClientSecret "..." -Count 5

.EXAMPLE
  .\scripts\seed-google-health-study-lab-orders.ps1 -ClientId "..." -ClientSecret "..." -Status Results Ready
#>
[CmdletBinding()]
param(
    [string]$BaseUrl = "https://questdiagnosticscitorg1--preprod.sandbox.my.salesforce.com",
    [int]$Count = 6,
    [ValidateSet("create", "enrich-existing", "create-and-enrich")]
    [string]$Mode = "create-and-enrich",
    [ValidateSet("Registered", "PA Approved", "In Progress", "Partial Results Ready", "Results Ready", "Cancelled")]
    [string]$Status,
    [string]$AccessToken,
    [string]$ClientId,
    [string]$ClientSecret,
    [int]$DelayMs = 0,
    [int]$RecentHours = 24
)

$ErrorActionPreference = "Stop"

if ($BaseUrl -notmatch "preprod") {
    throw "This script is for preprod only. Use a -BaseUrl that contains 'preprod' (default Quest preprod sandbox). Current: $BaseUrl"
}

$seedScript = Join-Path $PSScriptRoot "seed-preprod-lab-orders.ps1"
if (-not (Test-Path -LiteralPath $seedScript)) {
    throw "Could not find seed script at: $seedScript"
}

$params = @{
    BaseUrl     = $BaseUrl
    Mode        = $Mode
    Count       = $Count
    ClientNames = @("GOOGLE_HEALTH_STUDY")
    DelayMs     = $DelayMs
    RecentHours = $RecentHours
}

$resolvedToken = $AccessToken
if ([string]::IsNullOrWhiteSpace($resolvedToken)) {
    $resolvedToken = $env:QUEST_PREPROD_SF_ACCESS_TOKEN
}
$resolvedId = $ClientId
if ([string]::IsNullOrWhiteSpace($resolvedId)) {
    $resolvedId = $env:QUEST_PREPROD_SF_CLIENT_ID
}
$resolvedSecret = $ClientSecret
if ([string]::IsNullOrWhiteSpace($resolvedSecret)) {
    $resolvedSecret = $env:QUEST_PREPROD_SF_CLIENT_SECRET
}

if (-not [string]::IsNullOrWhiteSpace($resolvedToken)) {
    $params.AccessToken = $resolvedToken
}
elseif (-not [string]::IsNullOrWhiteSpace($resolvedId) -and -not [string]::IsNullOrWhiteSpace($resolvedSecret)) {
    $params.ClientId = $resolvedId
    $params.ClientSecret = $resolvedSecret
}
if ($PSBoundParameters.ContainsKey("Status") -and -not [string]::IsNullOrWhiteSpace($Status)) {
    $params.ForcedStatus = $Status
}

Write-Host "Seeding $Count lab order(s) for GOOGLE_HEALTH_STUDY (mode=$Mode)..."
& $seedScript @params
