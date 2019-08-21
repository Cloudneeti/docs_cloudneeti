<#
.SYNOPSIS
    This script configure Azure Security Center policies.

.DESCRIPTION
    This script helps to configure policies of Azure Security Center.

.NOTES
    Version:        1.0
    Author:         Cloudneeti
    Creation Date:  09/08/2019

    Pre-Requisites:
    - This script needs to run inside Azure Cloud Shell.

.EXAMPLE
    1. Configure ASC default policies
        .\configure-ASCPolicies.ps1 -SubscriptionId <subscriptionId>

.INPUTS
    SubscriptionId: Subscription id for which ASC policies needs to be configured.

.OUTPUTS
    Configured ASC policies.
#>

[CmdletBinding()]
param (
        
    # Subscription Id
    [Parameter(Mandatory = $True,
        HelpMessage = "SubscriptionId",
        Position = 1
    )]
    [ValidateNotNullOrEmpty()]
    [guid] $SubscriptionId
)

# Session configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

# Initialization of variables
$Flag = 0

Write-Host "Script Execution Started..." -ForegroundColor Yellow

# Checking current az context to deploy Azure automation
$AzureContextSubscriptionId = (Get-AzContext).Subscription.Id

If ($AzureContextSubscriptionId -ne $SubscriptionId) {
    Write-Host "You are not logged in to subscription" $SubscriptionId 
    Try {
        Write-Host "Trying to switch powershell context to subscription" $SubscriptionId
        $AllAvailableSubscriptions = (Get-AzSubscription).Id
        if ($AllAvailableSubscriptions -contains $SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId
            Write-Host "Successfully context switched to subscription" $SubscriptionId -ForegroundColor Green
        }
        else {
            Write-Host "Looks like the $SubscriptionId is not present in current powershell context or you don't have access" -ForegroundColor Red -ErrorAction Stop
            break
        }
    }
    catch [Exception] {
        Write-Host "Error occurred while switching to subscription $subscriptionId. Check subscription Id and try again." -ForegroundColor Red
        Write-Error $_ -ErrorAction Stop
    }
}

# Read ASC policies data
Write-host "Fetching ASC policies to configure"
try {
    $ascPolicies = Invoke-WebRequest -uri "https://raw.githubusercontent.com/Cloudneeti/docs_cloudneeti/master/scripts/subscription-governance/asc-policy-data.json" | ConvertFrom-Json
    write-host "Successfully fetched ASC policies" -ForegroundColor Green
}
catch [Exception] {
    write-host "Error occurred while fetching ASC policies" -ForegroundColor Red
    Write-Error $_ -ErrorAction Stop
}

# Get existing security center built in policy definition set
$defaultAssignment = Get-AzPolicyAssignment -Name "SecurityCenterBuiltIn" -ErrorAction SilentlyContinue
if ($null -ne $defaultAssignment) {
    $ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState.properties.displayName = $($defaultAssignment.Properties.displayName)
	$ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState.properties.displayName = $($defaultAssignment.Properties.displayName)
}
else {
    # Assign default policy name
    $ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState.properties.displayName = "ASC Default (subscription: $SubscriptionId)"
    $ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState.properties.displayName = "ASC Default (subscription: $SubscriptionId)"
}

# Converting ASC PSObject into JSON object
$disabledPolicies = ($ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState | ConvertTo-Json -Depth 20)
$enabledPolicies = ($ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState | ConvertTo-Json -Depth 20)

# Getting access token for asc
Write-Host "Getting Access Token ..."
$token=$(az account get-access-token | jq -r .accessToken)
Write-Host "Access Token retrieved Successfully." -ForegroundColor Green

$mgmtAPI = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Authorization/policyAssignments/SecurityCenterBuiltIn?api-version=2018-05-01"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add('authorization', "Bearer " + $token)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Disable asc policies
try {
    Write-Host "Disabling ASC policies ..."
    $response = Invoke-WebRequest -Method PUT -Uri $mgmtAPI -Headers $headers -Body $disabledPolicies -ContentType "application/json"
    if ($null -ne $response) {
       Write-Host "Successfully disabled ASC policies." -ForegroundColor Green
    }
}
catch [Exception] {
    Write-Host "Error occurred while disabling ASC policies." -foregroundcolor red
    Write-Host $_
}

# Wait for 10 seconds
Write-Host "Wait for 10 seconds to reflect the changes in azure security center ..."
Start-Sleep -Seconds 10

# Enable ASC policies
try {
    Write-Host "Enabling ASC policies ..." -ForegroundColor Yellow
    $response = Invoke-WebRequest -Method PUT -Uri $mgmtAPI -Headers $headers -Body $enabledPolicies -ContentType "application/json"
    if ($null -ne $response) {
        Write-Host "Successfully enabled ASC policies." -ForegroundColor Green
    }
}
catch [Exception] {
    Write-Host "Error occurred while enabling ASC policies." -foregroundcolor red
    Write-Host $_
}

Write-Host "Script execution completed." -ForegroundColor Yellow
