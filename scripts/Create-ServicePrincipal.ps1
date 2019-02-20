<#
.SYNOPSIS
    Create service principal and assign permission required for Cloudneeti application.
    
.DESCRIPTION
	This script creates an Active Directory Application, Service Principal and setup the permission required for Cloudneeti application.
        The script requires activeDirectoryId as a mandatory input.
 
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
		The script must be executed with user having role Global AD Administrator
.EXAMPLE
    1. Creates a service principal.
    	.\Create-ServicePrincipal.ps1 -activeDirectoryId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx 
    2. Creates a Service Principal with service principal Name.
		.\Create-ServicePrincipal.ps1 -activeDirectoryId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx -servicePrincipalName <CloudneetiDataCollector>
    3. Creates a Service Principal with the expiry date.
		.\Create-ServicePrincipal.ps1 -activeDirectoryId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx -expirationPeriod <1year, 2year, NeverExpires>
.INPUTS
	azureActiveDirectoryId [Mandatory]:- Azure Active Directory Id (aka TenantId)
        servicePrincipalName [Optional]:- It is the display name for your app, must be unique in your directory (Azure AD Application name)
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
                "name":"Read directory data",
                "id":"5778995a-e1bf-45b8-affa-663a9f3f4d04",
                "type":"Role"
             },
             {  
                "name":"Manage apps that this app creates or owns",
                "id":"824c81eb-e3f8-4ee6-8f6d-de7f50d565b7",
                "type":"Role"
             },
             {  
                "name":"Read all hidden memberships",
                "id":"9728c0c4-a06b-4e0e-8d1b-3d694e8ec207",
                "type":"Role"
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
                "name":"Read directory data",
                "id":"5778995a-e1bf-45b8-affa-663a9f3f4d04",
                "type":"Scope"
             }
          ]
       },
       {  
          "name":"microsoftGraph",
          "resourceAppId":"00000003-0000-0000-c000-000000000000",
          "rules":[  
             {  
                "name":"Read all usage reports",
                "id":"230c1aed-a721-4c5d-9cb4-a90514e508ef",
                "type":"Role"
             },
             {  
                "name":"Read all hidden memberships",
                "id":"658aa5d8-239f-45c4-aa12-864f4fc7e490",
                "type":"Role"
             },
             {  
                "name":"Read all groups",
                "id":"5b567255-7703-4780-807c-7be8301ae99b",
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
                "name":"Read all identity risky user information",
                "id":"dc5007c0-2d7d-4c42-879c-2dab87571379",
                "type":"Role"
             },
             {  
                "name":"Read user devices",
                "id":"11d4cd79-5ba5-460f-803f-e22c8ab85ccd",
                "type":"Scope"
             },
             {  
                "name":"Read your organization?s security events",
                "id":"bf394140-e372-4bf9-a898-299cfc7564e5",
                "type":"Role"
             }
          ]
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

   $isGlobalAdmin = $false
   $isApplicationAdmin = $false
	$memberUser = $userEmailID
   $guestUser = $($userEmailID -replace '@','_') + "#EXT*"
#check if user is global Administrator
try {
   $role = Get-AzureADDirectoryRole | Where-Object {$_.displayName -eq 'Company Administrator'}
	Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId | ForEach-Object {
		if($_.UserPrincipalName -like $memberUser -or $_.UserPrincipalName -like $guestUser)
		{
			 $isGlobalAdmin = $true
			 Write-Host "Logged in User $userEmailID is global AD administrator " -ForegroundColor "Green"
		}
   }
}
catch {
    $isGlobalAdmin = $false
}

 if(!$isGlobalAdmin){
	Write-Host "Logged in user $userEmailID is not global AD administrator , Please re-run the script using global AD administrator account"
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
	
    try
    {
        # Creating AAD Application and Service Principal
	    Write-Host "Creating service principal $servicePrincipalName..."
	 
	    $adApp = New-AzureADApplication -DisplayName $servicePrincipalName -HomePage $aadHomePage -IdentifierUris $aadHomePage	
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