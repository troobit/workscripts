<#
=============================================================================
 SCAFFOLDING — NOT WORKING CONFIGURATION
=============================================================================
Skeleton for registering devices with Windows Autopilot by uploading
hardware hashes to Microsoft Graph. Placeholders must be replaced and the
flow tested against a real tenant with Intune licences before use.

Graph surface:
  POST /deviceManagement/importedWindowsAutopilotDeviceIdentities
  https://learn.microsoft.com/en-us/graph/api/resources/intune-enrollment-importedwindowsautopilotdeviceidentity?view=graph-rest-1.0

Input CSV format (produced by Get-WindowsAutopilotInfo on the device):
  Device Serial Number,Windows Product ID,Hardware Hash,Group Tag
  https://learn.microsoft.com/en-us/autopilot/add-devices
=============================================================================
#>

#Requires -Modules Microsoft.Graph.Authentication

[CmdletBinding()]
param(
    # csv exported from Get-WindowsAutopilotInfo
    [Parameter(Mandatory)]
    [string]$CsvPath,

    # optional group tag to stamp on every imported device
    [string]$GroupTag = '<GROUP_TAG>'
)

# DeviceManagementServiceConfig.ReadWrite.All is required for autopilot import
Connect-MgGraph -TenantId '<TENANT_ID>' -Scopes 'DeviceManagementServiceConfig.ReadWrite.All'

$devices = Import-Csv -Path $CsvPath

foreach ($device in $devices) {
    $body = @{
        '@odata.type'      = '#microsoft.graph.importedWindowsAutopilotDeviceIdentity'
        serialNumber       = $device.'Device Serial Number'
        productKey         = $device.'Windows Product ID'
        hardwareIdentifier = $device.'Hardware Hash'
        groupTag           = $GroupTag
        state              = @{
            '@odata.type'      = 'microsoft.graph.importedWindowsAutopilotDeviceIdentityState'
            deviceImportStatus = 'pending'
            deviceRegistrationId = ''
            deviceErrorCode    = 0
            deviceErrorName    = ''
        }
    }

    # import is async: poll the returned identity's state until complete
    Invoke-MgGraphRequest -Method POST `
        -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/importedWindowsAutopilotDeviceIdentities' `
        -Body ($body | ConvertTo-Json -Depth 5)

    Write-Host "Submitted import for serial $($device.'Device Serial Number')"
}

# TODO(scaffolding): poll import state, then trigger an Autopilot sync so
# devices appear in Intune (windowsAutopilotSettings/sync).
