<#
=============================================================================
 SCAFFOLDING — NOT WORKING CONFIGURATION
=============================================================================
Skeleton for assigning a Windows Autopilot deployment profile to an Entra
device group via Microsoft Graph (beta endpoint). Placeholders must be
replaced and the flow tested against a real tenant before use.

Graph surface:
  POST /deviceManagement/windowsAutopilotDeploymentProfiles/{id}/assignments
  https://learn.microsoft.com/en-us/graph/api/resources/intune-enrollment-windowsautopilotdeploymentprofileassignment?view=graph-rest-beta

Typical target: a dynamic device group over the Autopilot group tag, e.g.
  (device.devicePhysicalIds -any (_ -eq "[OrderID]:<GROUP_TAG>"))
=============================================================================
#>

#Requires -Modules Microsoft.Graph.Authentication

[CmdletBinding()]
param(
    # id returned by New-AutopilotDeploymentProfile.ps1
    [Parameter(Mandatory)]
    [string]$ProfileId,

    # object id of the entra device group receiving the profile
    [string]$GroupObjectId = '<DEVICE_GROUP_OBJECT_ID>'
)

Connect-MgGraph -TenantId '<TENANT_ID>' -Scopes 'DeviceManagementServiceConfig.ReadWrite.All'

$body = @{
    target = @{
        '@odata.type' = '#microsoft.graph.groupAssignmentTarget'
        groupId       = $GroupObjectId
    }
}

Invoke-MgGraphRequest -Method POST `
    -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles/$ProfileId/assignments" `
    -Body ($body | ConvertTo-Json -Depth 5)

Write-Host "Assigned profile $ProfileId to group $GroupObjectId"
