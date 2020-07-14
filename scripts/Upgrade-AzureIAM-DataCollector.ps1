<#
.SYNOPSIS
    Script to upgrade Cloudneeti IAM data collector automation account
.DESCRIPTION
    This script will upgrade runbook from IAM data collector(Automation Account) and deprecate older version on runbook.
.EXAMPLE
    Commands to run this script.
     Upload script to Azure CloudShell and execute below command:-
    .\Upgrade-AzureIAM-DataCollector.ps1.ps1

     Then script execution will prompt for below inputs and secrets:
            - Enter Cloudneeti Azure IAM Data Collector Artifacts Storage Name
            - Enter Cloudneeti Azure IAM Data Collector Artifacts Storage Access Key
            - Enter Cloudneeti Azure IAM Data Collector Version
            - Enter Azure Subscription Id where Azure IAM data collector resource is present
            - Enter Azure IAM data collector name
            
.INPUTS
        - Cloudneeti Azure IAM Collector Artifacts Storage Name <Contact Cloudneeti team>
        - Cloudneeti Azure IAM Collector Artifacts Storage Access Key <Contact Cloudneeti team>
        - Cloudneeti Azure IAM Data Collector Version <Contact Cloudneeti team>
        - Cloudneeti Azure IAM data collector name
        - Azure Subscription Id where Azure IAM data collector resouces will be created <Azure Subscription Id where Azure IAM data collector resouces is present>

.OUTPUTS
    Output (if any)

.NOTES

    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Pre-Requisites:
    - Only run using Azure Cloudshell
    - Azure IAM data collector already provisioned 
#>

[CmdletBinding()]
param
(
    # Cloudneeti Artifacts Storage Name
    [Parameter(Mandatory = $True,
        HelpMessage = "Cloudneeti Azure IAM Data Collector Artifact Name",
        Position = 1
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $ArtifactsName = $(Read-Host -prompt "Enter Cloudneeti Azure IAM Data Collector Artifacts Storage Name"),

    # Cloudneeti artifacts access key
    [Parameter(Mandatory = $True,
        HelpMessage = "Cloudneeti Azure IAM Data Collector Artifacts Acccess Key",
        Position = 2
    )]
    [ValidateNotNullOrEmpty()]
    [secureString]
    $ArtifactsAccessKey = $(Read-Host -prompt "Enter Cloudneeti Azure IAM Data Collector Artifacts Storage Access Key" -AsSecureString),

    # Data Collector version
    [Parameter(Mandatory = $True,
        HelpMessage = "Cloudneeti Azure IAM Data Collector Artifacts Version",
        Position = 3
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataCollectorVersion = $(Read-Host -prompt "Enter Cloudneeti Azure IAM Data Collector Version"),

    # Subscription Id for automation account creation
    [Parameter(Mandatory = $True,
        HelpMessage = "Azure Subscription Id for Azure IAM data collector resources provisioned",
        Position = 4
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $AzureSubscriptionId = $(Read-Host -prompt "Enter Azure Subscription Id where Azure IAM data collector is present"),

    # Resource group name for Cloudneeti Resouces
    [Parameter(Mandatory = $True,
        HelpMessage = "Azure IAM Data Collector Name",
        Position = 5
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataCollectorName = $(Read-Host -prompt "Enter Azure IAM data collector name")
)
# Session configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

# Resource names declaration
$AutomationAccountName = $DataCollectorName
$ResourceGroupName = "$DataCollectorName-rg"
$ScriptPrefix = "IAMDataCollector"
$ContianerName = "iam-datacollection-script"
$RunbookScriptName = "$ScriptPrefix-$DataCollectorVersion.ps1"
$RunbookName = "$ScriptPrefix-$DataCollectorVersion"
$path = "./runbooks"
$scheduleName = "$ScriptPrefix-DailySchedule" 
$VariableObject = @{
    "DataCollectorVersion"  = $DataCollectorVersion
}

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
 
    # Download Azure IAM scan script to push in to Azure automation runbook
    $ArtifactsKey = (New-Object PSCredential "user",$ArtifactsAccessKey).GetNetworkCredential().Password
    $CNConnectionString  = "BlobEndpoint=https://$ArtifactsName.blob.core.windows.net/;SharedAccessSignature=$ArtifactsKey"
    $PackageContext = New-AzureStorageContext -ConnectionString $CNConnectionString

    New-Item -ItemType Directory -Force -Path $path | Out-Null  
    Get-AzStorageBlobContent -Container $ContianerName -Blob $RunbookScriptName -Destination "./runbooks/" -Context $PackageContext -Force

    Write-Host "Azure IAM scanning script successfully fetched and ready to push in automation runbook" -ForegroundColor Green

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

    # Update the automation account variable
    foreach ($Variable in $VariableObject.GetEnumerator()) {
        $ExistingVariable = Get-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $Variable.Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
        If ($ExistingVariable -ne $null -and $ExistingVariable.Value -eq $Variable.Value) {
            Write-Host $Variable.Name "variable already exists" -ForegroundColor Yellow
        }
        else {
            if ($ExistingVariable -ne $null) {
                Write-Host "Updating Variable" $Variable.Name -ForegroundColor Yellow
                Set-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $Variable.Name -Encrypted $False -Value $Variable.Value -ResourceGroupName $ResourceGroupName
                Write-Host $Variable.Name "variable successfully updated" -ForegroundColor Green
            }
            else {
                Write-Host "Creating variable " $Variable.Name -ForegroundColor Yellow
                New-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $Variable.Name -Encrypted $False -Value $Variable.Value -ResourceGroupName $ResourceGroupName
                Write-Host $Variable.Name "variable successfully created" -ForegroundColor Green  
            }
        }
    }

    # Link schedule to the automation account	
    try {
        Write-Host "Linking automation account schedule $scheduleName to runbook $RunbookName"
        Register-AzAutomationScheduledRunbook –AutomationAccountName $AutomationAccountName –Name $RunbookName -ScheduleName $scheduleName -ResourceGroupName $ResourceGroupName 
        Write-Host "Successfully linked the automation account schedule $scheduleName to runbook $RunbookName"
    }
    catch [Exception] {
        Write-Host "Error occurred while linking automation schedule $scheduleName to runbook $RunbookName"
        Write-Output $_
    }
} 
else {
    Write-Host "Runbook already updated to version" $DataCollectorVersion -ForegroundColor DarkMagenta
}

Write-host "Script execution completed" -ForegroundColor Cyan