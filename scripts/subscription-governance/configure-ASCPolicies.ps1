<#
.SYNOPSIS
    This script configure Azure Security Center policies.

.DESCRIPTION
    This script helps to configure policies of Azure Security Center at subscription or management level scope.

.NOTES

    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Version:        1.1
    Author:         Cloudneeti
    Creation Date:  09/08/2019
    Updated On:     11/02/2020

    Pre-Requisites:
    - This script needs to run inside Azure Cloud Shell.

.EXAMPLE
    1. Configure ASC default policies
        .\configure-ASCPolicies.ps1 -SubscriptionId <subscriptionId>

    2. Configure ASC Policies at Management Group level
        .\configure-ASCPolicies.ps1 -EnableManagementGroup -ManagementGroupId <ManagementGroupId>

.INPUTS
    SubscriptionId: Subscription id for which ASC policies needs to be configured.
    EnableManagementGroup: Switch to select Management Group
    ManagementGroupId: Management group id for which ASC policies needs to be configured.

.OUTPUTS
    Configured ASC policies at subscription or management group level scope
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

# Read ASC policies data
Write-host "Fetching ASC policies to configure"
try {
    $ascPolicies = Invoke-WebRequest -uri "https://raw.githubusercontent.com/Cloudneeti/docs_cloudneeti/pratik/asc-quick-wins/scripts/subscription-governance/asc-policy-data.json" | ConvertFrom-Json
    write-host "Successfully fetched ASC policies" -ForegroundColor Green
}
catch [Exception] {
    write-host "Error occurred while fetching ASC policies" -ForegroundColor Red
    Write-Error $_ -ErrorAction Stop
}

# Get existing security center built in policy definition set
if($EnableManagementGroup)
{
    Write-Host "Getting Management Group level Azure Security Center policy initiative" -ForegroundColor Yellow
    $defaultAssignment = Get-AzPolicyAssignment -Scope "/providers/Microsoft.Management/managementGroups/$ManagementGroupId" -PolicyDefinitionId "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8" | Select-Object -First 1

    if ($null -ne $defaultAssignment) {
        Write-Host "Enabling ASC policies at Management Group level..." -ForegroundColor Yellow
        
        $PolicyAssignmentId = $defaultAssignment.PolicyAssignmentId.split('/')[-1]
        $mgmtAPI = "https://management.azure.com/providers/Microsoft.Management/managementGroups/$ManagementGroupId/providers/Microsoft.Authorization/policyAssignments/$($PolicyAssignmentId)?api-version=2018-05-01"
        
        # Setting up the JSON Object
        # ASC Disable JSON Object
        $ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState.name = $($defaultAssignment.Name)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState.identity.principalId = $($defaultAssignment.Identity.principalId)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState.identity.tenantId = $($defaultAssignment.Identity.tenantId)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState.id = $($defaultAssignment.PolicyAssignmentId)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState.location = $($defaultAssignment.Location)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState.properties.displayName = $($defaultAssignment.Properties.displayName)

        # ASC Enable JSON Object
        $ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState.name = $($defaultAssignment.Name)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState.identity.principalId = $($defaultAssignment.Identity.principalId)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState.identity.tenantId = $($defaultAssignment.Identity.tenantId)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState.id = $($defaultAssignment.PolicyAssignmentId)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState.location = $($defaultAssignment.Location)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState.properties.displayName = $($defaultAssignment.Properties.displayName)
    }
    else {
        Write-Host "Azure Security Center initiative at Management Group $ManagementGroupId not found." -foregroundcolor red
        break;

    }
}
else { 
    $defaultAssignment = Get-AzPolicyAssignment -Scope "/subscriptions/$SubscriptionId" -PolicyDefinitionId "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8" | Select-Object -First 1
    if ($null -ne $defaultAssignment) {
        $PolicyAssignmentId = $defaultAssignment.PolicyAssignmentId.split('/')[-1]
        $mgmtAPI = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Authorization/policyAssignments/$($PolicyAssignmentId)?api-version=2018-05-01"
        # Setting up the JSON Object
        # ASC Disable JSON Object
        $ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState.name = $($defaultAssignment.Name)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState.identity.principalId = $($defaultAssignment.Identity.principalId)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState.identity.tenantId = $($defaultAssignment.Identity.tenantId)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState.id = $($defaultAssignment.PolicyAssignmentId)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState.location = $($defaultAssignment.Location)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState.properties.displayName = $($defaultAssignment.Properties.displayName)

        # ASC Enable JSON Object
        $ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState.name = $($defaultAssignment.Name)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState.identity.principalId = $($defaultAssignment.Identity.principalId)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState.identity.tenantId = $($defaultAssignment.Identity.tenantId)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState.id = $($defaultAssignment.PolicyAssignmentId)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState.location = $($defaultAssignment.Location)
        $ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState.properties.displayName = $($defaultAssignment.Properties.displayName)
    }
    else {
        Write-Host "Azure Security Center initiative at default policy not found." -foregroundcolor red
        break;
    }
}

# Converting ASC PSObject into JSON object
$disabledPolicies = ($ascPolicies.AzureSecurityCenter.ASCPoliciesDisabledState | ConvertTo-Json -Depth 20)
$enabledPolicies = ($ascPolicies.AzureSecurityCenter.ASCPoliciesEnabledState | ConvertTo-Json -Depth 20)

# Getting access token for asc
Write-Host "Getting Access Token ..."
$token=(az account get-access-token | ConvertFrom-Json).accessToken
Write-Host "Access Token retrieved Successfully." -ForegroundColor Green
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
    Write-Error $_ -ErrorAction Stop
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
    Write-Error $_ -ErrorAction Stop
}

Write-Host "Script execution completed." -ForegroundColor Yellow
