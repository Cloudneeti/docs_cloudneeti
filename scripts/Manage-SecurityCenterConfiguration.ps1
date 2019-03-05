<#
.SYNOPSIS
    This Script remediate or revert the policy configuration for Azure security Center.

.DESCRIPTION
    This script apply configuration on security center with respect to Cloudneeti Policies. It can also be used for removing the configuration.

.NOTES
    Version:        1.0
    Author:         Cloudneeti
    Creation Date:  25/02/2019

.EXAMPLE

1. Apply Policy configuration
    .\Manage-SecurityCenterConfiguration.ps1 -subscriptionId <subscriptionId> -policyConfiguration Remediate/Revert

.INPUTS
-SubscriptionId

.OUTPUTS
Successfully Applied/Removed policy configuration.

#>

[CmdletBinding()]
param
(
    # SubscriptionId
    [Parameter(Mandatory = $False,
        HelpMessage = "SubscriptionId",
        Position = 1
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $SubscriptionId = $(Read-Host -prompt "Enter Subscription Id"),

    # policy configuration
    [Parameter(Mandatory = $False,
        HelpMessage = "Policy Configuration Action",
        Position = 2
    )]
    [ValidateSet("Remediate", "Revert")]
    [string]
    $PolicyConfigurationAction = $(Read-Host -prompt "Enter Policy Configuration Action (Remediate/Revert)")
)

# Session configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

Write-Host "Script Execution Started." -ForegroundColor Yellow

# Checking current azure rm context to deploy Azure automation
$AzureContextSubscriptionId = (Get-AzureRmContext).Subscription.Id

If ($AzureContextSubscriptionId -ne $SubscriptionId) {
    Write-Host "You are not logged in to subscription" $SubscriptionId 
    Try {
        Write-Host "Trying to switch powershell context to subscription" $SubscriptionId
        $AllAvailableSubscriptions = (Get-AzureRmSubscription).Id
        if ($AllAvailableSubscriptions -contains $SubscriptionId) {
            Set-AzureRmContext -SubscriptionId $SubscriptionId
            Write-Host "Successfully context switched to subscription" $SubscriptionId -ForegroundColor Green
        }
        else {
            Write-Host "Looks like the $SubscriptionId is not present in current powershell context or you don't have access" -ForegroundColor Red -ErrorAction Stop
            break
        }
    }
    catch [Exception] {
        Write-Output $_ -ErrorAction Stop
    }
}

# Get Bearer Token
$token=$(az account get-access-token | jq -r .accessToken)

switch ($PolicyConfigurationAction) {
    "remediate" {
        #$parameterFile = ".\positive.azurepolicyset.parameters.values.json"

        $body = @"
        {
            "properties": {
                "displayName": "ASC Default (subscription: $subscriptionId)",
                "metadata": {
                    "assignedBy": "Cloudneeti"
                },
                "policyDefinitionId": "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8",
                "parameters": {
                    "systemUpdatesMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "systemConfigurationsMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "endpointProtectionMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "diskEncryptionMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "networkSecurityGroupsMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "webApplicationFirewallMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "nextGenerationFirewallMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "vulnerabilityAssesmentMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "storageEncryptionMonitoringEffect": {
                        "value": "Audit"
                    },
                    "jitNetworkAccessMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "adaptiveApplicationControlsMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "sqlAuditingMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "sqlEncryptionMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "diagnosticsLogsInAppServiceMonitoringEffect": {
                        "value": "Audit"
                    },
                    "diagnosticsLogsInKeyVaultMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "diagnosticsLogsInKeyVaultRetentionDays": {
                        "value": "364"
                    },
                    "diagnosticsLogsInLogicAppsMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "diagnosticsLogsInLogicAppsRetentionDays": {
                        "value": "364"
                    },
                    "diagnosticsLogsInRedisCacheMonitoringEffect": {
                        "value": "Audit"
                    },
                    "diagnosticsLogsInSearchServiceMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "diagnosticsLogsInSearchServiceRetentionDays": {
                        "value": "364"
                    },
                    "aadAuthenticationInServiceFabricMonitoringEffect": {
                        "value": "Audit"
                    },
                    "diagnosticsLogsInServiceBusRetentionDays": {
                        "value": "364"
                    },
                    "aadAuthenticationInSqlServerMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "diagnosticsLogsInStreamAnalyticsMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    },
                    "diagnosticsLogsInStreamAnalyticsRetentionDays": {
                        "value": "364"
                    },
                    "diagnosticsLogsInServiceFabricMonitoringEffect": {
                        "value": "AuditIfNotExists"
                    }
                }
            }
        }
"@

        $StartMessage = "Applying configuration to security center"
        $SuccessMessage = "Successfully remediated security center configuration"
        $FailureMessage = "Error ocurred while remediating security ceter configuration"
    }
    "revert" {
        #$parameterFile = ".\negative.azurepolicyset.parameters.values.json"
        $body = @"
        {
            "properties": {
                "displayName": "ASC Default (subscription: $subscriptionId)",
                "metadata": {
                    "assignedBy": "Cloudneeti"
                },
                "policyDefinitionId": "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8",
                "parameters": {
                    "systemUpdatesMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "systemConfigurationsMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "endpointProtectionMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "diskEncryptionMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "networkSecurityGroupsMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "webApplicationFirewallMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "nextGenerationFirewallMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "vulnerabilityAssesmentMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "storageEncryptionMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "jitNetworkAccessMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "adaptiveApplicationControlsMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "sqlAuditingMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "sqlEncryptionMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "diagnosticsLogsInAppServiceMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "diagnosticsLogsInKeyVaultMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "diagnosticsLogsInKeyVaultRetentionDays": {
                        "value": "363"
                    },
                    "diagnosticsLogsInLogicAppsMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "diagnosticsLogsInLogicAppsRetentionDays": {
                        "value": "363"
                    },
                    "diagnosticsLogsInRedisCacheMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "diagnosticsLogsInSearchServiceMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "diagnosticsLogsInSearchServiceRetentionDays": {
                        "value": "363"
                    },
                    "aadAuthenticationInServiceFabricMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "diagnosticsLogsInServiceBusRetentionDays": {
                        "value": "363"
                    },
                    "aadAuthenticationInSqlServerMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "diagnosticsLogsInStreamAnalyticsMonitoringEffect": {
                        "value": "Disabled"
                    },
                    "diagnosticsLogsInStreamAnalyticsRetentionDays": {
                        "value": "363"
                    },
                    "diagnosticsLogsInServiceFabricMonitoringEffect": {
                        "value": "Disabled"
                    }
                }
            }
        }
"@
        $StartMessage = "Reverting security center configurations"
        $SuccessMessage = "Successfully reverted security center configuration"
        $FailureMessage = "Error ocurred while reverting security configuration"
    }
}


# Perform configuration changes
#$policySetAssignmentName = [guid]::NewGuid().Guid.ToUpper().Replace("-", "")
#$policySetAssignmentDisplayName = "cloudneeti-security-center-monitoring"


try {

    Write-Host "`n$StartMessage", $_.StorageAccountName    #Assign tagging policy set definition
    <#
    New-AzureRmPolicyAssignment -PolicySetDefinition $policySetDefinition `
        -Name $policySetAssignmentName `
        -DisplayName "$policySetAssignmentDisplayName" `
        -Sku @{"Name"="A1";"Tier"="Standard"} `
        -Scope "/subscriptions/$subscriptionId" `
        -PolicyParameter $parameterFile
    #>
    $mgmtAPI = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Authorization/policyAssignments/SecurityCenterBuiltIn?api-version=2018-05-01"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"

    $headers.Add('authorization', "Bearer " + $token)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $response = Invoke-WebRequest -Method PUT -Uri $mgmtAPI -Headers $headers -Body $body -ContentType "application/json" # -ErrorAction SilentlyContinue

    if ($response -ne $null) {
        Write-Host $SuccessMessage -ForegroundColor Green
    }
}
catch [Exception] {
    Write-Host $FailureMessage -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
}

Write-Host "`nScript Execution completed." -ForegroundColor Yellow