<#
.SYNOPSIS
    This script extract Azure Security Center policies.

.DESCRIPTION
    This script helps to extract the policies of Azure Security Center at subscription or management level scope.

.NOTES

    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Version:        1.1
    Author:         Cloudneeti
    Creation Date:  10/19/2021
    Updated On:     10/19/2021

    Pre-Requisites:
    - This script needs to run inside Azure Cloud Shell.

.EXAMPLE
    1. Configure ASC default policies
        .\Get-ASCPolicies.ps1 -SubscriptionId <subscriptionId>

    2. Configure ASC Policies at Management Group level
        .\Get-ASCPolicies.ps1 -EnableManagementGroup -ManagementGroupId <ManagementGroupId>

.INPUTS
    SubscriptionId: Subscription id for which ASC policies needs to be configured.
    EnableManagementGroup: Switch to select Management Group
    ManagementGroupId: Management group id for which ASC policies needs to be configured.

.OUTPUTS
    Json File with Configured ASC policies at subscription or management group level scope
#>

[CmdletBinding()]
param (
        
    # Subscription Id
    [Parameter(Mandatory = $false,
        HelpMessage = "SubscriptionId",
        Position = 1
    )]
    [ValidateNotNullOrEmpty()]
    [guid] $SubscriptionId,

    [Parameter(Mandatory = $false,
        HelpMessage = "EnableManagementGroup",
        Position = 2
    )]
    [switch] $EnableManagementGroup,

    [Parameter(Mandatory = $false,
        HelpMessage = "ManagementGroupId",
        Position = 3
    )]
    [String] $ManagementGroupId

)

# Session configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

Write-Host "Script Execution Started..." -ForegroundColor Yellow

if($EnableManagementGroup)
{
    $AvailableManagementGroups= (Get-AzManagementGroup).Name
    Write-Host "Checking Azure Management Group $ManagementGroupId"
    Try {
        if ($AvailableManagementGroups -contains $ManagementGroupId) {
            Write-Host "Found Azure Management Group with name :"$ManagementGroupId -ForegroundColor Green
        }
        else {
            Write-Host "Looks like the $ManagementGroupId is not present in current tenant or you don't have access" -ForegroundColor Red -ErrorAction Stop
            break
        }
    }
    catch [Exception] {
        Write-Host "Error occurred while checking Azure Management Group $ManagementGroupId. Check management group name and try again." -ForegroundColor Red
        Write-Error $_ -ErrorAction Stop
    }
}

else {
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
}

$policyAssignments=@()
# Get existing security center built in policy definition set
if($EnableManagementGroup)
{
    Write-Host "Fetching Management Group level Azure Security Center policy initiative" -ForegroundColor Yellow
    $defaultAssignment = Get-AzPolicyAssignment -Scope "/providers/Microsoft.Management/managementGroups/$ManagementGroupId" -PolicyDefinitionId "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"

    if ($null -ne $defaultAssignment) {
        $policyAssignments+=$defaultAssignment| ConvertTo-Json
            
    }
    else {
        Write-Host "Azure Security Center initiative at Management Group $ManagementGroupId not found." -foregroundcolor red
        break;
    }
}
else { 
    Write-Host "Fetching ASC policies at Subscription level..." -ForegroundColor Yellow
    $defaultAssignment = Get-AzPolicyAssignment -Scope "/subscriptions/$SubscriptionId" -PolicyDefinitionId "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
    if ($null -ne $defaultAssignment) {
        $policyAssignments += $defaultAssignment| ConvertTo-Json
    }
    else {
        Write-Host "Azure Security Center initiative at default policy not found." -foregroundcolor red
        break;
    }
}

$policyAssignments |Out-File -FilePath ./defaultPolicyAssignments.json -Force

Write-Host "Script execution completed." -ForegroundColor Yellow
