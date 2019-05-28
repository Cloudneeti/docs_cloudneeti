<#
.SYNOPSIS
    Assign Roles to Cloudneei Remediation policy's MSI
.DESCRIPTION
    This script helps Azure subscription 'owner'/'User Access Administrator' to assign roles to MSI generated for Cloudneei Remediation policies.
.NOTES
    Version:        1.0
    Author:         Cloudneeti
    Creation Date:  20/05/2019

    # PREREQUISITE
    * Run script should be run on Azure Cloud Shell
	* Account permissions
        Logged in user must be an 'owner'/'User Access Administrator' of subscriptions
    
	* If you get error which says "You cannot run this script on the current system." then please run following command 
     "powershell -ExecutionPolicy Bypass"
     
.EXAMPLE
    1. Assign Role to MSI generated for Remediation policies
    	.\Assign-RoleToRemediationPolicy.ps1 -azureActiveDirectoryId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx -subscriptionId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx
.INPUTS
	azureActiveDirectoryId [Mandatory]:- Azure Active Directory Id (aka TenantId)
    subscriptionId [Mandatory]:- Subscription Id
.OUTPUTS	
    RoleAssignmentStatus:- Table of role assignment status (Success/Failed)
#>


[CmdletBinding()]
param(
    #TenantId
    [parameter(
        mandatory = $true,
        Position = 1
    )]
    [guid]$azureActiveDirectoryId,    

    #SubscriptionId
    [parameter(
        mandatory = $true,
        Position = 2
    )]
    [guid]$subscriptionId
)

# Session configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

Write-Host "Script Execution Started"

# Checking current azure rm context and switching to required subscription
Write-Host "Checking Azure Context"
$AzureContextSubscriptionId = (Get-AzContext).Subscription.Id

If ($AzureContextSubscriptionId -ne $subscriptionId) {
    Write-Host "You are not logged in to subscription" $subscriptionId 
    Try {
        Write-Host "Trying to switch powershell context to subscription" $subscriptionId
        $AllAvailableSubscriptions = (Get-AzSubscription).Id
        if ($AllAvailableSubscriptions -contains $subscriptionId) {
            Set-AzContext -SubscriptionId $subscriptionId -TenantId $azureActiveDirectoryId
            Write-Host "Successfully context switched to subscription" $subscriptionId
        }
        else {
            Write-Host "Looks like the" $AzureSubscriptionId "is not present in current powershell context or you don't have access" -ForegroundColor Red
            exit
        }
    }
    catch [Exception] {
        Write-Host "Error occurred during Azure Context switching, Try again." -ForegroundColor Red
        Write-Output $_
        exit
    }
}

# Check User Access management or owner Permission
Write-host "Checking logged in user having required permissions(owner, user access administrator) or not"
# TODO:

# Get Cloudneeti Policy Assignments
Write-host "Getting Cloudneeti Remediation Policies assigned in subscription $subscriptionId"
try {
    $policyAssignments = Get-AzPolicyAssignment | Where-Object { ($_.Name -like "CN-*") -and ($_.Identity -ne $NULL) }
    Write-Host "Successfully got the Cloudneeti Remediation Policies" -ForegroundColor Green
}
catch [Exception] {
    Write-Host "Error occurred while getting policy assignments" -ForegroundColor Red
    Write-Host $_
    exit
}

$roleAssignmentStatus = @()

foreach( $policyAssignment in $policyAssignments) {

    # Check for missing role on managed service identity
    $existingRoles = Get-AzRoleAssignment -Scope "/subscriptions/$subscriptionId" -ObjectId $policyAssignment.Identity.PrincipalId
    if( $NULL -ne $existingRoles)
    {
        continue
    }
    # Get Policy Definition and its roles
    $policyDefinition = get-azPolicyDefinition -Id $policyAssignment.Properties.policyDefinitionId
    $roleDefinitionIds = $policyDefinition.Properties.policyRule.then.details.roleDefinitionIds

    # Assign Policy Role
    if ($roleDefinitionIds.Count -gt 0)
    {
        $roleDefinitionIds | ForEach-Object {
            $roleAssignmentStatusEntry = "" | Select-Object "PolicyAssignmentName", "Status"
            $roleAssignmentStatusEntry.PolicyAssignmentName = $policyAssignment.Name
            $roleDefId = $_.Split("/") | Select-Object -Last 1
            try {
                New-AzRoleAssignment -Scope "/subscriptions/$subscriptionId" -ObjectId $policyAssignment.Identity.PrincipalId -RoleDefinitionId $roleDefId
                $roleAssignmentStatusEntry.Status = "Success"
                Write-Host "Successfully assigned role to", $policyAssignment.Name
                #TODO: Adding permission name to status output
            }
            catch [Exception]
            {
                Write-Host "Error occurred while assigning role"
                $roleAssignmentStatusEntry.Status = "Failed"
            }
            $roleAssignmentStatus += $roleAssignmentStatusEntry
        }
    }
}

if($roleAssignmentStatus.Count -gt 0)
{
    Write-Host "-----------------------"
    Write-Host "ROLE ASSIGNMENT SUMMARY"
    Write-Host "-----------------------"
    $roleAssignmentStatus | sort-object Status | Format-Table -AutoSize -GroupBy Status
}
else
{
    Write-Host "Role assignment already exists on remediation policies OR No new remediation policies are assigned to subscription by Cloudneeti" -ForegroundColor Yellow
}

Write-Host "Script execution completed."