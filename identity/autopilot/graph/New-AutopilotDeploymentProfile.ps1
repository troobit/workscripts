<#
=============================================================================
 SCAFFOLDING — NOT WORKING CONFIGURATION
=============================================================================
Skeleton for creating a Windows Autopilot deployment profile via Microsoft
Graph (beta endpoint — profile types are not exposed on v1.0). Placeholders
must be replaced and the flow tested against a real tenant before use.

Graph surface:
  POST /deviceManagement/windowsAutopilotDeploymentProfiles
  https://learn.microsoft.com/en-us/graph/api/resources/intune-enrollment-azureadwindowsautopilotdeploymentprofile?view=graph-rest-beta

Profile body lives beside this script:
  profiles/standard-user.example.json
=============================================================================
#>

#Requires -Modules Microsoft.Graph.Authentication

[CmdletBinding()]
param(
    # json file containing the deployment profile body
    [string]$ProfilePath = "$PSScriptRoot/profiles/standard-user.example.json"
)

Connect-MgGraph -TenantId '<TENANT_ID>' -Scopes 'DeviceManagementServiceConfig.ReadWrite.All'

$body = Get-Content -Path $ProfilePath -Raw

# $created, not $profile — $PROFILE is a powershell automatic variable
$created = Invoke-MgGraphRequest -Method POST `
    -Uri 'https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles' `
    -Body $body

Write-Host "Created deployment profile '$($created.displayName)' with id $($created.id)"

# next step: assign the profile to a device group with
# Set-AutopilotProfileAssignment.ps1
