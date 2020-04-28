<#
.SYNOPSIS
    Assign read permission to keyvaults.
.DESCRIPTION
    This script will assign following permission to cloudneeti data collector application on all keyvaults in the specified subscription.
    Secrets : Get, List
    Keys : Get, List

.NOTES

    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Version:        1.0

    # PREREQUISITE
      Run this script in Azure Cloud Shell

.EXAMPLE
    1. Assign permissions.
        ./AutoAssign-PermissionsToKeyvault.ps1 -SubscriptionId <Subscription Id> -CloudneetiRegisteredApplicationObjectId <Cloudneeti Data Collector Service Principal Object ID>

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
$AzureActiveDirectoryId = Get-AutomationVariable -Name "AzureActiveDirectoryId"
$CloudneetiRegisteredApplicationObjectId = Get-AutomationVariable -Name "CloudneetiRegisteredApplicationObjectId"


$Subscriptions = $SubscriptionId.Split(',')

Write-Output "Login using service principal..."
Login-AzAccount -Subscription $Subscriptions[0] -Tenant $AzureActiveDirectoryId -Credential $Credentials -ServicePrincipal -Force

foreach ($Subscription in $Subscriptions) {

    Write-Output "Setting Azure Context to selected subscription..."
    Set-AzContext -Subscription $Subscription | Write-Output

    Write-Output "Getting list of all keyvaults in selected subscription....`n"
    $AllKeyVaults = Get-AzKeyVault

    foreach ($Vault in $AllKeyVaults) {
        Write-Output "Assigning permissions to keyvault: $($Vault.VaultName)"
        Set-AzKeyVaultAccessPolicy -VaultName $Vault.VaultName -ObjectId $CloudneetiRegisteredApplicationObjectId -PermissionsToSecrets Get, List -PermissionsToKeys Get, List
    }
}

Write-Output "`nScript Execution Completed !!!"
