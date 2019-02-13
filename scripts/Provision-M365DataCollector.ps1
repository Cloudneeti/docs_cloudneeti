<#
.SYNOPSIS
    Script to on-board M365 account for powershell policy data collection inside Cloudneeti.
    
.DESCRIPTION
    This script creates an automation account, Runbook, Schedule for execution and required variables & credentials for running the M365 policies. The automation runbook execute once per day and export data to cloudneeti using Cloudneeti API.
 
.NOTES
    Version:        1.0
    Author:         Cloudneeti
    Creation Date:  11/02/2018

    # PREREQUISITE
    * <TBA>

.EXAMPLE
    Upload script to Azure CloudShell and execute below command:-
    .\Provision-M365DataCollector.ps1 -CloudneetiLicenseId <Cloudneeti Contract Id> -CloudneetiAccountId <Cloudneeti Account Id> -CloudneetiEnvironment <Cloudneeti Environment> -ADApplicationId <Cloudneeti data  collector service principal Id> -ArtifactsName <Cloudneeti M365 data collector artifacts name> -DataCollectorVersion <optional> <version of artifacts> -OfficeDomain <Office Domain Name>  -OfficeTenantId <Office tenant Id> -OfficeAdminId <Office Administrator user Id> -AzureSubscriptionId <Subscription Id to deploy automation account> -DataCollectorName <optional> <Automation account name> -Location <optional> <Region to deploy automation account>

    Then script execution will prompt for below secrets:
        - Cloudneeti API Key
        - Cloudneeti Data Collector Service Principal Secret
        - Cloudneeti M365 Data  Collector Artifacts Storage Access Key
        - Office Administator Password


.INPUTS

.OUTPUTS

.NOTES
    - User should have contract with Cloudneeti 
    - Office Admin should have MFA disabled
    - This script can be execute only on Azure CloudShell
    - Office administrator should have "Enterprise E5" office license
#>

[CmdletBinding()]
param
(

    # Cloudneeti contract Id
    [Parameter(Mandatory = $False,
        HelpMessage="Cloudneeti License Id",
        Position=1
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $CloudneetiLicenseId = $(Read-Host -prompt "Enter Cloudneeti License Id"),

    # Cloudneeti account Id
    [Parameter(Mandatory = $False,
        HelpMessage="Cloudneeti Account Id",
        Position=2
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $CloudneetiAccountId = $(Read-Host -prompt "Enter Cloudneeti Account Id"),

    # Cloudneeti API key
    [Parameter(Mandatory = $False,
        HelpMessage="Cloudneeti API Key",
        Position=3
    )]
    [ValidateNotNullOrEmpty()]
    [secureString]
    $CloudneetiAPIKey = $(Read-Host -prompt "Enter Cloudneeti API Key" -AsSecureString),

    # Cloudneeti Environment
    [Parameter(Mandatory = $False,
        HelpMessage="Cloudneeti Environment",
        Position=4
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $CloudneetiEnvironment = $(Read-Host -prompt "Enter Cloudneeti Environment"),

    # Cloudneeti Service principal id
    [Parameter(Mandatory = $False,
        HelpMessage="Cloudneeti Data collector Service Principal Id",
	Position=5
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $ADApplicationId = $(Read-Host -prompt "Enter Cloudneeti Data Collector Service Principal Id"),

    # Enter service principal secret
    [Parameter(Mandatory = $False,
        HelpMessage="Cloudneeti Data collector Service Principal password",
	Position=6
    )]
    [ValidateNotNullOrEmpty()]
    [SecureString]
    $ADApplicationSecret =$(Read-Host -prompt "Enter Cloudneeti Data Collector Service Principal Secret" -AsSecureString),

    # Cloudneeti Artifacts Storage Name
    [Parameter(Mandatory = $False,
        HelpMessage="Cloudneeti M365 Data Collector Artifact Name",
	Position=7
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $ArtifactsName = $(Read-Host -prompt "Enter Cloudneeti M365 Data Collector Artifacts Storage Name"),

    # Cloudneeti artifacts access key
    [Parameter(Mandatory = $False,
        HelpMessage="Cloudneeti M365 Data Collector Artifacts Acccess Key",
        Position=8
    )]
    [ValidateNotNullOrEmpty()]
    [secureString]
    $ArtifactsAccessKey = $(Read-Host -prompt "Enter Cloudneeti M365 Data Collector Artifacts Storage Access Key" -AsSecureString),

    # Data Collector version
    [Parameter(Mandatory = $False,
        HelpMessage="Cloudneeti M365 Data Collector Version",
	Position=9
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataCollectorVersion = $(Read-Host -prompt "Enter Cloudneeti M365 Data Collector Version"),

    # Office Domain name
    [ValidateScript( {$_ -notmatch 'https://+' -and $_ -notmatch 'http://+'})]
    [Parameter(Mandatory = $False,
        HelpMessage="Office 365 Domain Name: ",
	Position=10
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $OfficeDomain = $(Read-Host -prompt "Enter Office 365 Domain Name"),

    # Office Tenant ID
    [Parameter(Mandatory = $False,
        HelpMessage="Office 365 Tenant Id",
	Position=11
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $OfficeTenantId = $(Read-Host -prompt "Enter Office 365 Tenant Id"),

    # Office Admin username
    [ValidateScript( {$_ -match '^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,7})$' })]
    [Parameter(Mandatory = $False,
        HelpMessage="Office 365 Administator Id",
	Position=12
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $OfficeAdminId = $(Read-Host -prompt "Enter Office 365 Administator Id"),

    # Office Admin password
    [Parameter(Mandatory = $False,
        HelpMessage="Office 365 Administator password",
	Position=13
    )]
    [ValidateNotNullOrEmpty()]
    [SecureString]
    $OfficeAdminPassword = $(Read-Host -prompt "Enter Office 365 Administator Password" -AsSecureString),

    # Subscription Id for automation account creation
    [Parameter(Mandatory = $False,
        HelpMessage="Azure Subscription Id for office 365 data collector resources provisioning",
        Position=14
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $AzureSubscriptionId = $(Read-Host -prompt "Enter Azure Subscription Id where office 365 data collector resouces will be created"),

    # Resource group name for Cloudneeti Resouces
    [Parameter(Mandatory = $False,
        HelpMessage="Office 365 Data Collector Name"
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataCollectorName = "cloundneeti-office-365-datacollector",

    # Data collector resource location
    [Parameter(Mandatory = $False,
        HelpMessage="Location for Cloudneeti office 365 data collector resources",
        Position=16
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

$AutomationAccountName

$ResourceGroupName = "$DataCollectorName-rg"
$ScriptPrefix = "M365DataCollector"
$ContianerName = "m365-datacollection-script"
$RunbookScriptName = "$ScriptPrefix-$DataCollectorVersion.ps1"
$RunbookName = "$ScriptPrefix-$DataCollectorVersion"
$path = "./runbooks"
$Tags = @{"Service"="Cloudneeti-M365-Data-Collection"}

# Cloudneeti API URL
$CloudneetiAPIEndpoints = @{
    dev="https://devapi.cloudneeti-devops.com";
    test="https://testapi.cloudneeti-devops.com";
    trial="https://trialapi.cloudneeti-devops.com";
    qa="https://qaapi.cloudneeti-devops.com";
}
$CloudneetiAPIURL = $CloudneetiAPIEndpoints[$CloudneetiEnvironment.ToLower()]

# Checking current azure rm context to deploy Azure automation
$AzureContextSubscriptionId = (Get-AzureRmContext).Subscription.Id

If ($AzureContextSubscriptionId -ne $AzureSubscriptionId){
    Write-Host "You are not logged in to subscription" $AzureSubscriptionId 
    Try{
        Write-Host "Trying to switch powershell context to subscription" $AzureSubscriptionId
        $AllAvailableSubscriptions = (Get-AzureRmSubscription).Id
        if ($AllAvailableSubscriptions -contains $AzureSubscriptionId)
        {
            Set-AzureRmContext -SubscriptionId $AzureSubscriptionId
            Write-Host "Successfully context switched to subscription" $AzureSubscriptionId
        }
        else{
            Write-Host "Looks like the" $AzureSubscriptionId "is not present in current powershell context or you dont have access"
        }
    }
    catch [Exception]{
        Write-Output $_
    }
}

Write-host "Fetching M365 scanning script to create Azure automation runbook..." -ForegroundColor Yellow
# Download cis m365 scan script to push in to Azure automation runbook
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ArtifactsAccessKey)            
$ArtifactsKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) 
$CNConnectionString  = "DefaultEndpointsProtocol=https;AccountName=$ArtifactsName;AccountKey=$ArtifactsKey;EndpointSuffix=core.windows.net"
$PackageContext = New-AzureStorageContext -ConnectionString $CNConnectionString

New-Item -ItemType Directory -Force -Path $path | Out-Null

Get-AzureStorageBlobContent -Container $ContianerName -Blob $RunbookScriptName -Destination "./runbooks/" -Context $PackageContext -Force | Out-Null
Write-Host "M365 scanning script successfully fetched and ready to push in automation runbook" -ForegroundColor Green


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
            "Product": "SkypeOnline",
            "Name": "SkypeOnlineConnector",
            "ContentUrl" : "https://$ArtifactsName.blob.core.windows.net/modules/SkypeOnlineConnector.zip",
            "Version" : "7.0.0.0"
        }
    ]
}
"@

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
Write-host "Creating secure credentials object for office admin in Automation accout" -ForegroundColor Yellow
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $OfficeAdminId, $OfficeAdminPassword
$OfficeAdminCredentials = "OfficeAdminCredentials"
$ExistingCredentials = Get-AzureRmAutomationCredential -Name $OfficeAdminCredentials -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue

If ($ExistingCredentials -ne $null -and $ExistingCredentials.UserName -eq $OfficeAdminId){
        Set-AzureRmAutomationCredential -AutomationAccountName $AutomationAccountName -Name $OfficeAdminCredentials -Value $Credential -ResourceGroupName $ResourceGroupName
        Write-Host $OfficeAdminId "credential object already exist, Updated sucessfully" -ForegroundColor Green
}    
else{
        New-AzureRmAutomationCredential -AutomationAccountName $AutomationAccountName -Name $OfficeAdminCredentials -Value $Credential -ResourceGroupName $ResourceGroupName
        Write-Host $OfficeAdminId "credentials object created successfully" -ForegroundColor Green
}

# Credential object creation
Write-host "Creating secure credentials object for clinet service principal in Automation account" -ForegroundColor Yellow
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ADApplicationId, $ADApplicationSecret
$CloudneetiCredentials = "CloudneetiCredentials"
$ExistingCredentials = Get-AzureRmAutomationCredential -Name $CloudneetiCredentials -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue

If ($ExistingCredentials -ne $null -and $ExistingCredentials.UserName -eq $OfficeAdminId){
        Set-AzureRmAutomationCredential -AutomationAccountName $AutomationAccountName -Name $CloudneetiCredentials -Value $Credential -ResourceGroupName $ResourceGroupName
        Write-Host $ADApplicationId "credential object already exist, Updated sucessfully" -ForegroundColor Green
}    
else{
        New-AzureRmAutomationCredential -AutomationAccountName $AutomationAccountName -Name $CloudneetiCredentials -Value $Credential -ResourceGroupName $ResourceGroupName
        Write-Host $ADApplicationId "credentials object created successfully" -ForegroundColor Green
}


# Creating variable in Azure automation
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($CloudneetiAPIKey)            
$CloudneetiAPIKeyEncrypt = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$VariableObject = @{    
                    "CloudneetiContractId"=$CloudneetiLicenseId;
                    "CloudneetiAccountId"=$CloudneetiAccountId; 
                    "OfficeDomain" = $OfficeDomain;
                    "CloudneetiEnvironment" = $CloudneetiEnvironment 
                    "OfficeTenantId" = $OfficeTenantId
                    "CloudneetiAPIKey" = $CloudneetiAPIKeyEncrypt
                    "CloudneetiAPIURL" = $CloudneetiAPIURL
}

Write-Host "Creating Azure automation variables in automation account"
foreach ($Variable in $VariableObject.GetEnumerator()){
    $ExistingVariable = Get-AzureRmAutomationVariable -AutomationAccountName $AutomationAccountName -Name $Variable.Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    If ($ExistingVariable -ne $null -and $ExistingVariable.Value -eq $Variable.Value)
    {
      Write-Host $Variable.Name "variable already exist" -ForegroundColor Yellow
    }
    else{
        if($ExistingVariable -ne $null){
            if($Variable.Name -eq "CloudneetiAPIKey"){
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
        else
        {
            if($Variable.Name -eq "CloudneetiAPIKey"){
                Write-Host "Creating variable " $Variable.Name -ForegroundColor Yellow
                New-AzureRmAutomationVariable -AutomationAccountName $AutomationAccountName -Name $Variable.Name -Encrypted $true -Value $Variable.Value -ResourceGroupName $ResourceGroupName
                Write-Host $Variable.Name "variable successfully created" -ForegroundColor Green
            }
            else{
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
    $scheduleName = "$RunbookName-DailySchedule" 
    $StartTime = (Get-Date).AddMinutes(8)
    New-AzureRmAutomationSchedule -ResourceGroupName $ResourceGroupName –AutomationAccountName $AutomationAccountName –Name $scheduleName –StartTime $StartTime –DayInterval 1
    Write-Host "Successfully created the automation account schedule $scheduleName."
}
catch [Exception]{
    Write-Host "Error occurred while creating automation schedule."
    Write-Output $_
}

# Link schedule to automation account	
try {
    Write-Host "Linking automation account schedule $scheduleName to runbook $RunbookName"
    Register-AzureRmAutomationScheduledRunbook -ResourceGroupName $ResourceGroupName –AutomationAccountName $AutomationAccountName –RunbookName $RunbookName –ScheduleName $scheduleName
    Write-Host "Successfully linked the automation account schedule $scheduleName to runbook $RunbookName"
}
catch [Exception]{
    Write-Host "Error occurred while linking automation schedule $scheduleName to runbook $RunbookName"
    Write-Output $_
}

Write-host "Script execution completed." -ForegroundColor Cyan
