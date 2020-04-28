<#
.SYNOPSIS
  Get raw summary data for a security benchmark.

.DESCRIPTION
  This script is used to get raw summary data of a security benchmark scanned by cloudneeti. The data is returned in json format.
  After successful execution of the script, a json file will created at the same location. 

.NOTES

    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Version:        1.0
    Author:         Cloudneeti

    # PREREQUISITE
    * Windows PowerShell version 5 and above
        1. To check PowerShell version type "$PSVersionTable.PSVersion" in PowerShell and you will find PowerShell version,
        2. To Install powershell follow link https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-6
    * Cloudneeti License ID and Account ID.
    * Subscription Key to Cloudneeti API

.EXAMPLE
    .\Get-BenchmarkSummary.ps1 -CloudneetiLicenseId <CloudneetiLicenseId> -CloudneetiAccountId <CloudneetiAccountId> -CloudneetiEnvironment <prod, trial> -BenchmarkId <BenchmarkId>

.INPUTS
    -CloudneetiLicenseId
    -CloudneetiAccountId
    -CloudneetiEnvironment
    -BenchmarkId
    -ResponseOption (Optional)

.OUTPUTS
    Cloudneeti summary raw data as json.
#>

[CmdletBinding()]
param
(
    # Cloudneeti LicenseId
    [Parameter(Mandatory = $true,
        HelpMessage = "Cloudneeti LicenseId",
        Position = 1
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $CloudneetiLicenseId = $(Read-Host -prompt "Enter Cloudneeti License Id"),

    # Cloudneeti AccountId
    [Parameter(Mandatory = $true,
        HelpMessage = "Cloudneeti AccountId",
        Position = 2
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $CloudneetiAccountId = $(Read-Host -prompt "Enter Cloudneeti Account Id"),
    
    # Benchmark Id
    [Parameter(Mandatory = $true,
        HelpMessage = "Benchmark Id",
        Position = 3
    )]
    [ValidateNotNullOrEmpty()]
    [string]
    $BenchmarkId = $(Read-Host -prompt "Enter Benchmark Id"),

    # Enter environment information.
    [Parameter(Mandatory = $true,
        HelpMessage = "Environment",
        Position = 4
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("prod", "trial")]
    [string]
    $CloudneetiEnvironment = "prod",

    # Cloudneeti Api Key.
    [Parameter(Mandatory = $true,
        HelpMessage = "Api Key",
        Position = 5
    )]
    [ValidateNotNullOrEmpty()]
    [securestring]
    $CloudneetiApiKey = $(Read-Host -prompt "Enter Cloudneeti Api Key" -AsSecureString),

    # Response Option.
    [Parameter(Mandatory = $false,
        HelpMessage = "Response Option",
        Position = 6
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("PostureWithPolicyData", "PostureOnly", "PolicyDataOnly")]
    [string]
    $ResponseOption = "PostureWithPolicyData"
)

####################### Function & Variable declaration ######################

$EnvironmentData = @{
    trial = @{
        "url"      = "https://trial.cloudneeti.com"
        "clientid" = "177b1999-df5f-4615-a04d-84a23971c1e3"
        "apiurl"   = "https://trialapi.cloudneeti.com"
    }
    prod  = @{
        "url"      = "https://app.cloudneeti.com"
        "clientid" = "e6e7c8e2-80d6-4053-863b-104e70052988"
        "apiurl"   = "https://api.cloudneeti.com"
    }
}

function Get-TokenWithBrowserLogin {
    param
    (
        [Parameter(HelpMessage = 'Redirect URI')]
        [ValidateNotNull()]
        [uri]$redirectUri,

        [Parameter(HelpMessage = 'Client Id')]
        [ValidateNotNull()]
        [uri]$clientId
    )

    $authorizationUrl = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?response_type=id_token&scope=user.read%20openid%20profile&client_id=$clientId&redirect_uri=$redirectUri&state=$((New-Guid).ToString())&nonce=$((New-Guid).ToString())&client_info=1&x-client-SKU=MSAL.JS&x-client-Ver=1.1.3&client-request-id=$((New-Guid).ToString())&response_mode=fragment"
    $logoutUrl = "https://login.microsoftonline.com/common/oauth2/v2.0/logout?post_logout_redirect_uri=$redirectUri"

    # Create an browser dialog box for the login.
    $ie = New-Object -ComObject InternetExplorer.Application
    $ie.Width = 600
    $ie.Height = 500
    $ie.AddressBar = $false
    $ie.ToolBar = $false
    $ie.StatusBar = $false
    $ie.visible = $true
    $ie.navigate($authorizationUrl)

    while ($ie.Busy) { } 

    :loop while ($true) {   
        # Retrieve URL in login dialog box
        $urls = (New-Object -ComObject Shell.Application).Windows() | Where-Object { ($_.LocationUrl -match "(^https?://.+)|(^ftp://)") -and ($_.HWND -eq $ie.HWND) } | Where-Object { $_.LocationUrl }

        foreach ($a in $urls) {
            # Verifies the reply url which contains '?id_token=' and retrieve the id_token.
            if (($a.LocationUrl).Contains("#id_token=")) {
                $id_token = ($a.LocationUrl)
                $id_token = ($id_token -replace (".*id_token=") -replace ("&.*"))
                
                Write-Host "Authenticated successfully, you will be logged out automatically..." -ForegroundColor Green

                $ie.navigate($logoutUrl)
                while ($ie.Busy) { }
                :loop2 while ($true) {
                    $logoutUrls = (New-Object -ComObject Shell.Application).Windows() | Where-Object { (($_.LocationUrl -contains $redirectUri) -and ($_.HWND -eq $ie.HWND)) } | Where-Object { $_.LocationUrl }
                    foreach ($a in $logoutUrls) {
                        if (($a.LocationUrl).Contains($redirectUri)) {
                            Start-Sleep 1
                            break loop2
                        }
                    }
                }
                    $ie.Quit()
                    break loop
                }
                # If url reverts '?error=', catch it as an error.
                elseif (($a.LocationUrl).StartsWith($redirectUri.ToString() + "?error=")) {
                    $error = [System.Web.HttpUtility]::UrlDecode(($a.LocationUrl) -replace (".*error="))
                    $error | Write-Host
                    break loop
                }
            }
        }

        # Return the Auth id_token
        return $id_token
    }

    ######################################## Authorization & Validation ###########################################

    $environment = $EnvironmentData[$CloudneetiEnvironment]
    $PlainApiKey = (New-Object PSCredential "user", $CloudneetiApiKey).GetNetworkCredential().Password

    Write-Host "Use your office 365/Azure AD/Microsoft account to sign in using the pop up window..." -foregroundcolor yellow

    $msalToken = Get-TokenWithBrowserLogin -redirectUri $environment.url -clientId $environment.clientid

    Write-Host "Generating cloudneeti access Token..." -foregroundcolor yellow

    $Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $Headers.Add('Authorization', 'Bearer {0}' -f $msalToken)
    $Headers.Add('Site-Referer', "")
    $Headers.Add('Ocp-Apim-Subscription-Key', $PlainApiKey)

    $uri = "$($environment.apiurl)/api/token"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $method = Invoke-WebRequest -Method GET -Uri $uri -Headers $Headers -ContentType "application/json"
        $method = $method | ConvertFrom-Json
        $CNToken = $method.token
        if ($null -ne $CNToken) {
            Write-Host "Cloudneeti access token generated successfully." -foregroundcolor green 
        }
    }
    catch [Exception] {
        Write-Host $_
        Write-Host "Cloudneeti access token generation failed. You might not have access to cloudneeti." -foregroundcolor red
        exit
    }

    if (!($method.userStateModels.AccountId -contains $CloudneetiAccountId)) {
        Write-Host "Logged in user does not have access to the account with id : $CloudneetiAccountId" -ForegroundColor Red
        exit
    }
    else {
        $parantLicenseId = ($method.userStateModels | where-object { $_.AccountId -eq $CloudneetiAccountId }).LicenseId
        if ($parantLicenseId -ne $CloudneetiLicenseId) {
            Write-Host "The account id provided does not belong to License id : $CloudneetiLicenseId" -ForegroundColor Red
            Write-Warning "Please make sure license id and account id are correct"
            exit
        }
    }

    ################################ BenchmarkSummary #########################

    $ConnectorType = ($method.userStateModels | where-object { $_.AccountId -eq $CloudneetiAccountId }).ConnectorType
    $AccountName = ($method.userStateModels | where-object { $_.AccountId -eq $CloudneetiAccountId }).AccountName

    $Date = Get-Date -Format "dd-MMM-yyyy"
    $outputFilePath = "$PSScriptRoot\BenchmarkSummary-$BenchmarkId-$AccountName-$Date.json"

    $benchmarkSummaryUrl = "$($environment.apiurl)/api/license/$($CloudneetiLicenseId)/account/$($CloudneetiAccountId)/benchmark/$($BenchmarkId)/summary?connector=$($ConnectorType)"

    $Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $Headers.Add('Authorization', 'Bearer {0}' -f $CNToken)
    $Headers.Add('Ocp-Apim-Subscription-Key', $PlainApiKey)

    $benchmarkSummaryData = Invoke-WebRequest -Method GET -Uri $benchmarkSummaryUrl -Headers $Headers -ContentType "application/json"

    if ("null" -eq $benchmarkSummaryData.Content) {
        Write-Host "Error : No data found. Please check if the Benchmark id ($BenchmarkId) is appropriate for the Account type ($ConnectorType)" -ForegroundColor Red
        exit
    }

    $objectData = $benchmarkSummaryData | ConvertFrom-Json

    switch ($ResponseOption) {
        "PolicyDataOnly" { 
            $dataOutput = [PSCustomObject]@{
                PolicyData = $objectData.ResourceCategories
            }
        }
        "PostureOnly" {
            $dataOutput = [PSCustomObject]@{
                Posture = $objectData.Posture
            }
        }
        "PostureWithPolicyData" {
            $dataOutput = $objectData
        }
        Default { }
    }

    $dataOutput | ConvertTo-Json -Depth 20 | Out-File $outputFilePath -Force

    Write-Host "`n`nRaw data saved to file $outputFilePath" -ForegroundColor Green
