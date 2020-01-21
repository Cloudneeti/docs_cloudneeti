<#
.SYNOPSIS
    Script to on-board Azure IAM account for PowerShell policy data collection inside Cloudneeti.
    
.DESCRIPTION
     This script creates an automation account, Runbook, Schedule for execution and required variables & credentials for running the Azure IAM policies. The automation runbook executes once per day and export data to cloudneeti using Cloudneeti API.
 
.NOTES
    Version:        1.0
    Author:         Cloudneeti
    Creation Date:  06/01/2020

    # PREREQUISITE

.EXAMPLE
    Upload script to Azure CloudShell and execute below command:-
    .\Provision-IAMPolicies-DataCollector.ps1

    Then script execution will prompt for below inputs:
        - Cloudneeti License Id
        - Cloudneeti Account Id
        - Cloudneeti API Key
        - Cloudneeti Environment
        - Cloudneeti Application Id
        - Cloudneeti Application Secret
        - Cloudneeti Azure IAM Data Collector Artifacts Storage Name
        - Cloudneeti Azure IAM Data Collector Artifacts Storage Access Key
        - Data Collection Version
        - Azure Active Directory Id
        - Azure AD Global Reader Email Id
        - Azure AD Global Reader Password
        - Azure Subscription Id where Azure data collector resouces will be created
        - Enter Azure IAM data collector name

.INPUTS
    Below is the list of inputs to the script:-
        - Cloudneeti License Id <Find in "Manage Licenses" of Cloudneeti Settings>
        - Cloudneeti Account Id <Find in "Manage Accounts" of Cloudneeti Settings>
        - Cloudneeti API Key <Contact Cloudneeti team>
        - Cloudneeti Environment <Cloudneeti Environment>
        - Cloudneeti Application Id <Cloudneeti Data Collector Application Id>
        - Cloudneeti Application Secret <Cloudneeti Data Collector Application Secret>
        - Cloudneeti Azure IAM Data Collector Artifacts Storage Name <Contact Cloudneeti team>
        - Cloudneeti Azure IAM Data Collector Artifacts Storage Access Key <Contact Cloudneeti team>
        - Cloudneeti Azure IAM Data Collector Version <Contact Cloudneeti team>
        - Azure Active Directory Id <Tenant Id of Azure Directory>
        - Azure Active Directory Global Reader Email Id <Azure Active Directory Global Reader Email Id>
        - Azure Active Directory Global Reader Password <Azure Active Directory Global Reader password>
        - Azure Subscription Id where Azure IAM data collector resouces will be created <Azure Subscription Id where Azure IAM data collector resouces will be created> 
        - Azure IAM data collector name

.OUTPUTS

.NOTES
        - The user should have a contract with Cloudneeti 
        - Azure Global Reader should be non MFA Azure AD User
        - This script should be executed only on Azure CloudShell.
#>

[CmdletBinding()]
param
(

    # Cloudneeti contract Id
    [Parameter(Mandatory = $False,
        HelpMessage = "Cloudneeti License Id",
        Position = 1
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $CloudneetiLicenseId = $(Read-Host -prompt "Enter Cloudneeti License Id"),

    # Cloudneeti account Id
    [Parameter(Mandatory = $False,
        HelpMessage = "Cloudneeti Account Id",
        Position = 2
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $CloudneetiAccountId = $(Read-Host -prompt "Enter Cloudneeti Account Id"),

    # Cloudneeti API key
    [Parameter(Mandatory = $False,
        HelpMessage = "Cloudneeti API Key",
        Position = 3
    )]
    [ValidateNotNullOrEmpty()]
    [secureString]
    $CloudneetiAPIKey = $(Read-Host -prompt "Enter Cloudneeti API Key" -AsSecureString),

    # Cloudneeti Environment
    [Parameter(Mandatory = $False,
        HelpMessage = "Cloudneeti Environment",
        Position = 4
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $CloudneetiEnvironment = $(Read-Host -prompt "Enter Cloudneeti Environment"),

    # Cloudneeti Service principal id
    [Parameter(Mandatory = $False,
        HelpMessage = "Cloudneeti Data collector Service Principal Id",
        Position = 5
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $CloudneetiApplicationId = $(Read-Host -prompt "Enter Cloudneeti Data Collector Service Principal Id"),

    # Enter service principal secret
    [Parameter(Mandatory = $False,
        HelpMessage = "Cloudneeti Data collector Service Principal password",
        Position = 6
    )]
    [ValidateNotNullOrEmpty()]
    [SecureString]
    $CloudneetiApplicationSecret = $(Read-Host -prompt "Enter Cloudneeti Data Collector Service Principal Secret" -AsSecureString),

    # Cloudneeti Artifacts Storage Name
    [Parameter(Mandatory = $False,
        HelpMessage = "Cloudneeti Azure IAM Data Collector Artifact Name",
        Position = 7
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $ArtifactsName = $(Read-Host -prompt "Enter Cloudneeti Azure IAM Data Collector Artifacts Storage Name"),

    # Cloudneeti artifacts access key
    [Parameter(Mandatory = $False,
        HelpMessage = "Cloudneeti Azure IAM Data Collector Artifacts Acccess Key",
        Position = 8
    )]
    [ValidateNotNullOrEmpty()]
    [secureString]
    $ArtifactsAccessKey = $(Read-Host -prompt "Enter Cloudneeti Azure IAM Data Collector Artifacts Storage Access Key" -AsSecureString),

    # Data Collector version
    [Parameter(Mandatory = $False,
        HelpMessage = "Cloudneeti Azure IAM Data Collector Artifacts Version",
        Position = 9
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataCollectorVersion = $(Read-Host -prompt "Enter Cloudneeti Azure IAM Data Collector Version"),

    # Azure Tenant ID
    [Parameter(Mandatory = $False,
        HelpMessage = "Azure Active Directory Id",
        Position = 10
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $AzureDirectoryId = $(Read-Host -prompt "Enter Azure Active Directory Id"),

    # Azure Global Reader username
    [ValidateScript( {$_ -match '^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,7})$' })]
    [Parameter(Mandatory = $False,
        HelpMessage = "Azure AD Global Reader Email Id",
        Position = 11
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $AzureGlobalReaderEmailId = $(Read-Host -prompt "Enter Azure AD Global Reader Email Id"),

    # Azure Global Reader password
    [Parameter(Mandatory = $False,
        HelpMessage = "Azure AD Global Reader Password",
        Position = 12
    )]
    [ValidateNotNullOrEmpty()]
    [SecureString]
    $AzureGlobalReaderPassword = $(Read-Host -prompt "Enter Azure AD Global Reader Password" -AsSecureString),

    # Subscription Id for automation account creation
    [Parameter(Mandatory = $False,
        HelpMessage = "Azure Subscription Id for IAM data collector resources provisioning",
        Position = 13
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $AzureSubscriptionId = $(Read-Host -prompt "Enter Azure Subscription Id where IAM data collector resouces will be created"),

    # Resource group name for Cloudneeti Resouces
    [Parameter(Mandatory = $False,
        HelpMessage = "Azure IAM Collector Name",
        Position = 14
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataCollectorName = $(Read-Host -prompt "Enter Azure IAM data collector name"),

    # Data collector resource location
    [Parameter(Mandatory = $False,
        HelpMessage = "Location for Cloudneeti Azure IAM data collector resources",
        Position = 15
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $Location = "eastus2"
)

# Session configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

# Resource names declaration
$AutomationAccountName = "$DataCollectorName"
$ResourceGroupName = "$DataCollectorName-rg"
$ScriptPrefix = "IAMDataCollector"
$ContianerName = "iam-datacollection-script"
$RunbookScriptName = "$ScriptPrefix$DataCollectorVersion.ps1"
$RunbookName = "$ScriptPrefix-$DataCollectorVersion"
$path = "./runbooks"
$Tags = @{"Service" = "Cloudneeti-AzureIAM-Data-Collection"}

# Cloudneeti API URL
$CloudneetiAPIEndpoints = @{
    dev   = "https://devapi.cloudneeti-devops.com";
    trial = "https://trialapi.cloudneeti.com";
    qa    = "https://qaapi.cloudneeti-devops.com";
    prod  = "https://api.cloudneeti.com"
}
$CloudneetiAPIURL = $CloudneetiAPIEndpoints[$CloudneetiEnvironment.ToLower()]

# Checking current azure rm context to deploy Azure automation
$AzureContextSubscriptionId = (Get-AzureRmContext).Subscription.Id

If ($AzureContextSubscriptionId -ne $AzureSubscriptionId) {
    Write-Host "You are not logged in to subscription" $AzureSubscriptionId 
    Try {
        Write-Host "Trying to switch powershell context to subscription" $AzureSubscriptionId
        $AllAvailableSubscriptions = (Get-AzureRmSubscription).Id
        if ($AllAvailableSubscriptions -contains $AzureSubscriptionId) {
            Set-AzureRmContext -SubscriptionId $AzureSubscriptionId
            Write-Host "Successfully context switched to subscription" $AzureSubscriptionId
        }
        else {
            $NotValidSubscription = 0
        }
    }
    catch [Exception] {
        Write-Output $_
    }
}

if ($NotValidSubscription -eq 0) {
    Write-Host "Looks like the" $AzureSubscriptionId "is not present in current powershell context or you don't have access" -ForegroundColor Red
    break
}

Write-host "Fetching Azure IAM scanning script to create Azure automation runbook..." -ForegroundColor Yellow
# Download cis m365 scan script to push in to Azure automation runbook
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ArtifactsAccessKey)            
$ArtifactsKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) 
$CNConnectionString = "BlobEndpoint=https://$ArtifactsName.blob.core.windows.net/;SharedAccessSignature=$ArtifactsKey"
$PackageContext = New-AzureStorageContext -ConnectionString $CNConnectionString

New-Item -ItemType Directory -Force -Path $path | Out-Null

Get-AzureStorageBlobContent -Container $ContianerName -Blob $RunbookScriptName -Destination "./runbooks/" -Context $PackageContext -Force | Out-Null
Write-Host "Azure IAM scanning script successfully fetched and ready to push in automation runbook" -ForegroundColor Green


$RequiredModules = @"
{
    Modules: [
        {
            "Product": "AzureRM.Profile",
            "Name": "AzureRM.Profile",
            "ContentUrl" : "https://www.powershellgallery.com/api/v2/package/azurerm.profile",
            "Version" : "5.8.3"
        }
    ]
}
"@

# Azure Automation account check for exists or not
$AllAutomationAccountList = Get-AzureRmAutomationAccount | Select AutomationAccountName
if ($AllAutomationAccountList.AutomationAccountName -contains $AutomationAccountName) {
    Write-Host "Data collector already exists with the name:" $AutomationAccountName -ForegroundColor Magenta
    Write-Host "Please choose different name and Re-run this script" -ForegroundColor Yellow
    break
}

# Resource Group creation
Write-host "Creating Resource Group for data collector resources" -ForegroundColor Yellow
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Force
Write-Host "Resource Group $ResourceGroupName  is created successfully" -ForegroundColor Green

# Automation account creation
Write-Host "Creating Azure Automation Account" -ForegroundColor Yellow
New-AzureRmAutomationAccount -Name $AutomationAccountName -Location $Location -ResourceGroupName $ResourceGroupName
Write-host $AutomationAccountName "Automation Account is created successfully"

# PSH module creation
Write-Host "Importing required module to Azure Automation account"
$RequiredModulesObj = ConvertFrom-Json $RequiredModules

$requiredModulesObj.Modules | ForEach-Object {
    Write-Host "Importing" $_.Name "PowerShell module" -ForegroundColor Yellow
    New-AzureRmAutomationModule -AutomationAccountName $AutomationAccountName -Name $_.Name -ContentLink $_.ContentUrl -ResourceGroupName $ResourceGroupName
    Write-Host $_.Name "module imported successfully" -ForegroundColor Green
}

# Runbook creation
Write-Host "Creating powershell runbook" -ForegroundColor Yellow

Import-AzureRmAutomationRunbook -Name $RunbookName -Path .\runbooks\$RunbookScriptName -Tags $Tags -ResourceGroup $ResourceGroupName -AutomationAccountName $AutomationAccountName -Type PowerShell -Published -Force
Write-Host $ScriptPrefix "Runbook created successfully with version" $RunbookScriptVersion


# Credential object creation
Write-host "Creating secure credentials object for Azure Global Reader in Automation accout" -ForegroundColor Yellow
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AzureGlobalReaderEmailId, $AzureGlobalReaderPassword
$AzureADReaderCredentials = "AzureADReaderCredentials"
$ExistingCredentials = Get-AzureRmAutomationCredential -Name $AzureADReaderCredentials -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue

If ($ExistingCredentials -ne $null -and $ExistingCredentials.UserName -eq $AzureGlobalReaderEmailId) {
    Set-AzureRmAutomationCredential -AutomationAccountName $AutomationAccountName -Name $AzureADReaderCredentials -Value $Credential -ResourceGroupName $ResourceGroupName
    Write-Host $AzureGlobalReaderEmailId "credential object already exist, Updated sucessfully" -ForegroundColor Green
}    
else {
    New-AzureRmAutomationCredential -AutomationAccountName $AutomationAccountName -Name $AzureADReaderCredentials -Value $Credential -ResourceGroupName $ResourceGroupName
    Write-Host $AzureGlobalReaderEmailId "credentials object created successfully" -ForegroundColor Green
}

# Credential object creation
Write-host "Creating secure credentials object for client service principal in Automation account" -ForegroundColor Yellow
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $CloudneetiApplicationId, $CloudneetiApplicationSecret
$CloudneetiCredentials = "CloudneetiCredentials"
$ExistingCredentials = Get-AzureRmAutomationCredential -Name $CloudneetiCredentials -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue

If ($ExistingCredentials -ne $null -and $ExistingCredentials.UserName -eq $AzureGlobalReaderEmailId) {
    Set-AzureRmAutomationCredential -AutomationAccountName $AutomationAccountName -Name $CloudneetiCredentials -Value $Credential -ResourceGroupName $ResourceGroupName
    Write-Host $CloudneetiApplicationId "credential object already exists, Updated sucessfully" -ForegroundColor Green
}    
else {
    New-AzureRmAutomationCredential -AutomationAccountName $AutomationAccountName -Name $CloudneetiCredentials -Value $Credential -ResourceGroupName $ResourceGroupName
    Write-Host $CloudneetiApplicationId "credentials object created successfully" -ForegroundColor Green
}


# Creating variable in Azure automation
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($CloudneetiAPIKey)            
$CloudneetiAPIKeyEncrypt = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$VariableObject = @{    
    "CloudneetiLicenseId"   = $CloudneetiLicenseId;
    "CloudneetiAccountId"   = $CloudneetiAccountId; 
    "CloudneetiEnvironment" = $CloudneetiEnvironment 
    "AzureDirectoryId"      = $AzureDirectoryId
    "CloudneetiAPIKey"      = $CloudneetiAPIKeyEncrypt
    "CloudneetiAPIURL"      = $CloudneetiAPIURL
}

Write-Host "Creating Azure automation variables in automation account"
foreach ($Variable in $VariableObject.GetEnumerator()) {
    $ExistingVariable = Get-AzureRmAutomationVariable -AutomationAccountName $AutomationAccountName -Name $Variable.Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    If ($ExistingVariable -ne $null -and $ExistingVariable.Value -eq $Variable.Value) {
        Write-Host $Variable.Name "variable already exists" -ForegroundColor Yellow
    }
    else {
        if ($ExistingVariable -ne $null) {
            if ($Variable.Name -eq "CloudneetiAPIKey") {
                Write-Host "Updating variable value of" $Variable.Name -ForegroundColor Yellow
                Set-AzureRmAutomationVariable -AutomationAccountName $AutomationAccountName -Name $Variable.Name -Encrypted $true -Value $Variable.Value -ResourceGroupName $ResourceGroupName
                Write-Host $Variable.Name "variable successfully updated" -ForegroundColor Green
            }
            else {
                Write-Host "Updating variable value of" $Variable.Name -ForegroundColor Yellow
                Set-AzureRmAutomationVariable -AutomationAccountName $AutomationAccountName -Name $Variable.Name -Encrypted $False -Value $Variable.Value -ResourceGroupName $ResourceGroupName
                Write-Host $Variable.Name "variable successfully updated" -ForegroundColor Green
            }
        }
        else {
            if ($Variable.Name -eq "CloudneetiAPIKey") {
                Write-Host "Creating variable " $Variable.Name -ForegroundColor Yellow
                New-AzureRmAutomationVariable -AutomationAccountName $AutomationAccountName -Name $Variable.Name -Encrypted $true -Value $Variable.Value -ResourceGroupName $ResourceGroupName
                Write-Host $Variable.Name "variable successfully created" -ForegroundColor Green
            }
            else {
                Write-Host "Creating variable " $Variable.Name -ForegroundColor Yellow
                New-AzureRmAutomationVariable -AutomationAccountName $AutomationAccountName -Name $Variable.Name -Encrypted $False -Value $Variable.Value -ResourceGroupName $ResourceGroupName
                Write-Host $Variable.Name "variable successfully created" -ForegroundColor Green   
            }         
        }
    }
}

# Create schedule
try {
    Write-Host "Creating automation account schedule"
    $scheduleName = "$ScriptPrefix-DailySchedule" 
    $StartTime = (Get-Date).AddMinutes(8)
    New-AzureRmAutomationSchedule -ResourceGroupName $ResourceGroupName –AutomationAccountName $AutomationAccountName –Name $scheduleName –StartTime $StartTime –DayInterval 1
    Write-Host "Successfully created the automation account schedule" $scheduleName
}
catch [Exception] {
    Write-Host "Error occurred while creating automation schedule"
    Write-Output $_
}

# Link schedule to the automation account	
try {
    Write-Host "Linking automation account schedule $scheduleName to runbook $RunbookName"
    Register-AzureRmAutomationScheduledRunbook -ResourceGroupName $ResourceGroupName –AutomationAccountName $AutomationAccountName –RunbookName $RunbookName -ScheduleName $scheduleName
    Write-Host "Successfully linked the automation account schedule $scheduleName to runbook $RunbookName"
}
catch [Exception] {
    Write-Host "Error occurred while linking automation schedule $scheduleName to runbook $RunbookName"
    Write-Output $_
}
Write-host "Script execution completed" 
