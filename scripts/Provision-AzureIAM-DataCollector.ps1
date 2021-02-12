<#
.SYNOPSIS
    Script to on-board Azure IAM account for PowerShell policy data collection inside Zscaler CSPM.
    
.DESCRIPTION
     This script creates an automation account, Runbook, Schedule for execution and required variables & credentials for running the Azure IAM policies. The automation runbook executes once per day and export data to Zscaler CSPM using Zscaler CSPM API.

.NOTES

    Copyright (c) Zscaler CSPM. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Version:        1.4
    Author:         Zscaler CSPM
    Creation Date:  06/01/2020
    Last Modified Date: 12/02/2021

    # PREREQUISITE

.EXAMPLE
    Upload script to Azure CloudShell and execute below command:-
    .\Provision-IAMPolicies-DataCollector.ps1

    Then script execution will prompt for below inputs:
        - ZCSPM License Id
        - ZCSPM Account Id
        - ZCSPM API Key
        - ZCSPM Environment
        - ZCSPM Application Id
        - ZCSPM Application Secret
        - ZCSPM Azure IAM Data Collector Artifacts Storage Name
        - ZCSPM Azure IAM Data Collector Artifacts Storage Access Key
        - Data Collection Version
        - Azure Active Directory Id
        - Azure AD Global Reader Email Id
        - Azure AD Global Reader Password
        - Azure Subscription Id where Azure data collector resouces will be created
        - Enter Azure IAM data collector name

.INPUTS
    Below is the list of inputs to the script:-
        - ZCSPM License Id <Find in "Manage Licenses" of ZCSPM Settings>
        - ZCSPM Account Id <Find in "Manage Accounts" of ZCSPM Settings>
        - ZCSPM API Key <Contact ZCSPM team>
        - ZCSPM Environment <ZCSPM Environment>
        - ZCSPM Application Id <ZCSPM Data Collector Application Id>
        - ZCSPM Application Secret <ZCSPM Data Collector Application Secret>
        - ZCSPM Azure IAM Data Collector Artifacts Storage Name <Contact ZCSPM team>
        - ZCSPM Azure IAM Data Collector Artifacts Storage Access Key <Contact ZCSPM team>
        - ZCSPM Azure IAM Data Collector Version <Contact ZCSPM team>
        - Azure Active Directory Id <Tenant Id of Azure Directory>
        - Azure Active Directory Global Reader Email Id <Azure Active Directory Global Reader Email Id>
        - Azure Active Directory Global Reader Password <Azure Active Directory Global Reader password>
        - Azure Subscription Id where Azure IAM data collector resouces will be created <Azure Subscription Id where Azure IAM data collector resouces will be created> 
        - Azure IAM data collector name

.OUTPUTS

.NOTES
        - The user should have a contract with Zscaler CSPM 
        - Azure Global Reader should be non MFA Azure AD User
        - This script should be executed only on Azure CloudShell.
#>

[CmdletBinding()]
param
(

    # ZCSPM contract Id
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM License Id",
        Position = 1
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $ZCSPMLicenseId = $(Read-Host -prompt "Enter ZCSPM License Id"),

    # ZCSPM account Id
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM Account Id",
        Position = 2
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $ZCSPMAccountId = $(Read-Host -prompt "Enter ZCSPM Account Id"),

    # ZCSPM API key
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM API Key",
        Position = 3
    )]
    [ValidateNotNullOrEmpty()]
    [secureString]
    $ZCSPMAPIKey = $(Read-Host -prompt "Enter ZCSPM API Key" -AsSecureString),

    # ZCSPM Environment
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM Environment",
        Position = 4
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $ZCSPMEnvironment = $(Read-Host -prompt "Enter ZCSPM Environment"),

    # ZCSPM Service principal id
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM Data collector Service Principal Id",
        Position = 5
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $ZCSPMApplicationId = $(Read-Host -prompt "Enter ZCSPM Data Collector Service Principal Id"),

    # Enter service principal secret
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM Data collector Service Principal password",
        Position = 6
    )]
    [ValidateNotNullOrEmpty()]
    [SecureString]
    $ZCSPMApplicationSecret = $(Read-Host -prompt "Enter ZCSPM Data Collector Service Principal Secret" -AsSecureString),

    # ZCSPM Artifacts Storage Name
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM Azure IAM Data Collector Artifact Name",
        Position = 7
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $ArtifactsName = $(Read-Host -prompt "Enter ZCSPM Azure IAM Data Collector Artifacts Storage Name"),

    # ZCSPM artifacts access key
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM Azure IAM Data Collector Artifacts Acccess Key",
        Position = 8
    )]
    [ValidateNotNullOrEmpty()]
    [secureString]
    $ArtifactsAccessKey = $(Read-Host -prompt "Enter ZCSPM Azure IAM Data Collector Artifacts Storage Access Key" -AsSecureString),

    # Data Collector version
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM Azure IAM Data Collector Artifacts Version",
        Position = 9
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataCollectorVersion = $(Read-Host -prompt "Enter ZCSPM Azure IAM Data Collector Version"),

    # Azure Tenant ID
    [Parameter(Mandatory = $False,
        HelpMessage = "Azure Active Directory Id",
        Position = 10
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $AzureActiveDirectoryId = $(Read-Host -prompt "Enter Azure Active Directory Id"),

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

    # Resource group name for ZCSPM Resouces
    [Parameter(Mandatory = $False,
        HelpMessage = "Azure IAM Collector Name",
        Position = 14
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataCollectorName = $(Read-Host -prompt "Enter Azure IAM data collector name"),

    # Data collector resource location
    [Parameter(Mandatory = $False,
        HelpMessage = "Location for ZCSPM Azure IAM data collector resources",
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
$RunbookScriptName = "$ScriptPrefix-$DataCollectorVersion.ps1"
$RunbookName = "$ScriptPrefix-$DataCollectorVersion"
$path = "./runbooks"
$Tags = @{"Service" = "ZCSPM-AzureIAM-Data-Collection"}

# ZCSPM API URL
$ZCSPMAPIEndpoints = @{
    dev   = "https://devapi.cloudneeti-devops.com";
    trial = "https://trialapi.cloudneeti.com";
    qa    = "https://qaapi.cloudneeti-devops.com";
    prod  = "https://api.cloudneeti.com"
}
$ZCSPMAPIURL = $ZCSPMAPIEndpoints[$ZCSPMEnvironment.ToLower()]

# Checking current azure rm context to deploy Azure automation
$AzureContextSubscriptionId = (Get-AzContext).Subscription.Id

If ($AzureContextSubscriptionId -ne $AzureSubscriptionId) {
    Write-Host "You are not logged in to subscription" $AzureSubscriptionId 
    Try {
        Write-Host "Trying to switch powershell context to subscription" $AzureSubscriptionId
        $AllAvailableSubscriptions = (Get-AzSubscription).Id
        if ($AllAvailableSubscriptions -contains $AzureSubscriptionId) {
            Set-AzContext -SubscriptionId $AzureSubscriptionId
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
$ArtifactsKey = (New-Object PSCredential "user",$ArtifactsAccessKey).GetNetworkCredential().Password
$CNConnectionString = "BlobEndpoint=https://$ArtifactsName.blob.core.windows.net/;SharedAccessSignature=$ArtifactsKey"
$PackageContext = New-AzStorageContext -ConnectionString $CNConnectionString

New-Item -ItemType Directory -Force -Path $path | Out-Null

Get-AzStorageBlobContent -Container $ContianerName -Blob $RunbookScriptName -Destination "./runbooks/" -Context $PackageContext -Force | Out-Null
Write-Host "Azure IAM scanning script successfully fetched and ready to push in automation runbook" -ForegroundColor Green


$RequiredModules = @"
{
    Modules: [
        {
            "Product": "AzureRM.Profile",
            "Name": "AzureRM.Profile",
            "ContentUrl" : "https://www.powershellgallery.com/api/v2/package/azurerm.profile",
            "Version" : "5.8.3"
        },
        {
            "Product": "MSOnline",
            "Name": "MSOnline",
            "ContentUrl" : "https://www.powershellgallery.com/api/v2/package/MSOnline",
            "Version" : "1.1.183.57"
        }
    ]
}
"@

# Azure Automation account check for exists or not
$AllAutomationAccountList = Get-AzAutomationAccount | Select AutomationAccountName
if ($AllAutomationAccountList.AutomationAccountName -contains $AutomationAccountName) {
    Write-Host "Data collector already exists with the name:" $AutomationAccountName -ForegroundColor Magenta
    Write-Host "Please choose different name and Re-run this script" -ForegroundColor Yellow
    break
}

# Resource Group creation
Write-host "Creating Resource Group for data collector resources" -ForegroundColor Yellow
New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
Write-Host "Resource Group $ResourceGroupName  is created successfully" -ForegroundColor Green

# Automation account creation
Write-Host "Creating Azure Automation Account" -ForegroundColor Yellow
New-AzAutomationAccount -Name $AutomationAccountName -Location $Location -ResourceGroupName $ResourceGroupName
Write-host $AutomationAccountName "Automation Account is created successfully"

# PSH module creation
Write-Host "Importing required module to Azure Automation account"
$RequiredModulesObj = ConvertFrom-Json $RequiredModules

$requiredModulesObj.Modules | ForEach-Object {
    Write-Host "Importing" $_.Name "PowerShell module" -ForegroundColor Yellow
    New-AzAutomationModule -AutomationAccountName $AutomationAccountName -Name $_.Name -ContentLink $_.ContentUrl -ResourceGroupName $ResourceGroupName
    Write-Host $_.Name "module imported successfully" -ForegroundColor Green
}

# Runbook creation
Write-Host "Creating powershell runbook" -ForegroundColor Yellow

Import-AzAutomationRunbook -Name $RunbookName -Path .\runbooks\$RunbookScriptName -Tags $Tags -ResourceGroup $ResourceGroupName -AutomationAccountName $AutomationAccountName -Type PowerShell -Published -Force
Write-Host $ScriptPrefix "Runbook created successfully with version" $RunbookScriptVersion


# Credential object creation
Write-host "Creating secure credentials object for Azure Global Reader in Automation accout" -ForegroundColor Yellow
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AzureGlobalReaderEmailId, $AzureGlobalReaderPassword
$AzureADReaderCredentials = "AzureADReaderCredentials"
$ExistingCredentials = Get-AzAutomationCredential -Name $AzureADReaderCredentials -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue

If ($ExistingCredentials -ne $null -and $ExistingCredentials.UserName -eq $AzureGlobalReaderEmailId) {
    Set-AzAutomationCredential -AutomationAccountName $AutomationAccountName -Name $AzureADReaderCredentials -Value $Credential -ResourceGroupName $ResourceGroupName
    Write-Host $AzureGlobalReaderEmailId "credential object already exist, Updated sucessfully" -ForegroundColor Green
}    
else {
    New-AzAutomationCredential -AutomationAccountName $AutomationAccountName -Name $AzureADReaderCredentials -Value $Credential -ResourceGroupName $ResourceGroupName
    Write-Host $AzureGlobalReaderEmailId "credentials object created successfully" -ForegroundColor Green
}

# Credential object creation
Write-host "Creating secure credentials object for client service principal in Automation account" -ForegroundColor Yellow
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ZCSPMApplicationId, $ZCSPMApplicationSecret
$ZCSPMCredentials = "ZCSPMCredentials"
$ExistingCredentials = Get-AzAutomationCredential -Name $ZCSPMCredentials -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue

If ($ExistingCredentials -ne $null -and $ExistingCredentials.UserName -eq $AzureGlobalReaderEmailId) {
    Set-AzAutomationCredential -AutomationAccountName $AutomationAccountName -Name $ZCSPMCredentials -Value $Credential -ResourceGroupName $ResourceGroupName
    Write-Host $ZCSPMApplicationId "credential object already exists, Updated sucessfully" -ForegroundColor Green
}    
else {
    New-AzAutomationCredential -AutomationAccountName $AutomationAccountName -Name $ZCSPMCredentials -Value $Credential -ResourceGroupName $ResourceGroupName
    Write-Host $ZCSPMApplicationId "credentials object created successfully" -ForegroundColor Green
}


# Creating variable in Azure automation
$ZCSPMAPIKeyEncrypt = (New-Object PSCredential "user",$ZCSPMAPIKey).GetNetworkCredential().Password

$VariableObject = @{    
    "ZCSPMLicenseId"        = $ZCSPMLicenseId;
    "ZCSPMAccountId"        = $ZCSPMAccountId; 
    "ZCSPMEnvironment"      = $ZCSPMEnvironment;
    "AzureDirectoryId"      = $AzureActiveDirectoryId;
    "ZCSPMAPIKey"           = $ZCSPMAPIKeyEncrypt;
    "ZCSPMAPIURL"           = $ZCSPMAPIURL;
    "DataCollectorVersion"  = $DataCollectorVersion;
}

Write-Host "Creating Azure automation variables in automation account"
foreach ($Variable in $VariableObject.GetEnumerator()) {
    $ExistingVariable = Get-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $Variable.Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    If ($ExistingVariable -ne $null -and $ExistingVariable.Value -eq $Variable.Value) {
        Write-Host $Variable.Name "variable already exists" -ForegroundColor Yellow
    }
    else {
        if ($ExistingVariable -ne $null) {
            if ($Variable.Name -eq "ZCSPMAPIKey") {
                Write-Host "Updating variable value of" $Variable.Name -ForegroundColor Yellow
                Set-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $Variable.Name -Encrypted $true -Value $Variable.Value -ResourceGroupName $ResourceGroupName
                Write-Host $Variable.Name "variable successfully updated" -ForegroundColor Green
            }
            else {
                Write-Host "Updating variable value of" $Variable.Name -ForegroundColor Yellow
                Set-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $Variable.Name -Encrypted $False -Value $Variable.Value -ResourceGroupName $ResourceGroupName
                Write-Host $Variable.Name "variable successfully updated" -ForegroundColor Green
            }
        }
        else {
            if ($Variable.Name -eq "ZCSPMAPIKey") {
                Write-Host "Creating variable " $Variable.Name -ForegroundColor Yellow
                New-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $Variable.Name -Encrypted $true -Value $Variable.Value -ResourceGroupName $ResourceGroupName
                Write-Host $Variable.Name "variable successfully created" -ForegroundColor Green
            }
            else {
                Write-Host "Creating variable " $Variable.Name -ForegroundColor Yellow
                New-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $Variable.Name -Encrypted $False -Value $Variable.Value -ResourceGroupName $ResourceGroupName
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
    New-AzAutomationSchedule -ResourceGroupName $ResourceGroupName –AutomationAccountName $AutomationAccountName –Name $scheduleName –StartTime $StartTime –DayInterval 1
    Write-Host "Successfully created the automation account schedule" $scheduleName
}
catch [Exception] {
    Write-Host "Error occurred while creating automation schedule"
    Write-Output $_
}

# Link schedule to the automation account	
try {
    Write-Host "Linking automation account schedule $scheduleName to runbook $RunbookName"
    Register-AzAutomationScheduledRunbook -ResourceGroupName $ResourceGroupName –AutomationAccountName $AutomationAccountName –RunbookName $RunbookName -ScheduleName $scheduleName
    Write-Host "Successfully linked the automation account schedule $scheduleName to runbook $RunbookName"
}
catch [Exception] {
    Write-Host "Error occurred while linking automation schedule $scheduleName to runbook $RunbookName"
    Write-Output $_
}
Write-host "Script execution completed" 