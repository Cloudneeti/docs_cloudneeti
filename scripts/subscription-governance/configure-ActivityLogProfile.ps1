<#
.SYNOPSIS
    Script to configure activity log profile at subscription level

.DESCRIPTION
    This script helps to configure activity log profile at subscription level

.NOTES

    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Version:        1.0
    Author:         Cloudneeti
    Creation Date:  15/10/2019
	
	- This script needs to run inside Azure Cloud Shell.
    - Only one activity log profile supported by Azure at subsription level. We are not creating any activity log profile in case if already exists.


.EXAMPLE
	1. Configure ActivityLogProfile at subscription level
		.\configure-ActivityLogProfile.ps1 `
				-SubscriptionId <SubscriptionId> `
				-ResourceGroupName <ResourceGroupName> `
				-StorageAccountName <StorageAccountName> `
				-StorageAccountSku <StorageAccountSku> `
				-Location <Location>

	2. Configure ActivityLogProfile at subscription level with tags
		.\configure-ActivityLogProfile.ps1 `
				-SubscriptionId <SubscriptionId> `
				-ResourceGroupName <ResourceGroupName> `
				-StorageAccountName <StorageAccountName> `
				-StorageAccountSku <StorageAccountSku> `
				-Location <Location> `
				-ApplicationOwnerTag <ApplicationOwnerTag> `
				-ServiceNameTag <ServiceNameTag> `
				-BusinessUnitTag <BusinessUnitTag> `
				-ProjectOwnerTag <ProjectOwnerTag> `
				-ApplicationTag <ApplicationTag> `
				-DepartmentTag <DepartmentTag> `
				-ProjectNameTag <ProjectNameTag> `
				-CostCenterTag <CostCenterTag> `
				-DataProfileTag <DataProfileTag>

.INPUTS
    SubscriptionId: Id of Subscription where the resources to be deployed
    ResourceGroupName: Name of the resource group
	StorageAccountName: Name of the storage account
	SKUName: Storage account SKU (Standard_RAGRS, Standard_GRS, Standard_LRS)
	Location: Location  
	ApplicationOwnerTag: Tag for application owner
	ServiceNameTag: Tag for service name
	BusinessUnitTag: Tag for business unit
	ProjectOwnerTag: Tag for application owner
	ApplicationTag: Tag for application 
	DepartmentTag: Tag for department
	ProjectNameTag: Tags for project name
	CostCenterTag: Tags for cost center
	DataProfileTag: Tags for data profile 
	
.OUTPUTS
    Creation of log retention storage account
	Configure Activity log profile

#>

[CmdletBinding()]
param
(
    # Enter Subscription Id for deployment.
    [Parameter(Mandatory = $true)]
    [Alias("Subscription")]
    [guid]
    $SubscriptionId,
    
    # Enter resource group name.
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName,

    # Enter storage account name.
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountName,

    # Storage account SKU	
    [Parameter(Mandatory = $false)]
    [ValidateSet("Standard_RAGRS", "Standard_GRS", "Standard_LRS")]
	[string]
    $StorageAccountSku = "Standard_GRS",

    # Enter Location for deployment.
    [Parameter(Mandatory = $false)]
    [string]
    $Location = "eastus",

    # Enter Application Owner Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $ApplicationOwnerTag,

    # Enter Service Name Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $ServiceNameTag = "activity-log-profile",

    # Enter Business Unit Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $BusinessUnitTag = "Governance",

    # Enter Project Owner Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $ProjectOwnerTag,

    # Enter Application Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $ApplicationTag = "activity-alert",

    # Enter Department Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $DepartmentTag = "Governance",
    
    # Enter Project Name Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $ProjectNameTag = "Governance",

    # Enter Cost Center Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $CostCenterTag = "NA",

    # Enter Data Profile Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $DataProfileTag = "log-retention"
)

# Setting session variables
$ErrorActionPreference = "Stop"
$WarningPreference = "SilentlyContinue"

# Initializing variables
$Subsciptions = $null
$AccountUser = $null

# Checking current az context to deploy Azure automation
Write-Host "Getting Azure Context ..."
$AzureContext = Get-AzContext
If ($AzureContext.Subscription.Id -ne $SubscriptionId) {
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
Write-Host "Azure Context retrived successfully."

# Getting Azure Log Profile
try
{
    Write-Host "Checking existing activity log profile"
	$ExistingProfile = Get-AzLogProfile
    if($null -ne $ExistingProfile){
		Write-Host "Activity log profile already exists in subscription $subscriptionId" -foregroundcolor Yellow
		Write-Host "Skipping creation of log profile."  
		Exit
	}
	Write-Host "Activity log profile doesn't exist, creating new activity profile..." -foregroundcolor Green
}
catch [Exception] {
    Write-Host "Error occurred while getting existing activity log profile, please try again in sometime..." -foregroundcolor red
	Write-Host $_
	Exit
}

# Getting log retention storage account
Write-Host "Checking log retention storage account ..."
try{
    $LogRetentionStorage = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if($null -eq $LogRetentionStorage){
        Write-Host "Storage Account $StorageAccountName Not Found" -ForegroundColor Red
        
		# Create resource group for log retention storage account
		Get-AzResourceGroup -Name $ResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
		if ($notPresent) {
			# Creating resource group
			Write-Host "Creating new $ResourceGroupName resource group"
			New-AzResourceGroup -Name $ResourceGroupName -Location $Location
		}
		
		# Create storage account for log retention 
		Write-Host "Creating new storage account $StorageAccountName for log retention"
		# Create the storage account.
		$LogRetentionStorage = New-AzStorageAccount -ResourceGroupName $ResourceGroupName `
											   -Name $StorageAccountName `
											   -Location $Location `
											   -SkuName $StorageAccountSku `
											   -ErrorAction SilentlyContinue
		if($null -ne $LogRetentionStorage) {
			Write-Host "Successfully created new storage account $StorageAccountName for log retention"
		}
		else {
		    Write-Host "Error occurred while creating log retention storage account, please try again with different storage account name..." -foregroundcolor red
			Exit
		}
    }
	Write-Host "Successfully retrived log retention storage account $StorageAccountName" -foregroundcolor Green
}
catch [Exception] {
    Write-Host "Error occurred while getting Storage Account, please try again after sometime" -foregroundcolor red
    Write-Host $_
	Exit
}

# Extracting User Name
$azureProfiles = Get-Content -path "./.azure/azureProfile.json" | ConvertFrom-Json
$subsciption = $azureProfiles.subscriptions | Where-Object { $_.id -eq $subscriptionId }
if($null -ne $subsciption) {
	$AccountUser = $Subsciption.user.name
	if($ProjectOwnerTag -eq ''){
		$ProjectOwnerTag = $Subsciption.user.name
	}
	if($ApplicationOwnerTag -eq ''){
		$ApplicationOwnerTag = $Subsciption.user.name
	}
}

$tags = @{      
			"ApplicationOwner"= $ApplicationOwnerTag
			"ServiceName"= $ServiceNameTag
			"DeployedBy"= $AccountUser
			"BusinessUnit"= $BusinessUnitTag
			"ProjectOwner"= $ProjectOwnerTag
			"Application"= $ApplicationTag
			"Description"= "Activity Log Profile"
			"Department"= $DepartmentTag
			"ProjectName" = $ProjectNameTag
			"CostCenter"= $CostCenterTag
			"DataProfile"= $DataProfileTag
        }

# Setting log up tags, https and replication configuration on log retention storage account
try{
    Write-Host "Updating tags, https and replication configuration of $StorageAccountName storage account ..."
    $LogRetentionStorage = Set-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupName -SkuName $StorageAccountSku -EnableHttpsTrafficOnly $true -Tag $tags -ErrorAction Stop
    Write-Host "Successfully updated tags, https and replication configuration of $StorageAccountName storage account." -foregroundcolor Green
}
catch [Exception] {
    Write-Host "Error occurred while setting up tags, https and replication configuration on log retention storage account." -foregroundcolor red
	Write-Host "Please check error message and try again." -foregroundcolor red
    Write-Host $_
	Exit
}

# Getting all Activity Log Location for Azure Log Profile
try{
    Write-Host "Getting all Activity Log Location for Azure Log Profile ..."
    $activityLogLocation = (Get-AzLocation).Location
    $activityLogLocation += "Global"
}
catch [Exception]{
    Write-Host "Error occurred while getting all Activity Log Location" -ForegroundColor Red
    Write-Host $_
}

# Creating Azure Log Profile
try{
    Write-Host "Creating Azure Log Profile..." -ForegroundColor Cyan
    Add-AzLogProfile -Location $activityLogLocation -Name "ActivityLogProfile" `
        -StorageAccountId $LogRetentionStorage.Id `
        -RetentionInDays 365
    Write-Host "Azure Log Profile Created Successfully." -ForegroundColor Green
}
catch [Exception] {
    Write-Host "Error occurred while Creating Azure Log Profile, Please check the error logs and try again in sometime" -foregroundcolor red
    Write-Host $_
}

Write-Host "Script execution completed." -ForegroundColor Yellow