<#
.SYNOPSIS
    Create service principal and assign permission required for Cloudneeti application.
.DESCRIPTION
    This script creates an Active Directory Application, Service Principal and setup the permission required for Cloudneeti application.
    The script requires activeDirectoryId as a mandatory input.
.NOTES
    Version:        1.0
    Author:         Cloudneeti
    Creation Date:  22/05/2019
    # PREREQUISITE
    * Windows PowerShell version 5 and above
        1. To check PowerShell version type "$PSVersionTable.PSVersion" in PowerShell and you will find PowerShell version,
        2. To Install powershell follow link https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-6
    * AzureAD 2.0.0.131 or above module installed
        1. To check Azure AD version type "Get-InstalledModule -Name azureAD" in PowerShell window
        2. You can Install the required modules by executing below command.
            Install-Module -Name AzureAD -MinimumVersion 2.0.0.131
    * Account permissions
        The script must be executed with user having Global AD Administrator or Application Administrator role
.EXAMPLE
    1. Creates a service principal.
        .\Create-ServicePrincipal-Office365Onboarding.ps1 -activeDirectoryId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx
    2. Creates a Service Principal with service principal Name.
        .\Create-ServicePrincipal-Office365Onboarding.ps1 -activeDirectoryId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx -servicePrincipalName <CloudneetiDataCollector>
    3. Creates a Service Principal with the expiry date.
        .\Create-ServicePrincipal-Office365Onboarding.ps1 -activeDirectoryId xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx -expirationPeriod <1year, 2year, NeverExpires>
.INPUTS
    azureActiveDirectoryId [Mandatory]:- Azure Active Directory Id (aka TenantId)
    servicePrincipalName [Optional]:- It is the display name for your app, must be unique in your directory (Azure AD Application name)
                                      Default: CloudneetiDataCollector
    expirationPeriod [Optional]:- Service principal key will get expire after this duration.
                                   Default: 1 year
                                   Available Values: 1year, 2year, NeverExpires
.OUTPUTS
    Tenat Id:- Azure Tenant Id
    Domain Name:- Azure AD domain Name
    ApplicationName:- Active Directory application Name
    ApplicationId:- Active Directory application Id
    Password Key Description:- Key Name
    Password Key:- Key Value
    Password Key Expiration Duration:- Key Expiry Duration
    PermissionTable:- API Permission assigned to service principal
#>


[cmdletbinding()]
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
        Position=2
    )][string] $servicePrincipalName = "CloudneetiDataCollector",

    # Key expiry after how many year
    [ValidateSet("1year","2years","NeverExpires")]
    [Parameter(
        Mandatory = $False,
        HelpMessage="Enter Service Principal Expiry Period, Valid values are 1year, 2years, NeverExpires",
        Position=3
    )][string] $expirationPeriod = "1year"
)

$ErrorActionPreference = "Stop"

$requiredAccess = @"
{
    "permissionCatergory":[
        {
            "name":"MicrosoftGraph",
            "resourceAppId":"00000003-0000-0000-c000-000000000000",
            "rules": [
                {
                    "name": "Organization.Read.All",
                    "description":"Read Organization Data",
                    "id":"498476ce-e0fe-48b0-b801-37ba7e2685c6",
                    "type":"Role"
                },
                {  
                    "name": "SecurityEvents.Read.All",
                    "description": "Read your organization's security events",
                    "id":"bf394140-e372-4bf9-a898-299cfc7564e5",
                    "type":"Role"
                },
                {  
                    "name": "User.Read.All",
                    "description": "Read your organization's users information",
                    "id":"df021288-bdef-4463-88db-98f22de89214",
                    "type":"Role"
                },
                {  
                    "name": "Application.Read.All",
                    "description": "Read your organization's Applications information",
                    "id":"9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30",
                    "type":"Role"
                },
                {
                    "name": "DeviceManagementConfiguration.Read.All",
                    "description":"Read DeviceManagement Configuration policies",
                    "id":"dc377aa6-52d8-4e23-b271-2a7ae04cedf3",
                    "type":"Role"
                },
                {
                    "name": "DeviceManagementApps.Read.All",
                    "description":"Read DeviceManagement Apps policies",
                    "id":"7a6ee1e7-141e-4cec-ae74-d9db155731ff",
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
    Write-Host "AzureAD module was found other than the required version 2. Run Below command to Install the AzureAD module and re-run the script"
    Write-Host "Install-Module -Name AzureAD -MinimumVersion 2.0.0.131" -ForegroundColor Yellow
    exit
}

# Login to Azure Active Directory
Write-Host "Connecting to Azure Active Directory..."
Write-Host "You will be redirected to login screen. Login using Global AD administrator or Application Administrator account to proceed..."
try {
    Start-Sleep 2
    $loginDetails = Connect-AzureAD -TenantId $azureActiveDirectoryId
    $userEmailID = $loginDetails.Account.Id
    $tenantDomain = $loginDetails.TenantDomain
    Write-Host "Connection to Azure Active Directory established successfully." -ForegroundColor "Green"
}
catch {
    Write-Host "Error Details: $_" -ForegroundColor Red
    Write-Host "Error occurred during connecting Azure active directory. Please try again!!" -ForegroundColor Red
    exit
}

# Check if login user is global Admin or Application administrator
Write-Host "Checking role of Logged In user $userEmailID..."

$isGlobalAdmin = $false
$isApplicationAdmin = $false

$memberUser = $userEmailID
$guestUser = $($userEmailID -replace '@','_') + "#EXT*"

try {
    # Checking Application administrator access
    $role = Get-AzureADDirectoryRole | Where-Object {$_.displayName -eq 'Application Administrator'}
    if($role){
        Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId | ForEach-Object {
            if($_.UserPrincipalName -like $memberUser -or $_.UserPrincipalName -like $guestUser)
            {
                $isApplicationAdmin = $true
                Write-Host "Logged in User $userEmailID is application administrator " -ForegroundColor "Green"
            }
        }
    }
    if(!$isApplicationAdmin){
        # Checking Global AD Administrator Access
        $role = Get-AzureADDirectoryRole | Where-Object {$_.displayName -eq 'Company Administrator'}
        Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId | ForEach-Object {
            if($_.UserPrincipalName -like $memberUser -or $_.UserPrincipalName -like $guestUser)
            {
                 $isGlobalAdmin = $true
                 Write-Host "Logged in User $userEmailID is global AD administrator " -ForegroundColor "Green"
            }
       }
    }
}
catch {
    $isGlobalAdmin = $false
    $isApplicationAdmin = $false
}

 if(!$isGlobalAdmin -and !$isApplicationAdmin){
    Write-Host "Logged in user $userEmailID is not global AD administrator or application administrator"
    Write-Host " Please re-run the script using global AD administrator or application administrator account"
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

    # Assign AD level permissions
    # Creating AD permission object
    $requiredAccessObj = ConvertFrom-Json $requiredAccess
    $resourceAccessCategory = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.RequiredResourceAccess]

    $permissionTable = @() 
    ForEach($category in $requiredAccessObj.permissionCatergory) {

    # Process Rule Info
        $category.rules | ForEach {

        # Create Permission table
        $permissionEntry = "" | select "API", "PermissionName", "PermissionType", "Description"
        $permissionEntry.API = $category.name
        $permissionEntry.PermissionName = $_.name
        $permissionEntry.Description = $_.description

        $_.PSObject.Properties.Remove('name')
        $_.PSObject.Properties.Remove('description')
        if($_.type -eq 'Role') { 
            $permissionEntry.PermissionType = "Application"
        }
        else {
            $permissionEntry.PermissionType = "Delegated"
        }
        $permissionTable += $permissionEntry
        }

        $resourceAccessObj = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
        $resourceAccessObj.ResourceAppId = $category.resourceAppId
        $resourceAccessObj.ResourceAccess = $category.rules
        $resourceAccessCategory.Add($resourceAccessObj) > $null
    }

    Write-Host "Setting up the required permissions on active directory application..."
    try 
    {
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
    Write-Host "Tenant Id :" $azureActiveDirectoryId -ForegroundColor "Green"
    Write-host "Domain Name :" $tenantDomain -ForegroundColor "Green"
    Write-Host "Application Name :" $servicePrincipalName -ForegroundColor "Green"
    Write-Host "Application Id :" $adApp.AppId -ForegroundColor "Green"
    Write-Host "Password Key Description :" $keyIdentifier -ForegroundColor "Green"
    Write-Host "Password Key :" $passwordCreds.Value -ForegroundColor "Green"
    Write-Host "Password Key Expiry Duration: $expirationPeriod`n" -ForegroundColor "Green"

    Write-Warning -Message "Store the above information in secure place. You won't be able to retrieve after you close the Powershell window."

    Write-Host "`n---------------------------"
    Write-Host "STEP 2: CONFIRM PERMISSIONS"
    Write-Host "---------------------------"
    Write-Host "1. Login to Azure Portal"
    Write-Host "2. Click on Azure Active Directory"
    Write-Host "3. Click on $servicePrincipalName service principal in 'App Registrations' section"
    Write-Host "4. Go to 'API permissions' and confirm Microsoft Graph permissions"
    Write-Host "5. Confirm the permissions given in below table."

    Write-Host "`nPermission Table"
    Write-Host "----------------"
    $permissionTable | Format-Table -AutoSize

    Write-Host "-------------------------"
    Write-Host "STEP 3: GRANT CONSENT"
    Write-Host "-------------------------"
    Write-Host "* Click on 'Grant Admin Consent' button under 'Grant Consent' section to grant admin consent"
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
                Write-Host "Tenant Id :" $azureActiveDirectoryId -ForegroundColor "Green"
                Write-host "Domain Name :" $tenantDomain -ForegroundColor "Green"
                Write-Host "Application Name :" $servicePrincipalName -ForegroundColor "Green"
                Write-Host "Application Id :" $adApp.AppId -ForegroundColor "Green"
                Write-Host "Password Key Description :" $keyIdentifier -ForegroundColor "Green"
                Write-Host "Password Key :" $passwordCreds.Value -ForegroundColor "Green"
                Write-Host "Password Key Expiry Duration: $expirationPeriod `n" -ForegroundColor "Green"
                
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
