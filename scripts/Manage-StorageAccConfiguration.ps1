<#
.SYNOPSIS
    This Script apply or remove the policy configuration for storage account resources.

.DESCRIPTION
    This script apply configuration on storage accounts with respect to Cloudneeti Policies. It can also be used for removing the configuration.

.NOTES

    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Version:        1.0
    Author:         Cloudneeti
    Creation Date:  25/02/2019

.EXAMPLE

1. Apply Policy configuration
    .\Manage-StorageAccConfiguration.ps1 -subscriptionId <subscriptionId> -policyConfiguration Apply/Remove

.INPUTS
-SubscriptionId

.OUTPUTS
Successfully Applied/Removed policy configuration.

#>

[CmdletBinding()]
param
(
    # SubscriptionId
    [Parameter(Mandatory = $False,
        HelpMessage="SubscriptionId",
        Position=1
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $SubscriptionId = $(Read-Host -prompt "Enter Subscription Id"),

    # policy configuration
    [Parameter(Mandatory = $False,
        HelpMessage="Policy Configuration Action",
        Position=2
    )]
    [ValidateSet("Apply", "Remove")]
    [string]
    $PolicyConfigurationAction = $(Read-Host -prompt "Enter Policy Configuration Action (Apply/Remove)")
)

# Session configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

Write-Host "Script Execution Started." -ForegroundColor Yellow

# Checking current azure rm context to deploy Azure automation
$AzureContextSubscriptionId = (Get-AzureRmContext).Subscription.Id

If ($AzureContextSubscriptionId -ne $SubscriptionId){
    Write-Host "You are not logged in to subscription" $SubscriptionId 
    Try{
        Write-Host "Trying to switch powershell context to subscription" $SubscriptionId
        $AllAvailableSubscriptions = (Get-AzureRmSubscription).Id
        if ($AllAvailableSubscriptions -contains $SubscriptionId)
        {
            Set-AzureRmContext -SubscriptionId $SubscriptionId
            Write-Host "Successfully context switched to subscription" $SubscriptionId -ForegroundColor Green
        }
        else{
            Write-Host "Looks like the $SubscriptionId is not present in current powershell context or you don't have access" -ForegroundColor Red -ErrorAction Stop
            break
        }
    }
    catch [Exception]{
        Write-Output $_ -ErrorAction Stop
    }
}

switch($PolicyConfigurationAction) {
    "apply" {
        $EnableHttpsTrafficOnly = $True
        $SkuName = "Standard_GRS"
        $Tags = @{DataProfile="phi"}
        $StartMessage = "Applying security configuration to storage account"
        $SuccessMessage = "Successfully applied security configuration to storage accounts"
        $FailureMessage = "Error ocurred while applying security configuration to storage accounts"
    }
    "remove" {
        $EnableHttpsTrafficOnly = $False
        $SkuName = "Standard_LRS"
        $Tags = @{}
        $StartMessage = "Removing security configuration of storage account"
        $SuccessMessage = "Successfully removed security configuration of storage accounts"
        $FailureMessage = "Error ocurred while removing security configuration of storage accounts"
    }
}

# Perform configuration changes
Get-AzureRmStorageAccount | ForEach-Object {
    try {
        Write-Host "`n$StartMessage", $_.StorageAccountName
        Set-AzureRmStorageAccount -StorageAccountName $_.StorageAccountName -ResourceGroupName $_.ResourceGroupName -EnableHttpsTrafficOnly $EnableHttpsTrafficOnly -SkuName $SkuName -Tags $Tags | Out-Null
        Write-Host $SuccessMessage, $_.StorageAccountName -ForegroundColor Green
    }
    catch [Exception]{
        Write-Host $FailureMessage, $_.StorageAccountName -ForegroundColor Red
        Write-Host $_ -ForegroundColor Red
    }
}

Write-Host "`nScript Execution completed." -ForegroundColor Yellow