<#
.SYNOPSIS
    Script to upgrade Cloudneeti data collector automation account
.DESCRIPTION
    
.EXAMPLE
    Commands to run this script.
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    Pre-Requisites:
    - Only run using Azure Cloudshell
    - Only NON-MFA user can run this script
#>

[CmdletBinding()]
param
(

    # Cloudneeti Artifacts Storage Name
    [Parameter(Mandatory = $False,
        HelpMessage="Cloudneeti office 365 Data Collector Artifact Name",
		Position=7
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $ArtifactsName = $(Read-Host -prompt "Enter Cloudneeti office 365 Data Collector Artifacts Storage Name"),

    # Cloudneeti artifacts access key
    [Parameter(Mandatory = $False,
        HelpMessage="Cloudneeti office 365 Data Collector Artifacts Acccess Key",
        Position=8
    )]
    [ValidateNotNullOrEmpty()]
    [secureString]
    $ArtifactsAccessKey = $(Read-Host -prompt "Enter Cloudneeti office 365 Data Collector Artifacts Storage Access Key" -AsSecureString),

    # Data Collector version
    [Parameter(Mandatory = $False,
        HelpMessage="Cloudneeti office 365 Data Collector Artifacts Version",
		Position=9
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataCollectorVersion = $(Read-Host -prompt "Enter Cloudneeti Office 365 Data Collector Version"),

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
    $DataCollectorName  = $(Read-Host -prompt "Enter office 365 data collector name"),

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
$AutomationAccountName = $DataCollectorName
$ResourceGroupName = "$DataCollectorName-rg"
$ScriptPrefix = "M365DataCollector"
$ContianerName = "m365-datacollection-script"
$RunbookScriptName = "$ScriptPrefix-$DataCollectorVersion.ps1"
$RunbookName = "$ScriptPrefix-$DataCollectorVersion"
$path = "./runbooks"
$Tags = @{"Service"="Cloudneeti-Office365-Data-Collection"}

$RequiredModules = @"
{
    Modules: [
        {
            "Product": "SharePoint",
            "Name": "Microsoft.Online.SharePoint.PowerShell",
            "ContentUrl" : "https://www.powershellgallery.com/api/v2/package/Microsoft.Online.SharePoint.PowerShell/16.0.8414.1200",
            "Version" : "16.0.8414.1200"
        }
    ]
}
"@

# Checking current azure rm context to deploy Azure automation
$AzureContextSubscriptionId = (Get-AzureRmContext).Subscription.Id

If ($AzureContextSubscriptionId -ne $AzureSubscriptionId){
    Write-Host "You are not logged in to subscription" $AzureSubscriptionId 
    Try{
        Write-Host "Trying to switch powershell context to subscription" $AzureSubscriptionId
        $AllAvailableSubscriptions = (Get-AzureRmSubscription).Id
        if ($AllAvailableSubscriptions -contains $SubscriptionId)
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

# Get existing runbook name and version
$ExistingRunbook = (Get-AzureRmAutomationRunbook -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName).name

If ($ExistingRunbook -ne $RunbookName){
    Write-host "Fetching scanning script to create Azure automation runbook" -ForegroundColor Yellow
 
    # Download cis m365 scan script to push in to Azure automation runbook
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ArtifactsAccessKey)            
    $ArtifactsKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) 
    $CNConnectionString  = "BlobEndpoint=https://$ArtifactsName.blob.core.windows.net/;SharedAccessSignature=$ArtifactsKey"
    $PackageContext = New-AzureStorageContext -ConnectionString $CNConnectionString

    New-Item -ItemType Directory -Force -Path $path | Out-Null  
    Get-AzureStorageBlobContent -Container $ContianerName -Blob $RunbookScriptName -Destination "./runbooks/" -Context $PackageContext -Force

    Write-Host "Office 365 scanning script successfully fetched and ready to push in automation runbook" -ForegroundColor Green

    Write-Host "Creating Cloudneeti automation runbook with version" $DataCollectorVersion

    Import-AzureRmAutomationRunbook -Name $RunbookName -Path .\runbooks\$RunbookScriptName -Tags $Tags -ResourceGroup $ResourceGroupName -AutomationAccountName $AutomationAccountName -Type PowerShell -Published -Force
    Write-Host "$RunbookName Runbook successfully created"

    # Remove older version of runbook
    if($ExistingRunbook -ne $NULL){
    Write-host "Deprecating older version of runbook:" $ExistingRunbook
    Remove-AzureRmAutomationRunbook -AutomationAccountName $AutomationAccountName -Name $ExistingRunbook -ResourceGroupName $ResourceGroupName -Force
    Write-Host "Successfully deprecated older version of runbook"
    }
    
    # import PSH module in automation account
    Write-Host "Importing required module to Azure Automation account"
    $RequiredModulesObj = ConvertFrom-Json $RequiredModules

    $requiredModulesObj.Modules | ForEach-Object {
    Write-Host "Importing" $_.Name "PowerShell module" -ForegroundColor Yellow
    New-AzureRmAutomationModule -AutomationAccountName $AutomationAccountName -Name $_.Name -ContentLink $_.ContentUrl -ResourceGroupName $ResourceGroupName
    Write-Host $_.Name "module imported successfully" -ForegroundColor Green

        # Create schedule
        try {
        Write-Host "Getting existing schedule from Automation account"
        $scheduleName = "$ScriptPrefix-DailySchedule" 
        $StartTime = (Get-Date).AddMinutes(8)
        $ExistingSchedule = Get-AzureRmAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ScheduleName $scheduleName -ErrorAction SilentlyContinue

        if($ExistingSchedule -eq $NULL){
            Write-Host "Creating automation account schedule"
            New-AzureRmAutomationSchedule -ResourceGroupName $ResourceGroupName –AutomationAccountName $AutomationAccountName –Name $scheduleName –StartTime $StartTime –DayInterval 1
            Write-Host "Successfully created the automation account schedule" $scheduleName
        }

        # Link schedule to automation account	
        Write-Host "Linking automation account schedule $scheduleName to runbook $RunbookName"
        Register-AzureRmAutomationScheduledRunbook -ResourceGroupName $ResourceGroupName –AutomationAccountName $AutomationAccountName –RunbookName $RunbookName -ScheduleName $scheduleName
        Write-Host "Successfully linked the automation account schedule $scheduleName to runbook $RunbookName"
        }
        catch [Exception] {
            Write-Host "Error occurred while creating automation schedule"
            Write-Output $_
        }   

    }
} 
else {
    Write-Host "Runbook already updated to version" $DataCollectorVersion -ForegroundColor DarkMagenta
}


Write-host "Script execution completed." -ForegroundColor Cyan