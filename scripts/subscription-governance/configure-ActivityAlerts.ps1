<#
.SYNOPSIS
    This script configure Azure activity alerts on subscription.

.DESCRIPTION
    This script helps to configure activity alerts on the given Azure subscription.

.NOTES

    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Version:        1.0
    Author:         Cloudneeti
    Creation Date:  13/08/2019

    Pre-Requisites:
    - This script needs to run inside Azure Cloud Shell.

.EXAMPLE
    1. Configure Activity alerts
       .\configure-ActivityAlerts.ps1 -SubscriptionId <SubscriptionId> `
                                      -ResourceGroupName <Resource Group Name for deployment> `
                                      -ReceiverEmailIds "<emails separated by comma (,)>"

    2. Configure Activity alerts along with custom tags
       .\configure-ActivityAlerts.ps1 -SubscriptionId <SubscriptionId> `
                                      -ResourceGroupName <ResourceGroupName> `
                                      -ReceiverEmailIds "<Email Ids>" `
                                      -Location <Location> `
                                      -ApplicationOwnerTag <ApplicationOwnerTag> `
                                      -ServiceNameTag <ServiceNameTag> `
                                      -BusinessUnitTag <BusinessUnitTag> `
                                      -ProjectOwnerTag <ProjectOwnerTag> `
                                      -ApplicationTag <ApplicationTag> `
                                      -DepartmentTag <DepartmentTag> `
                                      -ProjectNameTag <ProjectNameTag> `
                                      -CostCenterTag <CostCenterTag> `
                                      -DataProfileTag <DataProfileTag>
                                      
    3. Configure Activity Alerts in custom region
       .\configure-ActivityAlerts.ps1 -SubscriptionId <SubscriptionId> `
                                      -ResourceGroupName <Resource Group Name for deployment> `
                                      -ReceiverEmailIds <emails separated by comma (,)> `
                                      -Location <location>
                                    

.INPUTS
    SubscriptionId: Subscription id for which ASC policies needs to be configured.
    ResourceGroupName: Resource Group Name where activity alerts will be deployed
    ReceiverEmailIds: Email id to which alerts to be sent
    ActivityAlertsActionGroupName: Activity Alerts action group name
    Location: Location of resource group
    ApplicationOwnerTag: Application owner
    ServiceNameTag: Service name
    BusinessUnitTag: Business unit
    ProjectOwnerTag: Project owner
    ApplicationTag: Application 
    DepartmentTag: Department
    ProjectNameTag: Project name
    CostCenterTag: Cost center
    DataProfileTag: Data profile 

.OUTPUTS
    Activity alerts deployed on subscriptionId

#>

[CmdletBinding()]
param
(
    # Subscription Id
    [Parameter(Mandatory = $True,
        HelpMessage = "SubscriptionId",
        Position = 1
    )]
    [ValidateNotNullOrEmpty()]
    [guid] $SubscriptionId,

    # Resource Group Name
    [Parameter(Mandatory = $True,
        HelpMessage = "Resource Group Name",
        Position = 2
    )]
    [ValidateNotNullOrEmpty()]
    [string] $ResourceGroupName,

    # Enter Email Id for receiving alerts.
    [Parameter(Mandatory = $true,
        HelpMessage = "Provide email addresses for receiving alerts(separated by comma(,))",
        Position = 3
    )]
    [ValidateNotNullOrEmpty()]
    [string] $ReceiverEmailIds,

    # Activity Alert Action Group Name
    [Parameter(Mandatory = $false,
        HelpMessage = "Provide activity alerts action group name",
        Position = 4
    )]
    [ValidateNotNullOrEmpty()]
    [string] $ActivityAlertsActionGroupName = "Activity-Alerts-AG",

    # Enter Location for deployment.
    [Parameter(Mandatory = $false,
        HelpMessage = "Location",
        Position = 5
    )]
    [ValidateNotNullOrEmpty()]
    [string] $Location = "eastus",
    
    # Enter Application Owner Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $ApplicationOwnerTag,

    # Enter Service Name Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $ServiceNameTag = "activity-alerts",

    # Enter Business Unit Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $BusinessUnitTag = "Governance",

    # Enter Project Owner Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $ProjectOwnerTag,

    # Enter Application Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $ApplicationTag = "activity-alert",

    # Enter Department Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $DepartmentTag = "Governance",
    
    # Enter Project Name Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $ProjectNameTag = "Governance",

    # Enter Cost Center Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $CostCenterTag = "NA",

    # Enter Data Profile Tag.
    [Parameter(Mandatory = $false)]
    [string]
    $DataProfileTag = "log-alerts"
)

# Function to create activity alert on subscription
Function Set-ActivityAlert() {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string] $SubscriptionId,
        [Parameter(Mandatory = $true)]
        [string] $ResourceGroupName,
        [Parameter(Mandatory = $true)]
        [object] $ActionGroup,
        [Parameter(Mandatory = $true)]
        [string] $AlertName,
        [Parameter(Mandatory = $true)]
        [string] $category,
        [Parameter(Mandatory = $true)]
        [string] $resourceType,
        [Parameter(Mandatory = $true)]
        [string] $operationName,
        [Parameter(Mandatory = $true)]
        [string] $activityLogLocation
    )
    $WarningPreference = "SilentlyContinue"

    # Creating activity log alert conditions
    $condition1 = New-AzActivityLogAlertCondition -Field 'category' -Equal $category
    $condition2 = New-AzActivityLogAlertCondition -Field 'resourceType' -Equal $resourceType
    $condition3 = New-AzActivityLogAlertCondition -Field 'operationName' -Equal $operationName

    try {
        Write-Host "`n`nSetting $alertName activity log alert..."
        Set-AzActivityLogAlert -Location $activityLogLocation `
                               -Name $alertName `
                               -ResourceGroupName $ResourceGroupName `
                               -Scope "/subscriptions/$SubscriptionId" `
                               -Action $ActionGroup `
                               -Condition $condition1, $condition2, $condition3 | Out-Null

        Write-Host "Successfully setup $alertName actvity log alert." -ForegroundColor Green 
    }
    catch [Exception] {
        Write-Host "Error occurred while setting up $alertName activity log alert" -ForegroundColor Red
        write-error $_
    }
}

# Session configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Script Execution Started..." -ForegroundColor Yellow

# Checking current az context to deploy Azure automation
$AzureContext = Get-AzContext
If ($AzureContext.Subscription.Id -ne $SubscriptionId) {
    Write-Host "You are not logged in to subscription" $SubscriptionId 
    Try {
        Write-Host "Trying to switch powershell context to subscription" $SubscriptionId
        $AllAvailableSubscriptions = (Get-AzSubscription).Id
        if ($AllAvailableSubscriptions -contains $SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId
            Write-Host "Successfully context switched to subscription" $SubscriptionId -ForegroundColor Green
        }
        else {
            Write-Host "Looks like the $SubscriptionId is not present in current powershell context or you don't have access" -ForegroundColor Red -ErrorAction Stop
            break
        }
    }
    catch [Exception] {
        Write-Host "Error occurred while switching to subscription $subscriptionId. Check subscription Id and try again." -ForegroundColor Red
        Write-Error $_ -ErrorAction Stop
    }
}

# Initializing variables
$activityLogLocation = 'Global'
$alertReceiver = @()

# Setting up tags
if($null -eq $ProjectOwnerTag){
    $ProjectOwnerTag = "$($AzureContext.Account.Id)"
}
if($null -eq $ApplicationOwnerTag){
    $ApplicationOwnerTag = "$($AzureContext.Account.Id)"
}

# Tags for activity alerts
$tags = @{     "ApplicationOwner"= $ApplicationOwnerTag
                "ServiceName"= $ServiceNameTag
                "DeployedBy"= "$($AzureContext.Account.Id)"
                "BusinessUnit"= $BusinessUnitTag
                "ProjectOwner"= $ProjectOwnerTag
                "Application"= $ApplicationTag
                "Description"= "Activity Alerts"
                "Department"= $DepartmentTag
                "ProjectName" = $ProjectNameTag
                "CostCenter"= $CostCenterTag
                "DataProfile"= $DataProfileTag
        }

# Alerts Object
$activityAlerts = @(
    [PSCustomObject]@{AlertName="Alert-on-NSG-delete";ResourceType="Microsoft.Network/NetworkSecurityGroups";OperationName= "Microsoft.Network/NetworkSecurityGroups/delete"}
    [PSCustomObject]@{AlertName="Alert-on-security-center-createorupdate";ResourceType="microsoft.security/securitysolutions";OperationName= "microsoft.security/securitysolutions/write"}
    [PSCustomObject]@{AlertName="Alert-on-NSG-rule-delete";ResourceType="All";OperationName= "Microsoft.Network/networkSecurityGroups/securityRules/delete"}
    [PSCustomObject]@{AlertName="Alert-on-create-or-update-NSG";ResourceType="Microsoft.Network/networkSecurityGroups";OperationName= "Microsoft.Network/NetworkSecurityGroups/write"}
    [PSCustomObject]@{AlertName="Alert-on-update-security-policy";ResourceType="All";OperationName= "Microsoft.Security/policies/write"}
    [PSCustomObject]@{AlertName="Alert-on-create-policy-assignment";ResourceType="All";OperationName= "Microsoft.Authorization/policyAssignments/write"}
    [PSCustomObject]@{AlertName="Alert-on-delete-security-solution";ResourceType="microsoft.security/securitysolutions";OperationName= "microsoft.security/securitysolutions/delete"}
    [PSCustomObject]@{AlertName="Alert-on-NSG-rule-createorupdate";ResourceType="All";OperationName= "Microsoft.Network/networkSecurityGroups/securityRules/write"}
    [PSCustomObject]@{AlertName="Alert-on-SQL-firewallRule-createorupdate";ResourceType="All";OperationName= "Microsoft.Sql/servers/firewallRules/write"}
    [PSCustomObject]@{AlertName="Alert-on-SQL-delete-createorupdate";ResourceType="All";OperationName= "Microsoft.Sql/servers/firewallRules/delete"}
)


Write-Host "Getting Access Token ..."
$token=$(az account get-access-token | jq -r .accessToken)
Write-Host "Access Token retrieved Successfully." -ForegroundColor Green

# # Create Resource Group if not exist
try{
    if($null -eq (Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)){
        Write-Host "`nCreating $ResourceGroupName resource group..."
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $tags -Force
        Write-Host "Successfully created $ResourceGroupName." -ForegroundColor Green
    }
    else{
        Write-Host "Resource Group $ResourceGroupName is already exist." -ForegroundColor Yellow
    }
}
catch [Exception]{
    Write-Host "Error occurred while creating resource group." -ForegroundColor Red
	exit
}

try {
    # Checking action group on subscription
    $ag = Get-AzActionGroup -Name $ActivityAlertsActionGroupName -ResourceGroup $ResourceGroupName -ErrorAction SilentlyContinue
    if ($null -ne $ag) {
        Write-Host "$ActivityAlertsActionGroupName already exists in subscription $subscriptionId" -ForegroundColor "Yellow"
        do
        {
            $option = Read-Host -Prompt "Do you want to subscribes to $ActivityAlertsActionGroupName (yes/no) :"
            switch ($option.ToLower()) {
                "yes" {
                    $AllExistingAlertReceiver = $ag.EmailReceivers.EmailAddress
                    $EmailReceivers = $AllExistingAlertReceiver + $ReceiverEmailIds.Split(",") | select -uniq
                    ForEach($EmailReceiver in $EmailReceivers){
                        $alertReceiver += New-AzActionGroupReceiver -Name $EmailReceiver -EmailReceiver -EmailAddress $EmailReceiver
                    }
                    $actionGroup = Set-AzActionGroup -Name $ActivityAlertsActionGroupName -ResourceGroup $ResourceGroupName -ShortName "AlertsAG" -Receiver $alertReceiver
                    Write-Host  "Successfully added $ReceiverEmailIds in existing action group $ActivityAlertsActionGroupName on subscription $subscriptionId" -ForegroundColor Green
                    Write-Host "`nScript execution completed." -ForegroundColor Yellow
                    exit
                }
                "no" {
                    Write-Host "Please try again with different action group name." -ForegroundColor Yellow
                    Write-Host "`nScript execution completed." -ForegroundColor Yellow
                    exit
                }
                default {
                    Write-Host "You have entered invalid input, Please enter 'yes' or 'no' only"
                }
            }
        }
        while(!($option.ToLower() -eq "yes" -or $option.ToLower() -eq "no"))
    }

    # Creating action group on subscription
    Write-Host "`nCreating $ActivityAlertsActionGroupName action group in subscription $SubscriptionId to send alert"
    ForEach($ReceiverEmailId in $ReceiverEmailIds.Split(",")){
        $alertReceiver += New-AzActionGroupReceiver -Name $ReceiverEmailId -EmailReceiver -EmailAddress $ReceiverEmailId
    }
    $actionGroup = Set-AzActionGroup -Name $ActivityAlertsActionGroupName -ResourceGroup $ResourceGroupName -ShortName "AlertsAG" -Receiver $alertReceiver
    Write-Host  "Successfully created action group $ActivityAlertsActionGroupName on subscription $subscriptionId" -ForegroundColor Green
}
catch [Exception] {
    Write-Host "Error occurred while creating $actionGroupName action group to subscription $subscriptionId." -ForegroundColor Red
    Write-Error $_ -ErrorAction Stop
}

# Creting required object to set activity log
$agAlertObject = New-Object Microsoft.Azure.Management.Monitor.Management.Models.ActivityLogAlertActionGroup
$agAlertObject.ActionGroupId = $actionGroup.Id

ForEach ($alert in $activityAlerts) {
    try {
        # Creating Activity Alerts
        Set-ActivityAlert -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName `
						  -ActionGroup $agAlertObject -AlertName $alert.AlertName `
						  -category 'Administrative' -resourceType $alert.ResourceType `
						  -operationName $alert.OperationName -activityLogLocation $activityLogLocation `
						  -ErrorAction SilentlyContinue
        try {
            # Getting activity alerts
            $AlertURL = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/microsoft.insights/activityLogAlerts/$($alert.AlertName)?api-version=2017-04-01"
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add('Authorization','Bearer {0}' -f $Token)

            # Applying tags on activity alerts
            Write-Host "Applying required tags on $($alert.AlertName) activity alerts"    
            $alertResponse = Invoke-WebRequest -Method GET -Uri $AlertURL -Headers $headers -ContentType "application/json" -UseBasicParsing
            
            if($null -ne $alertResponse){
                $PutAlertResponseObject = $alertResponseObject = $alertResponse | ConvertFrom-Json
                foreach($tag in $tags.GetEnumerator()){
                    $alertResponseObject.tags  | Add-Member -MemberType NoteProperty -Name $tag.Name -Value $tag.Value -ErrorAction SilentlyContinue
                }
                $PutAlertResponseObject.properties = $alertResponseObject.properties | Select-Object -Property * -ExcludeProperty action,lastUpdatedTime,provisioningState
                $AlertResponseBody = $PutAlertResponseObject | ConvertTo-Json -Depth 4
                
                $headers.Add('Content-Type','Bearer {0}' -f "application/json")
                $alertResponse = Invoke-WebRequest -Method Put -Body $AlertResponseBody -Uri $AlertURL -Headers $headers -ContentType "application/json" -UseBasicParsing
				        Write-Host "Successfully applied tags on $($alert.AlertName) activity alert" -ForegroundColor Green
            }
        }
        catch [Exception] {
            Write-Host "Error occurred while setting tags on $($alert.AlertName) activity alert" -ForegroundColor Red
            Write-Error $_.Exception.Message -ErrorAction SilentlyContinue
        }
    }
    catch [Exception] {
        Write-Host "Error occurred while creating $($alert.AlertName) activity alert" -ForegroundColor Red
        Write-Error $_.Exception.Message -ErrorAction SilentlyContinue
    }
}

Write-Host "`nScript execution completed." -ForegroundColor Yellow
