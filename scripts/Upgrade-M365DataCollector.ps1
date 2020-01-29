<#
.SYNOPSIS
    Script to upgrade Cloudneeti Office 365 data collector automation account
.DESCRIPTION
    This script will upgrade runbbok from O365 data collector(Automation Account) and deprecate older version on runbbok.
.EXAMPLE
    Commands to run this script.
     Upload script to Azure CloudShell and execute below command:-
    .\Upgrade-M365DataCollector.ps1

     Then script execution will prompt for below inputs and secrets:
            - Enter Cloudneeti office 365 Data Collector Artifacts Storage Name
            - Enter Cloudneeti office 365 Data Collector Artifacts Storage Access Key
            - Enter Cloudneeti Office 365 Data Collector Version
            - Enter Azure Subscription Id where office 365 data collector resouces is present
            - Enter office 365 data collector name
            
.INPUTS
        - Cloudneeti Office 365 Data Collector Artifacts Storage Name <Contact Cloudneeti team>
        - Cloudneeti Office 365 Data Collector Artifacts Storage Access Key <Contact Cloudneeti team>
        - Cloudneeti Office 365 Data Collector Version <Contact Cloudneeti team>
        - Office 365 data collector name
        - Azure Subscription Id where office 365 data collector resouces will be created <Azure Subscription Id where office 365 data collector resouces is present>

.OUTPUTS
    Output (if any)
.NOTES
    Pre-Requisites:
    - Only run using Azure Cloudshell
    - M365 data collector already provisioned 
#>

[CmdletBinding()]
param
(
    # Cloudneeti Artifacts Storage Name
    [Parameter(Mandatory = $False,
        HelpMessage = "Cloudneeti office 365 Data Collector Artifact Name",
        Position = 7
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $ArtifactsName = $(Read-Host -prompt "Enter Cloudneeti office 365 Data Collector Artifacts Storage Name"),

    # Cloudneeti artifacts access key
    [Parameter(Mandatory = $False,
        HelpMessage = "Cloudneeti office 365 Data Collector Artifacts Acccess Key",
        Position = 8
    )]
    [ValidateNotNullOrEmpty()]
    [secureString]
    $ArtifactsAccessKey = $(Read-Host -prompt "Enter Cloudneeti office 365 Data Collector Artifacts Storage Access Key" -AsSecureString),

    # Data Collector version
    [Parameter(Mandatory = $False,
        HelpMessage = "Cloudneeti office 365 Data Collector Artifacts Version",
        Position = 9
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataCollectorVersion = $(Read-Host -prompt "Enter Cloudneeti Office 365 Data Collector Version"),

    # Subscription Id for automation account creation
    [Parameter(Mandatory = $False,
        HelpMessage = "Azure Subscription Id for office 365 data collector resources provisioned",
        Position = 14
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $AzureSubscriptionId = $(Read-Host -prompt "Enter Azure Subscription Id where office 365 data collector is present"),

    # Resource group name for Cloudneeti Resouces
    [Parameter(Mandatory = $False,
        HelpMessage = "Office 365 Data Collector Name"
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataCollectorName = $(Read-Host -prompt "Enter office 365 data collector name")
)
# Session configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

# Resource names declaration
$AutomationAccountName = $DataCollectorName
$ResourceGroupName = "$DataCollectorName-rg"
$ScriptPrefix = "M365DataCollector"
$ContianerName = "m365-datacollection-script"
$RunbookScriptName = "$ScriptPrefix-$DataCollectorVersion.ps1"
$RunbookName = "$ScriptPrefix-$DataCollectorVersion"
$path = "./runbooks"

$RequiredModules = @"
{
    Modules: [
        {
            "Product": "AzureRM.Profile",
            "Name": "AzureRM.Profile",
            "ContentUrl" : "https://www.powershellgallery.com/api/v2/package/AzureRM.profile/5.8.3",
            "Version" : "5.8.3"
        }
    ]
}
"@

# Checking current azure rm context to deploy Azure automation
$AzureContextSubscriptionId = (Get-AzContext).Subscription.Id

If ($AzureContextSubscriptionId -ne $AzureSubscriptionId){
    Write-Host "You are not logged in to subscription" $AzureSubscriptionId 
    Try{
        Write-Host "Trying to switch powershell context to subscription" $AzureSubscriptionId
        $AllAvailableSubscriptions = (Get-AzSubscription).Id
        if ($AllAvailableSubscriptions -contains $SubscriptionId)
        {
            Set-AzContext -SubscriptionId $AzureSubscriptionId
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

# Get existing runbook name and version
$ExistingRunbook = (Get-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName).name

If ($ExistingRunbook -ne $RunbookName){
    Write-host "Fetching scanning script to create Azure automation runbook" -ForegroundColor Yellow
 
    # Download cis m365 scan script to push in to Azure automation runbook
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ArtifactsAccessKey)            
    $ArtifactsKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) 
    $CNConnectionString  = "BlobEndpoint=https://$ArtifactsName.blob.core.windows.net/;SharedAccessSignature=$ArtifactsKey"
    $PackageContext = New-AzureStorageContext -ConnectionString $CNConnectionString

    New-Item -ItemType Directory -Force -Path $path | Out-Null  
    Get-AzStorageBlobContent -Container $ContianerName -Blob $RunbookScriptName -Destination "./runbooks/" -Context $PackageContext -Force

    Write-Host "Office 365 scanning script successfully fetched and ready to push in automation runbook" -ForegroundColor Green

    Write-Host "Creating Cloudneeti automation runbook with version" $DataCollectorVersion

    Import-AzAutomationRunbook -Name $RunbookName -Path .\runbooks\$RunbookScriptName -Tags $Tags -ResourceGroup $ResourceGroupName -AutomationAccountName $AutomationAccountName -Type PowerShell -Published -Force
    Write-Host "$RunbookName Runbook successfully created"

    # Remove older version of runbook
    if($ExistingRunbook -ne $NULL){
        Write-host "Deprecating older version of runbook:" $ExistingRunbook
        Remove-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -Name $ExistingRunbook -ResourceGroupName $ResourceGroupName -Force
        Write-Host "Successfully deprecated older version of runbook"
    }
    
    # import PSH module in automation account
    Write-Host "Importing required module to Azure Automation account"
    $RequiredModulesObj = ConvertFrom-Json $RequiredModules

    $requiredModulesObj.Modules | ForEach-Object {
        Write-Host "Importing" $_.Name "PowerShell module" -ForegroundColor Yellow
        New-AzAutomationModule -AutomationAccountName $AutomationAccountName -Name $_.Name -ContentLink $_.ContentUrl -ResourceGroupName $ResourceGroupName
        Write-Host $_.Name "module imported successfully" -ForegroundColor Green
    }
} 
else {
    Write-Host "Runbook already updated to version" $DataCollectorVersion -ForegroundColor DarkMagenta
}

Write-host "Script execution completed" -ForegroundColor Cyan