<#
.SYNOPSIS
    Script to get the resource count present in Azure subscription.

.DESCRIPTION
    This script helps to get the resource and workload based count present in subscription.

.NOTES
    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    Version:        1.0
    Author:         Cloudneeti
    Creation Date:  07/08/2020
    Pre-Requisites:
    - This script needs to run inside Azure Cloud Shell.

.EXAMPLE
    1. Get Azure Resource Count
        .\Get-AzureResourceCount.ps1 -SubscriptionId <subscriptionId>

.INPUTS
    SubscriptionId: Subscription id for which resource count needs to be calculate

.OUTPUTS
   Total resources present in Azure subscription 
   Workload count as specified in Workload file
#>

[CmdletBinding()]
param (            
    # Subscription Id
    [Parameter(Mandatory = $true,
        HelpMessage = "SubscriptionId",
        Position = 1
    )]
    [ValidateNotNullOrEmpty()]
    [guid] $SubscriptionId
)
# Session configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

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

# Read Zscaler CSPM workload Mapping
Write-host "Fetching Zscaler CSPM workload Mapping"
try {
    $workloadMapping = Invoke-WebRequest -uri "https://raw.githubusercontent.com/Avantika-Gupta30/docs_cloudneeti/Avantika/resource-count-script-modification/scripts/ZPC-Scripts/workloadMapping.json" | ConvertFrom-Json
    write-host "Successfully fetched workload mapping" -ForegroundColor Green
}
catch [Exception] {
    write-host "Error occurred while fetching workload mapping" -ForegroundColor Red
    Write-Error $_ -ErrorAction Stop
}

Write-Host "Adding Resource Graph Extension"
az extension add --name 'resource-graph'

# Prepare Filter Query
$query_filter = ""
$workLoadTotalCount = 0
Write-Output "Collecting total workloads count present in $subscriptionId subscription"
ForEach($workload in $workloadMapping.workloadMapping.Azure.PSObject.Properties) {
    # Checking presence of workload in all resources

    $query_filter = "type=='$($workload.value)'"
    #$query_filter = $query_filter.Substring(0,$query_filter.Length-3)
    # Processing Workloads
    $query = "summarize count() by type | where " + $query_filter + "| project resource=type , total=count_ | order by total desc" 
    $workloadDetails = az graph query -q $query --subscriptions $subscriptionId --output json | ConvertFrom-Json | Select-Object -Expand data
    if($workloadDetails)
    {
        Write-Host "`n`nWorkloads Distribution: $($workload.value)" -ForegroundColor Yellow
        Write-Host "...... Workload details" -ForegroundColor Blue
        $workloadDetails | Format-Table -AutoSize 
    }
    else
    {
        Write-Host "Workload distribution: $($workload.value)-> Not found" -ForegroundColor Red

    }
    ################### only functions /5 ######################
    $workloadCount = (az graph query -q "where $query_filter | summarize count()" --subscriptions $subscriptionId --output json | ConvertFrom-Json | Select-Object -Expand data).count_
    
    if(($workload.value -like "*microsoft.web/sites*") -and ($workloadCount -ne 0))
    {
        if($workloadCount -ge 5)
        {

            $workloadCount = [int]($workloadCount/5)
        }
        else
        {
            $workloadCount = 1

        }
    }
    $workLoadTotalCount = $workLoadTotalCount + $workloadCount
}
 Write-Output "Total Workload Count for Subscription $subscriptionId : $workLoadTotalCount"

# All Resources
Write-Host "Collecting all resources count present in $subscriptionId subscription"
$resourceCount = (az graph query -q "summarize count()" --subscriptions $subscriptionId --output json | ConvertFrom-Json | Select-Object -Expand data).count_


# Collect Resource Distribution
Write-Host "Collecting resource details present in $subscriptionId subscription"
$resourceDetails = az graph query -q "summarize count() by type| project resource=type , total=count_ | order by total desc" --subscriptions $subscriptionId --output json | ConvertFrom-Json | Select-Object -Expand data

Write-Host "`n`nCloudneeti Supported Total Workloads:", $workLoadTotalCount -ForegroundColor Green
Write-Host "Total Resource count:", $resourceCount -ForegroundColor Green


Write-Host "`n`n Resources details:" -ForegroundColor Yellow
$resourceDetails | Format-Table -AutoSize
