<#
.SYNOPSIS
    Manage key vault access policies for cloudneeti data collector service principal

.DESCRIPTION
    This script will assign/revoke following permission to cloudneeti data collector application on all keyvaults in the specified subscription.
    Secrets : Get, List
    Keys : Get, List

.NOTES

    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Version:        1.0
    Author:         Cloudneeti
    Creation Date:  09/08/2019

    # PREREQUISITE
      Run this script in Azure Cloud Shell

.EXAMPLE
    
    1. Assign keyvault access permissions to cloudneeti service principal
        ./Manage-KeyVaultPermissions.ps1 -SubscriptionId <Subscription Id> -CloudneetiServicePrincipalObjectId <Cloudneeti Data Collector Service Principal Object ID> -Action AssignPermission -Verbose
    2. Revoke cloudneeti service principal access permissions from keyvaults
        ./Manage-KeyVaultPermissions.ps1 -SubscriptionId <Subscription Id> -CloudneetiServicePrincipalObjectId <Cloudneeti Data Collector Service Principal Object ID> -Action RevokePermission -Verbose

.INPUTS
    SubscriptionId: Subscription Id
    CloudneetiServicePrincipalObjectId: Cloudneeti Data Collector Service Principal Object ID
    Action: Action to perform. AssignPermission/RevokePermission

.OUTPUTS
    None
#>

[cmdletbinding()]
param
(
    # Subscription Id
    [ValidateNotNullOrEmpty()]
    [Parameter(
        Mandatory = $True,
        Position = 1
    )][guid]$SubscriptionId,

    # Cloudneeti Data Collector Service Principal Object ID
    [ValidateNotNullOrEmpty()]
    [Parameter(
        Mandatory = $True,
        Position = 2
    )][guid] $CloudneetiServicePrincipalObjectId,

    # Action
    [ValidateNotNullOrEmpty()]
    [ValidateSet("AssignPermissions", "RevokePermissions")]
    [Parameter(
        Mandatory = $True,
        Position = 3
    )][String] $Action = $(Read-Host -Prompt "Action To Perform: AssignPermissions/RevokePermissions")
)

Write-Host "Script Execution Started !!!" -ForegroundColor Yellow

Try{
    Write-Host "`nUser Login is required for access policy assignments. Sign in with user principal by clicking the link below and use the code provided..." -ForegroundColor Green
    Connect-AzAccount -Subscription $SubscriptionId -ErrorAction Stop | Out-Host 
}
Catch [Exception] {
    Write-Host "Looks like you don't have access the" $SubscriptionId" subscription" -ForegroundColor Red
    Write-Error $_ -ErrorAction Stop
}

Write-Host "`nPerforming $Action oprations on all keyvaults from given subscriptions`n" -ForegroundColor Green
$AllKeyVaults = Get-AzKeyVault

if ($Action -eq "AssignPermissions") {
    foreach ($Vault in $AllKeyVaults) {
        Write-Host "Assigning permissions to keyvault: " -NoNewline
        Write-Host "$($Vault.VaultName)" -NoNewline -ForegroundColor Yellow
        try {        
            Set-AzKeyVaultAccessPolicy -VaultName $Vault.VaultName -ObjectId $CloudneetiServicePrincipalObjectId -PermissionsToSecrets Get, List -PermissionsToKeys Get, List
            Write-Host " - Success" -ForegroundColor Green
        }
        catch [Exception] {
            Write-Host " - Failed" -ForegroundColor Red
            Write-Host $_
        }
    }
}
elseif ($Action -eq "RevokePermissions") {
    foreach ($Vault in $AllKeyVaults) {
        Write-Host "Revoking permissions from keyvault: " -NoNewline
        Write-Host "$($Vault.VaultName)" -NoNewline -ForegroundColor Yellow
        try {        
            Remove-AzKeyVaultAccessPolicy -VaultName $Vault.VaultName -ObjectId $CloudneetiServicePrincipalObjectId
            Write-Host " - Success" -ForegroundColor Green
        }
        catch [Exception] {
            Write-Host " - Failed" -ForegroundColor Red
            Write-Host $_
        }
    }
}
else {
    Write-Error "No valid action provided, script will now exit."
}

Write-Host "`nScript Execution Completed !!!" -ForegroundColor Yellow
