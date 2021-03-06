<#
.SYNOPSIS
    Assign Cloudneeti Data Collector service principal with "Reader" and "Backup Reader" role to Azure Subscriptions.
.DESCRIPTION
    This script helps AzureRM subscription 'owner'/'User Access Administrator' to grant Cloudneeti Data Collector (or provided service principal name in parameters) service principal with "Reader","Backup Reader" permission to Azure Subscriptions.

.NOTES

    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Version:        1.0
    Author:         Cloudneeti
    Creation Date:  08/11/2018
    # PREREQUISITE
    * Windows PowerShell version 5 and above
        1. To check PowerShell version type "$PSVersionTable.PSVersion" in PowerShell and you will find PowerShell version,
	    2. To Install Powershell follow link https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-6
	    
    * AzureRM 6.8.1 or above module installed
	    1. To check AzureRM version type "Get-InstalledModule -Name azureRM" in PowerShell window
	    2. You can Install the required modules by executing below command.
    		Install-Module -Name AzureRM -MinimumVersion 6.8.1
    * Account permissions
        Logged in user must be an 'owner'/'User Access Administrator' of subscriptions
    * if you get error which says "You cannot run this script on the current system." then please run following command 
     "powershell -ExecutionPolicy Bypass"
     
.EXAMPLE
    1. Assign Role to Service Principal
    	.\Assign-RoleToServicePrincipal.ps1 -activeDirectoryId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx -numberOfSubscription <Number>
.INPUTS
	azureActiveDirectoryId [Mandatory]:- Azure Active Directory Id (aka TenantId)
    numberOfSubscription [Mandatory]:- Count of Azure subscriptions to which you need Cloudneeti data collector access
    servicePrincipalName [Optional]:- Service Principal name
                                      Default: CloudneetiDataCollector
	servicePrincipalRoles [Optional] :- Service principal access Role
                                       Default: Reader, Backup Reader
.OUTPUTS	
    OperationStatus:- Table of operation status (Success/Failed)
#>

[CmdletBinding()]
param
(

    # Active Directory Id
    [ValidateNotNullOrEmpty()]
    [Parameter(
        Mandatory = $False,
        HelpMessage = "Enter Azure Active Directory Id",
        Position = 1
    )][guid] $azureActiveDirectoryId = $(Read-Host -prompt "Enter Azure Active Directory Id: "),

    # Number of Subscriptions
    [ValidateNotNullOrEmpty()]
    [Parameter(
        Mandatory = $False,
        HelpMessage = "Enter count of Azure subscriptions to which you need Cloudneeti data collector access",
        Position = 1
    )][int] $numberOfSubscription = $(Read-Host -prompt "Enter count of Azure subscriptions to which you need Cloudneeti data collector access: "),

    # Service Principal Name
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Enter Service Principal Name, Default is set to CloudneetiDataCollector",
        Position = 2
    )][string] $servicePrincipalName = "CloudneetiDataCollector", 

    # Service Principal Access Role
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Enter Service Principal access role (Reader,Backup Reader)",
        Position = 3
    )][string[]] $servicePrincipalRole = @("Reader", "Backup Reader")

)

$ErrorActionPreference = "Stop"

# Check AzureAD Modules and Version
Write-Host "Checking required AzureRM Module is installed on machine or not..."
$azureRMModuleObj = Get-InstalledModule -Name AzureRM
if ($azureRMModuleObj.Version.Major -ge 6 -or $azureRMModuleObj.Version -ge 6) {
    Write-Host "Required AzureRM module already installed" -ForegroundColor "Green"
}
else {
    Write-Host -Message "AzureRM module was found other than the required version 6. Run Below command to Install the AzureAD module and re-run the script"
    Write-Host -Message "Install-Module -Name AzureRM -MinimumVersion 6.8.1" -ForegroundColor Yellow
    exit
}

# Login to Azure Account
Write-Host "Connecting to Azure Account..."
Write-Host "You will be redirected to login screen. Login using account with subscription 'OWNER' or 'USER ACCESS ADMINISTRATOR' permission to proceed..."
try {
    Start-Sleep 2
    Login-AzureRMAccount -TenantId $azureActiveDirectoryId
    $userEmailId = (Get-AzureRmContext).Account.Id
    Write-Host "Connection to Azure Account established successfully." -ForegroundColor "Green"
}
catch {
    Write-Host "Error Details: $_" -ForegroundColor Red
    Write-Host "Error occurred during connecting Azure account. Please try again!!" -ForegroundColor Red
    exit
}

# Check Cloudneeti Service Principal Exists or Not
$servicePrincipal = Get-AzureRmADServicePrincipal -DisplayName $servicePrincipalName

If ([string]::IsNullOrEmpty($servicePrincipal)) {
    Write-Host "$servicePrincipalName service principal doesn't exist in the Azure Active Directory. `nCreate Cloudneeti Data Collector Service principal using Create-ServicePrincipal.ps1 script and re-run the script!!" -ForegroundColor Red
    # Disconnect from Azure Account
    Write-Host "Disconnecting from Azure account."
    Disconnect-AzureRmAccount
    exit
}
Else {

    # Get Azure subscriptionIds from user    
    Write-Host "Enter $numberOfSubscription subscriptions Ids"
    $subscriptions = @()

    for ($i = 1; $i -le $numberOfSubscription; $i++) {
        do {
            try {
                $validSubscriptionId = $true
                [guid]$subscriptionId = Read-host "suscriptionId[$i]"
            } 
            catch {
                Write-Host "Enter valid subscriptionId..."
                $validSubscriptionId = $false
            }
        }
        until ($validSubscriptionId -and ($subscriptionId.GetType() -eq [guid]))
        
        $subscriptions += $subscriptionId
    }

    $operationStatus = @()

    # Assigning all mentioned Permission to subscriptions one by one
    foreach ($subscriptionId in $subscriptions) {
        # Set Subscription Context
        Write-Host "`nSelecting $subscriptionId subscription..."
        try {
            Set-AzureRmContext -SubscriptionId $subscriptionId
            Write-Host "Selected $subscriptionId successfully." -ForegroundColor "Green"
        }
        catch {
            Write-Host "$userEmailId does not have access to subscription '$subscriptionId'." -ForegroundColor Red
            $operationStatusEntry = "" | Select-Object "SubscriptionId", "Status", "Details" 
            $operationStatusEntry.SubscriptionId = $subscriptionId
            $operationStatusEntry.Status = "Failed"
            $operationStatusEntry.Details = "$userEmailId does not have access to subscription '$subscriptionId'."
            $operationStatus += $operationStatusEntry
            continue
        }
         
        foreach ($role in $servicePrincipalRole) {       
            Write-Host "Checking Service Principal '$servicePrincipalName' has '$role' access to $subscriptionId."       
            $SPRole = Get-AzureRmRoleAssignment -RoleDefinitionName $role -Scope "/subscriptions/$subscriptionId" -ObjectId $servicePrincipal.id.guid 
            if (-not ([string]::IsNullOrEmpty($SPRole))) {

                Write-Host "$servicePrincipalName has access to subscription $subscriptionId as $role" -ForegroundColor Yellow          
                $operationStatusEntry = "" | Select-Object "SubscriptionId", "Status", "Details" 
                $operationStatusEntry.SubscriptionId = $subscriptionId
                $operationStatusEntry.Status = "Success"
                $operationStatusEntry.Details = "$servicePrincipalName has access to subscription as $role"                
            } 
            else {
                try {
                    Write-Host "Service Principal '$servicePrincipalName' does not have '$role' role assigned on subscription $subscriptionId " -ForegroundColor Yellow
                    Write-Host "Assigning '$role' role to service principal '$servicePrincipalName' on subscription $subscriptionId..."
                    New-AzureRmRoleAssignment -RoleDefinitionName $role -ApplicationId $servicePrincipal.ApplicationId.Guid -Scope "/subscriptions/$subscriptionId"
                    Write-Host "Assigned '$role' role to service principal '$servicePrincipalName' on subscription $subscriptionId successfully." -ForegroundColor Green
                    $operationStatusEntry = "" | Select-Object "SubscriptionId", "Status", "Details" 
                    $operationStatusEntry.SubscriptionId = $subscriptionId
                    $operationStatusEntry.Status = "Success"
                    $operationStatusEntry.Details = "$servicePrincipalName has been assigned role '$role' on subscription"
                   
                }
                catch {
                    Write-Host "$userEmailId does not have required permissions to assign role '$role' to serviceprincipal '$servicePrincipalName'" -ForegroundColor Red
                    Write-Host "Error Details: $_" -ForegroundColor Red
                    $operationStatusEntry = "" | Select-Object "SubscriptionId", "Status", "Details" 
                    $operationStatusEntry.SubscriptionId = $subscriptionId
                    $operationStatusEntry.Status = "Failed"
                    $operationStatusEntry.Details = "$userEmailId does not have required permissions to assign role '$role' to serviceprincipal"
                    continue
                }
            }
            $operationStatus += $operationStatusEntry
        }
        
        
    }

    Write-Host "-----------------"
    Write-Host "OPERATION SUMMARY"
    Write-Host "-----------------"
    $operationStatus | sort-object Status | Format-Table -AutoSize -GroupBy Status

}

# Disconnect from Azure Account
Write-Host "Disconnecting from Azure account."
Disconnect-AzureRmAccount | Out-Null