<#
.SYNOPSIS
    Assign read permission to keyvaults.
.DESCRIPTION
    This script will assign following permission to cloudneeti data collector application on all keyvaults in the specified subscription.
    Secrets : Get, List
    Keys : Get, List
.NOTES
    Version:        1.0

    # PREREQUISITE
      Run this script in Azure Cloud Shell

.EXAMPLE
    1. Assign permissions.
        ./AutoAssign-PermissionsToKeyvault.ps1 -SubscriptionId <Subscription Id> -CloudneetiServicePrincipalObjectId <Cloudneeti Data Collector Service Principal Object ID>

.INPUTS
    SubscriptionId: Comma seperated list of Subscription Id.
    CloudneetiApplicationID: Cloudneeti Data Collector Service Principal Object ID

.OUTPUTS
    None
#>

# Session configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

Write-Output "Fetching login credentials..."

$Credentials = Get-AutomationPSCredential -Name "ContributorSPCredentials"

Write-Output "Fetching automation variables..."

$SubscriptionId = Get-AutomationVariable -Name "SubscriptionId"
$TenantId = Get-AutomationVariable -Name "TenantId"
$CloudneetiServicePrincipalObjectId = Get-AutomationVariable -Name "CloudneetiServicePrincipalObjectId"


$Subscriptions = $SubscriptionId.Split(',')

Write-Output "Login using service principal..."
Login-AzAccount -Subscription $Subscriptions[0] -Tenant $TenantId -Credential $Credentials -ServicePrincipal -Force

foreach ($Subscription in $Subscriptions) {

    Write-Output "Setting Azure Context to selected subscription..."
    Set-AzContext -Subscription $Subscription | Write-Output

    Write-Output "Getting list of all keyvaults in selected subscription....`n"
    $AllKeyVaults = Get-AzKeyVault

    foreach ($Vault in $AllKeyVaults) {
        Write-Output "Assigning permissions to keyvault: $($Vault.VaultName)"
        Set-AzKeyVaultAccessPolicy -VaultName $Vault.VaultName -ObjectId $CloudneetiServicePrincipalObjectId -PermissionsToSecrets Get, List -PermissionsToKeys Get, List
    }
}

Write-Output "`nScript Execution Completed !!!"