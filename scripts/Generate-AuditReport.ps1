<#
.SYNOPSIS
	Script to generate a consolidated audit report for multiple accounts

.DESCRIPTION
    This script is used to generate an audit report for multiple accounts of a security benchmark scanned by ZCSPM. The data is returned in CSV format. After successful execution of the script, a CSV file will created at the same location.

.NOTES
  Copyright (c) Zscaler CSPM. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    Version:        1.0
    Author:         Zscaler CSPM
    Creation Date:  01/10/2021
    Last Modified Date: 01/10/2021

    # PREREQUISITE
    * Windows PowerShell version 5 and above
        1. To check PowerShell version type "$PSVersionTable.PSVersion" in PowerShell and you will find PowerShell version,
        2. To Install powershell follow link https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-6
    * ZCSPM API Application with the following APIs to connect
        1. Account.Audit
        2. License.GetAPIAccess

.INPUTS
    Below is the list of inputs to the script:-
        - ZCSPM Environment <ZCSPM Environment>
        - ZCSPM License Id <Find in "Manage Licenses" of ZCSPM Settings>
        - ZCSPM Account Id List <Find in "Manage Accounts" of ZCSPM Settings>
        - ZCSPM Benchmark Id <ZCSPM Supported Benchmark>
        - ZCSPM Application Id
        - ZCSPM Application Secret
        - ZCSPM API Key <Find in "ZCSPM API Management Portal">

.OUTPUTS
    ZCSPM audit report in CSV format. Output file format: audit_report-year-month-date-hour-min-sec.csv (audit_report-2021-09-17-13-51-14.csv)

.EXAMPLE
	PS> .\Generate-AuditReport.ps1  `
        -ZCSPMEnvironment "prod" `
        -ZCSPMLicenseId "<ZCSPM License Id>" `
        -ZCSPMAccountIdList <ZCSPM Account Id>,<ZCSPM Account Id> `
        -ZCSPMApplicationId "<ZCSPM API application Id>" `
        -ZCSPMApplicationSecret (ConvertTo-SecureString "<ZCSPM API application secret>" -AsPlainText -Force) `
        -ZCSPMAPIKey (ConvertTo-SecureString "<ZCSPM API primary key>" -AsPlainText -Force)

.EXAMPLE
    By Default, the script will take all accounts unless specified by -ZCSPMAccountIdList parameter
	PS> .\Generate-AuditReport.ps1  `
        -ZCSPMEnvironment "trial" `
        -ZCSPMLicenseId "<ZCSPM License Id>" `
        -ZCSPMApplicationId "<ZCSPM API application Id>" `
        -ZCSPMApplicationSecret (ConvertTo-SecureString "<ZCSPM API application secret>" -AsPlainText -Force) `
        -ZCSPMAPIKey (ConvertTo-SecureString "<ZCSPM API primary key>" -AsPlainText -Force)

.EXAMPLE
    By Default, the script will take CSBP as Benchmark ID unless specified by -ZCSPMBenchmarkId parameter
	PS> .\Generate-AuditReport.ps1  `
        -ZCSPMEnvironment "trial" `
        -ZCSPMLicenseId "<ZCSPM License Id>" `
        -ZCSPMBenchmarkId "HIPAA" `
        -ZCSPMApplicationId "<ZCSPM API application Id>" `
        -ZCSPMApplicationSecret (ConvertTo-SecureString "<ZCSPM API application secret>" -AsPlainText -Force) `
        -ZCSPMAPIKey (ConvertTo-SecureString "<ZCSPM API primary key>" -AsPlainText -Force)

.PARAMETER ZCSPMEnvironment
        Specifies the ZCSPM API domain.
        Required = True
        Type = String

.PARAMETER ZCSPMLicenseId
        Specifies the ZCSPM License Id.
        Required = True
        Type = GUID

.PARAMETER ZCSPMAccountIdList
        Specifies the cloud account ID list. Enter 'All' for all accounts or comma-separated account Ids or single account Id.
        Required = False
        Default: All
        Type = GUID Array

.PARAMETER ZCSPMBenchmarkId
        Specifies the ZCSPM Benchmark Id. Default is "CSBP".
        Required = False
        Default : CSBP
        Type = String

.PARAMETER ZCSPMApplicationId
        Specifies the ZCSPM API application Id.
        Required = True
        Type = String

.PARAMETER ZCSPMApplicationSecret
        Specifies the ZCSPM API application secret.
        Required = True
        Type = Secure String

.PARAMETER ZCSPMAPIKey
        Specifies the ZCSPM API primary key.
        Required = True
        Type = Secure String

.LINK
	https://help.zscaler.com/zcspm/configure-zcspm-api-access
#>
[CmdletBinding()]
param
(
    # ZCSPM Environment
    [Parameter(Mandatory = $true, HelpMessage = "Enter ZCSPM Environment")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("dev", "qa", "trial", "prod", "prod1")]
    [string]
    $ZCSPMEnvironment,

    # ZCSPM contract Id
    [Parameter(Mandatory = $true, HelpMessage = "Enter ZCSPM License Id")]
    [ValidateNotNullOrEmpty()]
    [guid]
    $ZCSPMLicenseId,

    # ZCSPM account Id List
    [Parameter(Mandatory = $false, HelpMessage = "Enter comma-separated ZCSPM account IDs")]
    [ValidateNotNullOrEmpty()]
    [guid[]]
    $ZCSPMAccountIdList,

    # ZCSPM Benchmark Id
    [Parameter(Mandatory = $false, HelpMessage = "Enter ZCSPM Benchmark Id")]
    [ValidateNotNullOrEmpty()]
    [string]
    $ZCSPMBenchmarkId = "CSBP",

    # ZCSPM API application Id
    [Parameter(Mandatory = $true, HelpMessage = "Enter ZCSPM API application Id")]
    [ValidateNotNullOrEmpty()]
    [string]
    $ZCSPMApplicationId,

    # ZCSPM API application secret
    [Parameter(Mandatory = $true, HelpMessage = "Enter ZCSPM API application secret")]
    [ValidateNotNullOrEmpty()]
    [secureString]
    $ZCSPMApplicationSecret,

    # ZCSPM API Key
    [Parameter(Mandatory = $true, HelpMessage = "Enter ZCSPM API key")]
    [ValidateNotNullOrEmpty()]
    [secureString]
    $ZCSPMAPIKey
)

# ------------------------------------------------------------------------------------------------------------------------------ #
#                                                   Function: Get License Token                                                  #
# ------------------------------------------------------------------------------------------------------------------------------ #
function Get-LicenseToken {
    [cmdletbinding()]
    Param(
        [string]$ZCSPMApplicationId,
        [string]$Secret,
        [string]$ApiDomain,
        [string]$ZCSPMLicenseId,
        [string]$OcpApimSubscriptionKey
    )
    $Cred = @{
        "APIApplicationId" = "$ZCSPMApplicationId"
        "Secret"           = "$Secret"
    }
    $Payload = $Cred | ConvertTo-Json
    $params = @{
        Uri         = "https://$ApiDomain/authorize/license/$ZCSPMLicenseId/token"
        Headers     = @{ 'Ocp-Apim-Subscription-Key' = "$OcpApimSubscriptionKey" }
        Method      = 'POST'
        Body        = $Payload
        ContentType = 'application/json'
    }
    $response = Invoke-RestMethod @params
    $licToken = $response | Select-Object -Expand result | Select-Object token
    $token = [String]$licToken.token
    return $token
}

# ------------------------------------------------------------------------------------------------------------------------------ #
#                                                   Function: Get Account Token                                                  #
# ------------------------------------------------------------------------------------------------------------------------------ #

function Get-AccountToken {
    [cmdletbinding()]
    Param(
        [string]$ZCSPMApplicationId,
        [string]$Secret,
        [string]$ApiDomain,
        [string]$ZCSPMLicenseId,
        [string]$AccountId,
        [string]$OcpApimSubscriptionKey
    )
    $Cred = @{
        "APIApplicationId" = "$ZCSPMApplicationId"
        "Secret"           = "$Secret"
    }
    $Payload = $Cred | ConvertTo-Json
    $params = @{
        Uri         = "https://$ApiDomain/authorize/license/$ZCSPMLicenseId/token?accountId=$AccountId"
        Headers     = @{ 'Ocp-Apim-Subscription-Key' = "$OcpApimSubscriptionKey" }
        Method      = 'POST'
        Body        = $Payload
        ContentType = 'application/json'
    }
    $response = Invoke-RestMethod @params
    $accToken = $response | Select-Object -Expand result | Select-Object token
    $token = [String]$accToken.token
    return $token
}

# ------------------------------------------------------------------------------------------------------------------------------ #
#                                                 Function: Get All Accounts List                                                #
# ------------------------------------------------------------------------------------------------------------------------------ #
function Get-AccountList {
    [cmdletbinding()]
    Param(
        [string]$ApiDomain,
        [string]$ZCSPMLicenseId,
        [string]$BearerToken,
        [string]$OcpApimSubscriptionKey
    )
    $params = @{
        Uri     = "https://$ApiDomain/onboarding/license/$ZCSPMLicenseId/licenseAccounts"
        Headers = @{
            'Authorization'             = "Bearer $BearerToken"
            'Ocp-Apim-Subscription-Key' = "$OcpApimSubscriptionKey"
        }
        Method  = 'GET'
    }
    $response = Invoke-RestMethod @params
    $accountObj = $response | Select-Object -Expand result | Select-Object -Expand accounts | Select-Object accountId
    $apiObj = $response | Select-Object -Expand result | Select-Object -Expand apis
    if ($apiObj -notcontains "Account.Audit") {
        Write-Host "$(Get-Date -Format "yyyy-MM-dd-HH:mm:ss") ##[Error] Token is not valid for API permission. Update API application permission(Account.Audit) and regenerate token" -ForegroundColor RED
        Exit
    }
    $accountList = @()
    foreach ($account in $accountObj.accountId) {
        $accountList += $account
    }
    return $accountList
}

# ------------------------------------------------------------------------------------------------------------------------------ #
#                                                 Function: Get Audit Report JSON                                                #
# ------------------------------------------------------------------------------------------------------------------------------ #

function Get-AuditReport {
    [cmdletbinding()]
    Param(
        [string]$Uri,
        [string]$BearerToken,
        [string]$OcpApimSubscriptionKey
    )
    $params = @{
        Uri     = $Uri
        Headers = @{
            'Authorization'             = "Bearer $BearerToken"
            'Ocp-Apim-Subscription-Key' = $OcpApimSubscriptionKey
        }
        Method  = 'GET'
    }
    $audit_report = Invoke-RestMethod @params
    return $audit_report
}

# ------------------------------------------------------------------------------------------------------------------------------ #
#                                                      Function: Create CSV                                                      #
# ------------------------------------------------------------------------------------------------------------------------------ #

function Add-Csv {
    [cmdletbinding()]
    Param(
        [string]$Filename,
        $AuditReport
    )
    $row_count = 0
    ForEach ($result in $AuditReport.result) {
        ForEach ($resourceCategories in $result.resourceCategories) {
            ForEach ($policies in $resourceCategories.policies) {
                $audit_report_obj = [PSCustomObject]@{
                    "Cloud Account Id"      = $result.accountId
                    "Cloud Account Name"    = $result.accountName
                    "Connector Type"        = $result.connectorType
                    "Benchmark Name"        = $result.benchmarkId
                    "Category Name"         = $resourceCategories.categoryName
                    "Policy ID"             = $policies.policyId
                    "Policy Name"           = $policies.shortTitle
                    "Compliance Number"     = $policies.complianceNumber
                    "Total Resource Count"  = $policies.totalResourceCount
                    "Passed Resource Count" = $policies.passedResourceCount
                    "Failed Resource Count" = ($policies.totalResourceCount - $policies.passedResourceCount)
                    "Severity"              = $policies.severity
                    "Risk Likelihood"       = $policies.riskProbability
                    "Risk Level"            = $policies.riskLevel
                }
                $audit_report_obj | Export-Csv $Filename -NoTypeInformation -Append -Force
                $row_count += 1
            }
        }
    }
    return $row_count
}

# ------------------------------------------------------------------------------------------------------------------------------ #
#                                                         Set Parameters                                                         #
# ------------------------------------------------------------------------------------------------------------------------------ #

# ZCSPM API Domain
$ZCSPMApiDomain = @{
    dev   = "devapi.cloudneeti-devops.com";
    trial = "trialapi.cloudneeti.com";
    qa    = "qaapi.cloudneeti-devops.com";
    prod  = "api.cloudneeti.com";
    prod1 = "api1.cloudneeti.com"
}
$ApiDomain = $ZCSPMApiDomain[$ZCSPMEnvironment.ToLower()]

$Secret = (New-Object PSCredential "user", $ZCSPMApplicationSecret).GetNetworkCredential().Password
$OcpApimSubscriptionKey = (New-Object PSCredential "user", $ZCSPMAPIKey).GetNetworkCredential().Password

if ($null -eq $ZCSPMAccountIdList) {
    try {
        $licenseToken = Get-LicenseToken -ApiDomain $ApiDomain -ZCSPMLicenseId $ZCSPMLicenseId -ZCSPMApplicationId $ZCSPMApplicationId -Secret $Secret -OcpApimSubscriptionKey $OcpApimSubscriptionKey
        $accountList = Get-AccountList -ApiDomain $ApiDomain -ZCSPMLicenseId $ZCSPMLicenseId -BearerToken $licenseToken -OcpApimSubscriptionKey $OcpApimSubscriptionKey
    }
    catch {
        if ($null -ne $_.ErrorDetails.Message) {
            $error_message = $_.ErrorDetails.Message
        }
        else {
            $error_message = $_.Exception.Message
        }
        $line = $_.InvocationInfo.ScriptLineNumber
        Write-Host "$(Get-Date -Format "yyyy-MM-dd-HH:mm:ss") ##[Error] $error_message at line $line" -ForegroundColor Red
        Write-Host "$(Get-Date -Format "yyyy-MM-dd-HH:mm:ss") Unable to generate accounts list" -ForegroundColor Red
        Exit
    }
}
else {
    $accountList = $ZCSPMAccountIdList
}

# ------------------------------------------------------------------------------------------------------------------------------ #
#                                                  Consolidate All Accounts Data                                                 #
# ------------------------------------------------------------------------------------------------------------------------------ #

$accounts_count = 1
$total_accounts = $accountList.Count
Write-Host "Script execution started"
Write-Host "Total Accounts Found: $total_accounts" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------------------------------------------"
$accounts_failed = 0
$fileName = "audit_report-$(Get-Date -Format "yyyy-MM-dd-HH-mm-ss").csv"
$summaryAccountsList = @()

foreach ($accountId in $accountList) {
    $Uri = "https://$ApiDomain/audit/license/$ZCSPMLicenseId/account/$accountId/benchmark/$ZCSPMBenchmarkId/summary"
    $summaryAccountsStatus = "" | Select-Object "AccountId", "Status", "Details"
    try {
        Write-Host "$(Get-Date -Format "yyyy-MM-dd-HH:mm:ss") [$accounts_count/$total_accounts] Processing account: $accountId" -ForegroundColor Cyan

        Write-Host "$(Get-Date -Format "yyyy-MM-dd-HH:mm:ss") Generating account token..."
        $accountToken = Get-AccountToken -ApiDomain $ApiDomain -ZCSPMLicenseId $ZCSPMLicenseId -AccountId $accountId -ZCSPMApplicationId $ZCSPMApplicationId -Secret $Secret -OcpApimSubscriptionKey $OcpApimSubscriptionKey
        Write-Host "$(Get-Date -Format "yyyy-MM-dd-HH:mm:ss") Account token generated successfully"

        Write-Host "$(Get-Date -Format "yyyy-MM-dd-HH:mm:ss") Generating audit report..."
        $audit_report = Get-AuditReport -Uri $Uri -BearerToken $accountToken -OcpApimSubscriptionKey $OcpApimSubscriptionKey
        $row_count = Add-Csv -AuditReport $audit_report -Filename $fileName
        Write-Host "$(Get-Date -Format "yyyy-MM-dd-HH:mm:ss") Audit Report generated successfully"
        Write-Host "$(Get-Date -Format "yyyy-MM-dd-HH:mm:ss") Number of records added: $row_count"
        $summaryAccountsStatus.AccountId = $accountId
        $summaryAccountsStatus.Status = "Success"
        $summaryAccountsStatus.Details = "Number of records added: $row_count"
        $summaryAccountsList += $summaryAccountsStatus
        Write-Host "--------------------------------------------------------------------------------------------------------"
    }
    catch {
        if ($null -ne $_.ErrorDetails.Message) {
            $error_message = $_.ErrorDetails.Message
        }
        else {
            $error_message = $_.Exception.Message
        }
        $line = $_.InvocationInfo.ScriptLineNumber
        Write-Host "$(Get-Date -Format "yyyy-MM-dd-HH:mm:ss") ##[Error] $error_message at line $line" -ForegroundColor RED
        Write-Host "$(Get-Date -Format "yyyy-MM-dd-HH:mm:ss") Skipping audit report for account Id: $accountId" -ForegroundColor Yellow
        $accounts_failed += 1
        $summaryAccountsStatus.AccountId = $accountId
        $summaryAccountsStatus.Status = "Failed"
        if ($null -ne $_.ErrorDetails.Message) {
            $error_details = $_.ErrorDetails.Message | ConvertFrom-Json | Select-Object -Expand message
        }
        else {
            $error_details = $_.Exception.Message
        }
        $summaryAccountsStatus.Details = "$error_details"
        $summaryAccountsList += $summaryAccountsStatus
        Write-Host "--------------------------------------------------------------------------------------------------------"
    }
    $accounts_count += 1
}

# ------------------------------------------------------------------------------------------------------------------------------ #
#                                                      Audit Report Summary                                                      #
# ------------------------------------------------------------------------------------------------------------------------------ #

Write-Host "Audit Report Summary" -ForegroundColor Cyan
$summaryAccountsList | sort-object Status | Format-Table -AutoSize -Wrap
Write-Host "Total accounts processed: $total_accounts" -ForegroundColor Cyan
Write-Host "Accounts skipped: $accounts_failed" -ForegroundColor Cyan
Write-Host "Accounts passed: $($total_accounts-$accounts_failed)" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------------------------------------------"
if (-not(Test-Path -Path $fileName -PathType Leaf)) {
    Write-Host "$(Get-Date -Format "yyyy-MM-dd-HH:mm:ss") Failed to generate audit report" -ForegroundColor Red
}
else {
    $auditReportPath = Get-ChildItem -Path $fileName | select-object FullName
    Write-Host "Audit report generated successfully: $($auditReportPath.FullName)" -ForegroundColor Green
}
Write-Host "Script execution completed"
