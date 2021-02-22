<#
.SYNOPSIS
    This script configure storage account

.DESCRIPTION
    This script helps to configure storage account

.NOTES

    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Version:        1.1
    Author:         Cloudneeti
    Creation Date:  09/10/2019

    Pre-Requisites:
    - This script needs to run inside Azure Cloud Shell

.EXAMPLE
    
    1. Configure secure transfer on storage account with storage account exclusion 
        .\configure-StorageAccounts.ps1 -SubscriptionId <subscriptionId> -ExcludeStorageAccounts <excludeStorageAccounts> -EnableHttps

    2. Configure geo replication on storage account with exclusion 
        .\configure-StorageAccounts.ps1 -SubscriptionId <subscriptionId> -ExcludeStorageAccounts <excludeStorageAccounts> -EnableGeoReplication

    3. Configure secure transfer and geo replication on storage account with exclusion 
        .\configure-StorageAccounts.ps1 -SubscriptionId <subscriptionId> -ExcludeStorageAccounts <excludeStorageAccounts> -All

    4. Configure secure transfer on storage account with storage account exclusion 
        .\configure-StorageAccounts.ps1 -SubscriptionId <subscriptionId> -EnableHttps

    5. Configure geo replication on storage account with exclusion 
        .\configure-StorageAccounts.ps1 -SubscriptionId <subscriptionId> -EnableGeoReplication

    6. Configure secure transfer and geo replication on all storage account
        .\configure-StorageAccounts.ps1 -SubscriptionId <subscriptionId> -All

.INPUTS
    SubscriptionId: Subscription id for which storage account needs to be configured
    ExcludeStorageAccounts: Storage account name that want to exclude. [ Array -> put storage accounts name that want to exclude ]
    EnableHttps: Enable secure transfer on storage account
    EnableGeoReplication: Enable geo replication on storage account
    All: Enable secure transfer as well as geo replication on storage account

.OUTPUTS
    Configured storage accounts
#>

[CmdletBinding()]
param (
        
    # Subscription Id
    [Parameter(ParameterSetName = 'Https')]
    [Parameter(ParameterSetName = 'Geo')]
    [Parameter(ParameterSetName = 'All')]
    [Parameter(Mandatory = $True,
        HelpMessage = "Subscription Id",
        Position = 1
    )]
    [ValidateNotNullOrEmpty()]
    [guid] $SubscriptionId,

    # Exclude Storage Account
    [Parameter(Mandatory = $False,
        HelpMessage = "Exclude Storage Account",
        Position = 2
    )]
    [string[]] $ExcludeStorageAccounts = "",

    # Enable Secure Transfer
    [Parameter(ParameterSetName = 'Https')]
    [Parameter(Mandatory = $False,
        HelpMessage = "Enable Https",
        Position = 3
    )]
    [switch] $EnableHttps,

    # Enable Geo Replication
    [Parameter(ParameterSetName = 'Geo')]
    [Parameter(Mandatory = $False,
        HelpMessage = "Enable Geo Replication",
        Position = 4
    )]
    [switch] $EnableGeoReplication,

    # Enable Secure Transfer and Geo Replication
    [Parameter(ParameterSetName = 'All')]
    [Parameter(Mandatory = $False,
        HelpMessage = "Enable Https and Geo Replication",
        Position = 5
    )]
    [switch] $All
)

# Session configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

# Intialization 
$storageAccounts = @()

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

# Getting all storage account present Azure subscription
Try {
    Write-Host "Getting all the storage accounts present in subscription $subscriptionId..." -ForegroundColor Yellow
    $AllStorageAccounts = Get-AzStorageAccount
    if($null -eq $AllStorageAccounts){
        Write-Host "Storage accounts are not present in subscription $subscriptionId." -ForegroundColor Yellow
        Exit
    }else{
        Write-Host "Successfully retrieved all the storage accounts present in subscription $subscriptionId." -ForegroundColor Green
    }
}
Catch [Exception] {
        Write-Host "Error occurred while getting the storage accounts present in subscription $subscriptionId." -ForegroundColor Red
        write-error $_
        Exit
}

# Storage account list
$storageAccounts = $AllStorageAccounts | where { $ExcludeStorageAccounts -NotContains $_.StorageAccountName }

if(($storageAccounts).count -eq 0) {
    Write-Host "Storage accounts are not available for performing operations." -ForegroundColor Yellow
    Write-Host "Kindly check the ExcludeStorageAccount list and try again" -ForegroundColor Yellow
    Exit
}

# Updating storage accounts present in az context
if($EnableHttps -and ($null -ne $storageAccounts)){
    Try {
        Write-Host "Enabling secure transfer(HTTPS) on storage accounts..."
        $storageAccounts | Set-AzStorageAccount -EnableHttpsTrafficOnly $true
        Write-Host "Successfully enabled secure transfer(HTTPS) on storage accounts." -ForegroundColor Green
    }
    Catch [Exception] {
        Write-Host "Error occurred while enabling secure transfer(HTTPS) on storage accounts." -ForegroundColor Red
        write-error $_
    }
}
elseif($EnableGeoReplication -and ($null -ne $storageAccounts)){
    Try {
        Write-Host "Enabling geo replication on storage accounts..."
        $storageAccounts | Set-AzStorageAccount -SkuName Standard_GRS
        Write-Host "Successfully enabled geo replication on storage accounts." -ForegroundColor Green
    }
    Catch [Exception] {
        Write-Host "Error occurred while enabling geo replication on storage accounts." -ForegroundColor Red
        write-error $_
    }
}
elseif($All -and ($null -ne $storageAccounts)){
    Try {
        Write-Host "Enabling secure transfer(HTTPS) and geo replication on storage accounts..."
        $storageAccounts | Set-AzStorageAccount -EnableHttpsTrafficOnly $true -SkuName Standard_GRS
        Write-Host "Successfully enabled secure transfer(HTTPS) and geo replication on storage accounts." -ForegroundColor Green
    }
    Catch [Exception] {
        Write-Host "Error occurred while enabling secure transfer(HTTPS) and geo replication on storage accounts." -ForegroundColor Red
        write-error $_
    }
}

Write-Host "Script execution completed." -ForegroundColor Yellow
