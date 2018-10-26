<#
.SYNOPSIS
    Create service principal and assign permission required for Cloudneeti
    
.DESCRIPTION
	This script creates an AD Application, Service Principal, Add Response URL and Grant permission at Subscription or ResourceGroup level. This script requires tenantId and replyUrls as a mandatory input. 
	
.EXAMPLE
    1. Creates a service principal.
    	.\Create-ServicePrincipal.ps1 -tenantId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx -replyURLs "test.com,test1.com" 

    2. Creates a Service Principal with service principal prefix.
		.\Create-ServicePrincipal.ps1 -tenantId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx -replyURLs "test.com,test1.com" -servicePrincipalPrefix "<PrefixN>"

		** Default value is set to cloudneeti
	
    3. Creates a Service Principal with expiry date .
		.\Create-ServicePrincipal.ps1 -tenantId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx -replyURLs "test.com,test1.com" -expirationPeriod <NumberOfYears>

		** Default value is set to 1 year

.INPUTS
	tenantId
	replyURLs
	servicePrincipalPrefix
	expirationPeriod

.OUTPUTS
	
	ApplicationName 
	ApplicationId
	PasswordKey
	PermissionTable

.NOTES
	Pre-requisites to run this script -
    	Required Modules & Version-
			AzureAD  2.0.0.131 and above

    	You can Install the required modules by executing below command.
    		Install-Module -Name AzureAD -MinimumVersion 2.0.0.131

    	Account permissions -
			The account to execute this script must be an Azure AD Account with Global Administrator Permission at Tenant level and Owner permission at Subscription level.
#>

[CmdletBinding()]
param
(

    # Tenant Id
    [Parameter(Mandatory = $true)]
    [guid]
    $tenantId,

    # reply url1.
    [Parameter(Mandatory = $true)]
    [string]
    $replyURLs,

    [Parameter(Mandatory = $false)]
    [string]
	$servicePrincipalPrefix = "cloudneeti",
	
    # Key expiry after how many year
    [Parameter(Mandatory = $false)]
    [int]
    $expirationPeriod = 1  
)

$requiredAccess = @"
{
	"permissionCatergory": [{
			"name": "AzureActiveDirectory",
			"resourceAppId": "00000002-0000-0000-c000-000000000000",
			"rules": [{
					"name": "Manage apps that this app creates or owns",
					"id": "824c81eb-e3f8-4ee6-8f6d-de7f50d565b7",
					"type": "Role"
				},
				{
					"name": "Read and write devices",
					"id": "1138cb37-bd11-4084-a2b7-9f71582aeddb",
					"type": "Role"
				},
				{
					"name": "Read and write domains",
					"id": "abefe9df-d5a9-41c6-a60b-27b38eac3efb",
					"type": "Role"
				},
				{
					"name": "Read all hidden memberships",
					"id": "9728c0c4-a06b-4e0e-8d1b-3d694e8ec207",
					"type": "Role"
				},
				{
					"name": "Read and write directory data",
					"id": "78c8a3c8-a07e-4b9e-af1b-b5ccab50a175",
					"type": "Role"
				},
				{
					"name": "Read all groups",
					"id": "6234d376-f627-4f0f-90e0-dff25c5211a3",
					"type": "Scope"
				},
				{
					"name": "Read hidden memberships",
					"id": "2d05a661-f651-4d57-a595-489c91eda336",
					"type": "Scope"
				},
				{
					"name": "Sign in and read user profile",
					"id": "311a71cc-e848-46a1-bdf8-97ff7156d8e6",
					"type": "Scope"
				},
				{
					"name": "Read all user basic profiles",
					"id": "cba73afc-7f69-4d86-8450-4978e04ecd1a",
					"type": "Scope"
				},
				{
					"name": "Read all users full profiles",
					"id": "c582532d-9d9e-43bd-a97c-2667a28ce295",
					"type": "Scope"
				},
				{
					"name": "Read directory data",
					"id": "5778995a-e1bf-45b8-affa-663a9f3f4d04",
					"type": "Scope"
				},
				{
					"name": "Access the directory as the signed-in user",
					"id": "a42657d6-7f20-40e3-b6f0-cee03008a62a",
					"type": "Scope"
				}
			]
		},
		{
			"name": "WindowsAzureServiceManagement",
			"resourceAppId": "797f4846-ba00-4fd7-ba43-dac1f8f63013",
			"rules": {
				"name": "Access Azure Service Management as organization users (preview)",
				"id": "41094075-9dad-400e-a0bd-54e686782033",
				"type": "Scope"
			}
		},
		{
			"name": "AzureKeyVault",
			"resourceAppId": "cfa8b339-82a2-471a-a3c9-0fc0be7a4093",
			"rules": {
				"name": "Have full access to the Azure Key Vault service",
				"id": "f53da476-18e3-4152-8e01-aec403e6edc0",
				"type": "Scope"
			}
		},
		{
			"name": "microsoftGraph",
			"resourceAppId": "00000003-0000-0000-c000-000000000000",
			"rules": [{
					"name": "Read all usage reports",
					"id": "230c1aed-a721-4c5d-9cb4-a90514e508ef",
					"type": "Role"
				},
				{
					"name": "Read all groups",
					"id": "5b567255-7703-4780-807c-7be8301ae99b",
					"type": "Role"
				},
				{
					"name": "Read directory data",
					"id": "7ab1d382-f21e-4acd-a863-ba3e13f7da61",
					"type": "Role"
				},
				{
					"name": "Read all hidden memberships",
					"id": "658aa5d8-239f-45c4-aa12-864f4fc7e490",
					"type": "Role"
				},
				{
					"name": "Read all users full profiles",
					"id": "df021288-bdef-4463-88db-98f22de89214",
					"type": "Role"
				},
				{
					"name": "Read all identity risk event information",
					"id": "6e472fd1-ad78-48da-a0f0-97ab2c6b769e",
					"type": "Role"
				},
				{
					"name": "Read files in all site collections",
					"id": "01d4889c-1287-42c6-ac1f-5d1e02578ef6",
					"type": "Role"
				},
				{
					"name": "Read user and shared contacts",
					"id": "242b9d9e-ed24-4d09-9a52-f43769beb9d4",
					"type": "Scope"
				},
				{
					"name": "Sign in and read user profile",
					"id": "e1fe6dd8-ba31-4d61-89e7-88639da4683d",
					"type": "Scope"
				},
				{
					"name": "Read all users basic profiles",
					"id": "b340eb25-3456-403f-be2f-af7a0d370277",
					"type": "Scope"
				},
				{
					"name": "Read and write all groups",
					"id": "4e46008b-f24c-477d-8fff-7bb4ec7aafe0",
					"type": "Scope"
				},
				{
					"name": "Access directory as the signed in user",
					"id": "0e263e50-5827-48a4-b97c-d940288653c7",
					"type": "Scope"
				},
				{
					"name": "Read user contacts ",
					"id": "ff74d97f-43af-4b68-9f2a-b77ee6968c5d",
					"type": "Scope"
				},
				{
					"name": "Read user files",
					"id": "10465720-29dd-4523-a11a-6a75c743c9d9",
					"type": "Scope"
				},
				{
					"name": "Sign users in",
					"id": "37f7f235-527c-4136-accd-4a02d197296e",
					"type": "Scope"
				},
				{
					"name": "Access users data anytime",
					"id": "7427e0e9-2fba-42fe-b0c0-848c9e6a8182",
					"type": "Scope"
				},
				{
					"name": "View users email address",
					"id": "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0",
					"type": "Scope"
				},
				{
					"name": "View users basic profile",
					"id": "14dad69e-099b-42c9-810b-d002981feec1",
					"type": "Scope"
				},
				{
					"name": "Read identity risk event information",
					"id": "8f6a01e7-0391-4ee5-aa22-a3af122cef27",
					"type": "Scope"
				},
				{
					"name": "Read all usage reports",
					"id": "02e97553-ed7b-43d0-ab3c-f8bace0d040c",
					"type": "Scope"
				},
				{
					"name": "Read all users full profiles",
					"id": "a154be20-db9c-4678-8ab7-66f6cc099a59",
					"type": "Scope"
				},
				{
					"name": "Read all groups",
					"id": "5f8c59db-677d-491f-a6b8-5f174b11ec1d",
					"type": "Scope"
				},
				{
					"name": "Read directory data",
					"id": "06da0dbc-49e2-44d2-8312-53f166ab848a",
					"type": "Scope"
				}
			]
		}
	]
}
"@


# Check AzureAD Modules and Version
Write-Verbose "Checking if AzureAD Module is installed."
$azureADModuleObj = Get-InstalledModule -Name AzureAD
if ($azureADModuleObj.Version.Major -eq '2') {
    Write-Output "Required AzureAD module already installed"
}
else {
    Write-Warning -Message "AzureAD module was found other than the required version - 2. If deployment fails, try installing required module version and run the script."
    Write-Information -Message "Install-Module -Name AzureAD -MinimumVersion 2.0.0.131"
    exit
}

# Assigning scope and role using Microsoft object guids.
Write-Host "Connecting to AzureAD to assign read directory data permission to AAD application"
try {
    $userEmailID = (Connect-AzureAD -TenantId $tenantId).Account.Id
	Write-Verbose "Connection to AzureAD established."
}
catch {
	Write-Error $_
	Write-Error -Message "Error occured during connecting AzureAD. Please try again"
	exit
}

# Check if login user is global Admin
 try {
	$isGlobalAdmin = $false
	$memberUser = $userEmailID
	$guestUser = $($userEmailID -replace '@','_') + "#EXT*"

    $role = Get-AzureADDirectoryRole | Where-Object {$_.displayName -eq 'Company Administrator'}
	Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId | ForEach-Object {
		if($_.UserPrincipalName -like $memberUser -or $_.UserPrincipalName -like $guestUser)
		{
			 $isGlobalAdmin = $true
			 Write-Verbose -Message "User is global Admin"
		}
	}
 }
 catch {
    $isGlobalAdmin = $false
 }
 if(!$isGlobalAdmin){
	Write-Warning "Logged in user $AADGlobalAdminUser is not global AD administrator, Please login using global administrator account"
	
	# Disconnect from Azure AD 
	Write-Verbose -Message "Disconnecting from AzureAD."
	Disconnect-AzureAD
    exit
 }

# Defining variables required for service principal
$servicePrincipalName = "$servicePrincipalPrefix-$TenantId"
$aadHomePage = 'https://' + $servicePrincipalName + '.com'
$urls = $replyURLs.split(',') | foreach { 'https://' + $_}

# Create Password Object
$Guid = New-Guid
$startDate = Get-Date     
$passwordCreds = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordCredential
$passwordCreds.StartDate = $startDate
$passwordCreds.EndDate = $startDate.AddYears($expirationPeriod).ToUniversalTime()
$passwordCreds.KeyId = $Guid
$passwordCreds.Value = ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($Guid))))+"="

# Creating AAD Application and Service Principal
Write-Host "Creating AAD application with name: " $servicePrincipalName -ForegroundColor "yellow"
$adApp = New-AzureADApplication -DisplayName $servicePrincipalName -HomePage $aadHomePage -IdentifierUris $aadHomePage -ReplyUrls $urls -PasswordCredentials $passwordCreds

# Create Service Principal
$adServicePrincipal = New-AzureADServicePrincipal -AccountEnabled $true -AppId $adApp.AppId -AppRoleAssignmentRequired $true -DisplayName $servicePrincipalName

Write-Host  $servicePrincipalName "AAD application created successfully" -ForegroundColor "Green"

# Creating AD permission object
$requiredAccessObj = ConvertFrom-Json $requiredAccess
$resourceAccessCategory = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.RequiredResourceAccess]

$permissionTable = @() 
ForEach($category in $requiredAccessObj.permissionCatergory) {
	
	# Process Rule Info
	$applicationPermissionCount = 0
	$delegatedPermissionCount = 0
	$category.rules | ForEach { 
		$_.PSObject.Properties.Remove('name') 
		if($_.type -eq 'Role') { 
			$applicationPermissionCount += 1 
		}
		else {
			$delegatedPermissionCount += 1 		
		}
	}
	
	$resourceAccessObj = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
    $resourceAccessObj.ResourceAppId = $category.resourceAppId
    $resourceAccessObj.ResourceAccess = $category.rules

	$resourceAccessCategory.Add($resourceAccessObj) > $null

	# Count the Permission
	$permissionCountEntry = "" | select "API", "ApplicationPermissions", "DelegatedPermissions"
	$permissionCountEntry.API = $category.name
	$permissionCountEntry.ApplicationPermissions = $applicationPermissionCount
	$permissionCountEntry.DelegatedPermissions = $delegatedPermissionCount
	$permissionTable += $permissionCountEntry
}

Write-Host "Setting up the required permissions on AD"
try {
    Set-AzureADApplication -ObjectId $adApp.ObjectId -RequiredResourceAccess $resourceAccessCategory
}
catch {
	Write-Error $_
	Write-Error -Message "Error occurred during permission setting on AD. Please try again"
	# Disconnect from Azure AD 
	Write-Verbose -Message "Disconnecting from AzureAD."
	Disconnect-AzureAD
	exit
}

# Disconnect from Azure AD 
Write-Verbose -Message "Disconnecting from AzureAD."
Disconnect-AzureAD

# Script Outputs
Write-Warning -Message "Please store the output information below as it will be lost once the session is closed."

Write-Host "ApplicationName : $servicePrincipalName"
Write-Host "ApplicationId :" $adApp.AppId
Write-Host "PasswordKey :" $passwordCreds.Value

Write-Host "
Go to portal and perform below steps
1. Confirm the permission on service principal given below
2. Press Grant Permission Button

Permission Table
----------------"
$permissionTable | Format-Table -AutoSize