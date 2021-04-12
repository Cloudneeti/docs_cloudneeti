<#
.SYNOPSIS
    Script to upgrade ZCSPM IAM data collector's automation account
.DESCRIPTION
    This script will upgrade runbook from IAM data collector(Automation Account) and deprecate older version on runbook.
.EXAMPLE
    Commands to run this script.
     Upload script to Azure CloudShell and execute below command:-
    .\Upgrade-AzureIAM-DataCollector.ps1

     Then script execution will prompt for below inputs and secrets:
            - Enter ZCSPM Azure IAM Data Collector Artifacts Storage Name
            - Enter ZCSPM Azure IAM Data Collector Artifacts Storage Access Key
            - Enter ZCSPM Azure IAM Data Collector Version
            - Enter Azure Subscription Id where Azure IAM data collector resource is present
            - Enter Azure IAM data collector name
            
.INPUTS
        - ZCSPM Azure IAM Collector Artifacts Storage Name <Contact ZCSPM team>
        - ZCSPM Azure IAM Collector Artifacts Storage Access Key <Contact ZCSPM team>
        - ZCSPM Azure IAM Data Collector Version <Contact ZCSPM team>
        - ZCSPM Azure IAM data collector name
        - Azure Subscription Id where Azure IAM data collector resouces will be created <Azure Subscription Id where Azure IAM data collector resouces is present>

.OUTPUTS
    Output (if any)

.NOTES

    Copyright (c) Zscaler CSPM. All rights reserved.
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
    # ZCSPM Artifacts Storage Name
    [Parameter(Mandatory = $True,
        HelpMessage = "ZCSPM Azure IAM Data Collector Artifact Name",
        Position = 1
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $ArtifactsName = $(Read-Host -prompt "Enter ZCSPM Azure IAM Data Collector Artifacts Storage Name"),

    # ZCSPM artifacts access key
    [Parameter(Mandatory = $True,
        HelpMessage = "ZCSPM Azure IAM Data Collector Artifacts Acccess Key",
        Position = 2
    )]
    [ValidateNotNullOrEmpty()]
    [secureString]
    $ArtifactsAccessKey = $(Read-Host -prompt "Enter ZCSPM Azure IAM Data Collector Artifacts Storage Access Key" -AsSecureString),

    # Data Collector version
    [Parameter(Mandatory = $True,
        HelpMessage = "ZCSPM Azure IAM Data Collector Artifacts Version",
        Position = 3
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataCollectorVersion = $(Read-Host -prompt "Enter ZCSPM Azure IAM Data Collector Version"),

    # Subscription Id for automation account creation
    [Parameter(Mandatory = $True,
        HelpMessage = "Azure Subscription Id for Azure IAM data collector resources provisioned",
        Position = 4
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $AzureSubscriptionId = $(Read-Host -prompt "Enter Azure Subscription Id where Azure IAM data collector is present"),

    # Data collector automation account name
    [Parameter(Mandatory = $True,
        HelpMessage = "Azure IAM Data Collector Name",
        Position = 5
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataCollectorName = $(Read-Host -prompt "Enter Azure IAM data collector name"),

    # ZCSPM API key
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM API Key",
        Position = 6
    )]
    [ValidateNotNullOrEmpty()]
    [secureString]
    $ZCSPMAPIKey = $(Read-Host -prompt "Enter ZCSPM API Key" -AsSecureString),

    # ZCSPM Service principal id
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM Data collector application Id",
        Position = 7
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $ZCSPMApplicationId = $(Read-Host -prompt "Enter ZCSPM Data Collector application Id"),

    # Enter service principal secret
    [Parameter(Mandatory = $False,
        HelpMessage = "ZCSPM Data collector application secret",
        Position = 8
    )]
    [ValidateNotNullOrEmpty()]
    [SecureString]
    $ZCSPMApplicationSecret = $(Read-Host -prompt "Enter ZCSPM Data Collector Application Secret" -AsSecureString)
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
$ZCSPMCredentials = "ZCSPMCredentials"
$CloudneetiCredentials = "CloudneetiCredentials"
$VariableObject = @{
    "DataCollectorVersion"  = $DataCollectorVersion
}

$VariableObjectCSPM = @{
    "CloudneetiAccountId"   = "ZCSPMAccountId";
    "CloudneetiLicenseId"   = "ZCSPMLicenseId";
    "CloudneetiAPIURL"      = "ZCSPMAPIURL";
    "CloudneetiAPIKey"      = "ZCSPMAPIKey";
    "CloudneetiEnvironment" = "ZCSPMEnvironment"
}

$RequiredModules = @"
{
    Modules: [
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

    Write-Host "Creating ZCSPM automation runbook with version" $DataCollectorVersion

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

    # Update automation account credentials
    try{
        $credentials = Get-AzAutomationCredential -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName
        Write-host "Updating automation account credentials ..." -ForegroundColor Yellow
        Write-host "Updating secure credentials object for client service principal in Automation account" -ForegroundColor Yellow
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ZCSPMApplicationId, $ZCSPMApplicationSecret
        New-AzAutomationCredential -AutomationAccountName $AutomationAccountName -Name $ZCSPMCredentials -Value $Credential -ResourceGroupName $ResourceGroupName
        foreach($cred in $credentials){
            if($CloudneetiCredentials -eq $cred.Name){
                Remove-AzAutomationCredential -AutomationAccountName $AutomationAccountName -Name $CloudneetiCredentials -ResourceGroupName $ResourceGroupName
            }            
        }
        Write-host "Updated automation account credentials." -ForegroundColor Green
    }
    catch [Exception]{
        Write-Host "Error occurred while updating the automation account credentials"
        Write-Output $_
    }
    
    # Update automation account variables
    try{
        # Update automation account variables(Related to CSPM banding)
        Write-host "Updating automation account variables ..." -ForegroundColor Yellow
        foreach($VariableCSPM in $VariableObjectCSPM.GetEnumerator()) {
            $ExistingVariable = Get-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $($VariableCSPM.Name) -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
            [string]$Value1 = $ExistingVariable.Value
            if($ExistingVariable -ne $null -and $ExistingVariable.Name -ne 'CloudneetiAPIKey'){
                if($ExistingVariable.Value -ne $null -or $ExistingVariable.Name -eq 'CloudneetiAccountId')
                {
                    Write-Host "Removing Variable" $($VariableCSPM.Name) -ForegroundColor Yellow
                    Remove-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $($ExistingVariable.Name) -ResourceGroupName $ResourceGroupName
                    Write-Host $($VariableCSPM.Name) "variable successfully removed" -ForegroundColor Green
                }else{
                    Write-Host "Updating Variable" $($VariableCSPM.Name) -ForegroundColor Yellow
                    New-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $VariableCSPM.Value -Encrypted $False -Value $Value1 -ResourceGroupName $ResourceGroupName
                    Remove-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $($VariableCSPM.Name) -ResourceGroupName $ResourceGroupName
                    Write-Host $($VariableCSPM.Name) "variable successfully updated" -ForegroundColor Green
                }     
            }
            elseif($ExistingVariable.Name -eq 'CloudneetiAPIKey') {
                Write-Host "Updating Variable" $($VariableCSPM.Name) -ForegroundColor Yellow
                $ZCSPMAPIKeyEncrypt = (New-Object PSCredential "user",$ZCSPMAPIKey).GetNetworkCredential().Password
                New-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $($VariableCSPM.Value) -Encrypted $True -Value $ZCSPMAPIKeyEncrypt -ResourceGroupName $ResourceGroupName
                Remove-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $($VariableCSPM.Name) -ResourceGroupName $ResourceGroupName
                Write-Host $($VariableCSPM.Name) "variable successfully updated" -ForegroundColor Green
            }
        }
        foreach($VariableCSPM in $VariableObjectCSPM.GetEnumerator()) {
            $ExistingVariable = Get-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $($VariableCSPM.Value) -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
            [string]$Value1 = $ExistingVariable.Value
            if($ExistingVariable -ne $null -and $ExistingVariable.Name -ne 'ZCSPMAccountId'){
                Write-Host "Removing Variable" $ExistingVariable.Name -ForegroundColor Yellow
                Remove-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name $($ExistingVariable.Name) -ResourceGroupName $ResourceGroupName
                Write-Host $ExistingVariable.Name "variable successfully removed" -ForegroundColor Green     
            }
        }
        # Update the automation account variable(Not related to CSPM banding)
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
        Write-host "Updated all variables of automation account." -ForegroundColor Green
    }
    catch [Exception]{
        Write-Host "Error occurred while updating the automation account variables"
        Write-Output $_
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