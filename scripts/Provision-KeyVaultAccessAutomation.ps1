<#
.SYNOPSIS
    Script to provision an automation to assign keyvault access to Cloudneeti.
    
.DESCRIPTION
     This script creates an automation account, Runbook, Schedule for execution and required variables & credentials to connect to subscription.
     The automation runbook executes once per day and assigns read permissions for keys and secrets to cloudneeti application.
 
.NOTES
    Version:        1.0
    Author:         Cloudneeti
    Creation Date:  09/08/2019

    # PREREQUISITE
    * <TBA>

.EXAMPLE
    Upload script to Azure CloudShell and execute below command:-
    .\Provision-KeyVaultAccessAutomation.ps1

    Then script execution will prompt for below inputs:
        - Cloudneeti ServicePrincipal ObjectId
        - ServicePrincipal  Id
        - ServicePrincipal Secret
        - SubscriptionId
        - TenantId
        - AutomationAccountName
        - Location

.INPUTS
    Below is the list of inputs to the script:-
        - Cloudneeti ServicePrincipal ObjectId <Find in "Azure Portal -> Azure Active Directory -> Enterprize Application" of Cloudneeti Application>
        - ServicePrincipal  Id <Find in "Azure Portal -> Azure Active Directory -> App registration -> App id>
        - ServicePrincipal Secret <Get this value at the time of creating serviceprincipal>
        - SubscriptionId <Subscription onboarded to cloudneeti>
        - TenantId <TenantId>
        - AutomationAccountName <Automation account deploys with this name>
        - Location <Location where automation is deployed>

.OUTPUTS

.NOTES
        - The user should have an active license with Cloudneeti
        - This script should be executed only on Azure CloudShell.
        - The automation should be deployed in tha same subscription as that of key vaults. Additional subscriptions can be added to it later.
        - To add additional subscription, update the subscription id variable with comma seperated list of subscription ids.
        - The Contributor service principal should have contributor access to all the required subscriptions where keyvaults are present.
        - The Contributor service principal should have "Azure Active Directory Graph - Application.ReadWrite.All" permission over tenant.
        - https://docs.microsoft.com/en-us/azure/key-vault/key-vault-secure-your-key-vault#data-plane-and-access-policies
#>

[CmdletBinding()]
param
(

    # Cloudneeti Service Principal Object Id
    [Parameter(Mandatory = $False,
        HelpMessage = "Cloudneeti Service Principal Object Id",
        Position = 1
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $CloudneetiServicePrincipalObjectId = $(Read-Host -prompt "Enter Cloudneeti Service Principal Object Id"),

    # Contributor Service Principal App Id
    [Parameter(Mandatory = $False,
        HelpMessage = "Contributor Service Principal App Id",
        Position = 2
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $ServicePrincipalId = $(Read-Host -prompt "Enter Contributor Service Principal App Id"),

    # Contributor Service Principal Secret
    [Parameter(Mandatory = $False,
        HelpMessage = "Contributor Service Principal Secret",
        Position = 3
    )]
    [ValidateNotNullOrEmpty()]
    [secureString]
    $ServicePrincipalSecret = $(Read-Host -prompt "Enter Contributor Service Principal Secret" -AsSecureString),

    # Subscription ID
    [Parameter(Mandatory = $False,
        HelpMessage = "Subscription ID",
        Position = 4
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $SubscriptionId = $(Read-Host -prompt "Enter Subscription ID"),

    # Tenant ID
    [Parameter(Mandatory = $False,
        HelpMessage = "Tenant ID",
        Position = 5
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $TenantId = $(Read-Host -prompt "Enter Tenant ID"),

    # Automation Account Name
    [Parameter(Mandatory = $False,
        HelpMessage = "Automation Account Name",
        Position = 6
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $AutomationAccountName = $(Read-Host -prompt "Enter Automation Account Name"),

    # Automation Account resource location
    [Parameter(Mandatory = $False,
        HelpMessage = "Location for Automation Account resources",
        Position = 7
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $Location = "eastus2"
)

# Session configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

# Resource names declaration

$ResourceGroupName = "$AutomationAccountName-rg"
$Tags = @{"Service" = "Cloudneeti-KeyVaultAccessMgmt" }
$RunbookName = "AutoAssignCloudneetiKeyVaultPermission"

$RequiredModules = @"
[
    {
        "Name": "Az.Accounts",
        "ContentUrl" : "https://www.powershellgallery.com/api/v2/package/Az.Accounts/1.6.1"
    },
    {
        "Name": "Az.KeyVault",
        "ContentUrl" : "https://www.powershellgallery.com/api/v2/package/Az.KeyVault/1.3.0"
    }
]
"@ | ConvertFrom-Json

Set-AzContext -Subscription $SubscriptionId | Out-Host

# Check if azure automation account exist or not.

$AllAutomationAccountList = Get-AzAutomationAccount | Select-Object AutomationAccountName

if ($AllAutomationAccountList.AutomationAccountName -contains $AutomationAccountName) {
    Write-Host "Automation already exists with the name:" $AutomationAccountName -ForegroundColor Magenta
    Write-Host "Please choose different name and Re-run this script" -ForegroundColor Yellow
    break
} 

# Resource Group creation
Write-host "Creating Resource Group for Automation resources" -ForegroundColor Yellow
New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tags $Tags -Force

# Automation account creation
Write-Host "Creating Azure Automation Account" -ForegroundColor Yellow
New-AzAutomationAccount -Name $AutomationAccountName -ResourceGroupName $ResourceGroupName -Location $Location

Write-host "Acquiring Auth Token..." -ForegroundColor Yellow
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
$token = $profileClient.AcquireAccessToken($TenantId)

# Importing required modules
Write-Host "Importing required modules into the automation account..." -ForegroundColor Yellow

$RequiredModules | ForEach-Object {
    Write-Host "Importing" $_.Name "PowerShell module" -ForegroundColor Yellow
    New-AzAutomationModule -AutomationAccountName $AutomationAccountName -Name $_.Name -ContentLink $_.ContentUrl -ResourceGroupName $ResourceGroupName

    if ($_.Name -eq "Az.Accounts") {
        $res = $null
        do {
            Start-Sleep 5
            Write-Host "Waiting for Az.Accounts module import to complete..." -NoNewline
            $res = Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/modules/Az.Accounts?api-version=2015-10-31" -Method Get -Headers @{Authorization = "Bearer $($token.AccessToken)" }
            $res.properties.provisioningState | Out-Host
        } while ($res.properties.provisioningState -ne "Succeeded")

    }
}

# Runbook creation
Write-Host "Creating powershell runbook" -ForegroundColor Yellow
Import-AzureRmAutomationRunbook -Name $RunbookName `
    -AutomationAccountName $AutomationAccountName `
    -ResourceGroupName $ResourceGroupName `
    -Type PowerShell `
    -Path ".\AutoAssign-PermissionsToKeyvault.ps1" `
    -Published `
    -Tags $Tags `
    -Description "This runbook will provide cloudneeti read access to all keyvaults in the subscription."

# Credential object creation
Write-host "Creating secure credentials object contributor service principal in Automation accout" -ForegroundColor Yellow
$Credential = New-Object -TypeName System.Management.Automation.PSCredential($ServicePrincipalId, $ServicePrincipalSecret)
New-AzAutomationCredential -Name "ContributorSPCredentials" -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Value $Credential

# Creating variable in Azure automation
$VariableTable = @{    
    "CloudneetiServicePrincipalObjectId" = $CloudneetiServicePrincipalObjectId
    "SubscriptionId"                     = $SubscriptionId
    "TenantId"                           = $TenantId
}

foreach ($Variable in $VariableTable.GetEnumerator()) {
    Write-Host "Creating variable " $Variable.Name -ForegroundColor Yellow
    New-AzAutomationVariable -Name $Variable.Name -Value $Variable.Value -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Encrypted $False
}

# Credential object creation
Write-Host "Creating automation account schedule"
$StartTime = (Get-Date).AddMinutes(10)
$ScheduleName = "DailySchedule"
New-AzAutomationSchedule -Name $ScheduleName -StartTime $StartTime -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -DayInterval 1

Write-Host "Linking automation account schedule $ScheduleName to runbook $RunbookName"
Register-AzAutomationScheduledRunbook -ScheduleName $ScheduleName -RunbookName $RunbookName -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName

Write-host "Script execution completed"