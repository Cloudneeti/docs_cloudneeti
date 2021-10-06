<#
.SYNOPSIS
    Script to on-board Office 365 account for PowerShell policy data collection inside Zscaler CSPM.
    
.DESCRIPTION
     This script creates an automation account, Runbook, Schedule for execution and required variables & credentials for running the M365 policies. The automation runbook executes once per day and export data to Zscaler CSPM using Zscaler CSPM API.
 
.NOTES

  Copyright (c) Zscaler CSPM. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Version:        1.8
    Author:         Zscaler CSPM
    Creation Date:  23/11/2020
    Last Modified Date: 22/10/2020

    # PREREQUISITE
    * <TBA>

.EXAMPLE
    Upload script to Azure CloudShell and execute below command:-
    .\Provision-M365DataCollector.ps1

    Then script execution will prompt for below secrets:
        - ZCSPM License Id
        - ZCSPM Account Id
        - ZCSPM API Key
        - ZCSPM Environment
        - ZCSPM Application Id
        - ZCSPM Application Secret
        - ZCSPM Office 365 Data Collector Artifacts Storage Name
        - ZCSPM Office 365 Data Collector Artifacts Storage Access Key
        - ZCSPM Office 365 Data Collector Version
        - Office 365 Domain Name
        - SharePoint Admin Center URL
        - Office 365 Directory Id
        - Office 365 Administator Email Id
        - Office 365  App Password or User Password
        - Azure Subscription Id where office 365 data collector resouces will be created
        - Office 365 data collector name
        - Location

.INPUTS
    Below is the list of inputs to the script:-
        - ZCSPM License Id <Find in "Manage Licenses" of ZCSPM Settings>
        - ZCSPM Account Id <Find in "Manage Accounts" of ZCSPM Settings>
        - ZCSPM API Management Key <Find in "ZCSPM API Management Portal">
        - ZCSPM Environment <ZCSPM Environment>
        - ZCSPM Data Collector Application Id
        - ZCSPM Data Collector Application Secret 
        - ZCSPM Office 365 Data Collector Artifacts Storage Name <Contact ZCSPM team>
        - ZCSPM Office 365 Data Collector Artifacts Storage Access Key <Contact ZCSPM team>
        - ZCSPM Office 365 Data Collector Version <Contact ZCSPM team>
        - Office 365 Domain Name <Office 365 domian name>
        - SharePoint Admin Center URL 
        - Office 365 Directory Id <Directory Id of Office 365>
        - Office 365 Administator Email Id <Office 365 Global Administrator Email Id>
        - Office 365 App Password <Office 365 Administrator App password or User password>
        - Azure Subscription Id where office 365 data collector resouces will be created <Azure Subscription Id where office 365 data collector resouces will be created> 
        - Office 365 data collector name
        - Location

.OUTPUTS

.NOTES
        - The user should have a contract with Zscaler CSPM 
        - Office Admin should have MFA enabled and App Password for Office Admin
        - This script should be executed only on Azure CloudShell.
        - Office administrator should have "Enterprise E5" office license
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
        HelpMessage = "ZCSPM Data collector application Id",
        Position = 5
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $ZCSPMApplicationId = $(Read-Host -prompt "Enter ZCSPM Data Collector application Id"),

    # Enter service principal secret
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM Data collector application secret",
        Position = 6
    )]
    [ValidateNotNullOrEmpty()]
    [SecureString]
    $ZCSPMApplicationSecret = $(Read-Host -prompt "Enter ZCSPM Data Collector Application Secret" -AsSecureString),

    # ZCSPM Artifacts Storage Name
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM office 365 Data Collector Artifact Name",
        Position = 7
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $ArtifactsName = $(Read-Host -prompt "Enter ZCSPM office 365 Data Collector Artifacts Storage Name"),

    # ZCSPM artifacts access key
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM office 365 Data Collector Artifacts Acccess Key",
        Position = 8
    )]
    [ValidateNotNullOrEmpty()]
    [secureString]
    $ArtifactsAccessKey = $(Read-Host -prompt "Enter ZCSPM office 365 Data Collector Artifacts Storage Access Key" -AsSecureString),

    # Data Collector version
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM office 365 Data Collector Artifacts Version",
        Position = 9
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataCollectorVersion = $(Read-Host -prompt "Enter ZCSPM Office 365 Data Collector Version"),

    # Office Domain name
    [ValidateScript( {$_ -notmatch 'https://+' -and $_ -notmatch 'http://+'})]
    [Parameter(Mandatory = $False,
        HelpMessage = "Office 365 Domain Name",
        Position = 10
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $OfficeDomain = $(Read-Host -prompt "Enter Office 365 Domain Name"),

    # SharePoint URL
    [ValidateScript({$_ -notmatch 'http://+'})]
    [Parameter(Mandatory = $False,
        HelpMessage = "SharePoint URL",
        Position = 11
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $SharePointAdminCenterURL = $(Read-Host -prompt "Enter SharePoint admin center URL"),

    # Office Directory ID
    [Parameter(Mandatory = $False,
        HelpMessage = "Office 365 Directory Id",
        Position = 12
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $OfficeDirectoryId = $(Read-Host -prompt "Enter Office 365 Directory Id"),

    # Office Admin username
    [ValidateScript( {$_ -match '^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,7})$' })]
    [Parameter(Mandatory = $False,
        HelpMessage = "Office 365 Administator Email Id",
        Position = 13
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $OfficeAdminEmailId = $(Read-Host -prompt "Enter Office 365 Administator Email Id"),

    # Office App password or user password
    [Parameter(Mandatory = $False,
        HelpMessage = "Office 365 app password or user password",
        Position = 14
    )]
    [ValidateNotNullOrEmpty()]
    [SecureString]
    $Office365AppPassword = $(Read-Host -prompt "Enter Office 365 App Password or User Password" -AsSecureString),

    # Subscription Id for automation account creation
    [Parameter(Mandatory = $False,
        HelpMessage = "Azure Subscription Id for office 365 data collector resources provisioning",
        Position = 15
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $AzureSubscriptionId = $(Read-Host -prompt "Enter Azure Subscription Id where office 365 data collector resouces will be created"),

    # Resource group name for ZCSPM Resouces
    [Parameter(Mandatory = $False,
        HelpMessage = "Office 365 Data Collector Name",
        Position = 16
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataCollectorName = $(Read-Host -prompt "Enter office 365 data collector name"),

    # Data collector resource location
    [Parameter(Mandatory = $False,
        HelpMessage = "Location for ZCSPM office 365 data collector resources",
        Position = 17
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
$ScriptPrefix = "M365DataCollector"
$ContianerName = "m365-datacollection-script"
$RunbookScriptName = "$ScriptPrefix-$DataCollectorVersion.ps1"
$RunbookName = "$ScriptPrefix-$DataCollectorVersion"
$path = "./runbooks"
$Tags = @{"Service" = "ZCSPM-Office365-Data-Collection"}
if($SharePointAdminCenterURL -notlike "https://*"){
    $SharePointAdminCenterURL = "https://$SharePointAdminCenterURL"
}

# ZCSPM API URL
$ZCSPMAPIEndpoints = @{
    dev   = "https://devapi.cloudneeti-devops.com";
    trial = "https://trialapi.cloudneeti.com";
    qa    = "https://qaapi.cloudneeti-devops.com";
    prod  = "https://api.cloudneeti.com";
    prod1 = "https://api1.cloudneeti.com"
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

# Download cis m365 scan script to push in to Azure automation runbook
Write-host "Fetching Office 365 scanning script to create Azure automation runbook..." -ForegroundColor Yellow
$ArtifactsKey = (New-Object PSCredential "user",$ArtifactsAccessKey).GetNetworkCredential().Password
$CNConnectionString = "BlobEndpoint=https://$ArtifactsName.blob.core.windows.net/;SharedAccessSignature=$ArtifactsKey"
$PackageContext = New-AzStorageContext -ConnectionString $CNConnectionString

New-Item -ItemType Directory -Force -Path $path | Out-Null

Get-AzStorageBlobContent -Container $ContianerName -Blob $RunbookScriptName -Destination "./runbooks/" -Context $PackageContext -Force | Out-Null
Write-Host "Office 365 scanning script successfully fetched and ready to push in automation runbook" -ForegroundColor Green


$RequiredModules = @"
{
    Modules: [
        {
            "Product": "SharePoint",
            "Name": "Microsoft.Online.SharePoint.PowerShell",
            "ContentUrl" : "https://www.powershellgallery.com/api/v2/package/Microsoft.Online.SharePoint.PowerShell/16.0.8414.1200",
            "Version" : "16.0.8414.1200"
        },
        {
            "Product": "AzureRM.Profile",
            "Name": "AzureRM.Profile",
            "ContentUrl" : "https://www.powershellgallery.com/api/v2/package/AzureRM.profile/5.8.3",
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
Write-host "Creating secure credentials object for office admin in Automation accout" -ForegroundColor Yellow
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $OfficeAdminEmailId, $Office365AppPassword
$OfficeAdminCredentials = "OfficeAdminCredentials"
$ExistingCredentials = Get-AzAutomationCredential -Name $OfficeAdminCredentials -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue

If ($ExistingCredentials -ne $null -and $ExistingCredentials.UserName -eq $OfficeAdminEmailId) {
    Set-AzAutomationCredential -AutomationAccountName $AutomationAccountName -Name $OfficeAdminCredentials -Value $Credential -ResourceGroupName $ResourceGroupName
    Write-Host $OfficeAdminEmailId "credential object already exist, Updated sucessfully" -ForegroundColor Green
}    
else {
    New-AzAutomationCredential -AutomationAccountName $AutomationAccountName -Name $OfficeAdminCredentials -Value $Credential -ResourceGroupName $ResourceGroupName
    Write-Host $OfficeAdminEmailId "credentials object created successfully" -ForegroundColor Green
}

# Credential object creation
Write-host "Creating secure credentials object for client service principal in Automation account" -ForegroundColor Yellow
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ZCSPMApplicationId, $ZCSPMApplicationSecret
$ZCSPMCredentials = "ZCSPMCredentials"
$ExistingCredentials = Get-AzAutomationCredential -Name $ZCSPMCredentials -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue

If ($ExistingCredentials -ne $null -and $ExistingCredentials.UserName -eq $OfficeAdminEmailId) {
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
    "ZCSPMContractId"           = $ZCSPMLicenseId;
    "ZCSPMAccountId"            = $ZCSPMAccountId; 
    "OfficeDomain"              = $OfficeDomain;
    "ZCSPMEnvironment"          = $ZCSPMEnvironment;
    "OfficeDirectoryId"         = $OfficeDirectoryId;
    "ZCSPMAPIKey"               = $ZCSPMAPIKeyEncrypt;
    "ZCSPMAPIURL"               = $ZCSPMAPIURL;
    "DataCollectorVersion"      = $DataCollectorVersion;
    "SharePointAdminCenterURL"  = $SharePointAdminCenterURL
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
    New-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $scheduleName -StartTime $StartTime -DayInterval 1
    Write-Host "Successfully created the automation account schedule" $scheduleName
}
catch [Exception] {
    Write-Host "Error occurred while creating automation schedule"
    Write-Output $_
}

# Link schedule to automation account	
try {
    Write-Host "Linking automation account schedule $scheduleName to runbook $RunbookName"
    Register-AzAutomationScheduledRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -RunbookName $RunbookName -ScheduleName $scheduleName
    Write-Host "Successfully linked the automation account schedule $scheduleName to runbook $RunbookName"
}
catch [Exception] {
    Write-Host "Error occurred while linking automation schedule $scheduleName to runbook $RunbookName"
    Write-Output $_
}
Write-host "Script execution completed" 