$service = (Get-Service -Name SplunkForwarder -ErrorAction SilentlyContinue)

if ($service.length -gt 0)
{
Remove-Item 'C:\Program Files\SplunkUniversalForwarder\etc\system\local\outputs.conf'
$original = get-content 'C:\Program Files\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf'
$new = $original -replace '172.16.112.75','172.16.112.80'
$new | Set-Content -Path 'C:\Program Files\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf'
Get-Service | ? Name -Like "*splunk*" | Restart-Service
} else
{
Write-Host "No Splunk service seems to be running..."
}

get-content 'C:\Program Files\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf'