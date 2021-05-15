#Generate self signed cert, and strings for connection.
$certName = (Read-Host -Prompt "Enter a value for the certificate name.`nAny short unique identifier is sufficient,`nfor example, ProjCert, AZ1, RonanIsGreat...`n")

Write-Host "Creating P2S cert, with name $($certName).cert. This will be stored locally, with the exported public key stored on your desktop as $($certName).cer"
$cert = New-SelfSignedCertificate -Type Custom `
 -KeySpec Signature `
 -Subject "CN=$($certName).root" `
 -KeyExportPolicy Exportable `
 -HashAlgorithm sha256 `
 -KeyLength 2048 `
 -CertStoreLocation "Cert:\CurrentUser\My" `
 -KeyUsageProperty Sign `
 -KeyUsage CertSign `
 -FriendlyName "$($certName)_P2S_root"

New-SelfSignedCertificate -Type Custom `
-DnsName "$($certName).cert" `
-KeySpec Signature `
-Subject "CN=$($certName).cert" `
-KeyExportPolicy Exportable `
-HashAlgorithm sha256 `
-KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $cert `
-TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2") `
-FriendlyName "$($certName)_P2S_client"

$cert=(Get-ChildItem -Path "Cert:\CurrentUser\My\" | Where-Object -Property Subject -EQ "CN=$($certName).root")

Export-Certificate -Cert $cert `
-FilePath C:\Users\$($env:username)\Desktop\$($certName).cer `
-Type cert `
-Force
#certutil.exe allows us to change the encoding from the original to base 64 encoding, so we can use the cert string appropriately.
certutil.exe -encode C:\Users\$($env:username)\Desktop\$($certName).cer C:\Users\$($env:username)\Desktop\$($certName)_base64.cer
# Once we've got the base64 encoded version, the original is no longer needed.
Remove-Item -Force C:\Users\$($env:username)\Desktop\$($certName).cer

# The following lines just create a string of ONLY the cert details. It's both save on the current user's desktop AND copied
# to the clipboard, so all you need to to is hit CTRL-V
$cert = (Get-Content C:\Users\$($env:username)\Desktop\$($certName)_base64.cer)
# Get the END (last line of the cert, which is actually the 2nd last, in an agreeable type
[System.int32]$end = $cert.Length - 2
$certString = [system.String]::Join('',$cert[1..$end])
Write-Host "Your certificate string data is below:"
Write-Host $cert
Write-Host "(it's also in your clipboard without the --BEGIN-- and --END-- flags. Just it CTRL+V!)"
$certString | clip.exe