<#
.SYNOPSIS
    Create service principal and assign permission required for Cloudneeti applications
    
.DESCRIPTION
	This script creates an Active Directory Application, Service Principal and setup the permission required for Cloudneeti application.
    This script requires activeDirectoryId and replyUrl as a mandatory input.
 
.NOTES
    Version:        1.0
    Author:         Cloudneeti
    Creation Date:  08/11/2018

    # PREREQUISITE

    * Windows PowerShell version 5 and above
        1. To check PowerShell version type "$PSVersionTable.PSVersion" in PowerShell and you will find PowerShell version,
	    2. To Install powershell follow link https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-6
	    
    * AzureAD 2.0.0.131 or above module installed
	    1. To check Azure AD version type "Get-InstalledModule -Name azureAD" in PowerShell window
	    2. You can Install the required modules by executing below command.
    		Install-Module -Name AzureAD -MinimumVersion 2.0.0.131

    * Account permissions
		The script must be executed with Global AD Administrator account

.EXAMPLE
    1. Creates a service principal.
    	.\Create-ServicePrincipal.ps1 -activeDirectoryId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx -replyURL <URL> 

    2. Creates a Service Principal with service principal name.
		.\Create-ServicePrincipal.ps1 -activeDirectoryId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx -replyURL <URL> -servicePrincipalName <CloudneetiDataCollector>

    3. Creates a Service Principal with the expiry date.
		.\Create-ServicePrincipal.ps1 -activeDirectoryId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx -replyURL <URL> -expirationPeriod <1year, 2year, NeverExpires>

.INPUTS
	azureActiveDirectoryId [Mandatory]:- Azure Active Directory Id (aka TenantId)

    replyURLs [Mandatory]:- Cloudneeti application URL, where the response will be sent after login

    servicePrincipalName [Optional]:- Service Principal name
                                      Default: CloudneetiDataCollector

	expirationPeriod [Optional]:- Service principal key will get expire after this duration.
                                   Default: 1 year
                                   Available Values: 1year, 2year, NeverExpires

.OUTPUTS	
	ApplicationName:- Active Directory application Name
	ApplicationId:- Active Directory application Id
	Password Key Description:- Key Name
	Password Key:- Key Value
    Password Key Expiration Duration:- Key Expiry Duration 

    PermissionTable:- 'Application Permissions' and 'Delegated Permissions' count with respect to 'API'

#>


[CmdletBinding()]
param
(

    # Active Directory Id
    [ValidateNotNullOrEmpty()]
	[Parameter(
		Mandatory=$False,
		HelpMessage="Enter Azure Active Directory Id",
		Position=1
	)][guid] $azureActiveDirectoryId = $(Read-Host -prompt "Enter Azure Active Directory Id: "),


    # Reply URL
	[ValidateScript( {$_ -notmatch 'https://+' -and $_ -notmatch 'http://+' -and $_ -match '[a-zA-Z0-9]+'})]
    [ValidateNotNullOrEmpty()]
    [Parameter(
        Mandatory = $False, 
        HelpMessage="Enter Cloudneeti Reply URL", 
        Position=2
    )][string] $replyURL = $(Read-Host -prompt "Enter Cloudneeti Reply URL: "),

    # Service Principal Name
	[Parameter(
        Mandatory = $False,
        HelpMessage="Enter Service Principal Name, Default is set to CloudneetiDataCollector",
        Position=3
    )][string] $servicePrincipalName = "CloudneetiDataCollector", 

    # Key expiry after how many year
    [ValidateSet("1year","2years","NeverExpires")]
	[Parameter(
        Mandatory = $False,
        HelpMessage="Enter Service Principal Expiry Period, Valid values are 1year, 2years, NeverExpires",
        Position=4
    )][string] $expirationPeriod = "1year"

)

$ErrorActionPreference = "Stop"

$requiredAccess = @"
{  
    "permissionCatergory":[  
       {  
          "name":"AzureActiveDirectory",
          "resourceAppId":"00000002-0000-0000-c000-000000000000",
          "rules":[  
             {  
                "name":"Read and write devices",
                "id":"1138cb37-bd11-4084-a2b7-9f71582aeddb",
                "type":"Role"
             },
             {  
                "name":"Read directory data",
                "id":"5778995a-e1bf-45b8-affa-663a9f3f4d04",
                "type":"Role"
             },
             {  
                "name":"Read and write domains",
                "id":"abefe9df-d5a9-41c6-a60b-27b38eac3efb",
                "type":"Role"
             },
             {  
                "name":"Sign in and read user profile",
                "id":"311a71cc-e848-46a1-bdf8-97ff7156d8e6",
                "type":"Scope"
             },
             {  
                "name":"Read all users basic profiles",
                "id":"cba73afc-7f69-4d86-8450-4978e04ecd1a",
                "type":"Scope"
             },
             {  
                "name":"Read all users full profiles",
                "id":"c582532d-9d9e-43bd-a97c-2667a28ce295",
                "type":"Scope"
             },
             {  
                "name":"Access the directory as the signed-in user",
                "id":"a42657d6-7f20-40e3-b6f0-cee03008a62a",
                "type":"Scope"
             },
             {  
                "name":"Read hidden memberships",
                "id":"2d05a661-f651-4d57-a595-489c91eda336",
                "type":"Scope"
             },
             {  
                "name":"Read all groups",
                "id":"6234d376-f627-4f0f-90e0-dff25c5211a3",
                "type":"Scope"
             },
             {  
                "name":"Read directory data",
                "id":"5778995a-e1bf-45b8-affa-663a9f3f4d04",
                "type":"Scope"
             }
          ]
       },
       {  
          "name":"WindowsAzureServiceManagement",
          "resourceAppId":"797f4846-ba00-4fd7-ba43-dac1f8f63013",
          "rules":{  
             "name":"Access Azure Service Management as organization users (preview)",
             "id":"41094075-9dad-400e-a0bd-54e686782033",
             "type":"Scope"
          }
       },
       {  
          "name":"AzureKeyVault",
          "resourceAppId":"cfa8b339-82a2-471a-a3c9-0fc0be7a4093",
          "rules":{  
             "name":"Have full access to the Azure Key Vault service",
             "id":"f53da476-18e3-4152-8e01-aec403e6edc0",
             "type":"Scope"
          }
       },
       {  
          "name":"microsoftGraph",
          "resourceAppId":"00000003-0000-0000-c000-000000000000",
          "rules":[  
             {  
                "name":"Read all identity risky user information",
                "id":"dc5007c0-2d7d-4c42-879c-2dab87571379",
                "type":"Role"
             },
             {  
                "name":"Read all usage reports",
                "id":"230c1aed-a721-4c5d-9cb4-a90514e508ef",
                "type":"Role"
             },
             {  
                "name":"Read all audit log data",
                "id":"b0afded3-3588-46d8-8b3d-9842eff778da",
                "type":"Role"
             },
             {  
                "name":"Read your organization?s security events",
                "id":"bf394140-e372-4bf9-a898-299cfc7564e5",
                "type":"Role"
             },
             {  
                "name":"Read all user mailbox settings",
                "id":"40f97065-369a-49f4-947c-6a255697ae91",
                "type":"Role"
             },
             {  
                "name":"Read all hidden memberships",
                "id":"658aa5d8-239f-45c4-aa12-864f4fc7e490",
                "type":"Role"
             },
             {  
                "name":"Read directory data",
                "id":"7ab1d382-f21e-4acd-a863-ba3e13f7da61",
                "type":"Role"
             },
             {  
                "name":"Read all users' full profiles",
                "id":"df021288-bdef-4463-88db-98f22de89214",
                "type":"Role"
             },
             {  
                "name":"Read all identity risk event information",
                "id":"6e472fd1-ad78-48da-a0f0-97ab2c6b769e",
                "type":"Role"
             },
             {  
                "name":"Read all groups",
                "id":"5b567255-7703-4780-807c-7be8301ae99b",
                "type":"Role"
             },
             {  
                "name":"Read identity risky user information",
                "id":"d04bb851-cb7c-4146-97c7-ca3e71baf56c",
                "type":"Scope"
             },
             {  
                "name":"Read your organization's policies",
                "id":"572fea84-0151-49b2-9301-11cb16974376",
                "type":"Scope"
             },
             {  
                "name":"Read audit log data",
                "id":"e4c9e354-4dc5-45b8-9e7c-e1393b0b1a20",
                "type":"Scope"
             },
             {  
                "name":"Read your organization?s security events",
                "id":"64733abd-851e-478a-bffb-e47a14b18235",
                "type":"Scope"
             },
             {  
                "name":"Read user mailbox settings",
                "id":"87f447af-9fa4-4c32-9dfa-4a57a73d18ce",
                "type":"Scope"
             },
             {  
                "name":"Read all usage reports",
                "id":"02e97553-ed7b-43d0-ab3c-f8bace0d040c",
                "type":"Scope"
             },
             {  
                "name":"Sign in and read user profile",
                "id":"e1fe6dd8-ba31-4d61-89e7-88639da4683d",
                "type":"Scope"
             },
             {  
                "name":"Read all users' basic profiles",
                "id":"b340eb25-3456-403f-be2f-af7a0d370277",
                "type":"Scope"
             },
             {  
                "name":"Read all users' full profiles",
                "id":"a154be20-db9c-4678-8ab7-66f6cc099a59",
                "type":"Scope"
             },
             {  
                "name":"Read directory data",
                "id":"06da0dbc-49e2-44d2-8312-53f166ab848a",
                "type":"Scope"
             },
             {  
                "name":"Access directory as the signed in user",
                "id":"0e263e50-5827-48a4-b97c-d940288653c7",
                "type":"Scope"
             },
             {  
                "name":"Read user contacts ",
                "id":"ff74d97f-43af-4b68-9f2a-b77ee6968c5d",
                "type":"Scope"
             },
             {  
                "name":"Sign users in",
                "id":"37f7f235-527c-4136-accd-4a02d197296e",
                "type":"Scope"
             },
             {  
                "name":"Access user's data anytime",
                "id":"7427e0e9-2fba-42fe-b0c0-848c9e6a8182",
                "type":"Scope"
             },
             {  
                "name":"View users' email address",
                "id":"64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0",
                "type":"Scope"
             },
             {  
                "name":"View users' basic profile",
                "id":"14dad69e-099b-42c9-810b-d002981feec1",
                "type":"Scope"
             },
             {  
                "name":"Read identity risk event information",
                "id":"8f6a01e7-0391-4ee5-aa22-a3af122cef27",
                "type":"Scope"
             },
             {  
                "name":"Read user and shared contacts",
                "id":"242b9d9e-ed24-4d09-9a52-f43769beb9d4",
                "type":"Scope"
             },
             {  
                "name":"Read all groups",
                "id":"5f8c59db-677d-491f-a6b8-5f174b11ec1d",
                "type":"Scope"
             }
          ]
       },
       {  
          "name":"Office365ExchangeOnline",
          "resourceAppId":"00000002-0000-0ff1-ce00-000000000000",
          "rules":[  
             {  
                "name":"Read all users' full profiles",
                "id":"eb665d05-7f76-4d1b-b176-1cfc814e668d",
                "type":"Scope"
             },
             {  
                "name":"Read all users' basic profiles",
                "id":"9b005f11-86f0-45f7-8c27-4fff5d849916",
                "type":"Scope"
             },
             {  
                "name":"Read user profiles",
                "id":"6223a6d3-53ef-4f8f-982a-895b39483c61",
                "type":"Scope"
             },
             {  
                "name":"Read all users' basic profiles",
                "id":"6222dbab-a24c-4210-9d91-2f47cf565614",
                "type":"Scope"
             }
          ]
       },
       {  
          "name":"Office365ManagementAPIs",
          "resourceAppId":"c5393580-f805-4401-95e8-94b7a6ef2fc2",
          "rules":[  
             {  
                "name":"Read activity reports for your organization",
                "id":"825c9d21-ba03-4e97-8007-83f020ff8c0f",
                "type":"Scope"
             },
             {  
                "name":"Read threat intelligence data for your organization",
                "id":"69784729-33e3-471d-b130-744ce05343e5",
                "type":"Scope"
             },
             {  
                "name":"Read activity reports for your organization",
                "id":"b3b78c39-cb1d-4d17-820a-25d9196a800e",
                "type":"Scope"
             },
             {  
                "name":"Read activity data for your organization",
                "id":"594c1fb6-4f81-4475-ae41-0c394909246c",
                "type":"Scope"
             },
             {  
                "name":"Read service health information for your organization",
                "id":"e2cea78f-e743-4d8f-a16a-75b629a038ae",
                "type":"Scope"
             }
          ]
       },
       {  
          "name":"Office365SharePointOnline",
          "resourceAppId":"00000003-0000-0ff1-ce00-000000000000",
          "rules":{  
             "name":"Read user profiles",
             "id":"0cea5a30-f6f8-42b5-87a0-84cc26822e02",
             "type":"Scope"
          }
       }
    ]
 }
"@

# Key Expiry
$keyExpirationPeriod = @{
    "1year" = 1
    "2years" = 2
    "NeverExpires" = 99
}

# Check AzureAD Modules and Version
Write-Host "Checking required AzureAD Module is installed on machine or not..."
$azureADModuleObj = Get-InstalledModule -Name AzureAD
if ($azureADModuleObj.Version.Major -ge 2 -or $azureADModuleObj.Version -ge 2) {
    Write-Host "Required AzureAD module already installed" -ForegroundColor "Green"
}
else {
    Write-Host -Message "AzureAD module was found other than the required version 2. Run Below command to Install the AzureAD module and re-run the script"
    Write-Host -Message "Install-Module -Name AzureAD -MinimumVersion 2.0.0.131" -ForegroundColor Yellow
    exit
}


# Login to Azure Active Directory
Write-Host "Connecting to Azure Active Directory..."
Write-Host "You will be redirected to login screen. Login using Global AD administrator account to proceed..."
try {
    Start-Sleep 2
    $userEmailID = (Connect-AzureAD -TenantId $azureActiveDirectoryId).Account.Id
	Write-Host "Connection to Azure Active Directory established successfully." -ForegroundColor "Green"
}
catch {
	Write-Host "Error Details: $_" -ForegroundColor Red
	Write-Host "Error occurred during connecting Azure active directory. Please try again!!" -ForegroundColor Red
	exit
}


# Check if login user is global Admin
Write-Host "Checking Logged In user $userEmailID is Global AD Administrator or not..."
try {
	$isGlobalAdmin = $false
	$memberUser = $userEmailID
	$guestUser = $($userEmailID -replace '@','_') + "#EXT*"

    $role = Get-AzureADDirectoryRole | Where-Object {$_.displayName -eq 'Company Administrator'}
	Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId | ForEach-Object {
		if($_.UserPrincipalName -like $memberUser -or $_.UserPrincipalName -like $guestUser)
		{
			 $isGlobalAdmin = $true
			 Write-Host "Logged in User $userEmailID is global AD administrator" -ForegroundColor "Green"
		}
	}
 }
 catch {
    $isGlobalAdmin = $false
 }

 if(!$isGlobalAdmin){
	Write-Host "Logged in user $userEmailID is not global AD administrator, Please re-run the script using global AD administrator account"
	# Disconnect from Azure AD 
	Write-Host "Disconnecting from Azure Active Directory."
	Disconnect-AzureAD
    exit
 }

# Check Cloudneeti Service Principal Exists or Not
$servicePrincipal = Get-AzureADServicePrincipal -SearchString $servicePrincipalName
 
If([string]::IsNullOrEmpty($servicePrincipal))
{

	$aadHomePage = 'https://' + $servicePrincipalName + '.com'
	$urls = @("https://$replyURL","https://$replyURL/Account/SignIn")

    try
    {
        # Creating AAD Application and Service Principal
	    Write-Host "Creating service principal $servicePrincipalName..."
	 
	    $adApp = New-AzureADApplication -DisplayName $servicePrincipalName -HomePage $aadHomePage -IdentifierUris $aadHomePage -ReplyUrls $urls	
	    $keyIdentifier = "CloudneetiKey-" + -join ((48..57) + (97..122) | Get-Random -Count 5 | % {[char]$_})
	
        $keyExpiry = $keyExpirationPeriod[$expirationPeriod]

        $EndDate = (Get-Date).AddYears($keyExpiry).ToUniversalTime()
	    $passwordCreds = New-AzureADApplicationPasswordCredential -ObjectId $adApp.ObjectId -CustomKeyIdentifier $keyIdentifier -EndDate $EndDate

	    # Create Service Principal
	    $adServicePrincipal = New-AzureADServicePrincipal -AccountEnabled $true -AppId $adApp.AppId -AppRoleAssignmentRequired $true -DisplayName $servicePrincipalName

	    Write-Host "Service principal $servicePrincipalName created successfully." -ForegroundColor "Green"
    }
    catch {
        Write-Host "Error Details: $_" -ForegroundColor Red
	    Write-Host "Error occurred during service principal $servicePrincipalName creation. Please try again!!" -ForegroundColor Red
        # Disconnect from Azure AD 
		Write-Host "`nDisconnecting from AzureAD."
		Disconnect-AzureAD
	    exit
    }
    

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

	Write-Host "Setting up the required permissions on active directory application..."
	try {
		Set-AzureADApplication -ObjectId $adApp.ObjectId -RequiredResourceAccess $resourceAccessCategory
    	Write-Host "Required permission on $servicePrincipalName active directory application setup successfully." -ForegroundColor "Green"
	}
	catch {
        Write-Host "Error Details: $_" -ForegroundColor Red
		Write-Host "Error occurred during setting up permissions on $servicePrincipalName active directory application. Please try again" -ForegroundColor Red
		# Disconnect from Azure AD 
		Write-Host "`nDisconnecting from AzureAD."
		Disconnect-AzureAD
		exit
	}

    Write-Host "`nPerform following Steps,`n"

    Write-Host "-------------------------------------------"
    Write-Host "STEP 1: STORE SERVICE PRINCIPAL INFORMATION" 
    Write-Host "-------------------------------------------"
	Write-Host "ApplicationName : $servicePrincipalName" -ForegroundColor "Green"
	Write-Host "ApplicationId :" $adApp.AppId -ForegroundColor "Green"
	Write-Host "Password Key Description : $keyIdentifier" -ForegroundColor "Green"
	Write-Host "Password Key :" $passwordCreds.Value -ForegroundColor "Green"	
    Write-Host "Password Key Expiry Duration: $expirationPeriod`n" -ForegroundColor "Green"

    Write-Warning -Message "`nStore the above information in secure place. You won't be able to retrieve after you close the Powershell window."

    Write-Host "---------------------------"
    Write-Host "STEP 2: CONFIRM PERMISSIONS"
    Write-Host "---------------------------"
    Write-Host "1. Login to Azure Portal"
    Write-Host "2. Click on Azure Active Directory"
    Write-Host "3. Click on $servicePrincipalName service principal in 'App Registrations' section"
    Write-Host "4. Click on settings and go to 'Required Permission'"
    Write-Host "5. Confirm the permissions count with below table."

    Write-Host "`nPermission Table"
    Write-Host "----------------"
    $permissionTable | Format-Table -AutoSize

    Write-Host "-------------------------"
    Write-Host "STEP 3: GRANT PERMISSIONS"
    Write-Host "-------------------------"
    Write-Host "* Click on 'Grant Permissions' button to grant the permission"

}
else
{
	Write-Host "ServicePrincipal $servicePrincipalName already exists in your active directory" -ForegroundColor "Yellow"
	
	do
    {
		$option = Read-Host -Prompt "Do you want to create new key? (yes/no): "
		switch ($option.ToLower()){
	
			"yes"{

				#create new key
				$adApp =  Get-AzureADApplication -Filter "DisplayName eq '$servicePrincipalName'"
				$keyIdentifier = "CloudneetiKey-" + -join ((48..57) + (97..122) | Get-Random -Count 5 | % {[char]$_})
                $keyExpiry = $keyExpirationPeriod[$expirationPeriod]
                $EndDate = (Get-Date).AddYears($keyExpiry).ToUniversalTime()

                Write-Host "Generating new key for $servicePrincipalName Active directory application..."
	            try {
                    $passwordCreds = New-AzureADApplicationPasswordCredential -ObjectId $adApp.ObjectId -CustomKeyIdentifier $keyIdentifier -EndDate $EndDate
    	            Write-Host "New key for $servicePrincipalName Active directory application generated successfully." -ForegroundColor "Green"
	            }
	            catch {
                    Write-Host "Error Details: $_" -ForegroundColor Red
		            Write-Host "Error occurred during active directory application key generation. Please try again" -ForegroundColor Red
		            # Disconnect from Azure AD 
		            Write-Host "`nDisconnecting from AzureAD."
		            Disconnect-AzureAD
		            exit
	            }

                # Script Outputs
                Write-Host "`n-----------------------------------"
                Write-Host "STORE SERVICE PRINCIPAL INFORMATION"
                Write-Host "-----------------------------------"
	            Write-Host "ApplicationName : $servicePrincipalName" -ForegroundColor "Green"
	            Write-Host "ApplicationId :" $adApp.AppId -ForegroundColor "Green"
	            Write-Host "Password Key Description : $keyIdentifier" -ForegroundColor "Green"
	            Write-Host "Password Key :" $passwordCreds.Value -ForegroundColor "Green"	
                Write-Host "Password Key Expiry Duration: $expirationPeriod `n`n" -ForegroundColor "Green"
                
                Write-Warning -Message "Store the above information in secure place. You won't be able to retrieve after you close the Powershell window."
				break

			}
			"no"{

				Write-Host "Refer to information generated while creating the $servicePrincipalName principal first time." -ForegroundColor Yellow
				break

			}
			default{

				Write-Host "You have entered invalid input, Please enter 'yes' or 'no' only"

			}
		}
	}
	while(!($option.ToLower() -eq "yes" -or $option.ToLower() -eq "no"))
}

# Disconnect from Azure AD 
Write-Host "`nDisconnecting from AzureAD."
Disconnect-AzureAD